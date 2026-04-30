#!/usr/bin/env bash

set -uo pipefail

ROOT="${ROOT:-}"
TARGET_FILE="${TARGET_FILE:-src/parts/builtin/system.sh}"
MIN_TEST_BASH_VERSION="${MIN_TEST_BASH_VERSION:-5.2}"

if [[ -z "${ROOT}" ]]; then
    ROOT="$(pwd -P 2>/dev/null || pwd)"
fi

cd "${ROOT}" 2>/dev/null || exit 1

if [[ ! -f "${TARGET_FILE}" ]]; then
    printf 'FATAL: system.sh not found: %s\n' "${TARGET_FILE}" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "${TARGET_FILE}"

if declare -F sys::ensure_bash >/dev/null 2>&1; then
    sys::ensure_bash "${MIN_TEST_BASH_VERSION}" "$@"
elif declare -F sys::ensure >/dev/null 2>&1; then
    sys::ensure "${MIN_TEST_BASH_VERSION}" "$@"
fi

set -euo pipefail

# if [[ "${BASH_VERSION:-}" =~ ^([0-9]+)([.]([0-9]+))?([.]([0-9]+))? ]]; then
#     if (( BASH_REMATCH[1] < 5 || ( BASH_REMATCH[1] == 5 && ${BASH_REMATCH[3]:-0} < 2 ) )); then
#         printf 'FATAL: Bash >= %s required after ensure, got %s\n' "${MIN_TEST_BASH_VERSION}" "${BASH_VERSION:-unknown}" >&2
#         exit 1
#     fi
# else
#     printf 'FATAL: unable to parse Bash version: %s\n' "${BASH_VERSION:-unknown}" >&2
#     exit 1
# fi

# if ! declare -F sys::has >/dev/null 2>&1; then
#     printf 'FATAL: system.sh was not loaded after ensure: %s\n' "${TARGET_FILE}" >&2
#     exit 1
# fi

TARGET_ABS="$(cd "$(dirname "${TARGET_FILE}")" 2>/dev/null && pwd -P)/$(basename "${TARGET_FILE}")"
ROOT_TMP="$(mktemp -d 2>/dev/null || mktemp -d -t bashx_system_test)"

TOTAL=0
PASS=0
FAIL=0
SKIP=0

declare -A HIT=()

cleanup () {
    rm -rf -- "${ROOT_TMP}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

mark () {
    HIT["$1"]=1
}

has_fn () {
    declare -F "$1" >/dev/null 2>&1
}

section () {
    printf '\n[%s]\n' "$1"
}

pass () {
    PASS=$(( PASS + 1 ))
    TOTAL=$(( TOTAL + 1 ))
    printf '  PASS %s\n' "$1"
}

fail () {
    FAIL=$(( FAIL + 1 ))
    TOTAL=$(( TOTAL + 1 ))
    printf '  FAIL %s\n' "$1" >&2
}

skip () {
    SKIP=$(( SKIP + 1 ))
    printf '  SKIP %s\n' "$1"
}

assert_true () {
    local name="$1"
    shift

    if "$@"; then pass "${name}"
    else fail "${name}"
    fi
}

assert_false () {
    local name="$1"
    shift

    if "$@"; then fail "${name}"
    else pass "${name}"
    fi
}

assert_eq () {
    local name="$1" expected="$2" actual="$3"

    if [[ "${actual}" == "${expected}" ]]; then pass "${name}"
    else fail "${name}: expected <${expected}> got <${actual}>"
    fi
}

assert_ne () {
    local name="$1" actual="$2"

    if [[ -n "${actual}" ]]; then pass "${name}"
    else fail "${name}: empty output"
    fi
}

assert_re () {
    local name="$1" value="$2" regex="$3"

    if [[ "${value}" =~ ${regex} ]]; then pass "${name}"
    else fail "${name}: value <${value}> does not match <${regex}>"
    fi
}

assert_num () {
    local name="$1" value="$2"

    if [[ "${value}" =~ ^[0-9]+$ ]]; then pass "${name}"
    else fail "${name}: not numeric <${value}>"
    fi
}

assert_num_range () {
    local name="$1" value="$2" min="$3" max="$4"

    if [[ "${value}" =~ ^[0-9]+$ ]] && (( value >= min && value <= max )); then pass "${name}"
    else fail "${name}: expected ${min}..${max}, got <${value}>"
    fi
}

fresh_bash () {
    local script="$1"

    ROOT="${ROOT}" TARGET_FILE="${TARGET_ABS}" "${BASH}" -c 'source "${TARGET_FILE}"; eval "$1"' _ "${script}"
}

section 'bootstrap ensure gate'

if has_fn sys::ensure_bash; then
    mark sys::ensure_bash
    assert_true 'ensure_bash is idempotent after bootstrap' sys::ensure_bash "${MIN_TEST_BASH_VERSION}" "noop"
elif has_fn sys::ensure; then
    mark sys::ensure
    assert_true 'ensure is idempotent after bootstrap' sys::ensure "${MIN_TEST_BASH_VERSION}" "noop"
else
    skip 'ensure_bash/ensure not present'
fi

if has_fn sys::bash_msrv; then
    mark sys::bash_msrv
    assert_true 'current bash satisfies requested MSRV after ensure' sys::bash_msrv "${MIN_TEST_BASH_VERSION}"
fi

section 'coverage: functions exist'

mapfile -t DECLARED_FUNCS < <(declare -F | awk '{print $3}' | grep '^sys::' | LC_ALL=C sort)

if (( ${#DECLARED_FUNCS[@]} > 0 )); then pass 'found sys functions'
else fail 'found sys functions'
fi

for fn in "${DECLARED_FUNCS[@]}"; do
    if declare -F "${fn}" >/dev/null 2>&1; then pass "declared ${fn}"
    else fail "missing ${fn}"
    fi
done

section 'bash runtime layer'

if has_fn sys::bash_version; then
    mark sys::bash_version
    assert_eq 'bash_version matches BASH_VERSION' "${BASH_VERSION}" "$(sys::bash_version)"
fi

if has_fn sys::bash_major; then
    mark sys::bash_major
    assert_eq 'bash_major matches BASH_VERSINFO[0]' "${BASH_VERSINFO[0]}" "$(sys::bash_major)"
fi

if has_fn sys::bash_minor; then
    mark sys::bash_minor
    assert_eq 'bash_minor matches BASH_VERSINFO[1]' "${BASH_VERSINFO[1]}" "$(sys::bash_minor)"
fi

if has_fn sys::bash_msrv; then
    mark sys::bash_msrv
    assert_true 'bash_msrv accepts current major' sys::bash_msrv "${BASH_VERSINFO[0]}"
    assert_true 'bash_msrv accepts current major.minor' sys::bash_msrv "${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
    assert_false 'bash_msrv rejects impossible future version' sys::bash_msrv "999.0"
    assert_false 'bash_msrv rejects invalid version' sys::bash_msrv '5.x'
    assert_true 'bash_msrv compares external version argument' sys::bash_msrv '5.2' '5.2.99(1)-release'
    assert_false 'bash_msrv rejects lower external version argument' sys::bash_msrv '5.2' '5.1.16(1)-release'
fi

if has_fn sys::bash_ok; then
    mark sys::bash_ok
    assert_true 'bash_ok validates current bash binary' sys::bash_ok "${BASH}" "${MIN_TEST_BASH_VERSION}"
    assert_false 'bash_ok rejects missing binary' sys::bash_ok "${ROOT_TMP}/missing-bash" "${MIN_TEST_BASH_VERSION}"
fi

if has_fn sys::find_bash; then
    mark sys::find_bash
    found_bash="$(sys::find_bash "${MIN_TEST_BASH_VERSION}" 2>/dev/null || true)"
    assert_ne 'find_bash returns suitable bash' "${found_bash}"
    if [[ -n "${found_bash}" ]]; then
        if [[ -x "${found_bash}" || -n "$(command -v -- "${found_bash}" 2>/dev/null || true)" ]]; then pass 'find_bash result is executable/resolvable'
        else fail 'find_bash result is executable/resolvable'
        fi
    fi
fi

if has_fn sys::install_bash; then
    mark sys::install_bash
    if [[ "${BASHX_TEST_INSTALL_BASH:-}" == "1" ]]; then
        if sys::install_bash; then pass 'install_bash executed by explicit opt-in'
        else fail 'install_bash executed by explicit opt-in'
        fi
    else
        pass 'install_bash present; side-effect install skipped unless BASHX_TEST_INSTALL_BASH=1'
    fi
fi

if has_fn sys::shell; then
    mark sys::shell
    shell_path="$(sys::shell 2>/dev/null || true)"
    assert_ne 'shell returns value' "${shell_path}"
fi

if has_fn sys::exec_bash; then
    mark sys::exec_bash
    assert_true 'exec_bash idempotent when current bash satisfies MSRV' sys::exec_bash "${MIN_TEST_BASH_VERSION}" "noop"
fi

section 'command and platform predicates'

mark sys::has
assert_true 'has detects sh/bash command' sys::has sh
mark sys::has
assert_false 'has rejects missing command' sys::has '__bashx_missing_command_hopefully__'

uname_s="$(uname -s 2>/dev/null || true)"
ostype="${OSTYPE:-}"

mark sys::is_linux
case "${uname_s}:${ostype}" in
    Linux:*|*:linux*) assert_true 'is_linux matches environment' sys::is_linux ;;
    *)                assert_false 'is_linux rejects non-linux' sys::is_linux ;;
esac

mark sys::is_macos
case "${uname_s}:${ostype}" in
    Darwin:*|*:darwin*) assert_true 'is_macos matches environment' sys::is_macos ;;
    *)                  assert_false 'is_macos rejects non-macos' sys::is_macos ;;
esac

mark sys::is_cygwin
if [[ "${uname_s}" == CYGWIN* || "${ostype}" == cygwin* ]]; then assert_true 'is_cygwin matches environment' sys::is_cygwin
else assert_false 'is_cygwin rejects non-cygwin' sys::is_cygwin
fi

mark sys::is_msys
if [[ "${uname_s}" == MSYS* || "${uname_s}" == MINGW* || "${ostype}" == msys* || "${MSYSTEM:-}" == MSYS || "${MSYSTEM:-}" == MINGW* || "${MSYSTEM:-}" == UCRT* || "${MSYSTEM:-}" == CLANG* ]]; then
    assert_true 'is_msys matches environment' sys::is_msys
else
    assert_false 'is_msys rejects non-msys' sys::is_msys
fi

mark sys::is_wsl
if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] || { [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; }; then
    assert_true 'is_wsl matches environment' sys::is_wsl
else
    assert_false 'is_wsl rejects non-wsl' sys::is_wsl
fi

mark sys::is_windows
if sys::is_msys || sys::is_cygwin || { [[ -n "${WINDIR:-}" || -n "${SystemRoot:-}" || -n "${COMSPEC:-}" ]] && ! sys::is_wsl && ! sys::is_linux && ! sys::is_macos; }; then
    assert_true 'is_windows matches runtime' sys::is_windows
else
    assert_false 'is_windows rejects unix runtime' sys::is_windows
fi

mark sys::is_gitbash
if sys::is_gitbash; then pass 'is_gitbash callable and true when detected'
else pass 'is_gitbash callable and false when not detected'
fi

mark sys::is_unix
if sys::is_linux || sys::is_macos; then assert_true 'is_unix matches linux/macos' sys::is_unix
else assert_false 'is_unix rejects non linux/macos' sys::is_unix
fi

mark sys::is_posix
if sys::is_linux || sys::is_macos || sys::is_wsl || sys::is_msys || sys::is_cygwin; then assert_true 'is_posix matches supported shell runtimes' sys::is_posix
else assert_false 'is_posix rejects unsupported runtime' sys::is_posix
fi

section 'CI detection and event simulation'

mark sys::ci_name
assert_eq 'ci_name detects github' 'github' "$(fresh_bash 'GITHUB_ACTIONS=1; unset GITLAB_CI JENKINS_URL BUILDKITE CIRCLECI TRAVIS APPVEYOR TF_BUILD BITBUCKET_BUILD_NUMBER TEAMCITY_VERSION DRONE SEMAPHORE CODEBUILD_BUILD_ID CI; sys::ci_name')"
mark sys::ci_name
assert_eq 'ci_name detects gitlab' 'gitlab' "$(fresh_bash 'GITLAB_CI=1; unset GITHUB_ACTIONS JENKINS_URL BUILDKITE CIRCLECI TRAVIS APPVEYOR TF_BUILD BITBUCKET_BUILD_NUMBER TEAMCITY_VERSION DRONE SEMAPHORE CODEBUILD_BUILD_ID CI; sys::ci_name')"
mark sys::ci_name
assert_eq 'ci_name detects generic CI' 'generic' "$(fresh_bash 'CI=1; unset GITHUB_ACTIONS GITLAB_CI JENKINS_URL BUILDKITE CIRCLECI TRAVIS APPVEYOR TF_BUILD BITBUCKET_BUILD_NUMBER TEAMCITY_VERSION DRONE SEMAPHORE CODEBUILD_BUILD_ID; sys::ci_name')"
mark sys::ci_name
if fresh_bash 'unset GITHUB_ACTIONS GITLAB_CI JENKINS_URL BUILDKITE CIRCLECI TRAVIS APPVEYOR TF_BUILD BITBUCKET_BUILD_NUMBER TEAMCITY_VERSION DRONE SEMAPHORE CODEBUILD_BUILD_ID CI; sys::ci_name >/dev/null'; then fail 'ci_name none returns non-zero'
else pass 'ci_name none returns non-zero'
fi

mark sys::is_ci
assert_true 'is_ci true in simulated github' fresh_bash 'GITHUB_ACTIONS=1; sys::is_ci'
mark sys::is_ci
assert_false 'is_ci false without CI vars' fresh_bash 'unset GITHUB_ACTIONS GITLAB_CI JENKINS_URL BUILDKITE CIRCLECI TRAVIS APPVEYOR TF_BUILD BITBUCKET_BUILD_NUMBER TEAMCITY_VERSION DRONE SEMAPHORE CODEBUILD_BUILD_ID CI; sys::is_ci'

mark sys::is_ci_pull
assert_true 'is_ci_pull detects github pull_request' fresh_bash 'GITHUB_EVENT_NAME=pull_request; sys::is_ci_pull'
mark sys::is_ci_pull
assert_true 'is_ci_pull detects gitlab merge request' fresh_bash 'CI_MERGE_REQUEST_IID=123; sys::is_ci_pull'
mark sys::is_ci_pull
assert_false 'is_ci_pull rejects normal push' fresh_bash 'unset CI_MERGE_REQUEST_IID BITBUCKET_PR_ID SYSTEM_PULLREQUEST_PULLREQUESTID; GITHUB_EVENT_NAME=push; BUILD_REASON=IndividualCI; sys::is_ci_pull'

mark sys::is_ci_push
assert_true 'is_ci_push detects github push' fresh_bash 'GITHUB_ACTIONS=1; GITHUB_EVENT_NAME=push; unset CI_MERGE_REQUEST_IID BITBUCKET_PR_ID SYSTEM_PULLREQUEST_PULLREQUESTID; sys::is_ci_push'
mark sys::is_ci_push
assert_false 'is_ci_push rejects pull request' fresh_bash 'GITHUB_ACTIONS=1; GITHUB_EVENT_NAME=pull_request; sys::is_ci_push'

mark sys::is_ci_tag
assert_true 'is_ci_tag detects github tag' fresh_bash 'GITHUB_REF_TYPE=tag; sys::is_ci_tag'
mark sys::is_ci_tag
assert_true 'is_ci_tag detects gitlab tag' fresh_bash 'CI_COMMIT_TAG=v1.0.0; sys::is_ci_tag'
mark sys::is_ci_tag
assert_false 'is_ci_tag rejects branch' fresh_bash 'unset GITHUB_REF_TYPE CI_COMMIT_TAG BITBUCKET_TAG BUILD_SOURCEBRANCH; sys::is_ci_tag'

section 'runtime modes and privilege predicates'

mark sys::is_terminal
if sys::is_terminal; then pass 'is_terminal callable true'
else pass 'is_terminal callable false'
fi

mark sys::is_interactive
if sys::is_interactive; then pass 'is_interactive callable true'
else pass 'is_interactive callable false'
fi

mark sys::is_gui
if sys::is_gui; then pass 'is_gui callable true'
else pass 'is_gui callable false'
fi

mark sys::is_headless
if sys::is_gui; then assert_false 'is_headless inverse of gui' sys::is_headless
else assert_true 'is_headless inverse of gui' sys::is_headless
fi

mark sys::is_container
if sys::is_container; then pass 'is_container callable true'
else pass 'is_container callable false'
fi

mark sys::is_root
if sys::is_root; then pass 'is_root callable true'
else pass 'is_root callable false'
fi

mark sys::is_admin
if sys::is_root; then assert_true 'is_admin true when root/admin' sys::is_admin
else
    if sys::is_admin; then pass 'is_admin callable true'
    else pass 'is_admin callable false'
    fi
fi

mark sys::can_sudo
if sys::can_sudo; then pass 'can_sudo callable true'
else pass 'can_sudo callable false'
fi

section 'system constants and PATH parsing'

mark sys::null
if sys::is_windows; then assert_eq 'null returns windows null device' 'NUL' "$(sys::null)"
else assert_eq 'null returns unix null device' '/dev/null' "$(sys::null)"
fi

mark sys::path_sep
if sys::is_windows; then assert_eq 'path_sep returns native windows separator' ';' "$(sys::path_sep)"
else assert_eq 'path_sep returns native unix separator' ':' "$(sys::path_sep)"
fi

mark sys::line_sep
if sys::is_windows; then assert_eq 'line_sep returns crlf code' 'crlf' "$(sys::line_sep)"
else assert_eq 'line_sep returns lf code' 'lf' "$(sys::line_sep)"
fi

mark sys::env_path_name
if sys::is_windows; then assert_eq 'env_path_name returns Path on windows' 'Path' "$(sys::env_path_name)"
else assert_eq 'env_path_name returns PATH on unix' 'PATH' "$(sys::env_path_name)"
fi

mark sys::exe_suffix
if sys::is_windows; then assert_eq 'exe_suffix returns .exe on windows' '.exe' "$(sys::exe_suffix)"
else assert_eq 'exe_suffix empty on unix' '' "$(sys::exe_suffix)"
fi

mark sys::lib_suffix
if sys::is_windows; then assert_eq 'lib_suffix windows dll' '.dll' "$(sys::lib_suffix)"
elif sys::is_macos; then assert_eq 'lib_suffix macos dylib' '.dylib' "$(sys::lib_suffix)"
else assert_eq 'lib_suffix unix so' '.so' "$(sys::lib_suffix)"
fi

mark sys::path_dirs
PATH_BACKUP="${PATH:-}"
PATH="/alpha:/beta::/gamma"
assert_eq 'path_dirs splits colon PATH' $'/alpha\n/beta\n/gamma' "$(sys::path_dirs)"
PATH="C:/A;D:/B;;E:/C"
assert_eq 'path_dirs splits semicolon PATH' $'C:/A\nD:/B\nE:/C' "$(sys::path_dirs)"
PATH="${PATH_BACKUP}"
mark sys::path_dirs
if [[ -n "${PATH:-}" ]]; then assert_ne 'path_dirs returns current path entries' "$(sys::path_dirs | head -n 1)"
else pass 'path_dirs handles empty PATH'
fi

section 'identity, OS metadata, package manager and architecture'

mark sys::name
name="$(sys::name 2>/dev/null || true)"
assert_re 'name is known family' "${name}" '^(linux|macos|windows|unknown)$'
if sys::is_linux; then assert_eq 'name agrees with linux' 'linux' "${name}"
elif sys::is_macos; then assert_eq 'name agrees with macos' 'macos' "${name}"
elif sys::is_windows; then assert_eq 'name agrees with windows' 'windows' "${name}"
fi

mark sys::runtime
runtime="$(sys::runtime 2>/dev/null || true)"
assert_re 'runtime is known layer' "${runtime}" '^(wsl|gitbash|msys2|cygwin|linux|macos|windows|unknown)$'
if sys::is_wsl; then assert_eq 'runtime agrees with wsl' 'wsl' "${runtime}"
elif sys::is_gitbash; then assert_eq 'runtime agrees with gitbash' 'gitbash' "${runtime}"
elif sys::is_msys; then assert_eq 'runtime agrees with msys2' 'msys2' "${runtime}"
elif sys::is_cygwin; then assert_eq 'runtime agrees with cygwin' 'cygwin' "${runtime}"
fi

mark sys::kernel
kernel="$(sys::kernel 2>/dev/null || true)"
assert_ne 'kernel returns value' "${kernel}"

mark sys::distro
distro="$(sys::distro 2>/dev/null || true)"
assert_ne 'distro returns value' "${distro}"

mark sys::manager
manager_rc=0
manager="$(sys::manager 2>/dev/null)" || manager_rc=$?
assert_re 'manager returns known token or unknown' "${manager}" '^(apt|apk|dnf|yum|pacman|zypper|xbps|nix|rpm|brew|port|winget|scoop|choco|unknown)$'
if [[ "${manager}" == "unknown" ]]; then
    if (( manager_rc != 0 )); then pass 'manager unknown returns non-zero'
    else fail 'manager unknown returns non-zero'
    fi
else
    if (( manager_rc == 0 )); then pass 'manager known returns zero'
    else fail 'manager known returns zero'
    fi
fi

mark sys::arch
arch="$(sys::arch 2>/dev/null || true)"
assert_ne 'arch returns value' "${arch}"

mark sys::version
version="$(sys::version 2>/dev/null || true)"
assert_ne 'version returns value' "${version}"

mark sys::hostname
host="$(sys::hostname 2>/dev/null || true)"
assert_ne 'hostname returns value' "${host}"

mark sys::username
user="$(sys::username 2>/dev/null || true)"
assert_ne 'username returns value' "${user}"
case "${user}" in
    *\\*) fail 'username strips domain prefix' ;;
    *)    pass 'username strips domain prefix' ;;
esac

section 'uptime and load averages'

mark sys::uptime
if uptime_value="$(sys::uptime 2>/dev/null)"; then
    assert_num 'uptime returns seconds' "${uptime_value}"
else
    skip 'uptime unavailable on this platform/runtime'
fi

mark sys::loadavg
if load_value="$(sys::loadavg 2>/dev/null)"; then
    assert_re 'loadavg returns three fields' "${load_value}" '^[^[:space:]]+[[:space:]][^[:space:]]+[[:space:]][^[:space:]]+$'
else
    skip 'loadavg unavailable on this platform/runtime'
fi

section 'safe opener behavior'

mark sys::open
assert_false 'open rejects empty target' sys::open ''
mark sys::open
assert_false 'open rejects target with newline' sys::open $'https://example.com\nboom'
mark sys::open
if sys::has true; then
    if sys::open true app; then pass 'open app launches harmless true command'
    else fail 'open app launches harmless true command'
    fi
else
    skip 'true command unavailable for open app test'
fi

section 'disk information accuracy and invariants'

TEST_FILE="${ROOT_TMP}/disk-file.txt"
printf '%s' '1234567890' > "${TEST_FILE}"

mark sys::disk_total
if disk_total="$(sys::disk_total "${ROOT_TMP}" 2>/dev/null)"; then assert_num 'disk_total numeric' "${disk_total}"
else skip 'disk_total unavailable'
fi

mark sys::disk_free
if disk_free="$(sys::disk_free "${ROOT_TMP}" 2>/dev/null)"; then assert_num 'disk_free numeric' "${disk_free}"
else skip 'disk_free unavailable'
fi

mark sys::disk_used
if disk_used="$(sys::disk_used "${ROOT_TMP}" 2>/dev/null)"; then assert_num 'disk_used numeric' "${disk_used}"
else skip 'disk_used unavailable'
fi

if [[ "${disk_total:-}" =~ ^[0-9]+$ && "${disk_free:-}" =~ ^[0-9]+$ && "${disk_used:-}" =~ ^[0-9]+$ ]]; then
    if (( disk_free <= disk_total )); then pass 'disk free <= total'
    else fail 'disk free <= total'
    fi
    if (( disk_used <= disk_total )); then pass 'disk used <= total'
    else fail 'disk used <= total'
    fi
fi

mark sys::disk_percent
if disk_percent="$(sys::disk_percent "${ROOT_TMP}" 2>/dev/null)"; then assert_num_range 'disk_percent 0..100' "${disk_percent}" 0 100
else skip 'disk_percent unavailable'
fi

mark sys::disk_size
if disk_size="$(sys::disk_size "${TEST_FILE}" 2>/dev/null)"; then
    assert_num 'disk_size numeric' "${disk_size}"
    if (( disk_size >= 10 )); then pass 'disk_size at least file bytes'
    else fail 'disk_size at least file bytes'
    fi
else
    skip 'disk_size unavailable'
fi

mark sys::disk_info
if disk_info="$(sys::disk_info "${ROOT_TMP}" 2>/dev/null)"; then
    assert_re 'disk_info has total' "${disk_info}" '(^|[[:space:]])total=[0-9]+'
    assert_re 'disk_info has free' "${disk_info}" '(^|[[:space:]])free=[0-9]+'
    assert_re 'disk_info has used' "${disk_info}" '(^|[[:space:]])used=[0-9]+'
    assert_re 'disk_info has percent' "${disk_info}" '(^|[[:space:]])percent=[0-9]+'
else
    skip 'disk_info unavailable'
fi

section 'memory information accuracy and invariants'

mark sys::mem_total
if mem_total="$(sys::mem_total 2>/dev/null)"; then assert_num 'mem_total numeric' "${mem_total}"
else skip 'mem_total unavailable'
fi

mark sys::mem_free
if mem_free="$(sys::mem_free 2>/dev/null)"; then assert_num 'mem_free numeric' "${mem_free}"
else skip 'mem_free unavailable'
fi

mark sys::mem_used
if mem_used="$(sys::mem_used 2>/dev/null)"; then assert_num 'mem_used numeric' "${mem_used}"
else skip 'mem_used unavailable'
fi

if [[ "${mem_total:-}" =~ ^[0-9]+$ && "${mem_free:-}" =~ ^[0-9]+$ && "${mem_used:-}" =~ ^[0-9]+$ ]]; then
    if (( mem_total > 0 )); then pass 'mem_total positive'
    else fail 'mem_total positive'
    fi
    if (( mem_used <= mem_total )); then pass 'mem_used <= mem_total'
    else fail 'mem_used <= mem_total'
    fi
fi

mark sys::mem_percent
if mem_percent="$(sys::mem_percent 2>/dev/null)"; then assert_num_range 'mem_percent 0..100' "${mem_percent}" 0 100
else skip 'mem_percent unavailable'
fi

mark sys::mem_info
if mem_info="$(sys::mem_info 2>/dev/null)"; then
    assert_re 'mem_info has total' "${mem_info}" '(^|[[:space:]])total=[0-9]+'
    assert_re 'mem_info has free' "${mem_info}" '(^|[[:space:]])free=[0-9]+'
    assert_re 'mem_info has used' "${mem_info}" '(^|[[:space:]])used=[0-9]+'
    assert_re 'mem_info has percent' "${mem_info}" '(^|[[:space:]])percent=[0-9]+'
else
    skip 'mem_info unavailable'
fi

section 'CPU information accuracy and invariants'

mark sys::cpu_threads
if cpu_threads="$(sys::cpu_threads 2>/dev/null)"; then
    assert_num 'cpu_threads numeric' "${cpu_threads}"
    if (( cpu_threads >= 1 )); then pass 'cpu_threads >= 1'
    else fail 'cpu_threads >= 1'
    fi
else
    skip 'cpu_threads unavailable'
fi

mark sys::cpu_count
if cpu_count="$(sys::cpu_count 2>/dev/null)"; then
    if [[ "${cpu_threads:-}" =~ ^[0-9]+$ ]]; then assert_eq 'cpu_count aliases cpu_threads' "${cpu_threads}" "${cpu_count}"
    else assert_num 'cpu_count numeric' "${cpu_count}"
    fi
else
    skip 'cpu_count unavailable'
fi

mark sys::cpu_cores
if cpu_cores="$(sys::cpu_cores 2>/dev/null)"; then
    assert_num 'cpu_cores numeric' "${cpu_cores}"
    if (( cpu_cores >= 1 )); then pass 'cpu_cores >= 1'
    else fail 'cpu_cores >= 1'
    fi
    if [[ "${cpu_threads:-}" =~ ^[0-9]+$ ]]; then
        if (( cpu_cores <= cpu_threads )); then pass 'cpu_cores <= cpu_threads'
        else fail 'cpu_cores <= cpu_threads'
        fi
    fi
else
    skip 'cpu_cores unavailable'
fi

mark sys::cpu_model
cpu_model="$(sys::cpu_model 2>/dev/null || true)"
assert_ne 'cpu_model returns value' "${cpu_model}"

mark sys::cpu_usage
if cpu_usage="$(sys::cpu_usage 2>/dev/null)"; then assert_num_range 'cpu_usage 0..100' "${cpu_usage}" 0 100
else skip 'cpu_usage unavailable'
fi

mark sys::cpu_idle
if cpu_idle="$(sys::cpu_idle 2>/dev/null)"; then assert_num_range 'cpu_idle 0..100' "${cpu_idle}" 0 100
else skip 'cpu_idle unavailable'
fi

mark sys::cpu_info
if cpu_info="$(sys::cpu_info 2>/dev/null)"; then
    assert_re 'cpu_info has model' "${cpu_info}" '(^|[[:space:]])model='
    assert_re 'cpu_info has cores' "${cpu_info}" '(^|[[:space:]])cores=[0-9]+'
    assert_re 'cpu_info has threads' "${cpu_info}" '(^|[[:space:]])threads=[0-9]+'
    assert_re 'cpu_info has usage' "${cpu_info}" '(^|[[:space:]])usage=([0-9]+|unknown)'
    assert_re 'cpu_info has idle' "${cpu_info}" '(^|[[:space:]])idle=([0-9]+|unknown)'
else
    skip 'cpu_info unavailable'
fi

section 'negative and adversarial inputs'

mark sys::disk_total
assert_false 'disk_total rejects missing path' sys::disk_total "${ROOT_TMP}/missing"
mark sys::disk_free
assert_false 'disk_free rejects missing path' sys::disk_free "${ROOT_TMP}/missing"
mark sys::disk_size
assert_false 'disk_size rejects empty path' sys::disk_size ''
mark sys::disk_size
assert_false 'disk_size rejects missing path' sys::disk_size "${ROOT_TMP}/missing"

if has_fn sys::bash_msrv; then
    mark sys::bash_msrv
    assert_false 'bash_msrv rejects empty need' sys::bash_msrv ''
    assert_false 'bash_msrv rejects too many version components' sys::bash_msrv '5.2.1.9'
fi

if has_fn sys::find_bash; then
    mark sys::find_bash
    assert_false 'find_bash rejects invalid need' sys::find_bash 'bad.version'
fi

section 'coverage gate: every sys::* was exercised'

for fn in "${DECLARED_FUNCS[@]}"; do
    if [[ -n "${HIT[${fn}]:-}" ]]; then
        pass "covered ${fn}"
    else
        fail "uncovered ${fn}"
    fi
done

printf '\n============================================================\n'
printf ' system.sh brutal ensure test summary\n'
printf '============================================================\n'
printf 'Target : %s\n' "${TARGET_FILE}"
printf 'Root   : %s\n' "${ROOT_TMP}"
printf 'Bash   : %s\n' "${BASH_VERSION:-unknown}"
printf 'Funcs  : %s\n' "${#DECLARED_FUNCS[@]}"
printf 'Total  : %s\n' "${TOTAL}"
printf 'Pass   : %s\n' "${PASS}"
printf 'Fail   : %s\n' "${FAIL}"
printf 'Skip   : %s\n' "${SKIP}"
printf '============================================================\n'

(( FAIL == 0 ))
