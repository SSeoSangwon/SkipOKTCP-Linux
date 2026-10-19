# Validation record and boundaries

## Confirmed source-level evidence

- Recovered eight known modified files from the development VM (SSH 2230) with a source-reconstruction report.
- Constructed a patch from pristine Linux 6.6.158 to these eight files. Reapplication produced byte-identical recovered file contents.
- Current development guest source matched the eight recovered files (8/8) in the subsequent read-only provenance check.
- The isolated patch-based build completed `make ... bzImage` successfully.

## Build records

| Item | SHA-256 / result |
|---|---|
| 8-file patch | `8f08fac195b909c8e3d0543e9d82de43714b2115fac962f1b59d59aa800fa094` |
| Isolated rebuilt `bzImage` | `ff4e3ef2d308970f65ec64ea7c966170fca1bccbe06ef13c1f99806197c911b6` |
| B9E modified kernel image (local and seedfix guest) | `ea1deeaaeb01e03ae23db07ee097ad1ff909dc0c2985201a21afe5d28c766d9b` |
| B9E image vs isolated rebuild | Different (byte identity: NO) |
| Rebuilt effective `.config` | `c616153e345fd39f9e75bd62dd1eb6d0c00173a83f40c3b870814fa89b7179d8` |

Read-only provenance audit: `AUDIT_PASS`; seedfix `CONFIG_ISO9660_FS=y`, rebuilt `CONFIG_ISO9660_FS=m`; **22** config differences total; rebuilt GCC 9.4, seedfix GCC 13.3. The current development build vs seedfix `.config` differed at one recorded item. These differences can account for divergent binaries but are not shown to be the exclusive cause.

## What the evidence does not prove

1. It does **not** prove all Linux source files outside the known eight paths were unchanged in the historical B9E build.
2. It does **not** prove the eight captured files are byte-identical to their historical build-time state (only to the *current* development guest state at capture).
3. It does **not** prove the isolated rebuilt `bzImage` is equivalent or byte-identical to the B9E image.
4. It does **not** constitute runtime execution/testing of the isolated rebuilt image.
5. Performance observations from B9E/B10R are tied to those experiment setups and images; NC skipping can change total application data delivered. They must not be described as equal-byte throughput improvements.

## Release decision

This repository is suitable to review as a **reconstructed and compilable Linux 6.6.158 patch**. Do not label it as a bit-identical reproduction of the original experimental kernel. Additional experiments are optional and not prerequisites to honest publication of the recovered source patch.
