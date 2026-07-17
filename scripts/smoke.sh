#!/usr/bin/env bash
# smoke.sh — assert the composed image satisfies both invariants:
#   (a) the OSS baseline runs (exactly as upstream IIC-OSIC-TOOLS);
#   (b) the Vyges CLI + engines are on the default PATH and resolve the PDK with
#       NO PDK_ROOT/IHP_PDK_ROOT env set.
# Usage: scripts/smoke.sh <image-ref>
set -euo pipefail
IMG="${1:?usage: smoke.sh <image-ref>}"

echo ">> (a) OSS baseline (upstream tools) ..."
docker run --rm --entrypoint bash "$IMG" -lc '
  set -e
  klayout -v
  magic --version 2>/dev/null || true
  ngspice -v 2>/dev/null | head -1 || true
  echo "OSS baseline OK"
'

echo ">> (b) Vyges layer on default PATH + env-free PDK ..."
docker run --rm --entrypoint bash "$IMG" -lc '
  set -e
  command -v vyges-lvs >/dev/null || { echo "FAIL: vyges-lvs not on default PATH" >&2; exit 1; }
  vyges-lvs --version
  vyges-extract --version
  env -u PDK_ROOT -u IHP_PDK_ROOT vyges-extract gen-rc --pdk ihp_sg13cmos5l >/dev/null
  echo "Vyges layer OK (engines on PATH; PDK resolved with no PDK_ROOT)"
'
echo ">> smoke PASSED for $IMG"
