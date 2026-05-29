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
    nix-dev-shell-agentic-stub = {
      url = "github:pr0d1r2/nix-dev-shell-agentic";
      flake = false;
    };
    nix-lefthook-editorconfig-checker = {
      url = "github:pr0d1r2/nix-lefthook-editorconfig-checker";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
    nix-lefthook-git-conflict-markers = {
      url = "github:pr0d1r2/nix-lefthook-git-conflict-markers";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
    nix-lefthook-git-no-local-paths = {
      url = "github:pr0d1r2/nix-lefthook-git-no-local-paths";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
    nix-lefthook-missing-final-newline = {
      url = "github:pr0d1r2/nix-lefthook-missing-final-newline";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
    nix-lefthook-nix-flake-check = {
      url = "github:pr0d1r2/nix-lefthook-nix-flake-check";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
    nix-lefthook-nix-no-embedded-shell = {
      url = "github:pr0d1r2/nix-lefthook-nix-no-embedded-shell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
    nix-lefthook-nixfmt = {
      url = "github:pr0d1r2/nix-lefthook-nixfmt";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
    nix-lefthook-trailing-whitespace = {
      url = "github:pr0d1r2/nix-lefthook-trailing-whitespace";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
    nix-lefthook-statix = {
      url = "github:pr0d1r2/nix-lefthook-statix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
    nix-lefthook-typos = {
      url = "github:pr0d1r2/nix-lefthook-typos";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-dev-shell-agentic.follows = "nix-dev-shell-agentic-stub";
      };
    };
  };

  outputs =
    {
      nixpkgs,
      rtk-src,
      nix-lefthook-editorconfig-checker,
      nix-lefthook-git-conflict-markers,
      nix-lefthook-git-no-local-paths,
      nix-lefthook-missing-final-newline,
      nix-lefthook-nix-flake-check,
      nix-lefthook-nix-no-embedded-shell,
      nix-lefthook-nixfmt,
      nix-lefthook-statix,
      nix-lefthook-trailing-whitespace,
      nix-lefthook-typos,
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
        default = pkgs.mkShell {
          packages = [
            (import ./rtk.nix {
              inherit pkgs;
              src = rtk-src;
            })
            nix-lefthook-editorconfig-checker.packages.${pkgs.stdenv.hostPlatform.system}.default
            nix-lefthook-git-conflict-markers.packages.${pkgs.stdenv.hostPlatform.system}.default
            nix-lefthook-git-no-local-paths.packages.${pkgs.stdenv.hostPlatform.system}.default
            nix-lefthook-missing-final-newline.packages.${pkgs.stdenv.hostPlatform.system}.default
            nix-lefthook-nix-flake-check.packages.${pkgs.stdenv.hostPlatform.system}.default
            nix-lefthook-nix-no-embedded-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
            nix-lefthook-nixfmt.packages.${pkgs.stdenv.hostPlatform.system}.default
            nix-lefthook-statix.packages.${pkgs.stdenv.hostPlatform.system}.default
            nix-lefthook-trailing-whitespace.packages.${pkgs.stdenv.hostPlatform.system}.default
            nix-lefthook-typos.packages.${pkgs.stdenv.hostPlatform.system}.default
            pkgs.coreutils
            pkgs.deadnix
            pkgs.editorconfig-checker
            pkgs.git
            pkgs.lefthook
            pkgs.nix
            pkgs.nixfmt
            pkgs.typos
            pkgs.yamllint
          ];
          shellHook = builtins.readFile ./dev.sh;
        };
      });
    };
}
