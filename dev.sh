# shellcheck shell=bash
export NIX_CONFIG="experimental-features = nix-command flakes"
[ -f .git/hooks/pre-commit ] || lefthook install
