#!/usr/bin/env python3
"""Offline integrity verification of the recovered eight-file Linux patch."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATCH = ROOT / "patches" / "skipoktcp-linux-6.6.158.patch"
REPORT = ROOT / "evidence" / "source-reconstruction.json"
EXPECTED = "8f08fac195b909c8e3d0543e9d82de43714b2115fac962f1b59d59aa800fa094"


def main():
    patch = PATCH.read_bytes()
    observed = hashlib.sha256(patch).hexdigest()
    audit = json.loads(REPORT.read_text(encoding="utf-8"))
    paths = [line[6:].decode("ascii") for line in patch.splitlines() if line.startswith(b"--- a/")]
    expected_paths = set(audit["changed_files"])
    if observed != EXPECTED or observed != audit["patch_sha256"]:
        raise SystemExit("PATCH_INTEGRITY=FAIL sha256 mismatch")
    if len(paths) != 8 or set(paths) != expected_paths or len(set(paths)) != 8:
        raise SystemExit("PATCH_INTEGRITY=FAIL unexpected modified file list")
    add = sum(l.startswith(b"+") and not l.startswith(b"+++") for l in patch.splitlines())
    delete = sum(l.startswith(b"-") and not l.startswith(b"---") for l in patch.splitlines())
    if (add, delete) != (637, 3) or not audit["patch_reapplied_byte_exact"]:
        raise SystemExit("PATCH_INTEGRITY=FAIL unexpected diff statistics or audit")
    print(f"PATCH_INTEGRITY=PASS sha256={observed} files=8 additions={add} deletions={delete}")


if __name__ == "__main__":
    main()
