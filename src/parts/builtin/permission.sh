
perm::valid () {

    local v="${1:-}" kind="${2:-mode}"

    [[ -n "${v}" ]] || return 1
    [[ "${v}" != *$'\n'* && "${v}" != *$'\r'* ]] || return 1

    case "${kind}" in
        mode)
            [[ "${v}" =~ ^[0-7]{3,4}$ ]] && return 0
            [[ "${v}" =~ ^[ugoa]*[+-=][rwxXstugo]+(,[ugoa]*[+-=][rwxXstugo]+)*$ ]]
        ;;
        change)
            [[ "${v}" =~ ^[+-=]?[rwxXst]+$ ]] && return 0
            [[ "${v}" =~ ^[ugoa]*[+-=][rwxXstugo]+(,[ugoa]*[+-=][rwxXstugo]+)*$ ]]
        ;;
        remove)
            [[ "${v}" =~ ^[+-]?[rwxXst]+$ ]] && return 0
            [[ "${v}" =~ ^[ugoa]*[+-][rwxXstugo]+(,[ugoa]*[+-][rwxXstugo]+)*$ ]]
        ;;
        who)
            [[ "${v}" =~ ^[ugoa]+$ ]]
        ;;
        *)
            return 1
        ;;
    esac

}
perm::get () {

    local path="${1:-}" winpath="" out="" user="" domain_user="" owner="" other="" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if sys::is_windows && sys::has icacls.exe; then

        winpath="${path}"
        user="${USERNAME:-}"
        domain_user=""

        sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

        [[ -n "${user}" ]] || user="$(sys::username 2>/dev/null || true)"
        [[ -n "${USERDOMAIN:-}" && -n "${USERNAME:-}" ]] && domain_user="${USERDOMAIN}\\${USERNAME}"

        out="$(icacls.exe "${winpath}" 2>/dev/null | tr -d '\r' || true)"

        if [[ -n "${out}" && -n "${user}" ]]; then

            owner=0
            other=0

            if printf '%s\n' "${out}" | grep -Fi "${user}:" | grep -Eq '\(F\)' >/dev/null 2>&1; then owner=7
            elif [[ -n "${domain_user}" ]] && printf '%s\n' "${out}" | grep -Fi "${domain_user}:" | grep -Eq '\(F\)' >/dev/null 2>&1; then owner=7
            elif printf '%s\n' "${out}" | grep -Fi "${user}:" | grep -Eq '\(RX\)' >/dev/null 2>&1; then owner=5
            elif [[ -n "${domain_user}" ]] && printf '%s\n' "${out}" | grep -Fi "${domain_user}:" | grep -Eq '\(RX\)' >/dev/null 2>&1; then owner=5
            elif printf '%s\n' "${out}" | grep -Fi "${user}:" | grep -Eq '\(R,W\)|\(W,R\)|\(M\)' >/dev/null 2>&1; then owner=6
            elif [[ -n "${domain_user}" ]] && printf '%s\n' "${out}" | grep -Fi "${domain_user}:" | grep -Eq '\(R,W\)|\(W,R\)|\(M\)' >/dev/null 2>&1; then owner=6
            elif printf '%s\n' "${out}" | grep -Fi "${user}:" | grep -Eq '\(R\)' >/dev/null 2>&1; then owner=4
            elif [[ -n "${domain_user}" ]] && printf '%s\n' "${out}" | grep -Fi "${domain_user}:" | grep -Eq '\(R\)' >/dev/null 2>&1; then owner=4
            fi

            if printf '%s\n' "${out}" | grep -Ei "Users:|Everyone:|Authenticated Users:|S-1-5-32-545:" | grep -Eq '\(F\)' >/dev/null 2>&1; then other=7
            elif printf '%s\n' "${out}" | grep -Ei "Users:|Everyone:|Authenticated Users:|S-1-5-32-545:" | grep -Eq '\(RX\)' >/dev/null 2>&1; then other=5
            elif printf '%s\n' "${out}" | grep -Ei "Users:|Everyone:|Authenticated Users:|S-1-5-32-545:" | grep -Eq '\(R,W\)|\(W,R\)|\(M\)' >/dev/null 2>&1; then other=6
            elif printf '%s\n' "${out}" | grep -Ei "Users:|Everyone:|Authenticated Users:|S-1-5-32-545:" | grep -Eq '\(R\)' >/dev/null 2>&1; then other=4
            fi

            if (( owner > 0 )); then
                printf '%s%s%s\n' "${owner}" "${other}" "${other}"
                return 0
            fi

        fi

    fi

    sys::has stat || return 1

    v="$(stat -c '%a' "${path}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Lp' "${path}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
perm::set () {

    local path="${1:-}" mode="${2:-}" winpath="" user="" domain_user=""

    [[ -n "${path}" && -n "${mode}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${mode}" mode || return 1

    if sys::is_windows && sys::has icacls.exe; then

        winpath="${path}"
        user="${USERNAME:-}"

        sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

        [[ -n "${user}" ]] || user="$(sys::username 2>/dev/null || true)"
        [[ -n "${user}" ]] || return 1

        [[ -n "${USERDOMAIN:-}" && -n "${USERNAME:-}" ]] && domain_user="${USERDOMAIN}\\${USERNAME}"

        case "${mode}" in
            600)
                icacls.exe "${winpath}" /inheritance:r >/dev/null 2>&1 || return 1
                icacls.exe "${winpath}" /remove:g "*S-1-1-0" "*S-1-5-11" "*S-1-5-32-545" >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant:r "${user}:(R,W)" "*S-1-5-18:(F)" "*S-1-5-32-544:(F)" >/dev/null 2>&1 || {
                    [[ -n "${domain_user}" ]] || return 1
                    icacls.exe "${winpath}" /grant:r "${domain_user}:(R,W)" "*S-1-5-18:(F)" "*S-1-5-32-544:(F)" >/dev/null 2>&1 || return 1
                }
                sys::has chmod && { chmod 600 "${path}" >/dev/null 2>&1 || true; }
                return 0
            ;;
            644)
                icacls.exe "${winpath}" /inheritance:e >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant:r "${user}:(R,W)" "*S-1-5-32-545:(R)" >/dev/null 2>&1 || {
                    [[ -n "${domain_user}" ]] || return 1
                    icacls.exe "${winpath}" /grant:r "${domain_user}:(R,W)" "*S-1-5-32-545:(R)" >/dev/null 2>&1 || return 1
                }
                sys::has chmod && { chmod 644 "${path}" >/dev/null 2>&1 || true; }
                return 0
            ;;
            700)
                icacls.exe "${winpath}" /inheritance:r >/dev/null 2>&1 || return 1
                icacls.exe "${winpath}" /remove:g "*S-1-1-0" "*S-1-5-11" "*S-1-5-32-545" >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant:r "${user}:(F)" "*S-1-5-18:(F)" "*S-1-5-32-544:(F)" >/dev/null 2>&1 || {
                    [[ -n "${domain_user}" ]] || return 1
                    icacls.exe "${winpath}" /grant:r "${domain_user}:(F)" "*S-1-5-18:(F)" "*S-1-5-32-544:(F)" >/dev/null 2>&1 || return 1
                }
                sys::has chmod && { chmod 700 "${path}" >/dev/null 2>&1 || true; }
                return 0
            ;;
            755)
                icacls.exe "${winpath}" /inheritance:e >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant:r "${user}:(F)" "*S-1-5-32-545:(RX)" >/dev/null 2>&1 || {
                    [[ -n "${domain_user}" ]] || return 1
                    icacls.exe "${winpath}" /grant:r "${domain_user}:(F)" "*S-1-5-32-545:(RX)" >/dev/null 2>&1 || return 1
                }
                sys::has chmod && { chmod 755 "${path}" >/dev/null 2>&1 || true; }
                return 0
            ;;
        esac

    fi

    sys::has chmod || return 1
    chmod "${mode}" "${path}" >/dev/null 2>&1

}
perm::add () {

    local path="${1:-}" mode="${2:-}"

    [[ -n "${path}" && -n "${mode}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${mode}" change || return 1

    if sys::is_windows && sys::has icacls.exe; then

        [[ "${mode}" == *r* ]] && perm::read  "${path}" u
        [[ "${mode}" == *w* ]] && perm::write "${path}" u
        [[ "${mode}" == *x* || "${mode}" == *X* ]] && perm::execute "${path}" u

        sys::has chmod && {
            case "${mode}" in
                +*|-*|=*|[ugoa]*[+-=]*) chmod "${mode}" "${path}" >/dev/null 2>&1 || true ;;
                *)                       chmod "+${mode}" "${path}" >/dev/null 2>&1 || true ;;
            esac
        }

        return 0

    fi

    sys::has chmod || return 1

    case "${mode}" in
        +*|-*|=*|[ugoa]*[+-=]*) chmod "${mode}" "${path}" >/dev/null 2>&1 ;;
        *)                       chmod "+${mode}" "${path}" >/dev/null 2>&1 ;;
    esac

}
perm::del () {

    local path="${1:-}" mode="${2:-}"

    [[ -n "${path}" && -n "${mode}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    perm::valid "${mode}" remove || return 1
    sys::has chmod || return 1

    case "${mode}" in
        +*) chmod "-${mode#+}" "${path}" >/dev/null 2>&1 ;;
        -*) chmod "${mode}" "${path}" >/dev/null 2>&1 ;;
        =*) return 1 ;;
        [ugoa]*[+-=]*)
            case "${mode}" in
                *+*) chmod "${mode/+/-}" "${path}" >/dev/null 2>&1 ;;
                *-*) chmod "${mode}" "${path}" >/dev/null 2>&1 ;;
                *=*) return 1 ;;
            esac
        ;;
        *) chmod "-${mode}" "${path}" >/dev/null 2>&1 ;;
    esac

}

perm::read () {

    local path="${1:-}" who="${2:-u}" winpath="" user="" ok=1

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${who}" who || return 1

    if sys::is_windows; then

        if sys::has icacls.exe; then

            winpath="${path}"
            user="${USERNAME:-}"

            sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"
            [[ -n "${user}" ]] || user="$(sys::username 2>/dev/null || true)"

            if [[ -n "${user}" ]]; then
                case "${who}" in
                    *a*|*g*|*o*) icacls.exe "${winpath}" /grant "*S-1-5-32-545:(R)" >/dev/null 2>&1 && ok=0 ;;
                    *)           icacls.exe "${winpath}" /grant "${user}:(R)" >/dev/null 2>&1 && ok=0 ;;
                esac
            fi

        fi

        sys::has chmod && chmod "${who}+r" "${path}" >/dev/null 2>&1 && ok=0
        return "${ok}"

    fi

    sys::has chmod || return 1
    chmod "${who}+r" "${path}" >/dev/null 2>&1

}
perm::write () {

    local path="${1:-}" who="${2:-u}" winpath="" user="" ok=1

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${who}" who || return 1

    if sys::is_windows; then

        if sys::has icacls.exe; then

            winpath="${path}"
            user="${USERNAME:-}"

            sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"
            [[ -n "${user}" ]] || user="$(sys::username 2>/dev/null || true)"

            if [[ -n "${user}" ]]; then
                case "${who}" in
                    *a*|*g*|*o*) icacls.exe "${winpath}" /grant "*S-1-5-32-545:(W)" >/dev/null 2>&1 && ok=0 ;;
                    *)           icacls.exe "${winpath}" /grant "${user}:(W)" >/dev/null 2>&1 && ok=0 ;;
                esac
            fi

        fi

        sys::has chmod && chmod "${who}+w" "${path}" >/dev/null 2>&1 && ok=0
        return "${ok}"

    fi

    sys::has chmod || return 1
    chmod "${who}+w" "${path}" >/dev/null 2>&1

}
perm::execute () {

    local path="${1:-}" who="${2:-u}" winpath="" user="" ok=1

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${who}" who || return 1

    if sys::is_windows; then

        if sys::has icacls.exe; then

            winpath="${path}"
            user="${USERNAME:-}"

            sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"
            [[ -n "${user}" ]] || user="$(sys::username 2>/dev/null || true)"

            if [[ -n "${user}" ]]; then
                case "${who}" in
                    *a*|*g*|*o*) icacls.exe "${winpath}" /grant "*S-1-5-32-545:(RX)" >/dev/null 2>&1 && ok=0 ;;
                    *)           icacls.exe "${winpath}" /grant "${user}:(RX)" >/dev/null 2>&1 && ok=0 ;;
                esac
            fi

        fi

        sys::has chmod && chmod "${who}+x" "${path}" >/dev/null 2>&1 && ok=0
        return "${ok}"

    fi

    sys::has chmod || return 1
    chmod "${who}+x" "${path}" >/dev/null 2>&1

}
perm::writeonly () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    perm::write "${path}" u || return 1
    perm::del   "${path}" r || true

}
perm::readonly () {

    local path="${1:-}" who="${2:-u}"

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${who}" who || return 1

    perm::read "${path}" "${who}" || return 1
    perm::del  "${path}" w

}
perm::private () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -d "${path}" && ! -L "${path}" ]]; then
        perm::set "${path}" 700
        return
    fi

    perm::set "${path}" 600

}
perm::public () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -d "${path}" && ! -L "${path}" ]]; then
        perm::set "${path}" 755
        return
    fi

    perm::set "${path}" 644

}

perm::owner () {

    local path="${1:-}" user="${2:-}" winpath="" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -n "${user}" ]]; then

        [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1
        [[ "${user}" != *';'* && "${user}" != *'|'* && "${user}" != *'&'* && "${user}" != *'`'* ]] || return 1

        if sys::is_windows && sys::has icacls.exe; then

            winpath="${path}"

            sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"
            icacls.exe "${winpath}" /setowner "${user}" >/dev/null 2>&1 || return 1

            return 0

        fi

        sys::has chown || return 1
        chown "${user}" "${path}" >/dev/null 2>&1

        return

    fi

    sys::has stat || return 1

    v="$(stat -c '%U' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != *$'\n'* && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Su' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != *$'\n'* && "${v}" != "  File:"* ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
perm::group () {

    local path="${1:-}" group="${2:-}" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -n "${group}" ]]; then

        [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1
        [[ "${group}" != *';'* && "${group}" != *'|'* && "${group}" != *'&'* && "${group}" != *'`'* ]] || return 1

        sys::is_windows && return 1

        sys::has chgrp || return 1
        chgrp "${group}" "${path}" >/dev/null 2>&1

        return

    fi

    sys::is_windows && { printf '%s\n' "Users"; return 0; }
    sys::has stat || return 1

    v="$(stat -c '%G' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != *$'\n'* && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Sg' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != *$'\n'* && "${v}" != "  File:"* ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
perm::lock () {

    local path="${1:-}" who="${2:-u}" winpath="" user="" ok=1

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${who}" who || return 1

    if sys::is_windows; then

        if sys::has icacls.exe; then

            winpath="${path}"
            user="${USERNAME:-}"

            sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"
            [[ -n "${user}" ]] || user="$(sys::username 2>/dev/null || true)"

            if [[ -n "${user}" ]]; then
                case "${who}" in
                    *a*|*g*|*o*) icacls.exe "${winpath}" /deny "*S-1-5-32-545:(W)" >/dev/null 2>&1 && ok=0 ;;
                    *)           icacls.exe "${winpath}" /deny "${user}:(W)" >/dev/null 2>&1 && ok=0 ;;
                esac
            fi

        fi

        sys::has chmod && chmod "${who}-w" "${path}" >/dev/null 2>&1 && ok=0
        return "${ok}"

    fi

    sys::has chmod || return 1
    chmod "${who}-w" "${path}" >/dev/null 2>&1

}
perm::unlock () {

    local path="${1:-}" who="${2:-u}" winpath="" user="" ok=1

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${who}" who || return 1

    if sys::is_windows; then

        if sys::has icacls.exe; then

            winpath="${path}"
            user="${USERNAME:-}"

            sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"
            [[ -n "${user}" ]] || user="$(sys::username 2>/dev/null || true)"

            if [[ -n "${user}" ]]; then
                case "${who}" in
                    *a*|*g*|*o*)
                        icacls.exe "${winpath}" /remove:d "*S-1-5-32-545" >/dev/null 2>&1 || true
                        icacls.exe "${winpath}" /grant "*S-1-5-32-545:(W)" >/dev/null 2>&1 && ok=0
                    ;;
                    *)
                        icacls.exe "${winpath}" /remove:d "${user}" >/dev/null 2>&1 || true
                        icacls.exe "${winpath}" /grant "${user}:(W)" >/dev/null 2>&1 && ok=0
                    ;;
                esac
            fi

        fi

        sys::has chmod && chmod "${who}+w" "${path}" >/dev/null 2>&1 && ok=0
        return "${ok}"

    fi

    sys::has chmod || return 1
    chmod "${who}+w" "${path}" >/dev/null 2>&1

}

perm::readable () {

    local path="${1:-}"

    [[ -n "${path}" && -r "${path}" ]]

}
perm::writable () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -w "${path}" ]]

}
perm::executable () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -x "${path}" ]]

}
perm::editable () {

    local path="${1:-}" who="${2:-u}"

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${who}" who || return 1

    perm::read  "${path}" "${who}" || return 1
    perm::write "${path}" "${who}"

}
perm::owned () {

    local path="${1:-}" user="${2:-}" owner=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    [[ -n "${user}" ]] || user="$(sys::username 2>/dev/null || true)"
    [[ -n "${user}" ]] || return 1
    [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1

    owner="$(perm::owner "${path}" 2>/dev/null || true)"
    [[ "${owner}" == "${user}" ]]

}
perm::same () {

    local a="${1:-}" b="${2:-}" am="" bm=""

    [[ -n "${a}" && -n "${b}" ]] || return 1
    [[ -e "${a}" || -L "${a}" ]] || return 1
    [[ -e "${b}" || -L "${b}" ]] || return 1

    am="$(perm::get "${a}" 2>/dev/null || true)"
    bm="$(perm::get "${b}" 2>/dev/null || true)"

    [[ -n "${am}" && "${am}" == "${bm}" ]]

}

perm::copy () {

    local from="${1:-}" to="${2:-}" mode="" owner="" group=""

    [[ -n "${from}" && -n "${to}" ]] || return 1
    [[ -e "${from}" || -L "${from}" ]] || return 1
    [[ -e "${to}"   || -L "${to}"   ]] || return 1

    mode="$(perm::get "${from}" 2>/dev/null || true)"
    [[ -n "${mode}" ]] && perm::set "${to}" "${mode}" || return 1

    owner="$(perm::owner "${from}" 2>/dev/null || true)"
    [[ -n "${owner}" ]] && { perm::owner "${to}" "${owner}" >/dev/null 2>&1 || true; }

    group="$(perm::group "${from}" 2>/dev/null || true)"
    [[ -n "${group}" ]] && { perm::group "${to}" "${group}" >/dev/null 2>&1 || true; }

    return 0

}
perm::ensure () {

    local path="${1:-}" mode="${2:-}" current=""

    [[ -n "${path}" && -n "${mode}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    perm::valid "${mode}" mode || return 1

    current="$(perm::get "${path}" 2>/dev/null || true)"
    [[ "${current}" == "${mode}" ]] && return 0

    perm::set "${path}" "${mode}"

}
perm::info () {

    local path="${1:-}" mode="" owner="" group=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    mode="$(perm::get   "${path}" 2>/dev/null || true)"
    owner="$(perm::owner "${path}" 2>/dev/null || true)"
    group="$(perm::group "${path}" 2>/dev/null || true)"

    [[ -n "${mode}"  ]] || mode="unknown"
    [[ -n "${owner}" ]] || owner="unknown"
    [[ -n "${group}" ]] || group="unknown"

    printf '%s\n' "path=${path}" "mode=${mode}" "owner=${owner}" "group=${group}"

}
