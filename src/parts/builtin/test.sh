#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/permission.sh"
sys::ensure_bash 5 "$@"

__PERM_TEST_TOTAL=0
__PERM_TEST_PASS=0
__PERM_TEST_FAIL=0
__PERM_TEST_SKIP=0
__PERM_TEST_ROOT=""

_test::log () {

    printf '%s\n' "$*"

}

_test::pass () {

    __PERM_TEST_TOTAL=$(( __PERM_TEST_TOTAL + 1 ))
    __PERM_TEST_PASS=$(( __PERM_TEST_PASS + 1 ))

}

_test::fail () {

    __PERM_TEST_TOTAL=$(( __PERM_TEST_TOTAL + 1 ))
    __PERM_TEST_FAIL=$(( __PERM_TEST_FAIL + 1 ))

    printf 'FAIL: %s\n' "$*" >&2

}

_test::skip () {

    __PERM_TEST_TOTAL=$(( __PERM_TEST_TOTAL + 1 ))
    __PERM_TEST_SKIP=$(( __PERM_TEST_SKIP + 1 ))

    printf 'SKIP: %s\n' "$*" >&2

}

_test::ok () {

    local msg="${1:-assertion failed}"

    shift || true

    if "$@" >/dev/null 2>&1; then
        _test::pass
    else
        _test::fail "${msg}"
    fi

}

_test::not_ok () {

    local msg="${1:-assertion should fail}"

    shift || true

    if "$@" >/dev/null 2>&1; then
        _test::fail "${msg}"
    else
        _test::pass
    fi

}

_test::eq () {

    local msg="${1:-values differ}" got="${2-}" want="${3-}"

    if [[ "${got}" == "${want}" ]]; then
        _test::pass
    else
        _test::fail "${msg}: got=[${got}] want=[${want}]"
    fi

}

_test::ne () {

    local msg="${1:-values equal}" got="${2-}" want="${3-}"

    if [[ "${got}" != "${want}" ]]; then
        _test::pass
    else
        _test::fail "${msg}: got=[${got}]"
    fi

}

_test::match () {

    local msg="${1:-pattern mismatch}" got="${2-}" re="${3-}"

    if [[ "${got}" =~ ${re} ]]; then
        _test::pass
    else
        _test::fail "${msg}: got=[${got}] re=[${re}]"
    fi

}

_test::has () {

    command -v "${1:-}" >/dev/null 2>&1

}

_test::mkfile () {

    local path="${1:-}" data="${2:-x}"

    mkdir -p -- "$(dirname -- "${path}")"
    printf '%s\n' "${data}" > "${path}"

}

_test::mkdir () {

    mkdir -p -- "${1:?}"

}

_test::cleanup () {

    if [[ -n "${__PERM_TEST_ROOT:-}" && -d "${__PERM_TEST_ROOT}" ]]; then
        chmod -R u+rwx -- "${__PERM_TEST_ROOT}" >/dev/null 2>&1 || true
        rm -rf -- "${__PERM_TEST_ROOT}" >/dev/null 2>&1 || true
    fi

}

_test::mode () {

    perm::get "${1:?}" 2>/dev/null || true

}

_test::same_mode () {

    local path="${1:?}" want="${2:?}" got=""

    got="$(_test::mode "${path}")"
    [[ "${got}" == "${want}" || "${got}" == "0${want}" ]]

}

_test::can_check_perm_bits () {

    sys::has chmod || return 1
    sys::has stat  || return 1
    sys::is_windows && return 1

    return 0

}

_test::section () {

    printf '\n[%s]\n' "$*"

}

_test::summary () {

    printf '\n============================================================\n'
    printf ' permission.sh brutal test summary\n'
    printf '============================================================\n'
    printf 'Root  : %s\n' "${__PERM_TEST_ROOT}"
    printf 'Total : %s\n' "${__PERM_TEST_TOTAL}"
    printf 'Pass  : %s\n' "${__PERM_TEST_PASS}"
    printf 'Fail  : %s\n' "${__PERM_TEST_FAIL}"
    printf 'Skip  : %s\n' "${__PERM_TEST_SKIP}"
    printf '============================================================\n'

    (( __PERM_TEST_FAIL == 0 ))

}

trap _test::cleanup EXIT

__PERM_TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/perm-test.XXXXXX")"

_test::section "environment"

_test::log "root: ${__PERM_TEST_ROOT}"
_test::log "os  : $(sys::name 2>/dev/null || printf unknown)"
_test::log "run : $(sys::runtime 2>/dev/null || printf unknown)"
_test::log "user: $(sys::username 2>/dev/null || printf unknown)"

_test::section "api presence"

for fn in \
    perm::valid perm::get perm::set perm::add perm::del \
    perm::read perm::write perm::execute \
    perm::writeonly perm::readonly perm::editable \
    perm::private perm::public \
    perm::owner perm::group \
    perm::lock perm::unlock \
    perm::readable perm::writable perm::executable \
    perm::owned perm::same perm::copy perm::ensure perm::info
do
    _test::ok "function exists: ${fn}" declare -F "${fn}"
done

_test::section "perm::valid"

for x in 000 400 444 600 644 700 755 777 0644 0755 u+r u+w u+x u+rw u+rwx g-r o-w a+r ug+rwx u=rw go-rwx u+s g+s +r -w =rw rx rwx rXst u+rw,g-r,o+x; do
    _test::ok "valid mode: ${x}" perm::valid "${x}" mode
done

for x in "" "8" "999" "abc" "u+" "+z" "u+q" "u+r;" $'u+r\nx' "u+r o+w" "u+r|x" "u+r&&x" "755;rm -rf /"; do
    _test::not_ok "invalid mode: ${x}" perm::valid "${x}" mode
done

for x in r w x rw rx wx rwx +r +w +x +rw +rwx -r -w -x -rw -rwx =r =w =x =rw =rwx u+r u-w g+x o-r a+rw ug+rwx; do
    _test::ok "valid change: ${x}" perm::valid "${x}" change
done

for x in r w x rw rx wx rwx +r +w +x +rw +rwx -r -w -x -rw -rwx u+r u-w g+x o-r a+rw ug+rwx; do
    _test::ok "valid remove: ${x}" perm::valid "${x}" remove
done

for x in =r =w =x =rw u=rw a=rwx; do
    _test::not_ok "invalid remove: ${x}" perm::valid "${x}" remove
done

for x in u g o a ug uo go ugo augu; do
    _test::ok "valid who: ${x}" perm::valid "${x}" who
done

for x in "" "x" "user" "u+r" "u;" "u g" $'u\ng'; do
    _test::not_ok "invalid who: ${x}" perm::valid "${x}" who
done

_test::section "basic files and directories"

file="${__PERM_TEST_ROOT}/file.txt"
dir="${__PERM_TEST_ROOT}/dir"
nested="${dir}/nested.txt"
space="${__PERM_TEST_ROOT}/space name.txt"
unicode="${__PERM_TEST_ROOT}/طيبات.txt"
dash="${__PERM_TEST_ROOT}/-dash.txt"
semi="${__PERM_TEST_ROOT}/semi;name.txt"
glob="${__PERM_TEST_ROOT}/glob[abc]*?.txt"

_test::mkfile "${file}" "alpha"
_test::mkdir "${dir}"
_test::mkfile "${nested}" "nested"
_test::mkfile "${space}" "space"
_test::mkfile "${unicode}" "unicode"
_test::mkfile "${dash}" "dash"
_test::mkfile "${semi}" "semi"
_test::mkfile "${glob}" "glob"

for p in "${file}" "${dir}" "${nested}" "${space}" "${unicode}" "${dash}" "${semi}" "${glob}"; do
    _test::ok "perm::get exists: ${p}" perm::get "${p}"
    _test::match "perm::get octal: ${p}" "$(perm::get "${p}" 2>/dev/null || true)" '^[0-7]{3,4}$'
    _test::ok "perm::info exists: ${p}" perm::info "${p}"
    info="$(perm::info "${p}" 2>/dev/null || true)"
    _test::match "perm::info path: ${p}" "${info}" '^path='
    _test::match "perm::info mode: ${p}" "${info}" 'mode='
    _test::match "perm::info owner: ${p}" "${info}" 'owner='
    _test::match "perm::info group: ${p}" "${info}" 'group='
done

_test::section "perm::set and perm::ensure"

for m in 600 644 700 755; do
    target="${__PERM_TEST_ROOT}/set-${m}.txt"
    _test::mkfile "${target}" "${m}"

    _test::ok "perm::set ${m}" perm::set "${target}" "${m}"

    if _test::can_check_perm_bits; then
        _test::ok "mode is ${m}" _test::same_mode "${target}" "${m}"
    else
        _test::match "mode readable after set ${m}" "$(perm::get "${target}" 2>/dev/null || true)" '^[0-7]{3,4}$'
    fi

    _test::ok "perm::ensure ${m}" perm::ensure "${target}" "${m}"
done

for bad in "" 999 888 abc "644;echo pwn" $'644\n755' "u+z"; do
    target="${__PERM_TEST_ROOT}/bad-set.txt"
    _test::mkfile "${target}" "bad"
    _test::not_ok "perm::set rejects ${bad}" perm::set "${target}" "${bad}"
    _test::not_ok "perm::ensure rejects ${bad}" perm::ensure "${target}" "${bad}"
done

_test::section "perm::add / perm::del"

target="${__PERM_TEST_ROOT}/changes.txt"
_test::mkfile "${target}" "changes"
perm::set "${target}" 600 >/dev/null 2>&1 || true

_test::ok "perm::add x" perm::add "${target}" x
_test::ok "perm::executable after add x" perm::executable "${target}"
_test::ok "perm::del +x removes execute" perm::del "${target}" +x
_test::not_ok "not executable after del +x" perm::executable "${target}"

_test::ok "perm::add +x" perm::add "${target}" +x
_test::ok "perm::executable after add +x" perm::executable "${target}"
_test::ok "perm::del x removes execute" perm::del "${target}" x
_test::not_ok "not executable after del x" perm::executable "${target}"

_test::ok "perm::add u+x" perm::add "${target}" u+x
_test::ok "perm::executable after add u+x" perm::executable "${target}"
_test::ok "perm::del u+x removes execute" perm::del "${target}" u+x
_test::not_ok "not executable after del u+x" perm::executable "${target}"

_test::ok "perm::add rw" perm::add "${target}" rw
_test::ok "perm::readable after add rw" perm::readable "${target}"
_test::ok "perm::writable after add rw" perm::writable "${target}"

_test::not_ok "perm::add rejects invalid" perm::add "${target}" "x;echo pwn"
_test::not_ok "perm::del rejects invalid" perm::del "${target}" "x;echo pwn"
_test::not_ok "perm::del rejects =" perm::del "${target}" "=x"

_test::section "perm::read / write / execute"

target="${__PERM_TEST_ROOT}/rwx.txt"
_test::mkfile "${target}" "rwx"
perm::set "${target}" 600 >/dev/null 2>&1 || true

for who in u g o a ug go ugo; do
    _test::ok "perm::read ${who}" perm::read "${target}" "${who}"
    _test::ok "perm::write ${who}" perm::write "${target}" "${who}"
    _test::ok "perm::execute ${who}" perm::execute "${target}" "${who}"
done

for who in x "u+r" "u g" $'u\ng'; do
    _test::not_ok "perm::read rejects who ${who}" perm::read "${target}" "${who}"
    _test::not_ok "perm::write rejects who ${who}" perm::write "${target}" "${who}"
    _test::not_ok "perm::execute rejects who ${who}" perm::execute "${target}" "${who}"
done

_test::section "perm::private / public / readonly / writeonly / editable"

priv_file="${__PERM_TEST_ROOT}/private-file.txt"
priv_dir="${__PERM_TEST_ROOT}/private-dir"
pub_file="${__PERM_TEST_ROOT}/public-file.txt"
pub_dir="${__PERM_TEST_ROOT}/public-dir"
ro_file="${__PERM_TEST_ROOT}/readonly.txt"
wo_file="${__PERM_TEST_ROOT}/writeonly.txt"
ed_file="${__PERM_TEST_ROOT}/editable.txt"

_test::mkfile "${priv_file}" "private"
_test::mkdir "${priv_dir}"
_test::mkfile "${pub_file}" "public"
_test::mkdir "${pub_dir}"
_test::mkfile "${ro_file}" "readonly"
_test::mkfile "${wo_file}" "writeonly"
_test::mkfile "${ed_file}" "editable"

_test::ok "perm::private file" perm::private "${priv_file}"
_test::ok "perm::private dir"  perm::private "${priv_dir}"
_test::ok "perm::public file"  perm::public "${pub_file}"
_test::ok "perm::public dir"   perm::public "${pub_dir}"

if _test::can_check_perm_bits; then
    _test::ok "private file 600" _test::same_mode "${priv_file}" 600
    _test::ok "private dir 700"  _test::same_mode "${priv_dir}" 700
    _test::ok "public file 644"  _test::same_mode "${pub_file}" 644
    _test::ok "public dir 755"   _test::same_mode "${pub_dir}" 755
else
    _test::skip "exact private/public bit checks skipped on this runtime"
fi

_test::ok "perm::readonly" perm::readonly "${ro_file}"
_test::ok "readonly remains readable" perm::readable "${ro_file}"
if ! sys::is_windows; then
    _test::not_ok "readonly not writable" perm::writable "${ro_file}"
else
    _test::skip "readonly writable predicate can vary on Windows ACL/MSYS"
fi
chmod u+w -- "${ro_file}" >/dev/null 2>&1 || true

_test::ok "perm::writeonly" perm::writeonly "${wo_file}"
if ! sys::is_windows; then
    _test::ok "writeonly writable" perm::writable "${wo_file}"
else
    _test::skip "writeonly predicate can vary on Windows ACL/MSYS"
fi
chmod u+rw -- "${wo_file}" >/dev/null 2>&1 || true

_test::ok "perm::editable" perm::editable "${ed_file}"
_test::ok "editable readable" perm::readable "${ed_file}"
_test::ok "editable writable" perm::writable "${ed_file}"

_test::section "perm::readable / writable / executable predicates"

pred="${__PERM_TEST_ROOT}/pred.txt"
_test::mkfile "${pred}" "pred"

chmod 000 "${pred}" >/dev/null 2>&1 || true
if ! sys::is_windows && ! sys::is_root; then
    _test::not_ok "000 not readable" perm::readable "${pred}"
    _test::not_ok "000 not writable" perm::writable "${pred}"
else
    _test::skip "000 read/write predicates skipped for root/windows"
fi

chmod 600 "${pred}" >/dev/null 2>&1 || true
_test::ok "600 readable" perm::readable "${pred}"
_test::ok "600 writable" perm::writable "${pred}"

chmod 700 "${pred}" >/dev/null 2>&1 || true
_test::ok "700 executable" perm::executable "${pred}"

chmod 600 "${pred}" >/dev/null 2>&1 || true
_test::not_ok "600 not executable" perm::executable "${pred}"

_test::section "perm::owner / group / owned"

own="${__PERM_TEST_ROOT}/owner.txt"
_test::mkfile "${own}" "owner"

owner="$(perm::owner "${own}" 2>/dev/null || true)"
_test::ne "owner is non-empty" "${owner}" ""
_test::ok "perm::owned current/default" perm::owned "${own}"

if [[ -n "${owner}" ]]; then
    _test::ok "perm::owned explicit owner" perm::owned "${own}" "${owner}"
fi

group="$(perm::group "${own}" 2>/dev/null || true)"
_test::ne "group is non-empty" "${group}" ""

if ! sys::is_windows && [[ -n "${group}" ]]; then
    _test::ok "perm::group set current group" perm::group "${own}" "${group}"
else
    _test::not_ok "perm::group set fails on windows" perm::group "${own}" "${group:-Users}"
fi

_test::not_ok "perm::owner rejects injection" perm::owner "${own}" "bad;user"
_test::not_ok "perm::group rejects injection" perm::group "${own}" "bad;group"

_test::section "perm::same / copy"

a="${__PERM_TEST_ROOT}/same-a.txt"
b="${__PERM_TEST_ROOT}/same-b.txt"
c="${__PERM_TEST_ROOT}/copy-c.txt"

_test::mkfile "${a}" "a"
_test::mkfile "${b}" "b"
_test::mkfile "${c}" "c"

perm::set "${a}" 600 >/dev/null 2>&1 || true
perm::set "${b}" 600 >/dev/null 2>&1 || true
perm::set "${c}" 644 >/dev/null 2>&1 || true

_test::ok "perm::same true" perm::same "${a}" "${b}"

perm::set "${b}" 755 >/dev/null 2>&1 || true

if _test::can_check_perm_bits; then
    _test::not_ok "perm::same false" perm::same "${a}" "${b}"
else
    _test::skip "perm::same false exact check skipped on windows-like runtime"
fi

_test::ok "perm::copy" perm::copy "${a}" "${c}"
_test::ok "perm::same after copy" perm::same "${a}" "${c}"

_test::section "perm::lock / unlock"

lockf="${__PERM_TEST_ROOT}/lock.txt"
_test::mkfile "${lockf}" "lock"

_test::ok "perm::lock default" perm::lock "${lockf}"
if ! sys::is_windows && ! sys::is_root; then
    _test::not_ok "locked not writable" perm::writable "${lockf}"
else
    _test::skip "locked writable predicate skipped for root/windows"
fi

_test::ok "perm::unlock default" perm::unlock "${lockf}"
_test::ok "unlocked writable" perm::writable "${lockf}"

for who in u g o a; do
    _test::ok "perm::lock ${who}" perm::lock "${lockf}" "${who}"
    _test::ok "perm::unlock ${who}" perm::unlock "${lockf}" "${who}"
done

_test::not_ok "perm::lock rejects bad who" perm::lock "${lockf}" "u+x"
_test::not_ok "perm::unlock rejects bad who" perm::unlock "${lockf}" "u+x"

_test::section "symlink behavior"

link_target="${__PERM_TEST_ROOT}/link-target.txt"
link_path="${__PERM_TEST_ROOT}/link-path.txt"

_test::mkfile "${link_target}" "target"

if ln -s "${link_target}" "${link_path}" >/dev/null 2>&1; then
    _test::ok "perm::get symlink" perm::get "${link_path}"
    _test::ok "perm::info symlink" perm::info "${link_path}"
    _test::ok "perm::set symlink target semantics" perm::set "${link_path}" 600
else
    _test::skip "symlink unsupported"
fi

_test::section "hostile path names"

hostile_dir="${__PERM_TEST_ROOT}/hostile names"
_test::mkdir "${hostile_dir}"

hostile_paths=(
    "${hostile_dir}/ leading.txt"
    "${hostile_dir}/trailing .txt"
    "${hostile_dir}/semi;colon.txt"
    "${hostile_dir}/quote'file.txt"
    "${hostile_dir}/double\"quote.txt"
    "${hostile_dir}/dollar\$file.txt"
    "${hostile_dir}/paren(file).txt"
    "${hostile_dir}/bracket[1].txt"
    "${hostile_dir}/star*.txt"
    "${hostile_dir}/question?.txt"
    "${hostile_dir}/arabic-طيبات.txt"
)

for p in "${hostile_paths[@]}"; do
    _test::mkfile "${p}" "hostile"
    _test::ok "hostile get: ${p}" perm::get "${p}"
    _test::ok "hostile private: ${p}" perm::private "${p}"
    _test::ok "hostile public: ${p}" perm::public "${p}"
    _test::ok "hostile readonly: ${p}" perm::readonly "${p}"
    chmod u+w -- "${p}" >/dev/null 2>&1 || true
done

_test::section "invalid path and argument failures"

missing="${__PERM_TEST_ROOT}/missing.txt"

_test::not_ok "get missing" perm::get "${missing}"
_test::not_ok "set missing" perm::set "${missing}" 600
_test::not_ok "add missing" perm::add "${missing}" x
_test::not_ok "del missing" perm::del "${missing}" x
_test::not_ok "read missing" perm::read "${missing}"
_test::not_ok "write missing" perm::write "${missing}"
_test::not_ok "execute missing" perm::execute "${missing}"
_test::not_ok "owner missing" perm::owner "${missing}"
_test::not_ok "group missing" perm::group "${missing}"
_test::not_ok "private missing" perm::private "${missing}"
_test::not_ok "public missing" perm::public "${missing}"
_test::not_ok "ensure missing" perm::ensure "${missing}" 600
_test::not_ok "copy missing source" perm::copy "${missing}" "${file}"
_test::not_ok "copy missing target" perm::copy "${file}" "${missing}"
_test::not_ok "same missing left" perm::same "${missing}" "${file}"
_test::not_ok "same missing right" perm::same "${file}" "${missing}"
_test::not_ok "info missing" perm::info "${missing}"

_test::not_ok "get empty" perm::get ""
_test::not_ok "set empty" perm::set "" 600
_test::not_ok "set empty mode" perm::set "${file}" ""
_test::not_ok "copy empty from" perm::copy "" "${file}"
_test::not_ok "copy empty to" perm::copy "${file}" ""
_test::not_ok "same empty left" perm::same "" "${file}"

_test::section "medium stress matrix"

stress="${__PERM_TEST_ROOT}/stress"
_test::mkdir "${stress}"

modes=(600 644 700 755)
changes=(r w x rw rx wx rwx +r +w +x +rw +rwx u+r u+w u+x u+rw u+rwx g-r o-r a+r)
removes=(r w x rw rx wx rwx +r +w +x +rw +rwx -r -w -x u+r u+w u+x u+rw g-r o-r a-r)

for i in $(seq 1 80); do
    p="${stress}/file-${i}.txt"
    _test::mkfile "${p}" "stress ${i}"

    m="${modes[$(( ( i - 1 ) % ${#modes[@]} ))]}"
    c1="${changes[$(( ( i - 1 ) % ${#changes[@]} ))]}"
    c2="${removes[$(( ( i - 1 ) % ${#removes[@]} ))]}"

    _test::ok "stress set ${i}" perm::set "${p}" "${m}"
    _test::ok "stress get ${i}" perm::get "${p}"
    _test::ok "stress add ${i}" perm::add "${p}" "${c1}"
    _test::ok "stress del ${i}" perm::del "${p}" "${c2}"
    _test::ok "stress info ${i}" perm::info "${p}"
done

_test::section "final coverage smoke"

coverage_fns=(
    valid get set add del read write execute writeonly readonly editable private public owner group
    lock unlock readable writable executable owned same copy ensure info
)

for fn in "${coverage_fns[@]}"; do
    if declare -F "perm::${fn}" >/dev/null 2>&1; then
        _test::pass
    else
        _test::fail "missing coverage function: perm::${fn}"
    fi
done

_test::summary
