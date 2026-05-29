# SPEC — nix-rtk

## §G GOAL

Standalone Nix package for [RTK](https://github.com/rtk-ai/rtk) (Rust Token Killer) — CLI proxy reducing LLM token consumption 60-90%. Builds from upstream source w/ `rustPlatform.buildRustPackage`. Pre-built binaries via cachix (`pr0d1r2.cachix.org`). Consumed as flake input by downstream repos (hallucinogen, nix-dev-shell-agentic, etc.).

## §C CONSTRAINTS

- C1: Nix flake, pinned `nixos-25.11`
- C2: 4 systems: aarch64-darwin, x86_64-darwin, x86_64-linux, aarch64-linux
- C3: RTK source pinned as `flake = false` input — version from upstream `Cargo.toml`
- C4: Rust build via `rustPlatform.buildRustPackage` — needs pkg-config, git, sqlite
- C5: `RUSQLITE_USE_PKG_CONFIG = "1"` — link sqlite via pkg-config ⊥ vendored
- C6: preCheck hook gives writable HOME + disposable sqlite db path for test suite
- C7: cachix binary cache in `nixConfig` — consumers get pre-built binaries w/o compile
- C8: 7 nix-lefthook inputs w/ full follows deduplication
- C9: nix-dev-shell-agentic as non-flake stub — breaks circular dep chain
- C10: ⊥ embedded shell in nix — extract to fragments/
- C11: lefthook remotes for pre-commit quality gates

## §I INTERFACES

- I.pkg: `packages.<system>.default` — RTK binary
- I.dev: `devShells.<system>.default` — dev environment w/ RTK + linters + lefthook
- I.flake-input: `inputs.nix-rtk.url = "github:pr0d1r2/nix-rtk"` w/ `nixpkgs.follows`
- I.run: `nix run github:pr0d1r2/nix-rtk` — direct execution
- I.cache-check: `bash cachix-check.sh` — verify binary cache status per system

## §V VERSIONING

- RTK version: derived from `Cargo.toml` in pinned source (currently 0.42.0)
- Bump: update `rtk-src` input URL tag, `nix flake update rtk-src`
- Cachix: push after build on each supported system

## §T TESTING

- T1: `nix flake check` — evaluates package + devShell for all systems
- T2: RTK test suite runs during build (preCheck sets HOME + RTK_DB_PATH)
- T3: `cachix-check.sh` — verify cache population per system
- T4: lefthook pre-commit: nixfmt, statix, deadnix, typos, yamllint, editorconfig, trailing whitespace, missing newline, conflict markers, no local paths, no embedded shell, flake check

## §B BUILD

- B1: `nix build` — builds RTK for current system (pulls from cachix if cached)
- B2: `nix develop` — enters dev shell w/ RTK + all tooling
- B3: cachix push: `nix build && cachix push pr0d1r2 result`
