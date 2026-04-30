#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"

print () {

    local name="$1" value="" rc=0

    value="$("${name}" 2>/dev/null)" || rc=$?

    if (( rc == 0 )); then
        printf '%-24s = %s\n' "${name}" "${value//$'\n'/ | }"
    else
        printf '%-24s = <failed:%s>\n' "${name}" "${rc}"
    fi

}
print_arg () {

    local name="$1" arg="$2" value="" rc=0

    value="$("${name}" "${arg}" 2>/dev/null)" || rc=$?

    if (( rc == 0 )); then
        printf '%-24s = %s\n' "${name} ${arg}" "${value//$'\n'/ | }"
    else
        printf '%-24s = <failed:%s>\n' "${name} ${arg}" "${rc}"
    fi

}

printf '\n[commands]\n'
print sys::shell
print_arg sys::has bash
print_arg sys::which bash
print_arg sys::which_all bash

printf '\n[platform]\n'
print sys::name
print sys::runtime
print sys::kernel
print sys::distro
print sys::manager
print sys::arch
print sys::version

printf '\n[env/constants]\n'
print sys::path_sep
print sys::line_sep
print sys::path_name
print sys::exe_suffix
print sys::lib_suffix
print sys::path_dirs

printf '\n[identity]\n'
print sys::hostname
print sys::username

printf '\n[ci/runtime flags]\n'
print sys::ci_name
print sys::is_ci
print sys::is_ci_pull
print sys::is_ci_push
print sys::is_ci_tag
print sys::is_linux
print sys::is_macos
print sys::is_windows
print sys::is_wsl
print sys::is_msys
print sys::is_gitbash
print sys::is_cygwin
print sys::is_unix
print sys::is_posix
print sys::is_gui
print sys::is_headless
print sys::is_terminal
print sys::is_interactive
print sys::is_container
print sys::is_root
print sys::is_admin
print sys::can_sudo

printf '\n[time/load]\n'
print sys::uptime
print sys::loadavg

printf '\n[disk]\n'
print_arg sys::disk_total "."
print_arg sys::disk_free "."
print_arg sys::disk_used "."
print_arg sys::disk_percent "."
print_arg sys::disk_size "."
print_arg sys::disk_info "."

printf '\n[memory]\n'
print sys::mem_total
print sys::mem_free
print sys::mem_used
print sys::mem_percent
print sys::mem_info

printf '\n[cpu]\n'
print sys::cpu_threads
print sys::cpu_count
print sys::cpu_cores
print sys::cpu_model
print sys::cpu_usage
print sys::cpu_idle
print sys::cpu_info

printf '\n[bash]\n'
print sys::bash_version
print sys::bash_major
print sys::bash_minor
print_arg sys::bash_msrv "${MIN_BASH_VERSION:-${MSRV_BASH_VERSION:-5}}"
print_arg sys::find_bash "${MIN_BASH_VERSION:-${MSRV_BASH_VERSION:-5}}"

printf '\n[done]\n'
