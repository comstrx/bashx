# shellcheck disable=SC2034

APP_NAME="${APP_NAME:-gun}"
APP_TARGET="${APP_TARGET:-release}"
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BASH_VERSION="${APP_BASH_VERSION:-5.2}"

ROOT_DIR="${ROOT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
BUILD_DIR="${BUILD_DIR:-${ROOT_DIR}/target}"
SOURCE_DIR="${SOURCE_DIR:-${ROOT_DIR}/src}"
ENTRY_FILE="${ENTRY_FILE:-${ROOT_DIR}/src/main.sh}"

declare -A APP_MODS=()
declare -a APP_SRCS=()
declare -a APP_TESTS=()
declare -a APP_TEMPS=()

color () {

    local code="${1:-}" text="${2:-}"

    if [[ -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" && -t 2 ]]; then
        printf '\033[%sm%s\033[0m' "${code}" "${text}"
    else
        printf '%s' "${text}"
    fi

}
error () {

    local msg="${1:-unknown error}" label=""

    label="$(color '1;31' '[ERR]')"
    printf '%s %s\n' "${label}" "${msg}" >&2

}
die () {

    local code=1

    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        code="${1}"
        shift || true
    fi

    error "${*:-unknown error}"
    exit "${code}"

}
cleanup () {

    local file=""

    for file in "${APP_TEMPS[@]}"; do

        [[ -n "${file:-}" ]] || continue
        [[ -e "${file}" || -L "${file}" ]] || continue

        rm -rf -- "${file}" 2>/dev/null || true

    done

    APP_TEMPS=()

}

tmp_file () {

    local ref="${1:-}" path="${2:-/tmp}" dir="" mkt_file=""

    [[ -n "${ref}" ]] || die "missing output variable name"

    if [[ -d "${path}" ]]; then dir="${path}"
    else dir="$(dirname -- "${path}")" || die "failed to detect dirname of: ${path}"
    fi

    [[ -d "${dir}" ]] || die "temp directory not found: ${dir}"
    mkt_file="$(mktemp "${dir%/}/.out.tmp.XXXXXX")" || die "failed to create temp file in dir: ${dir}"

    APP_TEMPS+=( "${mkt_file}" )

    local -n out_ref="${ref}"
    out_ref="${mkt_file}"

}
exec_file () {

    local file="${1:-}"

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"
    chmod +x -- "${file}" 2>/dev/null || true

}
out_file () {

    local name="${1:-${APP_NAME}}" target="${2:-${APP_TARGET}}" dir="${3:-${BUILD_DIR}}"

    [[ -n "${name}" ]] || die "missing output file name"
    [[ "${name}" == *.sh ]] || name="${name}.sh"

    printf '%s\n' "${dir%/}/${target}/${name}"

}
bin_file () {

    local file="${1:-}" name="" dir=""

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"

    name="${file##*/}"
    name="${name%.sh}"

    [[ -n "${name}" ]] || die "invalid binary name from file: ${file}"

    if [[ -n "${XDG_BIN_HOME:-}" ]]; then dir="${XDG_BIN_HOME}"
    elif [[ -n "${HOME:-}" ]]; then dir="${HOME}/.local/bin"
    else die "can not detect home dir"
    fi

    printf '%s\n' "${dir%/}/${name}"

}
mkdir_file () {

    local file="${1:-}" dir=""

    [[ -n "${file}" ]] || die "missing file path"

    if [[ -d "${file}" ]]; then
        die "file is a directory: ${file}"
    fi

    dir="$(dirname -- "${file}")" || die "failed to detect dirname of: ${file}"
    mkdir -p -- "${dir}" || die "failed to create directory: ${dir}"

}
copy_file () {

    local file="${1:-}" dest="${2:-}"

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"
    [[ -n "${dest}" ]] || die "missing copy destination"

    mkdir_file "${dest}"
    cp -f -- "${file}" "${dest}" || die "failed to copy file: ${file} -> ${dest}"

}
move_file () {

    local file="${1:-}" dest="${2:-}"

    [[ -n "${file}" && -e "${file}" ]] || die "file not found: ${file}"
    [[ -n "${dest}" ]] || die "missing move destination"

    mkdir_file "${dest}"
    mv -f -- "${file}" "${dest}" || die "failed to move file: ${file} -> ${dest}"

}
minify_file () {

    local file="${1:-}"

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"
    shift || true

    command -v shfmt >/dev/null 2>&1 || die "missing tool: shfmt"
    shfmt -ln=bash -s -mn -w "${file}" "$@" || die "minify file failed: ${file}"

}
verify_file () {

    local file="${1:-}" shellcheck="${2:-0}"

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"
    shift 2 || true

    bash -n "${file}" || die "syntax check failed: ${file}"

    if (( shellcheck )); then
        command -v shellcheck >/dev/null 2>&1 || die "missing tool: shellcheck"
        shellcheck -e SC2317 "${file}" "$@" || die "shellcheck failed: ${file}"
    fi

}

hash_file () {

    local file="${1:-}"

    [[ -n "${file}" && -f "${file}" ]] || die "file not found: ${file}"

    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum -- "${file}" | awk '{print $1}'
        return 0
    fi
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 -- "${file}" | awk '{print $1}'
        return 0
    fi
    if command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 -- "${file}" | awk '{print $NF}'
        return 0
    fi

    die "missing sha256 tool"

}
hash_stream () {

    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
        return 0
    fi
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{print $1}'
        return 0
    fi
    if command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 | awk '{print $NF}'
        return 0
    fi

    die "missing sha256 tool"

}
new_checksum () {

    local file="" sum=""

    [[ -d "${SOURCE_DIR}" ]] || die "source directory not found: ${SOURCE_DIR}"

    while IFS= read -r file || [[ -n "${file}" ]]; do

        [[ -f "${file}" ]] || continue

        sum="$(hash_file "${file}")" || die "failed to hash file: ${file}"
        printf '%s  %s\n' "${sum}" "${file#"${ROOT_DIR}/"}"

    done < <(find "${SOURCE_DIR}" -type f | LC_ALL=C sort) | hash_stream

}
read_checksum () {

    local file="${1:-}"

    [[ -n "${file}" && -f "${file}" ]] || return 1
    sed -n -e "s/^readonly __INNER_APP_SRC_CHECKSUM__='\(.*\)'$/\1/p" "${file}" | head -n 1

}
check_checksum () {

    local file="${1:-}" old="" new=""

    old="$(read_checksum "${file}")" || return 1
    [[ -n "${old}" ]] || return 1

    new="$(new_checksum)" || return 1
    [[ -n "${new}" ]] || return 1

    [[ "${old}" == "${new}" ]]

}
build_checksum () {

    local sum=""
    sum="$(new_checksum)" || return 1
    printf "readonly __INNER_APP_SRC_CHECKSUM__='%s'\n" "${sum}"

}
