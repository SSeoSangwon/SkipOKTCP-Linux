#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH="$ROOT/patches/skipoktcp-linux-6.6.158.patch"

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 /absolute/pristine/linux-6.6.158 /absolute/NEW-output-dir [kernel.config]" >&2
  exit 2
fi

SOURCE="$(realpath -e -- "$1")"
OUT="$2"
CONFIG="${3:-}"

if [[ "$OUT" != /* ]]; then
  echo "ERROR: output path must be absolute" >&2
  exit 2
fi
if [[ -e "$OUT" || -L "$OUT" ]]; then
  echo "ERROR: output already exists (will not overwrite): $OUT" >&2
  exit 2
fi
# Never let the copied Linux tree recurse into itself (including through symlinked parents).
OUT_CANON="$(realpath -m -- "$OUT")"
case "$OUT_CANON/" in
  "$SOURCE/"*)
    echo "ERROR: output directory must be outside the pristine source tree" >&2
    exit 2
    ;;
esac
if [[ -n "$CONFIG" ]]; then
  CONFIG="$(realpath -e -- "$CONFIG")"
  [[ -f "$CONFIG" ]] || { echo "ERROR: config is not a regular file" >&2; exit 2; }
fi
if [[ ! -f "$SOURCE/Makefile" || ! -f "$SOURCE/net/ipv4/tcp_output.c" ]]; then
  echo "ERROR: kernel source tree not found" >&2
  exit 2
fi

python3 "$ROOT/scripts/verify_patch.py"

# Verify version from top-level kernel Makefile before copying.
python3 - "$SOURCE/Makefile" <<'PY_VERSION'
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace')
def v(name):
    match = re.search(r'^'+re.escape(name)+r'\s*=\s*(\d+)\s*$',text,re.M)
    if not match: raise SystemExit('ERROR: cannot read kernel version '+name)
    return int(match.group(1))
version = tuple(v(x) for x in ('VERSION','PATCHLEVEL','SUBLEVEL'))
if version != (6,6,158): raise SystemExit('ERROR: expected Linux 6.6.158; found '+str(version))
print('UPSTREAM_VERSION=PASS 6.6.158')
PY_VERSION

mkdir -p -- "$OUT"
DEST="$OUT/linux-6.6.158-skipok"
BUILD="$OUT/build"
echo "STAGE=copy_pristine_tree"
cp -a -- "$SOURCE" "$DEST"

echo "STAGE=apply_patch_to_isolated_copy"
patch --directory "$DEST" --batch --forward --fuzz=0 -p1 -i "$PATCH"

python3 - "$ROOT/evidence/source-reconstruction.json" "$DEST" <<'PY_HASH'
import hashlib, json, pathlib, sys
report=json.loads(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))
root=pathlib.Path(sys.argv[2])
for rel,expected in sorted(report['reconstructed_sha256'].items()):
    p=root/rel
    actual=hashlib.sha256(p.read_bytes()).hexdigest()
    if actual!=expected: raise SystemExit('RECOVERED_SOURCE_SHA256=FAIL '+rel)
print('RECOVERED_SOURCE_SHA256=PASS files=8')
PY_HASH

mkdir -p "$BUILD"
if [[ -n "$CONFIG" ]]; then
  cp -- "$CONFIG" "$BUILD/.config"
  echo "STAGE=olddefconfig"
  make -C "$DEST" O="$BUILD" olddefconfig
else
  echo "STAGE=defconfig (NOT historical B9E config)"
  make -C "$DEST" O="$BUILD" defconfig
fi

JOBS="${JOBS:-4}"
if ! [[ "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: JOBS must be a positive integer" >&2
  exit 2
fi

echo "STAGE=build_bzImage jobs=$JOBS"
make -C "$DEST" O="$BUILD" -j"$JOBS" bzImage
IMAGE="$BUILD/arch/x86/boot/bzImage"
[[ -s "$IMAGE" ]] || { echo "KERNEL_BUILD=FAIL no bzImage" >&2; exit 1; }
echo "KERNEL_BUILD=PASS"
sha256sum "$IMAGE"
echo "B9E_BYTE_IDENTITY=NOT_CLAIMED"
echo "OUTPUT=$OUT"
