[[ WSL ]]

codingmaster@codingmstr:/var/www/projects/bashx$ bash -n src/parts/builtin/permission.sh
codingmaster@codingmstr:/var/www/projects/bashx$ shellcheck src/parts/builtin/permission.sh -e SC2148
codingmaster@codingmstr:/var/www/projects/bashx$ bash src/parts/builtin/test.sh
[env]
root    : /tmp/perm-rest.vdlqpq
os      : linux
runtime : wsl
user    : codingmaster

[api presence: rest only]
PASS function exists: perm::valid
PASS function exists: perm::read
PASS function exists: perm::write
PASS function exists: perm::execute
PASS function exists: perm::writeonly
PASS function exists: perm::readonly
PASS function exists: perm::seal
PASS function exists: perm::private
PASS function exists: perm::public
PASS function exists: perm::shared
PASS function exists: perm::owner
PASS function exists: perm::group
PASS function exists: perm::readable
PASS function exists: perm::writable
PASS function exists: perm::executable
PASS function exists: perm::runnable
PASS function exists: perm::editable
PASS function exists: perm::is_private
PASS function exists: perm::is_public
PASS function exists: perm::is_same
PASS function exists: perm::owned
PASS function exists: perm::lock
PASS function exists: perm::unlock
PASS function exists: perm::copy
PASS function exists: perm::ensure
PASS function exists: perm::info

[perm::valid]
PASS valid mode 000
PASS valid mode 400
PASS valid mode 500
PASS valid mode 600
PASS valid mode 644
PASS valid mode 664
PASS valid mode 700
PASS valid mode 755
PASS valid mode 775
PASS valid mode 0777
PASS valid mode u+r
PASS valid mode u-w
PASS valid mode g+x
PASS valid mode o-r
PASS valid mode a+rw
PASS valid mode ug+rwx
PASS valid mode u+rw,g-r,o+x
PASS valid change r
PASS valid change w
PASS valid change x
PASS valid change rw
PASS valid change rx
PASS valid change rwx
PASS valid change +r
PASS valid change +w
PASS valid change +x
PASS valid change -r
PASS valid change -w
PASS valid change -x
PASS valid change u+r
PASS valid change u-w
PASS valid change g+x
PASS valid change o-r
PASS valid change a+rw
PASS valid remove r
PASS valid remove w
PASS valid remove x
PASS valid remove rw
PASS valid remove rx
PASS valid remove rwx
PASS valid remove +r
PASS valid remove +w
PASS valid remove +x
PASS valid remove -r
PASS valid remove -w
PASS valid remove -x
PASS valid remove u+r
PASS valid remove u-w
PASS valid remove g+x
PASS valid remove o-r
PASS valid remove a+rw
PASS valid who u
PASS valid who g
PASS valid who o
PASS valid who a
PASS valid who ug
PASS valid who go
PASS valid who ugo
PASS invalid mode
PASS invalid mode 999
PASS invalid mode abc
PASS invalid mode u+
PASS invalid mode +z
PASS invalid mode u+r;
PASS invalid mode u+r
x
PASS invalid mode u+r o+w
PASS invalid mode u+r|x
PASS invalid who
PASS invalid who x
PASS invalid who user
PASS invalid who u+r
PASS invalid who u g
PASS invalid who u
g

[predicates: readable / writable / executable]
PASS perm::readable true
PASS effect readable true
PASS perm::writable true
PASS effect writable true
PASS perm::executable true
PASS effect executable true
PASS readable missing false
PASS writable missing false
PASS executable missing false

[facade predicates: runnable / editable / owned]
PASS perm::runnable
PASS effect runnable readable
PASS effect runnable executable
PASS perm::editable
PASS effect editable readable
PASS effect editable writable
PASS perm::owned
PASS perm::owned explicit current user
PASS perm::owned bogus user

[owner / group / info]
PASS perm::owner getter output
PASS perm::group getter output
PASS perm::info output
PASS perm::info has path
PASS perm::info has mode
PASS perm::info has owner
PASS perm::info has group
PASS perm::owner rejects injection
PASS perm::group rejects injection

[is_private / is_public / is_same]
PASS perm::private action for is_private
PASS perm::is_private private file
PASS perm::public action for is_public
PASS perm::is_public public file
PASS private is not public
PASS public is not private
PASS prepare same_a private
PASS prepare same_b private
PASS perm::is_same same permissions
PASS prepare same_c public
PASS perm::is_same different permissions

[copy]
PASS prepare copy source private
PASS prepare copy target public
PASS perm::copy source target
PASS effect copy makes is_same true

[ensure]
PASS perm::ensure 600
PASS effect ensure readable
PASS effect ensure writable
PASS perm::ensure 400
PASS effect ensure 400 readable
PASS effect ensure 400 blocks write

[facades already covered but rest-safe]
PASS perm::private action
PASS perm::public action
PASS perm::seal action
PASS perm::shared action
PASS perm::readonly action
PASS perm::writeonly action
PASS perm::lock action
PASS perm::unlock action

[missing path failures]
PASS perm::owner missing
PASS perm::group missing
PASS perm::readable missing
PASS perm::writable missing
PASS perm::executable missing
PASS perm::runnable missing
PASS perm::editable missing
PASS perm::is_private missing
PASS perm::is_public missing
PASS perm::owned missing
PASS perm::info missing
PASS perm::is_same missing left
PASS perm::is_same missing right
PASS perm::copy missing source
PASS perm::copy missing target
PASS perm::ensure missing

[raw API: get / set / add / del]

[raw: set/get consistency]
PASS perm::set 400 a
PASS perm::set 400 b
PASS perm::get 400 a non-empty
PASS perm::get 400 b non-empty
PASS perm::get 400 exact a
PASS perm::get 400 exact b
PASS perm::set 500 a
PASS perm::set 500 b
PASS perm::get 500 a non-empty
PASS perm::get 500 b non-empty
PASS perm::get 500 exact a
PASS perm::get 500 exact b
PASS perm::set 600 a
PASS perm::set 600 b
PASS perm::get 600 a non-empty
PASS perm::get 600 b non-empty
PASS perm::get 600 exact a
PASS perm::get 600 exact b
PASS perm::set 644 a
PASS perm::set 644 b
PASS perm::get 644 a non-empty
PASS perm::get 644 b non-empty
PASS perm::get 644 exact a
PASS perm::get 644 exact b
PASS perm::set 664 a
PASS perm::set 664 b
PASS perm::get 664 a non-empty
PASS perm::get 664 b non-empty
PASS perm::get 664 exact a
PASS perm::get 664 exact b
PASS perm::set 700 a
PASS perm::set 700 b
PASS perm::get 700 a non-empty
PASS perm::get 700 b non-empty
PASS perm::get 700 exact a
PASS perm::get 700 exact b
PASS perm::set 755 a
PASS perm::set 755 b
PASS perm::get 755 a non-empty
PASS perm::get 755 b non-empty
PASS perm::get 755 exact a
PASS perm::get 755 exact b
PASS perm::set 775 a
PASS perm::set 775 b
PASS perm::get 775 a non-empty
PASS perm::get 775 b non-empty
PASS perm::get 775 exact a
PASS perm::get 775 exact b

[raw: add effects]
PASS perm::add r
PASS effect add r readable
PASS perm::add w
PASS effect add w writable
PASS perm::add x
PASS effect add x executable

[raw: del effects]
PASS perm::del w
PASS effect del w blocks write
PASS effect write restores write
PASS perm::del x
PASS effect del x blocks execute
PASS effect execute restores execute
PASS perm::del r
PASS effect del r blocks read
PASS effect read restores read

[raw: invalid args]
PASS perm::set invalid mode
PASS perm::set injected mode
PASS perm::add invalid mode
PASS perm::del invalid mode
PASS perm::get missing
PASS perm::set missing
PASS perm::add missing
PASS perm::del missing

[summary]
pass: 242
fail: 0
codingmaster@codingmstr:/var/www/projects/bashx$

[[ MSYS ]]

codingmaster@codingmstr MINGW64 /d/Projects/Bashx
$ bash src/parts/builtin/test.sh
[env]
root    : /tmp/perm-rest.pSU0GF
os      : windows
runtime : msys2
user    : codingmaster

[api presence: rest only]
PASS function exists: perm::valid
PASS function exists: perm::read
PASS function exists: perm::write
PASS function exists: perm::execute
PASS function exists: perm::writeonly
PASS function exists: perm::readonly
PASS function exists: perm::seal
PASS function exists: perm::private
PASS function exists: perm::public
PASS function exists: perm::shared
PASS function exists: perm::owner
PASS function exists: perm::group
PASS function exists: perm::readable
PASS function exists: perm::writable
PASS function exists: perm::executable
PASS function exists: perm::runnable
PASS function exists: perm::editable
PASS function exists: perm::is_private
PASS function exists: perm::is_public
PASS function exists: perm::is_same
PASS function exists: perm::owned
PASS function exists: perm::lock
PASS function exists: perm::unlock
PASS function exists: perm::copy
PASS function exists: perm::ensure
PASS function exists: perm::info

[perm::valid]
PASS valid mode 000
PASS valid mode 400
PASS valid mode 500
PASS valid mode 600
PASS valid mode 644
PASS valid mode 664
PASS valid mode 700
PASS valid mode 755
PASS valid mode 775
PASS valid mode 0777
PASS valid mode u+r
PASS valid mode u-w
PASS valid mode g+x
PASS valid mode o-r
PASS valid mode a+rw
PASS valid mode ug+rwx
PASS valid mode u+rw,g-r,o+x
PASS valid change r
PASS valid change w
PASS valid change x
PASS valid change rw
PASS valid change rx
PASS valid change rwx
PASS valid change +r
PASS valid change +w
PASS valid change +x
PASS valid change -r
PASS valid change -w
PASS valid change -x
PASS valid change u+r
PASS valid change u-w
PASS valid change g+x
PASS valid change o-r
PASS valid change a+rw
PASS valid remove r
PASS valid remove w
PASS valid remove x
PASS valid remove rw
PASS valid remove rx
PASS valid remove rwx
PASS valid remove +r
PASS valid remove +w
PASS valid remove +x
PASS valid remove -r
PASS valid remove -w
PASS valid remove -x
PASS valid remove u+r
PASS valid remove u-w
PASS valid remove g+x
PASS valid remove o-r
PASS valid remove a+rw
PASS valid who u
PASS valid who g
PASS valid who o
PASS valid who a
PASS valid who ug
PASS valid who go
PASS valid who ugo
PASS invalid mode
PASS invalid mode 999
PASS invalid mode abc
PASS invalid mode u+
PASS invalid mode +z
PASS invalid mode u+r;
PASS invalid mode u+r
x
PASS invalid mode u+r o+w
PASS invalid mode u+r|x
PASS invalid who
PASS invalid who x
PASS invalid who user
PASS invalid who u+r
PASS invalid who u g
PASS invalid who u
g

[predicates: readable / writable / executable]
PASS perm::readable true
PASS effect readable true
PASS perm::writable true
PASS effect writable true
PASS perm::executable true
PASS effect executable true
PASS readable missing false
PASS writable missing false
PASS executable missing false

[facade predicates: runnable / editable / owned]
PASS perm::runnable
PASS effect runnable readable
PASS effect runnable executable
PASS perm::editable
PASS effect editable readable
PASS effect editable writable
PASS perm::owned
PASS perm::owned explicit current user
PASS perm::owned bogus user

[owner / group / info]
PASS perm::owner getter output
PASS perm::group getter output
PASS perm::info output
PASS perm::info has path
PASS perm::info has mode
PASS perm::info has owner
PASS perm::info has group
PASS perm::owner rejects injection
PASS perm::group rejects injection

[is_private / is_public / is_same]
PASS perm::private action for is_private
PASS perm::is_private private file
PASS perm::public action for is_public
PASS private is not public on Windows best-effort
PASS prepare same_a private
PASS prepare same_b private
PASS perm::is_same same permissions
PASS prepare same_c public
PASS perm::is_same callable on Windows same pair

[copy]
PASS prepare copy source private
PASS prepare copy target public
PASS perm::copy source target
PASS effect copy keeps target readable

[ensure]
PASS perm::ensure 600
PASS effect ensure readable
PASS effect ensure writable
PASS perm::ensure 400
PASS effect ensure 400 readable
PASS effect ensure 400 blocks write on Windows

[facades already covered but rest-safe]
PASS perm::private action
PASS perm::public action
PASS perm::seal action
PASS perm::shared action
PASS perm::readonly action
PASS perm::writeonly action
PASS perm::lock action
PASS perm::unlock action

[missing path failures]
PASS perm::owner missing
PASS perm::group missing
PASS perm::readable missing
PASS perm::writable missing
PASS perm::executable missing
PASS perm::runnable missing
PASS perm::editable missing
PASS perm::is_private missing
PASS perm::is_public missing
PASS perm::owned missing
PASS perm::info missing
PASS perm::is_same missing left
PASS perm::is_same missing right
PASS perm::copy missing source
PASS perm::copy missing target
PASS perm::ensure missing

[raw API: get / set / add / del]

[raw: set/get consistency]
PASS perm::set 400 a
PASS perm::set 400 b
PASS perm::get 400 a non-empty
PASS perm::get 400 b non-empty
PASS perm::get 400 stable mapping
PASS perm::set 500 a
PASS perm::set 500 b
PASS perm::get 500 a non-empty
PASS perm::get 500 b non-empty
PASS perm::get 500 stable mapping
PASS perm::set 600 a
PASS perm::set 600 b
PASS perm::get 600 a non-empty
PASS perm::get 600 b non-empty
PASS perm::get 600 stable mapping
PASS perm::set 644 a
PASS perm::set 644 b
PASS perm::get 644 a non-empty
PASS perm::get 644 b non-empty
PASS perm::get 644 stable mapping
PASS perm::set 664 a
PASS perm::set 664 b
PASS perm::get 664 a non-empty
PASS perm::get 664 b non-empty
PASS perm::get 664 stable mapping
PASS perm::set 700 a
PASS perm::set 700 b
PASS perm::get 700 a non-empty
PASS perm::get 700 b non-empty
PASS perm::get 700 stable mapping
PASS perm::set 755 a
PASS perm::set 755 b
PASS perm::get 755 a non-empty
PASS perm::get 755 b non-empty
PASS perm::get 755 stable mapping
PASS perm::set 775 a
PASS perm::set 775 b
PASS perm::get 775 a non-empty
PASS perm::get 775 b non-empty
PASS perm::get 775 stable mapping

[raw: add effects]
PASS perm::add r
PASS effect add r readable
PASS perm::add w
PASS effect add w writable
PASS perm::add x
PASS effect add x executable

[raw: del effects]
PASS perm::del w
PASS effect del w blocks write
PASS effect write restores write
PASS perm::del x
PASS perm::del x callable on Windows
PASS effect execute restores execute
PASS perm::del r
PASS perm::del r callable on windows/root
PASS effect read restores read

[raw: invalid args]
PASS perm::set invalid mode
PASS perm::set injected mode
PASS perm::add invalid mode
PASS perm::del invalid mode
PASS perm::get missing
PASS perm::set missing
PASS perm::add missing
PASS perm::del missing

[summary]
pass: 232
fail: 0

codingmaster@codingmstr MINGW64 /d/Projects/Bashx

[[ GITBASH ]]

codingmaster@codingmstr MINGW64 /d/Projects/Bashx
$ bash src/parts/builtin/test.sh
[env]
root    : /tmp/perm-rest.zwihHg
os      : windows
runtime : gitbash
user    : codingmaster

[api presence: rest only]
PASS function exists: perm::valid
PASS function exists: perm::read
PASS function exists: perm::write
PASS function exists: perm::execute
PASS function exists: perm::writeonly
PASS function exists: perm::readonly
PASS function exists: perm::seal
PASS function exists: perm::private
PASS function exists: perm::public
PASS function exists: perm::shared
PASS function exists: perm::owner
PASS function exists: perm::group
PASS function exists: perm::readable
PASS function exists: perm::writable
PASS function exists: perm::executable
PASS function exists: perm::runnable
PASS function exists: perm::editable
PASS function exists: perm::is_private
PASS function exists: perm::is_public
PASS function exists: perm::is_same
PASS function exists: perm::owned
PASS function exists: perm::lock
PASS function exists: perm::unlock
PASS function exists: perm::copy
PASS function exists: perm::ensure
PASS function exists: perm::info

[perm::valid]
PASS valid mode 000
PASS valid mode 400
PASS valid mode 500
PASS valid mode 600
PASS valid mode 644
PASS valid mode 664
PASS valid mode 700
PASS valid mode 755
PASS valid mode 775
PASS valid mode 0777
PASS valid mode u+r
PASS valid mode u-w
PASS valid mode g+x
PASS valid mode o-r
PASS valid mode a+rw
PASS valid mode ug+rwx
PASS valid mode u+rw,g-r,o+x
PASS valid change r
PASS valid change w
PASS valid change x
PASS valid change rw
PASS valid change rx
PASS valid change rwx
PASS valid change +r
PASS valid change +w
PASS valid change +x
PASS valid change -r
PASS valid change -w
PASS valid change -x
PASS valid change u+r
PASS valid change u-w
PASS valid change g+x
PASS valid change o-r
PASS valid change a+rw
PASS valid remove r
PASS valid remove w
PASS valid remove x
PASS valid remove rw
PASS valid remove rx
PASS valid remove rwx
PASS valid remove +r
PASS valid remove +w
PASS valid remove +x
PASS valid remove -r
PASS valid remove -w
PASS valid remove -x
PASS valid remove u+r
PASS valid remove u-w
PASS valid remove g+x
PASS valid remove o-r
PASS valid remove a+rw
PASS valid who u
PASS valid who g
PASS valid who o
PASS valid who a
PASS valid who ug
PASS valid who go
PASS valid who ugo
PASS invalid mode
PASS invalid mode 999
PASS invalid mode abc
PASS invalid mode u+
PASS invalid mode +z
PASS invalid mode u+r;
PASS invalid mode u+r
x
PASS invalid mode u+r o+w
PASS invalid mode u+r|x
PASS invalid who
PASS invalid who x
PASS invalid who user
PASS invalid who u+r
PASS invalid who u g
PASS invalid who u
g

[predicates: readable / writable / executable]
PASS perm::readable true
PASS effect readable true
PASS perm::writable true
PASS effect writable true
PASS perm::executable true
PASS effect executable true
PASS readable missing false
PASS writable missing false
PASS executable missing false

[facade predicates: runnable / editable / owned]
PASS perm::runnable
PASS effect runnable readable
PASS effect runnable executable
PASS perm::editable
PASS effect editable readable
PASS effect editable writable
PASS perm::owned
PASS perm::owned explicit current user
PASS perm::owned bogus user

[owner / group / info]
PASS perm::owner getter output
PASS perm::group getter output
PASS perm::info output
PASS perm::info has path
PASS perm::info has mode
PASS perm::info has owner
PASS perm::info has group
PASS perm::owner rejects injection
PASS perm::group rejects injection

[is_private / is_public / is_same]
PASS perm::private action for is_private
PASS perm::is_private private file
PASS perm::public action for is_public
PASS private is not public on Windows best-effort
PASS prepare same_a private
PASS prepare same_b private
PASS perm::is_same same permissions
PASS prepare same_c public
PASS perm::is_same callable on Windows same pair

[copy]
PASS prepare copy source private
PASS prepare copy target public
PASS perm::copy source target
PASS effect copy keeps target readable

[ensure]
PASS perm::ensure 600
PASS effect ensure readable
PASS effect ensure writable
PASS perm::ensure 400
PASS effect ensure 400 readable
PASS effect ensure 400 blocks write on Windows

[facades already covered but rest-safe]
PASS perm::private action
PASS perm::public action
PASS perm::seal action
PASS perm::shared action
PASS perm::readonly action
PASS perm::writeonly action
PASS perm::lock action
PASS perm::unlock action

[missing path failures]
PASS perm::owner missing
PASS perm::group missing
PASS perm::readable missing
PASS perm::writable missing
PASS perm::executable missing
PASS perm::runnable missing
PASS perm::editable missing
PASS perm::is_private missing
PASS perm::is_public missing
PASS perm::owned missing
PASS perm::info missing
PASS perm::is_same missing left
PASS perm::is_same missing right
PASS perm::copy missing source
PASS perm::copy missing target
PASS perm::ensure missing

[raw API: get / set / add / del]

[raw: set/get consistency]
PASS perm::set 400 a
PASS perm::set 400 b
PASS perm::get 400 a non-empty
PASS perm::get 400 b non-empty
PASS perm::get 400 stable mapping
PASS perm::set 500 a
PASS perm::set 500 b
PASS perm::get 500 a non-empty
PASS perm::get 500 b non-empty
PASS perm::get 500 stable mapping
PASS perm::set 600 a
PASS perm::set 600 b
PASS perm::get 600 a non-empty
PASS perm::get 600 b non-empty
PASS perm::get 600 stable mapping
PASS perm::set 644 a
PASS perm::set 644 b
PASS perm::get 644 a non-empty
PASS perm::get 644 b non-empty
PASS perm::get 644 stable mapping
PASS perm::set 664 a
PASS perm::set 664 b
PASS perm::get 664 a non-empty
PASS perm::get 664 b non-empty
PASS perm::get 664 stable mapping
PASS perm::set 700 a
PASS perm::set 700 b
PASS perm::get 700 a non-empty
PASS perm::get 700 b non-empty
PASS perm::get 700 stable mapping
PASS perm::set 755 a
PASS perm::set 755 b
PASS perm::get 755 a non-empty
PASS perm::get 755 b non-empty
PASS perm::get 755 stable mapping
PASS perm::set 775 a
PASS perm::set 775 b
PASS perm::get 775 a non-empty
PASS perm::get 775 b non-empty
PASS perm::get 775 stable mapping

[raw: add effects]
PASS perm::add r
PASS effect add r readable
PASS perm::add w
PASS effect add w writable
PASS perm::add x
PASS effect add x executable

[raw: del effects]
PASS perm::del w
PASS effect del w blocks write
PASS effect write restores write
PASS perm::del x
PASS perm::del x callable on Windows
PASS effect execute restores execute
PASS perm::del r
PASS perm::del r callable on windows/root
PASS effect read restores read

[raw: invalid args]
PASS perm::set invalid mode
PASS perm::set injected mode
PASS perm::add invalid mode
PASS perm::del invalid mode
PASS perm::get missing
PASS perm::set missing
PASS perm::add missing
PASS perm::del missing

[summary]
pass: 232
fail: 0

codingmaster@codingmstr MINGW64 /d/Projects/Bashx

[[ CI LINUX ]]

Run bash src/parts/builtin/test.sh
[env]
root    : /tmp/perm-rest.nfkWfx
os      : linux
runtime : linux
user    : runner

[api presence: rest only]
PASS function exists: perm::valid
PASS function exists: perm::read
PASS function exists: perm::write
PASS function exists: perm::execute
PASS function exists: perm::writeonly
PASS function exists: perm::readonly
PASS function exists: perm::seal
PASS function exists: perm::private
PASS function exists: perm::public
PASS function exists: perm::shared
PASS function exists: perm::owner
PASS function exists: perm::group
PASS function exists: perm::readable
PASS function exists: perm::writable
PASS function exists: perm::executable
PASS function exists: perm::runnable
PASS function exists: perm::editable
PASS function exists: perm::is_private
PASS function exists: perm::is_public
PASS function exists: perm::is_same
PASS function exists: perm::owned
PASS function exists: perm::lock
PASS function exists: perm::unlock
PASS function exists: perm::copy
PASS function exists: perm::ensure
PASS function exists: perm::info

[perm::valid]
PASS valid mode 000
PASS valid mode 400
PASS valid mode 500
PASS valid mode 600
PASS valid mode 644
PASS valid mode 664
PASS valid mode 700
PASS valid mode 755
PASS valid mode 775
PASS valid mode 0777
PASS valid mode u+r
PASS valid mode u-w
PASS valid mode g+x
PASS valid mode o-r
PASS valid mode a+rw
PASS valid mode ug+rwx
PASS valid mode u+rw,g-r,o+x
PASS valid change r
PASS valid change w
PASS valid change x
PASS valid change rw
PASS valid change rx
PASS valid change rwx
PASS valid change +r
PASS valid change +w
PASS valid change +x
PASS valid change -r
PASS valid change -w
PASS valid change -x
PASS valid change u+r
PASS valid change u-w
PASS valid change g+x
PASS valid change o-r
PASS valid change a+rw
PASS valid remove r
PASS valid remove w
PASS valid remove x
PASS valid remove rw
PASS valid remove rx
PASS valid remove rwx
PASS valid remove +r
PASS valid remove +w
PASS valid remove +x
PASS valid remove -r
PASS valid remove -w
PASS valid remove -x
PASS valid remove u+r
PASS valid remove u-w
PASS valid remove g+x
PASS valid remove o-r
PASS valid remove a+rw
PASS valid who u
PASS valid who g
PASS valid who o
PASS valid who a
PASS valid who ug
PASS valid who go
PASS valid who ugo
PASS invalid mode 
PASS invalid mode 999
PASS invalid mode abc
PASS invalid mode u+
PASS invalid mode +z
PASS invalid mode u+r;
PASS invalid mode u+r
x
PASS invalid mode u+r o+w
PASS invalid mode u+r|x
PASS invalid who 
PASS invalid who x
PASS invalid who user
PASS invalid who u+r
PASS invalid who u g
PASS invalid who u
g

[predicates: readable / writable / executable]
PASS perm::readable true
PASS effect readable true
PASS perm::writable true
PASS effect writable true
PASS perm::executable true
PASS effect executable true
PASS readable missing false
PASS writable missing false
PASS executable missing false

[facade predicates: runnable / editable / owned]
PASS perm::runnable
PASS effect runnable readable
PASS effect runnable executable
PASS perm::editable
PASS effect editable readable
PASS effect editable writable
PASS perm::owned
PASS perm::owned explicit current user
PASS perm::owned bogus user

[owner / group / info]
PASS perm::owner getter output
PASS perm::group getter output
PASS perm::info output
PASS perm::info has path
PASS perm::info has mode
PASS perm::info has owner
PASS perm::info has group
PASS perm::owner rejects injection
PASS perm::group rejects injection

[is_private / is_public / is_same]
PASS perm::private action for is_private
PASS perm::is_private private file
PASS perm::public action for is_public
PASS perm::is_public public file
PASS private is not public
PASS public is not private
PASS prepare same_a private
PASS prepare same_b private
PASS perm::is_same same permissions
PASS prepare same_c public
PASS perm::is_same different permissions

[copy]
PASS prepare copy source private
PASS prepare copy target public
PASS perm::copy source target
PASS effect copy makes is_same true

[ensure]
PASS perm::ensure 600
PASS effect ensure readable
PASS effect ensure writable
PASS perm::ensure 400
PASS effect ensure 400 readable
PASS effect ensure 400 blocks write

[facades already covered but rest-safe]
PASS perm::private action
PASS perm::public action
PASS perm::seal action
PASS perm::shared action
PASS perm::readonly action
PASS perm::writeonly action
PASS perm::lock action
PASS perm::unlock action

[missing path failures]
PASS perm::owner missing
PASS perm::group missing
PASS perm::readable missing
PASS perm::writable missing
PASS perm::executable missing
PASS perm::runnable missing
PASS perm::editable missing
PASS perm::is_private missing
PASS perm::is_public missing
PASS perm::owned missing
PASS perm::info missing
PASS perm::is_same missing left
PASS perm::is_same missing right
PASS perm::copy missing source
PASS perm::copy missing target
PASS perm::ensure missing

[raw API: get / set / add / del]

[raw: set/get consistency]
PASS perm::set 400 a
PASS perm::set 400 b
PASS perm::get 400 a non-empty
PASS perm::get 400 b non-empty
PASS perm::get 400 exact a
PASS perm::get 400 exact b
PASS perm::set 500 a
PASS perm::set 500 b
PASS perm::get 500 a non-empty
PASS perm::get 500 b non-empty
PASS perm::get 500 exact a
PASS perm::get 500 exact b
PASS perm::set 600 a
PASS perm::set 600 b
PASS perm::get 600 a non-empty
PASS perm::get 600 b non-empty
PASS perm::get 600 exact a
PASS perm::get 600 exact b
PASS perm::set 644 a
PASS perm::set 644 b
PASS perm::get 644 a non-empty
PASS perm::get 644 b non-empty
PASS perm::get 644 exact a
PASS perm::get 644 exact b
PASS perm::set 664 a
PASS perm::set 664 b
PASS perm::get 664 a non-empty
PASS perm::get 664 b non-empty
PASS perm::get 664 exact a
PASS perm::get 664 exact b
PASS perm::set 700 a
PASS perm::set 700 b
PASS perm::get 700 a non-empty
PASS perm::get 700 b non-empty
PASS perm::get 700 exact a
PASS perm::get 700 exact b
PASS perm::set 755 a
PASS perm::set 755 b
PASS perm::get 755 a non-empty
PASS perm::get 755 b non-empty
PASS perm::get 755 exact a
PASS perm::get 755 exact b
PASS perm::set 775 a
PASS perm::set 775 b
PASS perm::get 775 a non-empty
PASS perm::get 775 b non-empty
PASS perm::get 775 exact a
PASS perm::get 775 exact b

[raw: add effects]
PASS perm::add r
PASS effect add r readable
PASS perm::add w
PASS effect add w writable
PASS perm::add x
PASS effect add x executable

[raw: del effects]
PASS perm::del w
PASS effect del w blocks write
PASS effect write restores write
PASS perm::del x
PASS effect del x blocks execute
PASS effect execute restores execute
PASS perm::del r
PASS effect del r blocks read
PASS effect read restores read

[raw: invalid args]
PASS perm::set invalid mode
PASS perm::set injected mode
PASS perm::add invalid mode
PASS perm::del invalid mode
PASS perm::get missing
PASS perm::set missing
PASS perm::add missing
PASS perm::del missing

[summary]
pass: 242
fail: 0

[[ CI MACOS ]]

Run bash src/parts/builtin/test.sh
==> Fetching downloads for: bash
✔︎ Bottle Manifest bash (5.3.9)
✔︎ Bottle Manifest ncurses (6.6)
✔︎ Bottle bash (5.3.9)
✔︎ Bottle ncurses (6.6)
==> Installing bash dependency: ncurses
==> Pouring ncurses--6.6.arm64_sequoia.bottle.tar.gz
🍺  /opt/homebrew/Cellar/ncurses/6.6: 4,086 files, 10.6MB
==> Pouring bash--5.3.9.arm64_sequoia.bottle.tar.gz
==> Caveats
DEFAULT_LOADABLE_BUILTINS_PATH: /opt/homebrew/lib/bash:/usr/local/lib/bash:/usr/lib/bash:/opt/local/lib/bash:/usr/pkg/lib/bash:/opt/pkg/lib/bash:.
==> Summary
🍺  /opt/homebrew/Cellar/bash/5.3.9: 172 files, 13.8MB
==> Caveats
==> bash
DEFAULT_LOADABLE_BUILTINS_PATH: /opt/homebrew/lib/bash:/usr/local/lib/bash:/usr/lib/bash:/opt/local/lib/bash:/usr/pkg/lib/bash:/opt/pkg/lib/bash:.
[env]
root    : /var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T//perm-rest.HzhR5z
os      : macos
runtime : macos
user    : runner

[api presence: rest only]
PASS function exists: perm::valid
PASS function exists: perm::read
PASS function exists: perm::write
PASS function exists: perm::execute
PASS function exists: perm::writeonly
PASS function exists: perm::readonly
PASS function exists: perm::seal
PASS function exists: perm::private
PASS function exists: perm::public
PASS function exists: perm::shared
PASS function exists: perm::owner
PASS function exists: perm::group
PASS function exists: perm::readable
PASS function exists: perm::writable
PASS function exists: perm::executable
PASS function exists: perm::runnable
PASS function exists: perm::editable
PASS function exists: perm::is_private
PASS function exists: perm::is_public
PASS function exists: perm::is_same
PASS function exists: perm::owned
PASS function exists: perm::lock
PASS function exists: perm::unlock
PASS function exists: perm::copy
PASS function exists: perm::ensure
PASS function exists: perm::info

[perm::valid]
PASS valid mode 000
PASS valid mode 400
PASS valid mode 500
PASS valid mode 600
PASS valid mode 644
PASS valid mode 664
PASS valid mode 700
PASS valid mode 755
PASS valid mode 775
PASS valid mode 0777
PASS valid mode u+r
PASS valid mode u-w
PASS valid mode g+x
PASS valid mode o-r
PASS valid mode a+rw
PASS valid mode ug+rwx
PASS valid mode u+rw,g-r,o+x
PASS valid change r
PASS valid change w
PASS valid change x
PASS valid change rw
PASS valid change rx
PASS valid change rwx
PASS valid change +r
PASS valid change +w
PASS valid change +x
PASS valid change -r
PASS valid change -w
PASS valid change -x
PASS valid change u+r
PASS valid change u-w
PASS valid change g+x
PASS valid change o-r
PASS valid change a+rw
PASS valid remove r
PASS valid remove w
PASS valid remove x
PASS valid remove rw
PASS valid remove rx
PASS valid remove rwx
PASS valid remove +r
PASS valid remove +w
PASS valid remove +x
PASS valid remove -r
PASS valid remove -w
PASS valid remove -x
PASS valid remove u+r
PASS valid remove u-w
PASS valid remove g+x
PASS valid remove o-r
PASS valid remove a+rw
PASS valid who u
PASS valid who g
PASS valid who o
PASS valid who a
PASS valid who ug
PASS valid who go
PASS valid who ugo
PASS invalid mode 
PASS invalid mode 999
PASS invalid mode abc
PASS invalid mode u+
PASS invalid mode +z
PASS invalid mode u+r;
PASS invalid mode u+r
x
PASS invalid mode u+r o+w
PASS invalid mode u+r|x
PASS invalid who 
PASS invalid who x
PASS invalid who user
PASS invalid who u+r
PASS invalid who u g
PASS invalid who u
g

[predicates: readable / writable / executable]
PASS perm::readable true
PASS effect readable true
PASS perm::writable true
PASS effect writable true
PASS perm::executable true
PASS effect executable true
PASS readable missing false
PASS writable missing false
PASS executable missing false

[facade predicates: runnable / editable / owned]
PASS perm::runnable
PASS effect runnable readable
PASS effect runnable executable
PASS perm::editable
PASS effect editable readable
PASS effect editable writable
PASS perm::owned
PASS perm::owned explicit current user
PASS perm::owned bogus user

[owner / group / info]
PASS perm::owner getter output
PASS perm::group getter output
PASS perm::info output
PASS perm::info has path
PASS perm::info has mode
PASS perm::info has owner
PASS perm::info has group
PASS perm::owner rejects injection
PASS perm::group rejects injection

[is_private / is_public / is_same]
PASS perm::private action for is_private
PASS perm::is_private private file
PASS perm::public action for is_public
PASS perm::is_public public file
PASS private is not public
PASS public is not private
PASS prepare same_a private
PASS prepare same_b private
PASS perm::is_same same permissions
PASS prepare same_c public
PASS perm::is_same different permissions

[copy]
PASS prepare copy source private
PASS prepare copy target public
PASS perm::copy source target
PASS effect copy makes is_same true

[ensure]
PASS perm::ensure 600
PASS effect ensure readable
PASS effect ensure writable
PASS perm::ensure 400
PASS effect ensure 400 readable
PASS effect ensure 400 blocks write

[facades already covered but rest-safe]
PASS perm::private action
PASS perm::public action
PASS perm::seal action
PASS perm::shared action
PASS perm::readonly action
PASS perm::writeonly action
PASS perm::lock action
PASS perm::unlock action

[missing path failures]
PASS perm::owner missing
PASS perm::group missing
PASS perm::readable missing
PASS perm::writable missing
PASS perm::executable missing
PASS perm::runnable missing
PASS perm::editable missing
PASS perm::is_private missing
PASS perm::is_public missing
PASS perm::owned missing
PASS perm::info missing
PASS perm::is_same missing left
PASS perm::is_same missing right
PASS perm::copy missing source
PASS perm::copy missing target
PASS perm::ensure missing

[raw API: get / set / add / del]

[raw: set/get consistency]
PASS perm::set 400 a
PASS perm::set 400 b
PASS perm::get 400 a non-empty
PASS perm::get 400 b non-empty
PASS perm::get 400 exact a
PASS perm::get 400 exact b
PASS perm::set 500 a
PASS perm::set 500 b
PASS perm::get 500 a non-empty
PASS perm::get 500 b non-empty
PASS perm::get 500 exact a
PASS perm::get 500 exact b
PASS perm::set 600 a
PASS perm::set 600 b
PASS perm::get 600 a non-empty
PASS perm::get 600 b non-empty
PASS perm::get 600 exact a
PASS perm::get 600 exact b
PASS perm::set 644 a
PASS perm::set 644 b
PASS perm::get 644 a non-empty
PASS perm::get 644 b non-empty
PASS perm::get 644 exact a
PASS perm::get 644 exact b
PASS perm::set 664 a
PASS perm::set 664 b
PASS perm::get 664 a non-empty
PASS perm::get 664 b non-empty
PASS perm::get 664 exact a
PASS perm::get 664 exact b
PASS perm::set 700 a
PASS perm::set 700 b
PASS perm::get 700 a non-empty
PASS perm::get 700 b non-empty
PASS perm::get 700 exact a
PASS perm::get 700 exact b
PASS perm::set 755 a
PASS perm::set 755 b
PASS perm::get 755 a non-empty
PASS perm::get 755 b non-empty
PASS perm::get 755 exact a
PASS perm::get 755 exact b
PASS perm::set 775 a
PASS perm::set 775 b
PASS perm::get 775 a non-empty
PASS perm::get 775 b non-empty
PASS perm::get 775 exact a
PASS perm::get 775 exact b

[raw: add effects]
PASS perm::add r
PASS effect add r readable
PASS perm::add w
PASS effect add w writable
PASS perm::add x
PASS effect add x executable

[raw: del effects]
PASS perm::del w
PASS effect del w blocks write
PASS effect write restores write
PASS perm::del x
PASS effect del x blocks execute
PASS effect execute restores execute
PASS perm::del r
PASS effect del r blocks read
PASS effect read restores read

[raw: invalid args]
PASS perm::set invalid mode
PASS perm::set injected mode
PASS perm::add invalid mode
PASS perm::del invalid mode
PASS perm::get missing
PASS perm::set missing
PASS perm::add missing
PASS perm::del missing

[summary]
pass: 242
fail: 0

[[ CI WINDOWS ]]

Run bash src/parts/builtin/test.sh
[env]
root    : /tmp/perm-rest.Vkt7IJ
os      : windows
runtime : msys2
user    : runneradmin

[api presence: rest only]
PASS function exists: perm::valid
PASS function exists: perm::read
PASS function exists: perm::write
PASS function exists: perm::execute
PASS function exists: perm::writeonly
PASS function exists: perm::readonly
PASS function exists: perm::seal
PASS function exists: perm::private
PASS function exists: perm::public
PASS function exists: perm::shared
PASS function exists: perm::owner
PASS function exists: perm::group
PASS function exists: perm::readable
PASS function exists: perm::writable
PASS function exists: perm::executable
PASS function exists: perm::runnable
PASS function exists: perm::editable
PASS function exists: perm::is_private
PASS function exists: perm::is_public
PASS function exists: perm::is_same
PASS function exists: perm::owned
PASS function exists: perm::lock
PASS function exists: perm::unlock
PASS function exists: perm::copy
PASS function exists: perm::ensure
PASS function exists: perm::info

[perm::valid]
PASS valid mode 000
PASS valid mode 400
PASS valid mode 500
PASS valid mode 600
PASS valid mode 644
PASS valid mode 664
PASS valid mode 700
PASS valid mode 755
PASS valid mode 775
PASS valid mode 0777
PASS valid mode u+r
PASS valid mode u-w
PASS valid mode g+x
PASS valid mode o-r
PASS valid mode a+rw
PASS valid mode ug+rwx
PASS valid mode u+rw,g-r,o+x
PASS valid change r
PASS valid change w
PASS valid change x
PASS valid change rw
PASS valid change rx
PASS valid change rwx
PASS valid change +r
PASS valid change +w
PASS valid change +x
PASS valid change -r
PASS valid change -w
PASS valid change -x
PASS valid change u+r
PASS valid change u-w
PASS valid change g+x
PASS valid change o-r
PASS valid change a+rw
PASS valid remove r
PASS valid remove w
PASS valid remove x
PASS valid remove rw
PASS valid remove rx
PASS valid remove rwx
PASS valid remove +r
PASS valid remove +w
PASS valid remove +x
PASS valid remove -r
PASS valid remove -w
PASS valid remove -x
PASS valid remove u+r
PASS valid remove u-w
PASS valid remove g+x
PASS valid remove o-r
PASS valid remove a+rw
PASS valid who u
PASS valid who g
PASS valid who o
PASS valid who a
PASS valid who ug
PASS valid who go
PASS valid who ugo
PASS invalid mode 
PASS invalid mode 999
PASS invalid mode abc
PASS invalid mode u+
PASS invalid mode +z
PASS invalid mode u+r;
PASS invalid mode u+r
x
PASS invalid mode u+r o+w
PASS invalid mode u+r|x
PASS invalid who 
PASS invalid who x
PASS invalid who user
PASS invalid who u+r
PASS invalid who u g
PASS invalid who u
g

[predicates: readable / writable / executable]
PASS perm::readable true
PASS effect readable true
PASS perm::writable true
PASS effect writable true
PASS perm::executable true
PASS effect executable true
PASS readable missing false
PASS writable missing false
PASS executable missing false

[facade predicates: runnable / editable / owned]
PASS perm::runnable
PASS effect runnable readable
PASS effect runnable executable
PASS perm::editable
PASS effect editable readable
PASS effect editable writable
PASS perm::owned
PASS perm::owned explicit current user
PASS perm::owned bogus user

[owner / group / info]
PASS perm::owner getter output
PASS perm::group getter output
PASS perm::info output
PASS perm::info has path
PASS perm::info has mode
PASS perm::info has owner
PASS perm::info has group
PASS perm::owner rejects injection
PASS perm::group rejects injection

[is_private / is_public / is_same]
PASS perm::private action for is_private
PASS perm::is_private private file
PASS perm::public action for is_public
PASS private is not public on Windows best-effort
PASS prepare same_a private
PASS prepare same_b private
PASS perm::is_same same permissions
PASS prepare same_c public
PASS perm::is_same callable on Windows same pair

[copy]
PASS prepare copy source private
PASS prepare copy target public
PASS perm::copy source target
PASS effect copy keeps target readable

[ensure]
PASS perm::ensure 600
PASS effect ensure readable
PASS effect ensure writable
PASS perm::ensure 400
PASS effect ensure 400 readable
PASS effect ensure 400 blocks write on Windows

[facades already covered but rest-safe]
PASS perm::private action
PASS perm::public action
PASS perm::seal action
PASS perm::shared action
PASS perm::readonly action
PASS perm::writeonly action
PASS perm::lock action
PASS perm::unlock action

[missing path failures]
PASS perm::owner missing
PASS perm::group missing
PASS perm::readable missing
PASS perm::writable missing
PASS perm::executable missing
PASS perm::runnable missing
PASS perm::editable missing
PASS perm::is_private missing
PASS perm::is_public missing
PASS perm::owned missing
PASS perm::info missing
PASS perm::is_same missing left
PASS perm::is_same missing right
PASS perm::copy missing source
PASS perm::copy missing target
PASS perm::ensure missing

[raw API: get / set / add / del]

[raw: set/get consistency]
PASS perm::set 400 a
PASS perm::set 400 b
PASS perm::get 400 a non-empty
PASS perm::get 400 b non-empty
PASS perm::get 400 stable mapping
PASS perm::set 500 a
PASS perm::set 500 b
PASS perm::get 500 a non-empty
PASS perm::get 500 b non-empty
PASS perm::get 500 stable mapping
PASS perm::set 600 a
PASS perm::set 600 b
PASS perm::get 600 a non-empty
PASS perm::get 600 b non-empty
PASS perm::get 600 stable mapping
PASS perm::set 644 a
PASS perm::set 644 b
PASS perm::get 644 a non-empty
PASS perm::get 644 b non-empty
PASS perm::get 644 stable mapping
PASS perm::set 664 a
PASS perm::set 664 b
PASS perm::get 664 a non-empty
PASS perm::get 664 b non-empty
PASS perm::get 664 stable mapping
PASS perm::set 700 a
PASS perm::set 700 b
PASS perm::get 700 a non-empty
PASS perm::get 700 b non-empty
PASS perm::get 700 stable mapping
PASS perm::set 755 a
PASS perm::set 755 b
PASS perm::get 755 a non-empty
PASS perm::get 755 b non-empty
PASS perm::get 755 stable mapping
PASS perm::set 775 a
PASS perm::set 775 b
PASS perm::get 775 a non-empty
PASS perm::get 775 b non-empty
PASS perm::get 775 stable mapping

[raw: add effects]
PASS perm::add r
PASS effect add r readable
PASS perm::add w
PASS effect add w writable
PASS perm::add x
PASS effect add x executable

[raw: del effects]
PASS perm::del w
PASS effect del w blocks write ignored for root
PASS effect write restores write
PASS perm::del x
PASS perm::del x callable on Windows
PASS effect execute restores execute
PASS perm::del r
PASS perm::del r callable on windows/root
PASS effect read restores read

[raw: invalid args]
PASS perm::set invalid mode
PASS perm::set injected mode
PASS perm::add invalid mode
PASS perm::del invalid mode
PASS perm::get missing
PASS perm::set missing
PASS perm::add missing
PASS perm::del missing

[summary]
pass: 232
fail: 0
