#!/usr/bin/env bash
# which.sh — resolve 'latest' / a release tag / an upstream-digest or loom-version
# fragment to a pullable image ref from index.json.
# Usage: scripts/which.sh <latest|version|digest-frag|loom-version>
set -euo pipefail
Q="${1:?usage: which.sh <latest|version|digest-frag|loom-version>}"
IDX="${IDX:-index.json}"
[ -f "$IDX" ] || { echo "no index.json" >&2; exit 1; }

case "$Q" in
  latest) sel='[.builds[]|select(.channel=="release")][0]' ;;
  *)      sel="[.builds[]|select(.version==\"$Q\" or (.upstream_digest|startswith(\"$Q\")) or (.short==\"$Q\") or (.loom_version==\"$Q\"))][0]" ;;
esac

row=$(jq -c "$sel" "$IDX")
[ "$row" != "null" ] || { echo "no build matches '$Q'" >&2; exit 1; }
echo "$row" | jq -r '"image:    \(.image_ref)\ndigest:   \(.image_digest)\nupstream: \(.upstream_digest)\nloom:     \(.loom_version)"'
