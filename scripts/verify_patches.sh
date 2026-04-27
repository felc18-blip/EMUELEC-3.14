#!/bin/bash
# verify_patches.sh — audit packages tree for patch/version hygiene
#
# Reports:
#   1. patches > 500 lines (candidates for splitting)
#   2. PKG_VERSION using git hashes (not pinned to release tags)
#   3. PKG_GIT_CLONE_BRANCH set without a fixed tag (drift risk)
#   4. .bak / .disabled / .orig / .old files in packages tree (cleanup)
#
# Usage: scripts/verify_patches.sh [--max-lines N]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAX_LINES=500

while [ $# -gt 0 ]; do
  case "$1" in
    --max-lines) MAX_LINES="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

cd "$ROOT"

echo "==> Large patches (>${MAX_LINES} lines)"
find packages -type f -name "*.patch" -exec wc -l {} + 2>/dev/null \
  | awk -v m="$MAX_LINES" '$1 > m && $2 != "total" {printf "  %6d  %s\n", $1, $2}' \
  | sort -rn

echo
echo "==> PKG_VERSION pinned to git hash (no semantic tag)"
grep -rE '^PKG_VERSION="[a-f0-9]{7,40}"' packages --include="package.mk" -l 2>/dev/null \
  | sed 's|^|  |' | sort | head -40
hash_count=$(grep -rE '^PKG_VERSION="[a-f0-9]{7,40}"' packages --include="package.mk" -l 2>/dev/null | wc -l)
echo "  ... total: $hash_count packages"

echo
echo "==> PKG_GIT_CLONE_BRANCH set (drift risk if upstream rebases)"
grep -rE '^PKG_GIT_CLONE_BRANCH=' packages --include="package.mk" 2>/dev/null \
  | sed 's|^|  |'

echo
echo "==> Stale files in packages tree (.bak / .disabled / .orig / .old)"
stale=$(find packages -type f \( -name "*.bak" -o -name "*.disabled" -o -name "*.orig" -o -name "*.old" \) 2>/dev/null)
stale_dirs=$(find packages -type d \( -name "*.bak" -o -name "*.classic*" -o -name "*.disabled" -o -name "*.orig" \) 2>/dev/null)
if [ -z "$stale" ] && [ -z "$stale_dirs" ]; then
  echo "  (none — clean)"
else
  [ -n "$stale" ]      && echo "$stale"      | sed 's|^|  FILE: |'
  [ -n "$stale_dirs" ] && echo "$stale_dirs" | sed 's|^|  DIR:  |'
fi

echo
echo "==> Done. Inspect above and act case-by-case."
