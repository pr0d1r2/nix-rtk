#!/usr/bin/env bash
# Run every lefthook gate (pre-commit + pre-push) over the whole tree, inside
# the dev flake's ci shell. Same invocation CI uses, so a local pass means a
# CI pass.
set -euo pipefail

cd "$(dirname "$0")/.."
export TERM=dumb
export HOME="${HOME:-${TMPDIR:-/tmp}/nix-rtk-home}"
export NIX_CONFIG="${NIX_CONFIG:-experimental-features = nix-command flakes}"
mkdir -p "$HOME"
nix develop --accept-flake-config ./dev#ci --ignore-environment --keep TERM \
  --keep HOME \
  --keep NIX_CONFIG \
  --command bash -c \
  'lefthook install && lefthook run pre-commit --all-files && lefthook run pre-push --all-files'
