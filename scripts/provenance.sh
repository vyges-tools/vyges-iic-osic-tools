#!/usr/bin/env bash
# provenance.sh — emit manifest.json recording exactly what was composed.
# CI fills image_digest + build_date after push.
# Env: VERSION, UPSTREAM_IMAGE, UPSTREAM_DIGEST, CLI_VERSION (all required).
set -euo pipefail
: "${VERSION:?}"; : "${UPSTREAM_IMAGE:?}"; : "${UPSTREAM_DIGEST:?}"; : "${CLI_VERSION:?}"

cat <<JSON
{
  "schema": "vyges-iic-osic-tools-manifest/1.0",
  "version": "${VERSION}",
  "base": {
    "image": "${UPSTREAM_IMAGE}",
    "digest": "${UPSTREAM_DIGEST}",
    "license": "Apache-2.0 (recipe); bundled tools/PDKs keep their own terms"
  },
  "vyges": {
    "cli_version": "${CLI_VERSION}",
    "loom": "vyges install loom (foundation + engines)",
    "install_path": "~/.vyges/bin (on default PATH)",
    "loom_core_license": "Apache-2.0",
    "notes": "vyges CLI closed-source; per-foundry calibration/plugins separate terms"
  },
  "image_digest": "${IMAGE_DIGEST:-TBD-filled-by-CI}",
  "build_date": "${BUILD_DATE:-TBD-filled-by-CI}"
}
JSON
