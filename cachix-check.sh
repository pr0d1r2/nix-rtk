#!/usr/bin/env bash
set -euo pipefail

CACHE="${1:-pr0d1r2}"
if [ -n "${2:-}" ]; then
  FLAKE="$2"
elif remote_url=$(git remote get-url origin 2>/dev/null); then
  repo=$(echo "$remote_url" | sed -E 's|.*github\.com[:/](.+)(\.git)?$|\1|' | sed 's/\.git$//')
  FLAKE="github:${repo}"
else
  FLAKE="."
fi
SYSTEMS=("aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux")

cache_url="https://${CACHE}.cachix.org"

for system in "${SYSTEMS[@]}"; do
  attr="packages.${system}.default"
  store_path=$(nix eval "${FLAKE}#${attr}.outPath" --raw 2>/dev/null) || continue
  hash=$(basename "$store_path" | cut -d- -f1)
  name=$(basename "$store_path" | cut -d- -f2-)

  response=$(curl -sf "${cache_url}/${hash}.narinfo" 2>/dev/null) || {
    printf "%-18s %-25s %s\n" "$system" "$name" "not cached"
    continue
  }

  size=$(echo "$response" | grep "^FileSize:" | awk '{printf "%.1fMB", $2/1024/1024}')
  printf "%-18s %-25s %s\n" "$system" "$name" "cached (${size})"
done
