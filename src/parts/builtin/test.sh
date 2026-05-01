#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/permission.sh"

sys::ensure_bash 5 "$@"

root="$(mktemp -d "${TMPDIR:-/tmp}/perm-rest.XXXXXX")"
pass=0
fail=0

cleanup () {
    chmod -R u+rwx -- "${root}" >/dev/null 2>&1 || true
    rm -rf -- "${root}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

pass () {
    pass=$(( pass + 1 ))
    printf 'PASS %s\n' "$*"
}

fail () {
    fail=$(( fail + 1 ))
    printf 'FAIL %s\n' "$*" >&2
}

ok () {
    local name="${1:-}" rc=0
    shift || true

    "$@" >/dev/null 2>&1 || rc=$?

    (( rc == 0 )) && pass "${name}" || fail "${name} rc=${rc}"
}

not_ok () {
    local name="${1:-}" rc=0
    shift || true

    "$@" >/dev/null 2>&1 || rc=$?

    (( rc != 0 )) && pass "${name}" || fail "${name} unexpectedly succeeded"
}

out_ok () {
    local name="${1:-}" out=""
    shift || true

    out="$("$@" 2>/dev/null || true)"
    [[ -n "${out}" ]] && pass "${name}" || fail "${name} empty output"
}

has_line () {
    local name="${1:-}" pattern="${2:-}" out="${3:-}"

    [[ "${out}" == *"${pattern}"* ]] && pass "${name}" || fail "${name} missing ${pattern}"
}

mkfile () {
    local path="${1:-}" data="${2:-hello}"

    mkdir -p -- "$(dirname -- "${path}")"
    printf '%s\n' "${data}" > "${path}"
}

mkscript () {
    local path="${1:-}"

    mkdir -p -- "$(dirname -- "${path}")"
    printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" ok' > "${path}"
    chmod u+rw -- "${path}" >/dev/null 2>&1 || true
}

can_read () {
    cat -- "$1" >/dev/null
}

can_write () {
    printf '' >> "$1"
}

can_exec () {
    "$1" >/dev/null
}

printf '[env]\n'
printf 'root    : %s\n' "${root}"
printf 'os      : %s\n' "$(sys::name 2>/dev/null || printf unknown)"
printf 'runtime : %s\n' "$(sys::runtime 2>/dev/null || printf unknown)"
printf 'user    : %s\n' "$(sys::username 2>/dev/null || printf unknown)"

printf '\n[api presence: rest only]\n'
for fn in \
    valid read write execute writeonly readonly seal private public shared \
    owner group readable writable executable runnable editable \
    is_private is_public is_same owned lock unlock copy ensure info
do
    ok "function exists: perm::${fn}" declare -F "perm::${fn}"
done

printf '\n[perm::valid]\n'
for x in 000 400 500 600 644 664 700 755 775 0777 u+r u-w g+x o-r a+rw ug+rwx u+rw,g-r,o+x; do
    ok "valid mode ${x}" perm::valid "${x}" mode
done

for x in r w x rw rx rwx +r +w +x -r -w -x u+r u-w g+x o-r a+rw; do
    ok "valid change ${x}" perm::valid "${x}" change
done

for x in r w x rw rx rwx +r +w +x -r -w -x u+r u-w g+x o-r a+rw; do
    ok "valid remove ${x}" perm::valid "${x}" remove
done

for x in u g o a ug go ugo; do
    ok "valid who ${x}" perm::valid "${x}" who
done

for x in "" 999 abc "u+" "+z" "u+r;" $'u+r\nx' "u+r o+w" "u+r|x"; do
    not_ok "invalid mode ${x}" perm::valid "${x}" mode
done

for x in "" x user "u+r" "u g" $'u\ng'; do
    not_ok "invalid who ${x}" perm::valid "${x}" who
done

printf '\n[predicates: readable / writable / executable]\n'
rf="${root}/readable.txt"
wf="${root}/writable.txt"
xf="${root}/executable.sh"

mkfile "${rf}" "readable"
mkfile "${wf}" "writable"
mkscript "${xf}"

perm::read "${rf}" >/dev/null 2>&1 || true
ok "perm::readable true" perm::readable "${rf}"
ok "effect readable true" can_read "${rf}"

perm::write "${wf}" >/dev/null 2>&1 || true
ok "perm::writable true" perm::writable "${wf}"
ok "effect writable true" can_write "${wf}"

perm::execute "${xf}" >/dev/null 2>&1 || true
ok "perm::executable true" perm::executable "${xf}"
ok "effect executable true" can_exec "${xf}"

not_ok "readable missing false" perm::readable "${root}/missing"
not_ok "writable missing false" perm::writable "${root}/missing"
not_ok "executable missing false" perm::executable "${root}/missing"

printf '\n[facade predicates: runnable / editable / owned]\n'
runf="${root}/run.sh"
editf="${root}/edit.txt"
ownf="${root}/own.txt"

mkscript "${runf}"
mkfile "${editf}" "edit"
mkfile "${ownf}" "own"

ok "perm::runnable" perm::runnable "${runf}"
ok "effect runnable readable" can_read "${runf}"
ok "effect runnable executable" can_exec "${runf}"

ok "perm::editable" perm::editable "${editf}"
ok "effect editable readable" can_read "${editf}"
ok "effect editable writable" can_write "${editf}"

ok "perm::owned" perm::owned "${ownf}"

current_user="$(sys::username 2>/dev/null || true)"
if [[ -n "${current_user}" ]]; then
    ok "perm::owned explicit current user" perm::owned "${ownf}" "${current_user}"
fi

not_ok "perm::owned bogus user" perm::owned "${ownf}" "__definitely_not_current_user__"

printf '\n[owner / group / info]\n'
infof="${root}/info.txt"
mkfile "${infof}" "info"

out_ok "perm::owner getter output" perm::owner "${infof}"
out_ok "perm::group getter output" perm::group "${infof}"

info="$(perm::info "${infof}" 2>/dev/null || true)"
[[ -n "${info}" ]] && pass "perm::info output" || fail "perm::info output empty"
has_line "perm::info has path"  "path="  "${info}"
has_line "perm::info has mode"  "mode="  "${info}"
has_line "perm::info has owner" "owner=" "${info}"
has_line "perm::info has group" "group=" "${info}"

not_ok "perm::owner rejects injection" perm::owner "${infof}" "bad;user"
not_ok "perm::group rejects injection" perm::group "${infof}" "bad;group"

printf '\n[is_private / is_public / is_same]\n'
priv="${root}/priv.txt"
pub="${root}/pub.txt"
same_a="${root}/same-a.txt"
same_b="${root}/same-b.txt"
same_c="${root}/same-c.txt"

mkfile "${priv}" "private"
mkfile "${pub}" "public"
mkfile "${same_a}" "a"
mkfile "${same_b}" "b"
mkfile "${same_c}" "c"

ok "perm::private action for is_private" perm::private "${priv}"
ok "perm::is_private private file" perm::is_private "${priv}"

ok "perm::public action for is_public" perm::public "${pub}"

if ! sys::is_windows; then
    ok "perm::is_public public file" perm::is_public "${pub}"
    not_ok "private is not public" perm::is_public "${priv}"
    not_ok "public is not private" perm::is_private "${pub}"
else
    not_ok "private is not public on Windows best-effort" perm::is_public "${priv}"
fi

ok "prepare same_a private" perm::private "${same_a}"
ok "prepare same_b private" perm::private "${same_b}"
ok "perm::is_same same permissions" perm::is_same "${same_a}" "${same_b}"

ok "prepare same_c public" perm::public "${same_c}"

if ! sys::is_windows; then
    not_ok "perm::is_same different permissions" perm::is_same "${same_a}" "${same_c}"
else
    ok "perm::is_same callable on Windows same pair" perm::is_same "${same_a}" "${same_b}"
fi

printf '\n[copy]\n'
copy_a="${root}/copy-a.txt"
copy_b="${root}/copy-b.txt"

mkfile "${copy_a}" "copy-a"
mkfile "${copy_b}" "copy-b"

ok "prepare copy source private" perm::private "${copy_a}"
ok "prepare copy target public" perm::public "${copy_b}"
ok "perm::copy source target" perm::copy "${copy_a}" "${copy_b}"

if ! sys::is_windows; then
    ok "effect copy makes is_same true" perm::is_same "${copy_a}" "${copy_b}"
else
    ok "effect copy keeps target readable" perm::readable "${copy_b}"
fi

printf '\n[ensure]\n'
ens="${root}/ensure.txt"
mkfile "${ens}" "ensure"

ok "perm::ensure 600" perm::ensure "${ens}" 600
ok "effect ensure readable" perm::readable "${ens}"
ok "effect ensure writable" perm::writable "${ens}"

ok "perm::ensure 400" perm::ensure "${ens}" 400
ok "effect ensure 400 readable" perm::readable "${ens}"

if ! sys::is_windows; then
    not_ok "effect ensure 400 blocks write" can_write "${ens}"
else
    not_ok "effect ensure 400 blocks write on Windows" can_write "${ens}"
fi

perm::unlock "${ens}" >/dev/null 2>&1 || true
chmod u+rw -- "${ens}" >/dev/null 2>&1 || true

printf '\n[facades already covered but rest-safe]\n'
for fn in private public seal shared readonly writeonly lock unlock; do
    f="${root}/${fn}.txt"
    mkfile "${f}" "${fn}"
    ok "perm::${fn} action" "perm::${fn}" "${f}"
    perm::unlock "${f}" >/dev/null 2>&1 || true
    chmod u+rw -- "${f}" >/dev/null 2>&1 || true
done

printf '\n[missing path failures]\n'
missing="${root}/missing.txt"

for fn in owner group readable writable executable runnable editable is_private is_public owned info; do
    not_ok "perm::${fn} missing" "perm::${fn}" "${missing}"
done

not_ok "perm::is_same missing left" perm::is_same "${missing}" "${rf}"
not_ok "perm::is_same missing right" perm::is_same "${rf}" "${missing}"
not_ok "perm::copy missing source" perm::copy "${missing}" "${rf}"
not_ok "perm::copy missing target" perm::copy "${rf}" "${missing}"
not_ok "perm::ensure missing" perm::ensure "${missing}" 600

printf '\n[raw API: get / set / add / del]\n'

raw_a="${root}/raw-a.sh"
raw_b="${root}/raw-b.sh"
raw_c="${root}/raw-c.sh"

mkscript "${raw_a}"
mkscript "${raw_b}"
mkscript "${raw_c}"

printf '\n[raw: set/get consistency]\n'

for m in 400 500 600 644 664 700 755 775; do
    f1="${root}/raw-set-${m}-a.txt"
    f2="${root}/raw-set-${m}-b.txt"

    mkfile "${f1}" "a-${m}"
    mkfile "${f2}" "b-${m}"

    ok "perm::set ${m} a" perm::set "${f1}" "${m}"
    ok "perm::set ${m} b" perm::set "${f2}" "${m}"

    g1="$(perm::get "${f1}" 2>/dev/null || true)"
    g2="$(perm::get "${f2}" 2>/dev/null || true)"

    [[ -n "${g1}" ]] && pass "perm::get ${m} a non-empty" || fail "perm::get ${m} a empty"
    [[ -n "${g2}" ]] && pass "perm::get ${m} b non-empty" || fail "perm::get ${m} b empty"

    if ! sys::is_windows; then
        [[ "${g1}" == "${m}" || "${g1}" == "0${m}" ]] && pass "perm::get ${m} exact a" || fail "perm::get ${m} exact a got=${g1}"
        [[ "${g2}" == "${m}" || "${g2}" == "0${m}" ]] && pass "perm::get ${m} exact b" || fail "perm::get ${m} exact b got=${g2}"
    else
        [[ "${g1}" == "${g2}" ]] && pass "perm::get ${m} stable mapping" || fail "perm::get ${m} unstable mapping a=${g1} b=${g2}"
    fi

    chmod u+rw -- "${f1}" "${f2}" >/dev/null 2>&1 || true
    perm::unlock "${f1}" >/dev/null 2>&1 || true
    perm::unlock "${f2}" >/dev/null 2>&1 || true
done

printf '\n[raw: add effects]\n'

mkscript "${raw_a}"
chmod 600 "${raw_a}" >/dev/null 2>&1 || true
perm::unlock "${raw_a}" >/dev/null 2>&1 || true

ok "perm::add r" perm::add "${raw_a}" r
ok "effect add r readable" can_read "${raw_a}"

ok "perm::add w" perm::add "${raw_a}" w
ok "effect add w writable" can_write "${raw_a}"

ok "perm::add x" perm::add "${raw_a}" x
perm::read "${raw_a}" >/dev/null 2>&1 || true
ok "effect add x executable" can_exec "${raw_a}"

printf '\n[raw: del effects]\n'

mkscript "${raw_b}"
perm::runnable "${raw_b}" >/dev/null 2>&1 || true
perm::editable "${raw_b}" >/dev/null 2>&1 || true

ok "perm::del w" perm::del "${raw_b}" w

if sys::is_root; then
    pass "effect del w blocks write ignored for root"
else
    not_ok "effect del w blocks write" can_write "${raw_b}"
fi

perm::write "${raw_b}" >/dev/null 2>&1 || true
ok "effect write restores write" can_write "${raw_b}"

ok "perm::del x" perm::del "${raw_b}" x

if ! sys::is_windows; then
    not_ok "effect del x blocks execute" can_exec "${raw_b}"
else
    ok "perm::del x callable on Windows" true
fi

perm::read    "${raw_b}" >/dev/null 2>&1 || true
perm::execute "${raw_b}" >/dev/null 2>&1 || true
ok "effect execute restores execute" can_exec "${raw_b}"

ok "perm::del r" perm::del "${raw_b}" r

if sys::is_windows || sys::is_root; then
    ok "perm::del r callable on windows/root" true
else
    not_ok "effect del r blocks read" can_read "${raw_b}"
fi

perm::read "${raw_b}" >/dev/null 2>&1 || true
ok "effect read restores read" can_read "${raw_b}"

printf '\n[raw: invalid args]\n'

not_ok "perm::set invalid mode" perm::set "${raw_c}" "999"
not_ok "perm::set injected mode" perm::set "${raw_c}" "644;echo bad"
not_ok "perm::add invalid mode" perm::add "${raw_c}" "x;echo bad"
not_ok "perm::del invalid mode" perm::del "${raw_c}" "x;echo bad"
not_ok "perm::get missing" perm::get "${root}/missing-raw.txt"
not_ok "perm::set missing" perm::set "${root}/missing-raw.txt" 600
not_ok "perm::add missing" perm::add "${root}/missing-raw.txt" x
not_ok "perm::del missing" perm::del "${root}/missing-raw.txt" x

printf '\n[summary]\n'
printf 'pass: %s\n' "${pass}"
printf 'fail: %s\n' "${fail}"

(( fail == 0 ))
