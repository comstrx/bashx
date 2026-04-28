codingmaster@codingmstr:/var/www/projects/bashx$ bash -n src/parts/builtin/path.sh
codingmaster@codingmstr:/var/www/projects/bashx$ shellcheck src/parts/builtin/path.sh -e SC2148
codingmaster@codingmstr:/var/www/projects/bashx$

[[CI LINUX]]

Run "bash" src/parts/builtin/test.sh

[target]
file: src/parts/builtin/path.sh
root: /tmp/tmp.V7qE7Gs9Ix

[basic predicates]

[pure path semantics]

[roots, relations, types, metadata]
/usr/bin/bash
[standard directories]

[filesystem mutations and safety]

[checksum and snapshot]

[archive extract backup strip sync]
/tmp/tmp.V7qE7Gs9Ix/archives/archive.zip
/tmp/tmp.V7qE7Gs9Ix/extract/tar-strip
/tmp/tmp.V7qE7Gs9Ix/extract/zip

[watch]

[industrial helpers]

[codec and encryption]

[adversarial path fuzz]

[safety fuzz]

[concurrency smoke]

[medium tree stress]
/tmp/tmp.V7qE7Gs9Ix/archives/medium.tar.gz
/tmp/tmp.V7qE7Gs9Ix/extract/medium

[coverage gate]

============================================================
 path.sh brutal test summary
============================================================
Target : src/parts/builtin/path.sh
Root   : /tmp/tmp.V7qE7Gs9Ix
Total  : 2288
Pass   : 2288
Fail   : 0
Skip   : 0
Funcs  : 130/130 covered
============================================================

[[CI MACOS]]

Run "/opt/homebrew/bin/bash" src/parts/builtin/test.sh

[target]
file: src/parts/builtin/path.sh
root: /var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.9bcvFYWJzZ

[basic predicates]

[pure path semantics]

[roots, relations, types, metadata]
/opt/homebrew/bin/bash
[standard directories]

[filesystem mutations and safety]

[checksum and snapshot]

[archive extract backup strip sync]
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.9bcvFYWJzZ/archives/archive.zip
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.9bcvFYWJzZ/extract/tar-strip
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.9bcvFYWJzZ/extract/zip

[watch]

[industrial helpers]

[codec and encryption]

[adversarial path fuzz]

[safety fuzz]

[concurrency smoke]

[medium tree stress]
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.9bcvFYWJzZ/archives/medium.tar.gz
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.9bcvFYWJzZ/extract/medium

[coverage gate]

============================================================
 path.sh brutal test summary
============================================================
Target : src/parts/builtin/path.sh
Root   : /var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.9bcvFYWJzZ
Total  : 2288
Pass   : 2288
Fail   : 0
Skip   : 0
Funcs  : 130/130 covered
============================================================

[[CI WINDOWS]]

Run "bash" src/parts/builtin/test.sh
[target]
file: src/parts/builtin/path.sh
root: /tmp/tmp.gpgEXbpT8g
[basic predicates]
[pure path semantics]
[roots, relations, types, metadata]
  SKIP chmod exact mode unsupported on Windows ACL/MSYS
  SKIP is_link symlink unavailable on this OS/session
  SKIP is_socket unix socket unsupported
/usr/bin/bash
[standard directories]
[filesystem mutations and safety]
  SKIP remove symlink-to-root safety unavailable
  SKIP clear symlink safety unavailable
  SKIP clear symlink-to-root safety unavailable
  SKIP symlink unsupported
  SKIP readlink no symlink
  SKIP mkdir mode exact unsupported on Windows ACL/MSYS
[checksum and snapshot]
  SKIP snapshot symlink unavailable
[archive extract backup strip sync]
/tmp/tmp.gpgEXbpT8g/archives/archive.zip
/tmp/tmp.gpgEXbpT8g/extract/tar-strip
/tmp/tmp.gpgEXbpT8g/extract/zip
[watch]
[industrial helpers]
  SKIP is_safe symlink escape unavailable
[codec and encryption]
  SKIP encode symlink rejection no symlink
[adversarial path fuzz]
[safety fuzz]
[concurrency smoke]
[medium tree stress]
/tmp/tmp.gpgEXbpT8g/archives/medium.tar.gz
/tmp/tmp.gpgEXbpT8g/extract/medium
[coverage gate]
============================================================
 path.sh brutal test summary
============================================================
Target : src/parts/builtin/path.sh
Root   : /tmp/tmp.gpgEXbpT8g
Total  : 2283
Pass   : 2271
Fail   : 0
Skip   : 12
Funcs  : 130/130 covered
============================================================
