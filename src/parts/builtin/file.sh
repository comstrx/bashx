
file::valid () {

    path::valid "$@"

}
file::exists () {

    path::is_file "$@"

}
file::missing () {

    ! path::is_file "$@"

}
file::empty () {

    path::is_file "$@" || return 0
    path::empty "$@"

}
file::filled () {

    path::is_file "$@" || return 1
    path::filled "$@"

}
file::readable () {

    path::is_file "$@" || return 1
    path::readable "$@"

}
file::writable () {

    path::is_file "$@" || return 1
    path::writable "$@"

}
file::executable () {

    path::is_file "$@" || return 1
    path::executable "$@"

}

file::name () {

    path::basename "$@"

}
file::dir () {

    path::parentname "$@"

}
file::dirname () {

    path::dirname "$@"

}
file::drive () {

    path::drive "$@"

}
file::stem () {

    path::stem "$@"

}
file::ext () {

    path::ext "$@"

}
file::dotext () {

    path::dotext "$@"

}
file::setname () {

    path::setname "$@"

}
file::setstem () {

    path::setstem "$@"

}
file::setext () {

    path::setext "$@"

}

file::type () {

    path::is_file "$@" || return 1
    printf 'file'

}
file::size () {

    path::is_file "$@" || return 1
    path::size "$@"

}
file::mtime () {

    path::is_file "$@" || return 1
    path::mtime "$@"

}
file::atime () {

    path::is_file "$@" || return 1
    path::atime "$@"

}
file::ctime () {

    path::is_file "$@" || return 1
    path::ctime "$@"

}
file::age () {

    path::is_file "$@" || return 1
    path::age "$@"

}
file::owner () {

    path::is_file "$@" || return 1
    path::owner "$@"

}
file::group () {

    path::is_file "$@" || return 1
    path::group "$@"

}
file::mode () {

    path::is_file "$@" || return 1
    path::mode "$@"

}
file::inode () {

    path::is_file "$@" || return 1
    path::inode "$@"

}

file::new () {

    path::touch "$@"

}
file::ensure () {

    path::touch "$@"

}
file::ensure_dir () {

    path::mkparent "$@"

}
file::remove () {

    path::is_file "$@" || return 1
    path::remove "$@"

}
file::clear () {

    path::is_file "$@" || return 1
    path::clear "$@"

}
file::rename () {

    path::is_file "$@" || return 1
    path::rename "$@"

}
file::move () {

    file::rename "$@"

}
file::copy () {

    path::is_file "$@" || return 1
    path::copy "$@"

}
file::link () {

    path::is_file "${1:-}" || return 1
    path::link "$@"

}
file::symlink () {

    path::is_file "${1:-}" || return 1
    path::symlink "$@"

}
file::readlink () {

    file::is_link "$@" || return 1
    path::readlink "$@"

}

file::chmod () {

    path::is_file "$@" || return 1
    path::chmod "$@"

}
file::mktemp () {

    path::mktemp_file "$@"

}
file::mktemp_near () {

    path::mktemp_near "$@"

}

file::hash () {

    path::is_file "$@" || return 1
    path::hash "$@"

}
file::checksum () {

    path::is_file "$@" || return 1
    path::checksum "$@"

}
file::snapshot () {

    path::is_file "$@" || return 1
    path::snapshot "$@"

}
file::strip () {

    path::is_file "$@" || return 1
    path::strip "$@"

}
file::archive () {

    path::is_file "$@" || return 1
    path::archive "$@"

}
file::backup () {

    path::is_file "$@" || return 1
    path::backup "$@"

}
file::extract () {

    path::extract "$@"

}
file::sync () {

    path::is_file "$@" || return 1
    path::sync "$@"

}
file::watch () {

    path::is_file "$@" || return 1
    path::watch "$@"

}

file::trylock () {

    path::trylock "$@"

}
file::lock () {

    path::lock "$@"

}
file::unlock () {

    path::unlock "$@"

}
file::locked () {

    path::locked "$@"

}
file::with_lock () {

    path::with_lock "$@"

}

file::has_ext () {

    path::has_ext "$@"

}
file::is_link () {

    path::is_link "$@" || return 1
    path::is_file "$@"

}
file::is_hidden () {

    path::is_file "$@" || return 1
    path::is_hidden "$@"

}
file::is_text () {

    local p="${1:-}" v=""

    path::is_file "${p}" || return 1

    [[ -s "${p}" ]] || return 0

    if sys::has file; then

        v="$(file -b --mime-encoding "${p}" 2>/dev/null || true)"

        case "${v}" in
            binary) return 1 ;;
            "") ;;
            *) return 0 ;;
        esac

    fi
    if sys::has grep; then
        LC_ALL=C grep -Iq -- . "${p}" 2>/dev/null && return 0
    fi

    return 1

}
file::is_binary () {

    local p="${1:-}"

    path::is_file "${p}" || return 1
    file::is_text "${p}" && return 1

    return 0

}
file::mime () {

    local p="${1:-}" v=""

    path::is_file "${p}" || return 1

    if sys::has file; then

        v="$(file -b --mime-type "${p}" 2>/dev/null | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
file::kind () {

    local p="${1:-}" ext=""

    path::valid "${p}" || return 1

    ext="$(path::ext "${p}" 2>/dev/null || true)"
    ext="${ext,,}"

    case "${ext}" in
        sh|bash|zsh|fish)                    printf 'script';       return 0 ;;
        py|pyw)                              printf 'python';       return 0 ;;
        js|mjs|cjs|jsx|ts|tsx)               printf 'javascript';   return 0 ;;
        rs)                                  printf 'rust';         return 0 ;;
        go)                                  printf 'go';           return 0 ;;
        c|h)                                 printf 'c';            return 0 ;;
        cpp|cxx|cc|hpp|hxx|hh)               printf 'cpp';          return 0 ;;
        java|kt|scala)                       printf 'jvm';          return 0 ;;
        rb)                                  printf 'ruby';         return 0 ;;
        php)                                 printf 'php';          return 0 ;;
        lua)                                 printf 'lua';          return 0 ;;
        r)                                   printf 'r';            return 0 ;;
        json|yaml|yml|toml|ini|env|conf|cfg) printf 'config';       return 0 ;;
        xml|html|htm|svg)                    printf 'markup';       return 0 ;;
        css|scss|sass|less)                  printf 'style';        return 0 ;;
        md|rst|adoc|txt|log)                 printf 'text';         return 0 ;;
        png|jpg|jpeg|gif|webp|bmp|ico|tiff)  printf 'image';        return 0 ;;
        mp3|wav|flac|ogg|m4a|aac)            printf 'audio';        return 0 ;;
        mp4|mkv|avi|mov|webm|wmv)            printf 'video';        return 0 ;;
        zip|tar|gz|bz2|xz|zst|7z|rar)        printf 'archive';      return 0 ;;
        pdf)                                 printf 'pdf';          return 0 ;;
        doc|docx|odt|rtf)                    printf 'document';     return 0 ;;
        xls|xlsx|ods|csv|tsv)                printf 'spreadsheet';  return 0 ;;
        ppt|pptx|odp)                        printf 'presentation'; return 0 ;;
        sql|db|sqlite|sqlite3)               printf 'database';     return 0 ;;
        exe|dll|so|dylib|a|lib|o|obj)        printf 'binary';       return 0 ;;
    esac

    path::is_file "${p}" || { printf 'unknown'; return 0; }

    if file::is_binary "${p}"; then printf 'binary'
    else printf 'text'
    fi

}

file::write () {

    local p="${1:-}" content="${2:-}"

    file::ensure_dir "${p}" || return 1
    printf '%s' "${content}" > "${p}" 2>/dev/null

}
file::writeln () {

    local p="${1:-}" content="${2:-}"

    file::ensure_dir "${p}" || return 1
    printf '%s\n' "${content}" > "${p}" 2>/dev/null

}
file::write_lines () {

    local p="${1:-}"

    file::ensure_dir "${p}" || return 1
    shift || true

    if (( $# > 0 )); then printf '%s\n' "$@" > "${p}" 2>/dev/null
    else : > "${p}" 2>/dev/null
    fi

}
file::write_stdin () {

    local p="${1:-}"

    file::ensure_dir "${p}" || return 1
    cat > "${p}" 2>/dev/null

}
file::write_atomic () {

    local p="${1:-}" content="${2:-}" tmp="" mode="" rc=0

    file::ensure_dir "${p}" || return 1
    file::exists "${p}" && { mode="$(file::mode "${p}" 2>/dev/null || true)"; }

    tmp="$(file::mktemp_near "${p}")" || return 1

    printf '%s' "${content}" > "${tmp}" 2>/dev/null
    rc=$?

    (( rc != 0 )) && { rm -f -- "${tmp}" 2>/dev/null; return "${rc}"; }
    [[ -n "${mode}" ]] && chmod -- "${mode}" "${tmp}" 2>/dev/null || true

    mv -f -- "${tmp}" "${p}" 2>/dev/null
    rc=$?

    (( rc != 0 )) && rm -f -- "${tmp}" 2>/dev/null
    return "${rc}"

}

file::append () {

    local p="${1:-}" content="${2:-}"

    file::ensure_dir "${p}" || return 1
    printf '%s' "${content}" >> "${p}" 2>/dev/null

}
file::appendln () {

    local p="${1:-}" content="${2:-}"

    file::ensure_dir "${p}" || return 1
    printf '%s\n' "${content}" >> "${p}" 2>/dev/null

}
file::append_lines () {

    local p="${1:-}"

    file::ensure_dir "${p}" || return 1

    shift || true
    (( $# > 0 )) || return 0

    printf '%s\n' "$@" >> "${p}" 2>/dev/null

}
file::append_stdin () {

    local p="${1:-}"

    file::ensure_dir "${p}" || return 1
    cat >> "${p}" 2>/dev/null

}
file::append_unique () {

    local p="${1:-}" line="${2:-}"

    [[ -n "${line}" ]] || return 1

    file::ensure_dir "${p}" || return 1
    file::exists "${p}" && sys::has grep && grep -Fxq -- "${line}" "${p}" 2>/dev/null && return 0

    printf '%s\n' "${line}" >> "${p}" 2>/dev/null

}
file::prepend () {

    local p="${1:-}" content="${2:-}" tmp=""

    file::ensure_dir "${p}" || return 1
    file::exists "${p}" || { file::write "${p}" "${content}"; return; }

    tmp="$(file::mktemp_near "${p}")" || return 1

    {
        printf '%s' "${content}"
        cat -- "${p}"
    } > "${tmp}" 2>/dev/null || { rm -f -- "${tmp}" 2>/dev/null; return 1; }

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::prependln () {

    local p="${1:-}" content="${2:-}" tmp=""

    file::ensure_dir "${p}" || return 1
    file::exists "${p}" || { file::writeln "${p}" "${content}"; return; }

    tmp="$(file::mktemp_near "${p}")" || return 1

    {
        printf '%s\n' "${content}"
        cat -- "${p}"
    } > "${tmp}" 2>/dev/null || { rm -f -- "${tmp}" 2>/dev/null; return 1; }

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::prepend_lines () {

    local p="${1:-}" tmp=""

    file::ensure_dir "${p}" || return 1
    shift || true

    file::exists "${p}" || { file::write_lines "${p}" "$@"; return; }

    tmp="$(file::mktemp_near "${p}")" || return 1

    {
        (( $# > 0 )) && printf '%s\n' "$@"
        cat -- "${p}"
    } > "${tmp}" 2>/dev/null || { rm -f -- "${tmp}" 2>/dev/null; return 1; }

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::prepend_stdin () {

    local p="${1:-}" tmp=""

    file::ensure_dir "${p}" || return 1

    tmp="$(file::mktemp_near "${p}")" || return 1

    {
        cat
        file::exists "${p}" && cat -- "${p}"
    } > "${tmp}" 2>/dev/null || { rm -f -- "${tmp}" 2>/dev/null; return 1; }

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::prepend_unique () {

    local p="${1:-}" line="${2:-}" tmp=""

    [[ -n "${line}" ]] || return 1

    file::ensure_dir "${p}" || return 1
    file::exists "${p}" && sys::has grep && grep -Fxq -- "${line}" "${p}" 2>/dev/null && return 0

    tmp="$(file::mktemp_near "${p}")" || return 1

    {
        printf '%s\n' "${line}"
        file::exists "${p}" && cat -- "${p}"
    } > "${tmp}" 2>/dev/null || { rm -f -- "${tmp}" 2>/dev/null; return 1; }

    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::truncate () {

    local p="${1:-}" size="${2:-0}"

    file::exists "${p}" || return 1
    [[ "${size}" =~ ^[0-9]+$ ]] || return 1

    if (( size == 0 )); then
        : > "${p}" 2>/dev/null
        return
    fi
    if sys::has truncate; then
        truncate -s "${size}" -- "${p}" 2>/dev/null && return 0
    fi
    if sys::has dd; then
        dd if=/dev/null of="${p}" bs=1 count=0 seek="${size}" 2>/dev/null
        return
    fi

    return 1

}

file::read () {

    local p="${1:-}"

    path::is_file "${p}" || return 1
    path::readable "${p}" || return 1

    cat -- "${p}" 2>/dev/null

}
file::lines () {

    file::read "$@"

}
file::first_line () {

    local p="${1:-}" line=""

    file::readable "${p}" || return 1

    IFS= read -r line < "${p}" 2>/dev/null || true
    printf '%s' "${line}"

}
file::last_line () {

    local p="${1:-}" line=""

    file::readable "${p}" || return 1

    sys::has tail && { tail -n 1 -- "${p}" 2>/dev/null; return; }
    while IFS= read -r line || [[ -n "${line}" ]]; do :; done < "${p}"

    printf '%s' "${line}"

}
file::line () {

    local p="${1:-}" n="${2:-1}"

    file::readable "${p}" || return 1

    [[ "${n}" =~ ^[0-9]+$ ]] || return 1
    (( n > 0 )) || return 1

    if sys::has sed; then sed -n "${n}p" -- "${p}" 2>/dev/null
    elif sys::has awk; then awk -v n="${n}" 'NR == n { print; exit }' < "${p}" 2>/dev/null
    else return 1
    fi

}
file::range () {

    local p="${1:-}" from="${2:-1}" to="${3:-}"

    file::readable "${p}" || return 1

    [[ "${from}" =~ ^[0-9]+$ ]] || return 1
    [[ -z "${to}" || "${to}" =~ ^[0-9]+$ ]] || return 1
    (( from > 0 )) || return 1

    if [[ -n "${to}" ]]; then

        (( to >= from )) || return 1

        if sys::has sed; then sed -n "${from},${to}p" -- "${p}" 2>/dev/null
        elif sys::has awk; then awk -v a="${from}" -v b="${to}" 'NR >= a && NR <= b; NR > b { exit }' < "${p}" 2>/dev/null
        else return 1
        fi

    else

        if sys::has sed; then sed -n "${from},\$p" -- "${p}" 2>/dev/null
        elif sys::has awk; then awk -v a="${from}" 'NR >= a' < "${p}" 2>/dev/null
        else return 1
        fi

    fi

}
file::head () {

    local p="${1:-}" n="${2:-10}"

    file::readable "${p}" || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    if sys::has head; then head -n "${n}" -- "${p}" 2>/dev/null
    elif sys::has awk; then awk -v n="${n}" 'NR <= n; NR > n { exit }' < "${p}" 2>/dev/null
    else return 1
    fi

}
file::tail () {

    local p="${1:-}" n="${2:-10}"

    file::readable "${p}" || return 1
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    if sys::has tail; then tail -n "${n}" -- "${p}" 2>/dev/null
    elif sys::has awk; then awk -v n="${n}" '{ buf[NR % n] = $0 } END { for ( i = NR - n + 1; i <= NR; i++ ) if ( i > 0 ) print buf[i % n] }' < "${p}" 2>/dev/null
    else return 1
    fi

}

file::grep () {

    local p="${1:-}" pattern="${2:-}"

    [[ -n "${pattern}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has grep || return 1

    grep -E -- "${pattern}" "${p}" 2>/dev/null

}
file::find () {

    local p="${1:-}" pattern="${2:-}" v=""

    [[ -n "${pattern}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has grep || return 1

    v="$(grep -nboE -- "${pattern}" "${p}" 2>/dev/null | head -n 1)"
    [[ -n "${v}" ]] || return 1

    printf '%s\n' "${v}"

}
file::find_line () {

    local p="${1:-}" pattern="${2:-}" v=""

    [[ -n "${pattern}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has grep || return 1

    v="$(grep -nE -- "${pattern}" "${p}" 2>/dev/null | head -n 1 | cut -d: -f1)"
    [[ "${v}" =~ ^[0-9]+$ ]] || return 1

    printf '%s\n' "${v}"

}
file::matches_count () {

    local p="${1:-}" pattern="${2:-}" v=""

    [[ -n "${pattern}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has grep || return 1

    v="$(grep -oE -- "${pattern}" "${p}" 2>/dev/null | wc -l | tr -d '[:space:]')"
    [[ "${v}" =~ ^[0-9]+$ ]] || v=0

    printf '%s\n' "${v}"

}
file::lines_count () {

    local p="${1:-}" n=0

    file::readable "${p}" || return 1

    if sys::has wc; then

        n="$(wc -l < "${p}" 2>/dev/null | tr -d '[:space:]')"
        [[ "${n}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${n}"; return 0; }

    fi

    while IFS= read -r _; do n=$(( n + 1 )); done < "${p}"

    printf '%s\n' "${n}"

}
file::words_count () {

    local p="${1:-}" n=""

    file::readable "${p}" || return 1
    sys::has wc || return 1

    n="$(wc -w < "${p}" 2>/dev/null | tr -d '[:space:]')"
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    printf '%s\n' "${n}"

}
file::contains () {

    local p="${1:-}" pattern="${2:-}" mode="${3:-regex}"

    [[ -n "${pattern}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has grep || return 1

    case "${mode}" in
        regex|re|"") grep -Eq -- "${pattern}" "${p}" 2>/dev/null ;;
        text|literal|fixed) grep -Fq -- "${pattern}" "${p}" 2>/dev/null ;;
        *) return 1 ;;
    esac

}
file::contains_line () {

    local p="${1:-}" pattern="${2:-}" mode="${3:-regex}"

    [[ -n "${pattern}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has grep || return 1

    case "${mode}" in
        regex|re|"") grep -Eq -- "^(${pattern})$" "${p}" 2>/dev/null ;;
        text|literal|fixed) grep -Fxq -- "${pattern}" "${p}" 2>/dev/null ;;
        *) return 1 ;;
    esac

}
file::starts_with () {

    local p="${1:-}" pattern="${2:-}" mode="${3:-regex}" first=""

    [[ -n "${pattern}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has grep || return 1

    first="$(file::first_line "${p}" 2>/dev/null || true)"

    case "${mode}" in
        regex|re|"") printf '%s\n' "${first}" | grep -Eq -- "^(${pattern})" 2>/dev/null ;;
        text|literal|fixed) [[ "${first}" == "${pattern}"* ]] ;;
        *) return 1 ;;
    esac

}
file::ends_with () {

    local p="${1:-}" pattern="${2:-}" mode="${3:-regex}" last=""

    [[ -n "${pattern}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has grep || return 1

    last="$(file::last_line "${p}" 2>/dev/null || true)"

    case "${mode}" in
        regex|re|"") printf '%s\n' "${last}" | grep -Eq -- "(${pattern})$" 2>/dev/null ;;
        text|literal|fixed) [[ "${last}" == *"${pattern}" ]] ;;
        *) return 1 ;;
    esac

}

file::replace () {

    local p="${1:-}" from="${2:-}" to="${3:-}" tmp="" esc_from="" esc_to="" rc=0

    [[ -n "${from}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has sed || return 1

    tmp="$(file::mktemp_near "${p}")" || return 1

    esc_from="$(printf '%s' "${from}" | sed -e 's/[]\/$*.^[]/\\&/g')"
    esc_to="$(printf '%s' "${to}" | sed -e 's/[\/&]/\\&/g')"

    sed "s/${esc_from}/${esc_to}/g" < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    (( rc != 0 )) && { rm -f -- "${tmp}" 2>/dev/null; return "${rc}"; }
    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::replace_line () {

    local p="${1:-}" n="${2:-}" content="${3:-}" tmp="" rc=0

    [[ "${n}" =~ ^[0-9]+$ ]] || return 1
    (( n > 0 )) || return 1

    file::readable "${p}" || return 1
    sys::has awk || return 1

    tmp="$(file::mktemp_near "${p}")" || return 1

    awk -v n="${n}" -v c="${content}" 'NR == n { print c; next } { print }' < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    (( rc != 0 )) && { rm -f -- "${tmp}" 2>/dev/null; return "${rc}"; }
    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::insert_line () {

    local p="${1:-}" n="${2:-}" content="${3:-}" tmp="" rc=0

    [[ "${n}" =~ ^[0-9]+$ ]] || return 1
    (( n > 0 )) || return 1

    file::readable "${p}" || return 1
    sys::has awk || return 1

    tmp="$(file::mktemp_near "${p}")" || return 1

    awk -v n="${n}" -v c="${content}" 'NR == n { print c } { print }' < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    (( rc != 0 )) && { rm -f -- "${tmp}" 2>/dev/null; return "${rc}"; }
    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::delete_line () {

    local p="${1:-}" n="${2:-}" tmp="" rc=0

    [[ "${n}" =~ ^[0-9]+$ ]] || return 1
    (( n > 0 )) || return 1

    file::readable "${p}" || return 1
    sys::has awk || return 1

    tmp="$(file::mktemp_near "${p}")" || return 1

    awk -v n="${n}" 'NR != n { print }' < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    (( rc != 0 )) && { rm -f -- "${tmp}" 2>/dev/null; return "${rc}"; }
    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::delete_match () {

    local p="${1:-}" pattern="${2:-}" tmp="" rc=0

    [[ -n "${pattern}" ]] || return 1

    file::readable "${p}" || return 1
    sys::has grep || return 1

    tmp="$(file::mktemp_near "${p}")" || return 1

    grep -Ev -- "${pattern}" "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    (( rc != 0 && rc != 1 )) && { rm -f -- "${tmp}" 2>/dev/null; return 1; }
    mv -f -- "${tmp}" "${p}" 2>/dev/null

}

file::dedupe () {

    local p="${1:-}" tmp="" rc=0

    file::exists "${p}" || return 1
    sys::has awk || return 1

    tmp="$(file::mktemp_near "${p}")" || return 1

    awk '!seen[$0]++' < "${p}" > "${tmp}" 2>/dev/null
    rc=$?

    (( rc != 0 )) && { rm -f -- "${tmp}" 2>/dev/null; return "${rc}"; }
    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::sort () {

    local p="${1:-}" order="${2:-asc}" tmp="" rc=0

    file::exists "${p}" || return 1
    sys::has sort || return 1

    tmp="$(file::mktemp_near "${p}")" || return 1

    case "${order}" in
        asc|"")        LC_ALL=C sort < "${p}" > "${tmp}" 2>/dev/null ;;
        desc|reverse)  LC_ALL=C sort -r < "${p}" > "${tmp}" 2>/dev/null ;;
        *)             rm -f -- "${tmp}" 2>/dev/null; return 1 ;;
    esac

    rc=$?

    (( rc != 0 )) && { rm -f -- "${tmp}" 2>/dev/null; return "${rc}"; }
    mv -f -- "${tmp}" "${p}" 2>/dev/null

}
file::equal () {

    local a="${1:-}" b="${2:-}" ha="" hb=""

    file::readable "${a}" || return 1
    file::readable "${b}" || return 1

    if sys::has cmp; then
        cmp -s -- "${a}" "${b}"
    elif sys::has diff; then
        diff -q -- "${a}" "${b}" >/dev/null 2>&1
    else
        ha="$(file::hash "${a}" 2>/dev/null || true)"
        hb="$(file::hash "${b}" 2>/dev/null || true)"
        [[ -n "${ha}" && -n "${hb}" && "${ha}" == "${hb}" ]]
    fi

}
file::diff () {

    local a="${1:-}" b="${2:-}"

    file::readable "${a}" || return 1
    file::readable "${b}" || return 1

    sys::has diff || return 1

    diff -u -- "${a}" "${b}" 2>/dev/null

}
file::rotate () {

    local p="${1:-}" max="${2:-5}" up="${3:-0}" i=0 src="" dst=""

    [[ "${max}" =~ ^[0-9]+$ ]] || return 1
    (( max > 0 )) || return 1

    file::exists "${p}" || return 1

    if [[ "${up}" == "1" ]]; then

        rm -f -- "${p}.1" 2>/dev/null

        for (( i=2; i<=max; i++ )); do

            src="${p}.${i}"
            dst="${p}.$(( i - 1 ))"

            [[ -f "${src}" ]] && mv -f -- "${src}" "${dst}" 2>/dev/null

        done

        mv -f -- "${p}" "${p}.${max}" 2>/dev/null || return 1

    else

        rm -f -- "${p}.${max}" 2>/dev/null

        for (( i=max-1; i>=1; i-- )); do

            src="${p}.${i}"
            dst="${p}.$(( i + 1 ))"

            [[ -f "${src}" ]] && mv -f -- "${src}" "${dst}" 2>/dev/null

        done

        mv -f -- "${p}" "${p}.1" 2>/dev/null || return 1

    fi

    file::new "${p}"

}
file::restore () {

    local p="${1:-}" suffix="${2:-.bak}" src=""

    path::valid "${p}" || return 1

    src="${p}${suffix}"
    file::exists "${src}" || return 1

    mv -f -- "${src}" "${p}" 2>/dev/null

}
file::tail_follow () {

    local p="${1:-}" n="${2:-10}"

    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    file::readable "${p}" || return 1
    sys::has tail || return 1

    tail -n "${n}" -F -- "${p}" 2>/dev/null

}
