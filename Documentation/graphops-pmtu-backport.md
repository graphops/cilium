# GraphOps Cilium 1.20.2 PMTU backport

Branch: `graphops/v1.20.2-pmtu`, based on upstream `v1.20.2`
(`e0dc92bd6dac33d7ba3b5eace82a0448bbb13aac`).

Upstream contribution: https://github.com/cilium/cilium/pull/46993,
pinned at `e7dedbba8aba765a4af8e640b349e8a357767580`.
The three upstream commits retain their authors and cherry-pick provenance.
This is an independently maintained backport of an unmerged upstream proposal.

## Compatibility adjustments

- Preserve the 1.20.2 maximum-complexity compiler flags and include layout.
- Use 1.20.2's output-pointer ICMP checksum-diff helper and IPv6 NAT signature.
- Read UDP checksums using the existing packet-byte helper.
- Regenerate map BTF from the 1.20.2 datapath with the new rate-limit key member.
- Include the test checksum declarations, select Maglev before node configuration
  is initialized, and align packet-generator stack structures for the verifier.

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

Stock Cilium 1.20.2 with the accepted DSR configuration is the recovery image.
GraphOps operational evidence, image digest, controlled PMTU proof and rollout
records are maintained in production-infra/network-resilience-rollout.
