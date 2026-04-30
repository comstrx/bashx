codingmaster@codingmstr:/var/www/projects/bashx$ bash -n src/parts/builtin/dir.sh
codingmaster@codingmstr:/var/www/projects/bashx$ shellcheck src/parts/builtin/dir.sh -e SC2148
codingmaster@codingmstr:/var/www/projects/bashx$

[[CI LINUX]]

Run "bash" src/parts/builtin/test.sh

[target]
path: src/parts/builtin/path.sh
dir : src/parts/builtin/dir.sh
root: /tmp/tmp.28iU7S7OuG

[basic predicates and directory-only wrappers]

[names, path transforms, metadata]

[filesystem mutations]

[links]
  SKIP hard-linking directories unsupported

[directory query API]

[archive extract backup strip sync]
/tmp/tmp.28iU7S7OuG/archives/root.tar.gz
/tmp/tmp.28iU7S7OuG/archives/root.backup.tar.gz

[hash checksum snapshot]
  SKIP checksum unavailable: sha tool missing

[codec and encryption]

[lock and watch]

[adversarial names and safety fuzz]

[medium tree stress]
  SKIP slow archive/hash stress disabled

[coverage gate]

============================================================
 dir.sh brutal test summary
============================================================
Path   : src/parts/builtin/path.sh
Dir    : src/parts/builtin/dir.sh
Root   : /tmp/tmp.28iU7S7OuG
Total  : 2092
Pass   : 2089
Fail   : 0
Skip   : 3
Funcs  : 95/95 covered
Fuzz   : 300 iterations
============================================================

[[CI MACOS]]

Run "/opt/homebrew/bin/bash" src/parts/builtin/test.sh

[target]
path: src/parts/builtin/path.sh
dir : src/parts/builtin/dir.sh
root: /var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.kXyhBzYyIv

[basic predicates and directory-only wrappers]

[names, path transforms, metadata]

[filesystem mutations]

[links]
  SKIP hard-linking directories unsupported

[directory query API]

[archive extract backup strip sync]
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.kXyhBzYyIv/archives/root.tar.gz
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.kXyhBzYyIv/archives/root.backup.tar.gz

[hash checksum snapshot]
  SKIP checksum unavailable: sha tool missing

[codec and encryption]

[lock and watch]

[adversarial names and safety fuzz]

[medium tree stress]
  SKIP slow archive/hash stress disabled

[coverage gate]

============================================================
 dir.sh brutal test summary
============================================================
Path   : src/parts/builtin/path.sh
Dir    : src/parts/builtin/dir.sh
Root   : /var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.kXyhBzYyIv
Total  : 2092
Pass   : 2089
Fail   : 0
Skip   : 3
Funcs  : 95/95 covered
Fuzz   : 300 iterations
============================================================

[[CI WINDOWS]]

Run "bash" src/parts/builtin/test.sh

[target]
path: src/parts/builtin/path.sh
dir : src/parts/builtin/dir.sh
root: /tmp/tmp.vEgoOETTNz

[basic predicates and directory-only wrappers]

[names, path transforms, metadata]

[filesystem mutations]
  SKIP chmod exact mode unsupported on Windows ACL/MSYS

[links]
  SKIP symlink unavailable on this OS/session
  SKIP is_link symlink unavailable
  SKIP readlink symlink unavailable
  SKIP link directory hardlink unavailable

[directory query API]
  SKIP contains_link no symlink
  SKIP find_links no symlink
  SKIP walk_links no symlink
  SKIP list_links no symlink
  SKIP count_links no symlink

[archive extract backup strip sync]
/tmp/tmp.vEgoOETTNz/archives/root.tar.gz
/tmp/tmp.vEgoOETTNz/archives/root.backup.tar.gz

[hash checksum snapshot]
  SKIP checksum unavailable: sha tool missing

[codec and encryption]

[lock and watch]

[adversarial names and safety fuzz]

[medium tree stress]
  SKIP slow archive/hash stress disabled

[coverage gate]

============================================================
 dir.sh brutal test summary
============================================================
Path   : src/parts/builtin/path.sh
Dir    : src/parts/builtin/dir.sh
Root   : /tmp/tmp.vEgoOETTNz
Total  : 2092
Pass   : 2080
Fail   : 0
Skip   : 12
Funcs  : 95/95 covered
Fuzz   : 300 iterations
============================================================
