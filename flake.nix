{
  description = "Nix package for RTK — CLI proxy that reduces LLM token consumption by 60-90%";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    rtk-src = {
      url = "github:rtk-ai/rtk/v0.42.0";
      flake = false;
    };
    nix-lefthook = {
      url = "github:pr0d1r2/nix-lefthook";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      rtk-src,
      nix-lefthook,
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
    {
      packages = forAllSystems (pkgs: {
        default = import ./rtk.nix {
          inherit pkgs;
          src = rtk-src;
        };
      });

      devShells = forAllSystems (pkgs: {
        ci = pkgs.mkShell {
          inputsFrom = [ nix-lefthook.devShells.${pkgs.stdenv.hostPlatform.system}.ci ];
          packages = [
            (import ./rtk.nix {
              inherit pkgs;
              src = rtk-src;
            })
          ];
        };

        default = pkgs.mkShell {
          inputsFrom = [ nix-lefthook.devShells.${pkgs.stdenv.hostPlatform.system}.ci ];
          packages = [
            (import ./rtk.nix {
              inherit pkgs;
              src = rtk-src;
            })
          ];
          shellHook = builtins.readFile ./dev.sh;
        };
      });
    };
}
