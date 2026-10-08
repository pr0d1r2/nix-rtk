# SPEC — nix-rtk

## §G GOAL

Standalone Nix package for [RTK](https://github.com/rtk-ai/rtk) (Rust Token Killer) — CLI proxy reducing LLM token consumption 60-90%. Builds from upstream source w/ `rustPlatform.buildRustPackage`. Pre-built binaries via cachix (`pr0d1r2.cachix.org`). Single source of rtk for fleet (hallucinogen, nix-dev-shell-agentic, nix-config, etc.) so all consumers substitute same store path ⊥ compile.

## §C CONSTRAINTS

- C1: Nix flake; nixpkgs follows `nixpkgs-lock/nixpkgs` (fleet pin, currently nixos-26.05)
- C2: 4 systems: aarch64-darwin, x86_64-darwin, x86_64-linux, aarch64-linux
- C3: RTK source pinned as `flake = false` input at stable tag — version from upstream `Cargo.toml`
- C4: Rust build via `rustPlatform.buildRustPackage` — needs pkg-config, git, sqlite; jq for tests
- C5: `RUSQLITE_USE_PKG_CONFIG = "1"` — link sqlite via pkg-config ⊥ vendored
- C6: preCheck hook gives writable HOME + disposable sqlite db path for test suite
- C7: cachix binary cache in `nixConfig`
- C8: root flake inputs = `nixpkgs-lock` + `rtk-src` only — every root input lands in every consumer lock
- C9: dev tooling (nix-lefthook, linters) in `dev/` subflake (`nix-rtk.url = "path:.."`) — ⊥ consumer-visible
- C10: ⊥ embedded shell in nix — extract to fragments/ or scripts/
- C11: lefthook remotes for quality gates
- C12: no scheduled workflows — external loop drives pin + upstream bumps

## §I INTERFACES

- I.pkg: `packages.<system>.{default,rtk}` — RTK binary
- I.overlay: `overlays.default` — `pkgs.rtk` = this flake's cached build, ⊥ rebuilt against consumer pkgs
- I.dev: `dev#devShells.<system>.{default,ci}` — RTK + linters + lefthook
- I.flake-input: `inputs.nix-rtk.url = "github:pr0d1r2/nix-rtk/cached"` ⊥ `nixpkgs.follows`
- I.run: `nix run github:pr0d1r2/nix-rtk/cached`
- I.cache: `scripts/verify-cache.sh [flake]` — exit 1 if any tier-1 path missing
- I.bump: `scripts/bump-rtk.sh [--no-build]` — latest stable upstream tag; prints `NEW_VERSION=`
- I.lint: `scripts/lint.sh` — all lefthook gates, same as CI
- I.update: `scripts/update.sh` — whole daily update; prints `CHANGED=`
- I.dev-lock: `scripts/check-dev-lock.sh [system]` — dev shell rtk == root rtk

## §V INVARIANTS

- V1: `cached` branch → only commits w/ every tier-1 path in cachix (verify-cache gates promote)
- V2: `cached` moves fast-forward only (promote push ⊥ force)
- V3: nixpkgs rev == nixpkgs-lock's published rev on every PR (assert-pins)
- V4: tier-1 = aarch64-darwin, x86_64-linux, aarch64-linux; native runners ⊥ qemu ⊥ cross
- V5: x86_64-darwin eval-only; breakage ⊥ block main
- V6: bump picks `releases/latest` only — ⊥ `dev-*-rc` pre-releases
- V7: built binary `--version` == `Cargo.toml` version
- V9: dev/flake.lock rtk path == root rtk path (assert-pins) — stale dev lock builds second rtk
- V8: cachix push filtered to this repo's outputs (`pushFilter`) — ⊥ mirror nixpkgs closure

## §R RELEASE

- R1: loop: `scripts/update.sh` (nixpkgs-lock + bump-rtk + relock dev/); `CHANGED=true` → R2
- R2: lock changed → branch + PR; CI builds + pushes cache from PR (same-repo only)
- R3: merge green PR; main run: verify-cache → promote `cached`
- R4: consumers `nix flake update nix-rtk` only after `cached` moved

## §T TESTING

- T1: `nix flake check --all-systems`
- T2: RTK test suite runs during build (preCheck sets HOME + RTK_DB_PATH); 4 Linux-sandbox-only skips
- T3: `scripts/verify-cache.sh` post-main-build
- T4: lefthook pre-commit + pre-push via `scripts/lint.sh`; shellcheck + actionlint

## §B BUILD

- B1: `nix build` — builds RTK for current system (pulls from cachix if cached)
- B2: `nix develop ./dev` — dev shell w/ RTK + all tooling
