
__inner_trace_path__ () {

    local file="${1:-}" out=""

    [[ -n "${file}" ]] || return 1

    if command -v realpath >/dev/null 2>&1; then
        realpath -- "${file}" 2>/dev/null && return 0
    fi

    if command -v readlink >/dev/null 2>&1; then

        out="$(readlink -f -- "${file}" 2>/dev/null || true)"

        [[ -n "${out}" ]] && {
            printf '%s\n' "${out}"
            return 0
        }

    fi

    printf '%s\n' "${file}"

}
__inner_trace_parse_error__ () {

    local text="${1:-}" prefix="" rest="" line="" msg="" off=0

    [[ -n "${text}" ]] || return 1
    [[ "${text}" == *": line "*": "* ]] || return 1

    prefix="${text%%: line *}"
    off=$(( ${#prefix} + 7 ))
    rest="${text:${off}}"

    line="${rest%%: *}"
    msg="${rest#${line}: }"

    [[ -n "${prefix}" ]] || return 1
    [[ "${line}" =~ ^[0-9]+$ ]] || return 1

    printf '%s\t%s\t%s\n' "${prefix}" "${line}" "${msg}"

}
__inner_trace_lookup__ () {

    local line="${1:-0}" item="" start="" end="" src_file=""

    [[ "${line}" =~ ^[0-9]+$ ]] || return 1

    for item in "${__INNER_TRACE_SOURCE__[@]}"; do

        IFS=$'\t' read -r start end src_file <<< "${item}"

        [[ "${start}" =~ ^[0-9]+$ ]] || continue
        [[ "${end}"   =~ ^[0-9]+$ ]] || continue
        [[ -n "${src_file}" ]] || continue

        if (( line >= start && line <= end )); then
            printf '%s\t%s\t%s\n' "${src_file}" "${start}" "${end}"
            return 0
        fi

    done

    return 1

}
__inner_trace_best_line__ () {

    local src_file="${1:-}" final_file="${2:-}" final_line="${3:-0}" final_start="${4:-0}" final_end="${5:-0}"
    local fallback=1 best=""

    [[ -f "${src_file}"  ]] || return 1
    [[ -f "${final_file}" ]] || return 1
    [[ "${final_line}"  =~ ^[0-9]+$ ]] || return 1
    [[ "${final_start}" =~ ^[0-9]+$ ]] || return 1
    [[ "${final_end}"   =~ ^[0-9]+$ ]] || return 1

    fallback=$(( final_line - final_start + 1 ))
    (( fallback >= 1 )) || fallback=1

    best="$(
        awk \
            -v src_file="${src_file}" \
            -v final_file="${final_file}" \
            -v final_line="${final_line}" \
            -v final_start="${final_start}" \
            -v final_end="${final_end}" \
            -v fallback="${fallback}" '

            function trim ( s ) {
                sub(/^[[:space:]]+/, "", s)
                sub(/[[:space:]]+$/, "", s)
                return s
            }
            function norm ( s ) {
                gsub(/\r/, "", s)
                s = trim(s)

                if (s == "") return ""
                if (s ~ /^#/) return ""

                sub(/[[:space:]]+#.*$/, "", s)
                s = trim(s)

                gsub(/[[:space:]]+/, " ", s)
                return s
            }
            function suffix ( s, a, n ) {
                s = norm(s)

                if (s == "") return ""

                n = split(s, a, /[[:space:]]+/)
                return a[n]
            }
            function abs ( x ) {
                return x < 0 ? -x : x
            }
            function prev_meaningful ( arr, from, min, need,    i, n ) {
                n = 0

                for (i = from - 1; i >= min; i--) {
                    if (arr[i] == "") continue

                    n++
                    if (n == need) return arr[i]
                }

                return ""
            }
            function next_meaningful ( arr, from, max, need,    i, n ) {
                n = 0

                for (i = from + 1; i <= max; i++) {
                    if (arr[i] == "") continue

                    n++
                    if (n == need) return arr[i]
                }

                return ""
            }
            BEGIN {

                final_count = 0
                final_idx = 0
                ctx_idx = 0

                while ((getline raw < final_file) > 0) {

                    final_count++

                    if (final_count < final_start || final_count > final_end) {
                        continue
                    }

                    final_idx++
                    final_norm[final_idx] = norm(raw)
                    final_suf[final_idx]  = suffix(raw)

                    if (final_count == final_line) {
                        ctx_idx = final_idx
                    }

                }

                close(final_file)

                if (ctx_idx < 1) {
                    ctx_idx = final_line - final_start + 1
                }

                ctx_norm[0]  = final_norm[ctx_idx]
                ctx_suf[0]   = final_suf[ctx_idx]

                ctx_norm[-1] = prev_meaningful(final_norm, ctx_idx, 1, 1)
                ctx_norm[-2] = prev_meaningful(final_norm, ctx_idx, 1, 2)
                ctx_norm[1]  = next_meaningful(final_norm, ctx_idx, final_idx, 1)
                ctx_norm[2]  = next_meaningful(final_norm, ctx_idx, final_idx, 2)

                ctx_suf[-1] = prev_meaningful(final_suf, ctx_idx, 1, 1)
                ctx_suf[-2] = prev_meaningful(final_suf, ctx_idx, 1, 2)
                ctx_suf[1]  = next_meaningful(final_suf, ctx_idx, final_idx, 1)
                ctx_suf[2]  = next_meaningful(final_suf, ctx_idx, final_idx, 2)

                src_count = 0

                while ((getline raw < src_file) > 0) {
                    src_norm[++src_count] = norm(raw)
                    src_suf[src_count]    = suffix(raw)
                }

                close(src_file)

                best_score = -1
                best_line  = fallback
                best_dist  = 2147483647

                for (i = 1; i <= src_count; i++) {

                    score = 0
                    dist  = abs(i - fallback)

                    src_prev_norm_1 = prev_meaningful(src_norm, i, 1, 1)
                    src_prev_norm_2 = prev_meaningful(src_norm, i, 1, 2)
                    src_next_norm_1 = next_meaningful(src_norm, i, src_count, 1)
                    src_next_norm_2 = next_meaningful(src_norm, i, src_count, 2)

                    src_prev_suf_1 = prev_meaningful(src_suf, i, 1, 1)
                    src_prev_suf_2 = prev_meaningful(src_suf, i, 1, 2)
                    src_next_suf_1 = next_meaningful(src_suf, i, src_count, 1)
                    src_next_suf_2 = next_meaningful(src_suf, i, src_count, 2)

                    if (ctx_suf[0]  != "" && src_suf[i]  == ctx_suf[0])  score += 40
                    if (ctx_norm[0] != "" && src_norm[i] == ctx_norm[0]) score += 100

                    if (ctx_suf[-1] != "" && src_prev_suf_1 == ctx_suf[-1]) score += 14
                    if (ctx_suf[1]  != "" && src_next_suf_1 == ctx_suf[1])  score += 14
                    if (ctx_suf[-2] != "" && src_prev_suf_2 == ctx_suf[-2]) score += 7
                    if (ctx_suf[2]  != "" && src_next_suf_2 == ctx_suf[2])  score += 7

                    if (ctx_norm[-1] != "" && src_prev_norm_1 == ctx_norm[-1]) score += 22
                    if (ctx_norm[1]  != "" && src_next_norm_1 == ctx_norm[1])  score += 22
                    if (ctx_norm[-2] != "" && src_prev_norm_2 == ctx_norm[-2]) score += 10
                    if (ctx_norm[2]  != "" && src_next_norm_2 == ctx_norm[2])  score += 10

                    if (src_norm[i] == "" && ctx_norm[0] != "") {
                        score = -1
                    }

                    if (score > best_score || (score == best_score && dist < best_dist)) {
                        best_score = score
                        best_line  = i
                        best_dist  = dist
                    }

                }

                if (best_score <= 0) {
                    best_line = fallback
                }
                if (best_line < 1) {
                    best_line = 1
                }

                print best_line
            }
        '
    )" || true

    [[ "${best}" =~ ^[0-9]+$ ]] || best="${fallback}"
    (( best >= 1 )) || best=1

    printf '%s\n' "${best}"

}
__inner_trace_map_text__ () {

    local text="${1:-}" file="" line="" msg=""
    local src_file="" final_start="" final_end="" src_line=""

    [[ -n "${text}" ]] || return 1

    IFS=$'\t' read -r file line msg < <(__inner_trace_parse_error__ "${text}") || return 1
    [[ "${file}" == "${__INNER_TRACE_FILE__}" ]] || return 1

    IFS=$'\t' read -r src_file final_start final_end < <(__inner_trace_lookup__ "${line}") || return 1
    src_line="$(__inner_trace_best_line__ "${src_file}" "${__INNER_TRACE_FILE__}" "${line}" "${final_start}" "${final_end}")" || return 1

    printf '%s:%s: %s\n' "${src_file}" "${src_line}" "${msg}" >&3

}
__inner_trace_map_line__ () {

    local file="${1:-}" line="${2:-0}" msg="${3:-}"
    local src_file="" final_start="" final_end="" src_line=""

    [[ "${line}" =~ ^[0-9]+$ ]] || {
        printf '%s: line %s: %s\n' "${file}" "${line}" "${msg}" >&3
        return 1
    }
    IFS=$'\t' read -r src_file final_start final_end < <(__inner_trace_lookup__ "${line}") || {
        printf '%s: line %s: %s\n' "${file}" "${line}" "${msg}" >&3
        return 1
    }
    src_line="$(__inner_trace_best_line__ "${src_file}" "${__INNER_TRACE_FILE__}" "${line}" "${final_start}" "${final_end}")" || {
        printf '%s: line %s: %s\n' "${file}" "${line}" "${msg}" >&3
        return 1
    }

    printf '%s:%s: %s\n' "${src_file}" "${src_line}" "${msg}" >&3

}
__inner_trace_stderr__ () {

    local line=""

    while IFS= read -r line || [[ -n "${line}" ]]; do

        [[ "${line}" == "__INNER_TRACE_EOF__" ]] && break

        if [[ "${line}" == "${__INNER_TRACE_FILE__}: line "* ]]; then
            __inner_trace_map_text__ "${line}" || printf '%s\n' "${line}" >&3
            continue
        fi

        printf '%s\n' "${line}" >&3

    done

}
__inner_trace_on_err__ () {

    local rc="${1:-1}" line="${2:-0}" cmd="${3:-}"

    case "${rc}" in
        0|126|127) return 0 ;;
    esac

    [[ "${__INNER_TRACE_INIT__:-0}" == "1" ]] || return 0
    __inner_trace_map_line__ "${__INNER_TRACE_FILE__}" "${line}" "${cmd}: exit ${rc}" || true

}
__inner_trace_cleanup__ () {

    local rc="${1:-0}"

    trap - ERR EXIT INT TERM HUP

    [[ "${__INNER_TRACE_INIT__:-0}" == "1" ]] || return 0

    printf '%s\n' '__INNER_TRACE_EOF__' >&2 || true

    exec 2>&3 || true
    exec 9>&- || true
    exec 8>&- || true
    exec 3>&- || true

    [[ -n "${__INNER_TRACE_PID__:-}" ]] && wait "${__INNER_TRACE_PID__}" 2>/dev/null || true

    if [[ -n "${__INNER_TRACE_DIR__:-}" ]]; then rm -rf -- "${__INNER_TRACE_DIR__}" 2>/dev/null || true
    elif [[ -n "${__INNER_TRACE_FIFO__:-}" ]]; then rm -f -- "${__INNER_TRACE_FIFO__}" 2>/dev/null || true
    fi

    __INNER_TRACE_INIT__=0
    __INNER_TRACE_FILE__=""
    __INNER_TRACE_DIR__=""
    __INNER_TRACE_FIFO__=""
    __INNER_TRACE_PID__=""

    return "${rc}"

}
__inner_trace_on_signal__ () {

    local sig="${1:-TERM}" code=143

    case "${sig}" in
        HUP)  code=129 ;;
        INT)  code=130 ;;
        TERM) code=143 ;;
    esac

    __inner_trace_cleanup__ "${code}" || true
    exit "${code}"

}
__inner_trace__ () {

    local file=""

    [[ "${__INNER_TRACE_INIT__:-0}" == "1" ]] && return 0

    file="${BASH_SOURCE[0]:-${0}}"
    file="$(__inner_trace_path__ "${file}")"

    __INNER_TRACE_FILE__="${file}"
    __INNER_TRACE_DIR__="$(mktemp -d "${TMPDIR:-/tmp}/inner-trace.XXXXXX")"
    __INNER_TRACE_FIFO__="${__INNER_TRACE_DIR__}/stderr.fifo"
    __INNER_TRACE_PID__=""
    __INNER_TRACE_INIT__=0

    mkfifo -- "${__INNER_TRACE_FIFO__}" || {
        rm -rf -- "${__INNER_TRACE_DIR__}" 2>/dev/null || true
        __INNER_TRACE_DIR__=""
        __INNER_TRACE_FIFO__=""
        exit 1
    }

    exec 3>&2
    exec 8<> "${__INNER_TRACE_FIFO__}"
    exec 9>  "${__INNER_TRACE_FIFO__}"

    __inner_trace_stderr__ <&8 &
    __INNER_TRACE_PID__=$!

    exec 2>&9
    __INNER_TRACE_INIT__=1

    trap 'rc=$?; __inner_trace_on_err__ "${rc}" "${LINENO}" "${BASH_COMMAND}"' ERR
    trap 'rc=$?; __inner_trace_cleanup__ "${rc}"' EXIT
    trap '__inner_trace_on_signal__ HUP' HUP
    trap '__inner_trace_on_signal__ INT' INT
    trap '__inner_trace_on_signal__ TERM' TERM

}
