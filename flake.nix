{
  description = "Nix package for RTK — CLI proxy that reduces LLM token consumption by 60-90%";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  # Consumer-facing flake: every input here lands in every consumer's lock, so
  # it carries only what the package needs. Dev tooling (lefthook and its
  # remotes) lives in ./dev, a separate flake consumers never see.
  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";
    rtk-src = {
      url = "github:rtk-ai/rtk/v0.51.0";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      rtk-src,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    rec {
      packages = forAllSystems (
        packagePkgs:
        let
          package = import ./rtk.nix {
            pkgs = packagePkgs;
            src = rtk-src;
          };
        in
        {
          default = package;
          rtk = package;
        }
      );

      overlays.default = final: _prev: {
        inherit (packages.${final.system}) rtk;
      };

    };
}
