codingmaster@codingmstr:/var/www/projects/bashx$ bash -n src/parts/builtin/system.sh
codingmaster@codingmstr:/var/www/projects/bashx$ shellcheck src/parts/builtin/system.sh -e SC2148
codingmaster@codingmstr:/var/www/projects/bashx$

[[CI LINUX]]

20s
Run bash src/parts/builtin/test.sh
[target] user.sh
[env] os=linux runtime=linux user=root group=root mutate=1

[0001] api presence
  PASS function exists: user::valid
  PASS function exists: user::id
  PASS function exists: user::name
  PASS function exists: user::exists
  PASS function exists: user::add
  PASS function exists: user::del
  PASS function exists: user::all
  PASS function exists: user::groups
  PASS function exists: user::add_group
  PASS function exists: user::del_group
  PASS function exists: user::group
  PASS function exists: user::home
  PASS function exists: user::shell
  PASS function exists: user::is_root
  PASS function exists: user::is_admin
  PASS function exists: user::can_sudo
  PASS function exists: group::valid
  PASS function exists: group::id
  PASS function exists: group::name
  PASS function exists: group::exists
  PASS function exists: group::add
  PASS function exists: group::del
  PASS function exists: group::all
  PASS function exists: group::users
  PASS function exists: group::add_user
  PASS function exists: group::del_user

[0002] validation API
  PASS user::valid accepts root
  PASS group::valid accepts root
  PASS user::valid accepts root
  PASS group::valid accepts root
  PASS user::valid accepts bx78687439ua
  PASS group::valid accepts bx78687439ua
  PASS user::valid accepts bx78687439ga
  PASS group::valid accepts bx78687439ga
  PASS user::valid accepts abc_123
  PASS group::valid accepts abc_123
  PASS user::valid accepts abc-123
  PASS group::valid accepts abc-123
  PASS user::valid rejects hostile []
  PASS group::valid rejects hostile []
  PASS user::valid rejects hostile [*]
  PASS group::valid rejects hostile [*]
  PASS user::valid rejects hostile [?]
  PASS group::valid rejects hostile [?]
  PASS user::valid rejects hostile [[abc]]
  PASS group::valid rejects hostile [[abc]]
  PASS user::valid rejects hostile [bad/name]
  PASS group::valid rejects hostile [bad/name]
  PASS user::valid rejects hostile [bad\name]
  PASS group::valid rejects hostile [bad\name]
  PASS user::valid rejects hostile [bad
name]
  PASS group::valid rejects hostile [bad
name]
  PASS user::valid rejects hostile [bad
name]
  PASS group::valid rejects hostile [bad
name]

[0003] current identity reads
  PASS user::name nonempty
  PASS user::id nonempty
  PASS user::id numeric
  PASS user::group nonempty
  PASS group::name nonempty
  PASS group::id nonempty
  PASS group::id numeric
  PASS user::home nonempty
  PASS user::shell nonempty
  PASS user::name no CR/LF
  PASS group::name no CR/LF

[0004] identity repeatability
  PASS repeat user::name 1
  PASS repeat user::id 1
  PASS repeat user::group 1
  PASS repeat group::id 1
  PASS repeat user::name 2
  PASS repeat user::id 2
  PASS repeat user::group 2
  PASS repeat group::id 2
  PASS repeat user::name 3
  PASS repeat user::id 3
  PASS repeat user::group 3
  PASS repeat group::id 3
  PASS repeat user::name 4
  PASS repeat user::id 4
  PASS repeat user::group 4
  PASS repeat group::id 4
  PASS repeat user::name 5
  PASS repeat user::id 5
  PASS repeat user::group 5
  PASS repeat group::id 5
  PASS repeat user::name 6
  PASS repeat user::id 6
  PASS repeat user::group 6
  PASS repeat group::id 6
  PASS repeat user::name 7
  PASS repeat user::id 7
  PASS repeat user::group 7
  PASS repeat group::id 7
  PASS repeat user::name 8
  PASS repeat user::id 8
  PASS repeat user::group 8
  PASS repeat group::id 8
  PASS repeat user::name 9
  PASS repeat user::id 9
  PASS repeat user::group 9
  PASS repeat group::id 9
  PASS repeat user::name 10
  PASS repeat user::id 10
  PASS repeat user::group 10
  PASS repeat group::id 10
  PASS repeat user::name 11
  PASS repeat user::id 11
  PASS repeat user::group 11
  PASS repeat group::id 11
  PASS repeat user::name 12
  PASS repeat user::id 12
  PASS repeat user::group 12
  PASS repeat group::id 12

[0005] user::exists matrix
  PASS current user exists
  PASS current user in current group
  PASS fake user missing
  PASS fake user in current group missing
  PASS current user in fake group missing
  PASS user::exists rejects bad user []
  PASS user::exists rejects bad user [*]
  PASS user::exists rejects bad user [?]
  PASS user::exists rejects bad user [[x]]
  PASS user::exists rejects bad user [bad/name]
  PASS user::exists rejects bad user [bad
name]
  PASS user::exists rejects bad user [bad
name]
  PASS user::exists rejects bad group [*]
  PASS user::exists rejects bad group [?]
  PASS user::exists rejects bad group [[x]]
  PASS user::exists rejects bad group [bad/name]
  PASS user::exists rejects bad group [bad
group]
  PASS user::exists rejects bad group [bad
group]

[0006] group::exists matrix
  PASS current group exists
  PASS fake group missing
  PASS group::exists rejects bad group []
  PASS group::exists rejects bad group [*]
  PASS group::exists rejects bad group [?]
  PASS group::exists rejects bad group [[x]]
  PASS group::exists rejects bad group [bad/name]
  PASS group::exists rejects bad group [bad
group]
  PASS group::exists rejects bad group [bad
group]

[0007] id matrices
  PASS implicit id equals explicit current
  PASS fake user id fails
  PASS implicit group id equals explicit current
  PASS fake group id fails
  PASS user::id rejects bad [*]
  PASS group::id rejects bad [*]
  PASS user::id rejects bad [?]
  PASS group::id rejects bad [?]
  PASS user::id rejects bad [[x]]
  PASS group::id rejects bad [[x]]
  PASS user::id rejects bad [bad/name]
  PASS group::id rejects bad [bad/name]
  PASS user::id rejects bad [bad
x]
  PASS group::id rejects bad [bad
x]
  PASS user::id rejects bad [bad
x]
  PASS group::id rejects bad [bad
x]

[0008] list all users/groups
  PASS user::all nonempty
  PASS group::all nonempty
  PASS user::all contains current user
  PASS group::all contains current group
  PASS user::all excludes fake user
  PASS group::all excludes fake group
  PASS user::all unique
  PASS group::all unique

[0009] membership listing wrappers
  PASS user::groups current nonempty
  PASS group::users current nonempty
  PASS user::groups contains current group
  PASS group::users contains current user
  PASS user::groups current equals group::all user
  PASS group::users current equals user::all group
  PASS user::groups fake user fails
  PASS group::users fake group fails
  PASS user::groups rejects wildcard
  PASS group::users rejects wildcard

[0010] home and shell reads
  PASS implicit home nonempty
  PASS explicit home nonempty
  PASS implicit explicit home stable
  PASS implicit shell nonempty
  PASS explicit shell nonempty
  PASS implicit explicit shell stable
  PASS fake user home fails
  PASS fake user shell fails

[0011] privilege checks
  PASS user::is_root true branch
  PASS user::is_admin true branch
  PASS user::can_sudo true branch
  PASS is_root fake user fails
  PASS is_admin fake user fails
  PASS can_sudo fake user fails
  PASS non-windows can_sudo callable

[0012] pre-mutation clean state
  PASS user A absent
  PASS user B absent
  PASS group A absent
  PASS group B absent
  PASS group C absent

[0013] group lifecycle destructive
  PASS group add A
  PASS group exists A
  PASS group add A idempotent
  PASS group id A
  PASS group::all contains A
  PASS group add invalid empty
  PASS group add invalid wildcard
  PASS group add invalid newline
  PASS group del A
  PASS group A gone
  PASS group del A idempotent
  PASS group del invalid empty
  PASS group del invalid wildcard

[0014] user create-only strict lifecycle
  PASS group add A
  PASS group add B
  PASS user add A in group A
  PASS user A exists
  PASS user A in group A
  PASS user add A group A idempotent
  PASS user add A group B strict fails
  PASS user A id
  PASS user A group
  PASS user A home
  PASS user A shell
  PASS user::all contains A
  PASS group::users A contains user A
  PASS user add invalid empty
  PASS user add invalid wildcard
  PASS user add invalid newline
  PASS user add fake group fails
  PASS user del A wrong group B fails
  PASS user A survives wrong group del
  PASS user del A with group A
  PASS user A gone
  PASS user del A idempotent
  PASS group del A
  PASS group del B

[0015] membership lifecycle user namespace
  PASS group add A
  PASS group add B
  PASS user add A in group A
  PASS user A not in group B
  PASS user add_group A B
  PASS user A now in B
  PASS user add_group A B idempotent
  PASS user::groups A contains B
  PASS group::users B contains A
  PASS user del_group A B
  PASS user A no longer in B
  PASS user del_group A B idempotent
  PASS add_group fake user fails
  PASS add_group creates missing group C
  PASS group C created by user::add_group
  PASS user A in group C
  PASS user del A
  PASS group del A
  PASS group del B
  PASS group del C

[0016] membership lifecycle group namespace strict
  PASS group add A
  PASS group add C
  PASS user add B in group A
  PASS group add_user C B
  PASS user B in group C
  PASS group add_user C B idempotent
  PASS group add_user missing group fails
  PASS group add_user missing user fails
  PASS group add_user invalid group fails
  PASS group add_user invalid user fails
  PASS group del_user C B
  PASS user B not in C
  PASS group del_user C B idempotent
  PASS group del_user missing group fails
  PASS group del_user missing user fails
  PASS user del B
  PASS group del A
  PASS group del C

[0017] delete safety and idempotency
  PASS user::del empty rejects
  PASS user::del wildcard rejects
  PASS user::del newline rejects
  PASS user::del valid missing idempotent
  PASS user::del valid missing with group fails
  PASS group::del empty rejects
  PASS group::del wildcard rejects
  PASS group::del newline rejects
  PASS group::del valid missing idempotent

[0018] hostile input sweep
  PASS user::exists hostile *
  PASS user::id hostile *
  PASS user::group hostile *
  PASS user::home hostile *
  PASS user::shell hostile *
  PASS user::groups hostile *
  PASS group::exists hostile *
  PASS group::id hostile *
  PASS group::users hostile *
  PASS user::exists hostile ?
  PASS user::id hostile ?
  PASS user::group hostile ?
  PASS user::home hostile ?
  PASS user::shell hostile ?
  PASS user::groups hostile ?
  PASS group::exists hostile ?
  PASS group::id hostile ?
  PASS group::users hostile ?
  PASS user::exists hostile [abc]
  PASS user::id hostile [abc]
  PASS user::group hostile [abc]
  PASS user::home hostile [abc]
  PASS user::shell hostile [abc]
  PASS user::groups hostile [abc]
  PASS group::exists hostile [abc]
  PASS group::id hostile [abc]
  PASS group::users hostile [abc]
  PASS user::exists hostile bad/name
  PASS user::id hostile bad/name
  PASS user::group hostile bad/name
  PASS user::home hostile bad/name
  PASS user::shell hostile bad/name
  PASS user::groups hostile bad/name
  PASS group::exists hostile bad/name
  PASS group::id hostile bad/name
  PASS group::users hostile bad/name
  PASS user::exists hostile bad\name
  PASS user::id hostile bad\name
  PASS user::group hostile bad\name
  PASS user::home hostile bad\name
  PASS user::shell hostile bad\name
  PASS user::groups hostile bad\name
  PASS group::exists hostile bad\name
  PASS group::id hostile bad\name
  PASS group::users hostile bad\name
  PASS user::exists hostile $USER
  PASS user::id hostile $USER
  PASS user::group hostile $USER
  PASS user::home hostile $USER
  PASS user::shell hostile $USER
  PASS user::groups hostile $USER
  PASS group::exists hostile $USER
  PASS group::id hostile $USER
  PASS group::users hostile $USER
  PASS user::exists hostile $(id)
  PASS user::id hostile $(id)
  PASS user::group hostile $(id)
  PASS user::home hostile $(id)
  PASS user::shell hostile $(id)
  PASS user::groups hostile $(id)
  PASS group::exists hostile $(id)
  PASS group::id hostile $(id)
  PASS group::users hostile $(id)
  PASS user::exists hostile ;true
  PASS user::id hostile ;true
  PASS user::group hostile ;true
  PASS user::home hostile ;true
  PASS user::shell hostile ;true
  PASS user::groups hostile ;true
  PASS group::exists hostile ;true
  PASS group::id hostile ;true
  PASS group::users hostile ;true
  PASS user::exists hostile x
y
  PASS user::id hostile x
y
  PASS user::group hostile x
y
  PASS user::home hostile x
y
  PASS user::shell hostile x
y
  PASS user::groups hostile x
y
  PASS group::exists hostile x
y
  PASS group::id hostile x
y
  PASS group::users hostile x
y
  PASS user::exists hostile x
y
  PASS user::id hostile x
y
  PASS user::group hostile x
y
  PASS user::home hostile x
y
  PASS user::shell hostile x
y
  PASS user::groups hostile x
y
  PASS group::exists hostile x
y
  PASS group::id hostile x
y
  PASS group::users hostile x
y

[0019] read stress
  PASS stress user::name 1
  PASS stress user::id 1
  PASS stress user::group 1
  PASS stress user::home 1
  PASS stress user::shell 1
  PASS stress user::all 1
  PASS stress group::all 1
  PASS stress user::name 2
  PASS stress user::id 2
  PASS stress user::group 2
  PASS stress user::home 2
  PASS stress user::shell 2
  PASS stress user::all 2
  PASS stress group::all 2
  PASS stress user::name 3
  PASS stress user::id 3
  PASS stress user::group 3
  PASS stress user::home 3
  PASS stress user::shell 3
  PASS stress user::all 3
  PASS stress group::all 3
  PASS stress user::name 4
  PASS stress user::id 4
  PASS stress user::group 4
  PASS stress user::home 4
  PASS stress user::shell 4
  PASS stress user::all 4
  PASS stress group::all 4
  PASS stress user::name 5
  PASS stress user::id 5
  PASS stress user::group 5
  PASS stress user::home 5
  PASS stress user::shell 5
  PASS stress user::all 5
  PASS stress group::all 5
  PASS stress user::name 6
  PASS stress user::id 6
  PASS stress user::group 6
  PASS stress user::home 6
  PASS stress user::shell 6
  PASS stress user::all 6
  PASS stress group::all 6
  PASS stress user::name 7
  PASS stress user::id 7
  PASS stress user::group 7
  PASS stress user::home 7
  PASS stress user::shell 7
  PASS stress user::all 7
  PASS stress group::all 7
  PASS stress user::name 8
  PASS stress user::id 8
  PASS stress user::group 8
  PASS stress user::home 8
  PASS stress user::shell 8
  PASS stress user::all 8
  PASS stress group::all 8
  PASS stress user::name 9
  PASS stress user::id 9
  PASS stress user::group 9
  PASS stress user::home 9
  PASS stress user::shell 9
  PASS stress user::all 9
  PASS stress group::all 9
  PASS stress user::name 10
  PASS stress user::id 10
  PASS stress user::group 10
  PASS stress user::home 10
  PASS stress user::shell 10
  PASS stress user::all 10
  PASS stress group::all 10
  PASS stress user::name 11
  PASS stress user::id 11
  PASS stress user::group 11
  PASS stress user::home 11
  PASS stress user::shell 11
  PASS stress user::all 11
  PASS stress group::all 11
  PASS stress user::name 12
  PASS stress user::id 12
  PASS stress user::group 12
  PASS stress user::home 12
  PASS stress user::shell 12
  PASS stress user::all 12
  PASS stress group::all 12
  PASS stress user::name 13
  PASS stress user::id 13
  PASS stress user::group 13
  PASS stress user::home 13
  PASS stress user::shell 13
  PASS stress user::all 13
  PASS stress group::all 13
  PASS stress user::name 14
  PASS stress user::id 14
  PASS stress user::group 14
  PASS stress user::home 14
  PASS stress user::shell 14
  PASS stress user::all 14
  PASS stress group::all 14
  PASS stress user::name 15
  PASS stress user::id 15
  PASS stress user::group 15
  PASS stress user::home 15
  PASS stress user::shell 15
  PASS stress user::all 15
  PASS stress group::all 15
  PASS stress user::name 16
  PASS stress user::id 16
  PASS stress user::group 16
  PASS stress user::home 16
  PASS stress user::shell 16
  PASS stress user::all 16
  PASS stress group::all 16
  PASS stress user::name 17
  PASS stress user::id 17
  PASS stress user::group 17
  PASS stress user::home 17
  PASS stress user::shell 17
  PASS stress user::all 17
  PASS stress group::all 17
  PASS stress user::name 18
  PASS stress user::id 18
  PASS stress user::group 18
  PASS stress user::home 18
  PASS stress user::shell 18
  PASS stress user::all 18
  PASS stress group::all 18
  PASS stress user::name 19
  PASS stress user::id 19
  PASS stress user::group 19
  PASS stress user::home 19
  PASS stress user::shell 19
  PASS stress user::all 19
  PASS stress group::all 19
  PASS stress user::name 20
  PASS stress user::id 20
  PASS stress user::group 20
  PASS stress user::home 20
  PASS stress user::shell 20
  PASS stress user::all 20
  PASS stress group::all 20
  PASS stress user::name 21
  PASS stress user::id 21
  PASS stress user::group 21
  PASS stress user::home 21
  PASS stress user::shell 21
  PASS stress user::all 21
  PASS stress group::all 21
  PASS stress user::name 22
  PASS stress user::id 22
  PASS stress user::group 22
  PASS stress user::home 22
  PASS stress user::shell 22
  PASS stress user::all 22
  PASS stress group::all 22
  PASS stress user::name 23
  PASS stress user::id 23
  PASS stress user::group 23
  PASS stress user::home 23
  PASS stress user::shell 23
  PASS stress user::all 23
  PASS stress group::all 23
  PASS stress user::name 24
  PASS stress user::id 24
  PASS stress user::group 24
  PASS stress user::home 24
  PASS stress user::shell 24
  PASS stress user::all 24
  PASS stress group::all 24
  PASS stress user::name 25
  PASS stress user::id 25
  PASS stress user::group 25
  PASS stress user::home 25
  PASS stress user::shell 25
  PASS stress user::all 25
  PASS stress group::all 25
  PASS stress user::name 26
  PASS stress user::id 26
  PASS stress user::group 26
  PASS stress user::home 26
  PASS stress user::shell 26
  PASS stress user::all 26
  PASS stress group::all 26
  PASS stress user::name 27
  PASS stress user::id 27
  PASS stress user::group 27
  PASS stress user::home 27
  PASS stress user::shell 27
  PASS stress user::all 27
  PASS stress group::all 27
  PASS stress user::name 28
  PASS stress user::id 28
  PASS stress user::group 28
  PASS stress user::home 28
  PASS stress user::shell 28
  PASS stress user::all 28
  PASS stress group::all 28
  PASS stress user::name 29
  PASS stress user::id 29
  PASS stress user::group 29
  PASS stress user::home 29
  PASS stress user::shell 29
  PASS stress user::all 29
  PASS stress group::all 29
  PASS stress user::name 30
  PASS stress user::id 30
  PASS stress user::group 30
  PASS stress user::home 30
  PASS stress user::shell 30
  PASS stress user::all 30
  PASS stress group::all 30

[0020] final cleanup assertion
  PASS final user A absent
  PASS final user B absent
  PASS final user C absent
  PASS final group A absent
  PASS final group B absent
  PASS final group C absent

============================================================
 user.sh legendary production test summary
============================================================
Total sections : 20
Pass           : 584
Fail           : 0
Skip           : 0
Root           : /tmp/bashx-user-legendary.CEKwP0
Prefix         : bx78687439
============================================================

[[ CI MACOS ]]

59s
Run bash src/parts/builtin/test.sh
✔︎ JSON API formula_tap_migrations.jws.json
✔︎ JSON API cask_tap_migrations.jws.json
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
[target] user.sh
[env] os=macos runtime=macos user=root group=wheel mutate=1

[0001] api presence
  PASS function exists: user::valid
  PASS function exists: user::id
  PASS function exists: user::name
  PASS function exists: user::exists
  PASS function exists: user::add
  PASS function exists: user::del
  PASS function exists: user::all
  PASS function exists: user::groups
  PASS function exists: user::add_group
  PASS function exists: user::del_group
  PASS function exists: user::group
  PASS function exists: user::home
  PASS function exists: user::shell
  PASS function exists: user::is_root
  PASS function exists: user::is_admin
  PASS function exists: user::can_sudo
  PASS function exists: group::valid
  PASS function exists: group::id
  PASS function exists: group::name
  PASS function exists: group::exists
  PASS function exists: group::add
  PASS function exists: group::del
  PASS function exists: group::all
  PASS function exists: group::users
  PASS function exists: group::add_user
  PASS function exists: group::del_user

[0002] validation API
  PASS user::valid accepts root
  PASS group::valid accepts root
  PASS user::valid accepts wheel
  PASS group::valid accepts wheel
  PASS user::valid accepts bx26506796ua
  PASS group::valid accepts bx26506796ua
  PASS user::valid accepts bx26506796ga
  PASS group::valid accepts bx26506796ga
  PASS user::valid accepts abc_123
  PASS group::valid accepts abc_123
  PASS user::valid accepts abc-123
  PASS group::valid accepts abc-123
  PASS user::valid rejects hostile []
  PASS group::valid rejects hostile []
  PASS user::valid rejects hostile [*]
  PASS group::valid rejects hostile [*]
  PASS user::valid rejects hostile [?]
  PASS group::valid rejects hostile [?]
  PASS user::valid rejects hostile [[abc]]
  PASS group::valid rejects hostile [[abc]]
  PASS user::valid rejects hostile [bad/name]
  PASS group::valid rejects hostile [bad/name]
  PASS user::valid rejects hostile [bad\name]
  PASS group::valid rejects hostile [bad\name]
  PASS user::valid rejects hostile [bad
name]
  PASS group::valid rejects hostile [bad
name]
  PASS user::valid rejects hostile [bad
name]
  PASS group::valid rejects hostile [bad
name]

[0003] current identity reads
  PASS user::name nonempty
  PASS user::id nonempty
  PASS user::id numeric
  PASS user::group nonempty
  PASS group::name nonempty
  PASS group::id nonempty
  PASS group::id numeric
  PASS user::home nonempty
  PASS user::shell nonempty
  PASS user::name no CR/LF
  PASS group::name no CR/LF

[0004] identity repeatability
  PASS repeat user::name 1
  PASS repeat user::id 1
  PASS repeat user::group 1
  PASS repeat group::id 1
  PASS repeat user::name 2
  PASS repeat user::id 2
  PASS repeat user::group 2
  PASS repeat group::id 2
  PASS repeat user::name 3
  PASS repeat user::id 3
  PASS repeat user::group 3
  PASS repeat group::id 3
  PASS repeat user::name 4
  PASS repeat user::id 4
  PASS repeat user::group 4
  PASS repeat group::id 4
  PASS repeat user::name 5
  PASS repeat user::id 5
  PASS repeat user::group 5
  PASS repeat group::id 5
  PASS repeat user::name 6
  PASS repeat user::id 6
  PASS repeat user::group 6
  PASS repeat group::id 6
  PASS repeat user::name 7
  PASS repeat user::id 7
  PASS repeat user::group 7
  PASS repeat group::id 7
  PASS repeat user::name 8
  PASS repeat user::id 8
  PASS repeat user::group 8
  PASS repeat group::id 8
  PASS repeat user::name 9
  PASS repeat user::id 9
  PASS repeat user::group 9
  PASS repeat group::id 9
  PASS repeat user::name 10
  PASS repeat user::id 10
  PASS repeat user::group 10
  PASS repeat group::id 10
  PASS repeat user::name 11
  PASS repeat user::id 11
  PASS repeat user::group 11
  PASS repeat group::id 11
  PASS repeat user::name 12
  PASS repeat user::id 12
  PASS repeat user::group 12
  PASS repeat group::id 12

[0005] user::exists matrix
  PASS current user exists
  PASS current user in current group
  PASS fake user missing
  PASS fake user in current group missing
  PASS current user in fake group missing
  PASS user::exists rejects bad user []
  PASS user::exists rejects bad user [*]
  PASS user::exists rejects bad user [?]
  PASS user::exists rejects bad user [[x]]
  PASS user::exists rejects bad user [bad/name]
  PASS user::exists rejects bad user [bad
name]
  PASS user::exists rejects bad user [bad
name]
  PASS user::exists rejects bad group [*]
  PASS user::exists rejects bad group [?]
  PASS user::exists rejects bad group [[x]]
  PASS user::exists rejects bad group [bad/name]
  PASS user::exists rejects bad group [bad
group]
  PASS user::exists rejects bad group [bad
group]

[0006] group::exists matrix
  PASS current group exists
  PASS fake group missing
  PASS group::exists rejects bad group []
  PASS group::exists rejects bad group [*]
  PASS group::exists rejects bad group [?]
  PASS group::exists rejects bad group [[x]]
  PASS group::exists rejects bad group [bad/name]
  PASS group::exists rejects bad group [bad
group]
  PASS group::exists rejects bad group [bad
group]

[0007] id matrices
  PASS implicit id equals explicit current
  PASS fake user id fails
  PASS implicit group id equals explicit current
  PASS fake group id fails
  PASS user::id rejects bad [*]
  PASS group::id rejects bad [*]
  PASS user::id rejects bad [?]
  PASS group::id rejects bad [?]
  PASS user::id rejects bad [[x]]
  PASS group::id rejects bad [[x]]
  PASS user::id rejects bad [bad/name]
  PASS group::id rejects bad [bad/name]
  PASS user::id rejects bad [bad
x]
  PASS group::id rejects bad [bad
x]
  PASS user::id rejects bad [bad
x]
  PASS group::id rejects bad [bad
x]

[0008] list all users/groups
  PASS user::all nonempty
  PASS group::all nonempty
  PASS user::all contains current user
  PASS group::all contains current group
  PASS user::all excludes fake user
  PASS group::all excludes fake group
  PASS user::all unique
  PASS group::all unique

[0009] membership listing wrappers
  PASS user::groups current nonempty
  PASS group::users current nonempty
  PASS user::groups contains current group
  PASS group::users contains current user
  PASS user::groups current equals group::all user
  PASS group::users current equals user::all group
  PASS user::groups fake user fails
  PASS group::users fake group fails
  PASS user::groups rejects wildcard
  PASS group::users rejects wildcard

[0010] home and shell reads
  PASS implicit home nonempty
  PASS explicit home nonempty
  PASS implicit explicit home stable
  PASS implicit shell nonempty
  PASS explicit shell nonempty
  PASS implicit explicit shell stable
  PASS fake user home fails
  PASS fake user shell fails

[0011] privilege checks
  PASS user::is_root true branch
  PASS user::is_admin true branch
  PASS user::can_sudo true branch
  PASS is_root fake user fails
  PASS is_admin fake user fails
  PASS can_sudo fake user fails
  PASS non-windows can_sudo callable

[0012] pre-mutation clean state
  PASS user A absent
  PASS user B absent
  PASS group A absent
  PASS group B absent
  PASS group C absent

[0013] group lifecycle destructive
  PASS group add A
  PASS group exists A
  PASS group add A idempotent
  PASS group id A
  PASS group::all contains A
  PASS group add invalid empty
  PASS group add invalid wildcard
  PASS group add invalid newline
  PASS group del A
  PASS group A gone
  PASS group del A idempotent
  PASS group del invalid empty
  PASS group del invalid wildcard

[0014] user create-only strict lifecycle
  PASS group add A
  PASS group add B
  PASS user add A in group A
  PASS user A exists
  PASS user A in group A
  PASS user add A group A idempotent
  PASS user add A group B strict fails
  PASS user A id
  PASS user A group
  PASS user A home
  PASS user A shell
  PASS user::all contains A
  PASS group::users A contains user A
  PASS user add invalid empty
  PASS user add invalid wildcard
  PASS user add invalid newline
  PASS user add fake group fails
  PASS user del A wrong group B fails
  PASS user A survives wrong group del
  PASS user del A with group A
  PASS user A gone
  PASS user del A idempotent
  PASS group del A
  PASS group del B

[0015] membership lifecycle user namespace
  PASS group add A
  PASS group add B
  PASS user add A in group A
  PASS user A not in group B
  PASS user add_group A B
  PASS user A now in B
  PASS user add_group A B idempotent
  PASS user::groups A contains B
  PASS group::users B contains A
  PASS user del_group A B
  PASS user A no longer in B
  PASS user del_group A B idempotent
  PASS add_group fake user fails
  PASS add_group creates missing group C
  PASS group C created by user::add_group
  PASS user A in group C
  PASS user del A
  PASS group del A
  PASS group del B
  PASS group del C

[0016] membership lifecycle group namespace strict
  PASS group add A
  PASS group add C
  PASS user add B in group A
  PASS group add_user C B
  PASS user B in group C
  PASS group add_user C B idempotent
  PASS group add_user missing group fails
  PASS group add_user missing user fails
  PASS group add_user invalid group fails
  PASS group add_user invalid user fails
  PASS group del_user C B
  PASS user B not in C
  PASS group del_user C B idempotent
  PASS group del_user missing group fails
  PASS group del_user missing user fails
  PASS user del B
  PASS group del A
  PASS group del C

[0017] delete safety and idempotency
  PASS user::del empty rejects
  PASS user::del wildcard rejects
  PASS user::del newline rejects
  PASS user::del valid missing idempotent
  PASS user::del valid missing with group fails
  PASS group::del empty rejects
  PASS group::del wildcard rejects
  PASS group::del newline rejects
  PASS group::del valid missing idempotent

[0018] hostile input sweep
  PASS user::exists hostile *
  PASS user::id hostile *
  PASS user::group hostile *
  PASS user::home hostile *
  PASS user::shell hostile *
  PASS user::groups hostile *
  PASS group::exists hostile *
  PASS group::id hostile *
  PASS group::users hostile *
  PASS user::exists hostile ?
  PASS user::id hostile ?
  PASS user::group hostile ?
  PASS user::home hostile ?
  PASS user::shell hostile ?
  PASS user::groups hostile ?
  PASS group::exists hostile ?
  PASS group::id hostile ?
  PASS group::users hostile ?
  PASS user::exists hostile [abc]
  PASS user::id hostile [abc]
  PASS user::group hostile [abc]
  PASS user::home hostile [abc]
  PASS user::shell hostile [abc]
  PASS user::groups hostile [abc]
  PASS group::exists hostile [abc]
  PASS group::id hostile [abc]
  PASS group::users hostile [abc]
  PASS user::exists hostile bad/name
  PASS user::id hostile bad/name
  PASS user::group hostile bad/name
  PASS user::home hostile bad/name
  PASS user::shell hostile bad/name
  PASS user::groups hostile bad/name
  PASS group::exists hostile bad/name
  PASS group::id hostile bad/name
  PASS group::users hostile bad/name
  PASS user::exists hostile bad\name
  PASS user::id hostile bad\name
  PASS user::group hostile bad\name
  PASS user::home hostile bad\name
  PASS user::shell hostile bad\name
  PASS user::groups hostile bad\name
  PASS group::exists hostile bad\name
  PASS group::id hostile bad\name
  PASS group::users hostile bad\name
  PASS user::exists hostile $USER
  PASS user::id hostile $USER
  PASS user::group hostile $USER
  PASS user::home hostile $USER
  PASS user::shell hostile $USER
  PASS user::groups hostile $USER
  PASS group::exists hostile $USER
  PASS group::id hostile $USER
  PASS group::users hostile $USER
  PASS user::exists hostile $(id)
  PASS user::id hostile $(id)
  PASS user::group hostile $(id)
  PASS user::home hostile $(id)
  PASS user::shell hostile $(id)
  PASS user::groups hostile $(id)
  PASS group::exists hostile $(id)
  PASS group::id hostile $(id)
  PASS group::users hostile $(id)
  PASS user::exists hostile ;true
  PASS user::id hostile ;true
  PASS user::group hostile ;true
  PASS user::home hostile ;true
  PASS user::shell hostile ;true
  PASS user::groups hostile ;true
  PASS group::exists hostile ;true
  PASS group::id hostile ;true
  PASS group::users hostile ;true
  PASS user::exists hostile x
y
  PASS user::id hostile x
y
  PASS user::group hostile x
y
  PASS user::home hostile x
y
  PASS user::shell hostile x
y
  PASS user::groups hostile x
y
  PASS group::exists hostile x
y
  PASS group::id hostile x
y
  PASS group::users hostile x
y
  PASS user::exists hostile x
y
  PASS user::id hostile x
y
  PASS user::group hostile x
y
  PASS user::home hostile x
y
  PASS user::shell hostile x
y
  PASS user::groups hostile x
y
  PASS group::exists hostile x
y
  PASS group::id hostile x
y
  PASS group::users hostile x
y

[0019] read stress
  PASS stress user::name 1
  PASS stress user::id 1
  PASS stress user::group 1
  PASS stress user::home 1
  PASS stress user::shell 1
  PASS stress user::all 1
  PASS stress group::all 1
  PASS stress user::name 2
  PASS stress user::id 2
  PASS stress user::group 2
  PASS stress user::home 2
  PASS stress user::shell 2
  PASS stress user::all 2
  PASS stress group::all 2
  PASS stress user::name 3
  PASS stress user::id 3
  PASS stress user::group 3
  PASS stress user::home 3
  PASS stress user::shell 3
  PASS stress user::all 3
  PASS stress group::all 3
  PASS stress user::name 4
  PASS stress user::id 4
  PASS stress user::group 4
  PASS stress user::home 4
  PASS stress user::shell 4
  PASS stress user::all 4
  PASS stress group::all 4
  PASS stress user::name 5
  PASS stress user::id 5
  PASS stress user::group 5
  PASS stress user::home 5
  PASS stress user::shell 5
  PASS stress user::all 5
  PASS stress group::all 5
  PASS stress user::name 6
  PASS stress user::id 6
  PASS stress user::group 6
  PASS stress user::home 6
  PASS stress user::shell 6
  PASS stress user::all 6
  PASS stress group::all 6
  PASS stress user::name 7
  PASS stress user::id 7
  PASS stress user::group 7
  PASS stress user::home 7
  PASS stress user::shell 7
  PASS stress user::all 7
  PASS stress group::all 7
  PASS stress user::name 8
  PASS stress user::id 8
  PASS stress user::group 8
  PASS stress user::home 8
  PASS stress user::shell 8
  PASS stress user::all 8
  PASS stress group::all 8
  PASS stress user::name 9
  PASS stress user::id 9
  PASS stress user::group 9
  PASS stress user::home 9
  PASS stress user::shell 9
  PASS stress user::all 9
  PASS stress group::all 9
  PASS stress user::name 10
  PASS stress user::id 10
  PASS stress user::group 10
  PASS stress user::home 10
  PASS stress user::shell 10
  PASS stress user::all 10
  PASS stress group::all 10
  PASS stress user::name 11
  PASS stress user::id 11
  PASS stress user::group 11
  PASS stress user::home 11
  PASS stress user::shell 11
  PASS stress user::all 11
  PASS stress group::all 11
  PASS stress user::name 12
  PASS stress user::id 12
  PASS stress user::group 12
  PASS stress user::home 12
  PASS stress user::shell 12
  PASS stress user::all 12
  PASS stress group::all 12
  PASS stress user::name 13
  PASS stress user::id 13
  PASS stress user::group 13
  PASS stress user::home 13
  PASS stress user::shell 13
  PASS stress user::all 13
  PASS stress group::all 13
  PASS stress user::name 14
  PASS stress user::id 14
  PASS stress user::group 14
  PASS stress user::home 14
  PASS stress user::shell 14
  PASS stress user::all 14
  PASS stress group::all 14
  PASS stress user::name 15
  PASS stress user::id 15
  PASS stress user::group 15
  PASS stress user::home 15
  PASS stress user::shell 15
  PASS stress user::all 15
  PASS stress group::all 15
  PASS stress user::name 16
  PASS stress user::id 16
  PASS stress user::group 16
  PASS stress user::home 16
  PASS stress user::shell 16
  PASS stress user::all 16
  PASS stress group::all 16
  PASS stress user::name 17
  PASS stress user::id 17
  PASS stress user::group 17
  PASS stress user::home 17
  PASS stress user::shell 17
  PASS stress user::all 17
  PASS stress group::all 17
  PASS stress user::name 18
  PASS stress user::id 18
  PASS stress user::group 18
  PASS stress user::home 18
  PASS stress user::shell 18
  PASS stress user::all 18
  PASS stress group::all 18
  PASS stress user::name 19
  PASS stress user::id 19
  PASS stress user::group 19
  PASS stress user::home 19
  PASS stress user::shell 19
  PASS stress user::all 19
  PASS stress group::all 19
  PASS stress user::name 20
  PASS stress user::id 20
  PASS stress user::group 20
  PASS stress user::home 20
  PASS stress user::shell 20
  PASS stress user::all 20
  PASS stress group::all 20
  PASS stress user::name 21
  PASS stress user::id 21
  PASS stress user::group 21
  PASS stress user::home 21
  PASS stress user::shell 21
  PASS stress user::all 21
  PASS stress group::all 21
  PASS stress user::name 22
  PASS stress user::id 22
  PASS stress user::group 22
  PASS stress user::home 22
  PASS stress user::shell 22
  PASS stress user::all 22
  PASS stress group::all 22
  PASS stress user::name 23
  PASS stress user::id 23
  PASS stress user::group 23
  PASS stress user::home 23
  PASS stress user::shell 23
  PASS stress user::all 23
  PASS stress group::all 23
  PASS stress user::name 24
  PASS stress user::id 24
  PASS stress user::group 24
  PASS stress user::home 24
  PASS stress user::shell 24
  PASS stress user::all 24
  PASS stress group::all 24
  PASS stress user::name 25
  PASS stress user::id 25
  PASS stress user::group 25
  PASS stress user::home 25
  PASS stress user::shell 25
  PASS stress user::all 25
  PASS stress group::all 25
  PASS stress user::name 26
  PASS stress user::id 26
  PASS stress user::group 26
  PASS stress user::home 26
  PASS stress user::shell 26
  PASS stress user::all 26
  PASS stress group::all 26
  PASS stress user::name 27
  PASS stress user::id 27
  PASS stress user::group 27
  PASS stress user::home 27
  PASS stress user::shell 27
  PASS stress user::all 27
  PASS stress group::all 27
  PASS stress user::name 28
  PASS stress user::id 28
  PASS stress user::group 28
  PASS stress user::home 28
  PASS stress user::shell 28
  PASS stress user::all 28
  PASS stress group::all 28
  PASS stress user::name 29
  PASS stress user::id 29
  PASS stress user::group 29
  PASS stress user::home 29
  PASS stress user::shell 29
  PASS stress user::all 29
  PASS stress group::all 29
  PASS stress user::name 30
  PASS stress user::id 30
  PASS stress user::group 30
  PASS stress user::home 30
  PASS stress user::shell 30
  PASS stress user::all 30
  PASS stress group::all 30

[0020] final cleanup assertion
  PASS final user A absent
  PASS final user B absent
  PASS final user C absent
  PASS final group A absent
  PASS final group B absent
  PASS final group C absent

============================================================
 user.sh legendary production test summary
============================================================
Total sections : 20
Pass           : 584
Fail           : 0
Skip           : 0
Root           : /tmp/bashx-user-legendary.Y37HwO
Prefix         : bx26506796
============================================================

[[ CI WINDOWS ]]

3m 51s
Run bash src/parts/builtin/test.sh
[target] user.sh
[env] os=windows runtime=gitbash user=runneradmin group=Administrators mutate=1

[0001] api presence
  PASS function exists: user::valid
  PASS function exists: user::id
  PASS function exists: user::name
  PASS function exists: user::exists
  PASS function exists: user::add
  PASS function exists: user::del
  PASS function exists: user::all
  PASS function exists: user::groups
  PASS function exists: user::add_group
  PASS function exists: user::del_group
  PASS function exists: user::group
  PASS function exists: user::home
  PASS function exists: user::shell
  PASS function exists: user::is_root
  PASS function exists: user::is_admin
  PASS function exists: user::can_sudo
  PASS function exists: group::valid
  PASS function exists: group::id
  PASS function exists: group::name
  PASS function exists: group::exists
  PASS function exists: group::add
  PASS function exists: group::del
  PASS function exists: group::all
  PASS function exists: group::users
  PASS function exists: group::add_user
  PASS function exists: group::del_user

[0002] validation API
  PASS user::valid accepts runneradmin
  PASS group::valid accepts runneradmin
  PASS user::valid accepts Administrators
  PASS group::valid accepts Administrators
  PASS user::valid accepts bx97367526ua
  PASS group::valid accepts bx97367526ua
  PASS user::valid accepts bx97367526ga
  PASS group::valid accepts bx97367526ga
  PASS user::valid accepts abc_123
  PASS group::valid accepts abc_123
  PASS user::valid accepts abc-123
  PASS group::valid accepts abc-123
  PASS user::valid rejects hostile []
  PASS group::valid rejects hostile []
  PASS user::valid rejects hostile [*]
  PASS group::valid rejects hostile [*]
  PASS user::valid rejects hostile [?]
  PASS group::valid rejects hostile [?]
  PASS user::valid rejects hostile [[abc]]
  PASS group::valid rejects hostile [[abc]]
  PASS user::valid rejects hostile [bad/name]
  PASS group::valid rejects hostile [bad/name]
  PASS user::valid rejects hostile [bad\name]
  PASS group::valid rejects hostile [bad\name]
  PASS user::valid rejects hostile [bad
name]
  PASS group::valid rejects hostile [bad
name]
  PASS user::valid rejects hostile [bad
name]
  PASS group::valid rejects hostile [bad
name]

[0003] current identity reads
  PASS user::name nonempty
  PASS user::id nonempty
  PASS user::id numeric
  PASS user::group nonempty
  PASS group::name nonempty
  PASS group::id nonempty
  PASS group::id numeric
  PASS user::home nonempty
  PASS user::shell nonempty
  PASS user::name no CR/LF
  PASS group::name no CR/LF

[0004] identity repeatability
  PASS repeat user::name 1
  PASS repeat user::id 1
  PASS repeat user::group 1
  PASS repeat group::id 1
  PASS repeat user::name 2
  PASS repeat user::id 2
  PASS repeat user::group 2
  PASS repeat group::id 2
  PASS repeat user::name 3
  PASS repeat user::id 3
  PASS repeat user::group 3
  PASS repeat group::id 3
  PASS repeat user::name 4
  PASS repeat user::id 4
  PASS repeat user::group 4
  PASS repeat group::id 4
  PASS repeat user::name 5
  PASS repeat user::id 5
  PASS repeat user::group 5
  PASS repeat group::id 5
  PASS repeat user::name 6
  PASS repeat user::id 6
  PASS repeat user::group 6
  PASS repeat group::id 6
  PASS repeat user::name 7
  PASS repeat user::id 7
  PASS repeat user::group 7
  PASS repeat group::id 7
  PASS repeat user::name 8
  PASS repeat user::id 8
  PASS repeat user::group 8
  PASS repeat group::id 8
  PASS repeat user::name 9
  PASS repeat user::id 9
  PASS repeat user::group 9
  PASS repeat group::id 9
  PASS repeat user::name 10
  PASS repeat user::id 10
  PASS repeat user::group 10
  PASS repeat group::id 10
  PASS repeat user::name 11
  PASS repeat user::id 11
  PASS repeat user::group 11
  PASS repeat group::id 11
  PASS repeat user::name 12
  PASS repeat user::id 12
  PASS repeat user::group 12
  PASS repeat group::id 12

[0005] user::exists matrix
  PASS current user exists
  PASS current user in current group
  PASS fake user missing
  PASS fake user in current group missing
  PASS current user in fake group missing
  PASS user::exists rejects bad user []
  PASS user::exists rejects bad user [*]
  PASS user::exists rejects bad user [?]
  PASS user::exists rejects bad user [[x]]
  PASS user::exists rejects bad user [bad/name]
  PASS user::exists rejects bad user [bad
name]
  PASS user::exists rejects bad user [bad
name]
  PASS user::exists rejects bad group [*]
  PASS user::exists rejects bad group [?]
  PASS user::exists rejects bad group [[x]]
  PASS user::exists rejects bad group [bad/name]
  PASS user::exists rejects bad group [bad
group]
  PASS user::exists rejects bad group [bad
group]

[0006] group::exists matrix
  PASS current group exists
  PASS fake group missing
  PASS group::exists rejects bad group []
  PASS group::exists rejects bad group [*]
  PASS group::exists rejects bad group [?]
  PASS group::exists rejects bad group [[x]]
  PASS group::exists rejects bad group [bad/name]
  PASS group::exists rejects bad group [bad
group]
  PASS group::exists rejects bad group [bad
group]

[0007] id matrices
  PASS implicit id equals explicit current
  PASS fake user id fails
  PASS implicit group id equals explicit current
  PASS fake group id fails
  PASS user::id rejects bad [*]
  PASS group::id rejects bad [*]
  PASS user::id rejects bad [?]
  PASS group::id rejects bad [?]
  PASS user::id rejects bad [[x]]
  PASS group::id rejects bad [[x]]
  PASS user::id rejects bad [bad/name]
  PASS group::id rejects bad [bad/name]
  PASS user::id rejects bad [bad
x]
  PASS group::id rejects bad [bad
x]
  PASS user::id rejects bad [bad
x]
  PASS group::id rejects bad [bad
x]

[0008] list all users/groups
  PASS user::all nonempty
  PASS group::all nonempty
  PASS user::all contains current user
  PASS group::all contains current group
  PASS user::all excludes fake user
  PASS group::all excludes fake group
  PASS user::all unique
  PASS group::all unique

[0009] membership listing wrappers
  PASS user::groups current nonempty
  PASS group::users current nonempty
  PASS user::groups contains current group
  PASS group::users contains current user
  PASS user::groups current equals group::all user
  PASS group::users current equals user::all group
  PASS user::groups fake user fails
  PASS group::users fake group fails
  PASS user::groups rejects wildcard
  PASS group::users rejects wildcard

[0010] home and shell reads
  PASS implicit home nonempty
  PASS explicit home nonempty
  PASS implicit explicit home stable
  PASS implicit shell nonempty
  PASS explicit shell nonempty
  PASS implicit explicit shell stable
  PASS fake user home fails
  PASS fake user shell fails

[0011] privilege checks
  PASS user::is_root true branch
  PASS user::is_admin true branch
  PASS user::can_sudo false branch
  PASS is_root fake user fails
  PASS is_admin fake user fails
  PASS can_sudo fake user fails
  PASS windows can_sudo false

[0012] pre-mutation clean state
  PASS user A absent
  PASS user B absent
  PASS group A absent
  PASS group B absent
  PASS group C absent

[0013] group lifecycle destructive
  PASS group add A
  PASS group exists A
  PASS group add A idempotent
  PASS group id A
  PASS group::all contains A
  PASS group add invalid empty
  PASS group add invalid wildcard
  PASS group add invalid newline
  PASS group del A
  PASS group A gone
  PASS group del A idempotent
  PASS group del invalid empty
  PASS group del invalid wildcard

[0014] user create-only strict lifecycle
  PASS group add A
  PASS group add B
  PASS user add A in group A
  PASS user A exists
  PASS user A in group A
  PASS user add A group A idempotent
  PASS user add A group B strict fails
  PASS user A id
  PASS user A group
  PASS user A home
  PASS user A shell
  PASS user::all contains A
  PASS group::users A contains user A
  PASS user add invalid empty
  PASS user add invalid wildcard
  PASS user add invalid newline
  PASS user add fake group fails
  PASS user del A wrong group B fails
  PASS user A survives wrong group del
  PASS user del A with group A
  PASS user A gone
  PASS user del A idempotent
  PASS group del A
  PASS group del B

[0015] membership lifecycle user namespace
  PASS group add A
  PASS group add B
  PASS user add A in group A
  PASS user A not in group B
  PASS user add_group A B
  PASS user A now in B
  PASS user add_group A B idempotent
  PASS user::groups A contains B
  PASS group::users B contains A
  PASS user del_group A B
  PASS user A no longer in B
  PASS user del_group A B idempotent
  PASS add_group fake user fails
  PASS add_group creates missing group C
  PASS group C created by user::add_group
  PASS user A in group C
  PASS user del A
  PASS group del A
  PASS group del B
  PASS group del C

[0016] membership lifecycle group namespace strict
  PASS group add A
  PASS group add C
  PASS user add B in group A
  PASS group add_user C B
  PASS user B in group C
  PASS group add_user C B idempotent
  PASS group add_user missing group fails
  PASS group add_user missing user fails
  PASS group add_user invalid group fails
  PASS group add_user invalid user fails
  PASS group del_user C B
  PASS user B not in C
  PASS group del_user C B idempotent
  PASS group del_user missing group fails
  PASS group del_user missing user fails
  PASS user del B
  PASS group del A
  PASS group del C

[0017] delete safety and idempotency
  PASS user::del empty rejects
  PASS user::del wildcard rejects
  PASS user::del newline rejects
  PASS user::del valid missing idempotent
  PASS user::del valid missing with group fails
  PASS group::del empty rejects
  PASS group::del wildcard rejects
  PASS group::del newline rejects
  PASS group::del valid missing idempotent

[0018] hostile input sweep
  PASS user::exists hostile *
  PASS user::id hostile *
  PASS user::group hostile *
  PASS user::home hostile *
  PASS user::shell hostile *
  PASS user::groups hostile *
  PASS group::exists hostile *
  PASS group::id hostile *
  PASS group::users hostile *
  PASS user::exists hostile ?
  PASS user::id hostile ?
  PASS user::group hostile ?
  PASS user::home hostile ?
  PASS user::shell hostile ?
  PASS user::groups hostile ?
  PASS group::exists hostile ?
  PASS group::id hostile ?
  PASS group::users hostile ?
  PASS user::exists hostile [abc]
  PASS user::id hostile [abc]
  PASS user::group hostile [abc]
  PASS user::home hostile [abc]
  PASS user::shell hostile [abc]
  PASS user::groups hostile [abc]
  PASS group::exists hostile [abc]
  PASS group::id hostile [abc]
  PASS group::users hostile [abc]
  PASS user::exists hostile bad/name
  PASS user::id hostile bad/name
  PASS user::group hostile bad/name
  PASS user::home hostile bad/name
  PASS user::shell hostile bad/name
  PASS user::groups hostile bad/name
  PASS group::exists hostile bad/name
  PASS group::id hostile bad/name
  PASS group::users hostile bad/name
  PASS user::exists hostile bad\name
  PASS user::id hostile bad\name
  PASS user::group hostile bad\name
  PASS user::home hostile bad\name
  PASS user::shell hostile bad\name
  PASS user::groups hostile bad\name
  PASS group::exists hostile bad\name
  PASS group::id hostile bad\name
  PASS group::users hostile bad\name
  PASS user::exists hostile $USER
  PASS user::id hostile $USER
  PASS user::group hostile $USER
  PASS user::home hostile $USER
  PASS user::shell hostile $USER
  PASS user::groups hostile $USER
  PASS group::exists hostile $USER
  PASS group::id hostile $USER
  PASS group::users hostile $USER
  PASS user::exists hostile $(id)
  PASS user::id hostile $(id)
  PASS user::group hostile $(id)
  PASS user::home hostile $(id)
  PASS user::shell hostile $(id)
  PASS user::groups hostile $(id)
  PASS group::exists hostile $(id)
  PASS group::id hostile $(id)
  PASS group::users hostile $(id)
  PASS user::exists hostile ;true
  PASS user::id hostile ;true
  PASS user::group hostile ;true
  PASS user::home hostile ;true
  PASS user::shell hostile ;true
  PASS user::groups hostile ;true
  PASS group::exists hostile ;true
  PASS group::id hostile ;true
  PASS group::users hostile ;true
  PASS user::exists hostile x
y
  PASS user::id hostile x
y
  PASS user::group hostile x
y
  PASS user::home hostile x
y
  PASS user::shell hostile x
y
  PASS user::groups hostile x
y
  PASS group::exists hostile x
y
  PASS group::id hostile x
y
  PASS group::users hostile x
y
  PASS user::exists hostile x
y
  PASS user::id hostile x
y
  PASS user::group hostile x
y
  PASS user::home hostile x
y
  PASS user::shell hostile x
y
  PASS user::groups hostile x
y
  PASS group::exists hostile x
y
  PASS group::id hostile x
y
  PASS group::users hostile x
y

[0019] read stress
  PASS stress user::name 1
  PASS stress user::id 1
  PASS stress user::group 1
  PASS stress user::home 1
  PASS stress user::shell 1
  PASS stress user::all 1
  PASS stress group::all 1
  PASS stress user::name 2
  PASS stress user::id 2
  PASS stress user::group 2
  PASS stress user::home 2
  PASS stress user::shell 2
  PASS stress user::all 2
  PASS stress group::all 2
  PASS stress user::name 3
  PASS stress user::id 3
  PASS stress user::group 3
  PASS stress user::home 3
  PASS stress user::shell 3
  PASS stress user::all 3
  PASS stress group::all 3
  PASS stress user::name 4
  PASS stress user::id 4
  PASS stress user::group 4
  PASS stress user::home 4
  PASS stress user::shell 4
  PASS stress user::all 4
  PASS stress group::all 4
  PASS stress user::name 5
  PASS stress user::id 5
  PASS stress user::group 5
  PASS stress user::home 5
  PASS stress user::shell 5
  PASS stress user::all 5
  PASS stress group::all 5
  PASS stress user::name 6
  PASS stress user::id 6
  PASS stress user::group 6
  PASS stress user::home 6
  PASS stress user::shell 6
  PASS stress user::all 6
  PASS stress group::all 6
  PASS stress user::name 7
  PASS stress user::id 7
  PASS stress user::group 7
  PASS stress user::home 7
  PASS stress user::shell 7
  PASS stress user::all 7
  PASS stress group::all 7
  PASS stress user::name 8
  PASS stress user::id 8
  PASS stress user::group 8
  PASS stress user::home 8
  PASS stress user::shell 8
  PASS stress user::all 8
  PASS stress group::all 8
  PASS stress user::name 9
  PASS stress user::id 9
  PASS stress user::group 9
  PASS stress user::home 9
  PASS stress user::shell 9
  PASS stress user::all 9
  PASS stress group::all 9
  PASS stress user::name 10
  PASS stress user::id 10
  PASS stress user::group 10
  PASS stress user::home 10
  PASS stress user::shell 10
  PASS stress user::all 10
  PASS stress group::all 10
  PASS stress user::name 11
  PASS stress user::id 11
  PASS stress user::group 11
  PASS stress user::home 11
  PASS stress user::shell 11
  PASS stress user::all 11
  PASS stress group::all 11
  PASS stress user::name 12
  PASS stress user::id 12
  PASS stress user::group 12
  PASS stress user::home 12
  PASS stress user::shell 12
  PASS stress user::all 12
  PASS stress group::all 12
  PASS stress user::name 13
  PASS stress user::id 13
  PASS stress user::group 13
  PASS stress user::home 13
  PASS stress user::shell 13
  PASS stress user::all 13
  PASS stress group::all 13
  PASS stress user::name 14
  PASS stress user::id 14
  PASS stress user::group 14
  PASS stress user::home 14
  PASS stress user::shell 14
  PASS stress user::all 14
  PASS stress group::all 14
  PASS stress user::name 15
  PASS stress user::id 15
  PASS stress user::group 15
  PASS stress user::home 15
  PASS stress user::shell 15
  PASS stress user::all 15
  PASS stress group::all 15
  PASS stress user::name 16
  PASS stress user::id 16
  PASS stress user::group 16
  PASS stress user::home 16
  PASS stress user::shell 16
  PASS stress user::all 16
  PASS stress group::all 16
  PASS stress user::name 17
  PASS stress user::id 17
  PASS stress user::group 17
  PASS stress user::home 17
  PASS stress user::shell 17
  PASS stress user::all 17
  PASS stress group::all 17
  PASS stress user::name 18
  PASS stress user::id 18
  PASS stress user::group 18
  PASS stress user::home 18
  PASS stress user::shell 18
  PASS stress user::all 18
  PASS stress group::all 18
  PASS stress user::name 19
  PASS stress user::id 19
  PASS stress user::group 19
  PASS stress user::home 19
  PASS stress user::shell 19
  PASS stress user::all 19
  PASS stress group::all 19
  PASS stress user::name 20
  PASS stress user::id 20
  PASS stress user::group 20
  PASS stress user::home 20
  PASS stress user::shell 20
  PASS stress user::all 20
  PASS stress group::all 20
  PASS stress user::name 21
  PASS stress user::id 21
  PASS stress user::group 21
  PASS stress user::home 21
  PASS stress user::shell 21
  PASS stress user::all 21
  PASS stress group::all 21
  PASS stress user::name 22
  PASS stress user::id 22
  PASS stress user::group 22
  PASS stress user::home 22
  PASS stress user::shell 22
  PASS stress user::all 22
  PASS stress group::all 22
  PASS stress user::name 23
  PASS stress user::id 23
  PASS stress user::group 23
  PASS stress user::home 23
  PASS stress user::shell 23
  PASS stress user::all 23
  PASS stress group::all 23
  PASS stress user::name 24
  PASS stress user::id 24
  PASS stress user::group 24
  PASS stress user::home 24
  PASS stress user::shell 24
  PASS stress user::all 24
  PASS stress group::all 24
  PASS stress user::name 25
  PASS stress user::id 25
  PASS stress user::group 25
  PASS stress user::home 25
  PASS stress user::shell 25
  PASS stress user::all 25
  PASS stress group::all 25
  PASS stress user::name 26
  PASS stress user::id 26
  PASS stress user::group 26
  PASS stress user::home 26
  PASS stress user::shell 26
  PASS stress user::all 26
  PASS stress group::all 26
  PASS stress user::name 27
  PASS stress user::id 27
  PASS stress user::group 27
  PASS stress user::home 27
  PASS stress user::shell 27
  PASS stress user::all 27
  PASS stress group::all 27
  PASS stress user::name 28
  PASS stress user::id 28
  PASS stress user::group 28
  PASS stress user::home 28
  PASS stress user::shell 28
  PASS stress user::all 28
  PASS stress group::all 28
  PASS stress user::name 29
  PASS stress user::id 29
  PASS stress user::group 29
  PASS stress user::home 29
  PASS stress user::shell 29
  PASS stress user::all 29
  PASS stress group::all 29
  PASS stress user::name 30
  PASS stress user::id 30
  PASS stress user::group 30
  PASS stress user::home 30
  PASS stress user::shell 30
  PASS stress user::all 30
  PASS stress group::all 30

[0020] final cleanup assertion
  PASS final user A absent
  PASS final user B absent
  PASS final user C absent
  PASS final group A absent
  PASS final group B absent
  PASS final group C absent

============================================================
 user.sh legendary production test summary
============================================================
Total sections : 20
Pass           : 584
Fail           : 0
Skip           : 0
Root           : /tmp/bashx-user-legendary.XGOMFu
Prefix         : bx97367526
============================================================
