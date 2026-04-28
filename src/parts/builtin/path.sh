
path::valid () {

    local p="${1:-}"

    [[ -n "${p}" ]] || return 1
    [[ "${p}" != *$'\n'* && "${p}" != *$'\r'* ]] || return 1

    return 0

}
path::exists () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -e "${p}" || -L "${p}" ]]

}
path::missing () {

    local p="${1:-}"

    path::valid "${p}" || return 0
    [[ ! -e "${p}" && ! -L "${p}" ]]

}
path::empty () {

    local p="${1:-}" entry=""

    path::missing "${p}" && return 0

    if [[ -d "${p}" ]]; then

        for entry in "${p}"/* "${p}"/.[!.]* "${p}"/..?*; do
            [[ -e "${entry}" || -L "${entry}" ]] && return 1
        done

        return 0

    fi

    [[ ! -s "${p}" ]]

}
path::filled () {

    path::empty "$@" && return 1

    [[ -e "${1:-}" || -L "${1:-}" ]]

}
path::is_abs () {

    local p="${1:-}"

    [[ -n "${p}" ]] || return 1
    [[ "${p}" == /* ]] && return 0
    [[ "${p}" == \\* ]] && return 0
    [[ "${p}" =~ ^[A-Za-z]:[\\/] ]] && return 0

    return 1

}
path::is_rel () {

    path::is_abs "${1:-}" && return 1
    [[ -n "${1:-}" ]] || return 1

    return 0

}

path::cwd () {

    pwd 2>/dev/null

}
path::pwd () {

    pwd -P 2>/dev/null

}
path::drive () {

    local p="${1:-}"

    [[ "${p}" =~ ^([A-Za-z]):.* ]] || return 1
    printf '%s:' "${BASH_REMATCH[1]}"

}
path::dirname () {

    local p="${1:-}" dir="" drive="" rest=""

    path::valid "${p}" || return 1
    p="${p//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]:)(.*)$ ]]; then

        drive="${BASH_REMATCH[1]}"
        rest="${BASH_REMATCH[2]}"

        [[ -n "${rest}" ]] || { printf '%s' "${drive}"; return 0; }
        [[ "${rest}" == */* ]] || { printf '%s' "${drive}"; return 0; }

        dir="${rest%/*}"
        [[ -n "${dir}" ]] || dir="/"

        printf '%s%s' "${drive}" "${dir}"
        return 0

    fi

    if [[ "${p}" != */* ]]; then printf '.'; return 0; fi

    dir="${p%/*}"
    [[ -n "${dir}" ]] || dir="/"

    printf '%s' "${dir}"

}
path::basename () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    p="${p//\\//}"

    while [[ "${p}" == */ && ${#p} -gt 1 ]]; do
        p="${p%/}"
    done

    printf '%s' "${p##*/}"

}
path::parentname () {

    local p="${1:-}" parent="" name=""

    parent="$(path::dirname "${p}")" || return 1
    name="$(path::basename "${parent}")" || return 1

    [[ "${name}" != "." && "${name}" != "/" ]] || return 1
    printf '%s' "${name}"

}

path::stem () {

    local path_base="" lead="" rest=""

    path_base="$(path::basename "${1:-}")" || return 1

    lead="${path_base%%[!.]*}"
    rest="${path_base#"${lead}"}"

    [[ "${rest}" == *.* ]] && { printf '%s' "${path_base%.*}"; return 0; }
    printf '%s' "${path_base}"

}
path::ext () {

    local path_base="" lead="" rest=""

    path_base="$(path::basename "${1:-}")" || return 1

    lead="${path_base%%[!.]*}"
    rest="${path_base#"${lead}"}"

    [[ "${rest}" == *.* ]] && { printf '%s' "${path_base##*.}"; return 0; }
    printf ''

}
path::dotext () {

    local path_base="" lead="" rest=""

    path_base="$(path::basename "${1:-}")" || return 1

    lead="${path_base%%[!.]*}"
    rest="${path_base#"${lead}"}"

    [[ "${rest}" == *.* ]] && { printf '.%s' "${path_base##*.}"; return 0; }
    printf ''

}
path::setname () {

    local p="${1:-}" name="${2:-}" dir=""

    path::valid "${p}" || return 1
    [[ -n "${name}" ]] || return 1

    dir="$(path::dirname "${p}")"

    if [[ "${dir}" == "." && "${p}" != ./* ]]; then printf '%s' "${name}"
    else printf '%s/%s' "${dir%/}" "${name}"
    fi

}
path::setstem () {

    local p="${1:-}" stem="${2:-}" dir="" ext=""

    path::valid "${p}" || return 1
    [[ -n "${stem}" ]] || return 1

    dir="$(path::dirname "${p}")"
    ext="$(path::dotext "${p}")"

    if [[ "${dir}" == "." && "${p}" != ./* ]]; then printf '%s%s' "${stem}" "${ext}"
    else printf '%s/%s%s' "${dir%/}" "${stem}" "${ext}"
    fi

}
path::setext () {

    local p="${1:-}" ext="${2:-}" dir="" stem=""

    path::valid "${p}" || return 1

    dir="$(path::dirname "${p}")"
    stem="$(path::stem "${p}")"

    [[ -n "${ext}" && "${ext}" != .* ]] && ext=".${ext}"

    if [[ "${dir}" == "." && "${p}" != ./* ]]; then printf '%s%s' "${stem}" "${ext}"
    else printf '%s/%s%s' "${dir%/}" "${stem}" "${ext}"
    fi

}

path::posix () {

    local p="${1:-}" v="" letter=""

    path::valid "${p}" || return 1

    [[ "${p}" =~ ^[A-Za-z]:([^\\/].*)?$ ]] && return 1

    if sys::has cygpath; then
        v="$(cygpath -u -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }
    fi

    p="${p//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]):/(.*)$ ]]; then

        letter="${BASH_REMATCH[1]}"
        letter="${letter,,}"

        if sys::is_wsl; then printf '/mnt/%s' "${letter}"
        else printf '/%s' "${letter}"
        fi

        [[ -n "${BASH_REMATCH[2]}" ]] && printf '/%s' "${BASH_REMATCH[2]}"
        return 0

    fi

    printf '%s' "${p}"

}
path::windows () {

    local p="${1:-}" v="" letter="" rest=""

    path::valid "${p}" || return 1

    p="${p//\\//}"

    if [[ "${p}" =~ ^/mnt/([A-Za-z])(/.*)?$ ]]; then

        letter="${BASH_REMATCH[1]}"
        letter="${letter^^}"
        rest="${BASH_REMATCH[2]:-/}"
        rest="${rest//\//\\}"

        printf '%s:%s' "${letter}" "${rest}"
        return 0

    fi
    if sys::is_windows && [[ "${p}" =~ ^/([A-Za-z])(/.*)?$ ]]; then

        letter="${BASH_REMATCH[1]}"
        letter="${letter^^}"
        rest="${BASH_REMATCH[2]:-/}"
        rest="${rest//\//\\}"

        printf '%s:%s' "${letter}" "${rest}"
        return 0

    fi
    if [[ "${p}" =~ ^([A-Za-z]):(.*)$ ]]; then

        letter="${BASH_REMATCH[1]}"
        rest="${BASH_REMATCH[2]}"
        rest="${rest//\//\\}"

        printf '%s:%s' "${letter^^}" "${rest}"
        return 0

    fi

    if sys::has cygpath; then

        v="$(cygpath -w -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi

    printf '%s' "${p//\//\\}"

}
path::native () {

    local p="${1:-}"

    path::valid "${p}" || return 1

    if sys::is_windows; then path::windows "${p}"
    else path::posix "${p}"
    fi

}
path::quote () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    printf '%q' "${p}"

}
path::resolve () {

    local p="${1:-}" parent="" base="" v=""

    path::valid "${p}" || return 1

    if sys::has realpath; then

        v="$(realpath -m -- "${p}" 2>/dev/null)" || true
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

        v="$(realpath -- "${p}" 2>/dev/null)" || true
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi
    if sys::has readlink; then

        v="$(readlink -f -- "${p}" 2>/dev/null)" || true
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi

    if [[ -d "${p}" ]]; then
        v="$( cd -- "${p}" 2>/dev/null && pwd -P 2>/dev/null )" && { printf '%s' "${v}"; return 0; }
    fi

    parent="$(path::dirname "${p}")"
    base="$(path::basename "${p}")"

    if [[ -d "${parent}" ]]; then
        v="$( cd -- "${parent}" 2>/dev/null && pwd -P 2>/dev/null )" && {
            [[ -n "${base}" && "${base}" != "/" ]] && printf '%s/%s' "${v}" "${base}" || printf '%s' "${v}"
            return 0
        }
    fi

    path::abs "${p}"

}
path::normalize () {

    local p="${1:-}" prefix="" first="" head=""
    local -a parts=()
    local -a out=()

    path::valid "${p}" || return 1

    p="${p//\\//}"
    [[ "${p}" =~ ^/+$ ]] && { printf '/'; return 0; }

    if [[ "${p}" =~ ^([A-Za-z]:)(/?)(.*)$ ]]; then

        prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
        p="${BASH_REMATCH[3]}"

    elif [[ "${p}" == //* ]]; then

        p="${p#//}"
        head="${p%%/*}"
        p="${p#"${head}"}"
        p="${p#/}"
        prefix="//${head}/"

    elif [[ "${p}" == /* ]]; then

        prefix="/"
        p="${p#/}"

    fi

    while [[ "${p}" == *//* ]]; do
        p="${p//\/\//\/}"
    done

    [[ -z "${p}" ]] || IFS='/' read -r -a parts <<< "${p}"

    for first in "${parts[@]}"; do

        case "${first}" in
            ""|.)
                continue
            ;;
            ..)
                if (( ${#out[@]} > 0 )) && [[ "${out[-1]}" != ".." ]]; then unset 'out[-1]'
                elif [[ -z "${prefix}" ]]; then out+=( ".." )
                fi
            ;;
            *)
                out+=( "${first}" )
            ;;
        esac

    done

    if (( ${#out[@]} == 0 )); then

        if [[ "${prefix}" == */ ]]; then printf '%s' "${prefix}"
        elif [[ -n "${prefix}" ]]; then printf '%s' "${prefix}"
        else printf '%s' "."
        fi

        return 0

    fi

    head="$( IFS='/'; printf '%s' "${out[*]}" )"

    if [[ -n "${prefix}" ]]; then printf '%s%s' "${prefix}" "${head}"
    else printf '%s' "${head}"
    fi

}
path::expand () {

    local p="${1:-}" home="" user="" head=""

    [[ -n "${p}" ]] || return 1

    head="${p:0:1}"
    [[ "${head}" == "~" ]] || { printf '%s' "${p}"; return 0; }

    if [[ "${p}" == "~" ]]; then

        home="${HOME:-}"
        [[ -n "${home}" ]] || home="$(sys::uhome 2>/dev/null || true)"
        [[ -n "${home}" ]] || return 1

        printf '%s' "${home}"
        return 0

    fi
    if [[ "${p:0:1}" == "~" && "${p:1:1}" == "/" ]]; then

        home="${HOME:-}"
        [[ -n "${home}" ]] || home="$(sys::uhome 2>/dev/null || true)"
        [[ -n "${home}" ]] || return 1

        printf '%s%s' "${home}" "${p:1}"
        return 0

    fi

    user="${p:1}"
    user="${user%%/*}"

    [[ -n "${user}" ]] || return 1
    [[ "${user}" =~ ^[A-Za-z0-9._-]+$ ]] || return 1

    if sys::has getent; then home="$(getent passwd "${user}" 2>/dev/null | awk -F: 'NR==1 {print $6}')"
    elif sys::is_macos && sys::has dscl; then home="$(dscl . -read "/Users/${user}" NFSHomeDirectory 2>/dev/null | awk 'NR==1 {print $2}')"
    else return 1
    fi

    [[ -n "${home}" ]] || return 1

    if [[ "${p}" == "~${user}" ]]; then printf '%s' "${home}"
    else printf '%s%s' "${home}" "${p:$(( 1 + ${#user} ))}"
    fi

}
path::join () {

    local acc="" seg="" sep="/" first=1

    (( $# > 0 )) || return 1

    for seg in "$@"; do

        [[ -n "${seg}" ]] || continue
        seg="${seg//\\//}"

        if (( first )); then acc="${seg}"; first=0
        elif path::is_abs "${seg}"; then acc="${seg}"
        elif [[ "${acc}" == */ || "${acc}" == *\\ ]]; then acc="${acc}${seg}"
        else acc="${acc}${sep}${seg}"
        fi

    done

    [[ -n "${acc}" ]] || acc="."
    path::normalize "${acc}"

}
path::joinlist () {

    local delim=":" item="" joined=""

    sys::is_windows && delim=";"

    for item in "$@"; do

        [[ -n "${item}" ]] || continue

        if [[ -z "${joined}" ]]; then joined="${item}"
        else joined="${joined}${delim}${item}"
        fi

    done

    printf '%s' "${joined}"

}
path::abs () {

    local p="${1:-}"

    path::valid "${p}" || return 1

    if path::is_abs "${p}"; then path::normalize "${p}"
    else path::normalize "$(pwd 2>/dev/null || printf '.')/${p}"
    fi

}
path::can () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    [[ -e "${p}" || -L "${p}" ]] || return 1

    if sys::has realpath; then

        v="$(realpath -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi
    if sys::has readlink; then

        v="$(readlink -f -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi

    v="$(path::resolve "${p}" 2>/dev/null || true)"
    [[ -n "${v}" ]] || return 1

    printf '%s' "${v}"

}
path::rel () {

    local target="${1:-}" base="${2:-}" t_abs="" b_abs="" common=0 v="" target_drive="" base_drive="" td="" bd="" i=0 max=0 up=0

    local -a tparts=()
    local -a bparts=()

    path::valid "${target}" || return 1
    [[ -n "${base}" ]] || base="$(pwd 2>/dev/null || printf '.')"

    target_drive="${target:0:1}"
    base_drive="${base:0:1}"

    if [[ "${target:1:1}" == ":" && "${base:1:1}" == ":" && "${target_drive,,}" != "${base_drive,,}" ]]; then
        printf '%s' "${target//\\//}"
        return 0
    fi

    t_abs="$(path::abs "${target}")" || return 1
    b_abs="$(path::abs "${base}")" || return 1

    t_abs="${t_abs//\\//}"
    b_abs="${b_abs//\\//}"

    td="${t_abs:0:1}"
    bd="${b_abs:0:1}"

    if [[ "${t_abs}" =~ ^[A-Za-z]: && "${b_abs}" =~ ^[A-Za-z]: && "${td,,}" != "${bd,,}" ]]; then
        printf '%s' "${t_abs}"
        return 0
    fi

    IFS='/' read -r -a tparts <<< "${t_abs#/}"
    IFS='/' read -r -a bparts <<< "${b_abs#/}"

    max=${#tparts[@]}
    (( ${#bparts[@]} < max )) && max=${#bparts[@]}

    for (( i=0; i<max; i++ )); do
        [[ "${tparts[$i]}" == "${bparts[$i]}" ]] || break
        common=$(( i + 1 ))
    done

    up=$(( ${#bparts[@]} - common ))

    while (( up > 0 )); do
        v+="../"
        up=$(( up - 1 ))
    done

    for (( i=common; i<${#tparts[@]}; i++ )); do
        v+="${tparts[$i]}/"
    done

    v="${v%/}"
    [[ -n "${v}" ]] || v="."

    printf '%s' "${v}"

}

path::parts () {

    local p="${1:-}" prefix="" head=""
    local -a parts=()

    path::valid "${p}" || return 1
    p="${p//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]):(/?)(.*)$ ]]; then

        prefix="${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
        p="${BASH_REMATCH[3]}"

    elif [[ "${p}" == //* ]]; then

        p="${p#//}"
        head="${p%%/*}"
        p="${p#"${head}"}"
        p="${p#/}"
        prefix="//${head}/"

    elif [[ "${p}" == /* ]]; then

        prefix="/"
        p="${p#/}"

    fi

    [[ -n "${prefix}" ]] && printf '%s\n' "${prefix}"

    while [[ "${p}" == *//* ]]; do p="${p//\/\//\/}"; done

    [[ -z "${p}" ]] && return 0

    IFS='/' read -r -a parts <<< "${p}"

    for head in "${parts[@]}"; do
        [[ -n "${head}" ]] && printf '%s\n' "${head}"
    done

}
path::ancestors () {

    local p="${1:-}" cur=""

    path::valid "${p}" || return 1
    cur="$(path::dirname "${p}")" || return 1

    while [[ -n "${cur}" && "${cur}" != "." ]]; do

        printf '%s\n' "${cur}"
        path::is_root "${cur}" && return 0

        cur="$(path::dirname "${cur}")" || return 1

    done

    return 0

}
path::splitlist () {

    local list="${1:-}" delim=":" part=""

    sys::is_windows && delim=";"

    [[ -n "${list}" ]] || return 0

    while [[ "${list}" == *"${delim}"* ]]; do

        part="${list%%"${delim}"*}"
        list="${list#*"${delim}"}"

        [[ -n "${part}" ]] && printf '%s\n' "${part}"

    done

    [[ -n "${list}" ]] && printf '%s\n' "${list}"

}
path::depth () {

    local p="${1:-}" n=0

    path::valid "${p}" || return 1

    while IFS= read -r _; do
        n=$(( n + 1 ))
    done < <(path::parts "${p}")

    printf '%s\n' "${n}"

}
path::common () {

    local first="" cur="" prefix="" cur_prefix="" p="" head="" i=0
    local -a a=()
    local -a b=()
    local -a out=()

    (( $# > 0 )) || return 1

    first="$(path::abs "${1}")" || return 1
    shift || true

    p="${first//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]:)(/?)(.*)$ ]]; then
        prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
        p="${BASH_REMATCH[3]}"
    elif [[ "${p}" == //* ]]; then
        p="${p#//}"
        head="${p%%/*}"
        p="${p#"${head}"}"
        p="${p#/}"
        prefix="//${head}/"
    elif [[ "${p}" == /* ]]; then
        prefix="/"
        p="${p#/}"
    fi

    [[ -z "${p}" ]] || IFS='/' read -r -a a <<< "${p}"

    for cur in "$@"; do

        cur="$(path::abs "${cur}")" || return 1
        p="${cur//\\//}"
        cur_prefix=""

        if [[ "${p}" =~ ^([A-Za-z]:)(/?)(.*)$ ]]; then
            cur_prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
            p="${BASH_REMATCH[3]}"
        elif [[ "${p}" == //* ]]; then
            p="${p#//}"
            head="${p%%/*}"
            p="${p#"${head}"}"
            p="${p#/}"
            cur_prefix="//${head}/"
        elif [[ "${p}" == /* ]]; then
            cur_prefix="/"
            p="${p#/}"
        fi

        [[ "${prefix,,}" == "${cur_prefix,,}" ]] || return 1

        b=()
        [[ -z "${p}" ]] || IFS='/' read -r -a b <<< "${p}"

        out=()
        i=0

        while (( i < ${#a[@]} && i < ${#b[@]} )); do
            [[ "${a[$i]}" == "${b[$i]}" ]] || break
            out+=( "${a[$i]}" )
            i=$(( i + 1 ))
        done

        a=( "${out[@]}" )

    done

    if (( ${#a[@]} == 0 )); then
        [[ -n "${prefix}" ]] && printf '%s' "${prefix}" || printf '.'
    elif [[ -n "${prefix}" ]]; then
        printf '%s%s' "${prefix}" "$( IFS='/'; printf '%s' "${a[*]}" )"
    else
        printf '%s' "$( IFS='/'; printf '%s' "${a[*]}" )"
    fi

}
path::slashify () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    printf '%s' "${p//\\//}"

}
path::slugify () {

    local text="${1:-}" slug_fallback="${2:-_}" max="${3:-255}" lower="${4:-1}" base="" ext=""

    [[ -n "${slug_fallback}" ]] || slug_fallback="_"
    [[ "${max}" =~ ^[0-9]+$ ]] || max=255
    (( max > 0 )) || max=255

    text="${text//$'\n'/-}"
    text="${text//$'\r'/-}"
    text="${text//$'\t'/-}"
    text="${text// /-}"
    text="${text//\//-}"
    text="${text//\\/-}"
    text="${text//:/-}"
    text="${text//\*/-}"
    text="${text//\?/-}"
    text="${text//\"/-}"
    text="${text//</-}"
    text="${text//>/-}"
    text="${text//|/-}"
    text="${text//\'/-}"
    text="${text//\`/-}"
    text="${text//;/-}"
    text="${text//,/-}"
    text="${text//&/-}"
    text="${text//=/-}"
    text="${text//+/-}"
    text="${text//%/-}"
    text="${text//#/-}"
    text="${text//@/-}"
    text="${text//\!/-}"
    text="${text//\(/-}"
    text="${text//\)/-}"
    text="${text//\{/-}"
    text="${text//\}/-}"
    text="${text//\[/-}"
    text="${text//\]/-}"

    [[ "${lower}" == "1" ]] && text="${text,,}"

    while [[ "${text}" == *"--"* ]]; do text="${text//--/-}"; done
    while [[ "${text}" == "-"* || "${text}" == "."* ]]; do text="${text#?}"; done
    while [[ "${text}" == *"-" || "${text}" == *"." ]]; do text="${text%?}"; done

    [[ -n "${text}" && "${text}" != "." && "${text}" != ".." ]] || text="${slug_fallback}"

    base="${text%%.*}"
    ext=""

    [[ "${text}" == *.* && "${text}" != .* ]] && ext=".${text#*.}"

    case "${base,,}" in
        con|prn|aux|nul|clock\$|com[1-9]|lpt[1-9]) text="${base}_${ext}" ;;
    esac

    if (( ${#text} > max )); then

        text="${text:0:max}"

        while [[ "${text}" == *"-" || "${text}" == *"." ]]; do
            text="${text%?}"
        done

        [[ -n "${text}" ]] || text="${slug_fallback}"

    fi

    printf '%s' "${text}"

}

path::match () {

    local p="${1:-}" pattern="${2:-}"

    path::valid "${p}" || return 1
    [[ -n "${pattern}" ]] || return 1

    # shellcheck disable=SC2254
    case "${p}" in
        ${pattern}) return 0 ;;
        *) return 1 ;;
    esac

}
path::starts_with () {

    local path_value="${1:-}" prefix="${2:-}" p="" x=""

    path::valid "${path_value}" || return 1
    path::valid "${prefix}" || return 1

    p="$(path::normalize "${path_value}")" || return 1
    x="$(path::normalize "${prefix}")" || return 1

    p="${p%/}"
    x="${x%/}"

    [[ "${p}" == "${x}" || "${p}" == "${x}/"* ]]

}
path::ends_with () {

    local path_value="${1:-}" suffix="${2:-}" p="" x=""

    path::valid "${path_value}" || return 1
    path::valid "${suffix}" || return 1

    p="$(path::normalize "${path_value}")" || return 1
    x="$(path::normalize "${suffix}")" || return 1

    p="${p%/}"
    x="${x%/}"

    [[ "${p}" == "${x}" || "${p}" == */"${x}" ]]

}
path::has_ext () {

    local p="${1:-}" ext="" got=""

    path::valid "${p}" || return 1

    shift || return 1
    (( $# > 0 )) || return 1

    got="$(path::ext "${p}")" || return 1
    [[ -n "${got}" ]] || return 1

    for ext in "$@"; do

        ext="${ext#.}"
        [[ -n "${ext}" ]] || continue
        [[ "${got,,}" == "${ext,,}" ]] && return 0

    done

    return 1

}
path::has_drive () {

    local p="${1:-}"

    [[ "${p}" =~ ^[A-Za-z]: ]]

}
path::is_root () {

    local p="${1:-}"

    [[ -n "${p}" ]] || return 1
    [[ "${p}" == "/" ]] && return 0
    [[ "${p}" == "\\" ]] && return 0
    [[ "${p}" =~ ^[A-Za-z]:[\\/]?$ ]] && return 0

    return 1

}
path::is_unc () {

    local p="${1:-}"
    [[ "${p}" == //* || "${p}" == \\\\* ]]

}
path::is_same () {

    local pa="${1:-}" pb="${2:-}" x="" y=""

    path::valid "${pa}" || return 1
    path::valid "${pb}" || return 1

    [[ -e "${pa}" || -L "${pa}" ]] || return 1
    [[ -e "${pb}" || -L "${pb}" ]] || return 1

    [[ "${pa}" -ef "${pb}" ]] && return 0

    x="$(path::resolve "${pa}" 2>/dev/null || true)"
    y="$(path::resolve "${pb}" 2>/dev/null || true)"

    [[ -n "${x}" && -n "${y}" && "${x}" == "${y}" ]]

}
path::is_under () {

    local child="${1:-}" parent="${2:-}" x="" y=""

    path::valid "${child}" || return 1
    path::valid "${parent}" || return 1

    x="$(path::resolve "${child}" 2>/dev/null || path::abs "${child}")" || return 1
    y="$(path::resolve "${parent}" 2>/dev/null || path::abs "${parent}")" || return 1

    x="${x%/}"
    y="${y%/}"

    [[ -n "${x}" && -n "${y}" ]] || return 1
    path::is_root "${y}" && return 1

    [[ "${x}" == "${y}/"* ]]

}
path::is_parent () {

    local parent="${1:-}" child="${2:-}"
    path::is_under "${child}" "${parent}"

}
path::is_safe () {

    local target="${1:-}" root="${2:-}" t="" r=""

    path::valid "${target}" || return 1
    path::valid "${root}" || return 1

    path::is_root "${target}" && return 1
    path::is_root "${root}" && return 1

    case "${target}" in
        "."|".."|../*|*/../*|*/..)
            return 1
        ;;
    esac

    t="$(path::resolve "${target}" 2>/dev/null || path::abs "${target}")" || return 1
    r="$(path::resolve "${root}" 2>/dev/null || path::abs "${root}")" || return 1

    t="${t%/}"
    r="${r%/}"

    [[ -n "${t}" && -n "${r}" ]] || return 1
    [[ "${t}" == "${r}" || "${t}" == "${r}/"* ]]

}

path::is_file () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -f "${p}" ]]

}
path::is_dir () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -d "${p}" ]]

}
path::is_link () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -L "${p}" ]]

}
path::is_pipe () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -p "${p}" ]]

}
path::is_socket () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -S "${p}" ]]

}
path::is_block () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -b "${p}" ]]

}
path::is_char () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -c "${p}" ]]

}
path::is_hidden () {

    local p="${1:-}" base="" attr=""

    path::valid "${p}" || return 1

    base="$(path::basename "${p}")" || return 1
    [[ "${base}" == .* && "${base}" != "." && "${base}" != ".." ]] && return 0

    if sys::is_windows && sys::has attrib.exe; then

        attr="$(attrib.exe "$(path::windows "${p}")" 2>/dev/null | tr -d '\r' | awk 'NR==1 {print $1}' || true)"
        [[ "${attr}" == *H* ]] && return 0

    fi

    return 1

}
path::is_dot () {

    local p="${1:-}" base=""

    path::valid "${p}" || return 1

    base="$(path::basename "${p}")" || return 1
    [[ "${base}" == .* && "${base}" != "." && "${base}" != ".." ]]

}
path::readable () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -r "${p}" ]]

}
path::writable () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -w "${p}" ]]

}
path::executable () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -x "${p}" ]]

}

path::type () {

    local p="${1:-}"

    path::valid "${p}" || return 1

    [[ -L "${p}" ]] && { printf 'link';   return 0; }
    [[ -d "${p}" ]] && { printf 'dir';    return 0; }
    [[ -f "${p}" ]] && { printf 'file';   return 0; }
    [[ -p "${p}" ]] && { printf 'pipe';   return 0; }
    [[ -S "${p}" ]] && { printf 'socket'; return 0; }
    [[ -b "${p}" ]] && { printf 'block';  return 0; }
    [[ -c "${p}" ]] && { printf 'char';   return 0; }
    [[ -e "${p}" ]] && { printf 'other';  return 0; }

    return 1

}
path::size () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    [[ -e "${p}" || -L "${p}" ]] || return 1

    if [[ -f "${p}" ]] && sys::has stat; then

        v="$(stat -c '%s' -- "${p}" 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

        v="$(stat -f '%z' -- "${p}" 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has wc && [[ -f "${p}" ]]; then

        v="$(wc -c < "${p}" 2>/dev/null | tr -d '[:space:]' || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if [[ -d "${p}" ]] && sys::has du; then

        v="$(du -sk -- "${p}" 2>/dev/null | awk 'NR==1 {print $1}' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }

    fi

    return 1

}
path::mtime () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    sys::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%Y' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%m' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::atime () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    sys::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%X' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%a' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::ctime () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    sys::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%Z' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%c' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::age () {

    local p="${1:-}" m="" now=""

    m="$(path::mtime "${p}" 2>/dev/null || true)" || return 1
    [[ "${m}" =~ ^[0-9]+$ ]] || return 1

    now="$(date +%s 2>/dev/null || true)"
    [[ "${now}" =~ ^[0-9]+$ ]] || return 1

    (( now >= m )) || return 1
    printf '%s\n' "$(( now - m ))"

}
path::owner () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    sys::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%U' -- "${p}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Su' -- "${p}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::group () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    sys::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%G' -- "${p}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Sg' -- "${p}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::mode () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    sys::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%a' "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]{3,4}$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%p' "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v: -4}"; return 0; }

    return 1

}
path::inode () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    sys::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%i' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%i' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::tree () {

    local src="${1:-.}" max_depth="${2:-0}" prefix="${3:-}" name="" child="" total=0 i=0
    local -a items=()

    [[ -e "${src}" || -L "${src}" ]] || return 1

    name="${src##*/}"
    [[ -n "${name}" ]] || name="${src}"

    [[ -n "${prefix}" ]] || printf '%s\n' "${name}"
    [[ -d "${src}" && ! -L "${src}" ]] || return 0
    [[ "${max_depth}" != "0" && "${max_depth}" -le 1 ]] && return 0

    while IFS= read -r -d '' child; do
        items+=( "${child}" )
    done < <(find "${src}" -mindepth 1 -maxdepth 1 ! -name '.DS_Store' -print0 2>/dev/null | sort -z)

    total="${#items[@]}"

    for child in "${items[@]}"; do

        i=$(( i + 1 ))
        name="${child##*/}"

        if [[ "${i}" -eq "${total}" ]]; then

            printf '%s└── %s\n' "${prefix}" "${name}"

            if [[ -d "${child}" && ! -L "${child}" ]]; then

                if [[ "${max_depth}" == "0" ]]; then path::tree "${child}" "0" "${prefix}    "
                else path::tree "${child}" "$(( max_depth - 1 ))" "${prefix}    "
                fi

            fi

        else

            printf '%s├── %s\n' "${prefix}" "${name}"

            if [[ -d "${child}" && ! -L "${child}" ]]; then

                if [[ "${max_depth}" == "0" ]]; then path::tree "${child}" "0" "${prefix}│   "
                else path::tree "${child}" "$(( max_depth - 1 ))" "${prefix}│   "
                fi

            fi

        fi

    done

}

path::which () {

    local bin="${1:-}" v=""

    [[ -n "${bin}" ]] || return 1
    [[ "${bin}" != *$'\n'* && "${bin}" != *$'\r'* ]] || return 1

    v="$(command -v -- "${bin}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    return 1

}
path::which_all () {

    local bin="${1:-}" dir="" entry=""
    local -a dirs=()

    [[ -n "${bin}" ]] || return 1
    [[ "${bin}" != *$'\n'* && "${bin}" != *$'\r'* ]] || return 1

    IFS=":" read -r -a dirs <<< "${PATH:-}"

    for dir in "${dirs[@]}"; do

        [[ -n "${dir}" ]] || continue

        entry="${dir%/}/${bin}"
        [[ -f "${entry}" && -x "${entry}" ]] && printf '%s\n' "${entry}"

    done

}
path::root () {

    local p="${1:-}" head=""

    [[ -n "${p}" ]] || { printf '/'; return 0; }

    path::valid "${p}" || return 1
    p="${p//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]):(/?) ]]; then

        printf '%s:%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]:-/}"

    elif [[ "${p}" == //* ]]; then

        head="${p#//}"
        head="${head%%/*}"

        printf '//%s/' "${head}"

    elif [[ "${p}" == /* ]]; then

        printf '/'

    else

        return 1

    fi

}
path::script () {

    local p="${BASH_SOURCE[1]:-${BASH_SOURCE[0]:-$0}}" v=""

    [[ -n "${1:-}" ]] && p="${1}"
    [[ -n "${p}" ]] || return 1

    v="$(path::resolve "${p}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    path::abs "${p}"

}
path::script_dir () {

    local p="" v=""

    if [[ -n "${1:-}" ]]; then p="${1}"
    else p="${BASH_SOURCE[1]:-${BASH_SOURCE[0]:-$0}}"
    fi

    [[ -n "${p}" ]] || return 1

    v="$(path::resolve "${p}" 2>/dev/null || true)"
    [[ -n "${v}" ]] || v="$(path::abs "${p}")" || return 1

    path::dirname "${v}"

}

path::home_dir () {

    local v=""

    v="${HOME:-}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(sys::uhome 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    v="${USERPROFILE:-}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::tmp_dir () {

    local v=""

    for v in "${TMPDIR:-}" "${TMP:-}" "${TEMP:-}"; do

        if [[ -n "${v}" && -d "${v}" ]]; then
            printf '%s\n' "${v%/}"
            return 0
        fi

    done

    if sys::is_windows && [[ -n "${LOCALAPPDATA:-}" && -d "${LOCALAPPDATA}/Temp" ]]; then
        printf '%s\n' "${LOCALAPPDATA}/Temp"
        return 0
    fi

    [[ -d /tmp ]] && { printf '/tmp\n'; return 0; }
    [[ -d /var/tmp ]] && { printf '/var/tmp\n'; return 0; }

    v="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${v}" && -d "${v}" ]] && { printf '%s/.tmp\n' "${v%/}"; return 0; }

    return 1

}
path::config_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_CONFIG_HOME:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/.config\n' "${home%/}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        [[ -n "${home}" ]] && { printf '%s/Library/Application Support\n' "${home%/}"; return 0; }
        return 1

    fi
    if sys::is_windows; then

        v="${APPDATA:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/AppData/Roaming\n' "${home%/}"; return 0; }

        return 1

    fi

    [[ -n "${home}" ]] && { printf '%s/.config\n' "${home%/}"; return 0; }
    return 1

}
path::data_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_DATA_HOME:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/.local/share\n' "${home%/}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        [[ -n "${home}" ]] && { printf '%s/Library/Application Support\n' "${home%/}"; return 0; }
        return 1

    fi
    if sys::is_windows; then

        v="${LOCALAPPDATA:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/AppData/Local\n' "${home%/}"; return 0; }

        return 1

    fi

    [[ -n "${home}" ]] && { printf '%s/.local/share\n' "${home%/}"; return 0; }
    return 1

}
path::cache_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_CACHE_HOME:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/.cache\n' "${home%/}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        [[ -n "${home}" ]] && { printf '%s/Library/Caches\n' "${home%/}"; return 0; }
        return 1

    fi
    if sys::is_windows; then

        v="${LOCALAPPDATA:-}"

        [[ -n "${v}" ]] && { printf '%s/Cache\n' "${v%/}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/AppData/Local/Cache\n' "${home%/}"; return 0; }

        return 1

    fi

    [[ -n "${home}" ]] && { printf '%s/.cache\n' "${home%/}"; return 0; }
    return 1

}
path::state_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_STATE_HOME:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/.local/state\n' "${home%/}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        [[ -n "${home}" ]] && { printf '%s/Library/Application Support\n' "${home%/}"; return 0; }
        return 1

    fi
    if sys::is_windows; then

        v="${LOCALAPPDATA:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/AppData/Local\n' "${home%/}"; return 0; }

        return 1

    fi

    [[ -n "${home}" ]] && { printf '%s/.local/state\n' "${home%/}"; return 0; }
    return 1

}
path::runtime_dir () {

    local v=""

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_RUNTIME_DIR:-}"
        [[ -n "${v}" && -d "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    path::tmp_dir

}
path::log_dir () {

    local v="" home=""

    v="$(path::state_dir 2>/dev/null || true)"
    [[ -n "${v}" ]] || return 1

    if sys::is_linux || sys::is_wsl; then

        printf '%s/log\n' "${v%/}"

    elif sys::is_macos; then

        home="$(path::home_dir 2>/dev/null || true)"
        [[ -n "${home}" ]] || return 1

        printf '%s/Library/Logs\n' "${home%/}"

    else

        printf '%s/log\n' "${v%/}"

    fi

}
path::bin_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if sys::is_linux || sys::is_wsl; then

        printf '%s/.local/bin\n' "${home%/}"

    elif sys::is_macos; then

        printf '%s/.local/bin\n' "${home%/}"

    elif sys::is_windows; then

        v="${LOCALAPPDATA:-}"

        if [[ -n "${v}" ]]; then printf '%s/Programs/bin\n' "${v%/}"
        else printf '%s/AppData/Local/Programs/bin\n' "${home%/}"
        fi

    else

        printf '%s/.local/bin\n' "${home%/}"

    fi

}
path::desktop_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Desktop\n' "${home%/}"

}
path::downloads_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir DOWNLOAD 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Downloads\n' "${home%/}"

}
path::documents_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir DOCUMENTS 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Documents\n' "${home%/}"

}
path::pictures_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir PICTURES 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Pictures\n' "${home%/}"

}
path::music_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir MUSIC 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Music\n' "${home%/}"

}
path::videos_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir VIDEOS 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Videos\n' "${home%/}"

}
path::public_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir PUBLICSHARE 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    if sys::is_windows; then printf '%s/Public\n' "${PUBLIC:-${SystemDrive:-C:}/Users/Public}"
    else printf '%s/Public\n' "${home%/}"
    fi

}
path::templates_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir TEMPLATES 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Templates\n' "${home%/}"

}

path::touch () {

    local p="${1:-}" parent=""

    path::valid "${p}" || return 1

    parent="$(path::dirname "${p}")" || return 1
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if sys::has touch; then
        touch -- "${p}" 2>/dev/null
        return $?
    fi

    [[ -e "${p}" ]] && return 0
    : > "${p}" 2>/dev/null

}
path::mkdir () {

    local p="${1:-}" mode="${2:-}"

    path::valid "${p}" || return 1

    if [[ -d "${p}" && ! -L "${p}" ]]; then
        [[ -n "${mode}" ]] && { chmod "${mode}" "${p}" 2>/dev/null || return 1; }
        return 0
    fi

    [[ -e "${p}" || -L "${p}" ]] && return 1

    mkdir -p -- "${p}" 2>/dev/null || return 1
    [[ -n "${mode}" ]] && { chmod "${mode}" "${p}" 2>/dev/null || return 1; }

    return 0

}
path::mkparent () {

    local p="${1:-}" parent=""

    path::valid "${p}" || return 1

    parent="$(path::dirname "${p}")" || return 1
    [[ -n "${parent}" ]] || return 1
    [[ -d "${parent}" ]] && return 0

    mkdir -p -- "${parent}" 2>/dev/null

}
path::remove () {

    local p="${1:-}" resolved=""

    path::exists "${p}" || return 1
    path::is_root "${p}" && return 1

    resolved="$(path::resolve "${p}" 2>/dev/null || true)"
    [[ -n "${resolved}" ]] && path::is_root "${resolved}" && return 1

    if [[ -L "${p}" || -f "${p}" ]]; then
        rm -f -- "${p}" 2>/dev/null
        return $?
    fi
    if [[ -d "${p}" ]]; then
        rm -rf -- "${p}" 2>/dev/null
        return $?
    fi

    rm -f -- "${p}" 2>/dev/null

}
path::clear () {

    local p="${1:-}" entry="" name="" resolved=""

    path::exists "${p}" || return 1
    path::is_root "${p}" && return 1

    [[ -L "${p}" ]] && return 1

    resolved="$(path::resolve "${p}" 2>/dev/null || true)"
    [[ -n "${resolved}" ]] && path::is_root "${resolved}" && return 1

    if [[ -f "${p}" ]]; then
        : > "${p}" 2>/dev/null
        return $?
    fi

    [[ -d "${p}" ]] || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue
        name="${entry##*/}"
        [[ "${name}" == "." || "${name}" == ".." ]] && continue

        rm -rf -- "${entry}" 2>/dev/null || return 1

    done

    return 0

}
path::rename () {

    local from="${1:-}" to="${2:-}" parent=""

    path::exists "${from}" || return 1
    path::valid "${to}" || return 1
    sys::has mv || return 1

    parent="$(path::dirname "${to}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    mv -f -- "${from}" "${to}" 2>/dev/null

}
path::move () {

    path::rename "$@"

}
path::copy () {

    local from="${1:-}" to="${2:-}" parent=""

    path::exists "${from}" || return 1
    path::valid "${to}" || return 1
    sys::has cp || return 1

    parent="$(path::dirname "${to}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if [[ -d "${from}" && ! -L "${from}" ]]; then
        cp -a -- "${from}" "${to}" 2>/dev/null || cp -R -p -- "${from}" "${to}" 2>/dev/null
        return $?
    fi

    cp -P -p -f -- "${from}" "${to}" 2>/dev/null \
        || cp -p -f -- "${from}" "${to}" 2>/dev/null \
        || cp -f -- "${from}" "${to}" 2>/dev/null

}
path::link () {

    local from="${1:-}" to="${2:-}" parent=""

    path::exists "${from}" || return 1
    path::valid "${to}" || return 1
    sys::has ln || return 1

    parent="$(path::dirname "${to}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    ln -f -- "${from}" "${to}" 2>/dev/null

}
path::symlink () {

    local from="${1:-}" to="${2:-}" parent="" winfrom="" winto=""

    path::valid "${from}" || return 1
    path::valid "${to}" || return 1

    parent="$(path::dirname "${to}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if sys::has ln; then

        ln -sfn -- "${from}" "${to}" 2>/dev/null && return 0
        ln -sf -- "${from}" "${to}" 2>/dev/null && return 0

    fi
    if sys::is_windows && sys::has cmd.exe; then

        if sys::has cygpath; then
            winfrom="$(cygpath -aw -- "${from}" 2>/dev/null || printf '%s' "${from}")"
            winto="$(cygpath -aw -- "${to}" 2>/dev/null || printf '%s' "${to}")"
        else
            winfrom="$(path::windows "${from}")"
            winto="$(path::windows "${to}")"
        fi

        if [[ -d "${from}" ]]; then cmd.exe /C mklink /D "${winto}" "${winfrom}" >/dev/null 2>&1
        else cmd.exe /C mklink "${winto}" "${winfrom}" >/dev/null 2>&1
        fi

        return $?

    fi

    return 1

}
path::readlink () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    [[ -L "${p}" ]] || return 1

    if sys::has readlink; then

        v="$(readlink -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi
    if sys::has stat; then

        if stat -f '%Y' / >/dev/null 2>&1; then
            v="$(stat -f '%Y' -- "${p}" 2>/dev/null || true)"
            [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }
        fi

        v="$(stat -c '%N' -- "${p}" 2>/dev/null || true)"
        [[ "${v}" =~ ' -> '\'(.*)\'$ ]] && { printf '%s' "${BASH_REMATCH[1]}"; return 0; }

    fi

    return 1

}

path::chmod () {

    local p="${1:-}" mode="${2:-}"

    path::valid "${p}" || return 1
    sys::has chmod || return 1

    [[ -n "${mode}" ]] || return 1
    [[ -e "${p}" || -L "${p}" ]] || return 1

    case "${mode}" in
        [0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]|u+*|u-*|u=*|g+*|g-*|g=*|o+*|o-*|o=*|a+*|a-*|a=*|+*|-*)
            chmod -- "${mode}" "${p}" 2>/dev/null && return 0
            chmod "${mode}" "${p}" 2>/dev/null && return 0
        ;;
        *)
            return 1
        ;;
    esac

    return 1

}
path::temp_name () {

    local prefix="${1:-tmp}" suffix="${2:-}" dir="${3:-}" name="" p="" i=0

    [[ -n "${prefix}" || -n "${suffix}" || -z "${dir}" ]] || prefix="$(path::basename "${dir}" 2>/dev/null || true)"
    [[ -n "${dir}" ]] || dir="$(path::tmp_dir 2>/dev/null || true)"

    path::is_dir "${dir}" || return 1

    prefix="$(path::slugify "${prefix}" tmp 64 0)" || prefix="tmp"
    suffix="$(path::slugify "${suffix}" "" 64 0)" || suffix=""

    [[ -n "${prefix}" ]] || prefix="tmp"

    while (( i < 64 )); do

        name="${prefix}.$$.${RANDOM}${RANDOM}${RANDOM}${suffix}"
        p="${dir%/}/${name}"

        if [[ ! -e "${p}" && ! -L "${p}" ]]; then
            printf '%s' "${p}"
            return 0
        fi

        i=$(( i + 1 ))

    done

    return 1

}
path::mktemp_file () {

    local prefix="${1:-tmp}" suffix="${2:-}" dir="${3:-}" name="" v="" i=0

    [[ -n "${prefix}" || -n "${suffix}" || -z "${dir}" ]] || prefix="$(path::basename "${dir}" 2>/dev/null || true)"
    [[ -n "${dir}" ]] || dir="$(path::tmp_dir 2>/dev/null || true)"

    path::is_dir "${dir}" || return 1

    prefix="$(path::slugify "${prefix}" tmp 64 0)" || prefix="tmp"
    suffix="$(path::slugify "${suffix}" "" 64 0)" || suffix=""

    [[ -n "${prefix}" ]] || prefix="tmp"

    if sys::has mktemp; then

        if [[ -n "${suffix}" ]]; then

            v="$(mktemp --suffix="${suffix}" "${dir%/}/${prefix}.XXXXXXXX" 2>/dev/null || true)"
            [[ -n "${v}" && "${v}" == *"${suffix}" ]] && { printf '%s' "${v}"; return 0; }

        else

            v="$(mktemp "${dir%/}/${prefix}.XXXXXXXX" 2>/dev/null || true)"
            [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

            if [[ "${dir}" == "$(path::tmp_dir 2>/dev/null || true)" ]]; then
                v="$(mktemp -t "${prefix}.XXXXXXXX" 2>/dev/null || true)"
                [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }
            fi

        fi

    fi

    while (( i < 64 )); do

        name="${prefix}.$$.${RANDOM}${RANDOM}${RANDOM}${suffix}"
        v="${dir%/}/${name}"

        if ( set -C; : > "${v}" ) 2>/dev/null; then
            printf '%s' "${v}"
            return 0
        fi

        i=$(( i + 1 ))

    done

    return 1

}
path::mktemp_dir () {

    local prefix="${1:-tmp}" suffix="${2:-}" dir="${3:-}" name="" v="" i=0

    [[ -n "${prefix}" || -n "${suffix}" || -z "${dir}" ]] || prefix="$(path::basename "${dir}" 2>/dev/null || true)"
    [[ -n "${dir}" ]] || dir="$(path::tmp_dir 2>/dev/null || true)"

    path::is_dir "${dir}" || return 1

    prefix="$(path::slugify "${prefix}" tmp 64 0)" || prefix="tmp"
    suffix="$(path::slugify "${suffix}" "" 64 0)" || suffix=""

    [[ -n "${prefix}" ]] || prefix="tmp"

    if sys::has mktemp; then

        if [[ -n "${suffix}" ]]; then

            v="$(mktemp -d "${dir%/}/${prefix}.XXXXXXXX${suffix}" 2>/dev/null || true)"
            [[ -n "${v}" && -d "${v}" && "${v}" == *"${suffix}" ]] && { printf '%s' "${v}"; return 0; }

        else

            v="$(mktemp -d "${dir%/}/${prefix}.XXXXXXXX" 2>/dev/null || true)"
            [[ -n "${v}" && -d "${v}" ]] && { printf '%s' "${v}"; return 0; }

            if [[ "${dir}" == "$(path::tmp_dir 2>/dev/null || true)" ]]; then
                v="$(mktemp -d -t "${prefix}.XXXXXXXX" 2>/dev/null || true)"
                [[ -n "${v}" && -d "${v}" ]] && { printf '%s' "${v}"; return 0; }
            fi

        fi

    fi
    while (( i < 64 )); do

        name="${prefix}.$$.${RANDOM}${RANDOM}${RANDOM}${suffix}"
        v="${dir%/}/${name}"

        if mkdir -- "${v}" 2>/dev/null || mkdir "${v}" 2>/dev/null; then
            printf '%s' "${v}"
            return 0
        fi

        i=$(( i + 1 ))

    done

    return 1

}
path::mktemp_near () {

    local p="${1:-}" prefix="${2:-}" suffix="${3:-}" dir=""

    path::valid "${p}" || return 1
    dir="$(path::dirname "${p}")" || return 1

    if [[ -d "${p}" || "${p}" == */ ]]; then path::mktemp_dir "${prefix}" "${suffix}" "${dir}"
    else path::mktemp_file "${prefix}" "${suffix}" "${dir}"
    fi

}

path::sync () {

    local from="${1:-}" to="${2:-}" parent="" tmp="" old=""

    path::exists "${from}" || return 1
    path::valid "${to}" || return 1
    path::is_root "${to}" && return 1

    parent="$(path::dirname "${to}")" || return 1
    path::mkdir "${parent}" || return 1

    tmp="${parent%/}/.$(path::basename "${to}").tmp.$$"
    old="${parent%/}/.$(path::basename "${to}").old.$$"

    path::remove "${tmp}" 2>/dev/null || true

    path::copy "${from}" "${tmp}" || {
        path::remove "${tmp}" 2>/dev/null || true
        return 1
    }

    if path::exists "${to}"; then

        mv -- "${to}" "${old}" 2>/dev/null || {
            path::remove "${tmp}" 2>/dev/null || true
            return 1
        }

    fi
    if ! mv -- "${tmp}" "${to}" 2>/dev/null; then

        if [[ -e "${old}" || -L "${old}" ]]; then mv -- "${old}" "${to}" 2>/dev/null || true; fi
        path::remove "${tmp}" 2>/dev/null || true
        return 1

    fi

    path::remove "${old}" 2>/dev/null || true
    return 0

}
path::watch () {

    local p="${1:-}" interval="${2:-1}" callback="${3:-}" once="${4:-0}" on_error="${5:-abort}"
    local prev="" cur="" stat_kind="" _

    local -a recurse=()

    path::valid "${p}" || return 1

    [[ "${interval}" =~ ^[0-9]+([.][0-9]+)?$ ]] && [[ ! "${interval}" =~ ^0+([.]0+)?$ ]] || interval=1

    case "${once}" in
        1|true|yes|on|once) once=1 ;;
        *) once=0 ;;
    esac
    case "${on_error}" in
        abort|continue) ;;
        *) on_error="abort" ;;
    esac

    if sys::has inotifywait; then

        while :; do

            if [[ ! -e "${p}" && ! -L "${p}" ]]; then

                sleep "${interval}" 2>/dev/null || return 1
                continue

            fi

            recurse=()
            [[ -d "${p}" && ! -L "${p}" ]] && recurse=( -r )

            if (( once == 1 )); then

                inotifywait "${recurse[@]}" -q -e close_write,create,delete,move,attrib -- "${p}" >/dev/null 2>&1 || {
                    sleep "${interval}" 2>/dev/null || return 1
                    continue
                }

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || return 1
                else printf '%s\n' "${p}"
                fi

                return 0

            fi

            while IFS= read -r _; do

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || { [[ "${on_error}" == "continue" ]] || return 1; }
                else printf '%s\n' "${p}"
                fi

            done < <(inotifywait -m "${recurse[@]}" -q -e close_write,create,delete,move,attrib -- "${p}" 2>/dev/null)

            sleep "${interval}" 2>/dev/null || return 1

        done

    fi
    if sys::has fswatch; then

        while :; do

            if [[ ! -e "${p}" && ! -L "${p}" ]]; then

                sleep "${interval}" 2>/dev/null || return 1
                continue

            fi
            if (( once == 1 )); then

                fswatch -1 \
                    --event Created \
                    --event Updated \
                    --event Removed \
                    --event Renamed \
                    --event MovedFrom \
                    --event MovedTo \
                    --event AttributeModified \
                    -- "${p}" >/dev/null 2>&1 || {
                    sleep "${interval}" 2>/dev/null || return 1
                    continue
                }

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || return 1
                else printf '%s\n' "${p}"
                fi

                return 0

            fi

            while IFS= read -r _; do

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || { [[ "${on_error}" == "continue" ]] || return 1; }
                else printf '%s\n' "${p}"
                fi

            done < <(
                fswatch \
                    --event Created \
                    --event Updated \
                    --event Removed \
                    --event Renamed \
                    --event MovedFrom \
                    --event MovedTo \
                    --event AttributeModified \
                    -- "${p}" 2>/dev/null
            )

            sleep "${interval}" 2>/dev/null || return 1

        done

    fi
    if sys::has stat; then

        if stat -c '%s' -- /dev/null >/dev/null 2>&1; then stat_kind="gnu"
        elif stat -f '%z' -- /dev/null >/dev/null 2>&1; then stat_kind="bsd"
        else stat_kind=""
        fi

    fi

    while :; do

        if [[ -d "${p}" && ! -L "${p}" ]]; then

            if sys::has find && [[ "${stat_kind}" == "gnu" ]]; then

                cur="$(
                    {
                        stat -c '%n|%s|%Y|%F' -- "${p}" 2>/dev/null
                        find "${p}" -mindepth 1 -printf '%p|%s|%T@|%y\n' 2>/dev/null
                    } | LC_ALL=C sort 2>/dev/null
                )"

            elif sys::has find && [[ "${stat_kind}" == "bsd" ]]; then

                cur="$(
                    {
                        stat -f '%N|%z|%m|%HT' -- "${p}" 2>/dev/null
                        find "${p}" -mindepth 1 -print0 2>/dev/null |
                            xargs -0 stat -f '%N|%z|%m|%HT' 2>/dev/null
                    } | LC_ALL=C sort 2>/dev/null
                )"

            elif sys::has find; then

                cur="$(
                    {
                        printf '%s\n' "${p}"
                        find "${p}" -mindepth 1 -print 2>/dev/null
                    } | LC_ALL=C sort 2>/dev/null
                )"

            else

                cur="$(LC_ALL=C ls -laR "${p}" 2>/dev/null || true)"

            fi

        else

            if [[ -e "${p}" || -L "${p}" ]]; then

                case "${stat_kind}" in
                    gnu) cur="$(stat -c '%n|%s|%Y|%F' -- "${p}" 2>/dev/null || printf '%s\n' "${p}")" ;;
                    bsd) cur="$(stat -f '%N|%z|%m|%HT' -- "${p}" 2>/dev/null || printf '%s\n' "${p}")" ;;
                    *)   cur="$(LC_ALL=C ls -la "${p}" 2>/dev/null || printf '%s\n' "${p}")" ;;
                esac

            else
                cur="__missing__:${p}"
            fi

        fi

        if [[ "${cur}" != "${prev}" ]]; then

            if [[ -n "${prev}" ]]; then

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || { [[ "${on_error}" == "continue" ]] || return 1; }
                else printf '%s\n' "${p}"
                fi

                (( once == 1 )) && return 0

            fi

            prev="${cur}"

        fi

        sleep "${interval}" 2>/dev/null || return 1

    done

}

path::strip () {

    local target="${1:-}" n="${2:-1}" tmp_new="" tmp_old="" parent=""

    path::exists "${target}" || return 1
    path::is_dir "${target}" || return 1
    path::is_root "${target}" && return 1

    sys::has tar || return 1
    sys::has mktemp || return 1
    sys::has mv || return 1

    [[ "${n}" =~ ^[0-9]+$ ]] || return 1
    (( n > 0 )) || return 0

    target="${target%/}"
    parent="$(path::dirname "${target}")" || return 1

    tmp_new="$(mktemp -d -- "${parent%/}/.strip.new.XXXXXXXX" 2>/dev/null ||
        mktemp -d "${parent%/}/.strip.new.XXXXXXXX" 2>/dev/null)" ||
        return 1

    tmp_old="$(mktemp -d -- "${parent%/}/.strip.old.XXXXXXXX" 2>/dev/null ||
        mktemp -d "${parent%/}/.strip.old.XXXXXXXX" 2>/dev/null)" ||
        { rm -rf -- "${tmp_new}" 2>/dev/null; return 1; }

    rmdir -- "${tmp_old}" 2>/dev/null || { rm -rf -- "${tmp_new}" "${tmp_old}" 2>/dev/null; return 1; }

    if ! (
        set -o pipefail
        tar -C "${target}" -cf - . 2>/dev/null | tar -C "${tmp_new}" --strip-components="$(( n + 1 ))" -xpf - 2>/dev/null
    ); then
        rm -rf -- "${tmp_new}" "${tmp_old}" 2>/dev/null
        return 1
    fi

    if ! mv -- "${target}" "${tmp_old}" 2>/dev/null; then
        rm -rf -- "${tmp_new}" "${tmp_old}" 2>/dev/null
        return 1
    fi
    if ! mv -- "${tmp_new}" "${target}" 2>/dev/null; then
        mv -- "${tmp_old}" "${target}" 2>/dev/null
        rm -rf -- "${tmp_new}" "${tmp_old}" 2>/dev/null
        return 1
    fi

    rm -rf -- "${tmp_old}" 2>/dev/null
    return 0

}
path::archive () {

    local src="" archive_out="" format="" arg="" parent="" name="" out_parent="" pat="" lower=""

    local -a exclude=()
    local -a positional=()
    local -a args=()
    local -a fallback=()

    for arg in "$@"; do

        case "${arg}" in
            --exclude=*) exclude+=( "${arg#--exclude=}" ) ;;
            --format=*)  format="${arg#--format=}" ;;
            --) ;;
            -*) return 1 ;;
            *) positional+=( "${arg}" ) ;;
        esac

    done

    src="${positional[0]:-}"
    archive_out="${positional[1]:-}"

    path::exists "${src}" || return 1

    if [[ -n "${format}" ]]; then

        case "${format,,}" in
            zip|rar|7z|tar) format="${format,,}" ;;
            tgz|gz|tar.gz) format="tar.gz" ;;
            txz|xz|tar.xz) format="tar.xz" ;;
            tbz2|bz2|tar.bz2) format="tar.bz2" ;;
            tzst|zst|tar.zst) format="tar.zst" ;;
            *) return 1 ;;
        esac

    fi
    if [[ -z "${archive_out}" ]]; then

        [[ -n "${format}" ]] || format="tar.gz"
        archive_out="${src%/}.${format#.}"

    fi
    if [[ -n "${format}" ]]; then

        archive_out="${archive_out%.tar.zst}"
        archive_out="${archive_out%.tar.gz}"
        archive_out="${archive_out%.tar.xz}"
        archive_out="${archive_out%.tar.bz2}"
        archive_out="${archive_out%.tgz}"
        archive_out="${archive_out%.txz}"
        archive_out="${archive_out%.tbz2}"
        archive_out="${archive_out%.tzst}"
        archive_out="${archive_out%.tar}"
        archive_out="${archive_out%.zip}"
        archive_out="${archive_out%.rar}"
        archive_out="${archive_out%.7z}"
        archive_out="${archive_out}.${format#.}"

    fi

    path::valid "${archive_out}" || return 1

    case "${archive_out}" in
        /*|[A-Za-z]:*) ;;
        *) archive_out="${PWD}/${archive_out#./}" ;;
    esac

    parent="$(path::dirname "${src}")" || return 1
    name="$(path::basename "${src}")" || return 1
    out_parent="$(path::dirname "${archive_out}")" || return 1

    [[ -n "${parent}" && -n "${name}" ]] || return 1
    mkdir -p -- "${out_parent}" 2>/dev/null || mkdir -p "${out_parent}" 2>/dev/null || return 1

    lower="${archive_out,,}"

    case "${lower}" in
        *.tar.gz|*.tgz)

            sys::has tar || return 1
            args=( -czf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )
            tar "${args[@]}" 2>/dev/null

        ;;
        *.tar.bz2|*.tbz2)

            sys::has tar || return 1
            args=( -cjf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )
            tar "${args[@]}" 2>/dev/null

        ;;
        *.tar.xz|*.txz)

            sys::has tar || return 1
            args=( -cJf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )
            tar "${args[@]}" 2>/dev/null

        ;;
        *.tar.zst|*.tzst)

            sys::has tar || return 1

            args=( --zstd -cf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )

            tar "${args[@]}" 2>/dev/null && { printf '%s\n' "${archive_out}"; return 0; }

            sys::has zstd || return 1

            fallback=( -cf - )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && fallback+=( "--exclude=${pat}" )
            done

            fallback+=( -C "${parent}" "${name}" )

            (
                set -o pipefail
                tar "${fallback[@]}" 2>/dev/null | zstd -T0 -q -o "${archive_out}" >/dev/null 2>&1
            )

        ;;
        *.tar)

            sys::has tar || return 1
            args=( -cf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )
            tar "${args[@]}" 2>/dev/null

        ;;
        *.zip)

            if sys::has zip; then

                args=( -qr "${archive_out}" "${name}" )

                if (( ${#exclude[@]} > 0 )); then

                    args+=( -x )

                    for pat in "${exclude[@]}"; do
                        [[ -n "${pat}" ]] && args+=( "${pat}" )
                    done

                fi

                (
                    builtin cd -- "${parent}" 2>/dev/null || exit 1
                    zip "${args[@]}" >/dev/null 2>&1
                ) || return 1

                printf '%s\n' "${archive_out}"
                return 0

            fi
            if sys::has 7z; then

                args=( a -tzip -bd -y "${archive_out}" "${name}" )

                for pat in "${exclude[@]}"; do
                    [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
                done

                (
                    builtin cd -- "${parent}" 2>/dev/null || exit 1
                    7z "${args[@]}" >/dev/null 2>&1
                ) || return 1

                printf '%s\n' "${archive_out}"
                return 0

            fi

            return 1

        ;;
        *.rar)

            sys::has rar || return 1

            args=( a -idq -r )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "-x${pat}" )
            done

            args+=( "${archive_out}" "${name}" )

            (
                builtin cd -- "${parent}" 2>/dev/null || exit 1
                rar "${args[@]}" >/dev/null 2>&1
            )

        ;;
        *.7z)

            sys::has 7z || return 1

            args=( a -bd -y "${archive_out}" "${name}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
            done

            (
                builtin cd -- "${parent}" 2>/dev/null || exit 1
                7z "${args[@]}" >/dev/null 2>&1
            )

        ;;
        *)
            return 1
        ;;
    esac || return 1

    printf '%s\n' "${archive_out}"

}
path::extract () {

    local archive="" to="" strip=0 arg="" base="" parent="" pat="" lower=""

    local -a exclude=()
    local -a positional=()
    local -a args=()
    local -a fallback=()

    for arg in "$@"; do

        case "${arg}" in
            --exclude=*) exclude+=( "${arg#--exclude=}" ) ;;
            --strip=*)   strip="${arg#--strip=}" ;;
            --) ;;
            -*) return 1 ;;
            *) positional+=( "${arg}" ) ;;
        esac

    done

    archive="${positional[0]:-}"
    to="${positional[1]:-}"

    [[ -n "${archive}" && -f "${archive}" ]] || return 1
    [[ "${strip}" =~ ^[0-9]+$ ]] || return 1

    if [[ -z "${to}" ]]; then

        base="$(path::basename "${archive}")" || return 1

        case "${base,,}" in
            *.tar.gz|*.tar.bz2|*.tar.xz|*.tar.zst)
                base="${base%.*}"
                base="${base%.*}"
            ;;
            *.tgz|*.tbz2|*.txz|*.tzst|*.tar|*.zip|*.rar|*.7z)
                base="${base%.*}"
            ;;
        esac

        parent="$(path::dirname "${archive}")" || return 1

        if [[ "${parent}" == "." ]]; then to="${base}"
        else to="${parent}/${base}"
        fi

    fi

    path::valid "${to}" || return 1
    mkdir -p -- "${to}" 2>/dev/null || mkdir -p "${to}" 2>/dev/null || return 1

    lower="${archive,,}"

    case "${lower}" in
        *.tar.gz|*.tgz)

            sys::has tar || return 1
            args=( -xzf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null

        ;;
        *.tar.bz2|*.tbz2)

            sys::has tar || return 1
            args=( -xjf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null

        ;;
        *.tar.xz|*.txz)

            sys::has tar || return 1
            args=( -xJf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null

        ;;
        *.tar.zst|*.tzst)

            sys::has tar || return 1
            args=( --zstd -xf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null && { printf '%s\n' "${to}"; return 0; }

            sys::has zstd || return 1
            fallback=( -xf - )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && fallback+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && fallback+=( "--strip-components=${strip}" )

            (
                set -o pipefail
                zstd -dc -- "${archive}" 2>/dev/null | tar "${fallback[@]}" -C "${to}" 2>/dev/null
            )

        ;;
        *.tar)

            sys::has tar || return 1
            args=( -xf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null

        ;;
        *.zip)

            if sys::has unzip; then

                args=( -qo "${archive}" -d "${to}" )

                if (( ${#exclude[@]} > 0 )); then

                    args+=( -x )

                    for pat in "${exclude[@]}"; do
                        [[ -n "${pat}" ]] && args+=( "${pat}" )
                    done

                fi

                unzip "${args[@]}" 2>/dev/null || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi
            if sys::has 7z; then

                args=( x -bd -y "-o${to}" "${archive}" )

                for pat in "${exclude[@]}"; do
                    [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
                done

                7z "${args[@]}" >/dev/null 2>&1 || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi
            if sys::has bsdtar; then

                bsdtar -xf "${archive}" -C "${to}" 2>/dev/null || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi

            return 1

        ;;
        *.rar)

            if sys::has unrar; then

                args=( x -idq -y )

                for pat in "${exclude[@]}"; do
                    [[ -n "${pat}" ]] && args+=( "-x${pat}" )
                done

                args+=( "${archive}" "${to}/" )

                unrar "${args[@]}" >/dev/null 2>&1 || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi
            if sys::has 7z; then

                args=( x -bd -y "-o${to}" "${archive}" )

                for pat in "${exclude[@]}"; do
                    [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
                done

                7z "${args[@]}" >/dev/null 2>&1 || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi

            return 1

        ;;
        *.7z)

            sys::has 7z || return 1
            args=( x -bd -y "-o${to}" "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
            done

            7z "${args[@]}" >/dev/null 2>&1 || return 1
            (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

            printf '%s\n' "${to}";
            return 0

        ;;
        *)
            return 1
        ;;
    esac || return 1

    printf '%s\n' "${to}"

}
path::backup () {

    local src="${1:-}" backup_out="" stamp="" name=""

    path::exists "${src}" || return 1
    shift || true

    if (( $# > 0 )) && [[ "${1:-}" != --* ]]; then
        backup_out="${1:-}"
        shift || true
    fi

    stamp="$(date +%Y%m%d-%H%M%S 2>/dev/null)" || return 1
    name="$(path::basename "${src}")" || return 1

    [[ -n "${backup_out}" ]] || backup_out="${name}.backup.${stamp}.tar.gz"
    path::archive "${src}" "${backup_out}" "$@"

}

path::hash () {

    local p="${1:-}" algo="${2:-sha256}" item="" rel="" type="" sum="" target="" cmd=""
    local -a rows=()

    path::exists "${p}" || return 1

    case "${algo}" in
        sha256|"")
            if sys::has sha256sum; then cmd="sha256sum"
            elif sys::has shasum; then cmd="shasum -a 256"
            else return 1
            fi
        ;;
        sha1)
            if sys::has sha1sum; then cmd="sha1sum"
            elif sys::has shasum; then cmd="shasum -a 1"
            else return 1
            fi
        ;;
        md5)
            if sys::has md5sum; then cmd="md5sum"
            elif sys::has md5; then cmd="md5 -q"
            else return 1
            fi
        ;;
        *)
            return 1
        ;;
    esac

    if [[ -f "${p}" && ! -L "${p}" ]]; then

        if [[ "${cmd}" == "md5 -q" ]]; then
            md5 -q "${p}" 2>/dev/null
        else
            ${cmd} -- "${p}" 2>/dev/null | awk '{print $1}' ||
            ${cmd} "${p}" 2>/dev/null | awk '{print $1}'
        fi

        return

    fi
    if [[ -L "${p}" ]]; then

        target="$(path::readlink "${p}" 2>/dev/null || true)"

        printf 'link\t%s\t%s\n' "${target}" "${p}" | {

            if [[ "${cmd}" == "md5 -q" ]]; then md5 -q 2>/dev/null
            else ${cmd} 2>/dev/null | awk '{print $1}'
            fi

        }

        return

    fi

    [[ -d "${p}" ]] || return 1
    sys::has find || return 1

    while IFS= read -r item; do

        rel="${item#"${p%/}/"}"
        type="$(path::type "${item}" 2>/dev/null || printf other)"

        case "${type}" in
            file)
                if [[ "${cmd}" == "md5 -q" ]]; then sum="$(md5 -q "${item}" 2>/dev/null || true)"
                else sum="$(${cmd} -- "${item}" 2>/dev/null | awk '{print $1}' || ${cmd} "${item}" 2>/dev/null | awk '{print $1}' || true)"
                fi

                [[ -n "${sum}" ]] || return 1
                rows+=( "file	${sum}	${rel}" )
            ;;
            link)
                target="$(path::readlink "${item}" 2>/dev/null || true)"
                rows+=( "link	${target}	${rel}" )
            ;;
            dir)
                rows+=( "dir	-	${rel}" )
            ;;
            *)
                rows+=( "${type}	-	${rel}" )
            ;;
        esac

    done < <(find "${p}" -mindepth 1 2>/dev/null)

    printf '%s\n' "${rows[@]}" | LC_ALL=C sort | {

        if [[ "${cmd}" == "md5 -q" ]]; then md5 -q 2>/dev/null
        else ${cmd} 2>/dev/null | awk '{print $1}'
        fi

    }

}
path::checksum () {

    local p="${1:-}" expected="${2:-}" algo="${3:-sha256}" actual=""

    [[ -n "${expected}" ]] || return 1

    actual="$(path::hash "${p}" "${algo}")" || return 1
    [[ "${actual}" == "${expected}" ]]

}
path::snapshot () {

    local p="${1:-}" item="" rel="" type="" size="" mtime="" mode="" target=""

    path::exists "${p}" || return 1

    if [[ -L "${p}" ]]; then

        target="$(path::readlink "${p}" 2>/dev/null || true)"
        printf 'link\t-\t-\t-\t%s\t%s\n' "${target}" "${p}"
        return 0

    fi
    if [[ -f "${p}" ]]; then

        size="$(path::size "${p}" 2>/dev/null || printf 0)"
        mtime="$(path::mtime "${p}" 2>/dev/null || printf 0)"
        mode="$(path::mode "${p}" 2>/dev/null || printf 0)"

        printf 'file\t%s\t%s\t%s\t-\t%s\n' "${size}" "${mtime}" "${mode}" "${p}"
        return 0

    fi

    [[ -d "${p}" ]] || return 1
    sys::has find || return 1

    while IFS= read -r item; do

        rel="${item#"${p%/}/"}"
        type="$(path::type "${item}" 2>/dev/null || printf other)"

        case "${type}" in
            file)
                size="$(path::size "${item}" 2>/dev/null || printf 0)"
                mtime="$(path::mtime "${item}" 2>/dev/null || printf 0)"
                mode="$(path::mode "${item}" 2>/dev/null || printf 0)"
                target="-"
            ;;
            dir)
                size="-"
                mtime="$(path::mtime "${item}" 2>/dev/null || printf 0)"
                mode="$(path::mode "${item}" 2>/dev/null || printf 0)"
                target="-"
            ;;
            link)
                size="-"
                mtime="-"
                mode="-"
                target="$(path::readlink "${item}" 2>/dev/null || true)"
            ;;
            *)
                size="$(path::size "${item}" 2>/dev/null || printf 0)"
                mtime="$(path::mtime "${item}" 2>/dev/null || printf 0)"
                mode="$(path::mode "${item}" 2>/dev/null || printf 0)"
                target="-"
            ;;
        esac

        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${type}" "${size}" "${mtime}" "${mode}" "${target}" "${rel}"

    done < <(find "${p}" -mindepth 1 2>/dev/null | LC_ALL=C sort)

}

path::encode_caps () {

    local help=""
    local -n __wrap_out="${1:-_BASE64_WRAP}"
    local -n __flag_out="${2:-_BASE64_FLAG}"
    local -n __input_out="${3:-_BASE64_INPUT}"

    if [[ -n "${_BASE64_WRAP:-}" && -n "${_BASE64_FLAG:-}" && -n "${_BASE64_INPUT+x}" ]]; then
        __wrap_out="${_BASE64_WRAP}"
        __flag_out="${_BASE64_FLAG}"
        __input_out="${_BASE64_INPUT}"
        return 0
    fi

    sys::has base64 || return 2
    help="$( base64 --help 2>&1 )"

    case "${help}" in
        *" -w"*) __wrap_out="1" ;;
        *)       __wrap_out="0" ;;
    esac
    case "${help}" in
        *" -d"*) __flag_out="-d" ;;
        *)       __flag_out="-D" ;;
    esac
    case "${help}" in
        *" -i "*) __input_out="-i" ;;
        *"--input"*) __input_out="-i" ;;
        *) __input_out="" ;;
    esac

    _BASE64_WRAP="${__wrap_out}"
    _BASE64_FLAG="${__flag_out}"
    _BASE64_INPUT="${__input_out}"

    return 0

}
path::encode () {

    local src="${1:-}" output="${2:-}" file="" rel="" dst="" dir="" status=0 wrap="" flag="" input=""
    local -A mkdir_cache=()

    [[ -n "${src}" && -e "${src}" ]] || return 1
    [[ ! -L "${src}" ]] || return 3

    path::encode_caps wrap flag input || return 2

    if [[ -d "${src}" ]]; then

        [[ -n "${output}" ]] && { mkdir -p "${output}" || return 1; }

        while IFS= read -r -d '' file; do

            rel="${file#"${src%/}/"}"

            if [[ -n "${output}" ]]; then

                dst="${output%/}/${rel}"
                dir="$( dirname "${dst}" )"

                if [[ -z "${mkdir_cache[${dir}]:-}" ]]; then
                    mkdir -p "${dir}" || { status=1; continue; }
                    mkdir_cache["${dir}"]=1
                fi

                path::encode "${file}" "${dst}" || status=1

            else

                printf '==> %s\n' "${rel}" >&2
                path::encode "${file}" || status=1
                printf '\n' >&2

            fi

        done < <( find "${src}" -type f ! -name '.b64.*' -print0 )

        return "${status}"

    fi
    if [[ ! -f "${src}" ]]; then
        return 1
    fi
    if [[ -n "${output}" ]]; then

        dir="$( dirname "${output}" )"
        mkdir -p "${dir}" || return 1

        (

            local tmp=""

            tmp="$( mktemp "${dir}/.b64.encode.XXXXXX" )" || exit 1
            trap 'rm -f "${tmp}"' INT TERM HUP EXIT

            if [[ "${wrap}" == "1" ]]; then
                base64 -w 0 "${src}" > "${tmp}" || exit 1
            else
                if [[ -n "${input}" ]]; then base64 "${input}" "${src}" | tr -d '\n' > "${tmp}" || exit 1
                else base64 "${src}" | tr -d '\n' > "${tmp}" || exit 1
                fi
            fi

            mv -f "${tmp}" "${output}" || exit 1
            trap - INT TERM HUP EXIT

            exit 0

        )

        return $?

    fi

    if [[ "${wrap}" == "1" ]]; then
        base64 -w 0 "${src}"
    else
        if [[ -n "${input}" ]]; then base64 "${input}" "${src}" | tr -d '\n'
        else base64 "${src}" | tr -d '\n'
        fi
    fi

}
path::decode () {

    local src="${1:-}" output="${2:-}" file="" rel="" dst="" dir="" status=0 wrap="" flag="" input=""
    local -A mkdir_cache=()

    [[ -n "${src}" && -e "${src}" ]] || return 1
    [[ ! -L "${src}" ]] || return 3

    path::encode_caps wrap flag input || return 2

    if [[ -d "${src}" ]]; then

        [[ -n "${output}" ]] && { mkdir -p "${output}" || return 1; }

        while IFS= read -r -d '' file; do

            rel="${file#"${src%/}/"}"

            if [[ -n "${output}" ]]; then

                dst="${output%/}/${rel}"
                dir="$( dirname "${dst}" )"

                if [[ -z "${mkdir_cache[${dir}]:-}" ]]; then
                    mkdir -p "${dir}" || { status=1; continue; }
                    mkdir_cache["${dir}"]=1
                fi

                path::decode "${file}" "${dst}" || status=1

            else

                printf '==> %s\n' "${rel}" >&2
                path::decode "${file}" || status=1
                printf '\n' >&2

            fi

        done < <( find "${src}" -type f ! -name '.b64.*' -print0 )

        return "${status}"

    fi
    if [[ ! -f "${src}" ]]; then
        return 1
    fi
    if [[ -n "${output}" ]]; then

        dir="$( dirname "${output}" )"
        mkdir -p "${dir}" || return 1

        (

            local tmp=""

            tmp="$( mktemp "${dir}/.b64.decode.XXXXXX" )" || exit 1
            trap 'rm -f "${tmp}"' INT TERM HUP EXIT

            if [[ -n "${input}" ]]; then base64 "${flag}" "${input}" "${src}" > "${tmp}" || exit 1
            else base64 "${flag}" "${src}" > "${tmp}" || exit 1
            fi

            [[ -s "${src}" && ! -s "${tmp}" ]] && exit 1

            mv -f "${tmp}" "${output}" || exit 1
            trap - INT TERM HUP EXIT

            exit 0

        )

        return $?

    fi

    if [[ -n "${input}" ]]; then base64 "${flag}" "${input}" "${src}"
    else base64 "${flag}" "${src}"
    fi

}

path::encrypt_engine () {

    local src="${1:-}" probe="" engine_line=""
    local -n __encrypt_out="${2:-_ENCRYPT_ENGINE}"

    __encrypt_out=""
    [[ -n "${src}" && -f "${src}" ]] || return 1

    LC_ALL=C IFS= read -r -N 64 probe < "${src}" 2>/dev/null || true
    [[ "${probe}" == ENCRYPT1$'\n'engine:*$'\n'* ]] || return 1

    engine_line="${probe#ENCRYPT1$'\n'}"
    engine_line="${engine_line%%$'\n'*}"
    engine_line="${engine_line%$'\r'}"

    case "${engine_line}" in
        engine:gpg|engine:openssl)
            __encrypt_out="${engine_line#engine:}"
            return 0
        ;;
        engine:*)
            return 2
        ;;
    esac

    return 1

}
path::encrypt () {

    local src="${1:-}" pass="${2:-${ENCRYPT_PASS:-}}" engine="${3:-${ENCRYPT_ENGINE:-auto}}"
    local file="" found="" selected="" status=0 probe_status=0
    local -a engines=()

    [[ -n "${src}" && -e "${src}" ]] || return 1
    [[ -n "${pass}" ]] || return 2
    [[ ! -L "${src}" ]] || return 3

    case "${engine,,}" in
        ""|auto) engines=( gpg openssl ) ;;
        gpg|openssl) engines=( "${engine,,}" ) ;;
        *) return 4 ;;
    esac
    for selected in "${engines[@]}"; do
        sys::has "${selected}" && break
        selected=""
    done

    if [[ -z "${selected}" ]]; then
        return 5
    fi
    if [[ -d "${src}" ]]; then

        while IFS= read -r -d '' file; do
            path::encrypt "${file}" "${pass}" "${selected}" || status=1
        done < <(find "${src}" -type f ! -name '.encrypt.*' -print0)

        return "${status}"

    fi
    if [[ ! -f "${src}" ]]; then
        return 1
    fi

    path::encrypt_engine "${src}" found
    probe_status=$?

    case "${probe_status}" in
        0) return 0 ;;
        1) ;;
        2) return 12 ;;
        *) return 11 ;;
    esac

    (

        local dir="" tmp_payload="" tmp_final="" tmp_plain=""
        local mode="" owner="" group="" links="" hash_a="" hash_b="" header=""
        local verify="${ENCRYPT_VERIFY:-1}"

        links="$(stat -c '%h' "${src}" 2>/dev/null || stat -f '%l' "${src}" 2>/dev/null || true)"
        [[ -n "${links}" && "${links}" -gt 1 ]] && exit 6

        mode="$(stat -c '%a' "${src}" 2>/dev/null || stat -f '%Lp' "${src}" 2>/dev/null || true)"
        owner="$(stat -c '%u' "${src}" 2>/dev/null || stat -f '%u' "${src}" 2>/dev/null || true)"
        group="$(stat -c '%g' "${src}" 2>/dev/null || stat -f '%g' "${src}" 2>/dev/null || true)"

        dir="$(dirname "${src}")"

        tmp_payload="$(mktemp "${dir}/.encrypt.payload.XXXXXX")" || exit 1
        tmp_final="$(mktemp "${dir}/.encrypt.final.XXXXXX")" || exit 1
        tmp_plain="$(mktemp "${dir}/.encrypt.verify.XXXXXX")" || exit 1

        trap 'rm -f "${tmp_payload}" "${tmp_final}" "${tmp_plain}"' INT TERM HUP EXIT

        case "${selected}" in
            gpg)
                printf '%s' "${pass}" | gpg --batch --yes --quiet \
                    --symmetric \
                    --cipher-algo AES256 \
                    --pinentry-mode loopback \
                    --passphrase-fd 0 \
                    --output "${tmp_payload}" \
                    "${src}" >/dev/null 2>&1 || exit 7
            ;;
            openssl)
                printf '%s\n' "${pass}" | openssl enc -aes-256-cbc \
                    -salt \
                    -pbkdf2 \
                    -iter 300000 \
                    -md sha256 \
                    -in "${src}" \
                    -out "${tmp_payload}" \
                    -pass stdin >/dev/null 2>&1 || exit 7
            ;;
        esac

        [[ -s "${tmp_payload}" ]] || exit 7

        if [[ "${verify}" == "1" || "${verify}" == "true" ]]; then

            case "${selected}" in
                gpg)
                    printf '%s' "${pass}" | gpg --batch --yes --quiet \
                        --decrypt \
                        --pinentry-mode loopback \
                        --passphrase-fd 0 \
                        --output "${tmp_plain}" \
                        "${tmp_payload}" >/dev/null 2>&1 || exit 9
                ;;
                openssl)
                    printf '%s\n' "${pass}" | openssl enc -d -aes-256-cbc \
                        -pbkdf2 \
                        -iter 300000 \
                        -md sha256 \
                        -in "${tmp_payload}" \
                        -out "${tmp_plain}" \
                        -pass stdin >/dev/null 2>&1 || exit 9
                ;;
            esac

            if sys::has sha256sum; then

                hash_a="$(sha256sum "${src}" | awk '{print $1}')"
                hash_b="$(sha256sum "${tmp_plain}" | awk '{print $1}')"

                [[ "${hash_a}" == "${hash_b}" ]] || exit 9

            elif sys::has shasum; then

                hash_a="$(shasum -a 256 "${src}" | awk '{print $1}')"
                hash_b="$(shasum -a 256 "${tmp_plain}" | awk '{print $1}')"

                [[ "${hash_a}" == "${hash_b}" ]] || exit 9

            else

                cmp -s "${src}" "${tmp_plain}" || exit 9

            fi

        fi

        header=$'ENCRYPT1\nengine:'"${selected}"$'\n\n'

        printf '%s' "${header}" > "${tmp_final}" || exit 8
        cat "${tmp_payload}" >> "${tmp_final}" || exit 8

        [[ -n "${mode}" ]] && { chmod "${mode}" "${tmp_final}" 2>/dev/null || true; }
        [[ -n "${owner}" && -n "${group}" ]] && { chown "${owner}:${group}" "${tmp_final}" 2>/dev/null || true; }

        mv -f "${tmp_final}" "${src}" || exit 10

        trap - INT TERM HUP EXIT
        rm -f "${tmp_payload}" "${tmp_plain}"

        exit 0

    )

}
path::decrypt () {

    local src="${1:-}" pass="${2:-${ENCRYPT_PASS:-}}" engine="${3:-auto}"
    local force="${4:-${DECRYPT_FORCE:-0}}" fallback_engine="${ENCRYPT_ENGINE:-openssl}"
    local _engine_probe="" file="" status=0 probe_status=0

    [[ -n "${src}" && -e "${src}" ]] || return 1
    [[ -n "${pass}" ]] || return 2
    [[ ! -L "${src}" ]] || return 3

    case "${engine,,}" in
        auto|gpg|openssl) engine="${engine,,}";;
        *) return 4 ;;
    esac
    case "${force,,}" in
        1|true|yes|y|on|-f|--force|-y|--yes) force="1" ;;
        *) force="0" ;;
    esac

    if [[ -d "${src}" ]]; then

        while IFS= read -r -d '' file; do

            if [[ "${force}" != "1" ]]; then

                path::encrypt_engine "${file}" _engine_probe
                probe_status=$?

                case "${probe_status}" in
                    0) ;;
                    1) continue ;;
                    *) status=1; continue ;;
                esac

            fi

            path::decrypt "${file}" "${pass}" "${engine}" "${force}" || status=1

        done < <(find "${src}" -type f ! -name '.encrypt.*' -print0)

        return "${status}"

    fi
    if [[ ! -f "${src}" ]]; then
        return 1
    fi

    (

        local dir="" tmp_plain="" tmp_cipher="" cipher_src="" mode="" owner="" group="" links=""
        local header="" header_len="" found="" probe_status=0

        path::encrypt_engine "${src}" found
        probe_status=$?

        case "${probe_status}" in
            0) [[ "${engine}" != "auto" && -n "${engine}" && "${engine}" != "${found}" ]] && exit 13 ;;
            1)
                [[ "${force}" == "1" ]] || exit 11
                if [[ "${engine}" != "auto" && -n "${engine}" ]]; then found="${engine}"
                elif [[ -n "${fallback_engine}" ]]; then found="${fallback_engine}"
                else exit 16
                fi
            ;;
            2) exit 12 ;;
            *) exit 11 ;;
        esac
        case "${found}" in
            gpg|openssl) ;;
            *) exit 4 ;;
        esac

        sys::has "${found}" || exit 5

        links="$(stat -c '%h' "${src}" 2>/dev/null || stat -f '%l' "${src}" 2>/dev/null || true)"
        [[ -n "${links}" && "${links}" -gt 1 ]] && exit 6

        mode="$(stat -c '%a' "${src}" 2>/dev/null || stat -f '%Lp' "${src}" 2>/dev/null || true)"
        owner="$(stat -c '%u' "${src}" 2>/dev/null || stat -f '%u' "${src}" 2>/dev/null || true)"
        group="$(stat -c '%g' "${src}" 2>/dev/null || stat -f '%g' "${src}" 2>/dev/null || true)"

        dir="$(dirname "${src}")"
        tmp_plain="$(mktemp "${dir}/.encrypt.plain.XXXXXX")" || exit 1
        tmp_cipher="$(mktemp "${dir}/.encrypt.cipher.XXXXXX")" || exit 1

        trap 'rm -f "${tmp_plain}" "${tmp_cipher}"' INT TERM HUP EXIT

        if [[ "${probe_status}" -eq 0 ]]; then

            header=$'ENCRYPT1\nengine:'"${found}"$'\n\n'
            header_len="${#header}"

            tail -c +"$(( header_len + 1 ))" "${src}" > "${tmp_cipher}" 2>/dev/null || exit 8
            cipher_src="${tmp_cipher}"

        else
            cipher_src="${src}"
        fi

        case "${found}" in
            gpg)
                printf '%s' "${pass}" | gpg --batch --yes --quiet \
                    --decrypt \
                    --pinentry-mode loopback \
                    --passphrase-fd 0 \
                    --output "${tmp_plain}" \
                    "${cipher_src}" >/dev/null 2>&1 || exit 14
            ;;
            openssl)
                printf '%s\n' "${pass}" | openssl enc -d -aes-256-cbc \
                    -pbkdf2 \
                    -iter 300000 \
                    -md sha256 \
                    -in "${cipher_src}" \
                    -out "${tmp_plain}" \
                    -pass stdin >/dev/null 2>&1 || exit 14
            ;;
        esac

        [[ -f "${tmp_plain}" ]] || exit 14

        [[ -n "${mode}" ]] && { chmod "${mode}" "${tmp_plain}" 2>/dev/null || true; }
        [[ -n "${owner}" && -n "${group}" ]] && { chown "${owner}:${group}" "${tmp_plain}" 2>/dev/null || true; }

        mv -f "${tmp_plain}" "${src}" || exit 10

        trap - INT TERM HUP EXIT
        rm -f "${tmp_cipher}"

        exit 0

    )

}

path::trylock () {

    local lock="${1:-}" stale="${2:-0}" parent="" pidfile="" pid="" now="" mtime="" self=""

    self="${BASHPID:-$$}"

    path::valid "${lock}" || return 1
    path::is_root "${lock}" && return 1

    parent="$(path::dirname "${lock}")" || return 1
    mkdir -p -- "${parent}" 2>/dev/null || mkdir -p "${parent}" 2>/dev/null || return 1

    pidfile="${lock%/}/pid"

    if mkdir -- "${lock}" 2>/dev/null; then

        ( printf '%s\n' "${self}" > "${pidfile}" ) 2>/dev/null && return 0
        rm -rf -- "${lock}" 2>/dev/null || true
        return 1

    fi

    [[ "${stale}" =~ ^[0-9]+$ ]] || stale=0
    (( stale > 0 )) || return 1

    if [[ -f "${pidfile}" ]]; then

        pid="$(cat "${pidfile}" 2>/dev/null || true)"

        if [[ "${pid}" =~ ^[0-9]+$ ]]; then kill -0 "${pid}" 2>/dev/null && return 1
        else return 1
        fi

    fi

    mtime="$(path::mtime "${lock}" 2>/dev/null || printf 0)"
    now="$(date +%s 2>/dev/null || printf 0)"

    [[ "${mtime}" =~ ^[0-9]+$ && "${now}" =~ ^[0-9]+$ ]] || return 1
    (( now - mtime >= stale )) || return 1

    rm -rf -- "${lock}" 2>/dev/null || return 1

    if mkdir -- "${lock}" 2>/dev/null; then

        ( printf '%s\n' "${self}" > "${pidfile}" ) 2>/dev/null && return 0
        rm -rf -- "${lock}" 2>/dev/null || true
        return 1

    fi

    return 1

}
path::lock () {

    local lock="${1:-}" timeout="${2:-30}" sleep_for="${3:-0.1}" stale="${4:-0}" start="" now=""

    path::valid "${lock}" || return 1
    [[ "${timeout}" =~ ^[0-9]+$ ]] || return 1

    start="$(date +%s 2>/dev/null || printf 0)"

    while true; do

        path::trylock "${lock}" "${stale}" && return 0

        now="$(date +%s 2>/dev/null || printf 0)"
        (( timeout == 0 )) && return 1
        (( now - start >= timeout )) && return 1

        sleep "${sleep_for}" 2>/dev/null || sleep 1

    done

}
path::unlock () {

    local lock="${1:-}" pidfile="" pid="" self=""

    self="${BASHPID:-$$}"

    path::valid "${lock}" || return 1
    path::is_root "${lock}" && return 1

    [[ -d "${lock}" ]] || return 0

    pidfile="${lock%/}/pid"
    [[ -f "${pidfile}" ]] || return 1

    pid="$(cat "${pidfile}" 2>/dev/null || true)"
    [[ "${pid}" == "${self}" ]] || return 1

    rm -rf -- "${lock}" 2>/dev/null

}
path::locked () {

    local lock="${1:-}" pidfile="" pid=""

    path::valid "${lock}" || return 1
    [[ -d "${lock}" ]] || return 1

    pidfile="${lock%/}/pid"
    [[ -f "${pidfile}" ]] || return 0

    pid="$(cat "${pidfile}" 2>/dev/null || true)"
    [[ "${pid}" =~ ^[0-9]+$ ]] || return 0

    kill -0 "${pid}" 2>/dev/null

}
path::with_lock () {

    local lock="${1:-}" callback="${2:-}" timeout="${3:-30}" sleep_for="${4:-0.1}" stale="${5:-0}" code=0

    path::valid "${lock}" || return 1

    [[ -n "${callback}" ]] || return 1
    declare -F "${callback}" >/dev/null 2>&1 || return 1

    (( $# >= 5 )) || return 1
    shift 5
    path::lock "${lock}" "${timeout}" "${sleep_for}" "${stale}" || return 1

    "${callback}" "$@"
    code=$?

    path::unlock "${lock}" || true
    return "${code}"

}
