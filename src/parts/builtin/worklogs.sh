codingmaster@codingmstr:/var/www/projects/bashx$ bash -n src/parts/builtin/system.sh
codingmaster@codingmstr:/var/www/projects/bashx$ shellcheck src/parts/builtin/system.sh -e SC2148
codingmaster@codingmstr:/var/www/projects/bashx$

[[CI LINUX]]

Run bash src/parts/builtin/test.sh
[commands]
sys::shell               = /usr/bin/bash
sys::has bash            = 
sys::which bash          = /usr/bin/bash
sys::which_all bash      = /usr/bin/bash | /bin/bash
[platform]
sys::name                = linux
sys::runtime             = linux
sys::kernel              = Linux
sys::distro              = ubuntu
sys::pkg_manager         = apt
sys::svc_manager         = systemd
sys::fw_manager          = ufw
sys::arch                = x64
sys::version             = 6.17.0-1010-azure
[env/constants]
sys::path_sep            = :
sys::line_sep            = lf
sys::path_name           = PATH
sys::exe_suffix          = 
sys::lib_suffix          = .so
sys::path_dirs           = /snap/bin | /home/runner/.local/bin | /opt/pipx_bin | /home/runner/.cargo/bin | /home/runner/.config/composer/vendor/bin | /usr/local/.ghcup/bin | /home/runner/.dotnet/tools | /usr/local/sbin | /usr/local/bin | /usr/sbin | /usr/bin | /sbin | /bin | /usr/games | /usr/local/games | /snap/bin
[identity]
sys::hostname            = runnervmeorf1
sys::username            = runner
sys::pid                 = 2897
sys::ppid                = 2896
sys::umask               = 0022
sys::locale              = C.UTF-8
sys::timezone            = Etc/UTC
sys::proxy               = <failed:1>
sys::ip                  = 10.1.0.76 172.17.0.1
[ci/runtime flags]
sys::ci_name             = github
sys::is_ci               = 
sys::is_ci_pull          = <failed:1>
sys::is_ci_push          = 
sys::is_ci_tag           = <failed:1>
sys::is_linux            = 
sys::is_macos            = <failed:1>
sys::is_windows          = <failed:1>
sys::is_wsl              = <failed:1>
sys::is_msys             = <failed:1>
sys::is_gitbash          = <failed:1>
sys::is_cygwin           = <failed:1>
sys::is_unix             = 
sys::is_posix            = 
sys::is_gui              = <failed:1>
sys::is_headless         = 
sys::is_terminal         = <failed:1>
sys::is_interactive      = <failed:1>
sys::is_container        = <failed:1>
sys::is_root             = <failed:1>
sys::is_admin            = <failed:1>
sys::can_sudo            = 
[time/load]
sys::uptime              = 51
sys::loadavg             = 0.60 0.16 0.05
[disk]
sys::disk_total .        = 154894188544
sys::disk_free .         = 95809974272
sys::disk_used .         = 59084214272
sys::disk_percent .      = 38
sys::disk_size .         = 1064960
sys::disk_info .         = path=. | total=154894188544 | free=95809974272 | used=59084214272 | percent=38
[memory]
sys::mem_total           = 16766431232
sys::mem_free            = 15692713984
sys::mem_used            = 1073651712
sys::mem_percent         = 6
sys::mem_info            = total=16766431232 | free=15692779520 | used=1073651712 | percent=6
[cpu]
sys::cpu_threads         = 4
sys::cpu_count           = 4
sys::cpu_cores           = 2
sys::cpu_model           = AMD EPYC 7763 64-Core Processor
sys::cpu_usage           = 4
sys::cpu_idle            = 100
sys::cpu_info            = model=AMD EPYC 7763 64-Core Processor | cores=2 | threads=4 | usage=1 | idle=99
[bash]
sys::bash_version        = 5.2.21(1)-release
sys::bash_major          = 5
sys::bash_minor          = 2
sys::bash_msrv 5         = 
sys::find_bash 5         = /usr/bin/bash
[done]

[[CI MACOS]]

Run bash src/parts/builtin/test.sh

[commands]
sys::shell               = /bin/bash
sys::has bash            = 
sys::which bash          = /bin/bash
sys::which_all bash      = /bin/bash

[platform]
sys::name                = macos
sys::runtime             = macos
sys::kernel              = Darwin
sys::distro              = macos
sys::pkg_manager         = brew
sys::svc_manager         = launchd
sys::fw_manager          = pf
sys::arch                = arm64
sys::version             = 15.7.4

[env/constants]
sys::path_sep            = :
sys::line_sep            = lf
sys::path_name           = PATH
sys::exe_suffix          = 
sys::lib_suffix          = .dylib
sys::path_dirs           = /opt/homebrew/lib/ruby/gems/3.3.0/bin | /opt/homebrew/opt/ruby@3.3/bin | /Users/runner/.local/bin | /opt/homebrew/bin | /opt/homebrew/sbin | /Users/runner/.cargo/bin | /usr/local/opt/curl/bin | /usr/local/bin | /usr/local/sbin | /Users/runner/bin | /Users/runner/.yarn/bin | /Users/runner/Library/Android/sdk/tools | /Users/runner/Library/Android/sdk/platform-tools | /Library/Frameworks/Python.framework/Versions/Current/bin | /Library/Frameworks/Mono.framework/Versions/Current/Commands | /usr/bin | /bin | /usr/sbin | /sbin | /Users/runner/.dotnet/tools

[identity]
sys::hostname            = sjc22-bm204-4a3dc7a3-548b-44f5-a3ef-a762d5ff46a2-AE4F9BB4AC8C.local
sys::username            = runner
sys::pid                 = 6157
sys::ppid                = 6149
sys::umask               = 0022
sys::locale              = en_US.UTF-8
sys::timezone            = UTC
sys::proxy               = <failed:1>
sys::ip                  = 192.168.64.5

[ci/runtime flags]
sys::ci_name             = github
sys::is_ci               = 
sys::is_ci_pull          = <failed:1>
sys::is_ci_push          = 
sys::is_ci_tag           = <failed:1>
sys::is_linux            = <failed:1>
sys::is_macos            = 
sys::is_windows          = <failed:1>
sys::is_wsl              = <failed:1>
sys::is_msys             = <failed:1>
sys::is_gitbash          = <failed:1>
sys::is_cygwin           = <failed:1>
sys::is_unix             = 
sys::is_posix            = 
sys::is_gui              = <failed:1>
sys::is_headless         = 
sys::is_terminal         = <failed:1>
sys::is_interactive      = <failed:1>
sys::is_container        = <failed:1>
sys::is_root             = <failed:1>
sys::is_admin            = 
sys::can_sudo            = 

[time/load]
sys::uptime              = 1777565515
sys::loadavg             = 8.82 14.25 9.18

[disk]
sys::disk_total .        = 343073095680
sys::disk_free .         = 48706887680
sys::disk_used .         = 294366208000
sys::disk_percent .      = 85
sys::disk_size .         = 802816
sys::disk_info .         = path=. | total=343073095680 | free=48706887680 | used=294366208000 | percent=85

[memory]
sys::mem_total           = 7516192768
sys::mem_free            = 3279601664
sys::mem_used            = 4230316032
sys::mem_percent         = 56
sys::mem_info            = total=7516192768 | free=3280683008 | used=4235509760 | percent=56

[cpu]
sys::cpu_threads         = 3
sys::cpu_count           = 3
sys::cpu_cores           = 3
sys::cpu_model           = Apple M1 (Virtual)
sys::cpu_usage           = 35
sys::cpu_idle            = 10
sys::cpu_info            = model=Apple M1 (Virtual) | cores=3 | threads=3 | usage=100 | idle=0

[bash]
sys::bash_version        = 3.2.57(1)-release
sys::bash_major          = 3
sys::bash_minor          = 2
sys::bash_msrv 5         = <failed:1>
sys::find_bash 5         = <failed:1>

[done]

[[CI WINDOWS]]

Run bash src/parts/builtin/test.sh

[commands]
sys::shell               = /usr/bin/bash
sys::has bash            = 
sys::which bash          = /usr/bin/bash
sys::which_all bash      = /usr/bin/bash | /usr/bin/bash.exe | /bin/bash | /bin/bash.exe | /c/Windows/system32/bash | /c/Windows/system32/bash.exe | /usr/bin/bash | /usr/bin/bash.exe

[platform]
sys::name                = windows
sys::runtime             = gitbash
sys::kernel              = MINGW64_NT-10.0-26100
sys::distro              = gitbash
sys::pkg_manager         = winget
sys::svc_manager         = sc
sys::fw_manager          = windows-firewall
sys::arch                = x64
sys::version             = 10.0.26100.0

[env/constants]
sys::path_sep            = ;
sys::line_sep            = crlf
sys::path_name           = Path
sys::exe_suffix          = .exe
sys::lib_suffix          = .dll
sys::path_dirs           = /mingw64/bin | /usr/bin | /c/Users/runneradmin/bin | /c/Program Files/MongoDB/Server/7.0/bin | /c/vcpkg | /c/tools/zstd | /c/hostedtoolcache/windows/stack/3.9.3/x64 | /c/cabal/bin | /c/ghcup/bin | /c/mingw64/bin | /c/Program Files/dotnet | /c/Program Files/MySQL/MySQL Server 8.0/bin | /c/Program Files/R/R-4.5.3/bin/x64 | /c/SeleniumWebDrivers/GeckoDriver | /c/SeleniumWebDrivers/EdgeDriver | /c/SeleniumWebDrivers/ChromeDriver | /c/Program Files (x86)/sbt/bin | /c/Program Files (x86)/GitHub CLI | /bin | /c/Program Files (x86)/pipx_bin | /c/npm/prefix | /c/hostedtoolcache/windows/go/1.24.13/x64/bin | /c/hostedtoolcache/windows/Python/3.12.10/x64/Scripts | /c/hostedtoolcache/windows/Python/3.12.10/x64 | /c/hostedtoolcache/windows/Ruby/3.3.11/x64/bin | /c/Program Files/OpenSSL/bin | /c/tools/kotlinc/bin | /c/hostedtoolcache/windows/Java_Temurin-Hotspot_jdk/17.0.18-8/x64/bin | /c/Program Files/ImageMagick-7.1.2-Q16-HDRI | /c/Program Files/Microsoft SDKs/Azure/CLI2/wbin | /c/ProgramData/kind | /c/ProgramData/Chocolatey/bin | /c/Windows/system32 | /c/Windows | /c/Windows/System32/Wbem | /c/Windows/System32/WindowsPowerShell/v1.0 | /c/Windows/System32/OpenSSH | /c/Program Files/PowerShell/7 | /c/Program Files/Microsoft/Web Platform Installer | /c/Program Files/Microsoft SQL Server/Client SDK/ODBC/170/Tools/Binn | /c/Program Files/Microsoft SQL Server/150/Tools/Binn | /c/Program Files/dotnet | /c/Program Files (x86)/Windows Kits/10/Windows Performance Toolkit | /c/Program Files (x86)/WiX Toolset v3.14/bin | /c/Program Files/Microsoft SQL Server/130/DTS/Binn | /c/Program Files/Microsoft SQL Server/140/DTS/Binn | /c/Program Files/Microsoft SQL Server/150/DTS/Binn | /c/Program Files/Microsoft SQL Server/160/DTS/Binn | /c/Program Files/Microsoft SQL Server/170/DTS/Binn | /c/ProgramData/chocolatey/lib/pulumi/tools/Pulumi/bin | /c/Program Files/CMake/bin | /c/Strawberry/c/bin | /c/Strawberry/perl/site/bin | /c/Strawberry/perl/bin | /c/ProgramData/chocolatey/lib/maven/apache-maven-3.9.14/bin | /c/Program Files/Microsoft Service Fabric/bin/Fabric/Fabric.Code | /c/Program Files/Microsoft SDKs/Service Fabric/Tools/ServiceFabricLocalClusterManager | /c/Program Files/nodejs | /cmd | /mingw64/bin | /usr/bin | /c/Program Files/GitHub CLI | /c/tools/php | /c/Program Files (x86)/sbt/bin | /c/Program Files/Amazon/AWSCLIV2 | /c/Program Files/Amazon/SessionManagerPlugin/bin | /c/Program Files/Amazon/AWSSAMCLI/bin | /c/Program Files/Microsoft SQL Server/130/Tools/Binn | /c/Program Files/mongosh | /c/Program Files/LLVM/bin | /c/Program Files (x86)/LLVM/bin | /c/Users/runneradmin/.dotnet/tools | /c/Users/runneradmin/.cargo/bin | /c/Users/runneradmin/AppData/Local/Microsoft/WindowsApps

[identity]
sys::hostname            = runnervmxu3fp
sys::username            = runneradmin
sys::pid                 = 2031
sys::ppid                = 2030
sys::umask               = 0022
sys::locale              = en-US
sys::timezone            = UTC
sys::proxy               = <failed:1>
sys::ip                  = 172.29.192.1 | 10.1.0.10

[ci/runtime flags]
sys::ci_name             = github
sys::is_ci               = 
sys::is_ci_pull          = <failed:1>
sys::is_ci_push          = 
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
sys::is_gui              = <failed:1>
sys::is_headless         = 
sys::is_terminal         = <failed:1>
sys::is_interactive      = <failed:1>
sys::is_container        = <failed:1>
sys::is_root             = 
sys::is_admin            = 
sys::can_sudo            = <failed:1>

[time/load]
sys::uptime              = 154
sys::loadavg             = 2.03 2.03 2.03

[disk]
sys::disk_total .        = 161059172352
sys::disk_free .         = 157864730624
sys::disk_used .         = 3194441728
sys::disk_percent .      = 1
sys::disk_size .         = 714752
sys::disk_info .         = path=. | total=161059172352 | free=157864730624 | used=3194441728 | percent=1

[memory]
sys::mem_total           = 17174360064
sys::mem_free            = 14426214400
sys::mem_used            = 2751803392
sys::mem_percent         = 16
sys::mem_info            = total=17174360064 | free=14423486464 | used=2750873600 | percent=16

[cpu]
sys::cpu_threads         = 4
sys::cpu_count           = 4
sys::cpu_cores           = 2
sys::cpu_model           = AMD EPYC 9V74 80-Core Processor                
sys::cpu_usage           = 3
sys::cpu_idle            = 99
sys::cpu_info            = model=AMD EPYC 9V74 80-Core Processor                 | cores=2 | threads=4 | usage=4 | idle=96

[bash]
sys::bash_version        = 5.2.37(1)-release
sys::bash_major          = 5
sys::bash_minor          = 2
sys::bash_msrv 5         = 
sys::find_bash 5         = /usr/bin/bash

[done]

[[WSL]]

codingmaster@codingmstr:/var/www/projects/bashx$ bash src/parts/builtin/test.sh

[commands]
sys::shell               = /usr/bin/bash
sys::has bash            =
sys::which bash          = /usr/bin/bash
sys::which_all bash      = /usr/bin/bash | /bin/bash

[platform]
sys::name                = linux
sys::runtime             = wsl
sys::kernel              = Linux
sys::distro              = ubuntu
sys::pkg_manager         = apt
sys::svc_manager         = systemd
sys::fw_manager          = ufw
sys::arch                = x64
sys::version             = 5.15.167.4-microsoft-standard-WSL2

[env/constants]
sys::path_sep            = :
sys::line_sep            = lf
sys::path_name           = PATH
sys::exe_suffix          =
sys::lib_suffix          = .so
sys::path_dirs           = /home/codingmaster/.local/bin | /home/codingmaster/.local/zig/current | /home/codingmaster/.sdkman/candidates/maven/current/bin | /home/codingmaster/.sdkman/candidates/gradle/current/bin | /home/codingmaster/.bun/bin | /home/codingmaster/.pixi/bin | /home/codingmaster/.local/bin | /home/codingmaster/.nvm/versions/node/v25.2.1/bin | /mnt/c/Users/codingmstr/AppData/Local/Programs/Microsoft VS Code/bin | /usr/local/go/bin | /home/codingmaster/.cargo/bin | /run/user/1000/fnm_multishells/1013_1777540944871/bin | /home/codingmaster/.local/share/fnm | /home/codingmaster/.grit/bin | /usr/local/sbin | /usr/local/bin | /usr/sbin | /usr/bin | /sbin | /bin | /usr/games | /usr/local/games | /usr/lib/wsl/lib | /snap/bin | /home/codingmaster/.dotnet/tools | /home/codingmaster/.local/bin | /opt/zig | /home/codingmaster/.local/bin

[identity]
sys::hostname            = codingmstr
sys::username            = codingmaster
sys::pid                 = 28941
sys::ppid                = 979
sys::umask               = 0022
sys::locale              = C.UTF-8
sys::timezone            = Africa/Cairo
sys::proxy               = <failed:1>
sys::ip                  = 172.21.76.34 172.17.0.1 192.168.58.1

[ci/runtime flags]
sys::ci_name             = <failed:1>
sys::is_ci               = <failed:1>
sys::is_ci_pull          = <failed:1>
sys::is_ci_push          = <failed:1>
sys::is_ci_tag           = <failed:1>
sys::is_linux            =
sys::is_macos            = <failed:1>
sys::is_windows          = <failed:1>
sys::is_wsl              =
sys::is_msys             = <failed:1>
sys::is_gitbash          = <failed:1>
sys::is_cygwin           = <failed:1>
sys::is_unix             =
sys::is_posix            =
sys::is_gui              =
sys::is_headless         = <failed:1>
sys::is_terminal         =
sys::is_interactive      = <failed:1>
sys::is_container        =
sys::is_root             = <failed:1>
sys::is_admin            =
sys::can_sudo            = <failed:1>

[time/load]
sys::uptime              = 24495
sys::loadavg             = 0.15 0.06 0.02

[disk]
sys::disk_total .        = 1081101176832
sys::disk_free .         = 974579351552
sys::disk_used .         = 106521825280
sys::disk_percent .      = 9
sys::disk_size .         = 3190784
sys::disk_info .         = path=. | total=1081101176832 | free=974579351552 | used=106521825280 | percent=9

[memory]
sys::mem_total           = 6218076160
sys::mem_free            = 5009608704
sys::mem_used            = 1208725504
sys::mem_percent         = 19
sys::mem_info            = total=6218076160 | free=5009350656 | used=1208725504 | percent=19

[cpu]
sys::cpu_threads         = 8
sys::cpu_count           = 8
sys::cpu_cores           = 4
sys::cpu_model           = Intel(R) Core(TM) i5-10210U CPU @ 1.60GHz
sys::cpu_usage           = 4
sys::cpu_idle            = 97
sys::cpu_info            = model=Intel(R) Core(TM) i5-10210U CPU @ 1.60GHz | cores=4 | threads=8 | usage=3 | idle=97

[bash]
sys::bash_version        = 5.2.21(1)-release
sys::bash_major          = 5
sys::bash_minor          = 2
sys::bash_msrv 5         =
sys::find_bash 5         = /usr/bin/bash

[done]
codingmaster@codingmstr:/var/www/projects/bashx$

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
