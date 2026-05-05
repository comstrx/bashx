
proc::hash () {

    hash -r 2>/dev/null || true

}
proc::die () {

    local msg="${1:-}" code="${2:-1}"

    [[ "${code}" =~ ^[0-9]+$ ]] || code=1
    [[ -n "${msg}" ]] && printf '[ERR] %s\n' "${msg}" >&2
    [[ "${-}" == *i* ]] && return "${code}"

    exit "${code}"

}

proc::has () {

    command -v "${1:-}" >/dev/null 2>&1

}
proc::has_any () {

    local x=""
    (( $# > 0 )) || return 1

    for x in "$@"; do
        proc::has "${x}" && return 0
    done

    return 1

}
proc::has_all () {

    local x=""
    (( $# > 0 )) || return 1

    for x in "$@"; do
        proc::has "${x}" || return 1
    done

    return 0

}

proc::need () {

    local bin="${1:-}"

    [[ -n "${bin}" ]] || return 1
    proc::has "${bin}" && return 0

    proc::die "need command: ${bin}"

}
proc::need_any () {

    local x=""
    (( $# > 0 )) || return 1

    for x in "$@"; do
        proc::has "${x}" && return 0
    done

    proc::die "need any of: $*"

}
proc::need_all () {

    local x=""
    (( $# > 0 )) || return 1

    for x in "$@"; do
        proc::has "${x}" || proc::die "need command: ${x}"
    done

    return 0

}

proc::run () {

    (( $# > 0 )) || return 1
    "$@"

}
proc::run_trace () {

    (( $# > 0 )) || return 1

    printf '+ ' >&2
    printf '%q ' "$@" >&2
    printf '\n' >&2

    "$@"

}
proc::run_ok () {

    (( $# > 0 )) || return 1
    "$@" >/dev/null 2>&1

}
proc::run_all () {

    local cmd=""
    (( $# > 0 )) || return 1

    for cmd in "$@"; do

        [[ -n "${cmd}" ]] || return 1
        printf '+ %s\n' "${cmd}" >&2
        "${BASH:-bash}" -lc "${cmd}" || return 1

    done

}
proc::run_all_ok () {

    local cmd=""
    (( $# > 0 )) || return 1

    for cmd in "$@"; do
        [[ -n "${cmd}" ]] || return 1
        "${BASH:-bash}" -lc "${cmd}" >/dev/null 2>&1 || return 1
    done

}

proc::try_run () {

    local rc=1
    (( $# > 0 )) || return 1

    if sys::is_windows || sys::is_root; then
        "$@"
        return
    fi
    if proc::has sudo; then

        if sudo -n true >/dev/null 2>&1; then
            sudo -n "$@" && return 0
        fi
        if ! sys::is_ci && ! sys::is_headless && sys::is_terminal; then
            sudo "$@" && return 0
        fi

    fi

    "$@"
    rc=$?
    return "${rc}"

}
proc::try_run_trace () {

    (( $# > 0 )) || return 1

    printf '+ ' >&2
    printf '%q ' "$@" >&2
    printf '\n' >&2

    proc::try_run "$@"

}
proc::try_run_ok () {

    (( $# > 0 )) || return 1
    proc::try_run "$@" >/dev/null 2>&1

}
proc::try_run_all () {

    local cmd=""
    (( $# > 0 )) || return 1

    for cmd in "$@"; do

        [[ -n "${cmd}" ]] || return 1
        printf '+ %s\n' "${cmd}" >&2
        proc::try_run "${BASH:-bash}" -lc "${cmd}" || return 1

    done

}
proc::try_run_all_ok () {

    local cmd=""
    (( $# > 0 )) || return 1

    for cmd in "$@"; do
        [[ -n "${cmd}" ]] || return 1
        proc::try_run "${BASH:-bash}" -lc "${cmd}" >/dev/null 2>&1 || return 1
    done

}
