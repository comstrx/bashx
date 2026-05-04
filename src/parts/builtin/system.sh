
sys::has () {

    command -v "${1:-}" >/dev/null 2>&1

}
sys::is_linux () {

    local s=""

    if sys::has uname; then
        s="$(uname -s 2>/dev/null || true)"
    fi

    [[ "${s}" == "Linux" ]] && return 0
    [[ "${OSTYPE:-}" == linux* ]]

}
sys::is_macos () {

    local s=""

    if sys::has uname; then
        s="$(uname -s 2>/dev/null || true)"
    fi

    [[ "${s}" == "Darwin" ]] && return 0
    [[ "${OSTYPE:-}" == darwin* ]]

}
sys::is_wsl () {

    local r="" lower=""

    sys::is_linux || return 1
    [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] && return 0

    if [[ -r /proc/sys/kernel/osrelease ]]; then

        IFS= read -r r < /proc/sys/kernel/osrelease || true
        lower="$(printf '%s' "${r}" | tr '[:upper:]' '[:lower:]')"

        [[ "${lower}" == *microsoft* ]] && return 0

    fi
    if [[ -r /proc/version ]]; then

        IFS= read -r r < /proc/version || true
        lower="$(printf '%s' "${r}" | tr '[:upper:]' '[:lower:]')"

        [[ "${lower}" == *microsoft* ]] && return 0

    fi

    return 1

}
sys::is_unix () {

    sys::is_linux || sys::is_macos

}

sys::is_cygwin () {

    local s=""
    [[ "${OSTYPE:-}" == cygwin* ]] && return 0

    if sys::has uname; then
        s="$(uname -s 2>/dev/null || true)"
        [[ "${s}" == CYGWIN* ]] && return 0
    fi

    return 1

}
sys::is_msys () {

    local m="${MSYSTEM:-}" s=""

    [[ "${OSTYPE:-}" == msys* ]] && return 0

    if sys::has uname; then
        s="$(uname -s 2>/dev/null || true)"
        [[ "${s}" == MSYS* || "${s}" == MINGW* ]] && return 0
    fi

    case "${m}" in
        MSYS|MINGW*|UCRT*|CLANG*) return 0 ;;
        *) return 1 ;;
    esac

}
sys::is_gitbash () {

    sys::is_msys || return 1

    [[ -n "${GitInstallRoot:-}" ]] && return 0
    [[ "${OSTYPE:-}" == msys* && "${MSYSTEM:-}" == MINGW* && -n "${WINDIR:-}" ]] && return 0

    case "${TERM_PROGRAM:-}" in
        mintty)
            [[ "${MSYSTEM:-}" == MINGW* && -z "${MSYS2_PATH_TYPE:-}" ]]
            return
        ;;
    esac

    return 1

}
sys::is_windows () {

    sys::is_wsl    && return 1
    sys::is_msys   && return 0
    sys::is_cygwin && return 0

    [[ "${OSTYPE:-}" == win32* || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]] && return 0
    [[ -n "${WINDIR:-}" || -n "${SystemRoot:-}" || -n "${COMSPEC:-}" ]] || return 1

    sys::is_linux && return 1
    sys::is_macos && return 1

    return 0

}
sys::is_posix () {

    sys::is_linux || sys::is_macos || sys::is_wsl || sys::is_msys || sys::is_cygwin

}

sys::ci_name () {

    [[ -n "${GITHUB_ACTIONS:-}" ]]         && { printf '%s\n' "github";    return 0; }
    [[ -n "${GITLAB_CI:-}" ]]              && { printf '%s\n' "gitlab";    return 0; }
    [[ -n "${JENKINS_URL:-}" ]]            && { printf '%s\n' "jenkins";   return 0; }
    [[ -n "${BUILDKITE:-}" ]]              && { printf '%s\n' "buildkite"; return 0; }
    [[ -n "${CIRCLECI:-}" ]]               && { printf '%s\n' "circleci";  return 0; }
    [[ -n "${TRAVIS:-}" ]]                 && { printf '%s\n' "travis";    return 0; }
    [[ -n "${APPVEYOR:-}" ]]               && { printf '%s\n' "appveyor";  return 0; }
    [[ -n "${TF_BUILD:-}" ]]               && { printf '%s\n' "azure";     return 0; }
    [[ -n "${BITBUCKET_BUILD_NUMBER:-}" ]] && { printf '%s\n' "bitbucket"; return 0; }
    [[ -n "${TEAMCITY_VERSION:-}" ]]       && { printf '%s\n' "teamcity";  return 0; }
    [[ -n "${DRONE:-}" ]]                  && { printf '%s\n' "drone";     return 0; }
    [[ -n "${SEMAPHORE:-}" ]]              && { printf '%s\n' "semaphore"; return 0; }
    [[ -n "${CODEBUILD_BUILD_ID:-}" ]]     && { printf '%s\n' "codebuild"; return 0; }
    [[ -n "${CI:-}" ]]                     && { printf '%s\n' "generic";   return 0; }

    printf '%s\n' "none"
    return 1

}
sys::is_ci () {

    sys::ci_name >/dev/null 2>&1

}
sys::is_ci_pull () {

    [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" || "${GITHUB_EVENT_NAME:-}" == "pull_request_target" ]] && return 0
    [[ -n "${CI_MERGE_REQUEST_IID:-}" ]] && return 0
    [[ -n "${BITBUCKET_PR_ID:-}" ]] && return 0
    [[ -n "${SYSTEM_PULLREQUEST_PULLREQUESTID:-}" ]] && return 0
    [[ "${BUILD_REASON:-}" == "PullRequest" ]]  && return 0

    return 1

}
sys::is_ci_push () {

    sys::is_ci || return 1
    sys::is_ci_pull && return 1

    [[ "${GITHUB_EVENT_NAME:-}" == "push" ]] && return 0
    [[ "${CI_PIPELINE_SOURCE:-}" == "push" ]] && return 0
    [[ -n "${BITBUCKET_COMMIT:-}" && -z "${BITBUCKET_PR_ID:-}" ]] && return 0
    [[ "${BUILD_REASON:-}" == "IndividualCI" || "${BUILD_REASON:-}" == "BatchedCI" ]] && return 0

    return 1

}
sys::is_ci_tag () {

    [[ -n "${GITHUB_REF_TYPE:-}" && "${GITHUB_REF_TYPE:-}" == "tag" ]] && return 0
    [[ -n "${CI_COMMIT_TAG:-}" ]] && return 0
    [[ -n "${BITBUCKET_TAG:-}" ]] && return 0
    [[ "${BUILD_SOURCEBRANCH:-}" == refs/tags/* ]] && return 0

    return 1

}

sys::is_gui () {

    if sys::is_linux; then
        [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
        return
    fi
    if sys::is_macos; then
        [[ -z "${SSH_CONNECTION:-}" && -z "${SSH_CLIENT:-}" && -z "${SSH_TTY:-}" && -z "${CI:-}" ]]
        return
    fi
    if sys::is_windows; then

        sys::is_ci && return 1
        [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" ]] && return 1

        if sys::has powershell.exe; then
            powershell.exe -NoProfile -NonInteractive -Command "[Environment]::UserInteractive" 2>/dev/null | tr -d '\r' | grep -qi '^True$'
            return
        fi

        [[ -n "${WINDIR:-}" || -n "${SystemRoot:-}" ]]
        return

    fi

    return 1

}
sys::is_terminal () {

    [[ -t 0 || -t 1 || -t 2 ]]

}
sys::is_interactive () {

    [[ "${-}" == *i* ]]

}
sys::is_headless () {

    sys::is_gui && return 1
    return 0

}
sys::is_container () {

    local r="" lower=""

    [[ -f "/.dockerenv" ]] && return 0
    [[ -f "/run/.containerenv" ]] && return 0

    if [[ -r "/run/systemd/container" ]]; then

        IFS= read -r r < /run/systemd/container || true
        [[ -n "${r}" ]] && return 0

    fi
    if [[ -r /proc/1/cgroup ]]; then

        while IFS= read -r r || [[ -n "${r}" ]]; do

            lower="$(printf '%s' "${r}" | tr '[:upper:]' '[:lower:]')"

            [[ "${lower}" == *docker* ]]     && return 0
            [[ "${lower}" == *kubepods* ]]   && return 0
            [[ "${lower}" == *containerd* ]] && return 0
            [[ "${lower}" == *podman* ]]     && return 0
            [[ "${lower}" == *lxc* ]]        && return 0

        done < /proc/1/cgroup

    fi
    if [[ -r /proc/1/environ ]]; then

        while IFS= read -r -d '' r; do
            [[ "${r}" == container=* ]] && return 0
        done < /proc/1/environ

    fi

    return 1

}

sys::is_root () {

    local v="" cmd=""

    if sys::is_windows; then

        if sys::has net.exe && net.exe session >/dev/null 2>&1; then
            return 0
        fi
        if sys::has powershell.exe; then

            cmd="[bool](([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
            powershell.exe -NoProfile -NonInteractive -Command "${cmd}" 2>/dev/null | tr -d '\r' | grep -qi '^True$'

            return

        fi

        return 1

    fi
    if sys::has id; then

        v="$(id -u 2>/dev/null || true)"
        [[ "${v}" == "0" ]]
        return

    fi

    return 1

}
sys::is_admin () {

    local v="" x=""

    sys::is_root    && return 0
    sys::is_windows && return 1

    if sys::has id; then

        v="$(id -Gn 2>/dev/null || true)"

        for x in ${v}; do
            [[ "${x}" == "sudo"  ]] && return 0
            [[ "${x}" == "wheel" ]] && return 0
            [[ "${x}" == "admin" ]] && return 0
        done

    fi
    if sys::has groups; then

        v="$(groups 2>/dev/null || true)"

        for x in ${v}; do
            [[ "${x}" == "sudo"  ]] && return 0
            [[ "${x}" == "wheel" ]] && return 0
            [[ "${x}" == "admin" ]] && return 0
        done

    fi

    return 1

}
sys::can_sudo () {

    sys::is_windows && return 1
    sys::is_root    && return 0

    sys::has sudo || return 1
    sudo -n true >/dev/null 2>&1

}

sys::pkg_manager () {

    if sys::is_linux; then

        sys::has apt-get      && { printf '%s\n' "apt";     return 0; }
        sys::has apk          && { printf '%s\n' "apk";     return 0; }
        sys::has dnf          && { printf '%s\n' "dnf";     return 0; }
        sys::has yum          && { printf '%s\n' "yum";     return 0; }
        sys::has pacman       && { printf '%s\n' "pacman";  return 0; }
        sys::has zypper       && { printf '%s\n' "zypper";  return 0; }
        sys::has xbps-install && { printf '%s\n' "xbps";    return 0; }
        sys::has nix          && { printf '%s\n' "nix";     return 0; }
        sys::has rpm          && { printf '%s\n' "rpm";     return 0; }
        sys::has brew         && { printf '%s\n' "brew"; return 0; }

        printf '%s\n' "unknown"
        return 1

    fi
    if sys::is_macos; then

        sys::has brew && { printf '%s\n' "brew"; return 0; }
        sys::has port && { printf '%s\n' "port"; return 0; }

        printf '%s\n' "unknown"
        return 1

    fi
    if sys::is_windows; then

        if sys::is_msys && sys::has pacman; then
            printf '%s\n' "pacman"
            return 0
        fi

        sys::has winget && { printf '%s\n' "winget"; return 0; }
        sys::has scoop  && { printf '%s\n' "scoop";  return 0; }
        sys::has choco  && { printf '%s\n' "choco";  return 0; }
        sys::has pacman && { printf '%s\n' "pacman"; return 0; }

        printf '%s\n' "unknown"
        return 1

    fi

    printf '%s\n' "unknown"
    return 1

}
sys::svc_manager () {

    if sys::is_linux; then

        sys::has systemctl  && [[ -d /run/systemd/system || -d /sys/fs/cgroup/system.slice ]] && { printf '%s\n' "systemd"; return 0; }
        sys::has rc-service && { printf '%s\n' "openrc"; return 0; }
        sys::has service    && { printf '%s\n' "sysvinit"; return 0; }
        sys::has sv         && { printf '%s\n' "runit"; return 0; }
        sys::has s6-rc      && { printf '%s\n' "s6"; return 0; }

    fi
    if sys::is_macos; then

        sys::has launchctl && { printf '%s\n' "launchd"; return 0; }

    fi
    if sys::is_windows; then

        { sys::has sc.exe || sys::has sc; } && { printf '%s\n' "sc"; return 0; }
        sys::has powershell.exe && { printf '%s\n' "powershell"; return 0; }

    fi

    printf '%s\n' "none"
    return 1

}
sys::fw_manager () {

    if sys::is_linux; then

        sys::has ufw          && { printf '%s\n' "ufw";       return 0; }
        sys::has firewall-cmd && { printf '%s\n' "firewalld"; return 0; }
        sys::has nft          && { printf '%s\n' "nftables";  return 0; }
        sys::has iptables     && { printf '%s\n' "iptables";  return 0; }
        sys::has pfctl        && { printf '%s\n' "pf";        return 0; }

    fi
    if sys::is_macos; then

        sys::has pfctl && { printf '%s\n' "pf"; return 0; }

    fi
    if sys::is_windows; then

        sys::has powershell.exe && { printf '%s\n' "windows-firewall"; return 0; }
        sys::has netsh          && { printf '%s\n' "netsh"; return 0; }

    fi

    printf '%s\n' "none"
    return 1

}

sys::name () {

    if sys::is_linux; then
        printf '%s\n' "linux"
        return 0
    fi
    if sys::is_macos; then
        printf '%s\n' "macos"
        return 0
    fi
    if sys::is_windows; then
        printf '%s\n' "windows"
        return 0
    fi

    printf '%s\n' "unknown"
    return 1

}
sys::runtime () {

    if sys::is_wsl; then
        printf '%s\n' "wsl"
        return 0
    fi
    if sys::is_gitbash; then
        printf '%s\n' "gitbash"
        return 0
    fi
    if sys::is_msys; then
        printf '%s\n' "msys2"
        return 0
    fi
    if sys::is_cygwin; then
        printf '%s\n' "cygwin"
        return 0
    fi
    if sys::is_linux; then
        printf '%s\n' "linux"
        return 0
    fi
    if sys::is_macos; then
        printf '%s\n' "macos"
        return 0
    fi
    if sys::is_windows; then
        printf '%s\n' "windows"
        return 0
    fi

    printf '%s\n' "unknown"
    return 1

}
sys::kernel () {

    local v=""

    if sys::has uname; then
        v="$(uname -s 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if sys::is_windows; then
        printf '%s\n' "Windows"
        return 0
    fi

    printf '%s\n' "unknown"
    return 1

}
sys::distro () {

    local id="" runtime="" line="" file=""

    if sys::is_linux; then

        for file in /etc/os-release /usr/lib/os-release; do

            [[ -r "${file}" ]] || continue

            while IFS= read -r line || [[ -n "${line}" ]]; do

                [[ "${line}" == "ID="* ]] || continue

                line="${line#*=}"
                line="${line%\"}"
                line="${line#\"}"
                id="${line}"

                [[ -n "${id}" ]] && break

            done < "${file}"

            [[ -n "${id}" ]] && break

        done

        if [[ -n "${id}" ]]; then
            printf '%s\n' "${id}"
            return 0
        fi

        printf '%s\n' "linux"
        return 0

    fi
    if sys::is_macos; then

        printf '%s\n' "macos"
        return 0

    fi
    if sys::is_windows; then

        runtime="$(sys::runtime 2>/dev/null || true)"

        if [[ -n "${runtime}" && "${runtime}" != "unknown" ]]; then
            printf '%s\n' "${runtime}"
            return 0
        fi

        printf '%s\n' "windows"
        return 0

    fi

    printf '%s\n' "unknown"
    return 1

}

sys::arch () {

    local v="" lower=""

    sys::has uname && v="$(uname -m 2>/dev/null || true)"

    [[ -n "${v}" ]] || v="${PROCESSOR_ARCHITECTURE:-${HOSTTYPE:-}}"
    [[ -n "${v}" ]] || v="unknown"

    lower="$(printf '%s' "${v}" | tr '[:upper:]' '[:lower:]')"

    case "${lower}" in
        x86_64|amd64)             printf '%s\n' "x64" ;;
        x86|i386|i486|i586|i686)  printf '%s\n' "x86" ;;
        aarch64|arm64)            printf '%s\n' "arm64" ;;
        armv7l|armv7|armhf)       printf '%s\n' "armv7" ;;
        armv6l|armv6)             printf '%s\n' "armv6" ;;
        arm)                      printf '%s\n' "arm" ;;
        ppc64le)                  printf '%s\n' "ppc64le" ;;
        ppc64)                    printf '%s\n' "ppc64" ;;
        s390x)                    printf '%s\n' "s390x" ;;
        riscv64)                  printf '%s\n' "riscv64" ;;
        *)                        printf '%s\n' "${lower}" ;;
    esac

}
sys::version () {

    local v=""

    if sys::is_linux; then

        if [[ -r /proc/sys/kernel/osrelease ]]; then
            IFS= read -r v < /proc/sys/kernel/osrelease || true
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        fi

    fi
    if sys::is_macos && sys::has sw_vers; then

        v="$(sw_vers -productVersion 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_windows && sys::has powershell.exe; then

        v="$(powershell.exe -NoProfile -NonInteractive -Command "[Environment]::OSVersion.Version.ToString()" 2>/dev/null | tr -d '\r' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has uname; then

        v="$(uname -r 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s\n' "unknown"
    return 1

}
sys::uptime () {

    local v=""

    if sys::is_linux && [[ -r /proc/uptime ]]; then

        v="$(awk '{print int($1)}' /proc/uptime 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_macos && sys::has sysctl; then

        v="$(sysctl -n kern.boottime 2>/dev/null | sed -n 's/.*sec = \([0-9][0-9]*\).*/\1/p' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( $(date +%s) - v ))"; return 0; }

    fi
    if sys::is_windows && sys::has powershell.exe; then

        v="$(powershell.exe -NoProfile -NonInteractive -Command "\$b=(Get-CimInstance Win32_OperatingSystem).LastBootUpTime; [int64]((Get-Date)-\$b).TotalSeconds" 2>/dev/null | tr -d '\r' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
sys::loadavg () {

    local v="" a="" b="" c=""

    if [[ -r /proc/loadavg ]]; then

        awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null
        return

    fi
    if sys::has uptime; then

        v="$(uptime 2>/dev/null || true)"
        v="${v##*load average: }"
        v="${v##*load averages: }"
        v="${v//,/}"

        read -r a b c _ <<< "${v}"
        [[ -n "${a}" && -n "${b}" && -n "${c}" ]] && { printf '%s %s %s\n' "${a}" "${b}" "${c}"; return 0; }

    fi
    if sys::is_windows; then

        printf '%s\n' "0 0 0"
        return 0

    fi

    return 1

}

sys::umask () {

    local v=""

    v="$(umask 2>/dev/null || true)"
    [[ -n "${v}" ]] || return 1

    printf '%s\n' "${v}"

}
sys::proxy () {

    local k=""

    for k in HTTPS_PROXY https_proxy HTTP_PROXY http_proxy ALL_PROXY all_proxy NO_PROXY no_proxy; do
        [[ -n "${!k:-}" ]] || continue
        printf '%s=%s\n' "${k}" "${!k}"
    done

    return 0

}
sys::pid () {

    printf '%s\n' "$$"

}
sys::ppid () {

    printf '%s\n' "${PPID:-0}"

}
sys::ip () {

    local v=""

    if sys::has hostname; then

        v="$(hostname -I 2>/dev/null || true)"
        v="${v#"${v%%[![:space:]]*}"}"
        v="${v%"${v##*[![:space:]]}"}"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has ip; then

        v="$(ip -o -4 addr show scope global 2>/dev/null | awk '{ sub(/\/.*/, "", $4); print $4 }')"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has ifconfig; then

        v="$(ifconfig 2>/dev/null | awk '/inet / && $2 != "127.0.0.1" { print $2 }')"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_windows && sys::has powershell.exe; then

        v="$(powershell.exe -NoProfile -NonInteractive -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { \$_.IPAddress -notlike '127.*' -and \$_.PrefixOrigin -ne 'WellKnown' } | Select-Object -ExpandProperty IPAddress" 2>/dev/null | tr -d '\r')"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}

sys::locale () {

    local v=""

    v="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    if sys::has locale; then
        v="$(locale 2>/dev/null | sed -n 's/^LANG=//p' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if sys::is_windows && sys::has powershell.exe; then
        v="$(powershell.exe -NoProfile -NonInteractive -Command "(Get-Culture).Name" 2>/dev/null | tr -d '\r' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::timezone () {

    local v=""

    if [[ -n "${TZ:-}" ]]; then
        printf '%s\n' "${TZ}"
        return 0
    fi
    if sys::has timedatectl; then
        v="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if [[ -L /etc/localtime ]] && sys::has readlink; then
        v="$(readlink /etc/localtime 2>/dev/null || true)"
        v="${v#*/zoneinfo/}"
        [[ -n "${v}" && "${v}" != /etc/localtime ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if sys::is_macos && sys::has systemsetup; then
        v="$(systemsetup -gettimezone 2>/dev/null | sed 's/^Time Zone: //' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if sys::is_windows && sys::has powershell.exe; then
        v="$(powershell.exe -NoProfile -NonInteractive -Command "(Get-TimeZone).Id" 2>/dev/null | tr -d '\r' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::hostname () {

    local v=""

    if sys::has hostname; then
        v="$(hostname 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    v="${HOSTNAME:-${COMPUTERNAME:-}}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    printf '%s\n' "unknown"
    return 1

}
sys::username () {

    local v=""

    if sys::has id; then

        v="$(id -un 2>/dev/null || true)"
        v="${v##*\\}"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has whoami; then

        v="$(whoami 2>/dev/null || true)"
        v="${v##*\\}"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    v="${USER:-${USERNAME:-${LOGNAME:-}}}"
    v="${v##*\\}"

    [[ -n "${v}" ]] || return 1
    printf '%s\n' "${v}"

}

sys::path_name () {

    if sys::is_windows; then printf '%s\n' "Path"
    else printf '%s\n' "PATH"
    fi

}
sys::path_sep () {

    if sys::is_windows; then printf '%s\n' ";"
    else printf '%s\n' ":"
    fi

}
sys::line_sep () {

    if sys::is_windows; then printf '%s\n' "crlf"
    else printf '%s\n' "lf"
    fi

}
sys::exe_suffix () {

    if sys::is_windows; then printf '%s\n' ".exe"
    else printf '%s\n' ""
    fi

}
sys::lib_suffix () {

    if sys::is_windows; then printf '%s\n' ".dll"
    elif sys::is_macos; then printf '%s\n' ".dylib"
    else printf '%s\n' ".so"
    fi

}
sys::path_dirs () {

    local path_value="${PATH:-}" sep="" part=""

    [[ -n "${path_value}" ]] || return 0

    case "${path_value}" in
        *";"*) sep=";" ;;
        *)     sep=":" ;;
    esac

    while [[ "${path_value}" == *"${sep}"* ]]; do

        part="${path_value%%"${sep}"*}"
        path_value="${path_value#*"${sep}"}"

        [[ -n "${part}" ]] && printf '%s\n' "${part}"

    done

    [[ -n "${path_value}" ]] && printf '%s\n' "${path_value}"

}

sys::which () {

    local bin="${1:-}" v=""

    [[ -n "${bin}" ]] || return 1
    [[ "${bin}" != *$'\n'* && "${bin}" != *$'\r'* ]] || return 1

    v="$(command -v -- "${bin}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    if sys::is_windows; then
        for v in ".exe" ".cmd" ".bat" ".ps1"; do
            command -v -- "${bin}${v}" >/dev/null 2>&1 || continue
            command -v -- "${bin}${v}" 2>/dev/null
            return 0
        done
    fi

    return 1

}
sys::which_all () {

    local bin="${1:-}" path_value="${PATH:-}" sep="" dir="" entry="" ext="" found=1
    local -a dirs=() exts=()

    [[ -n "${bin}" ]] || return 1
    [[ "${bin}" != *$'\n'* && "${bin}" != *$'\r'* ]] || return 1

    case "${path_value}" in
        *";"*) sep=";" ;;
        *)     sep=":" ;;
    esac

    IFS="${sep}" read -r -a dirs <<< "${path_value}"

    if sys::is_windows; then exts=( "" ".exe" ".cmd" ".bat" ".ps1" )
    else exts=( "" )
    fi

    for dir in "${dirs[@]}"; do

        [[ -n "${dir}" ]] || continue

        for ext in "${exts[@]}"; do

            entry="${dir%/}/${bin}${ext}"
            [[ -f "${entry}" && -x "${entry}" ]] || continue

            printf '%s\n' "${entry}"
            found=0

        done

    done

    return "${found}"

}
sys::open () {

    local target="${1:-}" type="${2:-auto}" v=""

    [[ -z "${target}" || "${target}" == *$'\n'* || "${target}" == *$'\r'* ]] && return 1

    if [[ "${type}" == "app" ]]; then

        shift 2 || true

        if sys::has "${target}"; then
            "${target}" "$@" >/dev/null 2>&1 &
            sys::has disown && disown
            return 0
        fi
        if sys::has "${target}.exe"; then
            "${target}.exe" "$@" >/dev/null 2>&1 &
            sys::has disown && disown
            return 0
        fi

        return 1

    fi
    if [[ "${type}" == "auto" && -e "${target}" ]]; then

        type="path"

    fi

    if [[ "${type}" == "auto" || "${type}" == "url" ]]; then

        case "${target}" in
            www.*) target="https://${target}" ;;
            http://*|https://*|ftp://*|ftps://*|file://*|mailto:*|ssh://*) ;;
            localhost|localhost:*|localhost/*) target="http://${target}" ;;
            *)
                if [[ "${target}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:[0-9]+)?([/?#].*)?$ ]]; then target="http://${target}"
                elif [[ "${target}" =~ ^[A-Za-z0-9._-]+\.[A-Za-z0-9._-]+(:[0-9]+)?([/?#].*)?$ ]]; then target="https://${target}"
                else return 1
                fi
            ;;
        esac

        type="url"

    elif [[ "${type}" == "path" ]]; then

        [[ -e "${target}" ]] || return 1

    else

        return 1

    fi

    if sys::is_macos && sys::has open; then
        open "${target}" >/dev/null 2>&1
        return
    fi
    if sys::is_windows; then

        if [[ "${type}" == "path" ]] && sys::has cygpath; then
            v="$(cygpath -aw "${target}" 2>/dev/null || true)"
            [[ -n "${v}" ]] && target="${v}"
        fi
        if sys::has explorer.exe; then
            explorer.exe "${target}" >/dev/null 2>&1
            return
        fi
        if sys::has cmd.exe; then
            cmd.exe /C start "" "${target}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::has xdg-open; then
        xdg-open "${target}" >/dev/null 2>&1
        return
    fi

    return 1

}

sys::disk_df_field () {

    local path="${1:-.}" field="${2:-}" win="" norm="" distro="" linux_path="" v=""

    [[ -n "${path}" ]] || path="."
    [[ -e "${path}" ]] || return 1
    [[ "${field}" =~ ^[0-9]+$ ]] || return 1

    sys::is_windows || return 1

    sys::has wsl.exe || return 1
    sys::has cygpath && win="$(cygpath -aw "${path}" 2>/dev/null || true)"

    [[ -n "${win}" ]] || win="$(pwd -W 2>/dev/null || true)"
    [[ -n "${win}" ]] || return 1

    norm="${win//\\//}"

    if [[ "${norm}" =~ ^//wsl\$/([^/]+)(/.*)?$ ]]; then
        distro="${BASH_REMATCH[1]}"
        linux_path="${BASH_REMATCH[2]:-/}"
    elif [[ "${norm}" =~ ^//wsl[.]localhost/([^/]+)(/.*)?$ ]]; then
        distro="${BASH_REMATCH[1]}"
        linux_path="${BASH_REMATCH[2]:-/}"
    elif [[ "${norm}" =~ ^//[?]/UNC/wsl\$/([^/]+)(/.*)?$ ]]; then
        distro="${BASH_REMATCH[1]}"
        linux_path="${BASH_REMATCH[2]:-/}"
    elif [[ "${norm}" =~ ^//[?]/UNC/wsl[.]localhost/([^/]+)(/.*)?$ ]]; then
        distro="${BASH_REMATCH[1]}"
        linux_path="${BASH_REMATCH[2]:-/}"
    else
        return 1
    fi

    [[ -n "${distro}" && -n "${linux_path}" ]] || return 1

    v="$(MSYS2_ARG_CONV_EXCL="*" wsl.exe -d "${distro}" -- df -Pk "${linux_path}" 2>/dev/null |
        tr -d '\r' | awk -v f="${field}" 'NR > 1 && $f ~ /^[0-9]+$/ { print $f; exit }')"

    [[ "${v}" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$(( v * 1024 ))"

}
sys::disk_total () {

    local path="${1:-.}" v=""

    [[ -n "${path}" ]] || path="."
    [[ -e "${path}" ]] || return 1

    if sys::has df; then
        v="$(df -Pk "${path}" 2>/dev/null | awk -v f=2 'NR > 1 && $f ~ /^[0-9]+$/ { print $f; exit }')"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
    fi

    sys::disk_df_field "${path}" 2

}
sys::disk_free () {

    local path="${1:-.}" v=""

    [[ -n "${path}" ]] || path="."
    [[ -e "${path}" ]] || return 1

    if sys::has df; then
        v="$(df -Pk "${path}" 2>/dev/null | awk -v f=4 'NR > 1 && $f ~ /^[0-9]+$/ { print $f; exit }')"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
    fi

    sys::disk_df_field "${path}" 4

}
sys::disk_used () {

    local path="${1:-.}" total="" free=""

    total="$(sys::disk_total "${path}" 2>/dev/null || true)"
    free="$(sys::disk_free "${path}" 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${free}" =~ ^[0-9]+$ ]] || return 1
    (( free <= total )) || free="${total}"

    printf '%s\n' "$(( total - free ))"

}
sys::disk_percent () {

    local path="${1:-.}" total="" used=""

    total="$(sys::disk_total "${path}" 2>/dev/null || true)"
    used="$(sys::disk_used "${path}" 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${used}" =~ ^[0-9]+$ ]] || return 1
    (( total > 0 )) || return 1

    printf '%s\n' "$(( used * 100 / total ))"

}
sys::disk_size () {

    local path="${1:-}" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" ]] || return 1

    if sys::has du; then
        v="$(du -sk "${path}" 2>/dev/null | awk 'NR==1 {print $1}' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
    fi

    return 1

}
sys::disk_info () {

    local path="${1:-.}" total="" free="" used="" percent=""

    total="$(sys::disk_total "${path}" 2>/dev/null || true)"
    free="$(sys::disk_free "${path}" 2>/dev/null || true)"
    used="$(sys::disk_used "${path}" 2>/dev/null || true)"
    percent="$(sys::disk_percent "${path}" 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${free}" =~ ^[0-9]+$ ]] || return 1
    [[ "${used}" =~ ^[0-9]+$ ]] || return 1
    [[ "${percent}" =~ ^[0-9]+$ ]] || return 1

    printf '%s\n' "path=${path}" "total=${total}" "free=${free}" "used=${used}" "percent=${percent}"

}

sys::mem_total () {

    local v=""

    if sys::is_linux; then

        if [[ -r /proc/meminfo ]]; then
            v="$(sed -n 's/^MemTotal:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"
            [[ -n "${v}" ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
        fi

    fi
    if sys::is_macos; then

        v="$(sysctl -n hw.memsize 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then
            v="$(powershell.exe -NoProfile -Command "[int64](Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory" 2>/dev/null | tr -d '\r')"
            [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
        fi

    fi

    return 1

}
sys::mem_free () {

    local v="" a="" b="" c=""

    if sys::is_linux; then

        if [[ -r /proc/meminfo ]]; then

            v="$(sed -n 's/^MemAvailable:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"
            [[ -n "${v}" ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }

            a="$(sed -n 's/^MemFree:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"
            b="$(sed -n 's/^Buffers:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"
            c="$(sed -n 's/^Cached:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"

            [[ "${a}" =~ ^[0-9]+$ ]] || a=0
            [[ "${b}" =~ ^[0-9]+$ ]] || b=0
            [[ "${c}" =~ ^[0-9]+$ ]] || c=0

            printf '%s\n' "$(( ( a + b + c ) * 1024 ))"
            return 0

        fi

    fi
    if sys::is_macos; then

        if sys::has vm_stat && sys::has sysctl; then

            local page_size="" free_pages="" inactive_pages="" speculative_pages=""

            page_size="$(sysctl -n hw.pagesize 2>/dev/null || true)"
            free_pages="$(vm_stat 2>/dev/null | sed -n 's/^Pages free:[[:space:]]*\([0-9][0-9]*\)\.$/\1/p' | head -n 1)"
            inactive_pages="$(vm_stat 2>/dev/null | sed -n 's/^Pages inactive:[[:space:]]*\([0-9][0-9]*\)\.$/\1/p' | head -n 1)"
            speculative_pages="$(vm_stat 2>/dev/null | sed -n 's/^Pages speculative:[[:space:]]*\([0-9][0-9]*\)\.$/\1/p' | head -n 1)"

            [[ "${page_size}" =~ ^[0-9]+$ ]] || page_size=4096
            [[ "${free_pages}" =~ ^[0-9]+$ ]] || free_pages=0
            [[ "${inactive_pages}" =~ ^[0-9]+$ ]] || inactive_pages=0
            [[ "${speculative_pages}" =~ ^[0-9]+$ ]] || speculative_pages=0

            printf '%s\n' "$(( ( free_pages + inactive_pages + speculative_pages ) * page_size ))"
            return 0

        fi

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then
            v="$(powershell.exe -NoProfile -Command "[int64]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1024)" 2>/dev/null | tr -d '\r')"
            [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
        fi

    fi

    return 1

}
sys::mem_used () {

    local total="" free=""

    total="$(sys::mem_total 2>/dev/null || true)"
    free="$(sys::mem_free 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${free}" =~ ^[0-9]+$ ]] || return 1
    (( free <= total )) || free="${total}"

    printf '%s\n' "$(( total - free ))"

}
sys::mem_percent () {

    local total="" used=""

    total="$(sys::mem_total 2>/dev/null || true)"
    used="$(sys::mem_used 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${used}" =~ ^[0-9]+$ ]] || return 1
    (( total > 0 )) || return 1

    printf '%s\n' "$(( used * 100 / total ))"

}
sys::mem_info () {

    local total="" free="" used="" percent=""

    total="$(sys::mem_total 2>/dev/null)" || return 1
    free="$(sys::mem_free 2>/dev/null)"   || return 1

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${free}"  =~ ^[0-9]+$ ]] || return 1

    (( free <= total )) || free="${total}"
    used="$(( total - free ))"

    (( total > 0 )) || return 1
    percent="$(( used * 100 / total ))"

    printf 'total=%s\nfree=%s\nused=%s\npercent=%s\n' "${total}" "${free}" "${used}" "${percent}"

}

sys::cpu_threads () {

    local v=""

    if sys::has getconf; then
        v="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ && "${v}" -gt 0 ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if sys::is_linux && [[ -r /proc/cpuinfo ]]; then
        v="$(grep -c '^processor[[:space:]]*:' /proc/cpuinfo 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ && "${v}" -gt 0 ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if sys::is_macos && sys::has sysctl; then
        v="$(sysctl -n hw.logicalcpu 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ && "${v}" -gt 0 ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if sys::is_windows && sys::has powershell.exe; then
        v="$(powershell.exe -NoProfile -NonInteractive -Command "[Environment]::ProcessorCount" 2>/dev/null | tr -d '\r' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ && "${v}" -gt 0 ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    v="${NUMBER_OF_PROCESSORS:-}"
    [[ "${v}" =~ ^[0-9]+$ && "${v}" -gt 0 ]] && { printf '%s\n' "${v}"; return 0; }

    printf '%s\n' "1"

}
sys::cpu_cores () {

    local v=""

    if sys::is_linux && [[ -r /proc/cpuinfo ]]; then

        v="$(awk -F: '
            /physical id/ {
                gsub(/^[ \t]+/, "", $2)
                socket=$2
            }
            /cpu cores/ {
                gsub(/^[ \t]+/, "", $2)
                cores=$2
                if ( socket == "" ) socket=0
                if ( cores ~ /^[0-9]+$/ ) seen[socket]=cores
            }
            END {
                total=0
                for ( s in seen ) total += seen[s]
                if ( total > 0 ) print total
            }
        ' /proc/cpuinfo 2>/dev/null || true)"

        [[ "${v}" =~ ^[0-9]+$ && "${v}" -gt 0 ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_macos && sys::has sysctl; then

        v="$(sysctl -n hw.physicalcpu 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ && "${v}" -gt 0 ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_windows && sys::has powershell.exe; then

        v="$(powershell.exe -NoProfile -NonInteractive -Command "(Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores -Sum).Sum" 2>/dev/null | tr -d '\r' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ && "${v}" -gt 0 ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    sys::cpu_threads

}
sys::cpu_count () {

    sys::cpu_threads "$@"

}
sys::cpu_model () {

    local v=""

    if sys::is_linux && [[ -r /proc/cpuinfo ]]; then
        v="$(awk -F: '/model name|Hardware|Processor/ { sub(/^[ \t]+/, "", $2); print $2; exit }' /proc/cpuinfo 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if sys::is_macos && sys::has sysctl; then
        v="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi
    if sys::is_windows && sys::has powershell.exe; then
        v="$(powershell.exe -NoProfile -NonInteractive -Command "(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)" 2>/dev/null | tr -d '\r' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    v="${PROCESSOR_IDENTIFIER:-${PROCESSOR_ARCHITECTURE:-}}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    printf '%s\n' "unknown"
    return 1

}
sys::cpu_usage () {

    local a="" b="" c="" d="" e="" f="" g="" h="" i="" j="" idle_a="" total_a="" idle_b="" total_b="" diff_idle="" diff_total="" usage=""

    if sys::is_linux && [[ -r /proc/stat ]]; then

        read -r _ a b c d e f g h i j < /proc/stat || return 1

        idle_a=$(( d + e ))
        total_a=$(( a + b + c + d + e + f + g + h + i + j ))

        sleep 1

        read -r _ a b c d e f g h i j < /proc/stat || return 1

        idle_b=$(( d + e ))
        total_b=$(( a + b + c + d + e + f + g + h + i + j ))

        diff_idle=$(( idle_b - idle_a ))
        diff_total=$(( total_b - total_a ))

        (( diff_total > 0 )) || return 1

        usage=$(( ( 100 * ( diff_total - diff_idle ) ) / diff_total ))

        (( usage < 0 )) && usage=0
        (( usage > 100 )) && usage=100

        printf '%s\n' "${usage}"
        return 0

    fi
    if sys::is_macos && sys::has top; then

        usage="$(top -l 1 -n 0 2>/dev/null | awk -F'[:,% ]+' '
            /CPU usage/ {
                for ( i=1; i<=NF; i++ ) {
                    if ( $i == "idle" && i > 1 ) {
                        idle=$(i-1)
                        gsub(/[^0-9.]/, "", idle)
                        printf "%.0f\n", 100 - idle
                        exit
                    }
                }
            }
        ')"

        [[ "${usage}" =~ ^[0-9]+$ ]] || return 1

        (( usage < 0 )) && usage=0
        (( usage > 100 )) && usage=100

        printf '%s\n' "${usage}"
        return 0

    fi
    if sys::is_windows && sys::has powershell.exe; then

        usage="$(powershell.exe -NoProfile -NonInteractive -Command "[int](Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average" 2>/dev/null | tr -d '\r' | head -n 1)"

        [[ "${usage}" =~ ^[0-9]+$ ]] || return 1

        (( usage < 0 )) && usage=0
        (( usage > 100 )) && usage=100

        printf '%s\n' "${usage}"
        return 0

    fi

    return 1

}
sys::cpu_idle () {

    local usage=""

    usage="$(sys::cpu_usage 2>/dev/null || true)"
    [[ "${usage}" =~ ^[0-9]+$ ]] || return 1

    (( usage > 100 )) && usage=100
    printf '%s\n' "$(( 100 - usage ))"

}
sys::cpu_info () {

    local model="" cores="" threads="" usage="" idle=""

    model="$(sys::cpu_model 2>/dev/null || printf 'unknown')"
    cores="$(sys::cpu_cores 2>/dev/null || printf '1')"
    threads="$(sys::cpu_threads 2>/dev/null || printf '1')"
    usage="$(sys::cpu_usage 2>/dev/null || printf 'unknown')"

    if [[ "${usage}" =~ ^[0-9]+$ ]]; then
        (( usage > 100 )) && usage=100
        idle="$(( 100 - usage ))"
    else
        idle="unknown"
    fi

    printf '%s\n' "model=${model}" "cores=${cores}" "threads=${threads}" "usage=${usage}" "idle=${idle}"

}

sys::bash () {

    local v=""
    v="${BASH:-}"

    [[ -n "${v}" ]] || v="${0:-}"
    [[ -n "${v}" ]] || return 1

    printf '%s\n' "${v}"

}
sys::bash_version () {

    local v="${BASH_VERSION:-}"

    [[ -n "${v}" ]] || return 1

    printf '%s\n' "${v}"

}
sys::bash_major () {

    local v="${BASH_VERSINFO[0]:-}"

    [[ "${v}" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "${v}"

}
sys::bash_minor () {

    local v="${BASH_VERSINFO[1]:-}"

    [[ "${v}" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "${v}"

}
sys::bash_msrv () {

    local need="${1:-}" cur="${2:-${BASH_VERSION:-}}" n1=0 n2=0 n3=0 c1=0 c2=0 c3=0

    [[ "${need}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]] || return 1
    [[ "${cur}" =~ ^([0-9]+)([.]([0-9]+))?([.]([0-9]+))? ]] || return 1

    IFS=. read -r n1 n2 n3 <<< "${need}"

    c1="${BASH_REMATCH[1]:-0}"; c2="${BASH_REMATCH[3]:-0}"; c3="${BASH_REMATCH[5]:-0}"
    n1="${n1:-0}"; n2="${n2:-0}"; n3="${n3:-0}"
    c1="${c1:-0}"; c2="${c2:-0}"; c3="${c3:-0}"

    (( c1 > n1 )) && return 0
    (( c1 < n1 )) && return 1
    (( c2 > n2 )) && return 0
    (( c2 < n2 )) && return 1

    (( c3 >= n3 ))

}
sys::bash_ok () {

    local bin="${1:-}" need="${2:-}" cur=""

    [[ -n "${bin}" && -n "${need}" ]] || return 1

    sys::has "${bin}" && bin="$(command -v -- "${bin}" 2>/dev/null || true)"
    [[ -x "${bin}" ]] || return 1

    # shellcheck disable=SC2016
    cur="$("${bin}" -c 'printf "%s\n" "${BASH_VERSION:-}"' 2>/dev/null || true)"

    sys::bash_msrv "${need}" "${cur}"

}
sys::find_bash () {

    local need="${1:-}" bin="" resolved=""

    [[ "${need}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]] || return 1

    for bin in \
        "${BASHX_BASH:-}" \
        bash \
        /opt/homebrew/bin/bash \
        /usr/local/bin/bash \
        /usr/bin/bash \
        /bin/bash \
        /mingw64/bin/bash.exe \
        /usr/bin/bash.exe \
        /c/Program\ Files/Git/bin/bash.exe \
        /c/Program\ Files/Git/usr/bin/bash.exe
    do

        [[ -n "${bin}" ]] || continue

        if sys::has "${bin}"; then resolved="$(command -v -- "${bin}" 2>/dev/null || true)"
        else resolved="${bin}"
        fi

        sys::bash_ok "${resolved}" "${need}" || continue
        printf '%s\n' "${resolved}"

        return 0

    done

    return 1

}
sys::install_bash () {

    local manager=""

    manager="$(sys::pkg_manager 2>/dev/null || true)"
    [[ -n "${manager}" && "${manager}" != "unknown" ]] || return 1

    case "${manager}" in
        apt)
            if sys::is_root; then apt-get update -y && apt-get install -y bash
            else sys::can_sudo && sudo apt-get update -y && sudo apt-get install -y bash
            fi
        ;;
        apk)
            if sys::is_root; then apk add --no-cache bash
            else sys::can_sudo && sudo apk add --no-cache bash
            fi
        ;;
        dnf)
            if sys::is_root; then dnf install -y bash
            else sys::can_sudo && sudo dnf install -y bash
            fi
        ;;
        yum)
            if sys::is_root; then yum install -y bash
            else sys::can_sudo && sudo yum install -y bash
            fi
        ;;
        pacman)
            if sys::is_root; then pacman -S --needed --noconfirm bash
            else sys::can_sudo && sudo pacman -S --needed --noconfirm bash
            fi
        ;;
        zypper)
            if sys::is_root; then zypper --non-interactive install bash
            else sys::can_sudo && sudo zypper --non-interactive install bash
            fi
        ;;
        xbps)
            if sys::is_root; then xbps-install -Sy bash
            else sys::can_sudo && sudo xbps-install -Sy bash
            fi
        ;;
        brew)
            brew install bash
        ;;
        port)
            if sys::is_root; then port install bash
            else sys::can_sudo && sudo port install bash
            fi
        ;;
        winget)
            winget upgrade --id Git.Git -e --accept-source-agreements --accept-package-agreements ||
            winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
        ;;
        scoop)
            scoop update git || scoop install git
        ;;
        choco)
            choco upgrade git -y || choco install git -y
        ;;
        *)
            return 1
        ;;
    esac

}
sys::ensure_bash () {

    local need="${1:-}" found="" script=""

    if [[ "${need}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]]; then shift || true
    else need="${MIN_BASH_VERSION:-${MSRV_BASH_VERSION:-${MSRV_VERSION:-5}}}"
    fi

    [[ "${need}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]] || exit 1
    sys::bash_msrv "${need}" && { export ENSURE_MIN_BASH_VERSION_DONE=1; return 0; }

    [[ "${ENSURE_MIN_BASH_VERSION_DONE:-}" == "1" ]] && exit 1
    found="$(sys::find_bash "${need}" 2>/dev/null || true)"

    if [[ -z "${found}" ]]; then

        sys::install_bash || exit 1
        hash -r 2>/dev/null || true
        found="$(sys::find_bash "${need}" 2>/dev/null || true)"

    fi

    [[ -n "${found}" ]] || exit 1

    script="${0:-}"
    [[ -z "${script}" || ! -f "${script}" ]] && script="${BASH_SOURCE[0]:-${0:-}}"
    [[ -n "${script}" && -f "${script}" ]] || exit 1

    ENSURE_MIN_BASH_VERSION_DONE=1 exec "${found}" "${script}" "$@"

}
