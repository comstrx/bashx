
user::valid () {

    local v="${1:-}"

    [[ -n "${v}" ]] || return 1
    [[ "${v}" != *$'\n'* && "${v}" != *$'\r'* ]] || return 1
    [[ "${v}" != *'*'* && "${v}" != *'?'* && "${v}" != *'['* && "${v}" != *']'* ]] || return 1
    [[ "${v}" != *'/'* ]] || return 1
    [[ "${v}" != *"\\"* ]] || return 1

}
user::lock () {

    local name="${1:-}" run="${2:-}" code="" root="" lock="" pid="" old="" i=0 rc=0

    shift 2 || return 1
    user::valid "${name}" || return 1

    [[ -n "${run}" ]] || return 1
    [[ "${run}" != "--" ]] && { declare -F "${run}" >/dev/null 2>&1 || return 1; }

    root="${TMPDIR:-/tmp}/bash-permissions-locks"
    lock="${root}/${name}.lock"
    pid="${lock}/pid"

    mkdir -p -- "${root}" >/dev/null 2>&1 || return 1

    while ! mkdir -- "${lock}" 2>/dev/null; do

        old=""
        [[ -r "${pid}" ]] && { IFS= read -r old < "${pid}" || true; }

        if [[ "${old}" =~ ^[0-9]+$ ]] && ! kill -0 "${old}" 2>/dev/null; then
            rm -rf -- "${lock}" >/dev/null 2>&1 || true
            continue
        fi

        (( i++ < 200 )) || return 1
        sleep 0.05

    done

    printf '%s\n' "$$" > "${pid}" || { rm -rf -- "${lock}" >/dev/null 2>&1 || true; return 1; }

    if [[ "${run}" == "--" ]]; then

        if [[ $# -gt 0 && "${1:-}" == *$'\n'* ]]; then
            code="${1}"
            shift
            command bash -c "${code}" _ "$@"
            rc=$?
        else
            command bash -s -- "$@"
            rc=$?
        fi

    else

        "${run}" "$@"
        rc=$?

    fi

    rm -rf -- "${lock}" >/dev/null 2>&1 || true
    return "${rc}"

}
user::id () {

    local user="${1:-}" current="" v=""

    current="$(user::name 2>/dev/null || true)"
    [[ -n "${user}" ]] || user="${current}"

    user::exists "${user}" || return 1

    if sys::is_windows && sys::has powershell.exe; then

        if [[ "${user}" == "${current}" ]]; then

            v="$(powershell.exe -NoProfile -NonInteractive -Command "[Security.Principal.WindowsIdentity]::GetCurrent().User.Value.Split('-')[-1]" 2>/dev/null | tr -d '\r' || true)"
            [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

        else

            # shellcheck disable=SC2016
            v="$(SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                try {
                    $sid = ( Get-LocalUser -Name $env:SYS_USER_QUERY -ErrorAction Stop ).SID.Value
                    $sid.Split( "-" )[ -1 ]
                    exit 0
                } catch {
                    exit 1
                }
            ' 2>/dev/null | tr -d '\r' || true)"

            [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

        fi

    fi
    if sys::has id; then

        v="$(id -u "${user}" 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
user::name () {

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
user::exists () {

    local user="${1:-}" group="${2:-}" current="" v="" x="" found=0

    user::valid "${user}" || return 1
    [[ -n "${group}" ]] && { group::valid "${group}" || return 1; }

    current="$(user::name 2>/dev/null || true)"

    if [[ -n "${current}" && "${user}" == "${current}" ]]; then

        [[ -n "${group}" ]] || return 0

        v="$(group::all "${user}" 2>/dev/null || true)"
        [[ -n "${v}" ]] || return 1

        while IFS= read -r x || [[ -n "${x}" ]]; do
            [[ "${x}" == "${group}" ]] && return 0
        done <<< "${v}"

        return 1

    fi

    if sys::is_linux; then

        if sys::has getent; then
            getent passwd "${user}" >/dev/null 2>&1 || return 1
        elif [[ -r /etc/passwd ]]; then
            awk -F: -v u="${user}" '$1 == u { found = 1; exit } END { exit(found ? 0 : 1) }' /etc/passwd >/dev/null 2>&1 || return 1
        else
            return 1
        fi

    elif sys::is_macos; then

        sys::has dscl || return 1
        dscl . -read "/Users/${user}" >/dev/null 2>&1 || return 1

    elif sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                try { Get-LocalUser -Name $env:SYS_USER_QUERY -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }
            ' >/dev/null 2>&1 || return 1

        elif sys::has net.exe; then
            net.exe user "${user}" >/dev/null 2>&1 || return 1
        else
            return 1
        fi

    else

        return 1

    fi

    [[ -n "${group}" ]] || return 0

    v="$(group::all "${user}" 2>/dev/null || true)"
    [[ -n "${v}" ]] || return 1

    while IFS= read -r x || [[ -n "${x}" ]]; do
        [[ "${x}" == "${group}" ]] && return 0
    done <<< "${v}"

    return 1

}
user::add () {

    local user="${1:-}" group="${2:-}" pass=""

    user::valid "${user}" || return 1
    [[ -n "${group}" ]] || group="$(group::name 2>/dev/null || true)"

    group::exists "${group}" || return 1
    user::exists "${user}" "${group}" && return 0
    user::exists "${user}" && return 1

    if sys::is_linux; then

        if sys::has useradd; then
            useradd -m -g "${group}" "${user}" >/dev/null 2>&1
            return
        fi
        if sys::has adduser; then
            adduser --disabled-password --gecos "" --ingroup "${group}" "${user}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        # shellcheck disable=SC2016
        user::lock "__macos_user_add" -- '
            user="${1:-}"
            group="${2:-}"
            uid=""
            gid=""
            home=""
            shell=""

            command -v dscl >/dev/null 2>&1 || exit 1
            command -v dscacheutil >/dev/null 2>&1 || exit 1

            uid="$(dscl . -list /Users UniqueID 2>/dev/null | awk '"'"'
                $2 ~ /^[0-9]+$/ && $2 >= 500 {
                    if ( $2 > max ) max = $2
                }
                END {
                    if ( max < 500 ) max = 500
                    print max + 1
                }
            '"'"')"

            [[ "${uid}" =~ ^[0-9]+$ ]] || exit 1

            gid="$(dscacheutil -q group -a name "${group}" 2>/dev/null | awk '"'"'/gid:/ { print $2; exit }'"'"')"
            [[ "${gid}" =~ ^[0-9]+$ ]] || exit 1

            home="/Users/${user}"
            shell="/bin/bash"

            dscl . -create "/Users/${user}" >/dev/null 2>&1 || exit 1
            dscl . -create "/Users/${user}" UserShell "${shell}" >/dev/null 2>&1 || exit 1
            dscl . -create "/Users/${user}" RealName "${user}" >/dev/null 2>&1 || true
            dscl . -create "/Users/${user}" UniqueID "${uid}" >/dev/null 2>&1 || exit 1
            dscl . -create "/Users/${user}" PrimaryGroupID "${gid}" >/dev/null 2>&1 || exit 1
            dscl . -create "/Users/${user}" NFSHomeDirectory "${home}" >/dev/null 2>&1 || exit 1

            if command -v createhomedir >/dev/null 2>&1; then
                createhomedir -c -u "${user}" >/dev/null 2>&1 || true
            fi
        ' "${user}" "${group}"

        return

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                try {
                    $name  = $env:SYS_USER_QUERY
                    $group = $env:SYS_GROUP_QUERY
                    $pass  = [Guid]::NewGuid().ToString("N") + "aA1!"

                    $secure = ConvertTo-SecureString $pass -AsPlainText -Force

                    New-LocalUser `
                        -Name $name `
                        -Password $secure `
                        -PasswordNeverExpires `
                        -AccountNeverExpires `
                        -ErrorAction Stop | Out-Null

                    Add-LocalGroupMember -Group $group -Member $name -ErrorAction Stop
                    exit 0
                } catch {
                    try { Remove-LocalUser -Name $env:SYS_USER_QUERY -ErrorAction SilentlyContinue } catch {}
                    exit 1
                }
            ' >/dev/null 2>&1

            return

        fi
        if sys::has net.exe; then

            pass="Bx$(date +%s)${RANDOM}aA1!"
            net.exe user "${user}" "${pass}" /add >/dev/null 2>&1 || return 1

            net.exe localgroup "${group}" "${user}" /add >/dev/null 2>&1 || {
                net.exe user "${user}" /delete >/dev/null 2>&1 || true
                return 1
            }

            return 0

        fi

        return 1

    fi

    return 1

}
user::del () {

    local user="${1:-}" group="${2:-}"

    user::valid "${user}" || return 1
    [[ -n "${group}" ]] && { user::exists "${user}" "${group}" || return 1; }
    user::exists "${user}" || return 0

    if sys::is_linux; then

        if sys::has userdel; then
            userdel "${user}" >/dev/null 2>&1
            return
        fi
        if sys::has deluser; then
            deluser "${user}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        if sys::has sysadminctl; then
            sysadminctl -deleteUser "${user}" >/dev/null 2>&1
            return
        fi
        if sys::has dscl; then
            dscl . -delete "/Users/${user}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                try { Remove-LocalUser -Name $env:SYS_USER_QUERY -ErrorAction Stop; exit 0 } catch { exit 1 }
            ' >/dev/null 2>&1

            return

        fi
        if sys::has net.exe; then
            net.exe user "${user}" /delete >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}
user::all () {

    local group="${1:-}" user="" found=0

    if [[ -z "${group}" ]]; then

        if sys::is_linux; then

            if sys::has getent; then
                getent passwd 2>/dev/null | awk -F: '{ print $1 }' | awk 'NF && !seen[$0]++ { print }'
                return
            fi

            [[ -r /etc/passwd ]] || return 1
            awk -F: '{ print $1 }' /etc/passwd 2>/dev/null | awk 'NF && !seen[$0]++ { print }'

            return

        fi
        if sys::is_macos; then

            sys::has dscl || return 1
            dscl . -list /Users 2>/dev/null | awk 'NF && !seen[$0]++ { print }'

            return

        fi
        if sys::is_windows; then

            if sys::has powershell.exe; then
                powershell.exe -NoProfile -NonInteractive -Command "Get-LocalUser | Select-Object -ExpandProperty Name" 2>/dev/null | tr -d '\r' | awk 'NF && !seen[$0]++ { print }'
                return
            fi
            if sys::has net.exe; then

                net.exe user 2>/dev/null | tr -d '\r' | awk '
                    BEGIN { cap = 0 }
                    /^---/ { cap = 1; next }
                    /^The command completed successfully\./ { cap = 0 }
                    cap {
                        for ( i = 1; i <= NF; i++ ) print $i
                    }
                ' | awk 'NF && !seen[$0]++ { print }'

                return

            fi

            return 1

        fi

        return 1

    fi

    group::exists "${group}" || return 1

    if sys::is_windows && sys::has powershell.exe; then

        # shellcheck disable=SC2016
        SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
            try {
                Get-LocalGroupMember -Group $env:SYS_GROUP_QUERY -ErrorAction Stop | ForEach-Object {
                    if ( $_.ObjectClass -eq "User" ) { ( $_.Name -split "\\" )[ -1 ] }
                }
                exit 0
            } catch {
                exit 1
            }
        ' 2>/dev/null | tr -d '\r' | awk 'NF && !seen[$0]++ { print }'

        return

    fi
    if sys::is_linux; then

        while IFS=: read -r _user _x _uid _gid _rest || [[ -n "${_user:-}" ]]; do

            [[ -n "${_user:-}" ]] || continue

            if [[ "${_gid:-}" =~ ^[0-9]+$ ]]; then

                if sys::has getent; then
                    user="$(getent group "${_gid}" 2>/dev/null | awk -F: 'NR == 1 { print $1 }')"
                else
                    user="$(awk -F: -v g="${_gid}" '$3 == g { print $1; exit }' /etc/group 2>/dev/null)"
                fi

                if [[ "${user}" == "${group}" ]]; then
                    printf '%s\n' "${_user}"
                    found=1
                    continue
                fi

            fi
            if group::all "${_user}" 2>/dev/null | grep -Fqx -- "${group}"; then
                printf '%s\n' "${_user}"
                found=1
            fi

        done < <(
            if sys::has getent; then getent passwd 2>/dev/null
            else cat /etc/passwd 2>/dev/null
            fi
        )

    fi
    if sys::is_macos; then

        while IFS= read -r user || [[ -n "${user}" ]]; do

            [[ -n "${user}" ]] || continue

            if [[ "$(user::group "${user}" 2>/dev/null || true)" == "${group}" ]]; then
                printf '%s\n' "${user}"
                found=1
                continue
            fi
            if group::all "${user}" 2>/dev/null | grep -Fqx -- "${group}"; then
                printf '%s\n' "${user}"
                found=1
            fi

        done < <(dscl . -list /Users 2>/dev/null)

    fi

    (( found )) || return 1

}
user::groups () {

    local user="${1:-}" current=""

    current="$(user::name 2>/dev/null || true)"
    [[ -n "${user}" ]] || user="${current}"

    user::exists "${user}" || return 1

    group::all "${user}"

}
user::add_group () {

    local user="${1:-}" group="${2:-}"

    user::exists "${user}" || return 1
    group::exists "${group}" || group::add "${group}" || return 1

    user::exists "${user}" "${group}" && return 0

    if sys::is_linux; then

        if sys::has usermod; then
            usermod -a -G "${group}" "${user}" >/dev/null 2>&1
            return
        fi
        if sys::has gpasswd; then
            gpasswd -a "${user}" "${group}" >/dev/null 2>&1
            return
        fi
        if sys::has adduser; then
            adduser "${user}" "${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        sys::has dseditgroup || return 1
        dseditgroup -o edit -a "${user}" -t user "${group}" >/dev/null 2>&1
        return

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                try { Add-LocalGroupMember -Group $env:SYS_GROUP_QUERY -Member $env:SYS_USER_QUERY -ErrorAction Stop; exit 0 } catch { exit 1 }
            ' >/dev/null 2>&1

            return

        fi
        if sys::has net.exe; then
            net.exe localgroup "${group}" "${user}" /add >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}
user::del_group () {

    local user="${1:-}" group="${2:-}"

    user::exists "${user}" || return 1
    group::exists "${group}" || return 1

    user::exists "${user}" "${group}" || return 0

    if sys::is_linux; then

        if sys::has gpasswd; then
            gpasswd -d "${user}" "${group}" >/dev/null 2>&1
            return
        fi
        if sys::has deluser; then
            deluser "${user}" "${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        sys::has dseditgroup || return 1
        dseditgroup -o edit -d "${user}" -t user "${group}" >/dev/null 2>&1
        return

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                try { Remove-LocalGroupMember -Group $env:SYS_GROUP_QUERY -Member $env:SYS_USER_QUERY -ErrorAction Stop; exit 0 } catch { exit 1 }
            ' >/dev/null 2>&1

            return

        fi
        if sys::has net.exe; then
            net.exe localgroup "${group}" "${user}" /delete >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}

user::group () {

    local user="${1:-}" current="" v=""

    current="$(user::name 2>/dev/null || true)"
    [[ -n "${user}" ]] || user="${current}"

    user::exists "${user}" || return 1

    if sys::is_windows && sys::has powershell.exe; then

        # shellcheck disable=SC2016
        v="$(SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
            $u = $env:SYS_USER_QUERY
            $first = $null
            $users = $null
            $admins = $null

            Get-LocalGroup | ForEach-Object {
                try {
                    $name = $_.Name
                    $hit = Get-LocalGroupMember -Group $name -ErrorAction Stop | Where-Object {
                        $short = ( $_.Name -split "\\" )[ -1 ]
                        $short -eq $u -or $_.Name -eq $u
                    }

                    if ( $hit ) {
                        if ( $name -eq "Users" ) { $users = $name }
                        elseif ( $name -eq "Administrators" ) { $admins = $name }
                        elseif ( -not $first ) { $first = $name }
                    }
                } catch {}
            }

            if ( $users ) { $users; exit 0 }
            if ( $admins ) { $admins; exit 0 }
            if ( $first ) { $first; exit 0 }

            exit 1
        ' 2>/dev/null | tr -d '\r' | head -n 1 || true)"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has id; then

        if [[ -n "${current}" && "${user}" == "${current}" ]]; then v="$(id -gn 2>/dev/null || true)"
        else v="$(id -gn "${user}" 2>/dev/null || true)"
        fi

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
user::home () {

    local user="${1:-}" current="" v=""

    current="$(user::name 2>/dev/null || true)"
    [[ -n "${user}" ]] || user="${current}"

    user::exists "${user}" || return 1

    if sys::is_windows; then

        if [[ "${user}" == "${current}" ]]; then

            [[ -n "${HOME:-}" ]]        && { printf '%s\n' "${HOME}"; return 0; }
            [[ -n "${USERPROFILE:-}" ]] && { printf '%s\n' "${USERPROFILE}"; return 0; }

        fi
        if sys::has powershell.exe; then

            if [[ "${user}" == "${current}" ]]; then

                v="$(powershell.exe -NoProfile -NonInteractive -Command "[Environment]::GetFolderPath('UserProfile')" 2>/dev/null | tr -d '\r' | head -n 1 || true)"

            else

                # shellcheck disable=SC2016
                v="$(SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                    try {
                        $name = $env:SYS_USER_QUERY
                        $u = Get-LocalUser -Name $name -ErrorAction Stop
                        $sid = $u.SID.Value
                        $reg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"

                        try {
                            $p = ( Get-ItemProperty -Path $reg -ErrorAction Stop ).ProfileImagePath
                            if ( $p ) { $p; exit 0 }
                        } catch {}

                        $base = $env:SystemDrive
                        if ( -not $base ) { $base = "C:" }

                        "$base\Users\$name"
                        exit 0
                    } catch {
                        exit 1
                    }
                ' 2>/dev/null | tr -d '\r' | head -n 1 || true)"

            fi

            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        fi

        return 1

    fi
    if [[ "${user}" == "${current}" && -n "${HOME:-}" ]]; then

        printf '%s\n' "${HOME}"
        return 0

    fi
    if sys::is_linux; then

        if sys::has getent; then

            v="$(getent passwd "${user}" 2>/dev/null | awk -F: 'NR == 1 { print $6 }')"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        fi

        [[ -r /etc/passwd ]] || return 1

        v="$(awk -F: -v u="${user}" '$1 == u { print $6; exit }' /etc/passwd 2>/dev/null)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        sys::has dscl || return 1

        v="$(dscl . -read "/Users/${user}" NFSHomeDirectory 2>/dev/null | awk 'NR == 1 { print $2 }')"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        return 1

    fi

    return 1

}
user::shell () {

    local user="${1:-}" current="" v=""

    current="$(user::name 2>/dev/null || true)"
    [[ -n "${user}" ]] || user="${current}"

    user::exists "${user}" || return 1

    if sys::is_windows; then

        if [[ "${user}" == "${current}" && -n "${COMSPEC:-}" ]]; then

            printf '%s\n' "${COMSPEC}"
            return 0

        fi
        if sys::has powershell.exe; then

            v="$(powershell.exe -NoProfile -NonInteractive -Command "(Get-Command powershell.exe).Source" 2>/dev/null | tr -d '\r' | head -n 1 || true)"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        fi

        [[ -n "${COMSPEC:-}" ]] && { printf '%s\n' "${COMSPEC}"; return 0; }

        printf '%s\n' "powershell.exe"
        return 0

    fi
    if [[ "${user}" == "${current}" && -n "${SHELL:-}" ]]; then

        printf '%s\n' "${SHELL}"
        return 0

    fi
    if sys::is_linux; then

        if sys::has getent; then

            v="$(getent passwd "${user}" 2>/dev/null | awk -F: 'NR == 1 { print $7 }')"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        fi

        [[ -r /etc/passwd ]] || return 1

        v="$(awk -F: -v u="${user}" '$1 == u { print $7; exit }' /etc/passwd 2>/dev/null)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        sys::has dscl || return 1

        v="$(dscl . -read "/Users/${user}" UserShell 2>/dev/null | awk 'NR == 1 { print $2 }')"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        return 1

    fi

    return 1

}
user::is_root () {

    local user="${1:-}" current="" id=""

    current="$(user::name 2>/dev/null || true)"
    [[ -n "${user}" ]] || user="${current}"

    user::exists "${user}" || return 1

    if sys::is_windows; then

        if sys::has powershell.exe; then

            if [[ "${user}" == "${current}" ]]; then

                powershell.exe -NoProfile -NonInteractive -Command '
                    [bool](([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
                ' 2>/dev/null | tr -d '\r' | grep -qi '^True$'

                return

            fi

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                try {
                    $u = $env:SYS_USER_QUERY
                    $hit = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop | Where-Object {
                        $short = ( $_.Name -split "\\" )[ -1 ]
                        $short -eq $u -or $_.Name -eq $u
                    }

                    if ( $hit ) { exit 0 }
                    exit 1
                } catch {
                    exit 1
                }
            ' >/dev/null 2>&1

            return

        fi

        [[ "${user}" == "${current}" ]] || return 1

        sys::has net.exe && net.exe session >/dev/null 2>&1
        return

    fi

    id="$(user::id "${user}" 2>/dev/null || true)"
    [[ "${id}" == "0" ]]

}
user::is_admin () {

    local user="${1:-}" current="" v="" x=""

    current="$(user::name 2>/dev/null || true)"
    [[ -n "${user}" ]] || user="${current}"

    user::exists "${user}" || return 1
    user::is_root "${user}" && return 0

    v="$(group::all "${user}" 2>/dev/null || true)"
    [[ -n "${v}" ]] || return 1

    for x in ${v}; do
        [[ "${x}" == "sudo"           ]] && return 0
        [[ "${x}" == "wheel"          ]] && return 0
        [[ "${x}" == "admin"          ]] && return 0
        [[ "${x}" == "Administrators" ]] && return 0
    done

    return 1

}
user::can_sudo () {

    local user="${1:-}" current=""

    sys::is_windows && return 1

    current="$(user::name 2>/dev/null || true)"
    [[ -n "${user}" ]] || user="${current}"

    user::exists "${user}" || return 1
    sys::has sudo || return 1

    user::is_root "${user}" && return 0

    [[ "${user}" == "${current}" ]] && { sudo -n -v >/dev/null 2>&1; return; }

    user::is_root || sudo -n -v >/dev/null 2>&1 || return 1
    sudo -n -l -U "${user}" >/dev/null 2>&1

}

group::valid () {

    user::valid "$@"

}
group::lock () {

    user::lock "$@"

}
group::id () {

    local group="${1:-}" v=""

    [[ -n "${group}" ]] || group="$(group::name 2>/dev/null || true)"
    group::valid "${group}" || return 1

    if sys::is_windows && sys::has powershell.exe; then

        # shellcheck disable=SC2016
        v="$(SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
            try {
                $sid = ( Get-LocalGroup -Name $env:SYS_GROUP_QUERY -ErrorAction Stop ).SID.Value
                $sid.Split( "-" )[ -1 ]
                exit 0
            } catch {
                exit 1
            }
        ' 2>/dev/null | tr -d '\r' || true)"

        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_macos && sys::has dscl; then

        v="$(dscl . -read "/Groups/${group}" PrimaryGroupID 2>/dev/null | awk 'NR == 1 { print $2 }')"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has getent; then

        v="$(getent group "${group}" 2>/dev/null | awk -F: 'NR == 1 { print $3 }')"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if [[ -r /etc/group ]]; then

        v="$(awk -F: -v g="${group}" '$1 == g { print $3; exit }' /etc/group 2>/dev/null)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has id && [[ "${group}" == "$(group::name 2>/dev/null || true)" ]]; then

        v="$(id -g 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
group::name () {

    local v=""

    if sys::is_windows; then

        v="$(user::group 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has id; then

        v="$(id -gn 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
group::exists () {

    local group="${1:-}" found=0

    group::valid "${group}" || return 1

    if sys::is_linux; then

        if sys::has getent; then
            getent group "${group}" >/dev/null 2>&1 || return 1
        elif [[ -r /etc/group ]]; then
            awk -F: -v g="${group}" '$1 == g { found = 1; exit } END { exit(found ? 0 : 1) }' /etc/group >/dev/null 2>&1 || return 1
        else
            return 1
        fi

        return 0

    fi
    if sys::is_macos; then

        sys::has dscl || return 1
        dscl . -read "/Groups/${group}" >/dev/null 2>&1 || return 1
        return 0

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                try { Get-LocalGroup -Name $env:SYS_GROUP_QUERY -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }
            ' >/dev/null 2>&1 || return 1

        elif sys::has net.exe; then
            net.exe localgroup "${group}" >/dev/null 2>&1 || return 1
        else
            return 1
        fi

        return 0

    fi

    return 1

}
group::add () {

    local group="${1:-}" gid=""

    group::valid "${group}" || return 1
    group::exists "${group}" && return 0

    if sys::is_linux; then

        if sys::has groupadd; then
            groupadd "${group}" >/dev/null 2>&1
            return
        fi
        if sys::has addgroup; then
            addgroup "${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        sys::has dscl || return 1

        gid="$(dscl . -list /Groups PrimaryGroupID 2>/dev/null | awk '
            $2 ~ /^[0-9]+$/ && $2 >= 500 {
                if ( $2 > max ) max = $2
            }
            END {
                if ( max < 500 ) max = 500
                print max + 1
            }
        ')"

        [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

        dscl . -create "/Groups/${group}" >/dev/null 2>&1 || return 1
        dscl . -create "/Groups/${group}" PrimaryGroupID "${gid}" >/dev/null 2>&1 || return 1
        dscl . -create "/Groups/${group}" RealName "${group}" >/dev/null 2>&1 || true

        return 0

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                try { New-LocalGroup -Name $env:SYS_GROUP_QUERY -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }
            ' >/dev/null 2>&1

            return

        fi
        if sys::has net.exe; then
            net.exe localgroup "${group}" /add >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}
group::del () {

    local group="${1:-}"

    group::valid "${group}" || return 1
    group::exists "${group}" || return 0

    if sys::is_linux; then

        if sys::has groupdel; then
            groupdel "${group}" >/dev/null 2>&1
            return
        fi
        if sys::has delgroup; then
            delgroup "${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        if sys::has dscl; then
            dscl . -delete "/Groups/${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                try { Remove-LocalGroup -Name $env:SYS_GROUP_QUERY -ErrorAction Stop; exit 0 } catch { exit 1 }
            ' >/dev/null 2>&1

            return

        fi
        if sys::has net.exe; then
            net.exe localgroup "${group}" /delete >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}
group::all () {

    local user="${1:-}" current="" v="" x=""

    current="$(user::name 2>/dev/null || true)"
    [[ -n "${user}" ]] && { user::exists "${user}" || return 1; }

    if sys::is_windows; then

        if sys::has powershell.exe; then

            if [[ -n "${user}" ]]; then

                # shellcheck disable=SC2016
                v="$(SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                    $u = $env:SYS_USER_QUERY
                    $out = @()

                    try {
                        Get-LocalUser -Name $u -ErrorAction Stop | Out-Null

                        Get-LocalGroup | ForEach-Object {
                            try {
                                $name = $_.Name
                                $hit = Get-LocalGroupMember -Group $name -ErrorAction Stop | Where-Object {
                                    $short = ( $_.Name -split "\\" )[ -1 ]
                                    $short -eq $u -or $_.Name -eq $u
                                }

                                if ( $hit ) { $out += $name }
                            } catch {}
                        }

                        if ( $out.Count -lt 1 ) { exit 1 }

                        $out | Select-Object -Unique
                        exit 0
                    } catch {
                        exit 1
                    }
                ' 2>/dev/null | tr -d '\r' || true)"

                [[ -n "${v}" ]] || return 1

                printf '%s\n' "${v}" | awk 'NF && !seen[$0]++ { print }'
                return 0

            fi

            v="$(powershell.exe -NoProfile -NonInteractive -Command '
                try {
                    Get-LocalGroup | Select-Object -ExpandProperty Name
                    exit 0
                } catch {
                    exit 1
                }
            ' 2>/dev/null | tr -d '\r' || true)"

            [[ -n "${v}" ]] || return 1

            printf '%s\n' "${v}" | awk 'NF && !seen[$0]++ { print }'
            return 0

        fi
        if sys::has net.exe; then

            if [[ -n "${user}" ]]; then

                v="$(
                    net.exe localgroup 2>/dev/null | tr -d '\r' | awk '
                        BEGIN { cap = 0 }
                        /^---/ { cap = 1; next }
                        /^The command completed successfully\./ { cap = 0 }
                        cap {
                            line = $0
                            sub(/^[[:space:]]+/, "", line)
                            sub(/[[:space:]]+$/, "", line)
                            if ( line != "" ) print line
                        }
                    ' | while IFS= read -r x || [[ -n "${x}" ]]; do

                        [[ -n "${x}" ]] || continue

                        net.exe localgroup "${x}" 2>/dev/null | tr -d '\r' | awk -v u="${user}" -v g="${x}" '
                            {
                                line = $0
                                sub(/^[[:space:]]+/, "", line)
                                sub(/[[:space:]]+$/, "", line)

                                n = split(line, parts, "\\")
                                short = parts[n]

                                if ( line == u || short == u ) {
                                    print g
                                    exit
                                }
                            }
                        '

                    done | awk 'NF && !seen[$0]++ { print }'
                )"

                [[ -n "${v}" ]] || return 1
                printf '%s\n' "${v}"
                return 0

            fi

            v="$(net.exe localgroup 2>/dev/null | tr -d '\r' | awk '
                BEGIN { cap = 0 }
                /^---/ { cap = 1; next }
                /^The command completed successfully\./ { cap = 0 }
                cap {
                    line = $0
                    sub(/^[[:space:]]+/, "", line)
                    sub(/[[:space:]]+$/, "", line)
                    if ( line != "" ) print line
                }
            ' | awk 'NF && !seen[$0]++ { print }' || true)"

            [[ -n "${v}" ]] || return 1

            printf '%s\n' "${v}"
            return 0

        fi

        return 1

    fi
    if [[ -n "${user}" ]]; then

        if sys::has id; then

            if [[ -n "${current}" && "${user}" == "${current}" ]]; then v="$(id -Gn 2>/dev/null || true)"
            else v="$(id -Gn "${user}" 2>/dev/null || true)"
            fi

            [[ -n "${v}" ]] || return 1

            for x in ${v}; do
                printf '%s\n' "${x}"
            done | awk 'NF && !seen[$0]++ { print }'

            return 0

        fi

        return 1

    fi
    if sys::is_linux; then

        if sys::has getent; then
            getent group 2>/dev/null | awk -F: '{ print $1 }' | awk 'NF && !seen[$0]++ { print }'
            return
        fi

        [[ -r /etc/group ]] || return 1

        awk -F: '{ print $1 }' /etc/group 2>/dev/null | awk 'NF && !seen[$0]++ { print }'
        return

    fi
    if sys::is_macos; then

        sys::has dscl || return 1
        dscl . -list /Groups 2>/dev/null | awk 'NF && !seen[$0]++ { print }'
        return

    fi

    return 1

}
group::users () {

    local group="${1:-}"

    group::exists "${group}" || return 1
    user::all "${group}"

}
group::add_user () {

    local group="${1:-}" user="${2:-}"

    group::exists "${group}" || return 1
    user::add_group "${user}" "${group}"

}
group::del_user () {

    local group="${1:-}" user="${2:-}"

    group::exists "${group}" || return 1
    user::del_group "${user}" "${group}"

}
