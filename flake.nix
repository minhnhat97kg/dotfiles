{
  description = "Cross-platform Nix configuration (macOS, Linux, WSL, Termux, Android)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    warn-dirty = false;
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-on-droid, home-manager, ... }:
    let
      # User configuration
      username = "nhath";
      useremail = "minhnhat97kg@gmail.com";

      # Core packages — installed on ALL platforms including Termux
      corePackages = pkgs: with pkgs; [
        git gh fzf ripgrep fd jq jless coreutils
        delta diff-so-fancy
        fx
      ];

      # Dev packages — installed on Linux (Ubuntu/WSL) and macOS, NOT Termux
      devPackages = pkgs: with pkgs; [
        # Languages
        nodejs go delve goimports-reviser
        cargo rustc rustfmt clippy rust-analyzer
        python3 pipx

        # Cloud & DB
        terraform
        postgresql_16 mysql80 pgcli pspg
        # mycli removed due to pyarrow build issues on macOS

        # Utilities
        imagemagick
        # clipse removed — requires Wayland/X11 compositor; darwin-only
      ];

      # Shared packages — combined alias for backwards compat (macOS + Android use this)
      sharedPackages = pkgs: (corePackages pkgs) ++ (devPackages pkgs);

      # Helper to build a standalone home-manager config for Linux
      mkLinuxHome = { hostname, username ? "nhath", system ? "x86_64-linux" }:
        let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        in home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit corePackages devPackages sharedPackages; };
          modules = [
            ./modules/platforms/linux.nix
            ./hosts/linux/${hostname}.nix
          ];
        };

      # macOS-specific packages
      darwinPackages = pkgs: with pkgs; [
        clipboard-jh
        clipse
        nerd-fonts.jetbrains-mono
      ];

      # Shared home-manager configuration (modules/home/default.nix)
      # sharedHomeConfig kept for reference but no longer used — hosts import directly

    in
    {
      # ============================================================================
      # Dev Shells
      # ============================================================================
      devShells = {
        aarch64-darwin.go = let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in pkgs.mkShell { buildInputs = [ pkgs.go pkgs.delve pkgs.goimports-reviser pkgs.golangci-lint ]; };
        aarch64-darwin.java = let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in pkgs.mkShell { buildInputs = [ pkgs.maven pkgs.gradle ]; };
        aarch64-darwin.rust = let pkgs = nixpkgs.legacyPackages.aarch64-darwin; in pkgs.mkShell { buildInputs = [ pkgs.rustc pkgs.cargo pkgs.clippy pkgs.rustfmt pkgs.rust-analyzer ]; };
        aarch64-linux.go = let pkgs = nixpkgs.legacyPackages.aarch64-linux; in pkgs.mkShell { buildInputs = [ pkgs.go pkgs.delve pkgs.goimports-reviser pkgs.golangci-lint ]; };
        aarch64-linux.rust = let pkgs = nixpkgs.legacyPackages.aarch64-linux; in pkgs.mkShell { buildInputs = [ pkgs.rustc pkgs.cargo pkgs.clippy pkgs.rustfmt pkgs.rust-analyzer ]; };
      };

      # ============================================================================
      # macOS Configurations (nix-darwin)
      # To add a new Mac: copy this stanza, update hostname + host file path
      # ============================================================================
      darwinConfigurations."Nathan-Macbook" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs // { inherit username useremail darwinPackages sharedPackages; };
        modules = [
          ./modules/platforms/darwin.nix
          ./hosts/darwin/Nathan-Macbook.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              verbose = true;
              extraSpecialArgs = inputs // { inherit username darwinPackages sharedPackages; };
            };
          }
        ];
      };

      # ============================================================================
      # Android Configuration (nix-on-droid)
      # ============================================================================
      nixOnDroidConfigurations.default =
        let
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config.allowUnfree = true;
          };
        in
        nix-on-droid.lib.nixOnDroidConfiguration {
          inherit pkgs;
          modules = [
            ./modules/platforms/android.nix
            (import ./hosts/android/default.nix {
              inherit pkgs sharedPackages;
              lib = nixpkgs.lib;
            })
          ];
        };

      # Formatter
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.alejandra;
      };

      # ============================================================================
      # Linux Home-Manager Configurations (standalone)
      # To add a new host: add mkLinuxHome entry + create hosts/linux/<hostname>.nix
      # ============================================================================
      homeConfigurations = {
        "ubuntu"  = mkLinuxHome { hostname = "ubuntu"; };
        "wsl"     = mkLinuxHome { hostname = "wsl"; };
        "termux"  = mkLinuxHome { hostname = "termux"; system = "aarch64-linux"; };
      };
    };
}
