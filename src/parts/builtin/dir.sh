
dir::valid () {

    path::valid "$@"

}
dir::exists () {

    path::is_dir "$@"

}
dir::missing () {

    ! path::is_dir "$@"

}
dir::empty () {

    path::is_dir "$@" || return 0
    path::empty "$@"

}
dir::filled () {

    path::is_dir "$@" || return 1
    path::filled "$@"

}
dir::readable () {

    path::is_dir "$@" || return 1
    path::readable "$@"

}
dir::writable () {

    path::is_dir "$@" || return 1
    path::writable "$@"

}
dir::executable () {

    path::is_dir "$@" || return 1
    path::executable "$@"

}

dir::is_abs () {

    path::is_dir "$@" || return 1
    path::is_abs "$@"

}
dir::is_rel () {

    path::is_dir "$@" || return 1
    path::is_rel "$@"

}
dir::is_root () {

    path::is_dir "$@" || return 1
    path::is_root "$@"

}
dir::is_link () {

    path::is_link "$@" || return 1
    path::is_dir "$@"

}
dir::is_hidden () {

    path::is_dir "$@" || return 1
    path::is_hidden "$@"

}
dir::is_under () {

    path::is_under "$@"

}
dir::is_parent () {

    path::is_parent "$@"

}
dir::is_safe () {

    path::is_safe "$@"

}
dir::is_same () {

    path::is_same "$@"

}

dir::name () {

    path::basename "$@"

}
dir::parent () {

    path::parentname "$@"

}
dir::dirname () {

    path::dirname "$@"

}
dir::resolve () {

    path::resolve "$@"

}
dir::expand () {

    path::expand "$@"

}
dir::abs () {

    path::abs "$@"

}
dir::rel () {

    path::rel "$@"

}
dir::can () {

    path::is_dir "$@" || return 1
    path::can "$@"

}

dir::type () {

    path::is_dir "$@" || return 1
    printf 'dir'

}
dir::size () {

    path::is_dir "$@" || return 1
    path::size "$@"

}
dir::mtime () {

    path::is_dir "$@" || return 1
    path::mtime "$@"

}
dir::atime () {

    path::is_dir "$@" || return 1
    path::atime "$@"

}
dir::ctime () {

    path::is_dir "$@" || return 1
    path::ctime "$@"

}
dir::age () {

    path::is_dir "$@" || return 1
    path::age "$@"

}
dir::owner () {

    path::is_dir "$@" || return 1
    path::owner "$@"

}
dir::group () {

    path::is_dir "$@" || return 1
    path::group "$@"

}
dir::mode () {

    path::is_dir "$@" || return 1
    path::mode "$@"

}
dir::inode () {

    path::is_dir "$@" || return 1
    path::inode "$@"

}
dir::tree () {

    path::is_dir "$@" || return 1
    path::tree "$@"

}

dir::new () {

    path::is_dir "$@" && return 1
    path::mkdir "$@"

}
dir::ensure () {

    path::mkdir "$@"

}
dir::ensure_parent () {

    path::mkparent "$@"

}
dir::remove () {

    path::is_dir "$@" || return 1
    path::remove "$@"

}
dir::clear () {

    path::is_dir "$@" || return 1
    path::clear "$@"

}
dir::rename () {

    path::is_dir "$@" || return 1
    path::rename "$@"

}
dir::move () {

    dir::rename "$@"

}
dir::copy () {

    path::is_dir "$@" || return 1
    path::copy "$@"

}
dir::link () {

    path::is_dir "$@" || return 1
    path::link "$@"

}
dir::symlink () {

    path::is_dir "$@" || return 1
    path::symlink "$@"

}
dir::readlink () {

    path::is_dir "$@" || return 1
    path::readlink "$@"

}

dir::chmod () {

    path::is_dir "$@" || return 1
    path::chmod "$@"

}
dir::mktemp () {

    path::mktemp_dir "$@"

}
dir::mktemp_near () {

    path::mktemp_near dir "$@"

}

dir::sync () {

    path::is_dir "$@" || return 1
    path::sync "$@"

}
dir::watch () {

    path::is_dir "$@" || return 1
    path::watch "$@"

}

dir::strip () {

    path::is_dir "$@" || return 1
    path::strip "$@"

}
dir::archive () {

    path::is_dir "$@" || return 1
    path::archive "$@"

}
dir::extract () {

    path::extract "$@"

}
dir::backup () {

    path::is_dir "$@" || return 1
    path::backup "$@"

}

dir::hash () {

    path::is_dir "$@" || return 1
    path::hash "$@"

}
dir::checksum () {

    path::is_dir "$@" || return 1
    path::checksum "$@"

}
dir::snapshot () {

    path::is_dir "$@" || return 1
    path::snapshot "$@"

}

dir::encode () {

    path::is_dir "$@" || return 1
    path::encode "$@"

}
dir::decode () {

    path::is_dir "$@" || return 1
    path::decode "$@"

}
dir::encrypt () {

    path::is_dir "$@" || return 1
    path::encrypt "$@"

}
dir::decrypt () {

    path::is_dir "$@" || return 1
    path::decrypt "$@"

}

dir::trylock () {

    path::trylock "$@"

}
dir::lock () {

    path::lock "$@"

}
dir::unlock () {

    path::unlock "$@"

}
dir::locked () {

    path::locked "$@"

}
dir::with_lock () {

    path::with_lock "$@"

}

dir::glob () {

    local p="${1:-}" pattern="*" old_nullglob="" old_dotglob="" entry="" base=""
    local -a matches=()

    (( $# >= 2 )) && pattern="${2}"

    dir::exists "${p}" || return 1
    [[ -n "${pattern}" ]] || return 1

    old_nullglob="$(shopt -p nullglob)"
    old_dotglob="$(shopt -p dotglob)"

    shopt -s nullglob
    case "${pattern}" in .*) shopt -s dotglob ;; esac

    for entry in "${p%/}"/${pattern}; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue

        base="$(dir::name "${entry}")" || return 1
        [[ -n "${base}" ]] && matches+=( "${base}" )

    done

    eval "${old_nullglob}"
    eval "${old_dotglob}"

    (( ${#matches[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${matches[@]}" | LC_ALL=C sort
    else printf '%s\n' "${matches[@]}"
    fi

}
dir::has_glob () {

    local p="${1:-}" pattern="" old_nullglob="" old_dotglob="" entry="" found=1

    (( $# >= 2 )) && pattern="${2}"

    dir::exists "${p}" || return 1
    [[ -n "${pattern}" ]] || return 1

    old_nullglob="$(shopt -p nullglob)"
    old_dotglob="$(shopt -p dotglob)"

    shopt -s nullglob
    case "${pattern}" in .*) shopt -s dotglob ;; esac

    for entry in "${p%/}"/${pattern}; do
        [[ -e "${entry}" || -L "${entry}" ]] && { found=0; break; }
    done

    eval "${old_nullglob}"
    eval "${old_dotglob}"

    return "${found}"

}
dir::contains () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    path::valid "${name}" || return 1

    [[ -n "${name}" ]] || return 1
    [[ "${name}" != "." && "${name}" != ".." ]] || return 1
    [[ "${name}" != */* && "${name}" != *\\* ]] || return 1

    [[ -e "${parent%/}/${name}" || -L "${parent%/}/${name}" ]]

}
dir::contains_file () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    path::valid "${name}" || return 1

    [[ -n "${name}" ]] || return 1
    [[ "${name}" != "." && "${name}" != ".." ]] || return 1
    [[ "${name}" != */* && "${name}" != *\\* ]] || return 1

    [[ -f "${parent%/}/${name}" && ! -L "${parent%/}/${name}" ]]

}
dir::contains_dir () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    path::valid "${name}" || return 1

    [[ -n "${name}" ]] || return 1
    [[ "${name}" != "." && "${name}" != ".." ]] || return 1
    [[ "${name}" != */* && "${name}" != *\\* ]] || return 1

    [[ -d "${parent%/}/${name}" && ! -L "${parent%/}/${name}" ]]

}
dir::contains_link () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    path::valid "${name}" || return 1

    [[ -n "${name}" ]] || return 1
    [[ "${name}" != "." && "${name}" != ".." ]] || return 1
    [[ "${name}" != */* && "${name}" != *\\* ]] || return 1

    [[ -L "${parent%/}/${name}" ]]

}
dir::contains_hidden () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    path::valid "${name}" || return 1

    [[ -n "${name}" ]] || return 1
    [[ "${name}" != "." && "${name}" != ".." ]] || return 1
    [[ "${name}" != */* && "${name}" != *\\* ]] || return 1

    [[ "${name}" == .* ]] || name=".${name}"
    [[ "${name}" != "." && "${name}" != ".." ]] || return 1

    [[ -e "${parent%/}/${name}" || -L "${parent%/}/${name}" ]]

}

dir::find () {

    local p="${1:-}" name="${2:-*}" type="${3:-any}" depth="${4:-}"

    dir::exists "${p}" || return 1
    sys::has find || return 1

    [[ -n "${name}" ]] || return 1
    [[ -n "${depth}" && ! "${depth}" =~ ^[0-9]+$ ]] && return 1

    case "${type}" in
        ""|any)
            if [[ -n "${depth}" ]]; then find "${p}" -mindepth 1 -maxdepth "${depth}" -name "${name}" 2>/dev/null
            else find "${p}" -mindepth 1 -name "${name}" 2>/dev/null
            fi
        ;;
        file)
            if [[ -n "${depth}" ]]; then find "${p}" -mindepth 1 -maxdepth "${depth}" -type f -name "${name}" 2>/dev/null
            else find "${p}" -mindepth 1 -type f -name "${name}" 2>/dev/null
            fi
        ;;
        dir)
            if [[ -n "${depth}" ]]; then find "${p}" -mindepth 1 -maxdepth "${depth}" -type d -name "${name}" 2>/dev/null
            else find "${p}" -mindepth 1 -type d -name "${name}" 2>/dev/null
            fi
        ;;
        link)
            if [[ -n "${depth}" ]]; then find "${p}" -mindepth 1 -maxdepth "${depth}" -type l -name "${name}" 2>/dev/null
            else find "${p}" -mindepth 1 -type l -name "${name}" 2>/dev/null
            fi
        ;;
        *)
            return 1
        ;;
    esac

}
dir::find_files () {

    dir::find "${1:-}" "${2:-*}" file "${3:-}"

}
dir::find_dirs () {

    dir::find "${1:-}" "${2:-*}" dir "${3:-}"

}
dir::find_links () {

    dir::find "${1:-}" "${2:-*}" link "${3:-}"

}

dir::walk () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    sys::has find || return 1

    find "${p}" -mindepth 1 2>/dev/null

}
dir::walk_files () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    sys::has find || return 1

    find "${p}" -mindepth 1 -type f 2>/dev/null

}
dir::walk_dirs () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    sys::has find || return 1

    find "${p}" -mindepth 1 -type d 2>/dev/null

}
dir::walk_links () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    sys::has find || return 1

    find "${p}" -mindepth 1 -type l 2>/dev/null

}

dir::list () {

    local p="${1:-}" sort="${2:-name}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue

        base="$(dir::name "${entry}")" || return 1
        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    case "${sort}" in
        name|"")
            if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
            else printf '%s\n' "${names[@]}"
            fi
        ;;
        none)
            printf '%s\n' "${names[@]}"
        ;;
        reverse|desc)
            if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort -r
            else printf '%s\n' "${names[@]}"
            fi
        ;;
        *)
            return 1
        ;;
    esac

}
dir::list_paths () {

    local p="${1:-}" sort="${2:-name}" name=""

    dir::exists "${p}" || return 1

    while IFS= read -r name; do
        printf '%s/%s\n' "${p%/}" "${name}"
    done < <(dir::list "${p}" "${sort}")

}
dir::list_files () {

    local p="${1:-}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -f "${entry}" && ! -L "${entry}" ]] || continue

        base="$(dir::name "${entry}")" || return 1
        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_dirs () {

    local p="${1:-}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -d "${entry}" && ! -L "${entry}" ]] || continue

        base="$(dir::name "${entry}")" || return 1
        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_links () {

    local p="${1:-}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -L "${entry}" ]] || continue

        base="$(dir::name "${entry}")" || return 1
        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_hidden () {

    local p="${1:-}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue

        base="$(dir::name "${entry}")" || return 1
        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}

dir::count () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_files () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -f "${entry}" && ! -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_dirs () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -d "${entry}" && ! -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_links () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_hidden () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_recursive () {

    local p="${1:-}" n=0

    dir::exists "${p}" || return 1

    if sys::has find; then
        n="$(find "${p}" -mindepth 1 2>/dev/null | wc -l | tr -d '[:space:]')"
        [[ "${n}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${n}"; return 0; }
    fi

    while IFS= read -r _; do
        n=$(( n + 1 ))
    done < <(dir::walk "${p}")

    printf '%s\n' "${n}"

}
