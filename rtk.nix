{ pkgs, src }:
let
  cargoToml = pkgs.lib.trivial.importTOML "${src}/Cargo.toml";
in
pkgs.rustPlatform.buildRustPackage {
  pname = "rtk";
  inherit (cargoToml.package) version;

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = with pkgs; [
    pkg-config
    git
  ];

  buildInputs = with pkgs; [
    sqlite
  ];

  RUSQLITE_USE_PKG_CONFIG = "1";

  # rtk >= 0.51 tests run its hook scripts (hooks/claude/rtk-rewrite.sh),
  # which need jq; without it the hook prints a warning and no JSON.
  nativeCheckInputs = with pkgs; [
    jq
  ];

  # rtk 0.51 tests that need a path the Linux build sandbox lacks: the first
  # three spawn /usr/bin/printf or /bin/echo (tests/run_shell_test.rs), the
  # last writes a `#!/usr/bin/env bash` shim (tests/signal_flush_test.rs).
  # The sandbox has /bin/sh only, so they fail there; darwin builds
  # unsandboxed and runs all four.
  checkFlags = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    "--skip=unix::positional_arguments_are_not_interpreted_by_a_shell"
    "--skip=unix::summary_arguments_are_not_interpreted_by_a_shell"
    "--skip=unix::a_passthrough_keeps_its_own_shell_flag"
    "--skip=signalled_run_still_prints_captured_output"
  ];

  preCheck = builtins.readFile ./nix/fragments/rtk-pre-check.sh;

  meta = with pkgs.lib; {
    description = "CLI proxy that reduces LLM token consumption by 60-90%";
    homepage = "https://github.com/rtk-ai/rtk";
    license = licenses.mit;
    mainProgram = "rtk";
  };
}
