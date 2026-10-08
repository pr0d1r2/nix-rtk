#!/usr/bin/env bash
# The daily update, in one place, for whatever drives it (the loop, or a human):
#
#   1. follow nixpkgs-lock
#   2. bump rtk-src to the latest stable upstream tag
#   3. relock dev/ against the new root
#
# Step 3 is not optional. dev/flake.lock carries its own copy of the root
# flake's inputs, so without it the dev shell builds a second, stale rtk.
#
# Leaves changes in the working tree; prints CHANGED=true when flake.lock or
# dev/flake.lock moved, so the caller knows whether to open a PR.
set -euo pipefail

cd "$(dirname "$0")/.."

nix flake update nixpkgs-lock
scripts/bump-rtk.sh --no-build
(cd dev && nix flake update nix-rtk)

if git diff --quiet -- flake.nix flake.lock dev/flake.lock; then
  echo "CHANGED=false"
else
  echo "CHANGED=true"
fi
