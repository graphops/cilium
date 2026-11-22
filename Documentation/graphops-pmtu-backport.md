# GraphOps Cilium 1.20.5 PMTU backport

Branch: `graphops/v1.20.5-pmtu`, based on upstream `v1.20.5`
(`15012141`, "Prepare for release v1.20.5"). It carries the same four commits as
`graphops/v1.20.2-pmtu`, cherry-picked with `-x`. All four applied without conflicts.

Upstream contribution: https://github.com/cilium/cilium/pull/46993,
pinned at `e7dedbba8aba765a4af8e640b349e8a357767580`.
The three upstream commits retain their authors and cherry-pick provenance.
This is an independently maintained backport of an unmerged upstream proposal.

## Why 1.20.5

The two socket-LB termination fixes that matter on k-work:
- `#48564`: UDP termination no longer destroys unconnected sockets or changes
  their source port. Fixed in 1.20.3.
- `#49936`: a pod still in another Service keeps its sockets. That is CNPG's
  `-rw`/`-ro`/`-r` pattern. Fixed in 1.20.5.

## Compatibility adjustments (carried from the 1.20.2 backport)

- Preserve the 1.20 maximum-complexity compiler flags and include layout.
- Use 1.20's output-pointer ICMP checksum-diff helper and IPv6 NAT signature.
- Read UDP checksums using the existing packet-byte helper.
- Map BTF regenerated with the new rate-limit key member. `pkg/datapath/maps/mapkv.btf`
  is byte-identical between upstream v1.20.2 and v1.20.5, so the regenerated file
  still applies.
- Include the test checksum declarations, select Maglev before node configuration
  is initialized, and align packet-generator stack structures for the verifier.

Upstream changed `bpf/lib/lb.h` and `bpf/lib/nodeport.h` between 1.20.2 and 1.20.5,
and the relay also touches both. The merge was clean, but one call site broke.

- 1.20.5 changed `snat_v4_calc_icmp_error_csum_diff()` in `bpf/lib/nat.h` to return
  the `__wsum` diff instead of writing it through an output pointer.
- The IPv4 relay in `bpf/lib/pmtu.h` now takes the return value. The semantics are
  the same: the diff starts at zero and is computed the same way.
- Upstream's own callers also zero the diff for inner ICMP or SCTP. The relay only
  admits inner TCP and UDP, so it doesn't need that guard.

The eBPF unit suite passed on this branch (22 Nov 2026): 145 test objects and 712
scenarios, including `svc_icmp_pmtu_relay.o` and `svc_icmp_pmtu_relay6.o`, built
with the pinned 1.20.5 builder image.

## Build

Run `contrib/graphops/build-pmtu.sh`. It uses the release Dockerfile's pinned
builder, runtime and Envoy dependencies, targets linux/amd64 and embeds the source
commit in image labels. Override `CILIUM_PMTU_IMAGE` or `CONTAINER_ENGINE` if needed.
Push separately after tests pass. Deployment must pin the registry image digest.

## Runtime scope

The relay is opt-in via `pmtuDiscovery.enabled: true`, with native routing,
DSR forwarding and Maglev selection. It routes qualifying ICMP errors addressed
to a service VIP to the derived backend. It does not lower production MTUs.
The upstream exclusions for SNAT, non-Maglev forwarding, remote tunnel-dispatched
backends and Cilium's L7 proxy remain. Backend-set changes and node-local affinity
pins constrain stateless re-derivation; ordinary forwarding tests do not prove
PMTU correctness during all topology changes.

The running `v1.20.2-pmtu` image (pinned by digest) is the recovery image for this
rollout. GraphOps operational evidence, image digest, controlled PMTU proof and
rollout records are maintained in production-infra/network-resilience-rollout.
