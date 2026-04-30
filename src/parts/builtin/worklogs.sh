codingmaster@codingmstr:/var/www/projects/bashx$ bash -n src/parts/builtin/system.sh
codingmaster@codingmstr:/var/www/projects/bashx$ shellcheck src/parts/builtin/system.sh -e SC2148
codingmaster@codingmstr:/var/www/projects/bashx$

[[CI LINUX]]

4s
Run "bash" src/parts/builtin/test.sh

[coverage: functions exist]
  PASS found sys functions
  PASS declared sys::arch
  PASS declared sys::can_sudo
  PASS declared sys::ci_name
  PASS declared sys::cpu_cores
  PASS declared sys::cpu_count
  PASS declared sys::cpu_idle
  PASS declared sys::cpu_info
  PASS declared sys::cpu_model
  PASS declared sys::cpu_threads
  PASS declared sys::cpu_usage
  PASS declared sys::disk_free
  PASS declared sys::disk_info
  PASS declared sys::disk_percent
  PASS declared sys::disk_size
  PASS declared sys::disk_total
  PASS declared sys::disk_used
  PASS declared sys::distro
  PASS declared sys::env_path_name
  PASS declared sys::exe_suffix
  PASS declared sys::has
  PASS declared sys::hostname
  PASS declared sys::is_admin
  PASS declared sys::is_ci
  PASS declared sys::is_ci_pull
  PASS declared sys::is_ci_push
  PASS declared sys::is_ci_tag
  PASS declared sys::is_container
  PASS declared sys::is_cygwin
  PASS declared sys::is_gitbash
  PASS declared sys::is_gui
  PASS declared sys::is_headless
  PASS declared sys::is_interactive
  PASS declared sys::is_linux
  PASS declared sys::is_macos
  PASS declared sys::is_msys
  PASS declared sys::is_posix
  PASS declared sys::is_root
  PASS declared sys::is_terminal
  PASS declared sys::is_unix
  PASS declared sys::is_windows
  PASS declared sys::is_wsl
  PASS declared sys::kernel
  PASS declared sys::lib_suffix
  PASS declared sys::line_sep
  PASS declared sys::loadavg
  PASS declared sys::manager
  PASS declared sys::mem_free
  PASS declared sys::mem_info
  PASS declared sys::mem_percent
  PASS declared sys::mem_total
  PASS declared sys::mem_used
  PASS declared sys::name
  PASS declared sys::null
  PASS declared sys::open
  PASS declared sys::path_dirs
  PASS declared sys::path_sep
  PASS declared sys::runtime
  PASS declared sys::uptime
  PASS declared sys::username
  PASS declared sys::version

and platform predicates]
  PASS has detects sh/bash command
  PASS has rejects missing command
  PASS is_linux matches environment
  PASS is_macos rejects non-macos
  PASS is_cygwin rejects non-cygwin
  PASS is_msys rejects non-msys
  PASS is_wsl rejects non-wsl
  PASS is_windows rejects unix runtime
  PASS is_gitbash callable and false when not detected
  PASS is_unix matches linux/macos
  PASS is_posix matches supported shell runtimes

[CI detection and event simulation]
  PASS ci_name detects github
  PASS ci_name detects gitlab
  PASS ci_name detects generic CI
  PASS ci_name none returns non-zero
  PASS is_ci true in simulated github
  PASS is_ci false without CI vars
  PASS is_ci_pull detects github pull_request
  PASS is_ci_pull detects gitlab merge request
  PASS is_ci_pull rejects normal push
  PASS is_ci_push detects github push
  PASS is_ci_push rejects pull request
  PASS is_ci_tag detects github tag
  PASS is_ci_tag detects gitlab tag
  PASS is_ci_tag rejects branch

[runtime modes and privilege predicates]
  PASS is_terminal callable false
  PASS is_interactive callable false
  PASS is_gui callable false
  PASS is_headless inverse of gui
  PASS is_container callable false
  PASS is_root callable false
  PASS is_admin callable false
  PASS can_sudo callable true

[system constants and PATH parsing]
  PASS null returns unix null device
  PASS path_sep returns native unix separator
  PASS line_sep returns lf code
  PASS env_path_name returns PATH on unix
  PASS exe_suffix empty on unix
  PASS lib_suffix unix so
  PASS path_dirs splits colon PATH
  PASS path_dirs splits semicolon PATH
  PASS path_dirs returns current path entries

[identity, OS metadata, package manager and architecture]
  PASS name is known family
  PASS name agrees with linux
  PASS runtime is known layer
  PASS kernel returns value
  PASS distro returns value
  PASS manager returns known token or unknown
  PASS manager known returns zero
  PASS arch returns value
  PASS version returns value
  PASS hostname returns value
  PASS username returns value
  PASS username strips domain prefix

[uptime and load averages]
  PASS uptime returns seconds
  PASS loadavg returns three fields

[safe opener behavior]
  PASS open rejects empty target
  PASS open rejects target with newline
  PASS open app launches harmless true command

[disk information accuracy and invariants]
  PASS disk_total numeric
  PASS disk_free numeric
  PASS disk_used numeric
  PASS disk free <= total
  PASS disk used <= total
  PASS disk_percent 0..100
  PASS disk_size numeric
  PASS disk_size at least file bytes
  PASS disk_info has total
  PASS disk_info has free
  PASS disk_info has used
  PASS disk_info has percent

[memory information accuracy and invariants]
  PASS mem_total numeric
  PASS mem_free numeric
  PASS mem_used numeric
  PASS mem_total positive
  PASS mem_used <= mem_total
  PASS mem_percent 0..100
  PASS mem_info has total
  PASS mem_info has free
  PASS mem_info has used
  PASS mem_info has percent

[CPU information accuracy and invariants]
  PASS cpu_threads numeric
  PASS cpu_threads >= 1
  PASS cpu_count aliases cpu_threads
  PASS cpu_cores numeric
  PASS cpu_cores >= 1
  PASS cpu_cores <= cpu_threads
  PASS cpu_model returns value
  PASS cpu_usage 0..100
  PASS cpu_idle 0..100
  PASS cpu_info has model
  PASS cpu_info has cores
  PASS cpu_info has threads
  PASS cpu_info has usage
  PASS cpu_info has idle

[negative and adversarial inputs]
  PASS disk_total rejects missing path
  PASS disk_free rejects missing path
  PASS disk_size rejects empty path
  PASS disk_size rejects missing path

[coverage gate: every sys::* was exercised]
  PASS covered sys::arch
  PASS covered sys::can_sudo
  PASS covered sys::ci_name
  PASS covered sys::cpu_cores
  PASS covered sys::cpu_count
  PASS covered sys::cpu_idle
  PASS covered sys::cpu_info
  PASS covered sys::cpu_model
  PASS covered sys::cpu_threads
  PASS covered sys::cpu_usage
  PASS covered sys::disk_free
  PASS covered sys::disk_info
  PASS covered sys::disk_percent
  PASS covered sys::disk_size
  PASS covered sys::disk_total
  PASS covered sys::disk_used
  PASS covered sys::distro
  PASS covered sys::env_path_name
  PASS covered sys::exe_suffix
  PASS covered sys::has
  PASS covered sys::hostname
  PASS covered sys::is_admin
  PASS covered sys::is_ci
  PASS covered sys::is_ci_pull
  PASS covered sys::is_ci_push
  PASS covered sys::is_ci_tag
  PASS covered sys::is_container
  PASS covered sys::is_cygwin
  PASS covered sys::is_gitbash
  PASS covered sys::is_gui
  PASS covered sys::is_headless
  PASS covered sys::is_interactive
  PASS covered sys::is_linux
  PASS covered sys::is_macos
  PASS covered sys::is_msys
  PASS covered sys::is_posix
  PASS covered sys::is_root
  PASS covered sys::is_terminal
  PASS covered sys::is_unix
  PASS covered sys::is_windows
  PASS covered sys::is_wsl
  PASS covered sys::kernel
  PASS covered sys::lib_suffix
  PASS covered sys::line_sep
  PASS covered sys::loadavg
  PASS covered sys::manager
  PASS covered sys::mem_free
  PASS covered sys::mem_info
  PASS covered sys::mem_percent
  PASS covered sys::mem_total
  PASS covered sys::mem_used
  PASS covered sys::name
  PASS covered sys::null
  PASS covered sys::open
  PASS covered sys::path_dirs
  PASS covered sys::path_sep
  PASS covered sys::runtime
  PASS covered sys::uptime
  PASS covered sys::username
  PASS covered sys::version

============================================================
 system.sh brutal test summary
============================================================
Target : src/parts/builtin/system.sh
Root   : /tmp/tmp.qBj25oIquN
Funcs  : 60
Total  : 220
Pass   : 220
Fail   : 0
Skip   : 0
============================================================

[[CI MACOS]]

1s
Run "/opt/homebrew/bin/bash" src/parts/builtin/test.sh

[coverage: functions exist]
  PASS found sys functions
  PASS declared sys::arch
  PASS declared sys::can_sudo
  PASS declared sys::ci_name
  PASS declared sys::cpu_cores
  PASS declared sys::cpu_count
  PASS declared sys::cpu_idle
  PASS declared sys::cpu_info
  PASS declared sys::cpu_model
  PASS declared sys::cpu_threads
  PASS declared sys::cpu_usage
  PASS declared sys::disk_free
  PASS declared sys::disk_info
  PASS declared sys::disk_percent
  PASS declared sys::disk_size
  PASS declared sys::disk_total
  PASS declared sys::disk_used
  PASS declared sys::distro
  PASS declared sys::env_path_name
  PASS declared sys::exe_suffix
  PASS declared sys::has
  PASS declared sys::hostname
  PASS declared sys::is_admin
  PASS declared sys::is_ci
  PASS declared sys::is_ci_pull
  PASS declared sys::is_ci_push
  PASS declared sys::is_ci_tag
  PASS declared sys::is_container
  PASS declared sys::is_cygwin
  PASS declared sys::is_gitbash
  PASS declared sys::is_gui
  PASS declared sys::is_headless
  PASS declared sys::is_interactive
  PASS declared sys::is_linux
  PASS declared sys::is_macos
  PASS declared sys::is_msys
  PASS declared sys::is_posix
  PASS declared sys::is_root
  PASS declared sys::is_terminal
  PASS declared sys::is_unix
  PASS declared sys::is_windows
  PASS declared sys::is_wsl
  PASS declared sys::kernel
  PASS declared sys::lib_suffix
  PASS declared sys::line_sep
  PASS declared sys::loadavg
  PASS declared sys::manager
  PASS declared sys::mem_free
  PASS declared sys::mem_info
  PASS declared sys::mem_percent
  PASS declared sys::mem_total
  PASS declared sys::mem_used
  PASS declared sys::name
  PASS declared sys::null
  PASS declared sys::open
  PASS declared sys::path_dirs
  PASS declared sys::path_sep
  PASS declared sys::runtime
  PASS declared sys::uptime
  PASS declared sys::username
  PASS declared sys::version

and platform predicates]
  PASS has detects sh/bash command
  PASS has rejects missing command
  PASS is_linux rejects non-linux
  PASS is_macos matches environment
  PASS is_cygwin rejects non-cygwin
  PASS is_msys rejects non-msys
  PASS is_wsl rejects non-wsl
  PASS is_windows rejects unix runtime
  PASS is_gitbash callable and false when not detected
  PASS is_unix matches linux/macos
  PASS is_posix matches supported shell runtimes

[CI detection and event simulation]
  PASS ci_name detects github
  PASS ci_name detects gitlab
  PASS ci_name detects generic CI
  PASS ci_name none returns non-zero
  PASS is_ci true in simulated github
  PASS is_ci false without CI vars
  PASS is_ci_pull detects github pull_request
  PASS is_ci_pull detects gitlab merge request
  PASS is_ci_pull rejects normal push
  PASS is_ci_push detects github push
  PASS is_ci_push rejects pull request
  PASS is_ci_tag detects github tag
  PASS is_ci_tag detects gitlab tag
  PASS is_ci_tag rejects branch

[runtime modes and privilege predicates]
  PASS is_terminal callable false
  PASS is_interactive callable false
  PASS is_gui callable false
  PASS is_headless inverse of gui
  PASS is_container callable false
  PASS is_root callable false
  PASS is_admin callable true
  PASS can_sudo callable true

[system constants and PATH parsing]
  PASS null returns unix null device
  PASS path_sep returns native unix separator
  PASS line_sep returns lf code
  PASS env_path_name returns PATH on unix
  PASS exe_suffix empty on unix
  PASS lib_suffix macos dylib
  PASS path_dirs splits colon PATH
  PASS path_dirs splits semicolon PATH
  PASS path_dirs returns current path entries

[identity, OS metadata, package manager and architecture]
  PASS name is known family
  PASS name agrees with macos
  PASS runtime is known layer
  PASS kernel returns value
  PASS distro returns value
  PASS manager returns known token or unknown
  PASS manager known returns zero
  PASS arch returns value
  PASS version returns value
  PASS hostname returns value
  PASS username returns value
  PASS username strips domain prefix

[uptime and load averages]
  PASS uptime returns seconds
  PASS loadavg returns three fields

[safe opener behavior]
  PASS open rejects empty target
  PASS open rejects target with newline
  PASS open app launches harmless true command

[disk information accuracy and invariants]
  PASS disk_total numeric
  PASS disk_free numeric
  PASS disk_used numeric
  PASS disk free <= total
  PASS disk used <= total
  PASS disk_percent 0..100
  PASS disk_size numeric
  PASS disk_size at least file bytes
  PASS disk_info has total
  PASS disk_info has free
  PASS disk_info has used
  PASS disk_info has percent

[memory information accuracy and invariants]
  PASS mem_total numeric
  PASS mem_free numeric
  PASS mem_used numeric
  PASS mem_total positive
  PASS mem_used <= mem_total
  PASS mem_percent 0..100
  PASS mem_info has total
  PASS mem_info has free
  PASS mem_info has used
  PASS mem_info has percent

[CPU information accuracy and invariants]
  PASS cpu_threads numeric
  PASS cpu_threads >= 1
  PASS cpu_count aliases cpu_threads
  PASS cpu_cores numeric
  PASS cpu_cores >= 1
  PASS cpu_cores <= cpu_threads
  PASS cpu_model returns value
  PASS cpu_usage 0..100
  PASS cpu_idle 0..100
  PASS cpu_info has model
  PASS cpu_info has cores
  PASS cpu_info has threads
  PASS cpu_info has usage
  PASS cpu_info has idle

[negative and adversarial inputs]
  PASS disk_total rejects missing path
  PASS disk_free rejects missing path
  PASS disk_size rejects empty path
  PASS disk_size rejects missing path

[coverage gate: every sys::* was exercised]
  PASS covered sys::arch
  PASS covered sys::can_sudo
  PASS covered sys::ci_name
  PASS covered sys::cpu_cores
  PASS covered sys::cpu_count
  PASS covered sys::cpu_idle
  PASS covered sys::cpu_info
  PASS covered sys::cpu_model
  PASS covered sys::cpu_threads
  PASS covered sys::cpu_usage
  PASS covered sys::disk_free
  PASS covered sys::disk_info
  PASS covered sys::disk_percent
  PASS covered sys::disk_size
  PASS covered sys::disk_total
  PASS covered sys::disk_used
  PASS covered sys::distro
  PASS covered sys::env_path_name
  PASS covered sys::exe_suffix
  PASS covered sys::has
  PASS covered sys::hostname
  PASS covered sys::is_admin
  PASS covered sys::is_ci
  PASS covered sys::is_ci_pull
  PASS covered sys::is_ci_push
  PASS covered sys::is_ci_tag
  PASS covered sys::is_container
  PASS covered sys::is_cygwin
  PASS covered sys::is_gitbash
  PASS covered sys::is_gui
  PASS covered sys::is_headless
  PASS covered sys::is_interactive
  PASS covered sys::is_linux
  PASS covered sys::is_macos
  PASS covered sys::is_msys
  PASS covered sys::is_posix
  PASS covered sys::is_root
  PASS covered sys::is_terminal
  PASS covered sys::is_unix
  PASS covered sys::is_windows
  PASS covered sys::is_wsl
  PASS covered sys::kernel
  PASS covered sys::lib_suffix
  PASS covered sys::line_sep
  PASS covered sys::loadavg
  PASS covered sys::manager
  PASS covered sys::mem_free
  PASS covered sys::mem_info
  PASS covered sys::mem_percent
  PASS covered sys::mem_total
  PASS covered sys::mem_used
  PASS covered sys::name
  PASS covered sys::null
  PASS covered sys::open
  PASS covered sys::path_dirs
  PASS covered sys::path_sep
  PASS covered sys::runtime
  PASS covered sys::uptime
  PASS covered sys::username
  PASS covered sys::version

============================================================
 system.sh brutal test summary
============================================================
Target : src/parts/builtin/system.sh
Root   : /var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.oOnvpEDJKM
Funcs  : 60
Total  : 220
Pass   : 220
Fail   : 0
Skip   : 0
============================================================

[[CI WINDOWS]]

27s
Run "bash" src/parts/builtin/test.sh

[coverage: functions exist]
  PASS found sys functions
  PASS declared sys::arch
  PASS declared sys::can_sudo
  PASS declared sys::ci_name
  PASS declared sys::cpu_cores
  PASS declared sys::cpu_count
  PASS declared sys::cpu_idle
  PASS declared sys::cpu_info
  PASS declared sys::cpu_model
  PASS declared sys::cpu_threads
  PASS declared sys::cpu_usage
  PASS declared sys::disk_free
  PASS declared sys::disk_info
  PASS declared sys::disk_percent
  PASS declared sys::disk_size
  PASS declared sys::disk_total
  PASS declared sys::disk_used
  PASS declared sys::distro
  PASS declared sys::env_path_name
  PASS declared sys::exe_suffix
  PASS declared sys::has
  PASS declared sys::hostname
  PASS declared sys::is_admin
  PASS declared sys::is_ci
  PASS declared sys::is_ci_pull
  PASS declared sys::is_ci_push
  PASS declared sys::is_ci_tag
  PASS declared sys::is_container
  PASS declared sys::is_cygwin
  PASS declared sys::is_gitbash
  PASS declared sys::is_gui
  PASS declared sys::is_headless
  PASS declared sys::is_interactive
  PASS declared sys::is_linux
  PASS declared sys::is_macos
  PASS declared sys::is_msys
  PASS declared sys::is_posix
  PASS declared sys::is_root
  PASS declared sys::is_terminal
  PASS declared sys::is_unix
  PASS declared sys::is_windows
  PASS declared sys::is_wsl
  PASS declared sys::kernel
  PASS declared sys::lib_suffix
  PASS declared sys::line_sep
  PASS declared sys::loadavg
  PASS declared sys::manager
  PASS declared sys::mem_free
  PASS declared sys::mem_info
  PASS declared sys::mem_percent
  PASS declared sys::mem_total
  PASS declared sys::mem_used
  PASS declared sys::name
  PASS declared sys::null
  PASS declared sys::open
  PASS declared sys::path_dirs
  PASS declared sys::path_sep
  PASS declared sys::runtime
  PASS declared sys::uptime
  PASS declared sys::username
  PASS declared sys::version

and platform predicates]
  PASS has detects sh/bash command
  PASS has rejects missing command
  PASS is_linux rejects non-linux
  PASS is_macos rejects non-macos
  PASS is_cygwin rejects non-cygwin
  PASS is_msys matches environment
  PASS is_wsl rejects non-wsl
  PASS is_windows matches runtime
  PASS is_gitbash callable and true when detected
  PASS is_unix rejects non linux/macos
  PASS is_posix matches supported shell runtimes

[CI detection and event simulation]
  PASS ci_name detects github
  PASS ci_name detects gitlab
  PASS ci_name detects generic CI
  PASS ci_name none returns non-zero
  PASS is_ci true in simulated github
  PASS is_ci false without CI vars
  PASS is_ci_pull detects github pull_request
  PASS is_ci_pull detects gitlab merge request
  PASS is_ci_pull rejects normal push
  PASS is_ci_push detects github push
  PASS is_ci_push rejects pull request
  PASS is_ci_tag detects github tag
  PASS is_ci_tag detects gitlab tag
  PASS is_ci_tag rejects branch

[runtime modes and privilege predicates]
  PASS is_terminal callable false
  PASS is_interactive callable false
  PASS is_gui callable false
  PASS is_headless inverse of gui
  PASS is_container callable false
  PASS is_root callable true
  PASS is_admin true when root/admin
  PASS can_sudo callable false

[system constants and PATH parsing]
  PASS null returns windows null device
  PASS path_sep returns native windows separator
  PASS line_sep returns crlf code
  PASS env_path_name returns Path on windows
  PASS exe_suffix returns .exe on windows
  PASS lib_suffix windows dll
  PASS path_dirs splits colon PATH
  PASS path_dirs splits semicolon PATH
  PASS path_dirs returns current path entries

[identity, OS metadata, package manager and architecture]
  PASS name is known family
  PASS name agrees with windows
  PASS runtime is known layer
  PASS runtime agrees with gitbash
  PASS kernel returns value
  PASS distro returns value
  PASS manager returns known token or unknown
  PASS manager known returns zero
  PASS arch returns value
  PASS version returns value
  PASS hostname returns value
  PASS username returns value
  PASS username strips domain prefix

[uptime and load averages]
  PASS uptime returns seconds
  PASS loadavg returns three fields

[safe opener behavior]
  PASS open rejects empty target
  PASS open rejects target with newline
  PASS open app launches harmless true command

[disk information accuracy and invariants]
  PASS disk_total numeric
  PASS disk_free numeric
  PASS disk_used numeric
  PASS disk free <= total
  PASS disk used <= total
  PASS disk_percent 0..100
  PASS disk_size numeric
  PASS disk_size at least file bytes
  PASS disk_info has total
  PASS disk_info has free
  PASS disk_info has used
  PASS disk_info has percent

[memory information accuracy and invariants]
  PASS mem_total numeric
  PASS mem_free numeric
  PASS mem_used numeric
  PASS mem_total positive
  PASS mem_used <= mem_total
  PASS mem_percent 0..100
  PASS mem_info has total
  PASS mem_info has free
  PASS mem_info has used
  PASS mem_info has percent

[CPU information accuracy and invariants]
  PASS cpu_threads numeric
  PASS cpu_threads >= 1
  PASS cpu_count aliases cpu_threads
  PASS cpu_cores numeric
  PASS cpu_cores >= 1
  PASS cpu_cores <= cpu_threads
  PASS cpu_model returns value
  PASS cpu_usage 0..100
  PASS cpu_idle 0..100
  PASS cpu_info has model
  PASS cpu_info has cores
  PASS cpu_info has threads
  PASS cpu_info has usage
  PASS cpu_info has idle

[negative and adversarial inputs]
  PASS disk_total rejects missing path
  PASS disk_free rejects missing path
  PASS disk_size rejects empty path
  PASS disk_size rejects missing path

[coverage gate: every sys::* was exercised]
  PASS covered sys::arch
  PASS covered sys::can_sudo
  PASS covered sys::ci_name
  PASS covered sys::cpu_cores
  PASS covered sys::cpu_count
  PASS covered sys::cpu_idle
  PASS covered sys::cpu_info
  PASS covered sys::cpu_model
  PASS covered sys::cpu_threads
  PASS covered sys::cpu_usage
  PASS covered sys::disk_free
  PASS covered sys::disk_info
  PASS covered sys::disk_percent
  PASS covered sys::disk_size
  PASS covered sys::disk_total
  PASS covered sys::disk_used
  PASS covered sys::distro
  PASS covered sys::env_path_name
  PASS covered sys::exe_suffix
  PASS covered sys::has
  PASS covered sys::hostname
  PASS covered sys::is_admin
  PASS covered sys::is_ci
  PASS covered sys::is_ci_pull
  PASS covered sys::is_ci_push
  PASS covered sys::is_ci_tag
  PASS covered sys::is_container
  PASS covered sys::is_cygwin
  PASS covered sys::is_gitbash
  PASS covered sys::is_gui
  PASS covered sys::is_headless
  PASS covered sys::is_interactive
  PASS covered sys::is_linux
  PASS covered sys::is_macos
  PASS covered sys::is_msys
  PASS covered sys::is_posix
  PASS covered sys::is_root
  PASS covered sys::is_terminal
  PASS covered sys::is_unix
  PASS covered sys::is_windows
  PASS covered sys::is_wsl
  PASS covered sys::kernel
  PASS covered sys::lib_suffix
  PASS covered sys::line_sep
  PASS covered sys::loadavg
  PASS covered sys::manager
  PASS covered sys::mem_free
  PASS covered sys::mem_info
  PASS covered sys::mem_percent
  PASS covered sys::mem_total
  PASS covered sys::mem_used
  PASS covered sys::name
  PASS covered sys::null
  PASS covered sys::open
  PASS covered sys::path_dirs
  PASS covered sys::path_sep
  PASS covered sys::runtime
  PASS covered sys::uptime
  PASS covered sys::username
  PASS covered sys::version

============================================================
 system.sh brutal test summary
============================================================
Target : src/parts/builtin/system.sh
Root   : /tmp/tmp.OqY0lBNJtO
Funcs  : 60
Total  : 221
Pass   : 221
Fail   : 0
Skip   : 0
============================================================
