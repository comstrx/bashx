
match_use () {

    local line="${1:-}" mod="" dots="" pattern=""

    line="${line%$'\r'}"

    pattern='^[[:space:]]*use[[:space:]]+'
    pattern+='((\.|(\.\.)+)::[A-Za-z_][A-Za-z0-9_.-]*'
    pattern+='(::[A-Za-z_][A-Za-z0-9_.-]*)*'
    pattern+='|[A-Za-z_][A-Za-z0-9_.-]*'
    pattern+='(::[A-Za-z_][A-Za-z0-9_.-]*)*)'
    pattern+='[[:space:]]*([#].*)?$'

    [[ "${line}" =~ ${pattern} ]] || return 1

    mod="${BASH_REMATCH[1]}"

    [[ -n "${mod}" ]] || return 1
    [[ "${mod}" != *--* ]] || return 1
    [[ "${mod}" != *.-* ]] || return 1
    [[ "${mod}" != *-. ]] || return 1
    [[ "${mod}" != *//* ]] || return 1
    [[ "${mod}" != /* ]] || return 1
    [[ "${mod}" != *\\* ]] || return 1
    [[ "${mod}" != *'$'* ]] || return 1

    if [[ "${mod}" == .* ]]; then

        dots="${mod%%::*}"

        case "${dots}" in
            .) ;;
            *) (( ${#dots} % 2 == 0 )) || return 1 ;;
        esac

    fi

    printf '%s\n' "${mod}"

}
to_realpath () {

    local file="${1:-}" dir="" base=""

    [[ -n "${file}" ]] || return 1

    command -v realpath >/dev/null 2>&1 && realpath -- "${file}" 2>/dev/null && return 0
    command -v readlink >/dev/null 2>&1 && readlink -f -- "${file}" 2>/dev/null && return 0

    case "${file}" in
        /*)
            printf '%s\n' "${file}"
        ;;
        *)
            dir="$(cd -- "$(dirname -- "${file}")" 2>/dev/null && pwd -P)" || return 1
            base="${file##*/}"
            printf '%s/%s\n' "${dir%/}" "${base}"
        ;;
    esac

}
to_relative () {

    local file="${1:-}" dots="${2:-}" dir="" up=0 i=0

    [[ -n "${file}" && -f "${file}" ]] || return 1
    [[ -n "${dots}" ]] || return 1

    dir="$(cd -- "$(dirname -- "${file}")" && pwd -P)" || return 1

    case "${dots}" in
        .)
            printf '%s\n' "${dir}"
            return 0
        ;;
        *)
            (( ${#dots} % 2 == 0 )) || return 1
            up=$(( ${#dots} / 2 ))
        ;;
    esac

    for (( i = 0; i < up; i++ )); do

        if [[ "${dir}" == "/" ]]; then
            break
        fi

        dir="${dir%/*}"
        [[ -n "${dir}" ]] || dir="/"

    done

    printf '%s\n' "${dir}"

}
find_file () {

    local root="${1:-}" rel="${2:-}" file=""
    local -a possible=()

    [[ -n "${root}" && -d "${root}" ]] || return 1
    [[ -n "${rel}" ]] || return 1

    rel="${rel%.sh}"

    possible=(
        "${root%/}/${rel}"
        "${root%/}/${rel}.sh"
        "${root%/}/${rel}.bash"
        "${root%/}/${rel}/mod.sh"
        "${root%/}/${rel}/mod.bash"
        "${root%/}/${rel}/index.sh"
        "${root%/}/${rel}/index.bash"
    )

    for file in "${possible[@]}"; do

        [[ -f "${file}" ]] || continue

        to_realpath "${file}"
        return 0

    done

    return 1

}
load_source () {

    local mod="${1:-}" from="${2:-${ENTRY_FILE:-}}" rel="" file="" root="" dots="" rest="" entry="" entry_dir=""

    [[ -n "${mod}" ]] || die "missing module name"
    [[ -n "${from}" && -f "${from}" ]] || die "invalid source file: ${from}"
    [[ -n "${ENTRY_FILE:-}" && -f "${ENTRY_FILE}" ]] || die "invalid entry file: ${ENTRY_FILE:-}"

    from="$(to_realpath "${from}")"
    entry="$(to_realpath "${ENTRY_FILE}")"
    entry_dir="$(cd -- "$(dirname -- "${entry}")" && pwd -P)" || die "invalid entry dir"

    case "${mod}" in
        .*::*)

            dots="${mod%%::*}"
            rest="${mod#*::}"
            rel="${rest//::/\/}"

            root="$(to_relative "${from}" "${dots}")" || die "invalid relative module: ${mod}"
            file="$(find_file "${root}" "${rel}" 2>/dev/null || true)"

            [[ -n "${file}" ]] || { load_std "${mod}" && return 0; }
            [[ -n "${file}" ]] || die "relative module not found: ${mod} from ${from}"

            printf '%s\n' "${file}"

        ;;
        *)

            rel="${mod//::/\/}"
            file="$(find_file "${entry_dir}" "${rel}" 2>/dev/null || true)"

            [[ -n "${file}" ]] || { load_std "${mod}" && return 0; }
            [[ -n "${file}" ]] || die "module not found: ${mod}"

            printf '%s\n' "${file}"

        ;;
    esac

}
extract_mods () {

    local file="${1:-}" entry="" state="" line="" mod="" dep=""

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"
    [[ -n "${ENTRY_FILE:-}" && -f "${ENTRY_FILE}" ]] || die "invalid entry file: ${ENTRY_FILE:-}"

    file="$(to_realpath "${file}")"
    entry="$(to_realpath "${ENTRY_FILE}")"

    state="${APP_MODS[${file}]:-}"

    [[ "${state}" == "loaded" ]] && return 0
    [[ "${state}" != "loading" ]] || die "circular module import: ${file}"

    APP_MODS["${file}"]="loading"

    while IFS= read -r line || [[ -n "${line}" ]]; do

        mod="$(match_use "${line}" 2>/dev/null || true)"
        [[ -n "${mod}" ]] || continue

        dep="$(load_source "${mod}" "${file}")" || die "unable to load module: ${mod}"
        [[ -n "${dep}" ]] && extract_mods "${dep}"

    done < "${file}" || die "unable to read file: ${file}"

    APP_MODS["${file}"]="loaded"

    [[ "${file}" == "${entry}" ]] || APP_SRCS+=( "${file}" )

}

std_name () {

    local mod="${1:-}" name=""

    [[ -n "${mod}" ]] || return 1

    case "${mod}" in
        std::*) name="${mod#std::}" ;;
        *)     name="${mod}" ;;
    esac

    [[ -n "${name}" ]] || return 1
    [[ "${name}" != *::* ]] || return 1

    printf '%s\n' "${name}"

}
std_file () {

    local name="${1:-}" real="" file=""

    [[ -n "${name}" ]] || return 1
    [[ -n "${APP_STD_LIB[${name}]:-}" ]] || return 1
    [[ -n "${STD_DIR:-}" ]] || return 1

    real="${APP_STD_LIB[${name}]}"
    file="${STD_DIR%/}/${real}.sh"

    [[ -f "${file}" ]] || return 1

    to_realpath "${file}"

}
register_std () {

    local mod="${1:-}" name="" deps="" dep="" file="" state=""
    local -a items=()

    name="$(std_name "${mod}")" || die "invalid std module: ${mod}"
    [[ -n "${APP_STD_LIB[${name}]:-}" ]] || die "unknown std module: ${name}"

    state="${APP_STD_STATE[${name}]:-}"

    [[ "${state}" == "loaded" ]] && return 0
    [[ "${state}" != "loading" ]] || die "circular std dependency: ${name}"

    APP_STD_STATE["${name}"]="loading"

    deps="${APP_STD_DEPS[${name}]:-}"

    if [[ -n "${deps}" ]]; then

        IFS=',' read -r -a items <<< "${deps}"

        for dep in "${items[@]}"; do

            dep="${dep//[[:blank:]]/}"
            [[ -n "${dep}" ]] || continue

            register_std "${dep}"

        done

    fi

    file="$(std_file "${name}")" || die "std file not found: ${name}"

    APP_STD_STATE["${name}"]="loaded"
    APP_STDS+=( "${file}" )

}
register_std_basic () {

    local name=""

    for name in "${APP_STD_BASIC[@]}"; do
        register_std "${name}"
    done

}


match_test () {

    local file="${1:-}" line="" fn="" mark=0 probe="" flag_pattern="" func_pattern=""

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"

    flag_pattern="^#{1,2}@?(\[\[test\]\]|\[test\]|test)$"
    func_pattern="^[[:space:]]*(function[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\)[[:space:]]*(\{)?[[:space:]]*([#].*)?$"

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"
        probe="${line}"
        probe="${probe//[[:blank:]]/}"
        probe="${probe,,}"

        if [[ "${probe}" =~ ${flag_pattern} ]]; then

            mark=1
            continue

        fi

        if [[ "${line}" =~ ${func_pattern} ]]; then

            fn="${BASH_REMATCH[2]}"

            if (( mark )) || [[ "${fn}" == test_* || "${fn}" == *_test ]]; then
                printf '%s\n' "${fn}"
            fi

            mark=0
            continue

        fi

        [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue

        mark=0

    done < "${file}" || die "unable to read file: ${file}"

}
verify_entry () {

    local file="${1:-}" line="" entry="${APP_ENTRY_FN:-main}" escaped=""

    [[ -n "${file}" && -f "${file}" ]] || die "entry file not found: ${file}"
    [[ "${entry}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "invalid entry function: ${entry}"

    escaped="${entry}"

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"

        [[ "${line}" =~ ^[[:space:]]*(function[[:space:]]+)?${escaped}[[:space:]]*\(\)[[:space:]]*(\{)?[[:space:]]*([#].*)?$ ]] && return 0

    done < "${file}" || die "unable to read file: ${file}"

    die "missing ${entry} function in: ${file}"

}
extract_tests () {

    local file="" fn=""
    local -A seen=() loaded=()

    for file in "$@"; do

        [[ -n "${file}" && -f "${file}" ]] || continue

        file="$(to_realpath "${file}")"

        [[ -z "${loaded[${file}]:-}" ]] || continue
        loaded["${file}"]=1

        while IFS= read -r fn || [[ -n "${fn}" ]]; do

            [[ -n "${fn}" ]] || continue
            [[ -z "${seen[${fn}]:-}" ]] || continue

            seen["${fn}"]=1
            APP_TESTS+=( "${fn}" )

        done < <(match_test "${file}") || die "unable to extract tests from: ${file}"

    done

}
extract () {

    local entry=""

    APP_MODS=()
    APP_STD_MODS=()

    APP_SRCS=()
    APP_STDS=()
    APP_TESTS=()

    [[ -n "${ENTRY_FILE:-}" && -f "${ENTRY_FILE}" ]] || die "invalid entry file: ${ENTRY_FILE:-}"
    [[ -n "${STD_DIR:-}" && -d "${STD_DIR}" ]] || die "invalid std dir: ${STD_DIR:-}"

    entry="$(to_realpath "${ENTRY_FILE}")"
    ENTRY_FILE="${entry}"

    verify_entry "${ENTRY_FILE}"
    extract_mods "${ENTRY_FILE}" "${ENTRY_FILE}"
    extract_tests "${APP_STDS[@]}" "${APP_SRCS[@]}" "${ENTRY_FILE}"

}
