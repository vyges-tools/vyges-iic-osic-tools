#!/usr/bin/env bash
# pdk-import.sh — make a PDK resolvable by the Vyges engines WITHOUT any
# PDK_ROOT / IHP_PDK_ROOT env var, by materializing it under the managed
# ~/.vyges/pdk-store and repointing the descriptor `root` at $HOME (always set).
#
# The engines expand env vars in the descriptor `root`; the default
# "$IHP_PDK_ROOT/<pdk>" fails when that var is unset. Rooting at
# "$HOME/.vyges/pdk-store/<pdk>" resolves for any user with no config.
#
# Usage:
#   scripts/pdk-import.sh <pdk-name> <source-pdk-dir> [--copy|--symlink]
# e.g.
#   scripts/pdk-import.sh ihp_sg13cmos5l /foss/pdks/ihp-sg13cmos5l --symlink   # container: no dup
#   scripts/pdk-import.sh ihp_sg13cmos5l ~/.ciel/ihp-sg13cmos5l   --copy      # local: self-contained
set -euo pipefail
NAME="${1:?pdk name, e.g. ihp_sg13cmos5l}"
SRC="${2:?source PDK dir}"
MODE="${3:---symlink}"

STORE="${HOME}/.vyges/pdk-store"
DESC="${STORE}/${NAME}.vyges-pdk.json"
# The leaf dir name embedded in the descriptor root (…/<name>/<leaf>); default = basename of SRC.
LEAF="$(basename "$SRC")"
DEST="${STORE}/${LEAF}"

[ -d "$SRC" ] || { echo "source PDK dir not found: $SRC" >&2; exit 1; }

mkdir -p "$STORE"
# Fetch the pdk-store descriptor from the published catalog if it isn't present yet
# (a fresh install won't have it). Build-time only; runtime stays offline.
if [ ! -f "$DESC" ]; then
  URL="${DESCRIPTOR_URL:-https://raw.githubusercontent.com/vyges-tools/pdk-catalog/main/descriptors/${NAME}.vyges-pdk.json}"
  echo "descriptor absent — fetching ${URL}"
  curl -fsSL "$URL" -o "$DESC" || { echo "could not fetch descriptor for '${NAME}'" >&2; exit 1; }
fi
case "$MODE" in
  --symlink) ln -sfn "$SRC" "$DEST"; echo "linked  $DEST -> $SRC" ;;
  --copy)    rm -rf "$DEST"; cp -a "$SRC" "$DEST"; echo "copied  $SRC -> $DEST" ;;
  *) echo "mode must be --copy or --symlink" >&2; exit 2 ;;
esac

# Repoint the descriptor root at $HOME (idempotent; keeps a .bak once).
[ -f "${DESC}.bak" ] || cp "$DESC" "${DESC}.bak"
python3 - "$DESC" "$LEAF" <<'PY'
import json, sys
path, leaf = sys.argv[1], sys.argv[2]
d = json.load(open(path))
d["root"] = f"$HOME/.vyges/pdk-store/{leaf}"
json.dump(d, open(path, "w"), indent=4)
print("root ->", d["root"])
PY
echo "done — '${NAME}' now resolves with no PDK_ROOT / IHP_PDK_ROOT set."
