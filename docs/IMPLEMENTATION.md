# Implementation Details

**Fall 2025 · Personal Project**

This document describes the **reconstructed Linux 6.6.158 implementation** published in this repository. The source was recovered and validated in October 2026; identity with the unavailable Fall 2025 source or the historical B9E build has **not** been established.

## Design and Data Importance

SkipOKTCP adds an experimental, opt-in, importance-aware mechanism to the Linux TCP implementation. An application selects one of three per-socket transmission states using `TCP_SKIPOK_IMPORTANCE`: **0** (off/default), **1** (critical), or **2** (non-critical). The selected value is attached to newly queued transmit `sk_buff` metadata. Selected coalescing, SACK shifting, fragmentation, and retransmission paths are modified to preserve or account for this distinction.

A negotiated SKIP control can acknowledge the deliberate omission of an **eligible** non-critical sequence range. It is not a standard TCP capability, is not intended for deployment with unmodified peers, and changes the data delivered to the application.

## Source Files and Responsibilities

| File | Implementation responsibility |
|---|---|
| `include/uapi/linux/tcp.h` | Private experimental socket option identifiers and diagnostic structures |
| `include/linux/tcp.h` | Per-socket flags, negotiated state, pending control state, counters, and range tracking |
| `include/net/tcp.h` | Transmit SKB importance bits and declaration of the RTO helper |
| `net/ipv4/tcp.c` | `setsockopt`/`getsockopt` handling, transmit tagging in `tcp_sendmsg_locked()` |
| `net/ipv4/tcp_input.c` | Option parsing, observational probe, receiver-side SKIP validation, RTT-sampling guard |
| `net/ipv4/tcp_output.c` | Capability and control option encoding, tag propagation, merge guards, RTO SKIP helper |
| `net/ipv4/tcp_timer.c` | Retransmission timeout integration and accounting for a control-only send |
| `net/ipv4/tcp_minisocks.c` | Established child socket's negotiated capability state |

The patch consists of changes to **eight known files** against pristine Linux 6.6.158. It is not an assertion that all other files in the historical experimental source tree were unchanged.

## Connection Negotiation (P2A)

A socket must explicitly enable SkipOKTCP before a connection is established. When enabled and there is room in the SYN options, the active endpoint includes a private experimental SKOK capability offer. The passive endpoint responds in SYN-ACK only when enabled, the SYN offered the capability, the required request state exists, and option space permits it. The implementation avoids declaring successful negotiation via the SYN-cookie path where that request metadata is unavailable.

Both sides record negotiation state before SKIP controls can be accepted. The experimental format uses TCP experimental option kind `TCPOPT_EXP` with the `SKOK` identifier and version/subtype fields. The capability offer, diagnostic probe, and actual SKIP command are distinct forms.

## Transmit Metadata (P1A–P1C)

`tcp_sendmsg_locked()` snapshots the socket's selected importance value when sending and tags new payload SKBs. It refuses a selected append when the existing SKB belongs to another importance class. Fragmentation/TSO paths propagate the tag, and selected retransmission-queue collapse and SACK shifting paths block cross-class operations. Diagnostic socket options report counts, rather than constituting protocol-level delivery guarantees.

## Probe versus SKIP (P2B–P2C)

`tcp_skipok_observe_probe()` inspects an eligible control-only TCP segment and increments a diagnostic counter for a valid observation. **A probe does not advance `rcv_nxt` and does not suppress retransmission.**

`tcp_skipok_apply_skip()` handles the receiver-advancing SKIP option after incoming-segment validity checks. It requires negotiated capability, an appropriate control-only ACK, a valid sequence interval, receive-window bounds, consistency with `rcv_nxt` and `copied_seq`, an empty receive queue, and an out-of-order boundary that does not overlap the proposed omitted range. On acceptance, it advances `rcv_nxt` and `copied_seq`, processes eligible out-of-order data, records the accepted interval, and sends a cumulative ACK. Duplicate controls are handled separately. These are **strict experimental eligibility guards**, not a proof of general-purpose partial reliability.

## RTO-based SKIP and Prefix Mode (P2D, P2M)

`tcp_skipok_try_rto_skip()` is an opt-in path invoked from the TCP retransmission timeout handler. It checks connection state, negotiated capability, socket options, outstanding ranges, retransmission-queue continuity, packet metadata, and control-space constraints. The normal mode requires the entire eligible outstanding interval to be non-critical. The optional `TCP_SKIPOK_PREFIX_RTO` mode permits only a contiguous **leading non-critical prefix**: it does not intentionally cross a later critical SKB. The emitted range is bounded to 16,384 sequence bytes.

If the SKIP control cannot be emitted, the helper returns to the ordinary retransmission path. The timer modification preserves retransmission episode accounting when a control-only SKIP takes the place of a normal data retransmission.

## RTT Guard (P2L)

An ACK that covers intentionally skipped bytes is not evidence of the original segment's delivery time. The `skipok_rtt_guard_armed` state guards the relevant ACK path against creating an ordinary RTT sample, including the timestamp-echo fallback. This avoids interpreting a synthetic sequence-space acknowledgment as measured network delivery latency.

## Reading Historical Comments

The published patch deliberately retains development-stage labels such as `P1A`, `P2A`, `P2B`, `P2C`, `P2D`, `P2L`, and `P2M`. Some original comments describe the state **when the corresponding phase was introduced**, not the final aggregate implementation. For example, the receiver-side P2C comment that says control retransmission is not available *yet* predates the later P2D additions. Such comments should not be read as an up-to-date feature inventory. The verified patch was not reformatted solely for presentation, because modifying it would invalidate its recorded byte-level provenance.

## Scope and Limitations

This is an experimental extension requiring SkipOKTCP-capable peers. Critical data protection is implemented through specific recorded guards, not through a formally verified end-to-end protocol proof. Omitting non-critical bytes also changes application-visible delivery. See [Validation](VALIDATION.md), [Experimental design](EXPERIMENTS.md), and [Results](RESULTS.md) for the exact evidence and caveats.
