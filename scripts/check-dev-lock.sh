#!/usr/bin/env bash
# The dev shell must carry the same rtk store path the root flake publishes.
# dev/flake.lock holds its own copy of the root's inputs; when it lags, the dev
# shell (and CI lint) silently builds a stale rtk. Fix: scripts/update.sh.
set -euo pipefail

cd "$(dirname "$0")/.."
system="${1:-x86_64-linux}"

root="$(nix eval --raw ".#packages.${system}.default.outPath")"
dev="$(nix eval --raw "./dev#devShells.${system}.ci.nativeBuildInputs" \
  --apply 'xs: builtins.concatStringsSep "\n" (map toString xs)' | grep -- '-rtk-' || true)"

echo "root=$root"
echo "dev=$dev"
[ "$root" = "$dev" ] || {
  echo "dev/flake.lock is stale; run: (cd dev && nix flake update nix-rtk)" >&2
  exit 1
}
