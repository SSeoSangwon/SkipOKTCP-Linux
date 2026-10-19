# Experimental results (selected, original measurements)

These tables are **computed from the selected raw experiment CSV files**, not newly run benchmarks. The figures apply to the historical experiment kernels; **the reconstructed, isolated-build image was not runtime-tested here**.

## B9E — three-arm, original Linux upstream comparison

- 27 cases; 9 matched three-arm groups; 3 repeats per loss window.
- Same host, two diskless QEMU guests with a host-side controlled-loss proxy; not the two-host SSH-tunneled setup.
- Arms: upstream 6.6.158 stock, modified-kernel SKIP disabled, modified-kernel SKIP enabled.
- Payload: NC 1024 bytes and critical 4096 bytes. The upstream and modified kernel configurations differed.
- Values below are **medians**; paired gain is the median of individual pair percentages, not the percentage of medians.

| Loss window | 3-arm groups | Upstream median | Modified stock median | Modified SKIP median | Paired upstream→SKIP median gain |
|---:|---:|---:|---:|---:|---:|
| 0 ms | 3 | 0.409 ms | 0.555 ms | 0.494 ms | -22.016% |
| 200 ms | 3 | 205.472 ms | 205.075 ms | 205.422 ms | 0.007% |
| 650 ms | 3 | 1478.343 ms | 1477.358 ms | 205.519 ms | 86.096% |

**Interpretation:** Cross-kernel improvements cannot be attributed only to SKIP because the configurations differ. Within the modified kernel, stock-vs-SKIP comparisons are more controlled, but delivered NC bytes differ. See [`b9e/cases.csv`](../evidence/experiments/b9e/cases.csv) and [`b9e/paired.csv`](../evidence/experiments/b9e/paired.csv).

## B10R — eligible payload sensitivity

- 360 cases / 180 matched pairs, with 5 repeats for each 3 NC sizes × 3 critical sizes × 4 loss windows.
- NC payload: 512 / 1024 / 4096 bytes; critical payload: 1037 / 4096 / 8192 bytes.
- The comparison is **SKIP disabled vs enabled on the same modified kernel**, not against untouched Linux.
- Two-host SSH-tunneled QEMU Ethernet with controlled NC-only loss and integrity checks; not direct physical-Ethernet benchmarking.
- Paired gain = (stock completion time − SKIP completion time) / stock completion time × 100. Positive means faster completion under the measured application-ACK criterion.

| Loss window | Matched pairs | Median paired gain | SKIP wins | SKIP losses |
|---:|---:|---:|---:|---:|
| 0 ms | 45 | -0.306% | 20 | 25 |
| 120 ms | 45 | 0.986% | 29 | 16 |
| 200 ms | 45 | 61.772% | 45 | 0 |
| 650 ms | 45 | 83.263% | 45 | 0 |

**Limits:** B10R deliberately excluded NC=8192B after the preceding B10 evaluation encountered a pre-RTO suffix-emission failure and degraded/negative gains. This is an eligibility-restricted cohort, **not** proof of 8192B robustness. Skipping NC bytes changes application-visible delivered bytes: latency improvement is not equivalent to equal-byte throughput gain. See [`b10r/cases.csv`](../evidence/experiments/b10r/cases.csv) and [`b10r/paired.csv`](../evidence/experiments/b10r/paired.csv).

## Source and binary provenance

The recovered eight-file Linux 6.6.158 patch replays byte-exactly and compiles successfully. The isolated rebuilt image is **not** byte-identical to the B9E experimental image; full historical source-tree identity is unverified. Refer to [Validation](VALIDATION.md) and the sanitized provenance summaries in [`evidence/`](../evidence/).
