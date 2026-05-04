
tool::init () {

    [[ "${__TOOL_REGISTRY_INIT:-0}" == "1" ]] && return 0

    declare -gA __TOOL_REGISTRY_BIN=()
    declare -gA __TOOL_REGISTRY_PACKAGE=()
    declare -gA __TOOL_REGISTRY_VERSION=()
    declare -gA __TOOL_REGISTRY_PATH=()
    declare -gA __TOOL_REGISTRY_SOURCE=()
    declare -gA __TOOL_REGISTRY_METHOD=()
    declare -gA __TOOL_REGISTRY_CHECKSUM=()
    declare -gA __TOOL_REGISTRY_COMMAND=()
    declare -gA __TOOL_REGISTRY_CALLBACK=()
    declare -g  __TOOL_REGISTRY_INIT=1

}
tool::reset () {

    tool::init

    __TOOL_REGISTRY_BIN=()
    __TOOL_REGISTRY_PACKAGE=()
    __TOOL_REGISTRY_VERSION=()
    __TOOL_REGISTRY_PATH=()
    __TOOL_REGISTRY_SOURCE=()
    __TOOL_REGISTRY_METHOD=()
    __TOOL_REGISTRY_CHECKSUM=()
    __TOOL_REGISTRY_COMMAND=()
    __TOOL_REGISTRY_CALLBACK=()

}
tool::valid () {

    local item="${1:-}" value="${2:-}"

    [[ "${value}" != *$'\n'* && "${value}" != *$'\r'* ]] || return 1

    case "${item}" in
        target|name|bin|package|version|method) [[ "${value}" != *':'* ]] || return 1 ;;
        path|source|checksum|command|callback|field) return 0 ;;
        *) return 1 ;;
    esac

}
tool::key () {

    local target="${1:-}" name="${2:-}" os="default" runtime="default" manager="default"

    [[ -n "${target}" && -n "${name}" ]] || return 1

    case "${target,,}" in
        default|auto|all|any|global|unknown) ;;
        wsl*)   runtime="wsl";     os="linux" ;;
        msys*)  runtime="msys";    os="windows" ;;
        cyg*)   runtime="cygwin";  os="windows" ;;
        git*)   runtime="gitbash"; os="windows" ;;
        linux*) os="linux" ;;
        mac*)   os="macos" ;;
        win*)   os="windows" ;;
        *)      manager="${target,,}" ;;
    esac

    printf '%s\n' "${os}:${runtime}:${manager}:${name}"

}
tool::keys () {

    local key="${1:-}" os="" runtime="" manager="" name="" k=""
    local -a keys=()

    [[ -n "${key}" ]] || return 1

    IFS=':' read -r os runtime manager name <<< "${key}"
    [[ -n "${os}" && -n "${runtime}" && -n "${manager}" && -n "${name}" ]] || return 1

    [[ "${runtime}" != "default" ]] && keys+=( "${os}:${runtime}:default:${name}" )
    [[ "${os}" != "default" ]]      && keys+=( "${os}:default:default:${name}" )
    keys+=( "default:default:default:${name}" )

    for k in "${keys[@]}"; do
        [[ "${k}" == "${key}" ]] || printf '%s\n' "${k}"
    done

}
tool::set () {

    local target="${1:-}" name="${2:-}" bin="${3:-}" package="${4:-}" version="${5:-}" path="${6:-}"
    local source="${7:-}" method="${8:-}" checksum="${9:-}" command="${10:-}" callback="${11:-}" inherit="${12:-1}"

    local key="" keys="" parent="" final_bin="" final_package="" final_version="" final_path=""
    local final_source="" final_method="" final_checksum="" final_command="" final_callback=""

    [[ -n "${target}" && -n "${name}" ]] || return 1

    tool::valid name     "${name}"     || return 1
    tool::valid bin      "${bin}"      || return 1
    tool::valid package  "${package}"  || return 1
    tool::valid version  "${version}"  || return 1
    tool::valid path     "${path}"     || return 1
    tool::valid source   "${source}"   || return 1
    tool::valid method   "${method}"   || return 1
    tool::valid checksum "${checksum}" || return 1
    tool::valid command  "${command}"  || return 1
    tool::valid callback "${callback}" || return 1
    tool::valid target   "${target}"   || return 1

    tool::init
    key="$(tool::key "${target}" "${name}")" || return 1

    final_bin="${bin}"
    final_package="${package}"
    final_version="${version}"
    final_path="${path}"
    final_source="${source}"
    final_method="${method}"
    final_checksum="${checksum}"
    final_command="${command}"
    final_callback="${callback}"

    if (( inherit )); then

        keys="$(tool::keys "${key}")" || true

        while IFS= read -r parent || [[ -n "${parent}" ]]; do

            [[ -n "${parent}"         ]] || continue
            [[ -n "${final_bin}"      ]] || final_bin="${__TOOL_REGISTRY_BIN[${parent}]-}"
            [[ -n "${final_package}"  ]] || final_package="${__TOOL_REGISTRY_PACKAGE[${parent}]-}"
            [[ -n "${final_version}"  ]] || final_version="${__TOOL_REGISTRY_VERSION[${parent}]-}"
            [[ -n "${final_path}"     ]] || final_path="${__TOOL_REGISTRY_PATH[${parent}]-}"
            [[ -n "${final_source}"   ]] || final_source="${__TOOL_REGISTRY_SOURCE[${parent}]-}"
            [[ -n "${final_method}"   ]] || final_method="${__TOOL_REGISTRY_METHOD[${parent}]-}"
            [[ -n "${final_checksum}" ]] || final_checksum="${__TOOL_REGISTRY_CHECKSUM[${parent}]-}"
            [[ -n "${final_command}"  ]] || final_command="${__TOOL_REGISTRY_COMMAND[${parent}]-}"
            [[ -n "${final_callback}" ]] || final_callback="${__TOOL_REGISTRY_CALLBACK[${parent}]-}"

        done <<< "${keys}"

    fi

    [[ -n "${final_bin}"     ]] || final_bin="${name}"
    [[ -n "${final_package}" ]] || final_package="${final_bin}"
    [[ -n "${final_method}"  ]] || final_method="native"

    __TOOL_REGISTRY_BIN["${key}"]="${final_bin}"
    __TOOL_REGISTRY_PACKAGE["${key}"]="${final_package}"
    __TOOL_REGISTRY_VERSION["${key}"]="${final_version}"
    __TOOL_REGISTRY_PATH["${key}"]="${final_path}"
    __TOOL_REGISTRY_SOURCE["${key}"]="${final_source}"
    __TOOL_REGISTRY_METHOD["${key}"]="${final_method}"
    __TOOL_REGISTRY_CHECKSUM["${key}"]="${final_checksum}"
    __TOOL_REGISTRY_COMMAND["${key}"]="${final_command}"
    __TOOL_REGISTRY_CALLBACK["${key}"]="${final_callback}"

}
tool::get () {

    local name="${1:-}" field="${2:-}" key="" manager="" os="" runtime=""
    local bin="" package="" version="" path="" source="" method="" checksum="" command="" callback=""

    local -a keys=()

    [[ -n "${name}" ]] || return 1
    tool::valid name "${name}" || return 1

    os="$(sys::name 2>/dev/null || true)"
    runtime="$(sys::runtime 2>/dev/null || true)"
    manager="$(sys::pkg_manager 2>/dev/null || true)"

    tool::init

    keys+=( "${os}:${runtime}:${manager}:${name}" )
    keys+=( "default:${runtime}:${manager}:${name}" )
    keys+=( "${os}:default:${manager}:${name}" )
    keys+=( "default:default:${manager}:${name}" )
    keys+=( "${os}:${runtime}:default:${name}" )
    keys+=( "default:${runtime}:default:${name}" )
    keys+=( "${os}:default:default:${name}" )
    keys+=( "default:default:default:${name}" )

    for key in "${keys[@]}"; do

        if [[ -n "${__TOOL_REGISTRY_BIN[${key}]-}" && -n "${__TOOL_REGISTRY_PACKAGE[${key}]-}" ]]; then

            bin="${__TOOL_REGISTRY_BIN[${key}]-}"
            package="${__TOOL_REGISTRY_PACKAGE[${key}]-}"
            version="${__TOOL_REGISTRY_VERSION[${key}]-}"
            path="${__TOOL_REGISTRY_PATH[${key}]-}"
            source="${__TOOL_REGISTRY_SOURCE[${key}]-}"
            method="${__TOOL_REGISTRY_METHOD[${key}]-}"
            checksum="${__TOOL_REGISTRY_CHECKSUM[${key}]-}"
            command="${__TOOL_REGISTRY_COMMAND[${key}]-}"
            callback="${__TOOL_REGISTRY_CALLBACK[${key}]-}"

            break

        fi

    done

    [[ -n "${bin}"     ]] || bin="${name}"
    [[ -n "${package}" ]] || package="${bin}"
    [[ -n "${method}"  ]] || method="native"

    case "${field}" in
        "") ;;
        name)     printf '%s\n' "${name}";     return 0 ;;
        bin)      printf '%s\n' "${bin}";      return 0 ;;
        package)  printf '%s\n' "${package}";  return 0 ;;
        version)  printf '%s\n' "${version}";  return 0 ;;
        path)     printf '%s\n' "${path}";     return 0 ;;
        source)   printf '%s\n' "${source}";   return 0 ;;
        method)   printf '%s\n' "${method}";   return 0 ;;
        checksum) printf '%s\n' "${checksum}"; return 0 ;;
        command)  printf '%s\n' "${command}";  return 0 ;;
        callback) printf '%s\n' "${callback}"; return 0 ;;
        *)                                     return 1 ;;
    esac

    printf 'name=%s\n'     "${name}"
    printf 'bin=%s\n'      "${bin}"
    printf 'package=%s\n'  "${package}"
    printf 'version=%s\n'  "${version}"
    printf 'path=%s\n'     "${path}"
    printf 'source=%s\n'   "${source}"
    printf 'method=%s\n'   "${method}"
    printf 'checksum=%s\n' "${checksum}"
    printf 'command=%s\n'  "${command}"
    printf 'callback=%s\n' "${callback}"

}

tool::register () {

    local target="" name="" bin="" package="" version="" path="" source="" method="" checksum="" command="" callback="" inherit="1" k=""
    local p_target="" p_name="" p_bin="" p_package="" p_version="" p_path="" p_source="" p_method="" p_checksum="" p_command="" p_callback=""

    local -a pos=()

    while (( $# > 0 )); do

        k="${1:-}"
        shift || return 1

        case "${k}" in
            --target)
                (( $# > 0 )) || return 1
                target="${1:-}"
                shift || return 1
            ;;
            --name)
                (( $# > 0 )) || return 1
                name="${1:-}"
                shift || return 1
            ;;
            --bin)
                (( $# > 0 )) || return 1
                bin="${1:-}"
                shift || return 1
            ;;
            --package)
                (( $# > 0 )) || return 1
                package="${1:-}"
                shift || return 1
            ;;
            --version)
                (( $# > 0 )) || return 1
                version="${1:-}"
                shift || return 1
            ;;
            --path|--location)
                (( $# > 0 )) || return 1
                path="${1:-}"
                shift || return 1
            ;;
            --source)
                (( $# > 0 )) || return 1
                source="${1:-}"
                shift || return 1
            ;;
            --method|--way)
                (( $# > 0 )) || return 1
                method="${1:-}"
                shift || return 1
            ;;
            --checksum|--hash)
                (( $# > 0 )) || return 1
                checksum="${1:-}"
                shift || return 1
            ;;
            --command|--cmd)
                (( $# > 0 )) || return 1
                command="${1:-}"
                shift || return 1
            ;;
            --callback|--func)
                (( $# > 0 )) || return 1
                callback="${1:-}"
                shift || return 1
            ;;
            --inherit)
                inherit="1"
            ;;
            --no-inherit)
                inherit="0"
            ;;
            --)
                while (( $# > 0 )); do
                    pos+=( "${1:-}" )
                    shift || return 1
                done
            ;;
            -*)
                return 1
            ;;
            *)
                pos+=( "${k}" )
            ;;
        esac

    done

    p_target="${pos[0]:-}"
    p_name="${pos[1]:-}"
    p_bin="${pos[2]:-}"
    p_package="${pos[3]:-}"
    p_version="${pos[4]:-}"
    p_path="${pos[5]:-}"
    p_source="${pos[6]:-}"
    p_method="${pos[7]:-}"
    p_checksum="${pos[8]:-}"
    p_command="${pos[9]:-}"
    p_callback="${pos[10]:-}"

    [[ -n "${target}"   ]] || target="${p_target}"
    [[ -n "${name}"     ]] || name="${p_name}"
    [[ -n "${bin}"      ]] || bin="${p_bin}"
    [[ -n "${package}"  ]] || package="${p_package}"
    [[ -n "${version}"  ]] || version="${p_version}"
    [[ -n "${path}"     ]] || path="${p_path}"
    [[ -n "${source}"   ]] || source="${p_source}"
    [[ -n "${method}"   ]] || method="${p_method}"
    [[ -n "${checksum}" ]] || checksum="${p_checksum}"
    [[ -n "${command}"  ]] || command="${p_command}"
    [[ -n "${callback}" ]] || callback="${p_callback}"

    [[ -n "${bin}"  ]] || bin="${name}"
    [[ -n "${name}" ]] || name="${bin}"

    case "${inherit,,}" in
        1|true|yes|y|on) inherit=1 ;;
        *) inherit=0 ;;
    esac

    tool::set \
        "${target}" "${name}" "${bin}" "${package}" "${version}" "${path}" \
        "${source}" "${method}" "${checksum}" "${command}" "${callback}" "${inherit}"

}
tool::register::default () {

    tool::register default "$@"

}
tool::register::linux () {

    tool::register linux "$@"

}
tool::register::macos () {

    tool::register macos "$@"

}
tool::register::windows () {

    tool::register windows "$@"

}
tool::register::wsl () {

    tool::register wsl "$@"

}
tool::register::msys () {

    tool::register msys "$@"

}
tool::register::cygwin () {

    tool::register cygwin "$@"

}
tool::register::gitbash () {

    tool::register gitbash "$@"

}

tool::hash () {

    hash -r 2>/dev/null || true

}
tool::bin () {

    local name="${1:-}" bin=""

    bin="$(tool::get "${name}" bin 2>/dev/null)" || true
    [[ -n "${bin}" ]] || bin="${name}"

    printf '%s\n' "${bin}"

}
tool::paths () {

    local name="${1:-}" bin="" path="" ext="" dir="" entry="" found=1
    local -a dirs=()

    bin="$(tool::bin "${name}")" || return 1
    path="$(tool::get "${name}" path 2>/dev/null)" || true

    if [[ -n "${path}" && -f "${path}" && -x "${path}" ]]; then

        if sys::has realpath; then realpath "${path}" 2>/dev/null && found=0
        elif sys::has readlink; then readlink -f "${path}" 2>/dev/null && found=0
        else printf '%s\n' "${path}"; found=0
        fi

    fi
    if [[ "${bin}" == */* || "${bin}" == *\\* ]]; then

        if [[ -f "${bin}" && -x "${bin}" ]]; then

            sys::has realpath && realpath "${bin}" 2>/dev/null && return 0
            sys::has readlink && readlink -f "${bin}" 2>/dev/null && return 0

            printf '%s\n' "${bin}"
            return 0

        fi

        return "${found}"

    fi

    case "${PATH:-}" in
        *";"*) IFS=';' read -r -a dirs <<< "${PATH:-}" ;;
        *)     IFS=':' read -r -a dirs <<< "${PATH:-}" ;;
    esac

    for dir in "${dirs[@]}"; do

        [[ -n "${dir}" ]] || continue

        for ext in "" ".exe" ".cmd" ".bat" ".ps1"; do

            entry="${dir%/}/${bin}${ext}"
            [[ -f "${entry}" ]] || continue

            case "${entry}" in
                *.exe|*.cmd|*.bat|*.ps1) ;;
                *) [[ -x "${entry}" ]] || continue ;;
            esac

            printf '%s\n' "${entry}"
            found=0

        done

    done

    return "${found}"

}
tool::path () {

    local path=""

    IFS= read -r path < <(tool::paths "$@" 2>/dev/null) || return 1
    [[ -n "${path}" && -f "${path}" ]] || return 1

    printf '%s\n' "${path}"

}
tool::has () {

    tool::path "$@" >/dev/null 2>&1

}
tool::need () {

    local name="${1:-}"

    [[ -n "${name}" ]] || return 1
    tool::has "$@" && return 0

    printf '[PANIC] missing tool : ( %s )\n' "${name}" >&2

    [[ "${-}" == *i* ]] && return 127
    exit 127

}
tool::version () {

    local name="${1:-}" exe="" arg="" out="" s="" v="" major="" minor="" patch="" tail=""

    sys::has grep || return 1
    sys::has sed || return 1

    exe="$(tool::path "${name}")" || return 1

    for arg in --version -v -V version; do

        out="$("${exe}" "${arg}" 2>&1 || true)"
        [[ -n "${out}" ]] || continue

        while IFS= read -r s; do

            [[ -n "${s}" ]] || continue

            if [[ "${s}" =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))?([.+-].*)?$ ]]; then

                major="${BASH_REMATCH[1]}"
                minor="${BASH_REMATCH[2]}"
                patch="${BASH_REMATCH[4]:-0}"
                tail="${BASH_REMATCH[5]:-}"

                v="${major}.${minor}.${patch}"

                if [[ -n "${tail}" ]]; then

                    tail="${tail#[.+-]}"
                    tail="$(printf '%s\n' "${tail}" | sed -E 's/[.+-]+/./g; s/^\.+//; s/\.+$//')"

                    [[ -n "${tail}" ]] && v="${v}-${tail}"

                fi

                printf '%s\n' "${v}"
                return 0

            fi

        done < <(
            printf '%s\n' "${out}" |
            LC_ALL=C grep -Eio '[0-9]+[.][0-9]+([.][0-9]+)?([.+-][0-9A-Za-z][0-9A-Za-z.+-]*)?' 2>/dev/null
        )

    done

    return 1

}
tool::version_match () {

    local name="${1:-}" want="${2:-}" current="" raw="" i=0
    local want_major="" want_minor="" want_patch="" want_tail="" want_depth=0
    local cur_major="" cur_minor="" cur_patch="" cur_tail=""
    local major="" minor="" patch="" tail="" depth=0

    [[ -n "${name}" && -n "${want}" ]] || return 1

    current="$(tool::version "${name}" 2>/dev/null || true)"
    [[ -n "${current}" ]] || return 1

    for raw in "${want}" "${current}"; do

        raw="${raw//$'\r'/}"
        raw="${raw//$'\n'/ }"
        raw="${raw#"${raw%%[![:space:]]*}"}"
        raw="${raw%"${raw##*[![:space:]]}"}"
        raw="${raw#==}"
        raw="${raw#=}"
        raw="${raw#v}"
        raw="${raw#V}"

        [[ "${raw}" =~ ([0-9]+)([.]([0-9]+))?([.]([0-9]+))?([.+_-]?([A-Za-z][0-9A-Za-z.+_-]*|[0-9A-Za-z][0-9A-Za-z.+_-]*))? ]] || return 1

        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[3]:-}"
        patch="${BASH_REMATCH[5]:-}"
        tail="${BASH_REMATCH[7]:-}"

        depth=1
        [[ -n "${minor}" ]] && depth=2
        [[ -n "${patch}" ]] && depth=3

        major="$((10#${major}))"
        [[ -n "${minor}" ]] && minor="$((10#${minor}))"
        [[ -n "${patch}" ]] && patch="$((10#${patch}))"

        if [[ -n "${tail}" ]]; then
            tail="${tail#[.+_-]}"
            tail="$(printf '%s\n' "${tail}" | tr '[:upper:]_' '[:lower:].' | sed -E 's/[.+_-]+/./g; s/^\.+//; s/\.+$//')"
        fi

        if (( i == 0 )); then
            want_major="${major}"
            want_minor="${minor}"
            want_patch="${patch}"
            want_tail="${tail}"
            want_depth="${depth}"
        else
            cur_major="${major}"
            cur_minor="${minor}"
            cur_patch="${patch}"
            cur_tail="${tail}"
        fi

        i=$(( i + 1 ))

    done

    [[ "${want_major}" == "${cur_major}" ]] || return 1
    (( want_depth < 2 )) || { [[ "${want_minor}" == "${cur_minor}" ]] || return 1; }
    (( want_depth < 3 )) || { [[ "${want_patch}" == "${cur_patch}" ]] || return 1; }
    [[ -z "${want_tail}" ]] || { [[ "${want_tail}" == "${cur_tail}" ]] || return 1; }

    return 0

}

tool::algo () {

    local algo="${1:-sha256}"

    algo="${algo,,}"
    algo="${algo//_/-}"

    case "${algo}" in
        md5)                    printf '%s\n' "md5" ;;
        sha1|sha-1|1)           printf '%s\n' "sha1" ;;
        sha224|sha-224|224)     printf '%s\n' "sha224" ;;
        sha256|sha-256|256)     printf '%s\n' "sha256" ;;
        sha384|sha-384|384)     printf '%s\n' "sha384" ;;
        sha512|sha-512|512)     printf '%s\n' "sha512" ;;
        blake2b512|blake2b-512) printf '%s\n' "blake2b512" ;;
        blake2s256|blake2s-256) printf '%s\n' "blake2s256" ;;
        *)                      return 1 ;;
    esac

}
tool::checksum () {

    local file="${1:-}" algo="${2:-sha256}" out="" openssl_algo=""

    [[ -n "${file}" && -f "${file}" ]] || return 1
    algo="$(tool::algo "${algo}")" || return 1

    case "${algo}" in
        md5)

            if command -v md5sum >/dev/null 2>&1; then
                md5sum "${file}" | awk '{print tolower($1)}'
                return 0
            fi

            if command -v md5 >/dev/null 2>&1; then
                out="$(md5 -q "${file}" 2>/dev/null || md5 "${file}" 2>/dev/null || true)"
                [[ "${out}" =~ ([A-Fa-f0-9]{32}) ]] || return 1
                printf '%s\n' "${BASH_REMATCH[1],,}"
                return 0
            fi

            if command -v openssl >/dev/null 2>&1; then
                out="$(openssl dgst -md5 "${file}" 2>/dev/null || true)"
                [[ "${out}" =~ ([A-Fa-f0-9]{32}) ]] || return 1
                printf '%s\n' "${BASH_REMATCH[1],,}"
                return 0
            fi

        ;;
        sha1|sha224|sha256|sha384|sha512)

            if command -v "${algo}sum" >/dev/null 2>&1; then
                "${algo}sum" "${file}" | awk '{print tolower($1)}'
                return 0
            fi

            if command -v shasum >/dev/null 2>&1; then
                shasum -a "${algo#sha}" "${file}" | awk '{print tolower($1)}'
                return 0
            fi

            if command -v openssl >/dev/null 2>&1; then
                openssl_algo="-${algo}"
                out="$(openssl dgst "${openssl_algo}" "${file}" 2>/dev/null || true)"
                [[ "${out}" =~ ([A-Fa-f0-9]+)$ ]] || return 1
                printf '%s\n' "${BASH_REMATCH[1],,}"
                return 0
            fi

        ;;
        blake2b512)

            if command -v b2sum >/dev/null 2>&1; then
                b2sum "${file}" | awk '{print tolower($1)}'
                return 0
            fi

            if command -v openssl >/dev/null 2>&1; then
                out="$(openssl dgst -blake2b512 "${file}" 2>/dev/null || true)"
                [[ "${out}" =~ ([A-Fa-f0-9]{128}) ]] || return 1
                printf '%s\n' "${BASH_REMATCH[1],,}"
                return 0
            fi

        ;;
        blake2s256)

            if command -v openssl >/dev/null 2>&1; then
                out="$(openssl dgst -blake2s256 "${file}" 2>/dev/null || true)"
                [[ "${out}" =~ ([A-Fa-f0-9]{64}) ]] || return 1
                printf '%s\n' "${BASH_REMATCH[1],,}"
                return 0
            fi

        ;;
    esac

    return 1

}
tool::verify () {

    local file="${1:-}" checksum="${2:-}" algo="" want="" got="" n=0

    [[ -n "${checksum}" && -n "${file}" && -f "${file}" ]] || return 1

    checksum="${checksum//$'\r'/}"
    checksum="${checksum//$'\n'/ }"
    checksum="${checksum#"${checksum%%[![:space:]]*}"}"
    checksum="${checksum%"${checksum##*[![:space:]]}"}"

    case "${checksum}" in
        *:*)
            algo="${checksum%%:*}"
            want="${checksum#*:}"
        ;;
        *-*)
            algo="${checksum%%-*}"
            want="${checksum#*-}"
        ;;
        *)
            want="${checksum}"
            case "${#want}" in
                32)  algo="md5" ;;
                40)  algo="sha1" ;;
                56)  algo="sha224" ;;
                64)  algo="sha256" ;;
                96)  algo="sha384" ;;
                128) algo="sha512" ;;
                *)   return 1 ;;
            esac
        ;;
    esac

    algo="$(tool::algo "${algo}")" || return 1

    want="${want#"${want%%[![:space:]]*}"}"
    want="${want%"${want##*[![:space:]]}"}"
    want="${want,,}"

    case "${algo}" in
        md5)        n=32 ;;
        sha1)       n=40 ;;
        sha224)     n=56 ;;
        sha256)     n=64 ;;
        sha384)     n=96 ;;
        sha512)     n=128 ;;
        blake2b512) n=128 ;;
        blake2s256) n=64 ;;
        *)          return 1 ;;
    esac

    [[ "${want}" =~ ^[0-9a-f]+$ ]] || return 1
    (( ${#want} == n )) || return 1

    got="$(tool::checksum "${file}" "${algo}" 2>/dev/null || true)"
    got="${got,,}"

    [[ -n "${got}" && "${got}" == "${want}" ]]

}

tool::refresh () {

    local manager=""

    manager="$(sys::pkg_manager 2>/dev/null || true)"
    [[ -n "${manager}" && "${manager}" != "unknown" ]] || return 1

    case "${manager,,}" in
        apt)     proc::try_run apt-get update ;;
        apk)     proc::try_run apk update ;;
        dnf)     proc::try_run dnf makecache -y ;;
        yum)     proc::try_run yum makecache -y ;;
        zypper)  proc::try_run zypper --non-interactive refresh ;;
        pacman)  proc::try_run pacman -Sy --noconfirm ;;
        xbps)    proc::try_run xbps-install -S ;;
        nix)     proc::try_run nix-channel --update || proc::try_run nix flake update ;;
        brew)    proc::try_run brew update ;;
        port)    proc::try_run port selfupdate ;;
        scoop)   proc::try_run scoop update ;;
        choco)   proc::try_run choco upgrade chocolatey -y ;;
        winget)  proc::try_run winget source update ;;
        *)       return 1 ;;
    esac

}
tool::refresh_ok () {

    tool::refresh "$@" >/dev/null 2>&1

}

tool::windows_manager () {

    local name="" p=""

    for name in winget scoop choco; do

        p="$(command -v "${name}" 2>/dev/null || true)"
        [[ -n "${p}" ]] && { printf '%s\n' "${p}"; return 0; }

        p="$(command -v "${name}.exe" 2>/dev/null || true)"
        [[ -n "${p}" ]] && { printf '%s\n' "${p}"; return 0; }

        p="$(command -v "${name}.cmd" 2>/dev/null || true)"
        [[ -n "${p}" ]] && { printf '%s\n' "${p}"; return 0; }

        p="$(command -v "${name}.bat" 2>/dev/null || true)"
        [[ -n "${p}" ]] && { printf '%s\n' "${p}"; return 0; }

        for p in \
            "${LOCALAPPDATA:-}/Microsoft/WindowsApps/${name}.exe" \
            "${USERPROFILE:-}/AppData/Local/Microsoft/WindowsApps/${name}.exe" \
            "${HOME:-}/AppData/Local/Microsoft/WindowsApps/${name}.exe" \
            "${USERPROFILE:-}/scoop/shims/${name}.exe" \
            "${USERPROFILE:-}/scoop/shims/${name}.cmd" \
            "${SCOOP:-}/shims/${name}.exe" \
            "${SCOOP:-}/shims/${name}.cmd" \
            "${HOME:-}/scoop/shims/${name}.exe" \
            "${HOME:-}/scoop/shims/${name}.cmd" \
            "/c/ProgramData/chocolatey/bin/${name}.exe" \
            "/c/ProgramData/chocolatey/bin/${name}.cmd"
        do

            [[ -f "${p}" ]] || continue

            printf '%s\n' "${p}"
            return 0

        done

    done

    return 1

}
tool::windows_path () {

    local bin="${1:-}" p=""

    [[ -n "${bin}" ]] || return 1

    for p in \
        "$(command -v "${bin}" 2>/dev/null || true)" \
        "$(command -v "${bin}.exe" 2>/dev/null || true)" \
        "$(command -v "${bin}.cmd" 2>/dev/null || true)" \
        "$(command -v "${bin}.bat" 2>/dev/null || true)" \
        "${LOCALAPPDATA:-}/Microsoft/WindowsApps/${bin}.exe" \
        "${USERPROFILE:-}/scoop/shims/${bin}.exe" \
        "${USERPROFILE:-}/scoop/shims/${bin}.cmd" \
        "${SCOOP:-}/shims/${bin}.exe" \
        "${SCOOP:-}/shims/${bin}.cmd" \
        "${HOME:-}/scoop/shims/${bin}.exe" \
        "${HOME:-}/scoop/shims/${bin}.cmd" \
        "/c/ProgramData/chocolatey/bin/${bin}.exe" \
        "/c/ProgramData/chocolatey/bin/${bin}.cmd" \
        "/c/Program Files/${bin}/${bin}.exe" \
        "/c/Program Files (x86)/${bin}/${bin}.exe"
    do

        [[ -n "${p}" && -f "${p}" ]] || continue

        printf '%s\n' "${p}"
        return 0

    done

    return 1

}
tool::windows_wrapper () {

    local bin="${1:-}" exe="${2:-}" dest="" home="" q=""

    home="${HOME:-${USERPROFILE:-${HOMEDRIVE:-}${HOMEPATH:-}}}"

    [[ -n "${home}" && -n "${bin}" && -f "${exe}" ]] || return 1

    dest="${home%/}/.local/bin/${bin}"
    mkdir -p -- "${dest%/*}" >/dev/null 2>&1 || return 1

    q="'${exe//\'/\'\\\'\'}'"

    printf '%s\n' '#!/usr/bin/env bash' "exec ${q} \"\$@\"" > "${dest}" || return 1
    chmod +x -- "${dest}" >/dev/null 2>&1 || true

}
tool::msys_package () {

    local package="${1:-}" key="" name="" arch="${MSYSTEM_CARCH:-x86_64}"

    [[ -n "${package}" ]] || return 1

    case "${package}" in
        *:*)
            key="${package%%:*}"
            name="${package#*:}"

            case "${key,,}" in
                mingw|mingw64) printf 'mingw-w64-%s-%s\n' "${arch}" "${name}"; return 0 ;;
                ucrt|ucrt64)   printf 'mingw-w64-ucrt-%s-%s\n' "${arch}" "${name}"; return 0 ;;
                clang|clang64) printf 'mingw-w64-clang-%s-%s\n' "${arch}" "${name}"; return 0 ;;
                *)
                    key="${package##*:}"
                    name="${package%:*}"

                    case "${key,,}" in
                        mingw|mingw64) printf 'mingw-w64-%s-%s\n' "${arch}" "${name}" ;;
                        ucrt|ucrt64)   printf 'mingw-w64-ucrt-%s-%s\n' "${arch}" "${name}" ;;
                        clang|clang64) printf 'mingw-w64-clang-%s-%s\n' "${arch}" "${name}" ;;
                        *)             printf '%s\n' "${package}" ;;
                    esac
                ;;
            esac
        ;;
        *)
            printf '%s\n' "${package}"
        ;;
    esac

}

tool::install_windows () {

    local name="${1:-}" package="${2:-}" version="${3:-}" bin="" path="" manager="" mgr=""

    [[ -n "${name}" && -n "${package}" ]] || return 1

    if sys::is_msys && sys::has pacman && [[ -z "${version}" ]]; then

        package="$(tool::msys_package "${package}")" || return 1
        proc::try_run pacman -S --needed --noconfirm --noprogressbar "${package}" || true

        tool::hash || true
        tool::has "${name}" && return 0

    fi

    manager="$(tool::windows_manager 2>/dev/null)" || return 1
    [[ -n "${manager}" ]] || return 1

    mgr="$(basename -- "${manager}")"
    mgr="${mgr%.*}"

    case "${mgr,,}" in
        winget)
            if [[ -n "${version}" ]]; then
                proc::try_run "${manager}" install -e \
                    --id "${package}" \
                    --version "${version}" \
                    --source winget \
                    --accept-package-agreements \
                    --accept-source-agreements \
                    --disable-interactivity
            else
                proc::try_run "${manager}" install -e \
                    --id "${package}" \
                    --source winget \
                    --accept-package-agreements \
                    --accept-source-agreements \
                    --disable-interactivity
            fi
        ;;
        scoop)
            if [[ -n "${version}" ]]; then proc::try_run "${manager}" install "${package}@${version}"
            else proc::try_run "${manager}" install "${package}"
            fi
        ;;
        choco)
            if [[ -n "${version}" ]]; then proc::try_run "${manager}" install -y "${package}" "--version=${version}"
            else proc::try_run "${manager}" install -y "${package}"
            fi
        ;;
        *)
            return 1
        ;;
    esac

    tool::hash || true

    if ! tool::has "${name}"; then

        bin="$(tool::bin "${name}")" || true
        [[ -n "${bin}" ]] || bin="${name}"

        path="$(tool::windows_path "${bin}")" || return 1
        tool::windows_wrapper "${bin}" "${path}" || return 1

    fi

    tool::hash || true
    tool::has "${name}"

}
tool::install_native () {

    local name="${1:-}" package="${2:-}" version="${3:-}" manager=""

    [[ -n "${name}" && -n "${package}" ]] || return 1

    manager="$(sys::pkg_manager 2>/dev/null || true)"
    [[ -n "${manager}" && "${manager}" != "unknown" ]] || return 1

    case "${manager,,}" in
        apt)
            if [[ -n "${version}" ]]; then proc::try_run apt-get install -y "${package}=${version}"
            else proc::try_run apt-get install -y "${package}"
            fi
        ;;
        apk)
            if [[ -n "${version}" ]]; then proc::try_run apk add "${package}=${version}"
            else proc::try_run apk add "${package}"
            fi
        ;;
        dnf)
            if [[ -n "${version}" ]]; then proc::try_run dnf install -y "${package}-${version}"
            else proc::try_run dnf install -y "${package}"
            fi
        ;;
        yum)
            if [[ -n "${version}" ]]; then proc::try_run yum install -y "${package}-${version}"
            else proc::try_run yum install -y "${package}"
            fi
        ;;
        zypper)
            if [[ -n "${version}" ]]; then proc::try_run zypper --non-interactive install "${package}=${version}"
            else proc::try_run zypper --non-interactive install "${package}"
            fi
        ;;
        xbps)
            if [[ -n "${version}" ]]; then proc::try_run xbps-install -Sy "${package}-${version}"
            else proc::try_run xbps-install -Sy "${package}"
            fi
        ;;
        nix)
            if [[ -n "${version}" ]]; then proc::try_run nix profile install "nixpkgs/${version}#${package}"
            else proc::try_run nix profile install "nixpkgs#${package}"
            fi
        ;;
        brew)
            if [[ -n "${version}" ]]; then proc::try_run brew install "${package}@${version}"
            else proc::try_run brew install "${package}"
            fi
        ;;
        port)
            [[ -n "${version}" ]] && return 1
            proc::try_run port install "${package}"
        ;;
        pacman)
            if sys::is_windows; then tool::install_windows "${name}" "${package}" "${version}"
            elif [[ -n "${version}" ]]; then return 1
            else proc::try_run pacman -S --needed --noconfirm --noprogressbar "${package}"
            fi
        ;;
        winget|scoop|choco)
            tool::install_windows "${name}" "${package}" "${version}"
        ;;
        *)
            return 1
        ;;
    esac || return 1

    return 0

}
tool::install_source () {

    local type="${1:-}" source="${2:-}" version="${3:-}" bin="${4:-}" path="${5:-}" command="${6:-}" checksum="${7:-}"
    local home="" temp="" url="" dest="" dir="" base="" name="" file="" work="" entry="" ext="" rc=0

    local -a cmd=()
    [[ -n "${command}" ]] && { read -r -a cmd <<< "${command}" || true; }

    sys::has curl || return 1
    [[ -n "${type}" && -n "${source}" ]] || return 1

    home="${HOME:-${USERPROFILE:-${HOMEDRIVE:-}${HOMEPATH:-}}}"
    temp="${TMPDIR:-${TEMP:-${TMP:-/tmp}}}"

    url="${source//\{version\}/${version}}"
    url="${url//\{v\}/${version}}"

    name="${url//[^a-zA-Z0-9_-]/-}"
    name="${name:-installer}"

    bin="${bin:-"$(basename -- "${url%%\?*}")"}"
    bin="${bin##*/}"
    bin="${bin%%.*}"

    [[ -n "${home}" && -n "${temp}" && -n "${bin}" ]] || return 1
    [[ -n "${path}" ]] || path="${bin}"

    dest="${home%/}/.local/bin/${bin}"
    mkdir -p -- "${dest%/*}" >/dev/null 2>&1 || true

    file="${temp%/}/${name}-source-$$-${RANDOM}${RANDOM}"
    work="${temp%/}/${name}-extract-$$-${RANDOM}${RANDOM}"

    if (( rc == 0 )); then

        proc::try_run curl -fsSL "${url}" -o "${file}" || rc=1

    fi
    if (( rc == 0 )); then

        [[ -n "${checksum}" ]] && { tool::verify "${file}" "${checksum}" || rc=1; }

    fi
    if (( rc == 0 )); then

        case "${type}" in
            bash)

                sys::has bash || rc=1

                if (( rc == 0 )); then

                    chmod +x -- "${file}" >/dev/null 2>&1 || true
                    proc::try_run bash "${file}" "${cmd[@]}" || rc=$?

                fi

            ;;
            sh|shell)

                sys::has sh || rc=1

                if (( rc == 0 )); then

                    chmod +x -- "${file}" >/dev/null 2>&1 || true
                    proc::try_run sh "${file}" "${cmd[@]}" || rc=$?

                fi

            ;;
            bin|binary)

                proc::try_run cp -f -- "${file}" "${dest}" || rc=$?
                chmod +x -- "${dest}" >/dev/null 2>&1 || true

            ;;
            archive|extract|zip|tar.gz|tgz|tar.xz|txz|tar.bz2|tbz2)

                if [[ "${type}" == "archive" || "${type}" == "extract" ]]; then

                    case "${url%%\?*}" in
                        *.tar.gz|*.tgz)   type="tar.gz" ;;
                        *.tar.xz|*.txz)   type="tar.xz" ;;
                        *.tar.bz2|*.tbz2) type="tar.bz2" ;;
                        *)                type="zip" ;;
                    esac

                fi
                if (( rc == 0 )); then

                    if [[ "${type}" == *zip* ]]; then sys::has unzip || rc=1
                    elif [[ "${type}" == *tar* ]]; then sys::has tar || rc=1
                    fi

                    mkdir -p -- "${work}" >/dev/null 2>&1 || rc=1

                fi
                if (( rc == 0 )); then

                    case "${type}" in
                        zip)          proc::try_run unzip -oq "${file}" -d "${work}" || rc=$? ;;
                        tar.gz|tgz)   proc::try_run tar -xzf  "${file}" -C "${work}" || rc=$? ;;
                        tar.xz|txz)   proc::try_run tar -xJf  "${file}" -C "${work}" || rc=$? ;;
                        tar.bz2|tbz2) proc::try_run tar -xjf  "${file}" -C "${work}" || rc=$? ;;
                    esac

                fi
                if (( rc == 0 )); then

                    dir="${path%/*}"
                    base="${path##*/}"

                    base="${base%.exe}"
                    base="${base%.cmd}"
                    base="${base%.bat}"
                    base="${base%.ps1}"
                    base="${base%.sh}"
                    base="${base%.bash}"

                    [[ "${dir}" == "${path}" ]] && dir=""
                    [[ -n "${dir}" ]] && work="${work%/}/${dir}"

                    sys::has find || rc=1
                    sys::has head || rc=1

                fi
                if (( rc == 0 )); then

                    for ext in "" ".exe" ".cmd" ".bat" ".ps1" ".sh" ".bash"; do

                        entry="$(find "${work}" -type f -name "${base}${ext}" -perm -u+x 2>/dev/null | head -n 1)"
                        [[ -n "${entry}" ]] && break

                    done

                    if [[ -z "${entry}" ]]; then

                        for ext in "" ".exe" ".cmd" ".bat" ".ps1" ".sh" ".bash"; do

                            entry="$(find "${work}" -type f -name "${base}${ext}" 2>/dev/null | head -n 1)"
                            [[ -n "${entry}" ]] && break

                        done

                    fi

                    [[ -f "${entry}" ]] || rc=1

                fi
                if (( rc == 0 )); then

                    proc::try_run cp -f -- "${entry}" "${dest}" || rc=$?
                    chmod +x -- "${dest}" >/dev/null 2>&1 || true

                fi
            ;;
            *)
                rc=1
            ;;
        esac

    fi

    rm -rf -- "${work}" "${file}" >/dev/null 2>&1 || true
    return "${rc}"

}
tool::install () {

    local name="" bin="" path="" package="" version="" source="" method="" checksum="" command="" callback="" force=""
    local p_name="" p_package="" p_version="" p_source="" p_method="" p_checksum="" p_command="" p_callback="" p_force=""
    local data="" key="" value="" k="" current=""

    local -a pos=() cmd=()

    while (( $# > 0 )); do

        k="${1:-}"
        shift || return 1

        case "${k}" in
            --name)
                (( $# > 0 )) || return 1
                name="${1:-}"
                shift || return 1
            ;;
            --package)
                (( $# > 0 )) || return 1
                package="${1:-}"
                shift || return 1
            ;;
            --version)
                (( $# > 0 )) || return 1
                version="${1:-}"
                shift || return 1
            ;;
            --source)
                (( $# > 0 )) || return 1
                source="${1:-}"
                shift || return 1
            ;;
            --method|--way)
                (( $# > 0 )) || return 1
                method="${1:-}"
                shift || return 1
            ;;
            --checksum|--hash)
                (( $# > 0 )) || return 1
                checksum="${1:-}"
                shift || return 1
            ;;
            --command|--cmd)
                (( $# > 0 )) || return 1
                command="${1:-}"
                shift || return 1
            ;;
            --callback|--func)
                (( $# > 0 )) || return 1
                callback="${1:-}"
                shift || return 1
            ;;
            --force)
                force="1"
            ;;
            --no-force)
                force="0"
            ;;
            --)
                while (( $# > 0 )); do
                    pos+=( "${1:-}" )
                    shift || return 1
                done
            ;;
            -*)
                return 1
            ;;
            *)
                pos+=( "${k}" )
            ;;
        esac

    done

    p_name="${pos[0]:-}"
    p_package="${pos[1]:-}"
    p_version="${pos[2]:-}"
    p_source="${pos[3]:-}"
    p_method="${pos[4]:-}"
    p_checksum="${pos[5]:-}"
    p_command="${pos[6]:-}"
    p_callback="${pos[7]:-}"
    p_force="${pos[8]:-}"

    [[ -n "${name}"     ]] || name="${p_name}"
    [[ -n "${package}"  ]] || package="${p_package}"
    [[ -n "${version}"  ]] || version="${p_version}"
    [[ -n "${source}"   ]] || source="${p_source}"
    [[ -n "${method}"   ]] || method="${p_method}"
    [[ -n "${checksum}" ]] || checksum="${p_checksum}"
    [[ -n "${command}"  ]] || command="${p_command}"
    [[ -n "${callback}" ]] || callback="${p_callback}"
    [[ -n "${force}"    ]] || force="${p_force}"

    case "${force,,}" in
        1|true|yes|y|on) force=1 ;;
        *) force=0 ;;
    esac

    [[ -n "${name}" ]] || return 1

    data="$(tool::get "${name}" 2>/dev/null)" || return 1

    while IFS='=' read -r key value || [[ -n "${key}" ]]; do

        case "${key}" in
            bin)      [[ -n "${bin}"      ]] || bin="${value}" ;;
            package)  [[ -n "${package}"  ]] || package="${value}" ;;
            version)  [[ -n "${version}"  ]] || version="${value}" ;;
            path)     [[ -n "${path}"     ]] || path="${value}" ;;
            source)   [[ -n "${source}"   ]] || source="${value}" ;;
            method)   [[ -n "${method}"   ]] || method="${value}" ;;
            checksum) [[ -n "${checksum}" ]] || checksum="${value}" ;;
            command)  [[ -n "${command}"  ]] || command="${value}" ;;
            callback) [[ -n "${callback}" ]] || callback="${value}" ;;
        esac

    done <<< "${data}"

    if (( force )); then

        if [[ -n "${version}" ]]; then

            if ! tool::version_match "${name}" "${version}"; then
                tool::remove "${name}" >/dev/null 2>&1 || true
                tool::hash || true
            fi

        else

            tool::remove "${name}" >/dev/null 2>&1 || true
            tool::hash || true

        fi

    fi
    if ! tool::has "${name}"; then

        case "${method,,}" in
            ""|native) tool::install_native "${name}" "${package}" "${version}" || return 1 ;;
            *) tool::install_source "${method}" "${source}" "${version}" "${bin}" "${path}" "${command}" "${checksum}" || return 1 ;;
        esac

    fi

    tool::hash || true
    tool::has "${name}" || return 1

    if [[ -n "${callback}" ]]; then

        if declare -F "${callback}" >/dev/null 2>&1; then cmd+=( "${callback}" )
        else read -r -a cmd <<< "${callback}" || true
        fi

        (( ${#cmd[@]} > 0 )) || return 1
        "${cmd[@]}" "${name}" "${bin}" "${package}" "${version}" || return 1

    fi

    return 0

}
tool::install_all () {

    local spec="" delim="" name="" package="" version="" source="" method="" checksum="" command="" callback="" force=""

    (( $# > 0 )) || return 1

    for spec in "$@"; do

        [[ -n "${spec}" ]] || return 1
        [[ "${spec}" != *$'\n'* && "${spec}" != *$'\r'* ]] || return 1

        delim=":"
        [[ "${spec}" == *","* ]] && delim=","
        [[ "${spec}" == *"|"* ]] && delim="|"

        IFS="${delim}" read -r name package version source method checksum command callback force _ <<< "${spec}"

        tool::install \
            "${name}" "${package}" "${version}" "${source}" "${method}" \
            "${checksum}" "${command}" "${callback}" "${force}" || return 1

    done

    return 0

}

tool::remove_native () {

    local package="${1:-}" manager=""
    [[ -n "${package}" ]] || return 1

    manager="$(sys::pkg_manager 2>/dev/null || true)"
    [[ -n "${manager}" && "${manager}" != "unknown" ]] || return 1

    case "${manager,,}" in
        apt)     proc::try_run apt-get remove -y "${package}" ;;
        apk)     proc::try_run apk del "${package}" ;;
        dnf)     proc::try_run dnf remove -y "${package}" ;;
        yum)     proc::try_run yum remove -y "${package}" ;;
        zypper)  proc::try_run zypper --non-interactive remove "${package}" ;;
        pacman)  proc::try_run pacman -R --noconfirm "${package}" ;;
        xbps)    proc::try_run xbps-remove -Ry "${package}" ;;
        nix)     proc::try_run nix profile remove "${package}" ;;
        brew)    proc::try_run brew uninstall "${package}" ;;
        port)    proc::try_run port uninstall "${package}" ;;
        scoop)   proc::try_run scoop uninstall "${package}" ;;
        choco)   proc::try_run choco uninstall -y "${package}" ;;
        winget)  proc::try_run winget uninstall -e --id "${package}" --source winget --disable-interactivity ;;
        *)       return 1 ;;
    esac

}
tool::remove_path () {

    local name="${1:-}" path=""
    [[ -n "${name}" ]] || return 1

    while IFS= read -r path || [[ -n "${path}" ]]; do

        [[ -e "${path}" || -L "${path}" ]] || continue
        [[ -f "${path}" || -L "${path}" ]] || continue

        proc::try_run rm -f -- "${path}" >/dev/null 2>&1 || true

    done < <(tool::paths "${name}" 2>/dev/null || true)

    return 0

}
tool::remove () {

    local name="" package="" p_name="" p_package="" k=""
    local -a pos=()

    while (( $# > 0 )); do

        k="${1:-}"
        shift || return 1

        case "${k}" in
            --name)
                (( $# > 0 )) || return 1
                name="${1:-}"
                shift || return 1
            ;;
            --package)
                (( $# > 0 )) || return 1
                package="${1:-}"
                shift || return 1
            ;;
            --)
                while (( $# > 0 )); do
                    pos+=( "${1:-}" )
                    shift || return 1
                done
            ;;
            -*)
                return 1
            ;;
            *)
                pos+=( "${k}" )
            ;;
        esac

    done

    p_name="${pos[0]:-}"
    p_package="${pos[1]:-}"

    [[ -n "${name}"    ]] || name="${p_name}"
    [[ -n "${package}" ]] || package="${p_package}"

    [[ -n "${name}"    ]] || return 1
    [[ -n "${package}" ]] || package="$(tool::get "${name}" package 2>/dev/null)" || true
    [[ -n "${package}" ]] || package="${name}"

    if tool::has "${name}"; then

        tool::remove_native "${package}" || true
        tool::hash || true
        tool::has "${name}" && { tool::remove_path "${name}" || true; }

    fi

    tool::hash || true
    tool::has "${name}" && return 1

    return 0

}
tool::remove_all () {

    local spec="" delim="" name="" package=""

    (( $# > 0 )) || return 1

    for spec in "$@"; do

        [[ -n "${spec}" ]] || return 1
        [[ "${spec}" != *$'\n'* && "${spec}" != *$'\r'* ]] || return 1

        delim=":"
        [[ "${spec}" == *","* ]] && delim=","
        [[ "${spec}" == *"|"* ]] && delim="|"

        IFS="${delim}" read -r name package _ <<< "${spec}"

        tool::remove "${name}" "${package}" || return 1

    done

    return 0

}

tool::ensure () {

    tool::install "$@"

}
tool::ensure_all () {

    tool::install_all "$@"

}
