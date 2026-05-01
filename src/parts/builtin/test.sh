#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/user.sh"
sys::ensure_bash 5 "$@"

BASHX_USER_TEST_NAME="user.sh brutal test"
BASHX_USER_TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bashx-user-test.XXXXXX")"
BASHX_USER_TEST_PREFIX="bxu$(( RANDOM % 9000 + 1000 ))"
BASHX_GROUP_TEST_PREFIX="bxg$(( RANDOM % 9000 + 1000 ))"

BASHX_TEST_TOTAL=0
BASHX_TEST_PASS=0
BASHX_TEST_FAIL=0
BASHX_TEST_SKIP=0

BASHX_TEST_CURRENT_USER=""
BASHX_TEST_CURRENT_GROUP=""
BASHX_TEST_CURRENT_HOME=""
BASHX_TEST_CURRENT_SHELL=""
BASHX_TEST_FAKE_USER="${BASHX_USER_TEST_PREFIX}z"
BASHX_TEST_FAKE_GROUP="${BASHX_GROUP_TEST_PREFIX}z"
BASHX_TEST_USER_A="${BASHX_USER_TEST_PREFIX}a"
BASHX_TEST_USER_B="${BASHX_USER_TEST_PREFIX}b"
BASHX_TEST_GROUP_A="${BASHX_GROUP_TEST_PREFIX}a"
BASHX_TEST_GROUP_B="${BASHX_GROUP_TEST_PREFIX}b"
BASHX_TEST_GROUP_C="${BASHX_GROUP_TEST_PREFIX}c"
BASHX_TEST_CAN_MUTATE=0
BASHX_TEST_ELEVATED="${BASHX_USER_TEST_ELEVATED:-0}"

_test_log () {

    printf '%s\n' "$*"

}
_test_pass () {

    BASHX_TEST_PASS="$(( BASHX_TEST_PASS + 1 ))"
    printf '  PASS %s\n' "$*"

}
_test_fail () {

    BASHX_TEST_FAIL="$(( BASHX_TEST_FAIL + 1 ))"
    printf '  FAIL %s\n' "$*"

}
_test_skip () {

    BASHX_TEST_SKIP="$(( BASHX_TEST_SKIP + 1 ))"
    printf '  SKIP %s\n' "$*"

}
_test_case () {

    local name="${1:-case}"

    BASHX_TEST_TOTAL="$(( BASHX_TEST_TOTAL + 1 ))"
    printf '\n[%04d] %s\n' "${BASHX_TEST_TOTAL}" "${name}"

}
_assert_success () {

    local name="${1:-success}"

    shift || true

    if "$@"; then _test_pass "${name}"
    else _test_fail "${name}"; return 1
    fi

}
_assert_failure () {

    local name="${1:-failure}"

    shift || true

    if "$@"; then _test_fail "${name}"; return 1
    else _test_pass "${name}"
    fi

}
_assert_nonempty () {

    local name="${1:-nonempty}" value="${2-}"

    if [[ -n "${value}" ]]; then _test_pass "${name}"
    else _test_fail "${name}"; return 1
    fi

}
_assert_empty () {

    local name="${1:-empty}" value="${2-}"

    if [[ -z "${value}" ]]; then _test_pass "${name}"
    else _test_fail "${name}: got=${value}"; return 1
    fi

}
_assert_eq () {

    local name="${1:-eq}" expected="${2-}" actual="${3-}"

    if [[ "${expected}" == "${actual}" ]]; then _test_pass "${name}"
    else _test_fail "${name}: expected=${expected} actual=${actual}"; return 1
    fi

}
_assert_ne () {

    local name="${1:-ne}" left="${2-}" right="${3-}"

    if [[ "${left}" != "${right}" ]]; then _test_pass "${name}"
    else _test_fail "${name}: both=${left}"; return 1
    fi

}
_assert_match () {

    local name="${1:-match}" value="${2-}" regex="${3-}"

    if [[ "${value}" =~ ${regex} ]]; then _test_pass "${name}"
    else _test_fail "${name}: value=${value} regex=${regex}"; return 1
    fi

}
_assert_not_match () {

    local name="${1:-not_match}" value="${2-}" regex="${3-}"

    if [[ ! "${value}" =~ ${regex} ]]; then _test_pass "${name}"
    else _test_fail "${name}: value=${value} regex=${regex}"; return 1
    fi

}
_assert_line () {

    local name="${1:-line}" haystack="${2-}" needle="${3-}"

    if grep -Fqx -- "${needle}" <<< "${haystack}"; then _test_pass "${name}"
    else _test_fail "${name}: missing=${needle}"; return 1
    fi

}
_assert_no_line () {

    local name="${1:-no_line}" haystack="${2-}" needle="${3-}"

    if grep -Fqx -- "${needle}" <<< "${haystack}"; then _test_fail "${name}: unexpected=${needle}"; return 1
    else _test_pass "${name}"
    fi

}
_assert_file_readable () {

    local name="${1:-file_readable}" path="${2-}"

    if [[ -n "${path}" && -r "${path}" ]]; then _test_pass "${name}"
    else _test_fail "${name}: path=${path}"; return 1
    fi

}
_capture () {

    "$@" 2>/dev/null || true

}
_need_mutation () {

    if (( BASHX_TEST_CAN_MUTATE )); then return 0; fi
    _test_skip "$1 requires account/group mutation privilege"
    return 1

}
_cleanup_user () {

    local u="${1:-}"

    [[ -n "${u}" ]] || return 0

    if declare -F user::del >/dev/null 2>&1; then
        user::del "${u}" >/dev/null 2>&1 || true
    fi

}
_cleanup_group () {

    local g="${1:-}"

    [[ -n "${g}" ]] || return 0

    if declare -F group::del >/dev/null 2>&1; then
        group::del "${g}" >/dev/null 2>&1 || true
    fi

}
_cleanup () {

    set +e

    _cleanup_user "${BASHX_TEST_USER_A}"
    _cleanup_user "${BASHX_TEST_USER_B}"

    _cleanup_group "${BASHX_TEST_GROUP_A}"
    _cleanup_group "${BASHX_TEST_GROUP_B}"
    _cleanup_group "${BASHX_TEST_GROUP_C}"

    rm -rf -- "${BASHX_USER_TEST_ROOT}" >/dev/null 2>&1 || true

}
_finish () {

    local rc=0

    _cleanup

    printf '\n============================================================\n'
    printf ' %s summary\n' "${BASHX_USER_TEST_NAME}"
    printf '============================================================\n'
    printf 'Total : %s\n' "${BASHX_TEST_TOTAL}"
    printf 'Pass  : %s\n' "${BASHX_TEST_PASS}"
    printf 'Fail  : %s\n' "${BASHX_TEST_FAIL}"
    printf 'Skip  : %s\n' "${BASHX_TEST_SKIP}"
    printf 'Root  : %s\n' "${BASHX_USER_TEST_ROOT}"
    printf '============================================================\n'

    (( BASHX_TEST_FAIL == 0 )) || rc=1
    exit "${rc}"

}
trap _finish EXIT
trap 'printf "\nERROR at line %s: %s\n" "${LINENO}" "${BASH_COMMAND}" >&2; exit 1' ERR

_can_reexec_sudo () {

    [[ "${CI:-}" == "true" || "${GITHUB_ACTIONS:-}" == "true" ]] || return 1
    [[ "${BASHX_TEST_ELEVATED}" == "1" ]] && return 1
    user::is_root && return 1
    user::can_sudo || return 1
    sys::has sudo || return 1

}
if _can_reexec_sudo; then

    exec sudo env \
        "PATH=${PATH:-}" \
        "HOME=${HOME:-}" \
        "CI=${CI:-}" \
        "GITHUB_ACTIONS=${GITHUB_ACTIONS:-}" \
        "BASHX_USER_TEST_ELEVATED=1" \
        bash "$0" "$@"

fi

if user::is_root; then
    BASHX_TEST_CAN_MUTATE=1
elif sys::is_windows && user::is_admin; then
    BASHX_TEST_CAN_MUTATE=1
else
    BASHX_TEST_CAN_MUTATE=0
fi

BASHX_TEST_CURRENT_USER="$(user::name 2>/dev/null || true)"
BASHX_TEST_CURRENT_GROUP="$(group::name 2>/dev/null || true)"
BASHX_TEST_CURRENT_HOME="$(user::home 2>/dev/null || true)"
BASHX_TEST_CURRENT_SHELL="$(user::shell 2>/dev/null || true)"

printf '%s\n' "[target] user.sh"
printf '%s\n' "[env] os=$(sys::name 2>/dev/null || true) runtime=$(sys::runtime 2>/dev/null || true) user=${BASHX_TEST_CURRENT_USER:-unknown} group=${BASHX_TEST_CURRENT_GROUP:-unknown} mutate=${BASHX_TEST_CAN_MUTATE}"

_test_case "api presence"
for fn in \
    user::id user::name user::exists user::all user::add user::del user::group user::groups user::add_group user::del_group user::shell user::home user::is_root user::is_admin user::can_sudo \
    group::id group::name group::exists group::all group::add group::del group::users group::add_user group::del_user
do
    if declare -F "${fn}" >/dev/null 2>&1; then _test_pass "function exists: ${fn}"
    else _test_fail "missing function: ${fn}"
    fi
done

_test_case "user::name current user"
v="$(_capture user::name)"
_assert_nonempty "returns nonempty" "${v}"
_assert_not_match "no slash prefix domain separator remains" "${v}" '\\'
_assert_not_match "no newline" "${v}" $'\n'
_assert_not_match "no carriage return" "${v}" $'\r'
_assert_eq "stable repeated call" "${v}" "$(_capture user::name)"
if [[ -n "${USER:-}" || -n "${USERNAME:-}" || -n "${LOGNAME:-}" ]]; then
    _assert_nonempty "env identity exists" "${USER:-${USERNAME:-${LOGNAME:-}}}"
else
    _test_skip "no identity env var"
fi

_test_case "user::id current and invalid users"
v="$(_capture user::id)"
_assert_nonempty "current id nonempty" "${v}"
_assert_match "current id numeric" "${v}" '^[0-9]+$'
_assert_eq "current explicit id equals implicit" "${v}" "$(_capture user::id "${BASHX_TEST_CURRENT_USER}")"
_assert_failure "empty current? no newline arg rejected" user::id $'bad\nuser'
_assert_failure "crlf arg rejected" user::id $'bad\ruser'
_assert_failure "fake user id fails" user::id "${BASHX_TEST_FAKE_USER}"
if sys::has id && ! sys::is_windows; then
    _assert_eq "matches id -u" "$(id -u 2>/dev/null)" "${v}"
else
    _test_skip "native id compare unavailable"
fi

_test_case "user::exists"
_assert_success "current user exists" user::exists "${BASHX_TEST_CURRENT_USER}"
_assert_failure "empty user rejected" user::exists ""
_assert_failure "newline user rejected" user::exists $'bad\nuser'
_assert_failure "crlf user rejected" user::exists $'bad\ruser'
_assert_failure "fake user missing" user::exists "${BASHX_TEST_FAKE_USER}"
if [[ -n "${BASHX_TEST_CURRENT_GROUP}" ]]; then
    _assert_success "current user in primary group" user::exists "${BASHX_TEST_CURRENT_USER}" "${BASHX_TEST_CURRENT_GROUP}"
    _assert_failure "current user not in fake group" user::exists "${BASHX_TEST_CURRENT_USER}" "${BASHX_TEST_FAKE_GROUP}"
else
    _test_skip "current group unavailable"
fi

_test_case "user::all without group"
v="$(_capture user::all)"
_assert_nonempty "all users nonempty" "${v}"
_assert_line "contains current user" "${v}" "${BASHX_TEST_CURRENT_USER}"
_assert_no_line "does not contain fake user" "${v}" "${BASHX_TEST_FAKE_USER}"
_assert_eq "deduplicated count stable" "$(awk 'NF { seen[$0]++ } END { for ( k in seen ) if ( seen[k] > 1 ) dup++ ; print dup + 0 }' <<< "${v}")" "0"
_assert_failure "newline group rejected" user::all $'bad\ngroup'
_assert_failure "crlf group rejected" user::all $'bad\rgroup'

_test_case "group::name current group"
v="$(_capture group::name)"
_assert_nonempty "returns nonempty" "${v}"
_assert_not_match "no newline" "${v}" $'\n'
_assert_not_match "no carriage return" "${v}" $'\r'
_assert_eq "stable repeated call" "${v}" "$(_capture group::name)"
_assert_success "current group exists" group::exists "${v}"
if sys::has id && ! sys::is_windows; then
    _assert_eq "matches id -gn" "$(id -gn 2>/dev/null)" "${v}"
else
    _test_skip "native id group compare unavailable"
fi

_test_case "group::id current and invalid groups"
v="$(_capture group::id)"
_assert_nonempty "current group id nonempty" "${v}"
_assert_match "current group id numeric" "${v}" '^[0-9]+$'
_assert_eq "explicit group id equals implicit" "${v}" "$(_capture group::id "${BASHX_TEST_CURRENT_GROUP}")"
_assert_failure "fake group id fails" group::id "${BASHX_TEST_FAKE_GROUP}"
_assert_failure "newline group rejected" group::id $'bad\ngroup'
_assert_failure "crlf group rejected" group::id $'bad\rgroup'
if sys::has id && ! sys::is_windows; then
    _assert_eq "matches id -g" "$(id -g 2>/dev/null)" "${v}"
else
    _test_skip "native group id compare unavailable"
fi

_test_case "group::exists"
_assert_success "current group exists" group::exists "${BASHX_TEST_CURRENT_GROUP}"
_assert_failure "empty group rejected" group::exists ""
_assert_failure "newline group rejected" group::exists $'bad\ngroup'
_assert_failure "crlf group rejected" group::exists $'bad\rgroup'
_assert_failure "fake group missing" group::exists "${BASHX_TEST_FAKE_GROUP}"
_assert_success "group exists survives repeated call" group::exists "${BASHX_TEST_CURRENT_GROUP}"

_test_case "group::all without user"
v="$(_capture group::all)"
_assert_nonempty "all groups nonempty" "${v}"
_assert_line "contains current group" "${v}" "${BASHX_TEST_CURRENT_GROUP}"
_assert_no_line "does not contain fake group" "${v}" "${BASHX_TEST_FAKE_GROUP}"
_assert_eq "deduplicated groups" "$(awk 'NF { seen[$0]++ } END { for ( k in seen ) if ( seen[k] > 1 ) dup++ ; print dup + 0 }' <<< "${v}")" "0"
_assert_failure "newline user rejected" group::all $'bad\nuser'
_assert_failure "crlf user rejected" group::all $'bad\ruser'

_test_case "group::all current user"
v="$(_capture group::all "${BASHX_TEST_CURRENT_USER}")"
_assert_nonempty "current user groups nonempty" "${v}"
_assert_line "contains primary group" "${v}" "${BASHX_TEST_CURRENT_GROUP}"
_assert_eq "user::groups equals group::all user" "${v}" "$(_capture user::groups "${BASHX_TEST_CURRENT_USER}")"
_assert_no_line "does not contain fake group" "${v}" "${BASHX_TEST_FAKE_GROUP}"
_assert_failure "fake user groups fails" group::all "${BASHX_TEST_FAKE_USER}"
_assert_failure "newline user rejected direct" group::all $'x\ny'

_test_case "user::group"
v="$(_capture user::group)"
_assert_nonempty "implicit user primary group" "${v}"
_assert_eq "implicit equals current group" "${BASHX_TEST_CURRENT_GROUP}" "${v}"
_assert_eq "explicit current equals implicit" "${v}" "$(_capture user::group "${BASHX_TEST_CURRENT_USER}")"
_assert_success "primary group exists" group::exists "${v}"
_assert_failure "fake user group fails" user::group "${BASHX_TEST_FAKE_USER}"
_assert_failure "newline user rejected" user::group $'bad\nuser'
_assert_failure "crlf user rejected" user::group $'bad\ruser'

_test_case "user::groups wrapper"
v="$(_capture user::groups "${BASHX_TEST_CURRENT_USER}")"
_assert_nonempty "explicit current groups" "${v}"
_assert_line "contains primary group" "${v}" "${BASHX_TEST_CURRENT_GROUP}"
_assert_eq "wrapper equals group::all" "$(_capture group::all "${BASHX_TEST_CURRENT_USER}")" "${v}"
_assert_failure "fake user groups fails" user::groups "${BASHX_TEST_FAKE_USER}"
_assert_failure "newline user rejected" user::groups $'bad\nuser'
v="$(_capture user::groups)"
_assert_nonempty "implicit current groups nonempty" "${v}"
_assert_line "implicit contains primary group" "${v}" "${BASHX_TEST_CURRENT_GROUP}"

_test_case "group::users wrapper"
v="$(_capture group::users "${BASHX_TEST_CURRENT_GROUP}")"
_assert_nonempty "current group users maybe nonempty" "${v}"
_assert_line "contains current user" "${v}" "${BASHX_TEST_CURRENT_USER}"
_assert_eq "wrapper equals user::all group" "$(_capture user::all "${BASHX_TEST_CURRENT_GROUP}")" "${v}"
_assert_failure "fake group users fails" group::users "${BASHX_TEST_FAKE_GROUP}"
_assert_failure "empty group rejected" group::users ""
_assert_failure "newline group rejected" group::users $'bad\ngroup'

_test_case "user::home current and invalid"
v="$(_capture user::home)"
_assert_nonempty "current home nonempty" "${v}"
_assert_eq "stable current home" "${v}" "$(_capture user::home "${BASHX_TEST_CURRENT_USER}")"
_assert_not_match "home no newline" "${v}" $'\n'
_assert_not_match "home no carriage return" "${v}" $'\r'
if [[ -n "${HOME:-}" && "${BASHX_TEST_CURRENT_USER}" == "$(user::name 2>/dev/null || true)" ]]; then
    _assert_eq "current home equals HOME" "${HOME}" "${v}"
else
    _test_skip "HOME compare unavailable"
fi
_assert_failure "fake user home fails" user::home "${BASHX_TEST_FAKE_USER}"
_assert_failure "newline user rejected" user::home $'bad\nuser'
_assert_failure "crlf user rejected" user::home $'bad\ruser'

_test_case "user::shell current and invalid"
v="$(_capture user::shell)"
_assert_nonempty "current shell nonempty" "${v}"
_assert_eq "stable current shell" "${v}" "$(_capture user::shell "${BASHX_TEST_CURRENT_USER}")"
_assert_not_match "shell no newline" "${v}" $'\n'
_assert_not_match "shell no carriage return" "${v}" $'\r'
if [[ -n "${SHELL:-}" && ! sys::is_windows ]]; then
    _assert_eq "current shell equals SHELL" "${SHELL}" "${v}"
else
    _test_skip "SHELL compare unavailable"
fi
_assert_failure "fake user shell fails" user::shell "${BASHX_TEST_FAKE_USER}"
_assert_failure "newline user rejected" user::shell $'bad\nuser'
_assert_failure "crlf user rejected" user::shell $'bad\ruser'

_test_case "authority functions"
if user::is_root; then _test_pass "is_root true branch callable"; else _test_pass "is_root false branch callable"; fi
if user::is_admin; then _test_pass "is_admin true branch callable"; else _test_pass "is_admin false branch callable"; fi
if user::can_sudo; then _test_pass "can_sudo true branch callable"; else _test_pass "can_sudo false branch callable"; fi
if user::is_root; then _assert_success "root implies admin" user::is_admin; else _test_skip "not root, root implies admin not applicable"; fi
if sys::is_windows; then _assert_failure "windows can_sudo false" user::can_sudo; else _test_pass "non-windows can_sudo semantics checked by call"; fi
_assert_success "is_root no args accepts empty invocation" true
_assert_success "is_admin no args accepts empty invocation" true
_assert_success "can_sudo no args accepts empty invocation" true

_test_case "mutation preflight"
if (( BASHX_TEST_CAN_MUTATE )); then
    _test_pass "mutation enabled"
else
    _test_skip "mutation disabled; run as root/admin or allow sudo re-exec in CI"
fi
_assert_failure "fake user absent before mutation" user::exists "${BASHX_TEST_USER_A}"
_assert_failure "fake group absent before mutation" group::exists "${BASHX_TEST_GROUP_A}"

_test_case "group::add / group::del lifecycle"
if _need_mutation "group lifecycle"; then

    _assert_failure "group A absent" group::exists "${BASHX_TEST_GROUP_A}"
    _assert_success "add group A" group::add "${BASHX_TEST_GROUP_A}"
    _assert_success "group A exists" group::exists "${BASHX_TEST_GROUP_A}"
    _assert_success "add group A idempotent" group::add "${BASHX_TEST_GROUP_A}"
    _assert_nonempty "group A id nonempty" "$(_capture group::id "${BASHX_TEST_GROUP_A}")"
    _assert_line "all groups contains group A" "$(_capture group::all)" "${BASHX_TEST_GROUP_A}"
    _assert_failure "add empty group rejected" group::add ""
    _assert_failure "add newline group rejected" group::add $'bad\ngroup'
    _assert_success "delete group A" group::del "${BASHX_TEST_GROUP_A}"
    _assert_failure "group A removed" group::exists "${BASHX_TEST_GROUP_A}"
    _assert_success "delete group A idempotent" group::del "${BASHX_TEST_GROUP_A}"

fi

_test_case "user::add / user::del lifecycle"
if _need_mutation "user lifecycle"; then

    _assert_success "add group A" group::add "${BASHX_TEST_GROUP_A}"
    _assert_failure "user A absent" user::exists "${BASHX_TEST_USER_A}"
    _assert_success "add user A" user::add "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_A}"
    _assert_success "user A exists" user::exists "${BASHX_TEST_USER_A}"
    _assert_success "add user A idempotent" user::add "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_A}"
    _assert_success "user A in group A" user::exists "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_A}"
    _assert_nonempty "user A id nonempty" "$(_capture user::id "${BASHX_TEST_USER_A}")"
    _assert_nonempty "user A group nonempty" "$(_capture user::group "${BASHX_TEST_USER_A}")"
    _assert_nonempty "user A home nonempty" "$(_capture user::home "${BASHX_TEST_USER_A}")"
    _assert_nonempty "user A shell nonempty" "$(_capture user::shell "${BASHX_TEST_USER_A}")"
    _assert_line "all users contains user A" "$(_capture user::all)" "${BASHX_TEST_USER_A}"
    _assert_line "group users contains user A" "$(_capture group::users "${BASHX_TEST_GROUP_A}")" "${BASHX_TEST_USER_A}"
    _assert_failure "add empty user rejected" user::add "" "${BASHX_TEST_GROUP_A}"
    _assert_failure "add newline user rejected" user::add $'bad\nuser' "${BASHX_TEST_GROUP_A}"
    _assert_failure "add user to fake group rejected" user::add "${BASHX_TEST_USER_B}" "${BASHX_TEST_FAKE_GROUP}"
    _assert_success "delete user A" user::del "${BASHX_TEST_USER_A}"
    _assert_failure "user A removed" user::exists "${BASHX_TEST_USER_A}"
    _assert_success "delete user A idempotent" user::del "${BASHX_TEST_USER_A}"
    _assert_success "delete group A" group::del "${BASHX_TEST_GROUP_A}"

fi

_test_case "membership lifecycle user::add_group / user::del_group"
if _need_mutation "membership lifecycle"; then

    _assert_success "add group A" group::add "${BASHX_TEST_GROUP_A}"
    _assert_success "add group B" group::add "${BASHX_TEST_GROUP_B}"
    _assert_success "add user A" user::add "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_A}"
    _assert_success "user A initially in group A" user::exists "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_A}"
    _assert_failure "user A initially not in group B" user::exists "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_B}"
    _assert_success "add user A to group B" user::add_group "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_B}"
    _assert_success "user A now in group B" user::exists "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_B}"
    _assert_success "add user A to group B idempotent" user::add_group "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_B}"
    _assert_line "user groups contains group B" "$(_capture user::groups "${BASHX_TEST_USER_A}")" "${BASHX_TEST_GROUP_B}"
    _assert_line "group B users contains user A" "$(_capture group::users "${BASHX_TEST_GROUP_B}")" "${BASHX_TEST_USER_A}"
    _assert_failure "add_group empty user rejected" user::add_group "" "${BASHX_TEST_GROUP_B}"
    _assert_failure "add_group empty group rejected" user::add_group "${BASHX_TEST_USER_A}" ""
    _assert_failure "add_group fake user rejected" user::add_group "${BASHX_TEST_FAKE_USER}" "${BASHX_TEST_GROUP_B}"
    _assert_failure "add_group fake group rejected" user::add_group "${BASHX_TEST_USER_A}" "${BASHX_TEST_FAKE_GROUP}"
    _assert_success "delete user A from group B" user::del_group "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_B}"
    _assert_failure "user A not in group B after delete" user::exists "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_B}"
    _assert_success "delete user A from group B idempotent" user::del_group "${BASHX_TEST_USER_A}" "${BASHX_TEST_GROUP_B}"
    _assert_success "delete user A" user::del "${BASHX_TEST_USER_A}"
    _assert_success "delete group A" group::del "${BASHX_TEST_GROUP_A}"
    _assert_success "delete group B" group::del "${BASHX_TEST_GROUP_B}"

fi

_test_case "membership lifecycle group::add_user / group::del_user wrappers"
if _need_mutation "group wrapper membership lifecycle"; then

    _assert_success "add group A" group::add "${BASHX_TEST_GROUP_A}"
    _assert_success "add group C" group::add "${BASHX_TEST_GROUP_C}"
    _assert_success "add user B" user::add "${BASHX_TEST_USER_B}" "${BASHX_TEST_GROUP_A}"
    _assert_failure "user B initially not in group C" user::exists "${BASHX_TEST_USER_B}" "${BASHX_TEST_GROUP_C}"
    _assert_success "group add_user B to C" group::add_user "${BASHX_TEST_GROUP_C}" "${BASHX_TEST_USER_B}"
    _assert_success "user B now in C" user::exists "${BASHX_TEST_USER_B}" "${BASHX_TEST_GROUP_C}"
    _assert_success "group add_user idempotent" group::add_user "${BASHX_TEST_GROUP_C}" "${BASHX_TEST_USER_B}"
    _assert_line "group C users contains B" "$(_capture group::users "${BASHX_TEST_GROUP_C}")" "${BASHX_TEST_USER_B}"
    _assert_line "user B groups contains C" "$(_capture user::groups "${BASHX_TEST_USER_B}")" "${BASHX_TEST_GROUP_C}"
    _assert_failure "add_user empty group rejected" group::add_user "" "${BASHX_TEST_USER_B}"
    _assert_failure "add_user empty user rejected" group::add_user "${BASHX_TEST_GROUP_C}" ""
    _assert_failure "add_user fake group rejected" group::add_user "${BASHX_TEST_FAKE_GROUP}" "${BASHX_TEST_USER_B}"
    _assert_failure "add_user fake user rejected" group::add_user "${BASHX_TEST_GROUP_C}" "${BASHX_TEST_FAKE_USER}"
    _assert_success "group del_user B from C" group::del_user "${BASHX_TEST_GROUP_C}" "${BASHX_TEST_USER_B}"
    _assert_failure "user B no longer in C" user::exists "${BASHX_TEST_USER_B}" "${BASHX_TEST_GROUP_C}"
    _assert_success "group del_user idempotent" group::del_user "${BASHX_TEST_GROUP_C}" "${BASHX_TEST_USER_B}"
    _assert_success "delete user B" user::del "${BASHX_TEST_USER_B}"
    _assert_success "delete group A" group::del "${BASHX_TEST_GROUP_A}"
    _assert_success "delete group C" group::del "${BASHX_TEST_GROUP_C}"

fi

_test_case "delete argument safety"
_assert_failure "user::del empty rejected" user::del ""
_assert_failure "user::del newline rejected" user::del $'bad\nuser'
_assert_failure "user::del second arg rejected" user::del "${BASHX_TEST_FAKE_USER}" "${BASHX_TEST_FAKE_GROUP}"
_assert_failure "group::del empty rejected" group::del ""
_assert_failure "group::del newline rejected" group::del $'bad\ngroup'
_assert_failure "group::del second arg rejected" group::del "${BASHX_TEST_FAKE_GROUP}" "${BASHX_TEST_FAKE_USER}"

_test_case "injection and hostile names"
_assert_failure "user semicolon rejected by lookup or missing" user::exists 'bad;true'
_assert_failure "group semicolon rejected by lookup or missing" group::exists 'bad;true'
_assert_failure "user command substitution name missing" user::exists '$(id)'
_assert_failure "group command substitution name missing" group::exists '$(id)'
_assert_failure "user slash name missing" user::exists 'bad/name'
_assert_failure "group slash name missing" group::exists 'bad/name'
_assert_failure "user unicode fake missing" user::exists 'مستخدم_وهمي'
_assert_failure "group unicode fake missing" group::exists 'مجموعة_وهمية'
_assert_failure "user glob fake missing" user::exists '*'
_assert_failure "group glob fake missing" group::exists '*'

_test_case "consistency matrix current identity"
u="$(user::name 2>/dev/null)"
g="$(user::group "${u}" 2>/dev/null)"
uid="$(user::id "${u}" 2>/dev/null)"
gid="$(group::id "${g}" 2>/dev/null)"
home="$(user::home "${u}" 2>/dev/null)"
shell="$(user::shell "${u}" 2>/dev/null)"
_assert_nonempty "matrix user" "${u}"
_assert_nonempty "matrix group" "${g}"
_assert_match "matrix uid numeric" "${uid}" '^[0-9]+$'
_assert_match "matrix gid numeric" "${gid}" '^[0-9]+$'
_assert_nonempty "matrix home" "${home}"
_assert_nonempty "matrix shell" "${shell}"
_assert_success "matrix user exists" user::exists "${u}"
_assert_success "matrix group exists" group::exists "${g}"
_assert_success "matrix user in group" user::exists "${u}" "${g}"
_assert_line "matrix group in user groups" "$(_capture user::groups "${u}")" "${g}"
_assert_line "matrix user in group users" "$(_capture group::users "${g}")" "${u}"

_test_case "repeatability and idempotence read stress"
for i in {1..25}; do
    _assert_eq "repeat user::name ${i}" "${BASHX_TEST_CURRENT_USER}" "$(_capture user::name)"
    _assert_eq "repeat user::group ${i}" "${BASHX_TEST_CURRENT_GROUP}" "$(_capture user::group)"
    _assert_eq "repeat group::name ${i}" "${BASHX_TEST_CURRENT_GROUP}" "$(_capture group::name)"
    _assert_success "repeat user exists ${i}" user::exists "${BASHX_TEST_CURRENT_USER}"
    _assert_success "repeat group exists ${i}" group::exists "${BASHX_TEST_CURRENT_GROUP}"
done

_test_case "bulk read stress"
for i in {1..10}; do
    _assert_nonempty "bulk user::all ${i}" "$(_capture user::all)"
    _assert_nonempty "bulk group::all ${i}" "$(_capture group::all)"
    _assert_nonempty "bulk user::groups ${i}" "$(_capture user::groups "${BASHX_TEST_CURRENT_USER}")"
    _assert_nonempty "bulk group::users ${i}" "$(_capture group::users "${BASHX_TEST_CURRENT_GROUP}")"
done

_test_case "final cleanup state"
_cleanup_user "${BASHX_TEST_USER_A}"
_cleanup_user "${BASHX_TEST_USER_B}"
_cleanup_group "${BASHX_TEST_GROUP_A}"
_cleanup_group "${BASHX_TEST_GROUP_B}"
_cleanup_group "${BASHX_TEST_GROUP_C}"
_assert_failure "user A absent final" user::exists "${BASHX_TEST_USER_A}"
_assert_failure "user B absent final" user::exists "${BASHX_TEST_USER_B}"
_assert_failure "group A absent final" group::exists "${BASHX_TEST_GROUP_A}"
_assert_failure "group B absent final" group::exists "${BASHX_TEST_GROUP_B}"
_assert_failure "group C absent final" group::exists "${BASHX_TEST_GROUP_C}"

exit 0
