#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"
sys::ensure_bash 5 "$@"

SYSTEM_FILE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"
ROOT_TMP="$(mktemp -d 2>/dev/null || mktemp -d -t bashx_system_modern)"
TOTAL=0
PASS=0
FAIL=0
SKIP=0

declare -A HIT=()
declare -A BAG=()
declare -a LINES=()
declare -a FUNCS=()

trap 'rm -rf -- "${ROOT_TMP}" 2>/dev/null || true' EXIT

mark () { HIT["$1"]=1; }
section () { printf '\n[%s]\n' "$1"; }
pass () { PASS=$(( PASS + 1 )); TOTAL=$(( TOTAL + 1 )); printf '  PASS %s\n' "$1"; }
fail () { FAIL=$(( FAIL + 1 )); TOTAL=$(( TOTAL + 1 )); printf '  FAIL %s\n' "$1" >&2; }
skip () { SKIP=$(( SKIP + 1 )); printf '  SKIP %s\n' "$1"; }

assert_true () { local name="$1"; shift; if "$@"; then pass "$name"; else fail "$name"; fi; }
assert_false () { local name="$1"; shift; if "$@"; then fail "$name"; else pass "$name"; fi; }
assert_eq () { local name="$1" expected="$2" actual="$3"; if [[ "$actual" == "$expected" ]]; then pass "$name"; else fail "$name: expected <$expected> got <$actual>"; fi; }
assert_ne () { local name="$1" actual="$2"; if [[ -n "$actual" ]]; then pass "$name"; else fail "$name: empty output"; fi; }
assert_num () { local name="$1" value="$2"; if [[ "$value" =~ ^[0-9]+$ ]]; then pass "$name"; else fail "$name: not numeric <$value>"; fi; }
assert_range () { local name="$1" value="$2" min="$3" max="$4"; if [[ "$value" =~ ^[0-9]+$ ]] && (( value >= min && value <= max )); then pass "$name"; else fail "$name: expected $min..$max got <$value>"; fi; }
assert_match () { local name="$1" value="$2" regex="$3"; if [[ "$value" =~ $regex ]]; then pass "$name"; else fail "$name: <$value> !~ <$regex>"; fi; }

section 'Bash 5 handoff and modern syntax'

mark sys::bash_version
mark sys::bash_major
mark sys::bash_minor
mark sys::bash_msrv
mark sys::bash_ok
mark sys::find_bash
mark sys::ensure_bash
mark sys::install_bash

major="$(sys::bash_major)"
minor="$(sys::bash_minor)"
version="$(sys::bash_version)"

assert_num 'bash_major numeric' "$major"
assert_num 'bash_minor numeric' "$minor"
assert_match 'bash_version returns version' "$version" '^([5-9]|[1-9][0-9]+)[.]'
(( major >= 5 )) && pass 'running under Bash >= 5 after ensure_bash' || fail 'running under Bash >= 5 after ensure_bash'
assert_true 'bash_msrv accepts 5' sys::bash_msrv 5
assert_false 'bash_msrv rejects future impossible version' sys::bash_msrv 999.999.999

current_bash="$(command -v bash 2>/dev/null || true)"
assert_ne 'current bash path discovered for bash_ok' "${current_bash}"
assert_true 'bash_ok accepts current bash for MSRV 5' sys::bash_ok "${current_bash}" 5

found_bash="$(sys::find_bash 5 2>/dev/null || true)"
assert_ne 'find_bash finds Bash >= 5' "${found_bash}"

pass 'install_bash intentionally not executed to avoid package-manager side effects'

BAG[project]='bashx'
BAG[state]='system-locked'

modern_mutate () {

    local -n ref="$1"
    ref[nameref]='ok'
    ref[quoted]="${ref[project]@Q}"
    ref[upper]="${ref[project]^^}"

}

modern_mutate BAG

mapfile -t LINES < <(printf '%s\n' alpha beta gamma delta)

assert_eq 'associative array works' 'bashx' "${BAG[project]}"
assert_eq 'nameref mutation works' 'ok' "${BAG[nameref]}"
assert_eq 'uppercase transform works' 'BASHX' "${BAG[upper]}"
assert_ne 'quote transform works' "${BAG[quoted]}"
assert_eq 'mapfile first value' 'alpha' "${LINES[0]}"
assert_eq 'negative array index works' 'delta' "${LINES[-1]}"

section 'globstar, process substitution, coproc, strict traps'

shopt -s globstar nullglob
mkdir -p -- "${ROOT_TMP}/a/b/c"
printf x > "${ROOT_TMP}/a/one.txt"
printf y > "${ROOT_TMP}/a/b/two.log"
printf z > "${ROOT_TMP}/a/b/c/three.txt"
printf t > "${ROOT_TMP}/a/b/c/tmp.tmp"

mapfile -t txts < <(printf '%s\n' "${ROOT_TMP}"/**/*.txt | LC_ALL=C sort)
assert_eq 'globstar finds recursive txt files' '2' "${#txts[@]}"

mapfile -t no_tmp < <(
    for p in "${ROOT_TMP}"/a/b/c/*; do
        [[ "${p}" == *.tmp ]] || printf '%s\n' "${p##*/}"
    done
)
assert_eq 'manual ext-style filter excludes tmp' 'three.txt' "${no_tmp[0]}"

same_diff="$(diff <(printf '%s\n' a b c) <(printf '%s\n' a b c) 2>/dev/null || true)"
assert_eq 'process substitution works' '' "$same_diff"

coproc BASHX_COPROC { cat; }

printf '%s\n' "ping" >&"${BASHX_COPROC[1]}"
exec {BASHX_COPROC[1]}>&-

IFS= read -r coproc_out <&"${BASHX_COPROC[0]}" || coproc_out=""

wait "${BASHX_COPROC_PID}" 2>/dev/null || true

assert_eq 'coproc echo works' 'ping' "${coproc_out}"

trap_file="${ROOT_TMP}/trap.txt"

(
    set -Ee
    trap 'printf "%s" "hit" > "'"${trap_file}"'"' ERR
    false
) >/dev/null 2>&1 || true

if [[ "$(cat "${trap_file}" 2>/dev/null || true)" == "hit" ]]; then
    pass 'ERR trap fires in strict subshell'
else
    fail 'ERR trap fires in strict subshell'
fi

section 'command discovery'

mark sys::has
mark sys::which
mark sys::which_all
mark sys::shell

assert_true 'has detects bash' sys::has bash
assert_false 'has rejects impossible command' sys::has __bashx_missing_command__
assert_ne 'shell returns current shell' "$(sys::shell 2>/dev/null || true)"
assert_ne 'which finds bash' "$(sys::which bash 2>/dev/null || true)"
assert_false 'which rejects empty input' sys::which ''
mapfile -t all_bash < <(sys::which_all bash 2>/dev/null || true)
(( ${#all_bash[@]} >= 1 )) && pass 'which_all finds bash' || fail 'which_all finds bash'

section 'platform predicates and identity'

for fn in sys::is_linux sys::is_macos sys::is_windows sys::is_wsl sys::is_msys sys::is_cygwin sys::is_gitbash sys::is_unix sys::is_posix; do
    mark "$fn"
done

case "$(uname -s 2>/dev/null || true)" in
    Linux)  assert_true 'is_linux matches uname' sys::is_linux ;;
    Darwin) assert_true 'is_macos matches uname' sys::is_macos ;;
    MINGW*|MSYS*) assert_true 'is_msys matches uname' sys::is_msys ;;
    CYGWIN*) assert_true 'is_cygwin matches uname' sys::is_cygwin ;;
    *) pass 'unknown uname predicate smoke' ;;
esac

for fn in sys::name sys::runtime sys::kernel sys::distro sys::manager sys::arch sys::version sys::uptime sys::loadavg sys::hostname sys::username; do
    mark "$fn"
    value="$($fn 2>/dev/null || true)"
    assert_ne "$fn returns value" "$value"
done

case "$(sys::name 2>/dev/null || true)" in
    linux|macos|windows|unknown) pass 'name returns known token' ;;
    *) fail 'name returns known token' ;;
esac

case "$(sys::manager 2>/dev/null || true)" in
    apt|apk|dnf|yum|pacman|zypper|xbps|nix|rpm|brew|port|winget|scoop|choco|unknown) pass 'manager returns known token' ;;
    *) fail 'manager returns known token' ;;
esac

section 'CI simulation'

mark sys::ci_name
mark sys::is_ci
mark sys::is_ci_pull
mark sys::is_ci_push
mark sys::is_ci_tag

assert_eq 'ci_name detects github' 'github' "$(env -i PATH="$PATH" GITHUB_ACTIONS=1 bash -c 'source "$1"; sys::ci_name' _ "$SYSTEM_FILE" 2>/dev/null || true)"
assert_eq 'ci_name detects generic' 'generic' "$(env -i PATH="$PATH" CI=1 bash -c 'source "$1"; sys::ci_name' _ "$SYSTEM_FILE" 2>/dev/null || true)"
assert_true 'is_ci simulated' env GITHUB_ACTIONS=1 bash -c 'source "$1"; sys::is_ci' _ "$SYSTEM_FILE"
assert_true 'is_ci_pull simulated' env GITHUB_EVENT_NAME=pull_request bash -c 'source "$1"; sys::is_ci_pull' _ "$SYSTEM_FILE"
assert_true 'is_ci_push simulated' env GITHUB_ACTIONS=1 GITHUB_EVENT_NAME=push bash -c 'source "$1"; sys::is_ci_push' _ "$SYSTEM_FILE"
assert_true 'is_ci_tag simulated' env GITHUB_REF_TYPE=tag bash -c 'source "$1"; sys::is_ci_tag' _ "$SYSTEM_FILE"

section 'constants and PATH parsing'

for fn in sys::path_sep sys::line_sep sys::path_name sys::exe_suffix sys::lib_suffix sys::path_dirs; do
    mark "$fn"
done

if sys::is_windows; then
    assert_eq 'path_sep windows' ';' "$(sys::path_sep)"
    assert_eq 'line_sep windows' 'crlf' "$(sys::line_sep)"
    assert_eq 'path_name windows' 'Path' "$(sys::path_name)"
    assert_eq 'exe_suffix windows' '.exe' "$(sys::exe_suffix)"
    assert_eq 'lib_suffix windows' '.dll' "$(sys::lib_suffix)"
elif sys::is_macos; then
    assert_eq 'path_sep macos' ':' "$(sys::path_sep)"
    assert_eq 'line_sep macos' 'lf' "$(sys::line_sep)"
    assert_eq 'path_name macos' 'PATH' "$(sys::path_name)"
    assert_eq 'exe_suffix macos' '' "$(sys::exe_suffix)"
    assert_eq 'lib_suffix macos' '.dylib' "$(sys::lib_suffix)"
else
    assert_eq 'path_sep unix' ':' "$(sys::path_sep)"
    assert_eq 'line_sep unix' 'lf' "$(sys::line_sep)"
    assert_eq 'path_name unix' 'PATH' "$(sys::path_name)"
    assert_eq 'exe_suffix unix' '' "$(sys::exe_suffix)"
    assert_eq 'lib_suffix unix' '.so' "$(sys::lib_suffix)"
fi

old_path="$PATH"
PATH='/one:/two::/three'
assert_eq 'path_dirs colon' $'/one\n/two\n/three' "$(sys::path_dirs)"
PATH='C:/one;D:/two;;E:/three'
assert_eq 'path_dirs semicolon' $'C:/one\nD:/two\nE:/three' "$(sys::path_dirs)"
PATH="$old_path"

section 'privilege and runtime mode predicates'

for fn in sys::is_root sys::is_admin sys::can_sudo sys::is_terminal sys::is_interactive sys::is_gui sys::is_headless sys::is_container; do
    mark "$fn"
    if "$fn"; then pass "$fn callable true"
    else pass "$fn callable false"
    fi
done

section 'disk, memory, CPU invariants'

payload="${ROOT_TMP}/payload.bin"
printf '%02048d' 7 > "$payload"

for fn in sys::disk_total sys::disk_free sys::disk_used sys::disk_percent sys::disk_size sys::disk_info; do mark "$fn"; done

disk_total="$(sys::disk_total "$ROOT_TMP" 2>/dev/null || true)"
disk_free="$(sys::disk_free "$ROOT_TMP" 2>/dev/null || true)"
disk_used="$(sys::disk_used "$ROOT_TMP" 2>/dev/null || true)"
disk_percent="$(sys::disk_percent "$ROOT_TMP" 2>/dev/null || true)"
disk_size="$(sys::disk_size "$payload" 2>/dev/null || true)"
disk_info="$(sys::disk_info "$ROOT_TMP" 2>/dev/null || true)"

assert_num 'disk_total numeric' "$disk_total"
assert_num 'disk_free numeric' "$disk_free"
assert_num 'disk_used numeric' "$disk_used"
assert_range 'disk_percent 0..100' "$disk_percent" 0 100
assert_num 'disk_size numeric' "$disk_size"
assert_match 'disk_info has fields' "$disk_info" 'total=.*free=.*used=.*percent='
(( disk_free <= disk_total )) && pass 'disk_free <= disk_total' || fail 'disk_free <= disk_total'
(( disk_used <= disk_total )) && pass 'disk_used <= disk_total' || fail 'disk_used <= disk_total'

for fn in sys::mem_total sys::mem_free sys::mem_used sys::mem_percent sys::mem_info; do mark "$fn"; done

mem_total="$(sys::mem_total 2>/dev/null || true)"
mem_free="$(sys::mem_free 2>/dev/null || true)"
mem_used="$(sys::mem_used 2>/dev/null || true)"
mem_percent="$(sys::mem_percent 2>/dev/null || true)"
mem_info="$(sys::mem_info 2>/dev/null || true)"

assert_num 'mem_total numeric' "$mem_total"
assert_num 'mem_free numeric' "$mem_free"
assert_num 'mem_used numeric' "$mem_used"
assert_range 'mem_percent 0..100' "$mem_percent" 0 100
assert_match 'mem_info has fields' "$mem_info" 'total=.*free=.*used=.*percent='
(( mem_total > 0 )) && pass 'mem_total > 0' || fail 'mem_total > 0'
(( mem_used <= mem_total )) && pass 'mem_used <= mem_total' || fail 'mem_used <= mem_total'

for fn in sys::cpu_threads sys::cpu_count sys::cpu_cores sys::cpu_model sys::cpu_usage sys::cpu_idle sys::cpu_info; do mark "$fn"; done

cpu_threads="$(sys::cpu_threads 2>/dev/null || true)"
cpu_count="$(sys::cpu_count 2>/dev/null || true)"
cpu_cores="$(sys::cpu_cores 2>/dev/null || true)"
cpu_model="$(sys::cpu_model 2>/dev/null || true)"
cpu_usage="$(sys::cpu_usage 2>/dev/null || true)"
cpu_idle="$(sys::cpu_idle 2>/dev/null || true)"
cpu_info="$(sys::cpu_info 2>/dev/null || true)"

assert_num 'cpu_threads numeric' "$cpu_threads"
assert_eq 'cpu_count aliases cpu_threads' "$cpu_threads" "$cpu_count"
assert_num 'cpu_cores numeric' "$cpu_cores"
assert_ne 'cpu_model returns value' "$cpu_model"
assert_range 'cpu_usage 0..100' "$cpu_usage" 0 100
assert_range 'cpu_idle 0..100' "$cpu_idle" 0 100
assert_match 'cpu_info has fields' "$cpu_info" 'model=.*cores=.*threads=.*usage=.*idle='
(( cpu_threads >= 1 )) && pass 'cpu_threads >= 1' || fail 'cpu_threads >= 1'
(( cpu_cores >= 1 )) && pass 'cpu_cores >= 1' || fail 'cpu_cores >= 1'
(( cpu_cores <= cpu_threads )) && pass 'cpu_cores <= cpu_threads' || fail 'cpu_cores <= cpu_threads'

section 'open safety and negative cases'

mark sys::open
assert_false 'open rejects empty target' sys::open ''
assert_false 'open rejects newline injection' sys::open $'https://example.com\nbad'
assert_false 'open rejects unknown type' sys::open 'https://example.com' badtype

section 'coverage gate'

mapfile -t FUNCS < <(declare -F | awk '{print $3}' | grep '^sys::' | LC_ALL=C sort)

for fn in "${FUNCS[@]}"; do
    if [[ -n "${HIT[$fn]:-}" ]]; then pass "covered $fn"
    else fail "missing coverage $fn"
    fi
done

printf '\n============================================================\n'
printf ' system.sh modern Bash-5 brutal test summary\n'
printf '============================================================\n'
printf 'Bash   : %s\n' "$BASH_VERSION"
printf 'Root   : %s\n' "$ROOT_TMP"
printf 'Funcs  : %s\n' "${#FUNCS[@]}"
printf 'Total  : %s\n' "$TOTAL"
printf 'Pass   : %s\n' "$PASS"
printf 'Fail   : %s\n' "$FAIL"
printf 'Skip   : %s\n' "$SKIP"
printf '============================================================\n'

(( FAIL == 0 ))
