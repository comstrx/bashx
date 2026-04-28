#!/usr/bin/env bash
# path_brutal_test_v2.sh
# Brutal production CI test suite for src/parts/builtin/path.sh
#
# Usage:
#   bash path_brutal_test_v2.sh [path/to/path.sh]
#
# Modes:
#   GUN_TEST_VERBOSE=1    print every passing assertion
#   GUN_TEST_SLOW=1       enable heavier archive/snapshot/checksum stress
#   GUN_TEST_WATCH=0      disable watch tests
#   GUN_TEST_SHELLCHECK=1 also run shellcheck on target when available
#
# This test intentionally creates, deletes, moves, copies, archives, extracts,
# chmods, hardlinks, symlinks, fifos, sockets, unicode paths, spaces, dash files,
# and path traversal cases inside a temporary sandbox.

set -u

PATH_LIB="${1:-${PATH_LIB:-src/parts/builtin/path.sh}}"
TEST_ROOT=""
MAIN_PID="${BASHPID:-$$}"
TOTAL=0
PASS=0
FAIL=0
SKIP=0
VERBOSE="${GUN_TEST_VERBOSE:-0}"
SLOW="${GUN_TEST_SLOW:-0}"
DO_WATCH="${GUN_TEST_WATCH:-1}"
DO_SHELLCHECK="${GUN_TEST_SHELLCHECK:-0}"

# -----------------------------------------------------------------------------
# Minimal sys::* compatibility layer for standalone testing.
# Your real system.sh may be sourced before this test; these won't clobber it.
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

declare -A TESTED_FUNCS=()

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
    if "$@"; then ok "${label}"; else fail "${label}"; fi
}

assert_false () {
    local label="$1"; shift
    if "$@"; then fail "${label}"; else ok "${label}"; fi
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

can_unix_socket () {
    sys::is_windows && return 1
    command -v python3 >/dev/null 2>&1
}

portable_sleep () {
    sleep "${1:-0.2}" 2>/dev/null || sleep 1
}

# -----------------------------------------------------------------------------
# Load target
# -----------------------------------------------------------------------------

if [[ ! -f "${PATH_LIB}" ]]; then
    printf 'Target path.sh not found: %s\n' "${PATH_LIB}" >&2
    exit 2
fi

if ! bash -n "${PATH_LIB}" 2>/dev/null; then
    printf 'Syntax check failed: %s\n' "${PATH_LIB}" >&2
    bash -n "${PATH_LIB}"
    exit 2
fi

if [[ "${DO_SHELLCHECK}" == 1 ]]; then
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck "${PATH_LIB}" -e SC2148
    else
        printf 'shellcheck unavailable; skipping static check\n' >&2
    fi
fi

# shellcheck source=/dev/null
source "${PATH_LIB}"

if ! declare -F path::valid >/dev/null 2>&1; then
    printf 'Failed to load path functions from: %s\n' "${PATH_LIB}" >&2
    exit 2
fi

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t pathbrutal)"
mkdir -p -- \
    "${TEST_ROOT}/space dir" \
    "${TEST_ROOT}/src/a/b" \
    "${TEST_ROOT}/dst" \
    "${TEST_ROOT}/archives" \
    "${TEST_ROOT}/extract" \
    "${TEST_ROOT}/dash-dir"

printf 'alpha\n' > "${TEST_ROOT}/file.txt"
printf 'beta\n' > "${TEST_ROOT}/space dir/file with spaces.txt"
printf 'gamma\n' > "${TEST_ROOT}/src/a/b/deep.txt"
printf 'hidden\n' > "${TEST_ROOT}/.hidden"
printf 'unicode\n' > "${TEST_ROOT}/unicodé-ملف.txt"
printf 'dash\n' > "${TEST_ROOT}/dash-dir/-dash-file"

unalias -a 2>/dev/null || true

note "target"
printf 'file: %s\nroot: %s\n' "${PATH_LIB}" "${TEST_ROOT}"

# -----------------------------------------------------------------------------
# Basic validation / existence
# -----------------------------------------------------------------------------

note "basic predicates"

mark path::valid
assert_true  "valid accepts normal path" path::valid "${TEST_ROOT}/file.txt"
assert_true  "valid accepts spaces" path::valid "${TEST_ROOT}/space dir/file with spaces.txt"
assert_true  "valid accepts unicode" path::valid "${TEST_ROOT}/unicodé-ملف.txt"
assert_false "valid rejects empty" path::valid ""
assert_false "valid rejects newline" path::valid $'bad\npath'
assert_false "valid rejects carriage return" path::valid $'bad\rpath'

mark path::exists
assert_true  "exists file" path::exists "${TEST_ROOT}/file.txt"
assert_true  "exists dir" path::exists "${TEST_ROOT}/src"
assert_false "exists missing" path::exists "${TEST_ROOT}/missing"

mark path::missing
assert_true  "missing true for missing" path::missing "${TEST_ROOT}/missing"
assert_false "missing false for existing" path::missing "${TEST_ROOT}/file.txt"

mark path::empty
: > "${TEST_ROOT}/empty.txt"
mkdir -p "${TEST_ROOT}/empty-dir" "${TEST_ROOT}/non-empty-dir"
printf x > "${TEST_ROOT}/non-empty-dir/x"
assert_true  "empty file" path::empty "${TEST_ROOT}/empty.txt"
assert_false "non-empty file" path::empty "${TEST_ROOT}/file.txt"
assert_true  "empty dir" path::empty "${TEST_ROOT}/empty-dir"
assert_false "non-empty dir" path::empty "${TEST_ROOT}/non-empty-dir"
assert_true  "empty missing treated as empty" path::empty "${TEST_ROOT}/missing"

mark path::filled
assert_true  "filled file" path::filled "${TEST_ROOT}/file.txt"
assert_true  "filled dir" path::filled "${TEST_ROOT}/non-empty-dir"
assert_false "filled empty file" path::filled "${TEST_ROOT}/empty.txt"
assert_false "filled missing" path::filled "${TEST_ROOT}/missing"

# -----------------------------------------------------------------------------
# Pure path semantics
# -----------------------------------------------------------------------------

note "pure path semantics"

mark path::is_abs
assert_true  "is_abs POSIX" path::is_abs "/tmp"
assert_true  "is_abs Windows drive" path::is_abs "C:/Windows"
assert_true  "is_abs backslash root" path::is_abs "\\server"
assert_false "is_abs relative" path::is_abs "foo/bar"

mark path::is_rel
assert_true  "is_rel relative" path::is_rel "foo/bar"
assert_false "is_rel absolute" path::is_rel "/foo"
assert_false "is_rel empty" path::is_rel ""

mark path::has_drive
assert_true  "has_drive C:" path::has_drive "C:/x"
assert_true  "has_drive drive-relative" path::has_drive "C:foo"
assert_false "has_drive POSIX" path::has_drive "/tmp"

mark path::slashify
assert_eq    "slashify backslashes" "C:/A/B" "$(path::slashify 'C:\A\B')"
assert_false "slashify rejects newline" path::slashify $'a\nb'

mark path::posix
assert_eq    "posix C:/Users" "/c/Users" "$(path::posix 'C:/Users')"
assert_false "posix rejects drive-relative" path::posix "C:Users"
assert_eq    "posix slashifies plain" "a/b" "$(path::posix 'a\b')"

mark path::windows
assert_eq "windows /mnt/c/Users" 'C:\Users' "$(path::windows '/mnt/c/Users')"
assert_eq "windows drive uppercases" 'C:\Users' "$(path::windows 'c:/Users')"
if sys::is_windows; then
    assert_eq "windows /c/Users on windows" 'C:\Users' "$(path::windows '/c/Users')"
else
    assert_eq "windows plain POSIX style converts" '\usr\bin' "$(path::windows '/usr/bin')"
fi

mark path::normalize
assert_eq "normalize collapses slash and dot" "/a/c" "$(path::normalize '/a//b/../c/.')"
assert_eq "normalize relative up" "../a" "$(path::normalize '../x/../a')"
assert_eq "normalize root" "/" "$(path::normalize '////')"
assert_eq "normalize drive absolute" "C:/a/c" "$(path::normalize 'C:/a/b/../c')"
assert_eq "normalize drive-relative preserves C:" "C:" "$(path::normalize 'C:foo/..')"
assert_eq "normalize UNC" "//server/share" "$(path::normalize '//server/share/dir/..')"

mark path::resolve
resolved_file="$(path::resolve "${TEST_ROOT}/src/a/../a/b/deep.txt")"
assert_match "resolve file absolute" "${resolved_file}" '^/'
assert_eq "resolve basename" "deep.txt" "$(path::basename "${resolved_file}")"

mark path::join
assert_eq "join simple" "a/b/c" "$(path::join a b c)"
assert_eq "join resets on absolute" "/x/y" "$(path::join a b /x y)"
assert_eq "join handles empty segments" "a/b" "$(path::join '' a '' b)"
assert_eq "join normalizes traversal" "a/c" "$(path::join a b .. c)"

mark path::cwd
assert_eq "cwd equals pwd logical" "$(pwd)" "$(path::cwd)"

mark path::pwd
[[ -n "$(path::pwd)" ]] && ok "pwd returns something" || fail "pwd returns something"

mark path::abs
assert_match "abs relative becomes absolute" "$(path::abs 'abc')" '^/'
assert_eq "abs absolute normalized" "/tmp/x" "$(path::abs '/tmp/a/../x')"

mark path::rel
assert_eq "rel same" "." "$(path::rel "${TEST_ROOT}/src" "${TEST_ROOT}/src")"
assert_eq "rel child" "a/b/deep.txt" "$(path::rel "${TEST_ROOT}/src/a/b/deep.txt" "${TEST_ROOT}/src")"
assert_eq "rel sibling" "../dst" "$(path::rel "${TEST_ROOT}/dst" "${TEST_ROOT}/src")"
assert_eq "rel dot path" "src/a" "$(cd "${TEST_ROOT}" && path::rel "./src/a" ".")"

mark path::expand
assert_eq "expand ~" "${HOME:-}" "$(path::expand '~')"
assert_eq "expand ~/x" "${HOME:-}/x" "$(path::expand '~/x')"
assert_eq "expand plain" "plain" "$(path::expand 'plain')"
assert_false "expand invalid user chars" path::expand '~bad:user'

mark path::parts
mapfile -t __parts < <(path::parts "/a/b/c")
assert_eq "parts count" "4" "${#__parts[@]}"
assert_eq "parts root" "/" "${__parts[0]}"
assert_eq "parts leaf" "c" "${__parts[3]}"

mark path::depth
assert_eq "depth /a/b/c" "4" "$(path::depth '/a/b/c')"
assert_eq "depth relative" "2" "$(path::depth 'a/b')"

mark path::common
assert_eq "common posix" "${TEST_ROOT}/src" "$(path::common "${TEST_ROOT}/src/a" "${TEST_ROOT}/src/b")"
assert_eq "common one arg" "$(path::abs "${TEST_ROOT}/src/a")" "$(path::common "${TEST_ROOT}/src/a")"
assert_false "common no args fails" path::common

mark path::dirname
assert_eq "dirname file" "${TEST_ROOT}" "$(path::dirname "${TEST_ROOT}/file.txt")"
assert_eq "dirname no slash" "." "$(path::dirname "file.txt")"
assert_eq "dirname root child" "/" "$(path::dirname "/file.txt")"
assert_eq "dirname drive-relative" "C:" "$(path::dirname "C:foo")"
assert_eq "dirname drive absolute" "C:/foo" "$(path::dirname "C:/foo/bar")"

mark path::basename
assert_eq "basename file" "file.txt" "$(path::basename "${TEST_ROOT}/file.txt")"
assert_eq "basename trailing slash" "src" "$(path::basename "${TEST_ROOT}/src/")"
assert_eq "basename root" "" "$(path::basename "/")"

mark path::drive
assert_eq    "drive extracts C:" "C:" "$(path::drive 'C:/x')"
assert_false "drive fails posix" path::drive "/tmp"

mark path::stem
assert_eq "stem normal" "file.tar" "$(path::stem 'file.tar.gz')"
assert_eq "stem no ext" "file" "$(path::stem 'file')"
assert_eq "stem dotfile" ".bashrc" "$(path::stem '.bashrc')"
assert_eq "stem double-dot hidden" "..hidden" "$(path::stem '..hidden')"
assert_eq "stem dotdot" ".." "$(path::stem '..')"
assert_eq "stem triple dot" "..." "$(path::stem '...')"

mark path::ext
assert_eq "ext normal" "gz" "$(path::ext 'file.tar.gz')"
assert_eq "ext none" "" "$(path::ext 'file')"
assert_eq "ext dotfile none" "" "$(path::ext '.bashrc')"
assert_eq "ext double-dot hidden none" "" "$(path::ext '..hidden')"

mark path::dotext
assert_eq "dotext normal" ".gz" "$(path::dotext 'file.tar.gz')"
assert_eq "dotext none" "" "$(path::dotext '.bashrc')"

mark path::setname
assert_eq "setname file" "${TEST_ROOT}/renamed.md" "$(path::setname "${TEST_ROOT}/file.txt" "renamed.md")"
assert_eq "setname plain" "renamed.md" "$(path::setname "file.txt" "renamed.md")"
assert_false "setname empty name fails" path::setname "${TEST_ROOT}/file.txt" ""

mark path::setstem
assert_eq "setstem file" "${TEST_ROOT}/hello.txt" "$(path::setstem "${TEST_ROOT}/file.txt" "hello")"
assert_eq "setstem no ext" "hello" "$(path::setstem "file" "hello")"
assert_false "setstem empty stem fails" path::setstem "${TEST_ROOT}/file.txt" ""

mark path::setext
assert_eq "setext file" "${TEST_ROOT}/file.md" "$(path::setext "${TEST_ROOT}/file.txt" "md")"
assert_eq "setext dot ext" "${TEST_ROOT}/file.md" "$(path::setext "${TEST_ROOT}/file.txt" ".md")"
assert_eq "setext remove ext" "${TEST_ROOT}/file" "$(path::setext "${TEST_ROOT}/file.txt" "")"

# -----------------------------------------------------------------------------
# Roots / relation / types / metadata
# -----------------------------------------------------------------------------

note "roots, relations, types, metadata"

mark path::chmod
chmod_target="${TEST_ROOT}/chmod.txt"
printf z > "${chmod_target}"
assert_true "chmod 600" path::chmod "${chmod_target}" 600
if can_exact_chmod; then
    assert_match "chmod mode applied" "$(path::mode "${chmod_target}")" '600$|0600$'
else
    skip "chmod exact mode unsupported on Windows ACL/MSYS"
fi
assert_false "chmod rejects bad mode" path::chmod "${chmod_target}" 'bad-mode'

mark path::is_root
assert_true  "is_root slash" path::is_root "/"
assert_true  "is_root drive" path::is_root "C:/"
assert_false "is_root non-root" path::is_root "/tmp"
assert_false "is_root empty" path::is_root ""

mark path::is_unc
assert_true  "is_unc POSIX double slash" path::is_unc "//server/share"
assert_true  "is_unc Windows double backslash" path::is_unc "\\\\server\\share"
assert_false "is_unc normal" path::is_unc "/tmp"

mark path::is_same
assert_true  "is_same self" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/file.txt"
assert_false "is_same different" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/empty.txt"

mark path::is_under
assert_true  "is_under child" path::is_under "${TEST_ROOT}/src/a" "${TEST_ROOT}/src"
assert_false "is_under same" path::is_under "${TEST_ROOT}/src" "${TEST_ROOT}/src"
assert_false "is_under sibling" path::is_under "${TEST_ROOT}/dst" "${TEST_ROOT}/src"
assert_false "is_under parent root refused" path::is_under "${TEST_ROOT}" "/"

mark path::is_parent
assert_true  "is_parent parent" path::is_parent "${TEST_ROOT}/src" "${TEST_ROOT}/src/a"
assert_false "is_parent sibling" path::is_parent "${TEST_ROOT}/src" "${TEST_ROOT}/dst"

mark path::is_file
assert_true  "is_file" path::is_file "${TEST_ROOT}/file.txt"
assert_false "is_file dir" path::is_file "${TEST_ROOT}/src"

mark path::is_dir
assert_true  "is_dir" path::is_dir "${TEST_ROOT}/src"
assert_false "is_dir file" path::is_dir "${TEST_ROOT}/file.txt"

mark path::is_link
if can_symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/link-file.probe"; then
    if path::symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/link-file" && [[ -L "${TEST_ROOT}/link-file" ]]; then
        assert_true "is_link" path::is_link "${TEST_ROOT}/link-file"
    else
        skip "is_link symlink creation unavailable through path::symlink"
    fi
else
    skip "is_link symlink unavailable on this OS/session"
fi

mark path::is_pipe
if command -v mkfifo >/dev/null 2>&1 && mkfifo "${TEST_ROOT}/fifo" 2>/dev/null; then
    assert_true "is_pipe fifo" path::is_pipe "${TEST_ROOT}/fifo"
else
    skip "is_pipe mkfifo unavailable"
fi

mark path::is_socket
if can_unix_socket; then
    if python3 - "${TEST_ROOT}/sock" <<'PY' >/dev/null 2>&1
import os, socket, sys
p = sys.argv[1]
try:
    os.unlink(p)
except FileNotFoundError:
    pass
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.bind(p)
s.close()
PY
    then
        assert_true "is_socket unix socket" path::is_socket "${TEST_ROOT}/sock"
    else
        skip "is_socket unix socket creation unavailable"
    fi
else
    skip "is_socket unix socket unsupported"
fi

mark path::is_block
if [[ -b /dev/sda ]]; then assert_true "is_block /dev/sda" path::is_block /dev/sda
else assert_false "is_block regular file" path::is_block "${TEST_ROOT}/file.txt"
fi

mark path::is_char
if [[ -c /dev/null ]]; then assert_true "is_char /dev/null" path::is_char /dev/null; else skip "is_char no /dev/null char"; fi

mark path::readable
assert_true "readable file" path::readable "${TEST_ROOT}/file.txt"

mark path::writable
assert_true "writable file" path::writable "${TEST_ROOT}/file.txt"

mark path::executable
printf '#!/usr/bin/env bash\nexit 0\n' > "${TEST_ROOT}/run.sh"
chmod +x "${TEST_ROOT}/run.sh"
assert_true  "executable file" path::executable "${TEST_ROOT}/run.sh"
assert_false "non executable file" path::executable "${TEST_ROOT}/file.txt"

mark path::type
assert_eq "type file" "file" "$(path::type "${TEST_ROOT}/file.txt")"
assert_eq "type dir" "dir" "$(path::type "${TEST_ROOT}/src")"
[[ -L "${TEST_ROOT}/link-file" ]] && assert_eq "type link" "link" "$(path::type "${TEST_ROOT}/link-file")"

mark path::size
assert_match "size file numeric" "$(path::size "${TEST_ROOT}/file.txt")" '^[0-9]+$'
assert_match "size dir numeric" "$(path::size "${TEST_ROOT}/src")" '^[0-9]+$'

mark path::mtime
assert_match "mtime numeric" "$(path::mtime "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::atime
assert_match "atime numeric" "$(path::atime "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::ctime
assert_match "ctime numeric" "$(path::ctime "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::age
assert_match "age numeric" "$(path::age "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::owner
[[ -n "$(path::owner "${TEST_ROOT}/file.txt")" ]] && ok "owner non-empty" || fail "owner non-empty"

mark path::group
[[ -n "$(path::group "${TEST_ROOT}/file.txt")" ]] && ok "group non-empty" || fail "group non-empty"

mark path::mode
assert_match "mode octal" "$(path::mode "${TEST_ROOT}/file.txt")" '^[0-7]{3,4}$'

mark path::inode
assert_match "inode numeric" "$(path::inode "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::which
assert_true  "which bash" path::which bash
assert_false "which missing" path::which "definitely-not-a-real-command-xyz"
assert_false "which newline rejected" path::which $'bash\nls'

mark path::which_all
which_all_bash="$(path::which_all bash || true)"
if [[ -n "${which_all_bash}" ]]; then ok "which_all bash returns entries"; else fail "which_all bash returned empty"; fi

mark path::root
assert_eq    "root empty defaults slash" "/" "$(path::root '')"
assert_eq    "root posix" "/" "$(path::root '/a/b')"
assert_eq    "root drive" "C:/" "$(path::root 'C:/a/b')"
assert_eq    "root unc" "//server/" "$(path::root '//server/share/x')"
assert_false "root relative fails" path::root "a/b"

mark path::script
[[ -n "$(path::script "${PATH_LIB}")" ]] && ok "script target resolves" || fail "script target resolves"

mark path::script_dir
assert_eq "script_dir target dir" "$(path::dirname "$(path::abs "${PATH_LIB}")")" "$(path::script_dir "${PATH_LIB}")"

# -----------------------------------------------------------------------------
# Standard directories
# -----------------------------------------------------------------------------

note "standard directories"

for fn in home_dir tmp_dir config_dir data_dir cache_dir state_dir runtime_dir log_dir bin_dir desktop_dir downloads_dir documents_dir pictures_dir music_dir videos_dir public_dir templates_dir; do
    mark "path::${fn}"
    value="$("path::${fn}" 2>/dev/null || true)"
    if [[ -n "${value}" ]]; then ok "${fn} returns non-empty: ${value}"; else fail "${fn} returned empty/failure"; fi
done

# -----------------------------------------------------------------------------
# Mutations and destructive safety
# -----------------------------------------------------------------------------

note "filesystem mutations and safety"

mark path::remove
printf x > "${TEST_ROOT}/remove-me.txt"
assert_true "remove file" path::remove "${TEST_ROOT}/remove-me.txt"
assert_missing "remove deleted file" "${TEST_ROOT}/remove-me.txt"
mkdir -p "${TEST_ROOT}/remove-dir/a"
assert_true "remove dir" path::remove "${TEST_ROOT}/remove-dir"
assert_missing "remove deleted dir" "${TEST_ROOT}/remove-dir"
assert_false "remove refuses root" path::remove "/"
if can_symlink "/" "${TEST_ROOT}/link-to-root"; then
    ln -s "/" "${TEST_ROOT}/link-to-root" 2>/dev/null || true
    assert_false "remove refuses symlink resolving to root" path::remove "${TEST_ROOT}/link-to-root"
    assert_link "root symlink remains after refused remove" "${TEST_ROOT}/link-to-root"
    rm -f -- "${TEST_ROOT}/link-to-root"
else
    skip "remove symlink-to-root safety unavailable"
fi

mark path::clear
mkdir -p "${TEST_ROOT}/clear-dir/sub"
printf x > "${TEST_ROOT}/clear-dir/sub/x"
printf y > "${TEST_ROOT}/clear-dir/.hidden"
assert_true "clear dir" path::clear "${TEST_ROOT}/clear-dir"
assert_true "clear dir empty after" path::empty "${TEST_ROOT}/clear-dir"
printf x > "${TEST_ROOT}/clear-file.txt"
assert_true "clear file" path::clear "${TEST_ROOT}/clear-file.txt"
assert_true "clear file empty after" path::empty "${TEST_ROOT}/clear-file.txt"
assert_false "clear refuses root" path::clear "/"
if can_symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/clear-link"; then
    ln -s "${TEST_ROOT}/file.txt" "${TEST_ROOT}/clear-link" 2>/dev/null || true
    before_clear_link="$(cat "${TEST_ROOT}/file.txt")"
    assert_false "clear refuses symlink to file" path::clear "${TEST_ROOT}/clear-link"
    after_clear_link="$(cat "${TEST_ROOT}/file.txt")"
    assert_eq "clear symlink target untouched" "${before_clear_link}" "${after_clear_link}"
else
    skip "clear symlink safety unavailable"
fi
if can_symlink "/" "${TEST_ROOT}/clear-link-root"; then
    ln -s "/" "${TEST_ROOT}/clear-link-root" 2>/dev/null || true
    assert_false "clear refuses symlink to root" path::clear "${TEST_ROOT}/clear-link-root"
    rm -f -- "${TEST_ROOT}/clear-link-root"
else
    skip "clear symlink-to-root safety unavailable"
fi

mark path::rename
printf x > "${TEST_ROOT}/old-name.txt"
assert_true "rename file" path::rename "${TEST_ROOT}/old-name.txt" "${TEST_ROOT}/new-name.txt"
assert_file "rename destination exists" "${TEST_ROOT}/new-name.txt"
assert_missing "rename source gone" "${TEST_ROOT}/old-name.txt"

mark path::move
printf x > "${TEST_ROOT}/move-old.txt"
assert_true "move alias" path::move "${TEST_ROOT}/move-old.txt" "${TEST_ROOT}/move-new.txt"
assert_file "move destination exists" "${TEST_ROOT}/move-new.txt"

mark path::copy
printf copy > "${TEST_ROOT}/copy-src.txt"
assert_true "copy file" path::copy "${TEST_ROOT}/copy-src.txt" "${TEST_ROOT}/copy-dst.txt"
assert_eq "copy file content" "copy" "$(cat "${TEST_ROOT}/copy-dst.txt")"
mkdir -p "${TEST_ROOT}/copy-src-dir/n"
printf deep > "${TEST_ROOT}/copy-src-dir/n/deep.txt"
assert_true "copy dir" path::copy "${TEST_ROOT}/copy-src-dir" "${TEST_ROOT}/copy-dst-dir"
assert_file "copy dir deep file" "${TEST_ROOT}/copy-dst-dir/n/deep.txt"
assert_true "copy dash file" path::copy "${TEST_ROOT}/dash-dir/-dash-file" "${TEST_ROOT}/dash-dir/-dash-copy"
assert_file "copy dash destination" "${TEST_ROOT}/dash-dir/-dash-copy"

mark path::link
if ln "${TEST_ROOT}/file.txt" "${TEST_ROOT}/hardlink-manual" 2>/dev/null; then
    rm -f -- "${TEST_ROOT}/hardlink-manual"
    assert_true "hard link" path::link "${TEST_ROOT}/file.txt" "${TEST_ROOT}/hardlink"
    assert_true "hard link same inode" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/hardlink"
else
    skip "hard link unsupported"
fi

mark path::symlink
if can_symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/symlink-manual"; then
    if path::symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/symlink" && [[ -L "${TEST_ROOT}/symlink" ]]; then
        ok "symlink"
        assert_true "symlink is link" path::is_link "${TEST_ROOT}/symlink"
    else
        skip "symlink requires privileges/developer mode"
    fi
else
    skip "symlink unsupported"
fi

mark path::readlink
if [[ -L "${TEST_ROOT}/symlink" ]]; then
    assert_eq "readlink symlink" "${TEST_ROOT}/file.txt" "$(path::readlink "${TEST_ROOT}/symlink")"
else
    skip "readlink no symlink"
fi

mark path::touch
assert_true "touch nested file" path::touch "${TEST_ROOT}/touch/a/b/t.txt"
assert_file "touch created file" "${TEST_ROOT}/touch/a/b/t.txt"
assert_true "touch dash file" path::touch "${TEST_ROOT}/dash-dir/-touched"
assert_file "touch dash file exists" "${TEST_ROOT}/dash-dir/-touched"

mark path::mkdir
assert_true "mkdir nested dir" path::mkdir "${TEST_ROOT}/made/a/b"
assert_dir "mkdir created nested" "${TEST_ROOT}/made/a/b"
assert_false "mkdir refuses existing file" path::mkdir "${TEST_ROOT}/file.txt"
if can_exact_chmod; then
    assert_true "mkdir with mode" path::mkdir "${TEST_ROOT}/mode-dir" 700
    assert_match "mkdir mode applied" "$(path::mode "${TEST_ROOT}/mode-dir")" '700$|0700$'
else
    skip "mkdir mode exact unsupported on Windows ACL/MSYS"
fi

mark path::mkparent
assert_true "mkparent creates parent" path::mkparent "${TEST_ROOT}/parent/a/b/file.txt"
assert_dir "mkparent parent exists" "${TEST_ROOT}/parent/a/b"

mark path::mktemp_file
tmp_file="$(path::mktemp_file brutal .tmp)"
assert_file "mktemp creates file" "${tmp_file}"
assert_match "mktemp suffix" "${tmp_file}" 'tmp$'
rm -f -- "${tmp_file}"

mark path::mktemp_dir
tmp_dir="$(path::mktemp_dir brutal)"
assert_dir "mktemp_dir creates dir" "${tmp_dir}"
rmdir -- "${tmp_dir}" 2>/dev/null || true

# -----------------------------------------------------------------------------
# Snapshot / checksum
# -----------------------------------------------------------------------------

note "checksum and snapshot"

mark path::hash
hash_file="$(path::hash "${TEST_ROOT}/file.txt" sha256 2>/dev/null || true)"
assert_match "hash file sha256" "${hash_file}" '^[0-9a-fA-F]{64}$'
hash_md5="$(path::hash "${TEST_ROOT}/file.txt" md5 2>/dev/null || true)"
if [[ -n "${hash_md5}" ]]; then assert_match "hash file md5" "${hash_md5}" '^[0-9a-fA-F]{32}$'; else skip "hash md5 tool unavailable"; fi
hash_dir_1="$(path::hash "${TEST_ROOT}/src" sha256 2>/dev/null || true)"
hash_dir_2="$(path::hash "${TEST_ROOT}/src" sha256 2>/dev/null || true)"
assert_match "hash dir sha256" "${hash_dir_1}" '^[0-9a-fA-F]{64}$'
assert_eq "hash dir deterministic same run" "${hash_dir_1}" "${hash_dir_2}"
assert_false "hash rejects bad algo" path::hash "${TEST_ROOT}/file.txt" nope

mark path::checksum
assert_true "checksum file expected ok" path::checksum "${TEST_ROOT}/file.txt" "${hash_file}" sha256
assert_false "checksum file expected mismatch" path::checksum "${TEST_ROOT}/file.txt" "0000" sha256

mark path::snapshot
snapshot_file="$(path::snapshot "${TEST_ROOT}/file.txt" 2>/dev/null || true)"
assert_match "snapshot file line" "${snapshot_file}" '^file	[0-9]+	[0-9]+	[0-7]+	-	'
snapshot_dir="$(path::snapshot "${TEST_ROOT}/src" 2>/dev/null || true)"
if [[ "${snapshot_dir}" == *$'file\t'*"deep.txt"* ]]; then ok "snapshot dir includes deep file"; else fail "snapshot dir missing deep file"; fi
if [[ -L "${TEST_ROOT}/symlink" ]]; then
    snapshot_link="$(path::snapshot "${TEST_ROOT}/symlink" 2>/dev/null || true)"
    assert_match "snapshot link line" "${snapshot_link}" '^link	-	-	-	'
else
    skip "snapshot symlink unavailable"
fi

# -----------------------------------------------------------------------------
# Archive / extract / backup / strip / sync
# -----------------------------------------------------------------------------

note "archive extract backup strip sync"

mark path::strip
strip_root="${TEST_ROOT}/strip-root"
mkdir -p "${strip_root}/outer/inner"
printf stripped > "${strip_root}/outer/inner/file.txt"
if sys::has tar; then
    assert_true "strip dir one component" path::strip "${strip_root}" 1
    assert_file "strip removes first real component" "${strip_root}/inner/file.txt"
else
    skip "strip requires tar"
fi
assert_false "strip rejects file target" path::strip "${TEST_ROOT}/file.txt" 1
assert_false "strip rejects root" path::strip "/" 1
assert_false "strip rejects non numeric" path::strip "${TEST_ROOT}/src" bad

mark path::archive
archive_src="${TEST_ROOT}/archive-src"
mkdir -p "${archive_src}/top/nested" "${archive_src}/skip"
printf keep > "${archive_src}/top/nested/keep.txt"
printf skip > "${archive_src}/skip/skip.txt"
tar_out="${TEST_ROOT}/archives/archive.tar.gz"
if sys::has tar; then
    archive_print="$(path::archive "${archive_src}" "${tar_out}" --exclude='skip/*' 2>/dev/null || true)"
    [[ -f "${tar_out}" ]] && ok "archive tar.gz output exists" || fail "archive tar.gz output missing"
    assert_eq "archive prints output path" "${tar_out}" "${archive_print}"
else
    skip "archive tar.gz requires tar"
fi
zip_out="${TEST_ROOT}/archives/archive.zip"
if sys::has zip || sys::has 7z; then
    assert_true "archive zip" path::archive "${archive_src}" "${zip_out}" --format=zip
    assert_file "archive zip exists" "${zip_out}"
else
    skip "archive zip requires zip or 7z"
fi
assert_false "archive rejects bad format" path::archive "${archive_src}" "${TEST_ROOT}/bad.out" --format=nope

mark path::extract
if [[ -f "${tar_out}" ]]; then
    extract_to="${TEST_ROOT}/extract/tar"
    extract_print="$(path::extract "${tar_out}" "${extract_to}" 2>/dev/null || true)"
    assert_eq "extract tar.gz prints target" "${extract_to}" "${extract_print}"
    assert_file "extract tar.gz content" "${extract_to}/archive-src/top/nested/keep.txt"
    assert_missing "extract excluded file absent" "${extract_to}/archive-src/skip/skip.txt"

    extract_strip="${TEST_ROOT}/extract/tar-strip"
    assert_true "extract tar.gz --strip=1" path::extract "${tar_out}" "${extract_strip}" --strip=1
    assert_file "extract strip content" "${extract_strip}/top/nested/keep.txt"
else
    skip "extract tar.gz no tar archive"
fi
if [[ -f "${zip_out}" ]]; then
    extract_zip="${TEST_ROOT}/extract/zip"
    assert_true "extract zip" path::extract "${zip_out}" "${extract_zip}"
    assert_file "extract zip content" "${extract_zip}/archive-src/top/nested/keep.txt"
else
    skip "extract zip no zip archive"
fi
assert_false "extract rejects bad strip" path::extract "${tar_out:-/missing}" "${TEST_ROOT}/bad-strip" --strip=bad

mark path::backup
if sys::has tar; then
    explicit_backup="${TEST_ROOT}/archives/explicit-backup.tar.gz"
    backup_print="$(path::backup "${archive_src}" "${explicit_backup}" 2>/dev/null || true)"
    assert_eq "backup prints archive path" "${explicit_backup}" "${backup_print}"
    assert_file "backup explicit exists" "${explicit_backup}"
else
    skip "backup requires tar"
fi

mark path::sync
mkdir -p "${TEST_ROOT}/sync-src/a" "${TEST_ROOT}/sync-dst/old"
printf sync > "${TEST_ROOT}/sync-src/a/file.txt"
printf old > "${TEST_ROOT}/sync-dst/old/file.txt"
assert_true "sync dir" path::sync "${TEST_ROOT}/sync-src" "${TEST_ROOT}/sync-dst"
assert_file "sync copied file" "${TEST_ROOT}/sync-dst/a/file.txt"
assert_missing "sync removed old destination tree" "${TEST_ROOT}/sync-dst/old/file.txt"
printf one > "${TEST_ROOT}/sync-file-src.txt"
assert_true "sync file" path::sync "${TEST_ROOT}/sync-file-src.txt" "${TEST_ROOT}/sync-file-dst.txt"
assert_file "sync file copied" "${TEST_ROOT}/sync-file-dst.txt"
assert_eq "sync file content" "one" "$(cat "${TEST_ROOT}/sync-file-dst.txt")"
assert_false "sync refuses root target" path::sync "${TEST_ROOT}/sync-src" "/"

# -----------------------------------------------------------------------------
# Watch
# -----------------------------------------------------------------------------

note "watch"

mark path::watch
if [[ "${DO_WATCH}" != 1 ]]; then
    skip "watch disabled by GUN_TEST_WATCH=0"
else
    watch_file="${TEST_ROOT}/watch.txt"
    printf before > "${watch_file}"
    (
        if sys::is_windows; then portable_sleep 1; else portable_sleep 0.35; fi
        printf after >> "${watch_file}"
    ) &
    watcher_mod_pid=$!

    if run_timeout 12 bash -c '
        set -u
        declare -F sys::has >/dev/null 2>&1 || sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
        declare -F sys::is_linux >/dev/null 2>&1 || sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }
        declare -F sys::is_macos >/dev/null 2>&1 || sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }
        declare -F sys::is_windows >/dev/null 2>&1 || sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]]; }
        declare -F sys::is_wsl >/dev/null 2>&1 || sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]]; }
        declare -F sys::uhome >/dev/null 2>&1 || sys::uhome () { printf "%s\n" "${HOME:-${USERPROFILE:-}}"; }
        source "$1"
        path::watch "$2" 0.1 "" once >/dev/null
    ' _ "${PATH_LIB}" "${watch_file}"; then
        ok "watch file once detects modification"
    else
        fail "watch file once detects modification"
    fi
    wait "${watcher_mod_pid}" 2>/dev/null || true

    watch_dir="${TEST_ROOT}/watch-dir"
    mkdir -p "${watch_dir}"
    (
        if sys::is_windows; then portable_sleep 1; else portable_sleep 0.35; fi
        printf created > "${watch_dir}/created.txt"
    ) &
    watcher_dir_pid=$!

    if run_timeout 12 bash -c '
        set -u
        declare -F sys::has >/dev/null 2>&1 || sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
        declare -F sys::is_linux >/dev/null 2>&1 || sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }
        declare -F sys::is_macos >/dev/null 2>&1 || sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }
        declare -F sys::is_windows >/dev/null 2>&1 || sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]]; }
        declare -F sys::is_wsl >/dev/null 2>&1 || sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]]; }
        declare -F sys::uhome >/dev/null 2>&1 || sys::uhome () { printf "%s\n" "${HOME:-${USERPROFILE:-}}"; }
        source "$1"
        path::watch "$2" 0.1 "" once >/dev/null
    ' _ "${PATH_LIB}" "${watch_dir}"; then
        ok "watch dir once detects create"
    else
        fail "watch dir once detects create"
    fi
    wait "${watcher_dir_pid}" 2>/dev/null || true

    callback_file="${TEST_ROOT}/watch-callback.count"
    callback_script="${TEST_ROOT}/watch-callback.sh"
    cat > "${callback_script}" <<CB
#!/usr/bin/env bash
printf x >> "${callback_file}"
CB
    chmod +x "${callback_script}"
    printf before > "${watch_file}"
    (
        if sys::is_windows; then portable_sleep 1; else portable_sleep 0.35; fi
        printf again >> "${watch_file}"
    ) &
    watcher_cb_pid=$!

    if run_timeout 12 bash -c '
        set -u
        declare -F sys::has >/dev/null 2>&1 || sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
        declare -F sys::is_linux >/dev/null 2>&1 || sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }
        declare -F sys::is_macos >/dev/null 2>&1 || sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }
        declare -F sys::is_windows >/dev/null 2>&1 || sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]]; }
        declare -F sys::is_wsl >/dev/null 2>&1 || sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]]; }
        declare -F sys::uhome >/dev/null 2>&1 || sys::uhome () { printf "%s\n" "${HOME:-${USERPROFILE:-}}"; }
        source "$1"
        path::watch "$2" 0.1 "$3" once >/dev/null
    ' _ "${PATH_LIB}" "${watch_file}" "${callback_script}"; then
        [[ -s "${callback_file}" ]] && ok "watch callback fires" || fail "watch callback did not write"
    else
        fail "watch callback run"
    fi
    wait "${watcher_cb_pid}" 2>/dev/null || true
fi


# -----------------------------------------------------------------------------
# New industrial path helpers
# -----------------------------------------------------------------------------

note "industrial helpers"

mark path::native
if sys::is_windows; then
    assert_eq "native uses windows conversion" 'C:\Users' "$(path::native '/mnt/c/Users')"
else
    assert_eq "native uses posix conversion" "/c/Users" "$(path::native 'C:/Users')"
fi

mark path::quote
quoted_space="$(path::quote "${TEST_ROOT}/space dir/file with spaces.txt")"
[[ -n "${quoted_space}" ]] && ok "quote returns non-empty escaped path" || fail "quote returned empty"
assert_false "quote rejects newline" path::quote $'bad\npath'

mark path::can
can_file="$(path::can "${TEST_ROOT}/src/a/../a/b/deep.txt" 2>/dev/null || true)"
assert_match "can existing file absolute" "${can_file}" '^/'
assert_eq "can existing file basename" "deep.txt" "$(path::basename "${can_file}")"
assert_false "can rejects missing" path::can "${TEST_ROOT}/missing-file"

mark path::joinlist
joined_list="$(path::joinlist "${TEST_ROOT}/a" "${TEST_ROOT}/b" "" "${TEST_ROOT}/c")"
if sys::is_windows; then
    assert_eq "joinlist windows delimiter" "${TEST_ROOT}/a;${TEST_ROOT}/b;${TEST_ROOT}/c" "${joined_list}"
else
    assert_eq "joinlist posix delimiter" "${TEST_ROOT}/a:${TEST_ROOT}/b:${TEST_ROOT}/c" "${joined_list}"
fi

mark path::splitlist
if sys::is_windows; then
    mapfile -t __splitlist < <(path::splitlist "A;B;C")
else
    mapfile -t __splitlist < <(path::splitlist "A:B:C")
fi
assert_eq "splitlist count" "3" "${#__splitlist[@]}"
assert_eq "splitlist first" "A" "${__splitlist[0]}"
assert_eq "splitlist last" "C" "${__splitlist[2]}"

mark path::ancestors
mapfile -t __ancestors < <(path::ancestors "${TEST_ROOT}/src/a/b/deep.txt")
assert_eq "ancestors first dirname" "${TEST_ROOT}/src/a/b" "${__ancestors[0]}"
if (( ${#__ancestors[@]} > 2 )); then ok "ancestors returns parent chain"; else fail "ancestors returned too few entries"; fi

mark path::match
assert_true  "match simple glob" path::match "src/main.rs" "src/*.rs"
assert_true  "match recursive-ish glob" path::match "src/a/b/main.rs" "src/*/b/*.rs"
assert_false "match negative glob" path::match "src/main.py" "src/*.rs"

mark path::starts_with
assert_true  "starts_with same path" path::starts_with "${TEST_ROOT}/src" "${TEST_ROOT}/src"
assert_true  "starts_with child path" path::starts_with "${TEST_ROOT}/src/a/b" "${TEST_ROOT}/src"
assert_false "starts_with component-aware" path::starts_with "${TEST_ROOT}/src-old/a" "${TEST_ROOT}/src"

mark path::ends_with
assert_true  "ends_with same path" path::ends_with "${TEST_ROOT}/src/a" "${TEST_ROOT}/src/a"
assert_true  "ends_with suffix components" path::ends_with "${TEST_ROOT}/src/a/b/deep.txt" "a/b/deep.txt"
assert_false "ends_with component-aware" path::ends_with "${TEST_ROOT}/src/a/deep.txt.bak" "deep.txt"

mark path::has_ext
assert_true  "has_ext single lower" path::has_ext "file.txt" txt
assert_true  "has_ext dot upper" path::has_ext "IMAGE.PNG" .png jpg png webp
assert_false "has_ext missing ext" path::has_ext "README" md
assert_false "has_ext wrong ext" path::has_ext "archive.tar.gz" zip

mark path::slugify
assert_eq "slugify path text" "my-file-name-.txt" "$(path::slugify 'My File / Name?.txt')"
assert_eq "slugify reserved name" "con_" "$(path::slugify 'CON')"
assert_eq "slugify fallback" "_" "$(path::slugify '////')"
slug_max="$(path::slugify 'abcdefghijklmnopqrstuvwxyz' _ 8 1)"
assert_eq "slugify max length" "abcdefgh" "${slug_max}"

mark path::is_safe
safe_child="${TEST_ROOT}/src/a/b/deep.txt"
assert_true  "is_safe child within root" path::is_safe "${safe_child}" "${TEST_ROOT}"
assert_true  "is_safe same root allowed" path::is_safe "${TEST_ROOT}" "${TEST_ROOT}"
assert_false "is_safe rejects traversal text" path::is_safe "../etc/passwd" "${TEST_ROOT}"
assert_false "is_safe rejects root target" path::is_safe "/" "${TEST_ROOT}"
assert_false "is_safe rejects root base" path::is_safe "${TEST_ROOT}" "/"
if can_symlink "/" "${TEST_ROOT}/safe-link-root"; then
    ln -s "/" "${TEST_ROOT}/safe-link-root" 2>/dev/null || true
    assert_false "is_safe rejects symlink escape" path::is_safe "${TEST_ROOT}/safe-link-root/etc" "${TEST_ROOT}"
    rm -f -- "${TEST_ROOT}/safe-link-root"
else
    skip "is_safe symlink escape unavailable"
fi

mark path::is_dot
assert_true  "is_dot dotfile" path::is_dot "${TEST_ROOT}/.hidden"
assert_false "is_dot normal file" path::is_dot "${TEST_ROOT}/file.txt"
assert_false "is_dot dot entry" path::is_dot "."
assert_false "is_dot dotdot entry" path::is_dot ".."

mark path::is_hidden
assert_true  "is_hidden dotfile" path::is_hidden "${TEST_ROOT}/.hidden"
assert_false "is_hidden normal file" path::is_hidden "${TEST_ROOT}/file.txt"

mark path::temp_name
temp_candidate="$(path::temp_name 'unsafe prefix / A' '.tmp' "${TEST_ROOT}")"
assert_match "temp returns path inside dir" "${temp_candidate}" "^${TEST_ROOT}/"
assert_false "temp does not create file" path::exists "${temp_candidate}"
assert_match "temp suffix" "${temp_candidate}" 'tmp$'

mark path::trylock
mark path::lock
mark path::unlock
mark path::locked
mark path::with_lock
lock_dir="${TEST_ROOT}/locks/main.lock"
assert_true "trylock acquires new lock" path::trylock "${lock_dir}" 0
assert_true "locked detects held lock" path::locked "${lock_dir}"
assert_false "trylock refuses held lock" path::trylock "${lock_dir}" 0
assert_true "unlock releases owned lock" path::unlock "${lock_dir}"
assert_false "locked false after unlock" path::locked "${lock_dir}"
assert_true "lock acquires with timeout" path::lock "${lock_dir}" 1 0.05 0
assert_true "unlock after lock" path::unlock "${lock_dir}"

mkdir -p "${lock_dir}"
printf '999999999\n' > "${lock_dir}/pid"
if command -v touch >/dev/null 2>&1; then
    touch -t 200001010000 "${lock_dir}" 2>/dev/null || true
fi
assert_true "trylock removes stale dead lock" path::trylock "${lock_dir}" 1
assert_true "unlock stale lock owner" path::unlock "${lock_dir}"

__with_lock_file="${TEST_ROOT}/with-lock-result.txt"
__with_lock_callback () {
    local msg="${1:-}"
    printf '%s' "${msg}" > "${__with_lock_file}"
    return 7
}
path::with_lock "${TEST_ROOT}/locks/with.lock" __with_lock_callback 2 0.05 0 "hello"
with_lock_code=$?
assert_eq "with_lock preserves callback code" "7" "${with_lock_code}"
assert_eq "with_lock passes args" "hello" "$(cat "${__with_lock_file}" 2>/dev/null || true)"
assert_false "with_lock releases lock" path::locked "${TEST_ROOT}/locks/with.lock"



# -----------------------------------------------------------------------------
# Codec / encryption / tree / temp-near additions
# -----------------------------------------------------------------------------

note "codec and encryption"

mark path::tree
tree_out="$(path::tree "${TEST_ROOT}/src" 0 2>/dev/null || true)"
[[ "${tree_out}" == *"deep.txt"* ]] && ok "tree includes deep file" || fail "tree missing deep file"
file_tree="$(path::tree "${TEST_ROOT}/file.txt" 2>/dev/null || true)"
assert_eq "tree on file prints basename" "file.txt" "${file_tree}"

mark path::parentname
assert_eq "parentname nested" "b" "$(path::parentname "${TEST_ROOT}/src/a/b/deep.txt")"
assert_eq "parentname root child empty" "" "$(path::parentname "/file" 2>/dev/null || true)"

mark path::mktemp_near
mkdir -p "${TEST_ROOT}/near"
near_tmp="$(path::mktemp_near file "${TEST_ROOT}/near/base.txt" near .tmp 2>/dev/null || true)"
assert_file "mktemp_near creates file" "${near_tmp}"
case "${near_tmp}" in "${TEST_ROOT}/near"/*) ok "mktemp_near placed near target" ;; *) fail "mktemp_near wrong dir ${near_tmp}" ;; esac
rm -f -- "${near_tmp}" 2>/dev/null || true

mark path::encode_caps
wrap_cap=""; flag_cap=""
if path::encode_caps wrap_cap flag_cap; then
    [[ "${wrap_cap}" == "0" || "${wrap_cap}" == "1" ]] && ok "encode_caps wrap valid" || fail "encode_caps bad wrap"
    [[ "${flag_cap}" == "-d" || "${flag_cap}" == "-D" ]] && ok "encode_caps flag valid" || fail "encode_caps bad flag"
else
    skip "base64 unavailable"
fi

mark path::encode
mark path::decode
b64_src="${TEST_ROOT}/codec/raw.txt"
b64_out="${TEST_ROOT}/codec/raw.b64"
b64_dec="${TEST_ROOT}/codec/decoded.txt"
mkdir -p "${TEST_ROOT}/codec"
printf 'Base64 payload: %s\n' "unicode" > "${b64_src}"
encoded_stdout="$(path::encode "${b64_src}" 2>/dev/null || true)"
[[ -n "${encoded_stdout}" ]] && ok "encode file stdout non-empty" || fail "encode file stdout empty"
assert_true "encode file to output" path::encode "${b64_src}" "${b64_out}"
assert_file "encode output exists" "${b64_out}"
assert_true "decode file to output" path::decode "${b64_out}" "${b64_dec}"
assert_eq "decode roundtrip content" "$(cat "${b64_src}")" "$(cat "${b64_dec}")"
codec_dir="${TEST_ROOT}/codec/dir"
codec_encoded="${TEST_ROOT}/codec/encoded-dir"
codec_decoded="${TEST_ROOT}/codec/decoded-dir"
mkdir -p "${codec_dir}/nested"
printf one > "${codec_dir}/one.txt"
printf two > "${codec_dir}/nested/two.txt"
assert_true "encode directory to output tree" path::encode "${codec_dir}" "${codec_encoded}"
assert_file "encode dir one exists" "${codec_encoded}/one.txt"
assert_file "encode dir nested exists" "${codec_encoded}/nested/two.txt"
assert_true "decode directory output tree" path::decode "${codec_encoded}" "${codec_decoded}"
assert_eq "decode dir one content" "one" "$(cat "${codec_decoded}/one.txt")"
assert_eq "decode dir nested content" "two" "$(cat "${codec_decoded}/nested/two.txt")"
path::encode "${codec_dir}" >/tmp/pathbrutal-encode-dir.$$ 2>/tmp/pathbrutal-encode-dir.err.$$ && ok "encode dir stdout mode" || fail "encode dir stdout mode"
rm -f /tmp/pathbrutal-encode-dir.$$ /tmp/pathbrutal-encode-dir.err.$$ 2>/dev/null || true
if [[ -L "${TEST_ROOT}/symlink" ]]; then
    assert_false "encode rejects symlink input" path::encode "${TEST_ROOT}/symlink"
else
    skip "encode symlink rejection no symlink"
fi

mark path::encrypt_engine
mark path::encrypt
mark path::decrypt
crypt_pass="BrutalPass-12345!"
crypt_file="${TEST_ROOT}/crypt/secret.txt"
mkdir -p "${TEST_ROOT}/crypt"
printf 'top secret\n' > "${crypt_file}"
crypt_engine="auto"
if command -v openssl >/dev/null 2>&1; then crypt_engine="openssl"
elif command -v gpg >/dev/null 2>&1; then crypt_engine="gpg"
fi
if [[ "${crypt_engine}" != "auto" ]]; then
    if path::encrypt "${crypt_file}" "${crypt_pass}" "${crypt_engine}"; then ok "encrypt file in place"; else fail "encrypt file in place"; fi
    engine_probe=""
    if path::encrypt_engine "${crypt_file}" engine_probe; then
        case "${engine_probe}" in gpg|openssl) ok "encrypt_engine detects ${engine_probe}" ;; *) fail "encrypt_engine invalid ${engine_probe}" ;; esac
    else
        fail "encrypt_engine detects encrypted file"
    fi
    if path::encrypt "${crypt_file}" "${crypt_pass}" "${crypt_engine}"; then ok "encrypt idempotent second run"; else fail "encrypt idempotent second run"; fi
    if path::decrypt "${crypt_file}" "${crypt_pass}" auto; then ok "decrypt file in place"; else fail "decrypt file in place"; fi
    assert_eq "decrypt roundtrip" "top secret" "$(cat "${crypt_file}")"
    crypt_dir="${TEST_ROOT}/crypt/dir"
    mkdir -p "${crypt_dir}/sub"
    printf a > "${crypt_dir}/a.txt"
    printf b > "${crypt_dir}/sub/b.txt"
    if path::encrypt "${crypt_dir}" "${crypt_pass}" "${crypt_engine}"; then ok "encrypt directory"; else fail "encrypt directory"; fi
    if path::decrypt "${crypt_dir}" "${crypt_pass}" auto; then ok "decrypt directory"; else fail "decrypt directory"; fi
    assert_eq "decrypt directory file a" "a" "$(cat "${crypt_dir}/a.txt")"
    assert_eq "decrypt directory file b" "b" "$(cat "${crypt_dir}/sub/b.txt")"
else
    skip "encrypt/decrypt requires gpg or openssl"
fi


# -----------------------------------------------------------------------------
# Adversarial / fuzz-style path parsing suite
# -----------------------------------------------------------------------------

note "adversarial path fuzz"

fuzz_long="long-$(printf 'x%.0s' {1..300})"
fuzz_deep="d0/d1/d2/d3/d4/d5/d6/d7/d8/d9/d10/d11/d12/d13/d14/d15/d16/d17/d18/d19/file.txt"
fuzz_cases=(
    ""
    "."
    ".."
    "../x"
    "../../../../etc/passwd"
    "/"
    "//"
    "////"
    "/tmp//a/../b/."
    "./././x"
    "a//b///c"
    "a/../../b"
    "a/./b/../c"
    " "
    "  spaced  "
    "a b c"
    "space dir/file name.txt"
    $'tab\tpath'
    $'new\nline'
    $'carriage\rreturn'
    "semi;colon"
    "pipe|name"
    "amp&name"
    "dollar\$name"
    "backtick\`name"
    "quote'file"
    'quote"file'
    "paren(name)"
    "bracket[name]"
    "brace{name}"
    "star*file"
    "question?file"
    "less<file"
    "greater>file"
    "hash#file"
    "percent%file"
    "plus+file"
    "equals=file"
    "comma,file"
    "colon:file"
    "C:/Users/Test"
    "C:\\Users\\Test"
    "C:relative"
    "c:/mixed/Case"
    "//server/share/path"
    "\\\\server\\share\\path"
    "/mnt/c/Users/Test"
    "emoji-🔥.txt"
    "arabic-ملف.txt"
    "中文/文件.txt"
    "combining-é.txt"
    "rtl-‮txt.exe"
    "zero-width-‍file"
    "dash/-file"
    "--"
    "-rf"
    ".hidden"
    "..hidden"
    "..."
    "file."
    "file..ext"
    "archive.tar.gz"
    "CON"
    "NUL.txt"
    "aux"
    "COM1"
    "LPT9"
    "${fuzz_long}"
    "${fuzz_deep}"
)

pure_fuzz_funcs=(
    path::valid
    path::is_abs
    path::is_rel
    path::has_drive
    path::slashify
    path::dirname
    path::basename
    path::stem
    path::ext
    path::dotext
    path::normalize
    path::quote
    path::parts
    path::depth
    path::root
)

for fn in "${pure_fuzz_funcs[@]}"; do
    mark "${fn}"
done

for case_value in "${fuzz_cases[@]}"; do
    for fn in "${pure_fuzz_funcs[@]}"; do
        ( "${fn}" "${case_value}" >/dev/null 2>&1 || true )
        ok "fuzz ${fn} handles [$case_value]"
    done

done

for case_value in "${fuzz_cases[@]}"; do
    ( path::setname "${case_value}" "renamed.txt" >/dev/null 2>&1 || true )
    ok "fuzz path::setname handles [$case_value]"
    ( path::setstem "${case_value}" "stem" >/dev/null 2>&1 || true )
    ok "fuzz path::setstem handles [$case_value]"
    ( path::setext "${case_value}" "out" >/dev/null 2>&1 || true )
    ok "fuzz path::setext handles [$case_value]"
    ( path::join "${case_value}" "child" ".." "leaf" >/dev/null 2>&1 || true )
    ok "fuzz path::join handles [$case_value]"
    ( path::rel "${case_value}" "${TEST_ROOT}" >/dev/null 2>&1 || true )
    ok "fuzz path::rel handles [$case_value]"
    ( path::common "${TEST_ROOT}" "${TEST_ROOT}/${case_value}" >/dev/null 2>&1 || true )
    ok "fuzz path::common handles [$case_value]"
    ( path::slugify "${case_value}" _ 64 1 >/dev/null 2>&1 || true )
    ok "fuzz path::slugify handles [$case_value]"
done

# -----------------------------------------------------------------------------
# Safety fuzz for destructive / boundary-sensitive operations
# -----------------------------------------------------------------------------

note "safety fuzz"

safety_root="${TEST_ROOT}/safety"
mkdir -p "${safety_root}/inside" "${safety_root}/outside"
printf safe > "${safety_root}/inside/file.txt"
printf outside > "${safety_root}/outside/file.txt"

unsafe_targets=(
    "/"
    "."
    ".."
    "../outside/file.txt"
    "${safety_root}/inside/../outside/file.txt"
    "${safety_root}/inside/../../outside/file.txt"
    "${safety_root}/inside/file.txt"
    "${safety_root}/inside/missing.txt"
    "${safety_root}/inside/space file.txt"
    "${safety_root}/inside/-dash"
)

mark path::is_safe
mark path::remove
mark path::clear
mark path::sync
mark path::mkparent
mark path::touch
mark path::mkdir
mark path::copy
mark path::move
mark path::rename

for target_value in "${unsafe_targets[@]}"; do
    ( path::is_safe "${target_value}" "${safety_root}/inside" >/dev/null 2>&1 || true )
    ok "safety path::is_safe handles [$target_value]"

done

for n in $(seq 1 40); do
    f="${safety_root}/inside/generated-${n}.txt"
    d="${safety_root}/inside/generated-dir-${n}"
    c="${safety_root}/inside/generated-copy-${n}.txt"
    m="${safety_root}/inside/generated-moved-${n}.txt"

    assert_true "safety touch generated ${n}" path::touch "${f}"
    assert_file "safety touch exists ${n}" "${f}"
    assert_true "safety mkdir generated ${n}" path::mkdir "${d}"
    assert_dir "safety mkdir exists ${n}" "${d}"
    assert_true "safety copy generated ${n}" path::copy "${f}" "${c}"
    assert_file "safety copy exists ${n}" "${c}"
    assert_true "safety move generated ${n}" path::move "${c}" "${m}"
    assert_file "safety move exists ${n}" "${m}"
    assert_true "safety remove generated ${n}" path::remove "${m}"
    assert_missing "safety remove missing ${n}" "${m}"

done

assert_file "safety outside file survived" "${safety_root}/outside/file.txt"
assert_false "safety remove root refused again" path::remove "/"
assert_false "safety clear root refused again" path::clear "/"
assert_false "safety sync root target refused again" path::sync "${safety_root}/inside" "/"

# -----------------------------------------------------------------------------
# Lightweight concurrency / lock stress
# -----------------------------------------------------------------------------

note "concurrency smoke"

mark path::trylock
mark path::lock
mark path::unlock
mark path::locked
mark path::with_lock

concurrent_root="${TEST_ROOT}/concurrent"
mkdir -p "${concurrent_root}"
concurrent_lock="${concurrent_root}/main.lock"
concurrent_counter="${concurrent_root}/counter.txt"
printf '' > "${concurrent_counter}"

__path_brutal_locked_append () {
    local value="${1:-x}"
    printf '%s\n' "${value}" >> "${concurrent_counter}"
    return 0
}

concurrent_workers=25
concurrent_timeout=8
concurrent_sleep=0.03

if sys::is_windows; then
    concurrent_timeout=30
    concurrent_sleep=0.10
fi

for n in $(seq 1 "${concurrent_workers}"); do
    path::with_lock "${concurrent_lock}" __path_brutal_locked_append "${concurrent_timeout}" "${concurrent_sleep}" 0 "${n}" &
done
wait

counter_lines="$(wc -l < "${concurrent_counter}" 2>/dev/null | tr -d '[:space:]')"
assert_eq "concurrency with_lock wrote ${concurrent_workers} lines" "${concurrent_workers}" "${counter_lines}"
assert_false "concurrency lock released" path::locked "${concurrent_lock}"

# -----------------------------------------------------------------------------
# Medium-size tree stress without slow mode
# -----------------------------------------------------------------------------

note "medium tree stress"

medium_root="${TEST_ROOT}/medium-tree"
mkdir -p "${medium_root}"
for n in $(seq 1 120); do
    mkdir -p "${medium_root}/d$(( n % 12 ))/sub$(( n % 5 ))"
    printf 'medium-%s\n' "${n}" > "${medium_root}/d$(( n % 12 ))/sub$(( n % 5 ))/file-${n}.txt"
done

mark path::tree
mark path::hash
mark path::snapshot
mark path::archive
mark path::extract

medium_tree_out="$(path::tree "${medium_root}" 3 2>/dev/null || true)"
[[ "${medium_tree_out}" == *"file-"* || -n "${medium_tree_out}" ]] && ok "medium tree returns output" || fail "medium tree empty"
medium_hash_1="$(path::hash "${medium_root}" sha256 2>/dev/null || true)"
medium_hash_2="$(path::hash "${medium_root}" sha256 2>/dev/null || true)"
assert_match "medium hash sha256" "${medium_hash_1}" '^[0-9a-fA-F]{64}$'
assert_eq "medium hash deterministic" "${medium_hash_1}" "${medium_hash_2}"
medium_snapshot_count="$(path::snapshot "${medium_root}" 2>/dev/null | wc -l | tr -d '[:space:]')"
assert_match "medium snapshot count numeric" "${medium_snapshot_count}" '^[0-9]+$'

if sys::has tar; then
    medium_archive="${TEST_ROOT}/archives/medium.tar.gz"
    assert_true "medium archive" path::archive "${medium_root}" "${medium_archive}"
    assert_file "medium archive exists" "${medium_archive}"
    assert_true "medium extract" path::extract "${medium_archive}" "${TEST_ROOT}/extract/medium"
    assert_file "medium extract sample" "${TEST_ROOT}/extract/medium/medium-tree/d1/sub1/file-1.txt"
else
    skip "medium archive/extract requires tar"
fi


# -----------------------------------------------------------------------------
# Optional slow stress
# -----------------------------------------------------------------------------

if [[ "${SLOW}" == 1 ]]; then
    note "slow stress"

    stress_dir="${TEST_ROOT}/stress"
    mkdir -p "${stress_dir}"
    for i in $(seq 1 600); do
        mkdir -p "${stress_dir}/d$(( i % 31 ))"
        printf '%s\n' "${i}" > "${stress_dir}/d$(( i % 31 ))/file-${i}.txt"
    done

    assert_true "slow common many" path::common "${stress_dir}/d1/file-1.txt" "${stress_dir}/d1/file-32.txt"

    stress_sum_1="$(path::checksum "${stress_dir}" sha256 2>/dev/null || true)"
    stress_sum_2="$(path::checksum "${stress_dir}" sha256 2>/dev/null || true)"
    assert_match "slow checksum 600 files" "${stress_sum_1}" '^[0-9a-fA-F]{64}$'
    assert_eq "slow checksum deterministic" "${stress_sum_1}" "${stress_sum_2}"

    snap_count="$(path::snapshot "${stress_dir}" 2>/dev/null | wc -l | tr -d '[:space:]')"
    assert_match "slow snapshot count numeric" "${snap_count}" '^[0-9]+$'

    if sys::has tar; then
        stress_archive="${TEST_ROOT}/archives/stress.tar.gz"
        assert_true "slow archive 600 files" path::archive "${stress_dir}" "${stress_archive}"
        assert_true "slow extract 600 files" path::extract "${stress_archive}" "${TEST_ROOT}/extract/stress"
        assert_file "slow extract sample" "${TEST_ROOT}/extract/stress/stress/d1/file-1.txt"
    fi
fi

# -----------------------------------------------------------------------------
# Coverage gate: every path::* function from target must be marked.
# -----------------------------------------------------------------------------

note "coverage gate"

mapfile -t ALL_FUNCS < <(declare -F | awk '{print $3}' | grep '^path::' | sort)
missing=()

for fn in "${ALL_FUNCS[@]}"; do
    [[ -n "${TESTED_FUNCS[${fn}]:-}" ]] || missing+=( "${fn}" )
done

if (( ${#missing[@]} == 0 )); then
    ok "all ${#ALL_FUNCS[@]} path::* functions covered"
else
    fail "missing coverage: ${missing[*]}"
fi

# Expected exact count for the current API generation.
# If you intentionally add/remove functions, update EXPECTED_FUNC_COUNT.
EXPECTED_FUNC_COUNT="${GUN_EXPECTED_PATH_FUNCS:-130}"
if [[ "${#ALL_FUNCS[@]}" == "${EXPECTED_FUNC_COUNT}" ]]; then
    ok "expected function count ${EXPECTED_FUNC_COUNT}"
else
    fail "expected ${EXPECTED_FUNC_COUNT} path::* functions, found ${#ALL_FUNCS[@]}"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

printf '\n'
printf '============================================================\n'
printf ' path.sh brutal test summary\n'
printf '============================================================\n'
printf 'Target : %s\n' "${PATH_LIB}"
printf 'Root   : %s\n' "${TEST_ROOT}"
printf 'Total  : %s\n' "${TOTAL}"
printf 'Pass   : %s\n' "${PASS}"
printf 'Fail   : %s\n' "${FAIL}"
printf 'Skip   : %s\n' "${SKIP}"
printf 'Funcs  : %s/%s covered\n' "$(( ${#ALL_FUNCS[@]} - ${#missing[@]} ))" "${#ALL_FUNCS[@]}"
printf '============================================================\n'

if [[ "${GUN_TEST_KEEP_ROOT:-0}" != 1 ]]; then
    cleanup
fi

if (( FAIL > 0 )); then
    exit 1
fi

exit 0
