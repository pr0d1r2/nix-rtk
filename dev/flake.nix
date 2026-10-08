{
  description = "Dev shell for nix-rtk (lefthook + linters); not consumed downstream";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nix-rtk.url = "path:..";
    nixpkgs.follows = "nix-rtk/nixpkgs";
    nix-lefthook = {
      # Pinned to the last rev that still exposes devShells.ci; later revs
      # moved to the set-and-setting standard (separate migration).
      url = "github:pr0d1r2/nix-lefthook/0632a5424b53b92a1ea6156df85017232e479afd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      nix-rtk,
      nix-lefthook,
      ...
    }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs (builtins.attrNames nix-rtk.packages) (
          system: f system nixpkgs.legacyPackages.${system}
        );
    in
    {
      devShells = forAllSystems (
        system: pkgs: rec {
          ci = pkgs.mkShell {
            inputsFrom = [ nix-lefthook.devShells.${system}.ci ];
            packages = [
              nix-rtk.packages.${system}.default
              pkgs.actionlint
              pkgs.shellcheck
            ];
          };

          default = ci.overrideAttrs (old: {
            shellHook = (old.shellHook or "") + builtins.readFile ../dev.sh;
          });
        }
      );
    };
}
