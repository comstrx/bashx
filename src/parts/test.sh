
__inner_test_resolve__ () {

    local want="${1:-}"

    [[ -n "${want}" ]] || return 1
    [[ -n "${__INNER_TEST_MAP__[${want}]:-}" ]] || return 1

    printf '%s\n' "${__INNER_TEST_MAP__[${want}]}"

}
__inner_test_one__ () {

    local fn="${1:-}"
    [[ -n "${fn}" ]] || return 1

    shift || true
    printf '==> %s\n' "${fn}"

    if "${fn}" "$@"; then
        printf '[PASS]: %s\n\n' "${fn}"
        return 0
    fi

    printf '[FAIL]: %s\n\n' "${fn}" >&2
    return 1

}
__inner_test_run__ () {

    local fn="" rc=0 pass=0 fail=0
    local -a tests=( "$@" )

    for fn in "${tests[@]}"; do

        if __inner_test_one__ "${fn}"; then
            (( ++pass ))
        else
            (( ++fail ))
            rc=1
        fi

    done

    printf '[INFO]: total=%s pass=%s fail=%s\n' "${#tests[@]}" "${pass}" "${fail}"
    return "${rc}"

}
__inner_test__ () {

    local target="" resolved=""

    if (( $# == 0 )); then
        __inner_test_run__ "${__INNER_TEST_LIST__[@]}"
        return $?
    fi

    target="${1}"
    shift || true

    if ! resolved="$(__inner_test_resolve__ "${target}")"; then
        printf '[FAIL]: test not found: %s\n' "${target}" >&2
        printf '[INFO]: total=1 pass=0 fail=1\n' >&2
        return 1
    fi

    __inner_test_one__ "${resolved}" "$@"
    return $?

}
__inner_tests__ () {

    local fn=""

    for fn in "${__INNER_TEST_LIST__[@]}"; do
        printf '%s\n' "${fn}"
    done

}
