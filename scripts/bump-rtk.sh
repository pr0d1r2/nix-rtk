#!/usr/bin/env bash
# Bump rtk-src to the latest stable upstream release.
#
# Upstream publishes dev-*-rc pre-releases daily; releases/latest skips those,
# so only stable tags are ever picked. Cargo deps come from the pinned
# Cargo.lock, so the bump is the URL edit plus a relock -- no hashes.
#
#   scripts/bump-rtk.sh             # bump if upstream is newer, then build
#   scripts/bump-rtk.sh --no-build  # bump only; let CI prove the build
#
# Prints NEW_VERSION=... on stdout when the version moved.
set -euo pipefail

cd "$(dirname "$0")/.."
build=true
[ "${1:-}" = "--no-build" ] && build=false

current="$(sed -n 's|^ *url = "github:rtk-ai/rtk/v\(.*\)";$|\1|p' flake.nix)"
[ -n "$current" ] || { echo "cannot read rtk-src version from flake.nix" >&2; exit 1; }

latest="$(gh api repos/rtk-ai/rtk/releases/latest --jq .tag_name)"
latest="${latest#v}"
[ -n "$latest" ] || { echo "cannot read latest release from upstream" >&2; exit 1; }

echo "current=$current latest=$latest" >&2
if [ "$current" = "$latest" ]; then
  echo "already current" >&2
  exit 0
fi

tmp="$(mktemp)"
sed "s|github:rtk-ai/rtk/v$current\"|github:rtk-ai/rtk/v$latest\"|" flake.nix >"$tmp"
mv "$tmp" flake.nix
nix flake update rtk-src

got="$(nix eval --raw .#default.version)"
[ "$got" = "$latest" ] || { echo "Cargo.toml says $got, tag says $latest" >&2; exit 1; }

if [ "$build" = true ]; then
  nix build --print-build-logs --no-link .#default
fi

echo "NEW_VERSION=$latest"
