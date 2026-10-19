# Reproducibility and Evidence Boundaries

**Fall 2025 · Personal Project**

This repository supports **patch verification, isolated kernel rebuilding, and reanalysis of selected experiment measurements**. It does **not** include a complete one-command reproduction environment for the historical B9E/B10R experiments.

## 1. Verify the Published Patch

Run from the repository root:

```bash
python3 scripts/verify_patch.py
```

The expected patch SHA-256 is:

```text
8f08fac195b909c8e3d0543e9d82de43714b2115fac962f1b59d59aa800fa094
```

The verifier checks patch bytes, the expected eight changed paths, recorded added/deleted line counts, and the published reconstruction report. **This is an integrity check**, not a compilation test or a runtime execution of the kernel.

## 2. Rebuild Against Linux 6.6.158

Obtain a **pristine, verified Linux 6.6.158 source tree** from [kernel.org](https://www.kernel.org/), and install the required kernel build dependencies (`make`, a suitable C toolchain, development libraries, GNU `patch`, and Python 3). Ensure enough disk space for both a source copy and build outputs.

```bash
bash scripts/rebuild_isolated.sh \
  /absolute/path/to/pristine/linux-6.6.158 \
  /absolute/path/to/new-output-directory \
  /absolute/path/to/kernel.config
```

The third argument is optional. The script checks the Linux version, verifies the patch, copies the original source to a **new** output directory, applies the patch with zero fuzz, verifies the eight recovered file hashes, and invokes `make ... bzImage`. It neither modifies the pristine source nor boots a virtual machine.

Without a supplied configuration, the script uses `defconfig`; this is **not** the historical B9E configuration. A successful compile does not establish historical binary identity or runtime correctness.

## 3. Existing Source and Build Evidence

The isolated patch rebuild previously completed successfully, producing an x86-64 `bzImage`. The recovered eight files matched the captured development source and were reproduced byte-exactly after patch application. See [VALIDATION.md](VALIDATION.md) and `evidence/source-reconstruction.json` for scope and hashes.

The isolated rebuilt image has SHA-256 `ff4e3ef2d308970f65ec64ea7c966170fca1bccbe06ef13c1f99806197c911b6`. The historical B9E kernel image has SHA-256 `ea1deeaaeb01e03ae23db07ee097ad1ff909dc0c2985201a21afe5d28c766d9b`. **They are different.** The recorded audit found 22 configuration differences, including ISO9660 built-in versus module and GCC 13.3 versus 9.4; those differences are not proven to be the only causes. Complete historical source-tree identity is not established.

## 4. Published Measurement Data

| Study | Published evidence | Comparison scope |
|---|---|---|
| B9E | `evidence/experiments/b9e/cases.csv` (27 rows), `paired.csv` (9 groups), `result.json` | Three arms: pristine upstream, modified stock, modified SKIP; upstream and modified build configurations differed |
| B10R | `evidence/experiments/b10r/cases.csv` (360 rows), `paired.csv` (180 pairs), `meta.json` | SKIP disabled versus enabled on the same modified kernel; only the eligible payload cohort |

File checksums are recorded in `evidence/experiments/SHA256SUMS.json`. The measurements and aggregation definitions are described in [Experimental design](EXPERIMENTS.md) and [Results](RESULTS.md). The CSV files allow independent reading and reanalysis of the published rows. They are not evidence that the newly reconstructed and isolated-built image executed these experiments.

## 5. What Is Not Included

The public repository intentionally omits complete historical B9E/B10R launchers, guest VM disks, SSH/network tunnel setup, private credentials, and full raw tracing/log archives. Therefore, **the historical end-to-end experiments cannot be rerun from this public repository alone**.

B9E used a one-host, isolated-QEMU three-arm comparison with configuration differences across upstream and modified kernels. B10R used a two-host tunneled-VM arrangement, with NC=8192B excluded after earlier experiments identified an unfavorable/ineligible case. Both measured application-ACK completion behavior. Skipping non-critical data changes delivered byte counts: a latency reduction is **not** an equal-byte throughput improvement.

## 6. Historical Context

The project originated in **Fall 2025**. The publicly released Linux 6.6.158 patch was **reconstructed and validated in October 2026**. Neither an unchanged 2025 source archive nor binary equivalence with the historical experimental image is claimed.
