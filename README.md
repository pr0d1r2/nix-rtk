# nix-rtk

[![CI](https://github.com/pr0d1r2/nix-rtk/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-rtk/actions/workflows/ci.yml)

Nix package for [RTK](https://github.com/rtk-ai/rtk) — CLI proxy that reduces LLM token consumption by 60-90%. Pre-built binaries served via [cachix](https://pr0d1r2.cachix.org).

## Usage

### As a flake input

Track the `cached` branch. It only ever points at commits whose binaries are
already in the cache for every tier-1 system.

```nix
{
  inputs.nix-rtk.url = "github:pr0d1r2/nix-rtk/cached";
  # No `inputs.nixpkgs.follows` here: rtk built against your nixpkgs is a
  # different store path, so it would compile locally instead of downloading.

  # In devShell packages:
  nix-rtk.packages.${system}.default

  # Or via overlay (still the cached build, not rebuilt against your pkgs):
  nixpkgs.overlays = [ nix-rtk.overlays.default ];  # provides pkgs.rtk
}
```

The flake's `nixConfig` substituter applies only when nix-rtk is the flake you
invoke directly. Consumers need `https://pr0d1r2.cachix.org` in their own
`nixConfig` or in `nix.conf` (see below).

The consumer-facing flake has two inputs (`nixpkgs-lock`, `rtk-src`), so it
adds only a few nodes to your lock. Dev tooling lives in `dev/`, a separate
flake consumers never fetch.

### Direct run

```bash
nix run github:pr0d1r2/nix-rtk/cached
```

## Binary cache

To accept the cache without prompts, add to `~/.config/nix/nix.conf`:

```ini
trusted-substituters = https://pr0d1r2.cachix.org
trusted-public-keys = pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=
```

Tier-1 (built and cached by CI): `aarch64-darwin`, `x86_64-linux`,
`aarch64-linux`. `x86_64-darwin` is evaluated but not built.

Check what consumers get:

```bash
scripts/verify-cache.sh github:pr0d1r2/nix-rtk/cached
```

## Release flow

There is no scheduled workflow. An external loop drives the daily update:

1. `scripts/update.sh` follows nixpkgs-lock, bumps rtk to the latest stable tag and relocks `dev/`. It prints `CHANGED=true|false`.
2. If anything changed, push a branch and open a PR. CI builds on native runners and pushes to cachix from the PR itself.
3. Merge once green. The `main` run confirms every tier-1 path is in the cache (`verify-cache`), then fast-forwards `cached` (`promote`).
4. Consumers run `nix flake update nix-rtk` only after `cached` has moved.

## Development

```bash
direnv allow            # or: nix develop ./dev
scripts/lint.sh         # every lefthook gate, as CI runs it
```

## License

MIT
