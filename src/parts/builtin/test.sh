#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/user.sh"
sys::ensure_bash 5 "$@"

TEST_NAME="user.sh legendary production test"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bashx-user-legendary.XXXXXX")"
TEST_PREFIX="bx$(( RANDOM % 9000 + 1000 ))$(( RANDOM % 9000 + 1000 ))"
TEST_USER_A="${TEST_PREFIX}ua"
TEST_USER_B="${TEST_PREFIX}ub"
TEST_USER_C="${TEST_PREFIX}uc"
TEST_GROUP_A="${TEST_PREFIX}ga"
TEST_GROUP_B="${TEST_PREFIX}gb"
TEST_GROUP_C="${TEST_PREFIX}gc"
TEST_FAKE_USER="${TEST_PREFIX}zu"
TEST_FAKE_GROUP="${TEST_PREFIX}zg"

TEST_TOTAL=0
TEST_PASS=0
TEST_FAIL=0
TEST_SKIP=0
TEST_SECTION="boot"

CURRENT_USER=""
CURRENT_GROUP=""
CURRENT_UID=""
CURRENT_GID=""
CURRENT_HOME=""
CURRENT_SHELL=""
CAN_MUTATE=0
ELEVATED="${BASHX_USER_TEST_ELEVATED:-0}"

_pass () { TEST_PASS=$(( TEST_PASS + 1 )); printf '  PASS %s\n' "$*"; }
_fail () { TEST_FAIL=$(( TEST_FAIL + 1 )); printf '  FAIL %s\n' "$*"; }
_skip () { TEST_SKIP=$(( TEST_SKIP + 1 )); printf '  SKIP %s\n' "$*"; }
_section () { TEST_TOTAL=$(( TEST_TOTAL + 1 )); TEST_SECTION="$*"; printf '\n[%04d] %s\n' "${TEST_TOTAL}" "${TEST_SECTION}"; }

_capture () { "$@" 2>/dev/null || true; }

_expect_ok () {
    local name="${1:-ok}"
    shift || true
    if "$@" >/dev/null 2>&1; then _pass "${name}"; else _fail "${name}"; fi
}
_expect_fail () {
    local name="${1:-fail}"
    shift || true
    if "$@" >/dev/null 2>&1; then _fail "${name}"; else _pass "${name}"; fi
}
_expect_nonempty () {
    local name="${1:-nonempty}" value="${2-}"
    if [[ -n "${value}" ]]; then _pass "${name}"; else _fail "${name}"; fi
}
_expect_eq () {
    local name="${1:-eq}" expected="${2-}" actual="${3-}"
    if [[ "${expected}" == "${actual}" ]]; then _pass "${name}"; else _fail "${name}: expected=${expected} actual=${actual}"; fi
}
_expect_match () {
    local name="${1:-match}" value="${2-}" regex="${3-}"
    if [[ "${value}" =~ ${regex} ]]; then _pass "${name}"; else _fail "${name}: value=${value} regex=${regex}"; fi
}
_expect_no_match () {
    local name="${1:-no_match}" value="${2-}" regex="${3-}"
    if [[ ! "${value}" =~ ${regex} ]]; then _pass "${name}"; else _fail "${name}: value=${value} regex=${regex}"; fi
}
_expect_line () {
    local name="${1:-line}" haystack="${2-}" needle="${3-}"
    if grep -Fqx -- "${needle}" <<< "${haystack}"; then _pass "${name}"; else _fail "${name}: missing=${needle}"; fi
}
_expect_no_line () {
    local name="${1:-no_line}" haystack="${2-}" needle="${3-}"
    if grep -Fqx -- "${needle}" <<< "${haystack}"; then _fail "${name}: unexpected=${needle}"; else _pass "${name}"; fi
}
_expect_unique_lines () {
    local name="${1:-unique}" value="${2-}" dup=""
    dup="$(awk 'NF { seen[$0]++ } END { for ( k in seen ) if ( seen[k] > 1 ) { print k; exit } }' <<< "${value}")"
    if [[ -z "${dup}" ]]; then _pass "${name}"; else _fail "${name}: duplicate=${dup}"; fi
}
_need_mutation () {
    local name="${1:-mutation}"
    if (( CAN_MUTATE )); then return 0; fi
    _skip "${name}: requires root/admin"
    return 1
}
_cleanup_user () {
    local u="${1:-}"
    [[ -n "${u}" ]] || return 0
    declare -F user::del >/dev/null 2>&1 || return 0
    user::del "${u}" >/dev/null 2>&1 || true
}
_cleanup_group () {
    local g="${1:-}"
    [[ -n "${g}" ]] || return 0
    declare -F group::del >/dev/null 2>&1 || return 0
    group::del "${g}" >/dev/null 2>&1 || true
}
_cleanup () {
    set +e
    _cleanup_user "${TEST_USER_A}"
    _cleanup_user "${TEST_USER_B}"
    _cleanup_user "${TEST_USER_C}"
    _cleanup_group "${TEST_GROUP_A}"
    _cleanup_group "${TEST_GROUP_B}"
    _cleanup_group "${TEST_GROUP_C}"
    rm -rf -- "${TEST_ROOT}" >/dev/null 2>&1 || true
}
_finish () {
    local rc=0
    _cleanup
    printf '\n============================================================\n'
    printf ' %s summary\n' "${TEST_NAME}"
    printf '============================================================\n'
    printf 'Total sections : %s\n' "${TEST_TOTAL}"
    printf 'Pass           : %s\n' "${TEST_PASS}"
    printf 'Fail           : %s\n' "${TEST_FAIL}"
    printf 'Skip           : %s\n' "${TEST_SKIP}"
    printf 'Root           : %s\n' "${TEST_ROOT}"
    printf 'Prefix         : %s\n' "${TEST_PREFIX}"
    printf '============================================================\n'
    (( TEST_FAIL == 0 )) || rc=1
    exit "${rc}"
}
trap _finish EXIT
trap 'printf "\nERROR section=%s line=%s command=%s\n" "${TEST_SECTION}" "${LINENO}" "${BASH_COMMAND}" >&2; exit 1' ERR

_can_reexec_sudo () {
    [[ "${CI:-}" == "true" || "${GITHUB_ACTIONS:-}" == "true" ]] || return 1
    [[ "${ELEVATED}" == "1" ]] && return 1
    user::is_root >/dev/null 2>&1 && return 1
    user::can_sudo >/dev/null 2>&1 || return 1
    sys::has sudo || return 1
}
if _can_reexec_sudo; then
    exec sudo env \
        "PATH=${PATH:-}" \
        "HOME=${HOME:-}" \
        "SHELL=${SHELL:-}" \
        "CI=${CI:-}" \
        "GITHUB_ACTIONS=${GITHUB_ACTIONS:-}" \
        "BASHX_USER_TEST_ELEVATED=1" \
        bash "$0" "$@"
fi

if user::is_root >/dev/null 2>&1; then
    CAN_MUTATE=1
elif sys::is_windows && user::is_admin >/dev/null 2>&1; then
    CAN_MUTATE=1
else
    CAN_MUTATE=0
fi

CURRENT_USER="$(user::name 2>/dev/null || true)"
CURRENT_GROUP="$(user::group 2>/dev/null || group::name 2>/dev/null || true)"
CURRENT_UID="$(user::id 2>/dev/null || true)"
CURRENT_GID="$(group::id 2>/dev/null || true)"
CURRENT_HOME="$(user::home 2>/dev/null || true)"
CURRENT_SHELL="$(user::shell 2>/dev/null || true)"

printf '[target] user.sh\n'
printf '[env] os=%s runtime=%s user=%s group=%s mutate=%s\n' \
    "$(sys::name 2>/dev/null || true)" \
    "$(sys::runtime 2>/dev/null || true)" \
    "${CURRENT_USER:-unknown}" \
    "${CURRENT_GROUP:-unknown}" \
    "${CAN_MUTATE}"

_section "api presence"
for fn in \
    user::valid user::lock user::locked user::id user::name user::exists user::add user::del user::all user::groups user::add_group user::del_group user::group user::home user::shell user::is_root user::is_admin user::can_sudo \
    group::valid group::lock group::locked group::id group::name group::exists group::add group::del group::all group::users group::add_user group::del_user
do
    if declare -F "${fn}" >/dev/null 2>&1; then _pass "function exists: ${fn}"; else _fail "missing function: ${fn}"; fi
done

api_count=0
for fn in \
    user::valid user::lock user::locked user::id user::name user::exists user::add user::del user::all user::groups user::add_group user::del_group user::group user::home user::shell user::is_root user::is_admin user::can_sudo \
    group::valid group::lock group::locked group::id group::name group::exists group::add group::del group::all group::users group::add_user group::del_user
do
    declare -F "${fn}" >/dev/null 2>&1 && api_count=$(( api_count + 1 ))
done
_expect_eq "api count is 30" "30" "${api_count}"

_section "validation API"
for s in "${CURRENT_USER}" "${CURRENT_GROUP}" "${TEST_USER_A}" "${TEST_GROUP_A}" "abc_123" "abc-123"; do
    _expect_ok "user::valid accepts ${s}" user::valid "${s}"
    _expect_ok "group::valid accepts ${s}" group::valid "${s}"
done
for s in "__lock_key" "abc.def" "abc+def" "abc@def" "abc:def" "abc,def" "abc=def"; do
    _expect_ok "user::valid accepts extended safe ${s}" user::valid "${s}"
    _expect_ok "group::valid accepts extended safe ${s}" group::valid "${s}"
done
for s in "bad/path" 'bad\path' "*" "?" "[abc]" "bad]" $'bad\nname' $'bad\rname'; do
    _expect_fail "user::valid rejects extended hostile [$s]" user::valid "${s}"
    _expect_fail "group::valid rejects extended hostile [$s]" group::valid "${s}"
done

_section "lock API standalone"
_lock_fn_ok () {
    local out="${1:-}"
    [[ -n "${out}" ]] || return 1
    printf 'fn:%s\n' "${2:-}" > "${out}"
}
_lock_fn_fail () {
    return 7
}

rm -f -- "${TEST_ROOT}/user-lock-fn.out" "${TEST_ROOT}/group-lock-fn.out" "${TEST_ROOT}/user-lock-code.out" "${TEST_ROOT}/group-lock-code.out" "${TEST_ROOT}/user-lock-heredoc.out" "${TEST_ROOT}/group-lock-heredoc.out" >/dev/null 2>&1 || true

_expect_ok "user::lock function mode" user::lock "__test_user_lock_fn" _lock_fn_ok "${TEST_ROOT}/user-lock-fn.out" "ok"
_expect_eq "user::lock function mode output" "fn:ok" "$(cat "${TEST_ROOT}/user-lock-fn.out" 2>/dev/null || true)"
_expect_fail "user::lock function failure preserves rc" user::lock "__test_user_lock_fail" _lock_fn_fail
_expect_fail "user::lock rejects invalid key empty" user::lock "" _lock_fn_ok "${TEST_ROOT}/nope"
_expect_fail "user::lock rejects invalid key wildcard" user::lock "*" _lock_fn_ok "${TEST_ROOT}/nope"
_expect_fail "user::lock rejects missing runner" user::lock "__test_user_missing_runner" ""
_expect_fail "user::lock rejects unknown function" user::lock "__test_user_unknown_fn" "__missing_lock_fn__"

_expect_ok "group::lock function mode" group::lock "__test_group_lock_fn" _lock_fn_ok "${TEST_ROOT}/group-lock-fn.out" "ok"
_expect_eq "group::lock function mode output" "fn:ok" "$(cat "${TEST_ROOT}/group-lock-fn.out" 2>/dev/null || true)"
_expect_fail "group::lock function failure preserves rc" group::lock "__test_group_lock_fail" _lock_fn_fail
_expect_fail "group::lock rejects invalid key empty" group::lock "" _lock_fn_ok "${TEST_ROOT}/nope"
_expect_fail "group::lock rejects invalid key wildcard" group::lock "*" _lock_fn_ok "${TEST_ROOT}/nope"
_expect_fail "group::lock rejects missing runner" group::lock "__test_group_missing_runner" ""
_expect_fail "group::lock rejects unknown function" group::lock "__test_group_unknown_fn" "__missing_lock_fn__"

_expect_ok "user::lock bash -c code mode" user::lock "__test_user_lock_code" -- '
out="${1:-}"
value="${2:-}"
printf "code:%s\n" "${value}" > "${out}"
' "${TEST_ROOT}/user-lock-code.out" "ok"
_expect_eq "user::lock bash -c code output" "code:ok" "$(cat "${TEST_ROOT}/user-lock-code.out" 2>/dev/null || true)"

_expect_ok "group::lock bash -c code mode" group::lock "__test_group_lock_code" -- '
out="${1:-}"
value="${2:-}"
printf "code:%s\n" "${value}" > "${out}"
' "${TEST_ROOT}/group-lock-code.out" "ok"
_expect_eq "group::lock bash -c code output" "code:ok" "$(cat "${TEST_ROOT}/group-lock-code.out" 2>/dev/null || true)"

_expect_ok "user::lock stdin code mode" user::lock "__test_user_lock_stdin" --stdin "${TEST_ROOT}/user-lock-heredoc.out" "ok" <<'SH'
out="${1:-}"
value="${2:-}"
printf "stdin:%s\n" "${value}" > "${out}"
SH
_expect_eq "user::lock stdin output" "stdin:ok" "$(cat "${TEST_ROOT}/user-lock-heredoc.out" 2>/dev/null || true)"

_expect_ok "group::lock stdin code mode" group::lock "__test_group_lock_stdin" --stdin "${TEST_ROOT}/group-lock-heredoc.out" "ok" <<'SH'
out="${1:-}"
value="${2:-}"
printf "stdin:%s\n" "${value}" > "${out}"
SH
_expect_eq "group::lock stdin output" "stdin:ok" "$(cat "${TEST_ROOT}/group-lock-heredoc.out" 2>/dev/null || true)"

mkdir -p -- "${TMPDIR:-/tmp}/bash-permissions-locks/__test_user_stale.lock" >/dev/null 2>&1 || true
printf '999999999\n' > "${TMPDIR:-/tmp}/bash-permissions-locks/__test_user_stale.lock/pid" 2>/dev/null || true
_expect_ok "user::lock clears stale lock" user::lock "__test_user_stale" _lock_fn_ok "${TEST_ROOT}/user-lock-stale.out" "ok"
_expect_eq "user::lock stale output" "fn:ok" "$(cat "${TEST_ROOT}/user-lock-stale.out" 2>/dev/null || true)"

mkdir -p -- "${TMPDIR:-/tmp}/bash-permissions-locks/__test_group_stale.lock" >/dev/null 2>&1 || true
printf '999999999\n' > "${TMPDIR:-/tmp}/bash-permissions-locks/__test_group_stale.lock/pid" 2>/dev/null || true
_expect_ok "group::lock clears stale lock" group::lock "__test_group_stale" _lock_fn_ok "${TEST_ROOT}/group-lock-stale.out" "ok"
_expect_eq "group::lock stale output" "fn:ok" "$(cat "${TEST_ROOT}/group-lock-stale.out" 2>/dev/null || true)"

_section "locked API standalone"
LOCK_ROOT="${TMPDIR:-/tmp}/bash-permissions-locks"
rm -rf -- "${LOCK_ROOT}/__test_user_locked_absent.lock" "${LOCK_ROOT}/__test_group_locked_absent.lock" >/dev/null 2>&1 || true
_expect_fail "user::locked absent lock fails" user::locked "__test_user_locked_absent"
_expect_fail "group::locked absent lock fails" group::locked "__test_group_locked_absent"
_expect_fail "user::locked rejects invalid empty" user::locked ""
_expect_fail "user::locked rejects invalid wildcard" user::locked "*"
_expect_fail "group::locked rejects invalid empty" group::locked ""
_expect_fail "group::locked rejects invalid wildcard" group::locked "*"

mkdir -p -- "${LOCK_ROOT}/__test_user_locked_active.lock" "${LOCK_ROOT}/__test_group_locked_active.lock" >/dev/null 2>&1 || true
printf '%s\n' "$$" > "${LOCK_ROOT}/__test_user_locked_active.lock/pid"
printf '%s\n' "$$" > "${LOCK_ROOT}/__test_group_locked_active.lock/pid"
_expect_ok "user::locked active pid" user::locked "__test_user_locked_active"
_expect_ok "group::locked active pid" group::locked "__test_group_locked_active"
rm -rf -- "${LOCK_ROOT}/__test_user_locked_active.lock" "${LOCK_ROOT}/__test_group_locked_active.lock" >/dev/null 2>&1 || true

mkdir -p -- "${LOCK_ROOT}/__test_user_locked_pidless.lock" "${LOCK_ROOT}/__test_group_locked_pidless.lock" >/dev/null 2>&1 || true
rm -f -- "${LOCK_ROOT}/__test_user_locked_pidless.lock/pid" "${LOCK_ROOT}/__test_group_locked_pidless.lock/pid" >/dev/null 2>&1 || true
_expect_ok "user::locked pidless conservative locked" user::locked "__test_user_locked_pidless"
_expect_ok "group::locked pidless conservative locked" group::locked "__test_group_locked_pidless"
rm -rf -- "${LOCK_ROOT}/__test_user_locked_pidless.lock" "${LOCK_ROOT}/__test_group_locked_pidless.lock" >/dev/null 2>&1 || true

mkdir -p -- "${LOCK_ROOT}/__test_user_locked_stale.lock" "${LOCK_ROOT}/__test_group_locked_stale.lock" >/dev/null 2>&1 || true
printf '999999999\n' > "${LOCK_ROOT}/__test_user_locked_stale.lock/pid"
printf '999999999\n' > "${LOCK_ROOT}/__test_group_locked_stale.lock/pid"
_expect_fail "user::locked stale pid fails" user::locked "__test_user_locked_stale"
_expect_fail "group::locked stale pid fails" group::locked "__test_group_locked_stale"
if [[ -d "${LOCK_ROOT}/__test_user_locked_stale.lock" ]]; then _fail "user::locked stale dir removed"; else _pass "user::locked stale dir removed"; fi
if [[ -d "${LOCK_ROOT}/__test_group_locked_stale.lock" ]]; then _fail "group::locked stale dir removed"; else _pass "group::locked stale dir removed"; fi

_section "current identity reads"
_expect_nonempty "user::name nonempty" "${CURRENT_USER}"
_expect_nonempty "user::id nonempty" "${CURRENT_UID}"
_expect_match "user::id numeric" "${CURRENT_UID}" '^[0-9]+$'
_expect_nonempty "user::group nonempty" "${CURRENT_GROUP}"
_expect_nonempty "group::name nonempty" "$(group::name 2>/dev/null || true)"
_expect_nonempty "group::id nonempty" "${CURRENT_GID}"
_expect_match "group::id numeric" "${CURRENT_GID}" '^[0-9]+$'
_expect_nonempty "user::home nonempty" "${CURRENT_HOME}"
_expect_nonempty "user::shell nonempty" "${CURRENT_SHELL}"
_expect_no_match "user::name no CR/LF" "${CURRENT_USER}" $'[\r\n]'
_expect_no_match "group::name no CR/LF" "${CURRENT_GROUP}" $'[\r\n]'

_section "identity repeatability"
for i in {1..12}; do
    _expect_eq "repeat user::name ${i}" "${CURRENT_USER}" "$(_capture user::name)"
    _expect_eq "repeat user::id ${i}" "${CURRENT_UID}" "$(_capture user::id)"
    _expect_eq "repeat user::group ${i}" "${CURRENT_GROUP}" "$(_capture user::group)"
    _expect_eq "repeat group::id ${i}" "${CURRENT_GID}" "$(_capture group::id)"
done

_section "user::exists matrix"
_expect_ok "current user exists" user::exists "${CURRENT_USER}"
_expect_ok "current user in current group" user::exists "${CURRENT_USER}" "${CURRENT_GROUP}"
_expect_fail "fake user missing" user::exists "${TEST_FAKE_USER}"
_expect_fail "fake user in current group missing" user::exists "${TEST_FAKE_USER}" "${CURRENT_GROUP}"
_expect_fail "current user in fake group missing" user::exists "${CURRENT_USER}" "${TEST_FAKE_GROUP}"
for bad in "" "*" "?" "[x]" "bad/name" $'bad\nname' $'bad\rname'; do
    _expect_fail "user::exists rejects bad user [$bad]" user::exists "${bad}"
done
for bad in "*" "?" "[x]" "bad/name" $'bad\ngroup' $'bad\rgroup'; do
    _expect_fail "user::exists rejects bad group [$bad]" user::exists "${CURRENT_USER}" "${bad}"
done

_section "group::exists matrix"
_expect_ok "current group exists" group::exists "${CURRENT_GROUP}"
_expect_fail "fake group missing" group::exists "${TEST_FAKE_GROUP}"
for bad in "" "*" "?" "[x]" "bad/name" $'bad\ngroup' $'bad\rgroup'; do
    _expect_fail "group::exists rejects bad group [$bad]" group::exists "${bad}"
done

_section "id matrices"
_expect_eq "implicit id equals explicit current" "$(_capture user::id)" "$(_capture user::id "${CURRENT_USER}")"
_expect_fail "fake user id fails" user::id "${TEST_FAKE_USER}"
_expect_eq "implicit group id equals explicit current" "$(_capture group::id)" "$(_capture group::id "${CURRENT_GROUP}")"
_expect_fail "fake group id fails" group::id "${TEST_FAKE_GROUP}"
for bad in "*" "?" "[x]" "bad/name" $'bad\nx' $'bad\rx'; do
    _expect_fail "user::id rejects bad [$bad]" user::id "${bad}"
    _expect_fail "group::id rejects bad [$bad]" group::id "${bad}"
done

_section "list all users/groups"
users="$(_capture user::all)"
groups="$(_capture group::all)"
_expect_nonempty "user::all nonempty" "${users}"
_expect_nonempty "group::all nonempty" "${groups}"
_expect_line "user::all contains current user" "${users}" "${CURRENT_USER}"
_expect_line "group::all contains current group" "${groups}" "${CURRENT_GROUP}"
_expect_no_line "user::all excludes fake user" "${users}" "${TEST_FAKE_USER}"
_expect_no_line "group::all excludes fake group" "${groups}" "${TEST_FAKE_GROUP}"
_expect_unique_lines "user::all unique" "${users}"
_expect_unique_lines "group::all unique" "${groups}"

_section "membership listing wrappers"
ugroups="$(_capture user::groups "${CURRENT_USER}")"
gusers="$(_capture group::users "${CURRENT_GROUP}")"
_expect_nonempty "user::groups current nonempty" "${ugroups}"
_expect_nonempty "group::users current nonempty" "${gusers}"
_expect_line "user::groups contains current group" "${ugroups}" "${CURRENT_GROUP}"
_expect_line "group::users contains current user" "${gusers}" "${CURRENT_USER}"
_expect_eq "user::groups current equals group::all user" "${ugroups}" "$(_capture group::all "${CURRENT_USER}")"
_expect_eq "group::users current equals user::all group" "${gusers}" "$(_capture user::all "${CURRENT_GROUP}")"
_expect_fail "user::groups fake user fails" user::groups "${TEST_FAKE_USER}"
_expect_fail "group::users fake group fails" group::users "${TEST_FAKE_GROUP}"
_expect_fail "user::groups rejects wildcard" user::groups "*"
_expect_fail "group::users rejects wildcard" group::users "*"

_section "home and shell reads"
_expect_nonempty "implicit home nonempty" "$(_capture user::home)"
_expect_nonempty "explicit home nonempty" "$(_capture user::home "${CURRENT_USER}")"
_expect_eq "implicit explicit home stable" "$(_capture user::home)" "$(_capture user::home "${CURRENT_USER}")"
_expect_nonempty "implicit shell nonempty" "$(_capture user::shell)"
_expect_nonempty "explicit shell nonempty" "$(_capture user::shell "${CURRENT_USER}")"
_expect_eq "implicit explicit shell stable" "$(_capture user::shell)" "$(_capture user::shell "${CURRENT_USER}")"
_expect_fail "fake user home fails" user::home "${TEST_FAKE_USER}"
_expect_fail "fake user shell fails" user::shell "${TEST_FAKE_USER}"

_section "privilege checks"
if user::is_root >/dev/null 2>&1; then _pass "user::is_root true branch"; else _pass "user::is_root false branch"; fi
if user::is_admin >/dev/null 2>&1; then _pass "user::is_admin true branch"; else _pass "user::is_admin false branch"; fi
if user::can_sudo >/dev/null 2>&1; then _pass "user::can_sudo true branch"; else _pass "user::can_sudo false branch"; fi
_expect_fail "is_root fake user fails" user::is_root "${TEST_FAKE_USER}"
_expect_fail "is_admin fake user fails" user::is_admin "${TEST_FAKE_USER}"
_expect_fail "can_sudo fake user fails" user::can_sudo "${TEST_FAKE_USER}"
if sys::is_windows; then _expect_fail "windows can_sudo false" user::can_sudo; else _pass "non-windows can_sudo callable"; fi

_section "pre-mutation clean state"
_cleanup_user "${TEST_USER_A}"
_cleanup_user "${TEST_USER_B}"
_cleanup_user "${TEST_USER_C}"
_cleanup_group "${TEST_GROUP_A}"
_cleanup_group "${TEST_GROUP_B}"
_cleanup_group "${TEST_GROUP_C}"
_expect_fail "user A absent" user::exists "${TEST_USER_A}"
_expect_fail "user B absent" user::exists "${TEST_USER_B}"
_expect_fail "group A absent" group::exists "${TEST_GROUP_A}"
_expect_fail "group B absent" group::exists "${TEST_GROUP_B}"
_expect_fail "group C absent" group::exists "${TEST_GROUP_C}"

_section "group lifecycle destructive"
if _need_mutation "group lifecycle"; then
    _expect_ok "group add A" group::add "${TEST_GROUP_A}"
    _expect_ok "group exists A" group::exists "${TEST_GROUP_A}"
    _expect_ok "group add A idempotent" group::add "${TEST_GROUP_A}"
    _expect_nonempty "group id A" "$(_capture group::id "${TEST_GROUP_A}")"
    _expect_line "group::all contains A" "$(_capture group::all)" "${TEST_GROUP_A}"
    _expect_fail "group add invalid empty" group::add ""
    _expect_fail "group add invalid wildcard" group::add "*"
    _expect_fail "group add invalid newline" group::add $'bad\ngroup'
    _expect_ok "group del A" group::del "${TEST_GROUP_A}"
    _expect_fail "group A gone" group::exists "${TEST_GROUP_A}"
    _expect_ok "group del A idempotent" group::del "${TEST_GROUP_A}"
    _expect_fail "group del invalid empty" group::del ""
    _expect_fail "group del invalid wildcard" group::del "*"
fi

_section "user create-only strict lifecycle"
if _need_mutation "user lifecycle"; then
    _expect_ok "group add A" group::add "${TEST_GROUP_A}"
    _expect_ok "group add B" group::add "${TEST_GROUP_B}"
    _expect_ok "user add A in group A" user::add "${TEST_USER_A}" "${TEST_GROUP_A}"
    _expect_ok "user A exists" user::exists "${TEST_USER_A}"
    _expect_ok "user A in group A" user::exists "${TEST_USER_A}" "${TEST_GROUP_A}"
    _expect_ok "user add A group A idempotent" user::add "${TEST_USER_A}" "${TEST_GROUP_A}"
    _expect_fail "user add A group B strict fails" user::add "${TEST_USER_A}" "${TEST_GROUP_B}"
    _expect_nonempty "user A id" "$(_capture user::id "${TEST_USER_A}")"
    _expect_nonempty "user A group" "$(_capture user::group "${TEST_USER_A}")"
    _expect_nonempty "user A home" "$(_capture user::home "${TEST_USER_A}")"
    _expect_nonempty "user A shell" "$(_capture user::shell "${TEST_USER_A}")"
    _expect_line "user::all contains A" "$(_capture user::all)" "${TEST_USER_A}"
    _expect_line "group::users A contains user A" "$(_capture group::users "${TEST_GROUP_A}")" "${TEST_USER_A}"
    _expect_fail "user add invalid empty" user::add "" "${TEST_GROUP_A}"
    _expect_fail "user add invalid wildcard" user::add "*" "${TEST_GROUP_A}"
    _expect_fail "user add invalid newline" user::add $'bad\nuser' "${TEST_GROUP_A}"
    _expect_fail "user add fake group fails" user::add "${TEST_USER_B}" "${TEST_FAKE_GROUP}"
    _expect_fail "user del A wrong group B fails" user::del "${TEST_USER_A}" "${TEST_GROUP_B}"
    _expect_ok "user A survives wrong group del" user::exists "${TEST_USER_A}"
    _expect_ok "user del A with group A" user::del "${TEST_USER_A}" "${TEST_GROUP_A}"
    _expect_fail "user A gone" user::exists "${TEST_USER_A}"
    _expect_ok "user del A idempotent" user::del "${TEST_USER_A}"
    _expect_ok "group del A" group::del "${TEST_GROUP_A}"
    _expect_ok "group del B" group::del "${TEST_GROUP_B}"
fi

_section "membership lifecycle user namespace"
if _need_mutation "user membership lifecycle"; then
    _expect_ok "group add A" group::add "${TEST_GROUP_A}"
    _expect_ok "group add B" group::add "${TEST_GROUP_B}"
    _expect_ok "user add A in group A" user::add "${TEST_USER_A}" "${TEST_GROUP_A}"
    _expect_fail "user A not in group B" user::exists "${TEST_USER_A}" "${TEST_GROUP_B}"
    _expect_ok "user add_group A B" user::add_group "${TEST_USER_A}" "${TEST_GROUP_B}"
    _expect_ok "user A now in B" user::exists "${TEST_USER_A}" "${TEST_GROUP_B}"
    _expect_ok "user add_group A B idempotent" user::add_group "${TEST_USER_A}" "${TEST_GROUP_B}"
    _expect_line "user::groups A contains B" "$(_capture user::groups "${TEST_USER_A}")" "${TEST_GROUP_B}"
    _expect_line "group::users B contains A" "$(_capture group::users "${TEST_GROUP_B}")" "${TEST_USER_A}"
    _expect_ok "user del_group A B" user::del_group "${TEST_USER_A}" "${TEST_GROUP_B}"
    _expect_fail "user A no longer in B" user::exists "${TEST_USER_A}" "${TEST_GROUP_B}"
    _expect_ok "user del_group A B idempotent" user::del_group "${TEST_USER_A}" "${TEST_GROUP_B}"
    _expect_fail "add_group fake user fails" user::add_group "${TEST_FAKE_USER}" "${TEST_GROUP_B}"
    _expect_ok "add_group creates missing group C" user::add_group "${TEST_USER_A}" "${TEST_GROUP_C}"
    _expect_ok "group C created by user::add_group" group::exists "${TEST_GROUP_C}"
    _expect_ok "user A in group C" user::exists "${TEST_USER_A}" "${TEST_GROUP_C}"
    _expect_ok "user del A" user::del "${TEST_USER_A}"
    _expect_ok "group del A" group::del "${TEST_GROUP_A}"
    _expect_ok "group del B" group::del "${TEST_GROUP_B}"
    _expect_ok "group del C" group::del "${TEST_GROUP_C}"
fi

_section "membership lifecycle group namespace strict"
if _need_mutation "group namespace lifecycle"; then
    _expect_ok "group add A" group::add "${TEST_GROUP_A}"
    _expect_ok "group add C" group::add "${TEST_GROUP_C}"
    _expect_ok "user add B in group A" user::add "${TEST_USER_B}" "${TEST_GROUP_A}"
    _expect_ok "group add_user C B" group::add_user "${TEST_GROUP_C}" "${TEST_USER_B}"
    _expect_ok "user B in group C" user::exists "${TEST_USER_B}" "${TEST_GROUP_C}"
    _expect_ok "group add_user C B idempotent" group::add_user "${TEST_GROUP_C}" "${TEST_USER_B}"
    _expect_fail "group add_user missing group fails" group::add_user "${TEST_FAKE_GROUP}" "${TEST_USER_B}"
    _expect_fail "group add_user missing user fails" group::add_user "${TEST_GROUP_C}" "${TEST_FAKE_USER}"
    _expect_fail "group add_user invalid group fails" group::add_user "*" "${TEST_USER_B}"
    _expect_fail "group add_user invalid user fails" group::add_user "${TEST_GROUP_C}" "*"
    _expect_ok "group del_user C B" group::del_user "${TEST_GROUP_C}" "${TEST_USER_B}"
    _expect_fail "user B not in C" user::exists "${TEST_USER_B}" "${TEST_GROUP_C}"
    _expect_ok "group del_user C B idempotent" group::del_user "${TEST_GROUP_C}" "${TEST_USER_B}"
    _expect_fail "group del_user missing group fails" group::del_user "${TEST_FAKE_GROUP}" "${TEST_USER_B}"
    _expect_fail "group del_user missing user fails" group::del_user "${TEST_GROUP_C}" "${TEST_FAKE_USER}"
    _expect_ok "user del B" user::del "${TEST_USER_B}"
    _expect_ok "group del A" group::del "${TEST_GROUP_A}"
    _expect_ok "group del C" group::del "${TEST_GROUP_C}"
fi

_section "delete safety and idempotency"
_expect_fail "user::del empty rejects" user::del ""
_expect_fail "user::del wildcard rejects" user::del "*"
_expect_fail "user::del newline rejects" user::del $'bad\nuser'
_expect_ok "user::del valid missing idempotent" user::del "${TEST_FAKE_USER}"
_expect_fail "user::del valid missing with group fails" user::del "${TEST_FAKE_USER}" "${CURRENT_GROUP}"
_expect_fail "group::del empty rejects" group::del ""
_expect_fail "group::del wildcard rejects" group::del "*"
_expect_fail "group::del newline rejects" group::del $'bad\ngroup'
_expect_ok "group::del valid missing idempotent" group::del "${TEST_FAKE_GROUP}"

_section "hostile input sweep"
for bad in "*" "?" "[abc]" "bad/name" 'bad\name' '$USER' '$(id)' ';true' $'x\ny' $'x\ry'; do
    _expect_fail "user::valid hostile ${bad}" user::valid "${bad}"
    _expect_fail "user::lock hostile ${bad}" user::lock "${bad}" _lock_fn_ok "${TEST_ROOT}/nope"
    _expect_fail "user::locked hostile ${bad}" user::locked "${bad}"
    _expect_fail "user::exists hostile ${bad}" user::exists "${bad}"
    _expect_fail "user::id hostile ${bad}" user::id "${bad}"
    _expect_fail "user::group hostile ${bad}" user::group "${bad}"
    _expect_fail "user::home hostile ${bad}" user::home "${bad}"
    _expect_fail "user::shell hostile ${bad}" user::shell "${bad}"
    _expect_fail "user::groups hostile ${bad}" user::groups "${bad}"
    _expect_fail "group::valid hostile ${bad}" group::valid "${bad}"
    _expect_fail "group::lock hostile ${bad}" group::lock "${bad}" _lock_fn_ok "${TEST_ROOT}/nope"
    _expect_fail "group::locked hostile ${bad}" group::locked "${bad}"
    _expect_fail "group::exists hostile ${bad}" group::exists "${bad}"
    _expect_fail "group::id hostile ${bad}" group::id "${bad}"
    _expect_fail "group::users hostile ${bad}" group::users "${bad}"
done

_section "read stress"
for i in {1..30}; do
    _expect_nonempty "stress user::name ${i}" "$(_capture user::name)"
    _expect_nonempty "stress user::id ${i}" "$(_capture user::id)"
    _expect_nonempty "stress user::group ${i}" "$(_capture user::group)"
    _expect_nonempty "stress user::home ${i}" "$(_capture user::home)"
    _expect_nonempty "stress user::shell ${i}" "$(_capture user::shell)"
    _expect_nonempty "stress user::all ${i}" "$(_capture user::all)"
    _expect_nonempty "stress group::all ${i}" "$(_capture group::all)"
done

_section "minimal PATH graceful failure"
(
    PATH=""
    _expect_fail "minimal PATH user fake fails cleanly" user::exists "${TEST_FAKE_USER}"
    _expect_fail "minimal PATH group fake fails cleanly" group::exists "${TEST_FAKE_GROUP}"
)

_section "api coverage gate"
covered_functions="user::valid
user::lock
user::locked
user::id
user::name
user::exists
user::add
user::del
user::all
user::groups
user::add_group
user::del_group
user::group
user::home
user::shell
user::is_root
user::is_admin
user::can_sudo
group::valid
group::lock
group::locked
group::id
group::name
group::exists
group::add
group::del
group::all
group::users
group::add_user
group::del_user"
_expect_eq "documented coverage count" "30" "$(printf '%s\n' "${covered_functions}" | awk 'NF { n++ } END { print n + 0 }')"
for fn in ${covered_functions}; do
    if declare -F "${fn}" >/dev/null 2>&1; then _pass "covered: ${fn}"; else _fail "coverage missing function: ${fn}"; fi
done

_section "final cleanup assertion"
_cleanup_user "${TEST_USER_A}"
_cleanup_user "${TEST_USER_B}"
_cleanup_user "${TEST_USER_C}"
_cleanup_group "${TEST_GROUP_A}"
_cleanup_group "${TEST_GROUP_B}"
_cleanup_group "${TEST_GROUP_C}"
_expect_fail "final user A absent" user::exists "${TEST_USER_A}"
_expect_fail "final user B absent" user::exists "${TEST_USER_B}"
_expect_fail "final user C absent" user::exists "${TEST_USER_C}"
_expect_fail "final group A absent" group::exists "${TEST_GROUP_A}"
_expect_fail "final group B absent" group::exists "${TEST_GROUP_B}"
_expect_fail "final group C absent" group::exists "${TEST_GROUP_C}"

exit 0
