#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
image="${CILIUM_PMTU_IMAGE:-harbor.mgmt.infra.graphops.xyz/infra/cilium:v1.20.2-pmtu}"
engine="${CONTAINER_ENGINE:-podman}"
make GIT_VERSION images/cilium/Dockerfile.dockerignore
"$engine" build --layers --memory=32g --cpu-period=100000 --cpu-quota=1200000 \
  --platform=linux/amd64 --target=release \
  --build-arg BUILDPLATFORM=linux/amd64 \
  --build-arg TARGETOS=linux --build-arg TARGETARCH=amd64 \
  --build-arg 'MODIFIERS=V=0 EXTRA_GO_BUILD_FLAGS=-p=8' \
  --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
  --label 'org.opencontainers.image.version=v1.20.2-pmtu' \
  --label 'io.graphops.cilium.base=v1.20.2' \
  --label 'io.graphops.cilium.pmtu-pr=46993' \
  -f images/cilium/Dockerfile -t "$image" .
