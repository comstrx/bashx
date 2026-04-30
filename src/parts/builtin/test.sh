#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"

sys::ensure_bash "$@"

declare -A map=()
map["name"]="bashx"
map["status"]="ok"

mapfile -t lines < <(printf '%s\n' "alpha" "beta" "gamma")

ref_test () {

    local -n ref="$1"
    ref["nameref"]="ok"

}

ref_test map

[[ "${map[name]}" == "bashx" ]] || exit 1
[[ "${map[status]}" == "ok" ]] || exit 1
[[ "${map[nameref]}" == "ok" ]] || exit 1
[[ "${lines[0]}" == "alpha" ]] || exit 1
[[ "${lines[1]}" == "beta" ]] || exit 1
[[ "${lines[2]}" == "gamma" ]] || exit 1

printf 'PASS bash >=5 features work: %s\n' "${BASH_VERSION}"
