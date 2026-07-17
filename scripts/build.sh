#!/usr/bin/env bash
# build.sh — derive the composed image from the pins in upstream.yaml.
# Reads iic_osic_tools.digest + vyges.cli_version, builds Dockerfile.compose.
# Usage: VERSION=iic2026.07-loom0.1.14 scripts/build.sh [--push]
set -euo pipefail
cd "$(dirname "$0")/.."

y() { grep -E "^\s*$1:" upstream.yaml | head -1 | sed -E 's/.*:\s*"?([^"#]+)"?.*/\1/' | xargs; }
UPSTREAM_IMAGE="$(y source)"
UPSTREAM_DIGEST="$(y digest)"
CLI_VERSION="$(y cli_version)"
VERSION="${VERSION:-dev}"
IMAGE="${IMAGE:-ghcr.io/vyges-tools/vyges-iic-osic-tools}"

case "$UPSTREAM_DIGEST" in
  sha256:TODO*) echo "ERROR: upstream.yaml iic_osic_tools.digest is still a TODO placeholder." >&2
                echo "       Pin it with: docker buildx imagetools inspect ${UPSTREAM_IMAGE}:<tag>" >&2
                exit 2 ;;
esac

echo ">> composing ${IMAGE}:${VERSION}"
echo "   base   = ${UPSTREAM_IMAGE}@${UPSTREAM_DIGEST}"
echo "   vyges  = CLI v${CLI_VERSION} + \`vyges install loom\`"

args=(build -f Dockerfile.compose
  --build-arg "UPSTREAM_IMAGE=${UPSTREAM_IMAGE}"
  --build-arg "UPSTREAM_DIGEST=${UPSTREAM_DIGEST}"
  --build-arg "VYGES_CLI_VERSION=${CLI_VERSION}"
  -t "${IMAGE}:${VERSION}" .)
[ "${1:-}" = "--push" ] && args+=(--push)

docker "${args[@]}"
