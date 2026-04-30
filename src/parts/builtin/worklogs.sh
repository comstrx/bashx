codingmaster@codingmstr:/var/www/projects/bashx$ bash -n src/parts/builtin/system.sh
codingmaster@codingmstr:/var/www/projects/bashx$ shellcheck src/parts/builtin/system.sh -e SC2148
codingmaster@codingmstr:/var/www/projects/bashx$

[[CI LINUX]]

[[CI MACOS]]

[[CI WINDOWS]]

[[WSL]]


[[MSYS2]]

codingmaster@codingmstr MINGW64 //wsl$/Ubuntu/var/www/projects/bashx
$ bash src/parts/builtin/test.sh

[commands]
sys::shell               = /usr/bin/bash
sys::has bash            =
sys::which bash          = /usr/bin/bash
sys::which_all bash      = /usr/bin/bash | /usr/bin/bash.exe | /bin/bash | /bin/bash.exe | /c/Windows/System32/bash | /c/Windows/System32/bash.exe

[platform]
sys::name                = windows
sys::runtime             = msys2
sys::kernel              = MINGW64_NT-10.0-22621
sys::distro              = msys2
sys::pkg_manager         = pacman
sys::svc_manager         = sc
sys::fw_manager          = windows-firewall
sys::arch                = x64
sys::version             = 10.0.22621.0

[env/constants]
sys::path_sep            = ;
sys::line_sep            = crlf
sys::path_name           = Path
sys::exe_suffix          = .exe
sys::lib_suffix          = .dll
sys::path_dirs           = /c/Program Files/dotnet | /c/Users/codingmstr/.bun/bin | /c/Program Files/dotnet | /c/Users/codingmstr/.bun/bin | /mingw64/bin | /usr/local/bin | /usr/bin | /bin | /c/Windows/System32 | /c/Windows | /c/Windows/System32/Wbem | /c/Windows/System32/WindowsPowerShell/v1.0/ | /usr/bin/site_perl | /usr/bin/vendor_perl | /usr/bin/core_perl

[identity]
sys::hostname            = codingmstr
sys::username            = codingmaster
sys::pid                 = 4593
sys::ppid                = 1878
sys::umask               = 0022
sys::locale              = en_US.UTF-8
sys::timezone            = Africa/Cairo
sys::proxy               = <failed:1>
sys::ip                  = 172.21.64.1 | 192.168.1.6

[ci/runtime flags]
sys::ci_name             = <failed:1>
sys::is_ci               = <failed:1>
sys::is_ci_pull          = <failed:1>
sys::is_ci_push          = <failed:1>
sys::is_ci_tag           = <failed:1>
sys::is_linux            = <failed:1>
sys::is_macos            = <failed:1>
sys::is_windows          =
sys::is_wsl              = <failed:1>
sys::is_msys             =
sys::is_gitbash          = <failed:1>
sys::is_cygwin           =
sys::is_unix             = <failed:1>
sys::is_posix            =
sys::is_gui              =
sys::is_headless         = <failed:1>
sys::is_terminal         =
sys::is_interactive      = <failed:1>
sys::is_container        = <failed:1>
sys::is_root             = <failed:1>
sys::is_admin            = <failed:1>
sys::can_sudo            = <failed:1>

[time/load]
sys::uptime              = 24747
sys::loadavg             = 0.13 0.16 0.39

[disk]
sys::disk_total .        = 1081101176832
sys::disk_free .         = 974579367936
sys::disk_used .         = 106521808896
sys::disk_percent .      = 9
sys::disk_size .         = 2326528
sys::disk_info .         = path=. | total=1081101176832 | free=974579367936 | used=106521808896 | percent=9

[memory]
sys::mem_total           = 8417361920
sys::mem_free            = 1419415552
sys::mem_used            = 7032758272
sys::mem_percent         = 84
sys::mem_info            = total=8417361920 | free=1346691072 | used=7070670848 | percent=84

[cpu]
sys::cpu_threads         = 8
sys::cpu_count           = 8
sys::cpu_cores           = 4
sys::cpu_model           = Intel(R) Core(TM) i5-10210U CPU @ 1.60GHz
sys::cpu_usage           = 4
sys::cpu_idle            = 96
sys::cpu_info            = model=Intel(R) Core(TM) i5-10210U CPU @ 1.60GHz | cores=4 | threads=8 | usage=3 | idle=97

[bash]
sys::bash_version        = 5.3.9(1)-release
sys::bash_major          = 5
sys::bash_minor          = 3
sys::bash_msrv 5         =
sys::find_bash 5         = /usr/bin/bash

[done]

codingmaster@codingmstr MINGW64 //wsl$/Ubuntu/var/www/projects/bashx

[[GITBASH]]

codingmaster@codingmstr MINGW64 //wsl$/Ubuntu/var/www/projects/bashx
$ bash src/parts/builtin/test.sh

[commands]
sys::shell               = /usr/bin/bash
sys::has bash            =
sys::which bash          = /usr/bin/bash
sys::which_all bash      = /usr/bin/bash | /usr/bin/bash.exe | /bin/bash | /bin/bash.exe | /usr/bin/bash | /usr/bin/bash.exe | /c/Windows/system32/bash | /c/Windows/system32/bash.exe | /bin/bash | /bin/bash.exe | /c/Users/codingmstr/AppData/Local/Microsoft/WindowsApps/bash | /c/Users/codingmstr/AppData/Local/Microsoft/WindowsApps/bash.exe

[platform]
sys::name                = windows
sys::runtime             = gitbash
sys::kernel              = MINGW64_NT-10.0-22621
sys::distro              = gitbash
sys::pkg_manager         = winget
sys::svc_manager         = sc
sys::fw_manager          = windows-firewall
sys::arch                = x64
sys::version             = 10.0.22621.0

[env/constants]
sys::path_sep            = ;
sys::line_sep            = crlf
sys::path_name           = Path
sys::exe_suffix          = .exe
sys::lib_suffix          = .dll
sys::path_dirs           = /c/Users/codingmstr/bin | /mingw64/bin | /usr/local/bin | /usr/bin | /bin | /mingw64/bin | /usr/bin | /c/Users/codingmstr/bin | /c/Program Files/ImageMagick-7.1.1-Q16-HDRI | /c/Windows/system32 | /c/Windows | /c/Windows/System32/Wbem | /c/Windows/System32/WindowsPowerShell/v1.0 | /c/Windows/System32/OpenSSH | /c/Program Files/cmder | /cmd | /bin | /c/ProgramData/ComposerSetup/bin | /c/Program Files/Docker/Docker/resources/bin | /c/Program Files/MySQL/MySQL Server 9.1/bin | /c/Program Files/MATLAB/R2024b/bin | /c/Program Files (x86)/Windows Kits/10/Windows Performance Toolkit | /c/Program Files/redis | /c/Program Files/ffmpeg/bin | /c/Program Files/ngrok | /c/Program Files/WinRAR | /c/Program Files/nodejs | /c/Program Files/GitHub CLI | /c/Program Files/dotnet | /c/Users/codingmstr/.cargo/bin | /c/Users/codingmstr/AppData/Local/Programs/Python/Python312/Scripts | /c/Users/codingmstr/AppData/Local/Programs/Python/Python312 | /c/Users/codingmstr/AppData/Local/Microsoft/WindowsApps | /c/Users/codingmstr/AppData/Roaming/Composer/vendor/bin | /c/Program Files/php-8.3.9 | /c/Program Files/JetBrains/PyCharm 2024.3/bin | /c/Program Files/flutter/bin | /c/Users/codingmstr/AppData/Roaming/npm | /c/Users/codingmstr/AppData/Local/Programs/Microsoft VS Code/bin | /c/Users/codingmstr/AppData/Local/Programs/bin | /c/Users/codingmstr/.bun/bin | /c/Users/codingmstr/.dotnet/tools | /usr/bin/vendor_perl | /usr/bin/core_perl

[identity]
sys::hostname            = codingmstr
sys::username            = codingmaster
sys::pid                 = 2647
sys::ppid                = 40
sys::umask               = 0022
sys::locale              = en_US.UTF-8
sys::timezone            = Egypt Standard Time
sys::proxy               = <failed:1>
sys::ip                  = 172.21.64.1 | 192.168.1.6

[ci/runtime flags]
sys::ci_name             = <failed:1>
sys::is_ci               = <failed:1>
sys::is_ci_pull          = <failed:1>
sys::is_ci_push          = <failed:1>
sys::is_ci_tag           = <failed:1>
sys::is_linux            = <failed:1>
sys::is_macos            = <failed:1>
sys::is_windows          =
sys::is_wsl              = <failed:1>
sys::is_msys             =
sys::is_gitbash          =
sys::is_cygwin           = <failed:1>
sys::is_unix             = <failed:1>
sys::is_posix            =
sys::is_gui              =
sys::is_headless         = <failed:1>
sys::is_terminal         =
sys::is_interactive      = <failed:1>
sys::is_container        = <failed:1>
sys::is_root             = <failed:1>
sys::is_admin            = <failed:1>
sys::can_sudo            = <failed:1>

[time/load]
sys::uptime              = 24748
sys::loadavg             = 0.00 0.00 0.00

[disk]
sys::disk_total .        = 1081101176832
sys::disk_free .         = 974579367936
sys::disk_used .         = 106521808896
sys::disk_percent .      = 9
sys::disk_size .         = 2326528
sys::disk_info .         = path=. | total=1081101176832 | free=974579367936 | used=106521808896 | percent=9

[memory]
sys::mem_total           = 8417361920
sys::mem_free            = 1331503104
sys::mem_used            = 7091056640
sys::mem_percent         = 84
sys::mem_info            = total=8417361920 | free=1505357824 | used=6912004096 | percent=82

[cpu]
sys::cpu_threads         = 8
sys::cpu_count           = 8
sys::cpu_cores           = 4
sys::cpu_model           = Intel(R) Core(TM) i5-10210U CPU @ 1.60GHz
sys::cpu_usage           = 6
sys::cpu_idle            = 89
sys::cpu_info            = model=Intel(R) Core(TM) i5-10210U CPU @ 1.60GHz | cores=4 | threads=8 | usage=3 | idle=97

[bash]
sys::bash_version        = 5.2.26(1)-release
sys::bash_major          = 5
sys::bash_minor          = 2
sys::bash_msrv 5         =
sys::find_bash 5         = /usr/bin/bash

[done]

codingmaster@codingmstr MINGW64 //wsl$/Ubuntu/var/www/projects/bashx
