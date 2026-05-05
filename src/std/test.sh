#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/process.sh"
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/tool.sh"
sys::ensure_bash 5 "$@"

now_ns () {

    date +%s%N

}
bench_ns () {

    local title="${1:-}" count="${2:-}" start="" end="" total="" each=""

    shift 2 || return 1

    start="$(now_ns)"
    "$@"
    end="$(now_ns)"

    total=$(( end - start ))
    each=$(( total / count ))

    printf '%-28s total=%12dns  each=%10dns  each=%6dus\n' \
        "${title}" "${total}" "${each}" "$(( each / 1000 ))"

}
register_500 () {

    local i=""

    tool::reset

    for (( i = 1; i <= 10; i++ )); do

        tool::register \
            default \
            "tool${i}" \
            "bin${i}" \
            "package${i}" \
            "1.0.${i}" \
            "" \
            "" \
            native

    done

}
read_one () {

    tool::get tool250 >/dev/null

}
read_500 () {

    local i=""

    for (( i = 1; i <= 500; i++ )); do

        tool::get "tool${i}" >/dev/null
    done

}
read_500_field () {

    local i=""

    for (( i = 1; i <= 500; i++ )); do

        tool::get "tool${i}" bin >/dev/null
    done

}
read_500_miss () {

    local i=""

    for (( i = 1; i <= 500; i++ )); do

        tool::get "missing${i}" >/dev/null
    done

}

register_500

# bench_ns "read x1 full"        1   read_one
# bench_ns "read x500 full"      500 read_500
# bench_ns "read x500 field"     500 read_500_field
# bench_ns "read x500 missing"   500 read_500_miss
