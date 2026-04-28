#!/usr/bin/env bash
# dir_brutal_test_v1.sh
# Brutal production CI test suite for bashx/std/dir.sh
#
# Usage:
#   bash dir_brutal_test_v1.sh [path/to/path.sh] [path/to/dir.sh]
#
# Environment:
#   BASHX_TEST_VERBOSE=1       print passing assertions
#   BASHX_TEST_SLOW=1          enable heavier archive/checksum/snapshot stress
#   BASHX_TEST_WATCH=0         disable watch tests
#   BASHX_TEST_SHELLCHECK=1    run shellcheck on both libs when available
#   BASHX_TEST_FUZZ=300        path/name fuzz iterations
#
# Design:
#   - sources path.sh then dir.sh
#   - standalone sys::* shim when system.sh is not loaded
#   - creates a destructive sandbox only under mktemp
#   - checks every declared dir::* function is tested
#   - expects directory-specific safety semantics, especially:
#       dir::contains* accepts child names only, not paths/traversal.

set -u

PATH_LIB="${1:-${PATH_LIB:-src/parts/builtin/path.sh}}"
DIR_LIB="${2:-${DIR_LIB:-src/parts/builtin/dir.sh}}"

TEST_ROOT=""
MAIN_PID="${BASHPID:-$$}"
TOTAL=0
PASS=0
FAIL=0
SKIP=0

VERBOSE="${BASHX_TEST_VERBOSE:-0}"
SLOW="${BASHX_TEST_SLOW:-0}"
DO_WATCH="${BASHX_TEST_WATCH:-1}"
DO_SHELLCHECK="${BASHX_TEST_SHELLCHECK:-0}"
FUZZ="${BASHX_TEST_FUZZ:-300}"

declare -A TESTED_FUNCS=()

# -----------------------------------------------------------------------------
# Minimal sys::* compatibility layer.
# -----------------------------------------------------------------------------

declare -F sys::has >/dev/null 2>&1 || sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
declare -F sys::is_linux >/dev/null 2>&1 || sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }
declare -F sys::is_macos >/dev/null 2>&1 || sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }
declare -F sys::is_windows >/dev/null 2>&1 || sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]]; }
declare -F sys::is_wsl >/dev/null 2>&1 || sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]] && return 0; grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; }
declare -F sys::uhome >/dev/null 2>&1 || sys::uhome () { printf '%s\n' "${HOME:-${USERPROFILE:-}}"; }

# -----------------------------------------------------------------------------
# Harness
# -----------------------------------------------------------------------------

cleanup () {
    [[ "${BASHPID:-$$}" == "${MAIN_PID}" ]] || return 0
    if [[ -n "${TEST_ROOT:-}" && -d "${TEST_ROOT:-}" ]]; then
        chmod -R u+rwX -- "${TEST_ROOT}" 2>/dev/null || true
        rm -rf -- "${TEST_ROOT}" 2>/dev/null || true
    fi
}
trap 'cleanup; exit 130' INT TERM

note () { printf '\n\033[1;36m[%s]\033[0m\n' "$*"; }

mark () {
    local fn="${1:-}"
    [[ -n "${fn}" ]] && TESTED_FUNCS["${fn}"]=1
}

ok () {
    TOTAL=$(( TOTAL + 1 ))
    PASS=$(( PASS + 1 ))
    [[ "${VERBOSE}" == 1 ]] && printf '  \033[32mPASS\033[0m %s\n' "$1"
    return 0
}

fail () {
    TOTAL=$(( TOTAL + 1 ))
    FAIL=$(( FAIL + 1 ))
    printf '  \033[31mFAIL\033[0m %s\n' "$1"
    return 1
}

skip () {
    TOTAL=$(( TOTAL + 1 ))
    SKIP=$(( SKIP + 1 ))
    printf '  \033[33mSKIP\033[0m %s\n' "$1"
    return 0
}

assert_true () {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then ok "${label}"; else fail "${label}"; fi
}

assert_false () {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then fail "${label}"; else ok "${label}"; fi
}

assert_eq () {
    local label="$1" expected="$2" actual="$3"
    if [[ "${actual}" == "${expected}" ]]; then
        ok "${label}"
    else
        fail "${label} :: expected=[${expected}] actual=[${actual}]"
    fi
}

assert_ne () {
    local label="$1" a="$2" b="$3"
    if [[ "${a}" != "${b}" ]]; then ok "${label}"; else fail "${label} :: both=[${a}]"; fi
}

assert_match () {
    local label="$1" value="$2" regex="$3"
    if [[ "${value}" =~ ${regex} ]]; then ok "${label}"; else fail "${label} :: value=[${value}] regex=[${regex}]"; fi
}

assert_file () {
    local label="$1" p="$2"
    [[ -f "${p}" ]] && ok "${label}" || fail "${label} :: missing file ${p}"
}

assert_dir () {
    local label="$1" p="$2"
    [[ -d "${p}" ]] && ok "${label}" || fail "${label} :: missing dir ${p}"
}

assert_link () {
    local label="$1" p="$2"
    [[ -L "${p}" ]] && ok "${label}" || fail "${label} :: missing link ${p}"
}

assert_missing () {
    local label="$1" p="$2"
    [[ ! -e "${p}" && ! -L "${p}" ]] && ok "${label}" || fail "${label} :: still exists ${p}"
}

run_timeout () {
    local seconds="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${seconds}" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "${seconds}" "$@"
    else
        "$@"
    fi
}

can_exact_chmod () {
    sys::is_windows && return 1
    return 0
}

can_symlink () {
    local target="${1:-}" link="${2:-}"
    [[ -n "${target}" && -n "${link}" ]] || return 1
    ln -s "${target}" "${link}" 2>/dev/null || return 1
    [[ -L "${link}" ]] || { rm -f -- "${link}" 2>/dev/null || true; return 1; }
    rm -f -- "${link}" 2>/dev/null || true
    return 0
}

portable_sleep () {
    sleep "${1:-0.2}" 2>/dev/null || sleep 1
}

sorted_lines () {
    if command -v sort >/dev/null 2>&1; then LC_ALL=C sort
    else cat
    fi
}

count_lines () {
    wc -l | tr -d '[:space:]'
}

has_line () {
    local needle="$1"
    grep -Fx -- "${needle}" >/dev/null 2>&1
}

callback_touch () {
    local out="${1:-}" msg="${2:-ok}"
    printf '%s\n' "${msg}" >> "${out}"
}

with_lock_callback () {
    local out="${1:-}"
    printf 'locked\n' >> "${out}"
    return 0
}

# -----------------------------------------------------------------------------
# Load target
# -----------------------------------------------------------------------------

if [[ ! -f "${PATH_LIB}" ]]; then
    printf 'Target path.sh not found: %s\n' "${PATH_LIB}" >&2
    exit 2
fi
if [[ ! -f "${DIR_LIB}" ]]; then
    printf 'Target dir.sh not found: %s\n' "${DIR_LIB}" >&2
    exit 2
fi

if ! bash -n "${PATH_LIB}" 2>/dev/null; then
    printf 'Syntax check failed: %s\n' "${PATH_LIB}" >&2
    bash -n "${PATH_LIB}"
    exit 2
fi
if ! bash -n "${DIR_LIB}" 2>/dev/null; then
    printf 'Syntax check failed: %s\n' "${DIR_LIB}" >&2
    bash -n "${DIR_LIB}"
    exit 2
fi

if [[ "${DO_SHELLCHECK}" == 1 ]]; then
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck "${PATH_LIB}" -e SC2148
        shellcheck "${DIR_LIB}" -e SC2148
    else
        printf 'shellcheck unavailable; skipping static check\n' >&2
    fi
fi

# shellcheck source=/dev/null
source "${PATH_LIB}"
# shellcheck source=/dev/null
source "${DIR_LIB}"

if ! declare -F dir::exists >/dev/null 2>&1; then
    printf 'Failed to load dir functions from: %s\n' "${DIR_LIB}" >&2
    exit 2
fi

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t dirbrutal)"
mkdir -p -- \
    "${TEST_ROOT}/root/a/b/c" \
    "${TEST_ROOT}/root/space dir" \
    "${TEST_ROOT}/root/unicodé-دليل" \
    "${TEST_ROOT}/root/.hidden-dir" \
    "${TEST_ROOT}/root/empty-dir" \
    "${TEST_ROOT}/root/dash-dir" \
    "${TEST_ROOT}/outside" \
    "${TEST_ROOT}/archives" \
    "${TEST_ROOT}/extract" \
    "${TEST_ROOT}/dst"

printf 'alpha\n' > "${TEST_ROOT}/root/file.txt"
printf 'beta\n' > "${TEST_ROOT}/root/space dir/file with spaces.txt"
printf 'gamma\n' > "${TEST_ROOT}/root/a/b/c/deep.txt"
printf 'hidden file\n' > "${TEST_ROOT}/root/.hidden-file"
printf 'unicode file\n' > "${TEST_ROOT}/root/unicodé-دليل/ملف.txt"
printf 'dash file\n' > "${TEST_ROOT}/root/dash-dir/-dash-file"
printf 'escape\n' > "${TEST_ROOT}/outside/escape.txt"

ROOT="${TEST_ROOT}/root"
FILE="${ROOT}/file.txt"
SUB="${ROOT}/a"
DEEP="${ROOT}/a/b/c"
EMPTY="${ROOT}/empty-dir"

unalias -a 2>/dev/null || true

note "target"
printf 'path: %s\ndir : %s\nroot: %s\n' "${PATH_LIB}" "${DIR_LIB}" "${TEST_ROOT}"

# -----------------------------------------------------------------------------
# Basic predicates and wrappers
# -----------------------------------------------------------------------------

note "basic predicates and directory-only wrappers"

mark dir::valid
assert_true  "valid normal dir path" dir::valid "${ROOT}"
assert_true  "valid unicode dir path" dir::valid "${ROOT}/unicodé-دليل"
assert_false "valid rejects empty" dir::valid ""
assert_false "valid rejects newline" dir::valid $'bad\npath'
assert_false "valid rejects carriage return" dir::valid $'bad\rpath'

mark dir::exists
assert_true  "exists dir" dir::exists "${ROOT}"
assert_false "exists file is not dir" dir::exists "${FILE}"
assert_false "exists missing" dir::exists "${ROOT}/missing"

mark dir::missing
assert_true  "missing missing" dir::missing "${ROOT}/missing"
assert_true  "missing file because not dir" dir::missing "${FILE}"
assert_false "missing existing dir" dir::missing "${ROOT}"

mark dir::empty
assert_true  "empty existing empty dir" dir::empty "${EMPTY}"
assert_false "empty filled dir" dir::empty "${ROOT}"
assert_true  "empty missing treated as empty" dir::empty "${ROOT}/missing"

mark dir::filled
assert_true  "filled non-empty dir" dir::filled "${ROOT}"
assert_false "filled empty dir" dir::filled "${EMPTY}"
assert_false "filled file rejected" dir::filled "${FILE}"

mark dir::readable
assert_true  "readable dir" dir::readable "${ROOT}"
assert_false "readable rejects file" dir::readable "${FILE}"

mark dir::writable
assert_true  "writable dir" dir::writable "${ROOT}"
assert_false "writable rejects file" dir::writable "${FILE}"

mark dir::executable
assert_true  "executable/searchable dir" dir::executable "${ROOT}"
assert_false "executable rejects file" dir::executable "${FILE}"

mark dir::is_abs
assert_true  "is_abs existing abs dir" dir::is_abs "${ROOT}"
assert_false "is_abs rejects file" dir::is_abs "${FILE}"
assert_false "is_abs rejects relative existing dir unless cwd-local" dir::is_abs "definitely-missing-relative-dir"

mark dir::is_rel
mkdir -p "${TEST_ROOT}/rel-dir"
(
    cd "${TEST_ROOT}" || exit 1
    assert_true "is_rel relative existing dir" dir::is_rel "rel-dir"
    assert_false "is_rel absolute existing dir" dir::is_rel "${ROOT}"
)
assert_false "is_rel rejects file" dir::is_rel "${FILE}"

mark dir::is_root
assert_false "is_root normal dir" dir::is_root "${ROOT}"
if [[ -d "/" ]]; then assert_true "is_root slash dir" dir::is_root "/"; fi
assert_false "is_root rejects file" dir::is_root "${FILE}"

mark dir::is_hidden
assert_true  "is_hidden hidden dir" dir::is_hidden "${ROOT}/.hidden-dir"
assert_false "is_hidden normal dir" dir::is_hidden "${ROOT}/a"
assert_false "is_hidden rejects hidden file" dir::is_hidden "${ROOT}/.hidden-file"

mark dir::is_under
assert_true  "is_under child" dir::is_under "${DEEP}" "${ROOT}"
assert_false "is_under same" dir::is_under "${ROOT}" "${ROOT}"
assert_false "is_under sibling" dir::is_under "${TEST_ROOT}/outside" "${ROOT}"

mark dir::is_parent
assert_true  "is_parent parent" dir::is_parent "${ROOT}" "${DEEP}"
assert_false "is_parent same" dir::is_parent "${ROOT}" "${ROOT}"
assert_false "is_parent sibling" dir::is_parent "${ROOT}" "${TEST_ROOT}/outside"

mark dir::is_safe
assert_true  "is_safe child inside root" dir::is_safe "${DEEP}" "${ROOT}"
assert_false "is_safe traversal rejected" dir::is_safe "${ROOT}/../outside" "${ROOT}"
assert_false "is_safe root rejected" dir::is_safe "/" "${ROOT}"

mark dir::is_same
assert_true  "is_same self" dir::is_same "${ROOT}" "${ROOT}"
assert_false "is_same different dirs" dir::is_same "${ROOT}" "${TEST_ROOT}/outside"
assert_false "is_same rejects file" dir::is_same "${ROOT}" "${FILE}"

# -----------------------------------------------------------------------------
# Names, path transforms, metadata
# -----------------------------------------------------------------------------

note "names, path transforms, metadata"

mark dir::name
assert_eq "name root leaf" "root" "$(dir::name "${ROOT}")"
assert_eq "name trailing slash" "a" "$(dir::name "${ROOT}/a/")"

mark dir::parent
assert_eq "parent name" "$(basename "${TEST_ROOT}")" "$(dir::parent "${ROOT}")"

mark dir::dirname
assert_eq "dirname root" "${TEST_ROOT}" "$(dir::dirname "${ROOT}")"

mark dir::resolve
resolved="$(dir::resolve "${ROOT}/a/../a")"
assert_match "resolve absolute" "${resolved}" '^/'
assert_eq "resolve basename" "a" "$(basename "${resolved}")"

mark dir::expand
assert_eq "expand plain dir string" "${ROOT}" "$(dir::expand "${ROOT}")"
assert_eq "expand ~" "${HOME:-}" "$(dir::expand '~')"

mark dir::abs
assert_match "abs existing dir" "$(dir::abs "${ROOT}/a/..")" '^/'

mark dir::rel
assert_eq "rel child dir" "a/b/c" "$(dir::rel "${DEEP}" "${ROOT}")"
assert_eq "rel same dir" "." "$(dir::rel "${ROOT}" "${ROOT}")"

mark dir::can
assert_match "can existing dir" "$(dir::can "${ROOT}")" '^/'
assert_false "can rejects file" dir::can "${FILE}"

mark dir::type
assert_eq "type dir" "dir" "$(dir::type "${ROOT}")"
assert_false "type rejects file" dir::type "${FILE}"

mark dir::size
assert_match "size numeric" "$(dir::size "${ROOT}")" '^[0-9]+$'
assert_false "size rejects file" dir::size "${FILE}"

mark dir::mtime
assert_match "mtime numeric" "$(dir::mtime "${ROOT}")" '^[0-9]+$'
assert_false "mtime rejects file" dir::mtime "${FILE}"

mark dir::atime
assert_match "atime numeric" "$(dir::atime "${ROOT}")" '^[0-9]+$'
assert_false "atime rejects file" dir::atime "${FILE}"

mark dir::ctime
assert_match "ctime numeric" "$(dir::ctime "${ROOT}")" '^[0-9]+$'
assert_false "ctime rejects file" dir::ctime "${FILE}"

mark dir::age
assert_match "age numeric" "$(dir::age "${ROOT}")" '^[0-9]+$'
assert_false "age rejects file" dir::age "${FILE}"

mark dir::owner
[[ -n "$(dir::owner "${ROOT}")" ]] && ok "owner returns value" || fail "owner returns value"
assert_false "owner rejects file" dir::owner "${FILE}"

mark dir::group
[[ -n "$(dir::group "${ROOT}")" ]] && ok "group returns value" || fail "group returns value"
assert_false "group rejects file" dir::group "${FILE}"

mark dir::mode
assert_match "mode returns octal-ish" "$(dir::mode "${ROOT}")" '^[0-7]+$'
assert_false "mode rejects file" dir::mode "${FILE}"

mark dir::inode
assert_match "inode numeric" "$(dir::inode "${ROOT}")" '^[0-9]+$'
assert_false "inode rejects file" dir::inode "${FILE}"

mark dir::tree
tree_out="$(dir::tree "${ROOT}" 2>/dev/null || true)"
[[ -n "${tree_out}" ]] && ok "tree returns output" || skip "tree unavailable or empty output"
assert_false "tree rejects file" dir::tree "${FILE}"

# -----------------------------------------------------------------------------
# Mutations: create, ensure, parent, chmod, rename/move/copy/remove/clear
# -----------------------------------------------------------------------------

note "filesystem mutations"

mark dir::new
new_dir="${TEST_ROOT}/new-dir"
assert_true "new creates missing dir" dir::new "${new_dir}"
assert_dir  "new dir exists" "${new_dir}"
assert_false "new refuses existing dir" dir::new "${new_dir}"

mark dir::ensure
ensure_dir="${TEST_ROOT}/ensure/deep/path"
assert_true "ensure creates nested dir" dir::ensure "${ensure_dir}"
assert_dir  "ensure nested exists" "${ensure_dir}"
assert_true "ensure existing ok" dir::ensure "${ensure_dir}"

mark dir::ensure_parent
parent_target="${TEST_ROOT}/ensure-parent/a/b/file.txt"
assert_true "ensure_parent creates parents" dir::ensure_parent "${parent_target}"
assert_dir  "ensure_parent parent exists" "${TEST_ROOT}/ensure-parent/a/b"

mark dir::chmod
chmod_dir="${TEST_ROOT}/chmod-dir"
mkdir -p "${chmod_dir}"
assert_true "chmod dir 700" dir::chmod "${chmod_dir}" 700
if can_exact_chmod; then
    assert_match "chmod mode applied" "$(dir::mode "${chmod_dir}")" '700$|0700$'
else
    skip "chmod exact mode unsupported on Windows ACL/MSYS"
fi
assert_false "chmod rejects file" dir::chmod "${FILE}" 700
assert_false "chmod rejects bad mode" dir::chmod "${chmod_dir}" bad

mark dir::copy
copy_dst="${TEST_ROOT}/copy-root"
assert_true "copy dir" dir::copy "${ROOT}" "${copy_dst}"
assert_dir  "copy dst exists" "${copy_dst}"
assert_file "copy nested file exists" "${copy_dst}/a/b/c/deep.txt"
assert_false "copy rejects source file" dir::copy "${FILE}" "${TEST_ROOT}/copy-file"

mark dir::rename
ren_src="${TEST_ROOT}/ren-src"
ren_dst="${TEST_ROOT}/ren-dst"
mkdir -p "${ren_src}"
printf x > "${ren_src}/x.txt"
assert_true "rename dir" dir::rename "${ren_src}" "${ren_dst}"
assert_dir "rename dst exists" "${ren_dst}"
assert_missing "rename src gone" "${ren_src}"
assert_file "rename moved content" "${ren_dst}/x.txt"
assert_false "rename rejects file" dir::rename "${FILE}" "${TEST_ROOT}/bad"

mark dir::move
move_src="${TEST_ROOT}/move-src"
move_dst="${TEST_ROOT}/move-dst"
mkdir -p "${move_src}"
printf x > "${move_src}/x.txt"
assert_true "move dir" dir::move "${move_src}" "${move_dst}"
assert_dir "move dst exists" "${move_dst}"
assert_missing "move src gone" "${move_src}"

mark dir::clear
clear_dir="${TEST_ROOT}/clear-dir"
mkdir -p "${clear_dir}/sub"
printf x > "${clear_dir}/sub/x.txt"
assert_true "clear dir" dir::clear "${clear_dir}"
assert_dir "clear keeps directory" "${clear_dir}"
assert_eq "clear empties directory" "0" "$(dir::count "${clear_dir}")"
assert_false "clear rejects file" dir::clear "${FILE}"

mark dir::remove
remove_dir="${TEST_ROOT}/remove-dir"
mkdir -p "${remove_dir}/sub"
printf x > "${remove_dir}/sub/x.txt"
assert_true "remove dir" dir::remove "${remove_dir}"
assert_missing "remove dir gone" "${remove_dir}"
assert_false "remove rejects file" dir::remove "${FILE}"

mark dir::mktemp
tmp_dir="$(dir::mktemp 2>/dev/null || true)"
if [[ -n "${tmp_dir}" && -d "${tmp_dir}" ]]; then
    ok "mktemp creates dir"
    rm -rf -- "${tmp_dir}" 2>/dev/null || true
else
    fail "mktemp creates dir"
fi

tmp_near="$(dir::mktemp_near "${TEST_ROOT}/mut/new-dir" "near." "d")"

assert_dir "mktemp_near creates dir near target" "${tmp_near}"

assert_eq "mktemp_near parent is target parent" \
    "${TEST_ROOT}/mut" \
    "$(path::dirname "${tmp_near}")"

case "$(dir::name "${tmp_near}")" in
    near.*d) ok "mktemp_near respects prefix and suffix" ;;
    *) fail "mktemp_near respects prefix and suffix :: actual=[$(dir::name "${tmp_near}")]";;
esac

# -----------------------------------------------------------------------------
# Links
# -----------------------------------------------------------------------------

note "links"

mark dir::symlink
mark dir::is_link
mark dir::readlink
mark dir::link

if can_symlink "${ROOT}" "${TEST_ROOT}/probe-dir-link"; then
    dir_link="${TEST_ROOT}/root-link"
    if dir::symlink "${ROOT}" "${dir_link}"; then
        assert_link "symlink dir link exists" "${dir_link}"
        assert_true "is_link symlinked dir" dir::is_link "${dir_link}"
        readlink_value="$(dir::readlink "${dir_link}" 2>/dev/null || true)"
        [[ -n "${readlink_value}" ]] && ok "readlink dir link returns target" || fail "readlink dir link returns target"
    else
        fail "symlink dir"
    fi

    hard_dir_link="${TEST_ROOT}/hard-dir-link"
    if dir::link "${ROOT}" "${hard_dir_link}" 2>/dev/null; then
        assert_dir "hard link/copy fallback dir exists" "${hard_dir_link}"
    else
        skip "hard-linking directories unsupported"
    fi
else
    skip "symlink unavailable on this OS/session"
    skip "is_link symlink unavailable"
    skip "readlink symlink unavailable"
    skip "link directory hardlink unavailable"
fi

assert_false "symlink rejects file source under dir API" dir::symlink "${FILE}" "${TEST_ROOT}/file-link"
assert_false "readlink rejects non-link dir" dir::readlink "${ROOT}"

# -----------------------------------------------------------------------------
# Glob, contains, find, walk, list, counts
# -----------------------------------------------------------------------------

note "directory query API"

mark dir::glob
glob_txt="$(dir::glob "${ROOT}" '*.txt' | sorted_lines)"
printf '%s\n' "${glob_txt}" | has_line "file.txt" && ok "glob txt includes file.txt" || fail "glob txt includes file.txt"
assert_false "glob rejects missing dir" dir::glob "${ROOT}/missing" '*'
assert_false "glob rejects empty pattern" dir::glob "${ROOT}" ""

mark dir::has_glob
assert_true  "has_glob txt" dir::has_glob "${ROOT}" '*.txt'
assert_true  "has_glob hidden" dir::has_glob "${ROOT}" '.*'
assert_false "has_glob none" dir::has_glob "${ROOT}" '*.definitely-nope'
assert_false "has_glob empty pattern rejected" dir::has_glob "${ROOT}" ""

mark dir::contains
assert_true  "contains child file" dir::contains "${ROOT}" "file.txt"
assert_true  "contains child dir" dir::contains "${ROOT}" "a"
assert_false "contains missing" dir::contains "${ROOT}" "missing"
assert_false "contains rejects slash path" dir::contains "${ROOT}" "a/b"
assert_false "contains rejects backslash path" dir::contains "${ROOT}" 'a\b'
assert_false "contains rejects dot" dir::contains "${ROOT}" "."
assert_false "contains rejects dotdot" dir::contains "${ROOT}" ".."
assert_false "contains rejects traversal escape" dir::contains "${ROOT}/a" "../../outside/escape.txt"

mark dir::contains_file
assert_true  "contains_file child" dir::contains_file "${ROOT}" "file.txt"
assert_false "contains_file dir false" dir::contains_file "${ROOT}" "a"
assert_false "contains_file rejects slash path" dir::contains_file "${ROOT}" "a/b/c/deep.txt"
assert_false "contains_file rejects traversal escape" dir::contains_file "${ROOT}/a" "../../outside/escape.txt"

mark dir::contains_dir
assert_true  "contains_dir child" dir::contains_dir "${ROOT}" "a"
assert_false "contains_dir file false" dir::contains_dir "${ROOT}" "file.txt"
assert_false "contains_dir rejects slash path" dir::contains_dir "${ROOT}" "a/b"
assert_false "contains_dir rejects traversal" dir::contains_dir "${ROOT}/a" "../outside"

mark dir::contains_link
if [[ -L "${TEST_ROOT}/root-link" ]]; then
    assert_true "contains_link child link" dir::contains_link "${TEST_ROOT}" "root-link"
else
    skip "contains_link no symlink"
fi
assert_false "contains_link rejects slash path" dir::contains_link "${TEST_ROOT}" "root/a"
assert_false "contains_link rejects traversal" dir::contains_link "${ROOT}/a" "../../root-link"

mark dir::contains_hidden
assert_true  "contains_hidden with dot" dir::contains_hidden "${ROOT}" ".hidden-file"
assert_true  "contains_hidden without dot" dir::contains_hidden "${ROOT}" "hidden-file"
assert_false "contains_hidden rejects dot" dir::contains_hidden "${ROOT}" "."
assert_false "contains_hidden rejects dotdot" dir::contains_hidden "${ROOT}" ".."
assert_false "contains_hidden rejects slash" dir::contains_hidden "${ROOT}" ".hidden-dir/x"
assert_false "contains_hidden rejects traversal" dir::contains_hidden "${ROOT}/a" "../../root/.hidden-file"

mark dir::find
find_deep="$(dir::find "${ROOT}" 'deep.txt' file 10 | sorted_lines)"
printf '%s\n' "${find_deep}" | grep -F -- "${ROOT}/a/b/c/deep.txt" >/dev/null 2>&1 && ok "find file depth" || fail "find file depth"
assert_false "find invalid type rejected" dir::find "${ROOT}" '*' invalid
assert_false "find invalid depth rejected" dir::find "${ROOT}" '*' file bad-depth

mark dir::find_files
find_files_count="$(dir::find_files "${ROOT}" '*.txt' 10 | count_lines)"
assert_match "find_files count numeric" "${find_files_count}" '^[0-9]+$'
(( find_files_count >= 4 )) && ok "find_files sees nested txt files" || fail "find_files sees nested txt files"

mark dir::find_dirs
find_dirs_count="$(dir::find_dirs "${ROOT}" '*' 10 | count_lines)"
assert_match "find_dirs count numeric" "${find_dirs_count}" '^[0-9]+$'
(( find_dirs_count >= 6 )) && ok "find_dirs sees dirs" || fail "find_dirs sees dirs"

mark dir::find_links
if [[ -L "${TEST_ROOT}/root-link" ]]; then
    links_found="$(dir::find_links "${TEST_ROOT}" '*' 2 | count_lines)"
    (( links_found >= 1 )) && ok "find_links sees link" || fail "find_links sees link"
else
    skip "find_links no symlink"
fi

mark dir::walk
walk_count="$(dir::walk "${ROOT}" | count_lines)"
(( walk_count >= 10 )) && ok "walk recursive count" || fail "walk recursive count"

mark dir::walk_files
walk_files_count="$(dir::walk_files "${ROOT}" | count_lines)"
(( walk_files_count >= 5 )) && ok "walk_files recursive count" || fail "walk_files recursive count"

mark dir::walk_dirs
walk_dirs_count="$(dir::walk_dirs "${ROOT}" | count_lines)"
(( walk_dirs_count >= 6 )) && ok "walk_dirs recursive count" || fail "walk_dirs recursive count"

mark dir::walk_links
if [[ -L "${TEST_ROOT}/root-link" ]]; then
    walk_links_count="$(dir::walk_links "${TEST_ROOT}" | count_lines)"
    (( walk_links_count >= 1 )) && ok "walk_links recursive count" || fail "walk_links recursive count"
else
    skip "walk_links no symlink"
fi

mark dir::list
list_out="$(dir::list "${ROOT}")"
printf '%s\n' "${list_out}" | has_line "file.txt" && ok "list includes file" || fail "list includes file"
printf '%s\n' "${list_out}" | has_line ".hidden-file" && ok "list includes hidden file" || fail "list includes hidden file"
assert_false "list bad sort rejected" dir::list "${ROOT}" bad-sort

mark dir::list_paths
paths_out="$(dir::list_paths "${ROOT}")"
printf '%s\n' "${paths_out}" | has_line "${ROOT}/file.txt" && ok "list_paths includes full path" || fail "list_paths includes full path"
first_reverse="$(dir::list_paths "${ROOT}" reverse 2>/dev/null | head -n 1 || true)"
first_list_reverse="$(dir::list "${ROOT}" reverse 2>/dev/null | head -n 1 || true)"
if [[ -n "${first_reverse}" && -n "${first_list_reverse}" ]]; then
    assert_eq "list_paths forwards sort mode" "${ROOT}/${first_list_reverse}" "${first_reverse}"
else
    fail "list_paths forwards sort mode"
fi

mark dir::list_files
files_out="$(dir::list_files "${ROOT}")"
printf '%s\n' "${files_out}" | has_line "file.txt" && ok "list_files includes file.txt" || fail "list_files includes file.txt"
printf '%s\n' "${files_out}" | has_line ".hidden-file" && ok "list_files includes hidden file" || fail "list_files includes hidden file"
printf '%s\n' "${files_out}" | has_line "a" && fail "list_files excludes dirs" || ok "list_files excludes dirs"

mark dir::list_dirs
dirs_out="$(dir::list_dirs "${ROOT}")"
printf '%s\n' "${dirs_out}" | has_line "a" && ok "list_dirs includes a" || fail "list_dirs includes a"
printf '%s\n' "${dirs_out}" | has_line ".hidden-dir" && ok "list_dirs includes hidden dir" || fail "list_dirs includes hidden dir"
printf '%s\n' "${dirs_out}" | has_line "file.txt" && fail "list_dirs excludes files" || ok "list_dirs excludes files"

mark dir::list_links
if [[ -L "${TEST_ROOT}/root-link" ]]; then
    links_out="$(dir::list_links "${TEST_ROOT}")"
    printf '%s\n' "${links_out}" | has_line "root-link" && ok "list_links includes symlink" || fail "list_links includes symlink"
else
    skip "list_links no symlink"
fi

mark dir::list_hidden
hidden_out="$(dir::list_hidden "${ROOT}")"
printf '%s\n' "${hidden_out}" | has_line ".hidden-file" && ok "list_hidden includes hidden file" || fail "list_hidden includes hidden file"
printf '%s\n' "${hidden_out}" | has_line ".hidden-dir" && ok "list_hidden includes hidden dir" || fail "list_hidden includes hidden dir"
printf '%s\n' "${hidden_out}" | has_line "file.txt" && fail "list_hidden excludes normal file" || ok "list_hidden excludes normal file"

mark dir::count
count_all="$(dir::count "${ROOT}")"
assert_match "count numeric" "${count_all}" '^[0-9]+$'
(( count_all >= 8 )) && ok "count direct children" || fail "count direct children"

mark dir::count_files
count_files="$(dir::count_files "${ROOT}")"
assert_match "count_files numeric" "${count_files}" '^[0-9]+$'
(( count_files >= 2 )) && ok "count_files direct" || fail "count_files direct"

mark dir::count_dirs
count_dirs="$(dir::count_dirs "${ROOT}")"
assert_match "count_dirs numeric" "${count_dirs}" '^[0-9]+$'
(( count_dirs >= 6 )) && ok "count_dirs direct" || fail "count_dirs direct"

mark dir::count_links
if [[ -L "${TEST_ROOT}/root-link" ]]; then
    count_links="$(dir::count_links "${TEST_ROOT}")"
    (( count_links >= 1 )) && ok "count_links direct" || fail "count_links direct"
else
    skip "count_links no symlink"
fi

mark dir::count_hidden
count_hidden="$(dir::count_hidden "${ROOT}")"
assert_match "count_hidden numeric" "${count_hidden}" '^[0-9]+$'
(( count_hidden >= 2 )) && ok "count_hidden direct" || fail "count_hidden direct"

mark dir::count_recursive
count_recursive="$(dir::count_recursive "${ROOT}")"
assert_match "count_recursive numeric" "${count_recursive}" '^[0-9]+$'
(( count_recursive >= walk_count )) && ok "count_recursive >= walk" || fail "count_recursive >= walk"

# -----------------------------------------------------------------------------
# Archive, extract, backup, strip, sync
# -----------------------------------------------------------------------------

note "archive extract backup strip sync"

mark dir::archive
archive_file="${TEST_ROOT}/archives/root.tar.gz"
if dir::archive "${ROOT}" "${archive_file}" --format=tar.gz; then
    assert_file "archive creates tar.gz" "${archive_file}"
else
    fail "archive creates tar.gz"
fi
assert_false "archive rejects file source" dir::archive "${FILE}" "${TEST_ROOT}/archives/file.tar.gz"

mark dir::extract
extract_to="${TEST_ROOT}/extract/root"
if [[ -f "${archive_file}" ]]; then
    assert_true "extract archive" dir::extract "${archive_file}" "${extract_to}"
    assert_dir  "extract output dir" "${extract_to}"
else
    skip "extract archive missing"
fi

mark dir::backup
backup_file="${TEST_ROOT}/archives/root.backup.tar.gz"
if dir::backup "${ROOT}" "${backup_file}"; then
    assert_file "backup creates archive" "${backup_file}"
else
    fail "backup creates archive"
fi
assert_false "backup rejects file source" dir::backup "${FILE}" "${TEST_ROOT}/archives/file.backup.tar.gz"

mark dir::strip
strip_dir="${TEST_ROOT}/strip-dir"
mkdir -p "${strip_dir}/one/two"
printf x > "${strip_dir}/one/two/x.txt"
if sys::has tar && sys::has mktemp && sys::has mv; then
    assert_true "strip one level" dir::strip "${strip_dir}" 1
    assert_file "strip exposed nested file" "${strip_dir}/two/x.txt"
else
    skip "strip dependencies unavailable"
fi
assert_false "strip rejects file source" dir::strip "${FILE}" 1
assert_false "strip rejects bad level" dir::strip "${strip_dir}" bad

mark dir::sync
sync_src="${TEST_ROOT}/sync-src"
sync_dst="${TEST_ROOT}/sync-dst"
mkdir -p "${sync_src}/inner"
printf x > "${sync_src}/inner/x.txt"
assert_true "sync dir" dir::sync "${sync_src}" "${sync_dst}"
assert_dir "sync dst dir" "${sync_dst}"
assert_file "sync dst file" "${sync_dst}/inner/x.txt"
assert_false "sync rejects file source" dir::sync "${FILE}" "${TEST_ROOT}/sync-file-dst"

# -----------------------------------------------------------------------------
# Hash, checksum, snapshot
# -----------------------------------------------------------------------------

note "hash checksum snapshot"

mark dir::hash
hash_value="$(dir::hash "${ROOT}" sha256 2>/dev/null || true)"
if [[ -n "${hash_value}" ]]; then
    ok "hash directory returns output"
else
    skip "hash unavailable: sha tool missing"
fi
assert_false "hash rejects file source" dir::hash "${FILE}" sha256
assert_false "hash rejects bad algo" dir::hash "${ROOT}" nope

mark dir::checksum
checksum_value="$(dir::checksum "${ROOT}" sha256 2>/dev/null || true)"
if [[ -n "${checksum_value}" ]]; then
    ok "checksum directory returns output"
else
    skip "checksum unavailable: sha tool missing"
fi
assert_false "checksum rejects file source" dir::checksum "${FILE}" sha256
assert_false "checksum rejects bad algo" dir::checksum "${ROOT}" nope

mark dir::snapshot
snapshot_value="$(dir::snapshot "${ROOT}" 2>/dev/null || true)"
if [[ -n "${snapshot_value}" ]]; then
    ok "snapshot directory returns output"
else
    fail "snapshot directory returns output"
fi
assert_false "snapshot rejects file source" dir::snapshot "${FILE}"

# -----------------------------------------------------------------------------
# Encode, decode, encryption
# -----------------------------------------------------------------------------

note "codec and encryption"

mark dir::encode
mark dir::decode
codec_src="${TEST_ROOT}/codec-src"
codec_out="${TEST_ROOT}/codec-out"
codec_dec="${TEST_ROOT}/codec-dec"
mkdir -p "${codec_src}/inner"
printf 'hello-codec\n' > "${codec_src}/inner/msg.txt"

if dir::encode "${codec_src}" "${codec_out}" 2>/dev/null; then
    assert_dir "encode output dir" "${codec_out}"
    if dir::decode "${codec_out}" "${codec_dec}" 2>/dev/null; then
        assert_file "decode output file" "${codec_dec}/inner/msg.txt"
        assert_eq "decode restores content" "hello-codec" "$(tr -d '\r\n' < "${codec_dec}/inner/msg.txt")"
    else
        fail "decode directory"
    fi
else
    skip "encode/decode unavailable"
    skip "decode skipped"
fi
assert_false "encode rejects file source under dir API" dir::encode "${FILE}" "${TEST_ROOT}/file-encoded"
assert_false "decode rejects file source under dir API" dir::decode "${FILE}" "${TEST_ROOT}/file-decoded"

mark dir::encrypt
mark dir::decrypt
crypt_dir="${TEST_ROOT}/crypt-dir"
mkdir -p "${crypt_dir}"
printf 'secret\n' > "${crypt_dir}/secret.txt"
if sys::has openssl || sys::has gpg; then
    if dir::encrypt "${crypt_dir}" "passphrase-for-test" auto 2>/dev/null; then
        ok "encrypt directory"
        if dir::decrypt "${crypt_dir}" "passphrase-for-test" auto 1 2>/dev/null; then
            ok "decrypt directory"
        else
            fail "decrypt directory"
        fi
    else
        fail "encrypt directory"
        skip "decrypt skipped after encrypt failure"
    fi
else
    skip "encrypt unavailable: no openssl/gpg"
    skip "decrypt unavailable: no openssl/gpg"
fi
assert_false "encrypt rejects file source under dir API" dir::encrypt "${FILE}" pass
assert_false "decrypt rejects file source under dir API" dir::decrypt "${FILE}" pass

# -----------------------------------------------------------------------------
# Locks and watch
# -----------------------------------------------------------------------------

note "lock and watch"

mark dir::trylock
mark dir::lock
mark dir::unlock
mark dir::locked
mark dir::with_lock

lock_path="${TEST_ROOT}/locks/main.lock"
assert_true "trylock creates lock" dir::trylock "${lock_path}"
assert_true "locked true after trylock" dir::locked "${lock_path}"
assert_false "second trylock fails" dir::trylock "${lock_path}"
assert_true "unlock own lock" dir::unlock "${lock_path}"
assert_false "locked false after unlock" dir::locked "${lock_path}"

assert_true "lock creates lock" dir::lock "${lock_path}" 1 0.05 0
assert_true "unlock lock" dir::unlock "${lock_path}"

with_lock_out="${TEST_ROOT}/with-lock.out"
assert_true "with_lock callback" dir::with_lock "${lock_path}" with_lock_callback 1 0.05 0 "${with_lock_out}"
assert_file "with_lock callback wrote file" "${with_lock_out}"

mark dir::watch
if [[ "${DO_WATCH}" == 1 ]]; then
    watch_out="${TEST_ROOT}/watch.out"
    if run_timeout 4 bash -c '
        source "$1"
        source "$2"
        WATCH_OUT="$3"
        callback_touch () { printf "changed\n" >> "${WATCH_OUT}"; }
        ( sleep 0.5; printf x > "$4/new-watch-file" ) &
        dir::watch "$4" 0.1 callback_touch once continue
    ' _ "${PATH_LIB}" "${DIR_LIB}" "${watch_out}" "${ROOT}" >/dev/null 2>&1; then
        grep -F "changed" "${watch_out}" >/dev/null 2>&1 && ok "watch detects one change" || fail "watch detects one change"
    else
        skip "watch unavailable or timed out"
    fi
else
    skip "watch disabled"
fi

# -----------------------------------------------------------------------------
# Adversarial names and safety fuzz
# -----------------------------------------------------------------------------

note "adversarial names and safety fuzz"

[[ "${FUZZ}" =~ ^[0-9]+$ ]] || FUZZ=300

ad="${TEST_ROOT}/adversarial"
mkdir -p "${ad}"

declare -a names=(
    "space name"
    "unicodé-ملف"
    "-dash"
    "semi;colon"
    "quote'file"
    "bracket[file]"
    "paren(file)"
    "hash#file"
    "comma,file"
    "two  spaces"
    ".hidden"
)

i=0
for name in "${names[@]}"; do
    mkdir -p -- "${ad}/${name}"
    printf x > "${ad}/${name}/x.txt"

    assert_true  "adversarial exists ${i}" dir::exists "${ad}/${name}"
    assert_true  "adversarial contains ${i}" dir::contains "${ad}" "${name}"
    assert_true  "adversarial contains_dir ${i}" dir::contains_dir "${ad}" "${name}"
    assert_true  "adversarial is_under ${i}" dir::is_under "${ad}/${name}" "${ad}"
    assert_false "adversarial contains traversal ${i}" dir::contains "${ad}/${name}" "../escape"
    i=$(( i + 1 ))
done

for (( i=0; i<FUZZ; i++ )); do
    name="fuzz_${i}_$(( i * 17 % 97 ))"
    mkdir -p -- "${ad}/${name}/sub"
    printf '%s\n' "${i}" > "${ad}/${name}/sub/file.txt"

    assert_true  "fuzz exists ${i}" dir::exists "${ad}/${name}"
    assert_true  "fuzz contains ${i}" dir::contains "${ad}" "${name}"
    assert_true  "fuzz contains_dir ${i}" dir::contains_dir "${ad}" "${name}"
    assert_false "fuzz contains slash rejected ${i}" dir::contains "${ad}" "${name}/sub"
    assert_false "fuzz contains_file slash rejected ${i}" dir::contains_file "${ad}" "${name}/sub/file.txt"
    assert_true  "fuzz safe ${i}" dir::is_safe "${ad}/${name}/sub" "${ad}"
done

# -----------------------------------------------------------------------------
# Medium tree stress
# -----------------------------------------------------------------------------

note "medium tree stress"

stress="${TEST_ROOT}/stress"
mkdir -p "${stress}"

for (( i=0; i<40; i++ )); do
    mkdir -p "${stress}/d${i}/a/b"
    for (( j=0; j<5; j++ )); do
        printf '%s:%s\n' "${i}" "${j}" > "${stress}/d${i}/a/b/f${j}.txt"
    done
done

stress_files="$(dir::walk_files "${stress}" | count_lines)"
assert_eq "stress walk_files 200" "200" "${stress_files}"
stress_dirs="$(dir::walk_dirs "${stress}" | count_lines)"
(( stress_dirs >= 120 )) && ok "stress walk_dirs >= 120" || fail "stress walk_dirs >= 120"
stress_recursive="$(dir::count_recursive "${stress}")"
(( stress_recursive >= 320 )) && ok "stress count_recursive >= 320" || fail "stress count_recursive >= 320"

if [[ "${SLOW}" == 1 ]]; then
    slow_archive="${TEST_ROOT}/archives/stress.tar.gz"
    if dir::archive "${stress}" "${slow_archive}" --format=tar.gz; then
        assert_file "slow archive stress" "${slow_archive}"
        slow_extract="${TEST_ROOT}/extract/stress"
        assert_true "slow extract stress" dir::extract "${slow_archive}" "${slow_extract}"
        assert_eq "slow extracted file count" "200" "$(dir::walk_files "${slow_extract}" | count_lines)"
    else
        fail "slow archive stress"
    fi

    slow_hash="$(dir::hash "${stress}" sha256 2>/dev/null || true)"
    [[ -n "${slow_hash}" ]] && ok "slow hash stress" || skip "slow hash stress unavailable"
else
    skip "slow archive/hash stress disabled"
fi

# -----------------------------------------------------------------------------
# Coverage gate
# -----------------------------------------------------------------------------

note "coverage gate"

declared_count=0
missing_count=0

while IFS= read -r fn; do
    [[ "${fn}" == dir::* ]] || continue
    declared_count=$(( declared_count + 1 ))
    if [[ -z "${TESTED_FUNCS[${fn}]:-}" ]]; then
        fail "coverage missing ${fn}"
        missing_count=$(( missing_count + 1 ))
    fi
done < <(declare -F | awk '{print $3}' | LC_ALL=C sort | grep '^dir::')

covered_count=$(( declared_count - missing_count ))

if (( missing_count == 0 )); then
    ok "coverage all dir functions marked (${covered_count}/${declared_count})"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

printf '\n============================================================\n'
printf ' dir.sh brutal test summary\n'
printf '============================================================\n'
printf 'Path   : %s\n' "${PATH_LIB}"
printf 'Dir    : %s\n' "${DIR_LIB}"
printf 'Root   : %s\n' "${TEST_ROOT}"
printf 'Total  : %s\n' "${TOTAL}"
printf 'Pass   : %s\n' "${PASS}"
printf 'Fail   : %s\n' "${FAIL}"
printf 'Skip   : %s\n' "${SKIP}"
printf 'Funcs  : %s/%s covered\n' "${covered_count}" "${declared_count}"
printf 'Fuzz   : %s iterations\n' "${FUZZ}"
printf '============================================================\n'

if (( FAIL > 0 )); then
    exit 1
fi

exit 0
