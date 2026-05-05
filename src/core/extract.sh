
match_use () {

    local line="${1:-}" mod=""

    line="${line%$'\r'}"

    [[ "${line}" =~ ^[[:space:]]*use[[:space:]]+([A-Za-z_][A-Za-z0-9_.-]*(::[A-Za-z_][A-Za-z0-9_.-]*)*)[[:space:]]*([#].*)?$ ]] || return 1

    mod="${BASH_REMATCH[1]}"

    [[ "${mod}" != *..* ]] || return 1
    [[ "${mod}" != *--* ]] || return 1
    [[ "${mod}" != *.-* ]] || return 1
    [[ "${mod}" != *-. ]] || return 1

    printf '%s\n' "${mod}"

}
match_test () {

    local file="${1:-}" line="" fn="" mark=0 probe=""

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"
        probe="${line}"
        probe="${probe//[[:space:]]/}"
        probe="${probe,,}"

        if [[ "${probe}" =~ ^(##?|#\#)@?(\[\[test\]\]|\[test\]|test)$ ]]; then
            mark=1
            continue
        fi

        if [[ "${line}" =~ ^[[:space:]]*(function[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{ ]]; then

            fn="${BASH_REMATCH[2]}"

            if (( mark )) || [[ "${fn}" == test_* ]]; then
                printf '%s\n' "${fn}"
            fi

            mark=0
            continue

        fi

        [[ "${line}" =~ ^[[:space:]]*$ ]] && continue

        mark=0

    done < "${file}" || die "unable to read file: ${file}"

}

load_source () {

    local mod="${1:-}" root="" path="" file=""

    [[ -n "${mod}" ]] || die "missing module name"

    case "${mod}" in
        std::*)
            root="${SOURCE_DIR%/}/std"
            path="${root}/${mod#std::}"
            path="${path//::/\/}"
        ;;
        *)
            root="${ENTRY_FILE%/*}"
            path="${root}/${mod//::/\/}"
        ;;
    esac

    file="${path%.sh}.sh"
    [[ -f "${file}" ]] || file="${path%.sh}/mod.sh"
    [[ -f "${file}" ]] || die "module not found: ${mod}"

    printf '%s\n' "${file}"

}
verify_entry () {

    local file="${1:-}" line="" entry="${APP_ENTRY_FN:-main}"

    [[ -n "${file}" && -f "${file}" ]] || die "entry file not found: ${file}"

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"

        [[ "${line}" =~ ^[[:space:]]*(function[[:space:]]+)?${entry}[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*([#].*)?$ ]] && return 0

    done < "${file}" || die "unable to read file: ${file}"

    die "missing ${entry} function in: ${file}"

}

extract_mods () {

    local file="${1:-}" entry="${2:-}" line="" mod="" dep=""

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"

    [[ -n "${APP_MODS[${file}]:-}" ]] && return 0
    APP_MODS["${file}"]="loaded"

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"

        mod="$(match_use "${line}")" || continue
        dep="$(load_source "${mod}")" || return 1

        extract_mods "${dep}" "${entry}"

    done < "${file}" || die "unable to read file: ${file}"

    [[ "${file}" == "${entry}" ]] || APP_SRCS+=( "${file}" )

}
extract_tests () {

    local file="" fn=""
    local -A seen=() loaded=()

    for file in "$@"; do

        [[ -f "${file}" ]] || continue
        [[ -z "${loaded[${file}]:-}" ]] || continue

        loaded["${file}"]=1

        while IFS= read -r fn || [[ -n "${fn}" ]]; do

            [[ -n "${fn}" ]] || continue
            [[ -z "${seen[${fn}]:-}" ]] || continue

            seen["${fn}"]=1
            APP_TESTS+=( "${fn}" )

        done < <(match_test "${file}") || return 1

    done

}

extract () {

    APP_MODS=()
    APP_SRCS=()
    APP_TESTS=()

    [[ -n "${ENTRY_FILE}" && -f "${ENTRY_FILE}" ]] || die "invalid entry file: ${ENTRY_FILE}"

    verify_entry  "${ENTRY_FILE}"
    extract_mods  "${ENTRY_FILE}" "${ENTRY_FILE}"
    extract_tests "${APP_SRCS[@]}" "${ENTRY_FILE}"

}
