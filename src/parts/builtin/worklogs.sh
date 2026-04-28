codingmaster@codingmstr:/var/www/projects/gun$ bash -n tool/parts/builtin/path.sh
codingmaster@codingmstr:/var/www/projects/gun$ shellcheck tool/parts/builtin/path.sh
codingmaster@codingmstr:/var/www/projects/gun$ bash -n tool/parts/builtin/dir.sh
codingmaster@codingmstr:/var/www/projects/gun$ shellcheck tool/parts/builtin/dir.sh -e SC2148
codingmaster@codingmstr:/var/www/projects/gun$

[CI LINUX]

Run "bash" tool/parts/builtin/test.sh
[target]
file: tool/parts/builtin/path.sh
root: /tmp/tmp.ZFYhOYy5Q8
[basic predicates]
[pure path semantics]
[roots, relations, types, metadata]
/usr/bin/bash
[standard directories]
[filesystem mutations and safety]
[checksum and snapshot]
[archive extract backup strip sync]
/tmp/tmp.ZFYhOYy5Q8/archives/archive.zip
/tmp/tmp.ZFYhOYy5Q8/extract/tar-strip
/tmp/tmp.ZFYhOYy5Q8/extract/zip
[watch]
[industrial helpers]
[codec and encryption]
[adversarial path fuzz]
[safety fuzz]
[concurrency smoke]
[medium tree stress]
/tmp/tmp.ZFYhOYy5Q8/archives/medium.tar.gz
/tmp/tmp.ZFYhOYy5Q8/extract/medium
[coverage gate]
============================================================
 path.sh brutal test summary
============================================================
Target : tool/parts/builtin/path.sh
Root   : /tmp/tmp.ZFYhOYy5Q8
Total  : 2288
Pass   : 2288
Fail   : 0
Skip   : 0
Funcs  : 130/130 covered
============================================================

[CI MACOS]

Run "/opt/homebrew/bin/bash" tool/parts/builtin/test.sh

[target]
file: tool/parts/builtin/path.sh
root: /var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.x7oevYrVem

[basic predicates]

[pure path semantics]

[roots, relations, types, metadata]
/opt/homebrew/bin/bash
[standard directories]

[filesystem mutations and safety]

[checksum and snapshot]

[archive extract backup strip sync]
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.x7oevYrVem/archives/archive.zip
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.x7oevYrVem/extract/tar-strip
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.x7oevYrVem/extract/zip

[watch]

[industrial helpers]

[codec and encryption]

[adversarial path fuzz]

[safety fuzz]

[concurrency smoke]

[medium tree stress]
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.x7oevYrVem/archives/medium.tar.gz
/var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.x7oevYrVem/extract/medium

[coverage gate]

============================================================
 path.sh brutal test summary
============================================================
Target : tool/parts/builtin/path.sh
Root   : /var/folders/tb/y368xp_x10s3ty1b_mtl5mxr0000gn/T/tmp.x7oevYrVem
Total  : 2288
Pass   : 2288
Fail   : 0
Skip   : 0
Funcs  : 130/130 covered
============================================================

[CI WINDOWS]

Run "bash" tool/parts/builtin/test.sh
[target]
file: tool/parts/builtin/path.sh
root: /tmp/tmp.xEWbO3fHQj
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
/tmp/tmp.xEWbO3fHQj/archives/archive.zip
/tmp/tmp.xEWbO3fHQj/extract/tar-strip
/tmp/tmp.xEWbO3fHQj/extract/zip
[watch]
[industrial helpers]
  SKIP is_safe symlink escape unavailable
[codec and encryption]
  SKIP encode symlink rejection no symlink
[adversarial path fuzz]
[safety fuzz]
[concurrency smoke]
[medium tree stress]
/tmp/tmp.xEWbO3fHQj/archives/medium.tar.gz
/tmp/tmp.xEWbO3fHQj/extract/medium
[coverage gate]
============================================================
 path.sh brutal test summary
============================================================
Target : tool/parts/builtin/path.sh
Root   : /tmp/tmp.xEWbO3fHQj
Total  : 2283
Pass   : 2271
Fail   : 0
Skip   : 12
Funcs  : 130/130 covered
============================================================
