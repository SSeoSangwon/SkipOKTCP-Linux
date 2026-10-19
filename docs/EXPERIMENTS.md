# Experimental design and interpretation

## B9E (pristine upstream reference)

27 individual tests, grouped into 9 matched three-arm sets (upstream stock, modified stock, modified SKIP), at 0/200/650 ms controlled loss (3 repeats). One host launches two independent diskless KVM/QEMU guests with a controlled-drop bridge. NC=1024B, Critical=4096B. The upstream and modified kernels **were not built with matching configurations**. The experimental timing is application-ACK completion time, not byte-identical payload throughput.

## B10R (modified-kernel ablation)

180 matched pairs, 360 executions. SKIP disabled and enabled on the same modified kernel; 3 eligible NC sizes × 3 critical sizes × 4 loss windows × 5 repeats. It checks critical-byte hashes, NC byte accounting, controlled ingress drop, out-of-order evidence, and integrity guards. QEMU Ethernet was tunneled over SSH/TCP between hosts; it was not a direct 1GbE test. NC=8192B was excluded because earlier B10 trials found an ineligible pre-RTO emission condition and weaker or negative gains.

## Evidence selection policy

Only one fully verified B9E run and one fully verified B10R run are published as sanitized CSVs and metadata, with SHA-256 hashes. Earlier smoke tests, intermediary patch bundles, guest serial logs, VM disks, SSH credentials, trace dumps, hostnames, and failed-retry logs stay outside GitHub. This is a curated reproducibility record, not a complete raw experimental archive. Selecting these studies does not make their setups identical.
