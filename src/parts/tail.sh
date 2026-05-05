
__inner_enter__ () {

    __inner_trace__

    case "${1:-}" in
        --test)
            shift || true
            __inner_test__ "$@"
        ;;
        --tests)
            shift || true
            __inner_tests__ "$@"
        ;;
        *)
            "${__INNER_APP_ENTRY__}" "$@"
        ;;
    esac

}

__inner_enter__ "$@" || __INNER_APP_CODE__=$?

exit "${__INNER_APP_CODE__}"
