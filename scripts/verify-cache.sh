#!/usr/bin/env bash
# Ask the binary cache whether every tier-1 rtk path is there.
#
# Evaluation is cross-system, so one machine resolves every output path
# without building any of them. Exits 1 if any tier-1 path is missing, which
# is the gate before promoting a commit to the `cached` branch.
#
#   scripts/verify-cache.sh                                 # this checkout
#   scripts/verify-cache.sh github:pr0d1r2/nix-rtk/cached   # what consumers get
set -euo pipefail

FLAKE="${1:-.}"
CACHE="${CACHE:-pr0d1r2}"
SYSTEMS="${SYSTEMS:-aarch64-darwin x86_64-linux aarch64-linux}"

rc=0
for system in $SYSTEMS; do
  path="$(nix eval --raw "${FLAKE}#packages.${system}.default.outPath")"
  hash="$(basename "$path" | cut -d- -f1)"
  code="$(curl -s -o /dev/null -w '%{http_code}' "https://${CACHE}.cachix.org/${hash}.narinfo")"
  printf '%-16s %s %s\n' "$system" "$(basename "$path")" "$code"
  [ "$code" = "200" ] || rc=1
done
exit "$rc"
