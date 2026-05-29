# shellcheck shell=bash
# preCheck hook for the rtk rustPlatform.buildRustPackage in
# rtk.nix. Gives the rtk test suite a writable HOME + a
# disposable sqlite db path so its integration tests don't spray
# into the build sandbox's default locations.

HOME="$(mktemp -d)"
export HOME
export RTK_DB_PATH="$HOME/rtk-test.db"
