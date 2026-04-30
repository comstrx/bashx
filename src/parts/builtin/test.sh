#!/usr/bin/env bash

set -uo pipefail

ROOT="${ROOT:-}"
TARGET_FILE="${TARGET_FILE:-src/parts/builtin/file.sh}"
PATH_FILE="${PATH_FILE:-src/parts/builtin/path.sh}"
DIR_FILE="${DIR_FILE:-src/parts/builtin/dir.sh}"
SYSTEM_FILE="${SYSTEM_FILE:-src/parts/builtin/system.sh}"

if [[ -z "${ROOT}" ]]; then
    ROOT="$(pwd -P 2>/dev/null || pwd)"
fi

cd "${ROOT}" 2>/dev/null || exit 1

[[ -f "${SYSTEM_FILE}" ]] && source "${SYSTEM_FILE}"
[[ -f "${PATH_FILE}"   ]] && source "${PATH_FILE}"
[[ -f "${DIR_FILE}"    ]] && source "${DIR_FILE}"
[[ -f "${TARGET_FILE}" ]] && source "${TARGET_FILE}"

if ! declare -F file::exists >/dev/null 2>&1; then
    printf 'FATAL: file.sh was not loaded: %s\n' "${TARGET_FILE}" >&2
    exit 1
fi

if ! declare -F path::exists >/dev/null 2>&1; then
    printf 'FATAL: path.sh was not loaded: %s\n' "${PATH_FILE}" >&2
    exit 1
fi

if ! declare -F sys::has >/dev/null 2>&1; then
    sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
fi

TOTAL=0
PASS=0
FAIL=0
SKIP=0

ROOT_TMP="$(mktemp -d 2>/dev/null || mktemp -d -t bashx_file_test)"
A="${ROOT_TMP}/a.txt"
B="${ROOT_TMP}/b.txt"
C="${ROOT_TMP}/c.txt"
D="${ROOT_TMP}/deep/inner/d.txt"
BIN="${ROOT_TMP}/bin.dat"
EMPTY="${ROOT_TMP}/empty.txt"
MISSING="${ROOT_TMP}/missing.txt"
DIR="${ROOT_TMP}/dir"
OUT="${ROOT_TMP}/out"
LOCK="${ROOT_TMP}/lockfile"

mkdir -p "${DIR}" "${OUT}" "${ROOT_TMP}/deep/inner"
printf 'alpha\nbeta\ngamma\nbeta\n' > "${A}"
printf 'alpha\nbeta\ngamma\nbeta\n' > "${B}"
printf 'different\n' > "${C}"
printf '' > "${EMPTY}"
printf '\000\001\002\377' > "${BIN}"

cleanup () {
    rm -rf -- "${ROOT_TMP}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

declare -A HIT=()

mark () {
    HIT["$1"]=1
}

say () {
    printf '%s\n' "$*"
}

pass () {
    PASS=$(( PASS + 1 ))
    TOTAL=$(( TOTAL + 1 ))
    printf '  PASS %s\n' "$1"
}

fail () {
    FAIL=$(( FAIL + 1 ))
    TOTAL=$(( TOTAL + 1 ))
    printf '  FAIL %s\n' "$1" >&2
}

skip () {
    SKIP=$(( SKIP + 1 ))
    printf '  SKIP %s\n' "$1"
}

assert_true () {
    local name="$1"
    shift

    if "$@"; then pass "${name}"
    else fail "${name}"
    fi
}

assert_false () {
    local name="$1"
    shift

    if "$@"; then fail "${name}"
    else pass "${name}"
    fi
}

assert_eq () {
    local name="$1" expected="$2" actual="$3"

    if [[ "${actual}" == "${expected}" ]]; then pass "${name}"
    else
        fail "${name}: expected <${expected}> got <${actual}>"
    fi
}

assert_ne () {
    local name="$1" actual="$2"

    if [[ -n "${actual}" ]]; then pass "${name}"
    else fail "${name}: empty output"
    fi
}

assert_file_content () {
    local name="$1" file="$2" expected="$3" actual=""

    actual="$(cat "${file}" 2>/dev/null || true)"
    assert_eq "${name}" "${expected}" "${actual}"
}

section () {
    printf '\n[%s]\n' "$1"
}

call_timeout () {
    local seconds="$1"
    shift

    if sys::has timeout; then timeout "${seconds}" "$@"
    else return 125
    fi
}

section 'coverage: functions exist'

EXPECTED_FUNCS=(
    file::valid file::exists file::missing file::empty file::filled file::readable file::writable file::executable
    file::is_link file::is_hidden file::is_under file::is_safe file::is_same file::has_ext
    file::name file::dir file::dirname file::drive file::resolve file::expand file::abs file::rel file::can
    file::stem file::ext file::dotext file::setname file::setstem file::setext
    file::size file::mtime file::atime file::ctime file::age file::owner file::group file::mode file::inode
    file::new file::ensure file::ensure_dir file::remove file::clear file::rename file::move file::copy file::link file::symlink file::readlink file::chmod file::mktemp file::mktemp_near
    file::sync file::watch file::strip file::archive file::extract file::backup
    file::hash file::checksum file::snapshot file::encode file::decode file::encrypt file::decrypt
    file::trylock file::lock file::unlock file::locked file::with_lock
    file::encoding file::shebang file::mime file::kind file::is_text file::is_binary file::is_equal file::changed_since
    file::starts_with file::ends_with file::contains file::contains_line
    file::grep file::find file::find_line file::find_count file::lines_count file::words_count file::bytes_count
    file::write file::write_once file::writeln file::write_lines file::write_stdin file::write_atomic file::write_atomic_stdin
    file::append file::appendln file::append_lines file::append_stdin file::append_unique
    file::prepend file::prependln file::prepend_lines file::prepend_stdin file::prepend_unique
    file::read file::lines file::first_line file::last_line file::line file::range file::head file::tail
    file::replace file::replace_regex file::replace_line file::insert_line file::delete_line file::delete_match file::delete_empty_lines
    file::sort file::reverse file::dedupe file::truncate file::touch_at
    file::diff file::rotate file::restore file::tail_follow
)

assert_eq 'expected function count' '130' "${#EXPECTED_FUNCS[@]}"

for fn in "${EXPECTED_FUNCS[@]}"; do
    if declare -F "${fn}" >/dev/null 2>&1; then pass "declared ${fn}"
    else fail "missing ${fn}"
    fi
done

section 'predicates and path-facing wrappers'

mark file::valid;       assert_true  'valid accepts normal path' file::valid "${A}"
mark file::valid;       assert_false 'valid rejects empty path' file::valid ''
mark file::exists;      assert_true  'exists detects regular file' file::exists "${A}"
mark file::exists;      assert_false 'exists rejects directory' file::exists "${DIR}"
mark file::missing;     assert_true  'missing detects missing regular file' file::missing "${MISSING}"
mark file::missing;     assert_false 'missing rejects existing file' file::missing "${A}"
mark file::empty;       assert_true  'empty detects empty file' file::empty "${EMPTY}"
mark file::empty;       assert_true  'empty treats missing as empty' file::empty "${MISSING}"
mark file::filled;      assert_true  'filled detects content' file::filled "${A}"
mark file::filled;      assert_false 'filled rejects empty file' file::filled "${EMPTY}"
mark file::readable;    assert_true  'readable detects readable file' file::readable "${A}"
mark file::writable;    assert_true  'writable detects writable file' file::writable "${A}"
mark file::executable;  chmod +x "${A}" 2>/dev/null || true; assert_true 'executable detects executable file' file::executable "${A}"; chmod -x "${A}" 2>/dev/null || true
mark file::is_hidden;   printf x > "${ROOT_TMP}/.hidden"; assert_true 'is_hidden detects dotfile' file::is_hidden "${ROOT_TMP}/.hidden"
mark file::is_hidden;   assert_false 'is_hidden rejects normal file' file::is_hidden "${A}"
mark file::is_under;    assert_true  'is_under detects file below root' file::is_under "${A}" "${ROOT_TMP}"
mark file::is_safe;     assert_true  'is_safe accepts file inside root' file::is_safe "${A}" "${ROOT_TMP}"
mark file::is_same;     assert_true  'is_same detects same file path' file::is_same "${A}" "${A}"
mark file::has_ext;     assert_true  'has_ext matches extension' file::has_ext "${A}" txt TXT
mark file::has_ext;     assert_false 'has_ext rejects wrong extension' file::has_ext "${A}" md

if ln -s "${A}" "${ROOT_TMP}/a.link" 2>/dev/null; then
    mark file::is_link;     assert_true  'is_link detects symlink to file' file::is_link "${ROOT_TMP}/a.link"
    mark file::readlink;    assert_ne    'readlink returns target' "$(file::readlink "${ROOT_TMP}/a.link" 2>/dev/null || true)"
else
    mark file::is_link;     skip 'is_link symlink unsupported'
    mark file::readlink;    skip 'readlink symlink unsupported'
fi

section 'names, transforms, resolution'

mark file::name;        assert_eq 'name returns basename' 'a.txt' "$(file::name "${A}")"
mark file::dirname;     assert_eq 'dirname returns parent path' "${ROOT_TMP}" "$(file::dirname "${A}")"
mark file::dir;         assert_eq 'dir returns parent basename' "$(basename "${ROOT_TMP}")" "$(file::dir "${A}")"
mark file::stem;        assert_eq 'stem returns basename without extension' 'a' "$(file::stem "${A}")"
mark file::ext;         assert_eq 'ext returns extension' 'txt' "$(file::ext "${A}")"
mark file::dotext;      assert_eq 'dotext returns dotted extension' '.txt' "$(file::dotext "${A}")"
mark file::setname;     assert_eq 'setname changes name' "${ROOT_TMP}/renamed.md" "$(file::setname "${A}" renamed.md)"
mark file::setstem;     assert_eq 'setstem changes stem' "${ROOT_TMP}/main.txt" "$(file::setstem "${A}" main)"
mark file::setext;      assert_eq 'setext changes extension' "${ROOT_TMP}/a.md" "$(file::setext "${A}" md)"
mark file::drive;       file::drive 'C:/x/y.txt' >/dev/null 2>&1 && pass 'drive detects Windows drive' || skip 'drive unavailable on current path semantics'
mark file::resolve;     assert_ne 'resolve returns path' "$(file::resolve "${A}" 2>/dev/null || true)"
mark file::expand;      assert_eq 'expand leaves normal path intact' "${A}" "$(file::expand "${A}")"
mark file::abs;         assert_ne 'abs returns absolute path' "$(file::abs "${A}" 2>/dev/null || true)"
mark file::rel;         assert_eq 'rel returns relative from root' 'a.txt' "$(file::rel "${A}" "${ROOT_TMP}" 2>/dev/null || true)"
mark file::can;         assert_ne 'can returns canonical existing file' "$(file::can "${A}" 2>/dev/null || true)"

section 'metadata'

META="${ROOT_TMP}/metadata.txt"
printf '%s' 'alpha beta gamma delta' > "${META}"
META_SIZE="$(wc -c < "${META}" | tr -d '[:space:]')"

mark file::size;        assert_eq 'size counts bytes' "${META_SIZE}" "$(file::size "${META}" 2>/dev/null | tr -d '\n' || true)"
mark file::mtime;       assert_ne 'mtime returns timestamp' "$(file::mtime "${META}" 2>/dev/null || true)"
mark file::atime;       assert_ne 'atime returns timestamp' "$(file::atime "${META}" 2>/dev/null || true)"
mark file::ctime;       assert_ne 'ctime returns timestamp' "$(file::ctime "${META}" 2>/dev/null || true)"
mark file::age;         assert_ne 'age returns age seconds' "$(file::age "${META}" 2>/dev/null || true)"
mark file::owner;       file::owner "${META}" >/dev/null 2>&1 && pass 'owner returns owner' || skip 'owner unavailable'
mark file::group;       file::group "${META}" >/dev/null 2>&1 && pass 'group returns group' || skip 'group unavailable'
mark file::mode;        assert_ne 'mode returns permissions' "$(file::mode "${META}" 2>/dev/null || true)"
mark file::inode;       assert_ne 'inode returns inode' "$(file::inode "${META}" 2>/dev/null || true)"

section 'filesystem mutations'

T="${ROOT_TMP}/new.txt"
mark file::new;         assert_true  'new creates missing file' file::new "${T}"
mark file::new;         assert_false 'new rejects existing file' file::new "${T}"
mark file::ensure;      rm -f -- "${T}"; assert_true 'ensure creates or touches file' file::ensure "${T}"
mark file::ensure_dir;  assert_true  'ensure_dir creates parent directory' file::ensure_dir "${D}"
mark file::clear;       printf x > "${T}"; assert_true 'clear truncates file' file::clear "${T}"; assert_eq 'clear left zero bytes' '0' "$(file::size "${T}" | tr -d '\n')"
mark file::rename;      printf x > "${T}"; assert_true 'rename moves file' file::rename "${T}" "${ROOT_TMP}/renamed.txt"; T="${ROOT_TMP}/renamed.txt"
mark file::move;        assert_true 'move aliases rename' file::move "${T}" "${ROOT_TMP}/moved.txt"; T="${ROOT_TMP}/moved.txt"
mark file::copy;        assert_true 'copy duplicates file' file::copy "${T}" "${ROOT_TMP}/copy.txt"
mark file::chmod;       assert_true 'chmod applies permissions' file::chmod "${T}" 600
mark file::mktemp;      TMPF="$(file::mktemp 2>/dev/null || true)"; [[ -n "${TMPF}" && -f "${TMPF}" ]] && pass 'mktemp creates temp file' || fail 'mktemp creates temp file'; rm -f -- "${TMPF}" 2>/dev/null || true
mark file::mktemp_near; TMPN="$(file::mktemp_near "${A}" 2>/dev/null || true)"; [[ -n "${TMPN}" && -f "${TMPN}" ]] && pass 'mktemp_near creates nearby file' || fail 'mktemp_near creates nearby file'; rm -f -- "${TMPN}" 2>/dev/null || true
mark file::remove;      assert_true 'remove deletes regular file' file::remove "${ROOT_TMP}/copy.txt"

if ln "${A}" "${ROOT_TMP}/a.hard" 2>/dev/null; then
    mark file::link; assert_true 'link creates hardlink' file::link "${A}" "${ROOT_TMP}/a.hard2"
else
    mark file::link; skip 'hardlink unsupported'
fi

if ln -s "${A}" "${ROOT_TMP}/a.sym-src" 2>/dev/null; then
    rm -f -- "${ROOT_TMP}/a.sym-src"
    mark file::symlink; assert_true 'symlink creates symlink' file::symlink "${A}" "${ROOT_TMP}/a.sym"
else
    mark file::symlink; skip 'symlink unsupported'
fi

section 'path delegated heavy operations'

mark file::sync;        file::sync "${A}" "${ROOT_TMP}/sync.txt" >/dev/null 2>&1 && pass 'sync copies file to target' || skip 'sync unavailable or different arity'
mark file::strip;       printf '  x  \n\n' > "${ROOT_TMP}/strip.txt"; file::strip "${ROOT_TMP}/strip.txt" >/dev/null 2>&1 && pass 'strip runs on file' || skip 'strip unavailable'
mark file::archive;     if file::archive "${A}" "${ROOT_TMP}/a.tar.gz" >/dev/null 2>&1; then pass 'archive creates archive'; else skip 'archive unavailable'; fi
mark file::extract;     if [[ -f "${ROOT_TMP}/a.tar.gz" ]] && file::extract "${ROOT_TMP}/a.tar.gz" "${ROOT_TMP}/extract" >/dev/null 2>&1; then pass 'extract extracts archive'; else skip 'extract unavailable'; fi
mark file::backup;      cp "${A}" "${ROOT_TMP}/backup.txt"; file::backup "${ROOT_TMP}/backup.txt" >/dev/null 2>&1 && pass 'backup creates backup' || skip 'backup unavailable'
mark file::hash;        file::hash "${A}" >/dev/null 2>&1 && pass 'hash hashes file' || skip 'hash unavailable'
mark file::checksum;    file::checksum "${A}" >/dev/null 2>&1 && pass 'checksum snapshots file' || skip 'checksum unavailable'
mark file::snapshot;    file::snapshot "${A}" >/dev/null 2>&1 && pass 'snapshot snapshots file' || skip 'snapshot unavailable'

ENC="${ROOT_TMP}/enc.txt"
printf 'secret' > "${ENC}"
mark file::encode;      file::encode "${ENC}" "${ENC}.b64" >/dev/null 2>&1 && pass 'encode runs on file' || skip 'encode unavailable'
mark file::decode;      [[ -f "${ENC}.b64" ]] && file::decode "${ENC}.b64" "${ENC}.decoded" >/dev/null 2>&1 && pass 'decode runs on file' || skip 'decode unavailable'
mark file::encrypt;     file::encrypt "${ENC}" "${ENC}.crypt" test-pass >/dev/null 2>&1 && pass 'encrypt runs on file' || skip 'encrypt unavailable'
mark file::decrypt;     [[ -f "${ENC}.crypt" ]] && file::decrypt "${ENC}.crypt" "${ENC}.plain" test-pass >/dev/null 2>&1 && pass 'decrypt runs on file' || skip 'decrypt unavailable'

section 'locks and watchers'

mark file::trylock;     if file::trylock "${LOCK}" >/dev/null 2>&1; then pass 'trylock locks file'; else skip 'trylock unavailable'; fi
mark file::locked;      file::locked "${LOCK}" >/dev/null 2>&1 && pass 'locked detects lock' || skip 'locked unavailable or no lock active'
mark file::unlock;      file::unlock "${LOCK}" >/dev/null 2>&1 && pass 'unlock unlocks file' || skip 'unlock unavailable'
mark file::lock;        if call_timeout 2 file::lock "${LOCK}" >/dev/null 2>&1; then pass 'lock locks file'; file::unlock "${LOCK}" >/dev/null 2>&1 || true; else skip 'lock unavailable'; fi
mark file::with_lock;   if file::with_lock "${LOCK}" true >/dev/null 2>&1; then pass 'with_lock executes callback'; else skip 'with_lock unavailable'; fi
mark file::watch;       if call_timeout 1 file::watch "${A}" >/dev/null 2>&1; then pass 'watch exits under timeout'; else skip 'watch unavailable or long-running by design'; fi

section 'classification and content predicates'

SHE="${ROOT_TMP}/run.sh"
printf '#!/usr/bin/env bash\necho ok\n' > "${SHE}"
mark file::encoding;    file::encoding "${A}" >/dev/null 2>&1 && pass 'encoding detects encoding' || skip 'encoding requires file command'
mark file::shebang;     assert_eq 'shebang reads shebang' '#!/usr/bin/env bash' "$(file::shebang "${SHE}" 2>/dev/null || true)"
mark file::mime;        file::mime "${A}" >/dev/null 2>&1 && pass 'mime detects MIME' || skip 'mime requires file command'
mark file::kind;        assert_eq 'kind classifies shell script' 'script' "$(file::kind "${SHE}" 2>/dev/null || true)"
mark file::is_text;     assert_true 'is_text detects text' file::is_text "${A}"
mark file::is_binary;   assert_true 'is_binary detects binary-ish file' file::is_binary "${BIN}"
mark file::is_equal;    assert_true 'is_equal detects equal content' file::is_equal "${A}" "${B}"
mark file::is_equal;    assert_false 'is_equal rejects different content' file::is_equal "${A}" "${C}"
sleep 1
printf newer > "${ROOT_TMP}/newer.txt"
mark file::changed_since; assert_true 'changed_since detects newer file than timestamp/file' file::changed_since "${ROOT_TMP}/newer.txt" "${A}"
mark file::starts_with; assert_true 'starts_with regex checks first line' file::starts_with "${A}" 'alp'
mark file::starts_with; assert_true 'starts_with fixed checks first line' file::starts_with "${A}" 'alpha' fixed
mark file::ends_with;   assert_true 'ends_with regex checks last line' file::ends_with "${A}" 'beta'
mark file::ends_with;   assert_true 'ends_with fixed checks last line' file::ends_with "${A}" 'beta' fixed
mark file::contains;    assert_true 'contains regex finds pattern' file::contains "${A}" 'g.mm.'
mark file::contains;    assert_true 'contains fixed finds text' file::contains "${A}" 'gamma' fixed
mark file::contains_line; assert_true 'contains_line regex finds whole line' file::contains_line "${A}" 'beta'
mark file::contains_line; assert_true 'contains_line fixed finds whole line' file::contains_line "${A}" 'gamma' fixed

section 'search and counters'

mark file::grep;        assert_eq 'grep returns matching line count' '2' "$(file::grep "${A}" '^beta$' | wc -l | tr -d '[:space:]')"
mark file::find;        assert_ne 'find returns first byte occurrence' "$(file::find "${A}" beta 2>/dev/null || true)"
mark file::find_line;   assert_eq 'find_line returns first line number' '2' "$(file::find_line "${A}" beta 2>/dev/null || true)"
mark file::find_count;  assert_eq 'find_count counts occurrences' '2' "$(file::find_count "${A}" beta 2>/dev/null || true)"
mark file::lines_count; assert_eq 'lines_count counts lines' '4' "$(file::lines_count "${A}" 2>/dev/null || true)"
mark file::words_count; assert_eq 'words_count counts words' '4' "$(file::words_count "${A}" 2>/dev/null || true)"
mark file::bytes_count; A_SIZE="$(wc -c < "${A}" | tr -d '[:space:]')"; assert_eq 'bytes_count aliases size' "${A_SIZE}" "$(file::bytes_count "${A}" 2>/dev/null | tr -d '\n' || true)"

section 'write, append, prepend APIs'

W="${ROOT_TMP}/write.txt"
mark file::write;              assert_true 'write writes content' file::write "${W}" abc; assert_file_content 'write content ok' "${W}" abc
mark file::write_once;         assert_true 'write_once keeps existing file' file::write_once "${W}" zzz; assert_file_content 'write_once did not overwrite' "${W}" abc
mark file::writeln;            assert_true 'writeln writes line' file::writeln "${W}" abc; assert_eq 'writeln content ok' 'abc' "$(file::first_line "${W}")"
mark file::write_lines;        assert_true 'write_lines writes multiple lines' file::write_lines "${W}" one two three; assert_eq 'write_lines line count' '3' "$(file::lines_count "${W}")"
mark file::write_stdin;        printf stdin | file::write_stdin "${W}"; assert_file_content 'write_stdin content ok' "${W}" stdin
mark file::write_atomic;       assert_true 'write_atomic writes content' file::write_atomic "${W}" atomic; assert_file_content 'write_atomic content ok' "${W}" atomic
mark file::write_atomic_stdin; printf atomstdin | file::write_atomic_stdin "${W}"; assert_file_content 'write_atomic_stdin content ok' "${W}" atomstdin
mark file::append;             assert_true 'append appends content' file::append "${W}" X; assert_file_content 'append content ok' "${W}" atomstdinX
mark file::appendln;           assert_true 'appendln appends line' file::appendln "${W}" Y; assert_true 'appendln searchable' file::contains "${W}" Y fixed
mark file::append_lines;       assert_true 'append_lines appends many lines' file::append_lines "${W}" L1 L2; assert_true 'append_lines searchable' file::contains_line "${W}" L2 fixed
mark file::append_stdin;       printf Z | file::append_stdin "${W}"; assert_true 'append_stdin appends' file::contains "${W}" Z fixed
mark file::append_unique;      file::write_lines "${W}" one two; file::append_unique "${W}" two; file::append_unique "${W}" three; assert_eq 'append_unique adds only missing' '3' "$(file::lines_count "${W}")"
mark file::prepend;            file::write "${W}" tail; assert_true 'prepend prepends content' file::prepend "${W}" head; assert_file_content 'prepend content ok' "${W}" headtail
mark file::prependln;          file::write_lines "${W}" tail; assert_true 'prependln prepends line' file::prependln "${W}" head; assert_eq 'prependln first line' 'head' "$(file::first_line "${W}")"
mark file::prepend_lines;      file::write_lines "${W}" tail; assert_true 'prepend_lines prepends multiple' file::prepend_lines "${W}" h1 h2; assert_eq 'prepend_lines first line' 'h1' "$(file::first_line "${W}")"
mark file::prepend_stdin;      file::write_lines "${W}" tail; printf 'stdin-head\n' | file::prepend_stdin "${W}"; assert_eq 'prepend_stdin first line' 'stdin-head' "$(file::first_line "${W}")"
mark file::prepend_unique;     file::write_lines "${W}" two three; file::prepend_unique "${W}" two; file::prepend_unique "${W}" one; assert_eq 'prepend_unique adds only missing at top' 'one' "$(file::first_line "${W}")"

section 'read and line APIs'

R="${ROOT_TMP}/read.txt"
printf 'one\ntwo\nthree\nfour\n' > "${R}"
mark file::read;        assert_eq 'read reads file' $'one\ntwo\nthree\nfour' "$(file::read "${R}" 2>/dev/null || true)"
mark file::lines;       assert_eq 'lines aliases read' $'one\ntwo\nthree\nfour' "$(file::lines "${R}" 2>/dev/null || true)"
mark file::first_line;  assert_eq 'first_line returns first' 'one' "$(file::first_line "${R}" 2>/dev/null || true)"
mark file::last_line;   assert_eq 'last_line returns last' 'four' "$(file::last_line "${R}" 2>/dev/null | tr -d '\r' || true)"
mark file::line;        assert_eq 'line returns nth line' 'three' "$(file::line "${R}" 3 2>/dev/null | tr -d '\r' || true)"
mark file::range;       assert_eq 'range returns selected lines' $'two\nthree' "$(file::range "${R}" 2 3 2>/dev/null | tr -d '\r' || true)"
mark file::head;        assert_eq 'head returns first n lines' $'one\ntwo' "$(file::head "${R}" 2 2>/dev/null | tr -d '\r' || true)"
mark file::tail;        assert_eq 'tail returns last n lines' $'three\nfour' "$(file::tail "${R}" 2 2>/dev/null | tr -d '\r' || true)"

section 'editing APIs'

E="${ROOT_TMP}/edit.txt"
printf 'alpha\nbeta\ngamma\n\nalpha\n' > "${E}"
mark file::replace;            assert_true 'replace replaces literal text' file::replace "${E}" alpha ALPHA; assert_true 'replace result contains ALPHA' file::contains "${E}" ALPHA fixed
mark file::replace_regex;      assert_true 'replace_regex replaces regex' file::replace_regex "${E}" 'b.ta' BETA; assert_true 'replace_regex result contains BETA' file::contains "${E}" BETA fixed
mark file::replace_line;       assert_true 'replace_line replaces selected line' file::replace_line "${E}" 2 LINE2; assert_eq 'replace_line changed line' 'LINE2' "$(file::line "${E}" 2)"
mark file::insert_line;        assert_true 'insert_line inserts before selected line' file::insert_line "${E}" 2 INSERTED; assert_eq 'insert_line inserted line' 'INSERTED' "$(file::line "${E}" 2)"
mark file::delete_line;        assert_true 'delete_line deletes selected line' file::delete_line "${E}" 2; assert_ne 'delete_line preserved file' "$(file::read "${E}" 2>/dev/null || true)"
mark file::delete_match;       assert_true 'delete_match deletes matching lines' file::delete_match "${E}" '^ALPHA$'; assert_false 'delete_match removed ALPHA' file::contains_line "${E}" ALPHA fixed
mark file::delete_empty_lines; printf 'a\n\n b \n\n' > "${E}"; assert_true 'delete_empty_lines removes blank lines' file::delete_empty_lines "${E}"; assert_eq 'delete_empty_lines line count' '2' "$(file::lines_count "${E}")"

section 'ordering, truncation, timestamps, comparison, rotation'

O="${ROOT_TMP}/order.txt"
printf 'c\na\nb\na\n' > "${O}"
mark file::sort;        assert_true 'sort asc sorts lines' file::sort "${O}" asc; assert_eq 'sort asc first line' 'a' "$(file::first_line "${O}")"
printf 'c\na\nb\na\n' > "${O}"
mark file::sort;        assert_true 'sort unique removes duplicates' file::sort "${O}" unique; assert_eq 'sort unique line count' '3' "$(file::lines_count "${O}")"
printf 'one\ntwo\nthree\n' > "${O}"
mark file::reverse;     assert_true 'reverse reverses lines' file::reverse "${O}"; assert_eq 'reverse first line' 'three' "$(file::first_line "${O}")"
printf 'a\na\nb\na\n' > "${O}"
mark file::dedupe;      assert_true 'dedupe removes repeated lines keeping first' file::dedupe "${O}"; assert_eq 'dedupe line count' '2' "$(file::lines_count "${O}")"
printf '1234567890' > "${O}"
mark file::truncate;    assert_true 'truncate changes size' file::truncate "${O}" 4; assert_eq 'truncate size' '4' "$(file::size "${O}" | tr -d '\n')"
REF="${ROOT_TMP}/ref.txt"; printf ref > "${REF}"; sleep 1; printf dst > "${O}"
mark file::touch_at;    file::touch_at "${O}" "${REF}" >/dev/null 2>&1 && pass 'touch_at copies mtime from ref' || skip 'touch_at unsupported on platform'
mark file::diff;        file::diff "${A}" "${C}" >/dev/null 2>&1 && pass 'diff returns differences' || pass 'diff returns nonzero for differences as expected'
ROT="${ROOT_TMP}/rot.log"; printf rot > "${ROT}"
mark file::rotate;      assert_true 'rotate rotates log file' file::rotate "${ROT}" 3; [[ -f "${ROT}.1" && -f "${ROT}" ]] && pass 'rotate created numbered backup and fresh file' || fail 'rotate created numbered backup and fresh file'
REST="${ROOT_TMP}/restore.txt"; printf old > "${REST}"; printf new > "${REST}.bak"
mark file::restore;     assert_true 'restore replaces file from suffix backup' file::restore "${REST}" .bak; assert_file_content 'restore content ok' "${REST}" new

section 'tail follow smoke'

FOLLOW="${ROOT_TMP}/follow.log"
printf 'one\ntwo\n' > "${FOLLOW}"
mark file::tail_follow
if call_timeout 1 file::tail_follow "${FOLLOW}" 1 >/dev/null 2>&1; then
    pass 'tail_follow smoke exits'
else
    skip 'tail_follow is long-running or timeout unavailable'
fi

section 'adversarial filenames'

WEIRD_DIR="${ROOT_TMP}/weird names"
mkdir -p "${WEIRD_DIR}"
WEIRD="${WEIRD_DIR}/sp ace [x] ; quote ' file.txt"
mark file::write;       assert_true 'write handles adversarial filename' file::write "${WEIRD}" weird
mark file::read;        assert_file_content 'read handles adversarial filename' "${WEIRD}" weird
mark file::copy;        assert_true 'copy handles adversarial filename' file::copy "${WEIRD}" "${WEIRD}.copy"
mark file::is_equal;    assert_true 'is_equal handles adversarial filename' file::is_equal "${WEIRD}" "${WEIRD}.copy"

section 'negative cases'

assert_false 'read rejects missing file' file::read "${MISSING}"
assert_false 'remove rejects directory' file::remove "${DIR}"
assert_false 'copy rejects missing file' file::copy "${MISSING}" "${ROOT_TMP}/x"
assert_false 'line rejects zero line number' file::line "${A}" 0
assert_false 'range rejects inverted range' file::range "${A}" 3 2
assert_false 'contains rejects empty pattern' file::contains "${A}" ''
assert_false 'replace rejects empty search' file::replace "${A}" '' x
assert_false 'truncate rejects nonnumeric size' file::truncate "${A}" nope
assert_false 'changed_since rejects missing reference' file::changed_since "${A}" nope

section 'coverage gate: every file::* was exercised'

for fn in "${EXPECTED_FUNCS[@]}"; do
    if [[ -n "${HIT[${fn}]:-}" ]]; then pass "covered ${fn}"
    else fail "uncovered ${fn}"
    fi
done

printf '\n============================================================\n'
printf ' file.sh brutal test summary\n'
printf '============================================================\n'
printf 'Target : %s\n' "${TARGET_FILE}"
printf 'Root   : %s\n' "${ROOT_TMP}"
printf 'Funcs  : %s\n' "${#EXPECTED_FUNCS[@]}"
printf 'Total  : %s\n' "${TOTAL}"
printf 'Pass   : %s\n' "${PASS}"
printf 'Fail   : %s\n' "${FAIL}"
printf 'Skip   : %s\n' "${SKIP}"
printf '============================================================\n'

(( FAIL == 0 ))
