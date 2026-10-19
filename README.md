# SkipOKTCP-Linux

**Fall 2025 · Personal Project**

## Overview

SkipOKTCP-Linux is an experimental importance-aware TCP implementation for Linux 6.6.158. It distinguishes critical and non-critical application data and uses an explicitly negotiated SKIP control option to advance the receive sequence over eligible non-critical ranges, while preserving ordinary TCP recovery for critical data.

This is a nonstandard Linux kernel extension for controlled research environments. The project originated in Fall 2025; the publicly available implementation was reconstructed and validated in October 2026 after the earlier project sources became unavailable. Historical source-code or binary identity is **not** claimed.

## Environment / Technologies

- Language: C
- Base kernel: Linux 6.6.158
- Implementation: Linux TCP socket options, transmit/receive paths, SKB metadata, and retransmission timers
- Build: Linux kernel Kbuild (`make bzImage`)
- Validation: source SHA-256, zero-fuzz patch replay, and isolated x86-64 kernel build

## Main Implementation

The patch modifies eight upstream Linux source files:

```text
include/uapi/linux/tcp.h
include/linux/tcp.h
include/net/tcp.h
net/ipv4/tcp.c
net/ipv4/tcp_input.c
net/ipv4/tcp_output.c
net/ipv4/tcp_timer.c
net/ipv4/tcp_minisocks.c
```

The implementation includes:

- Per-socket importance selection (disabled / critical / non-critical) and transmit-SKB metadata propagation
- Boundaries that prevent selected cross-importance merge or retransmission-queue operations
- Opt-in SYN/SYN-ACK capability negotiation and experimental SKIP TCP options
- Guarded receiver-side sequence advancement over eligible non-critical ranges
- Bounded RTO-triggered SKIP, duplicate control handling, and retransmission timer accounting
- RTT-sampling protection for ACKs of intentionally skipped bytes (P2L)
- Optional leading non-critical-prefix SKIP without bypassing recovery of subsequent critical data (P2M)

The extension uses private, experimental TCP socket-option values and is **not** compatible with stock Linux peers for SKIP operation.

## Technical Documentation

- [Implementation Details](docs/IMPLEMENTATION.md)
- [Reproducibility](docs/REPRODUCIBILITY.md)

## Tests / Validation

The available source and build evidence supports the following results:

| Check | Result |
|---|---|
| Reconstruct the eight known modified source files | PASS |
| Reapply patch against pristine Linux 6.6.158 with byte-exact output | PASS |
| Match the current development VM source to the recovered eight files | 8/8 PASS |
| Build an isolated x86-64 `bzImage` from the recovered patch | PASS |
| Match the local and seedfix-guest B9E kernel image hashes | PASS |
| Reproduce the B9E image byte-for-byte from the isolated build | **Not established** |

The eight-file patch contains **637 added and 3 removed lines**. Source changes outside these eight paths in the historical experimental build have not been excluded. See [Validation record](docs/VALIDATION.md) for hashes, build-environment differences, and the scope of each claim.

Run the patch integrity check from the repository root:

```bash
python3 scripts/verify_patch.py
```

## Evaluation

The associated research project ran controlled Linux guest experiments, including B9E comparisons and B10R payload-sensitivity checks. Those measurements belong to the historical experimental kernels and their specific environments; they are **not** runtime measurements of the isolated rebuilt binary published here. Skipping non-critical bytes can also change the amount of application data delivered, so latency observations should not be described as equal-byte throughput improvements.

See [Experimental design](docs/EXPERIMENTS.md) and [measured results](docs/RESULTS.md) for the curated B9E/B10R raw CSV evidence.

## Build and Reproduction

Obtain a verified pristine Linux 6.6.158 source tree from [kernel.org](https://www.kernel.org/). The script copies it into a new output directory, applies the patch without fuzz, verifies the known source hashes, and builds an x86-64 `bzImage`. It does not modify the upstream directory or launch a VM.

```bash
bash scripts/rebuild_isolated.sh \
  /absolute/path/to/pristine/linux-6.6.158 \
  /absolute/path/to/new/output-dir \
  /absolute/path/to/kernel.config
```

The kernel configuration argument is optional; without it the script uses `make defconfig`. This is **not** the historical B9E configuration. A successful build demonstrates compilation, not historical binary equivalence or runtime correctness of the rebuilt binary.

## Repository Contents

- `patches/skipoktcp-linux-6.6.158.patch` — recovered Linux 6.6.158 source patch
- `scripts/verify_patch.py` — patch integrity verification
- `scripts/rebuild_isolated.sh` — isolated source-copy, patch, and build workflow
- `docs/VALIDATION.md` — validation evidence and limitations
- `evidence/` — sanitized source-reconstruction and build-provenance summaries

## Project Context

The project dates to **Fall 2025**. The source in this repository was reconstructed and validated in **October 2026**; it is not presented as an unchanged archive of the missing 2025 code or as a byte-identical reproduction of the B9E experimental kernel.

This Linux implementation is maintained separately from the [SkipOKTCP ns-3 project](https://github.com/SSeoSangwon/SkipOKTCP), which uses ns-3.47 rather than modifying a Linux kernel.

## License

The patch is distributed under the GNU General Public License version 2. See `COPYING` and the copyright/license notices in the upstream Linux source. This experimental extension is not intended for production deployment without independent compatibility and security review.
