{
  description = "Cross-platform Nix configuration (macOS, Linux, Termux, Android)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    neovim-src = {
      url = "github:neovim/neovim/v0.12.5";
      flake = false;
    };

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

    # Manages the Homebrew installation itself (pins the brew version and
    # installs/upgrades it via activation) so `brew` doesn't have to be
    # bootstrapped by hand. Package-level management stays in nix-darwin's
    # `homebrew.*` options (see modules/platforms/darwin.nix).
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Caelestia desktop shell (Quickshell), niri port. Upstream
    # caelestia-dots/shell is Hyprland-only. This is AyushKr2003's (archived)
    # niri port plus a fork's fixes: it installs scripts/ (colour generation,
    # OCR/Lens picker, manga/novel backends) and fixes notification actions.
    # See modules/home/niri.nix.
    caelestia-shell = {
      url = "github:chad-russell/niri-caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # GL wrapper for Nix-built Qt apps on this non-NixOS host — Nix's Mesa
    # fails eglGetDisplay otherwise (see modules/home/niri.nix).
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-on-droid, home-manager, neovim-src, nix-homebrew, ... }:
    let
      # User configuration
      username = "nhath";
      useremail = "nhath@example.com";

      # Systems this flake supports — used for the formatter so every host
      # gets `nix fmt`.
      forAllSystems = nixpkgs.lib.genAttrs [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];

      # Package lists (each a `pkgs: [ ... ]` function) — see packages.nix.
      inherit (import ./packages.nix) corePackages devPackages linuxDesktopPackages darwinPackages;

      # What every host's home-manager installs (modules/home/default.nix).
      sharedPackages = pkgs: (corePackages pkgs) ++ (devPackages pkgs);

      # Helper to build a standalone home-manager config for Linux.
      # `username` is only consumed by hosts/linux/termux.nix (ubuntu.nix
      # hardcodes its own). It must match `$USER` when that variable is set,
      # because home-manager's activation sanity check aborts otherwise (see
      # home-environment.nix: checkStringEq USER). Plain Termux leaves $USER
      # unset, so the check is skipped there, but the nix-on-droid shell sets
      # it to "nix-on-droid" — hence the default.
      mkLinuxHome = { hostname, username ? "nix-on-droid", system ? "x86_64-linux" }:
        let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        in home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit corePackages devPackages sharedPackages linuxDesktopPackages neovim-src username; inherit (inputs) caelestia-shell nixgl; };
          modules = [
            ./modules/platforms/linux.nix
            ./hosts/linux/${hostname}.nix
          ];
        };

    in
    {
      # ============================================================================
      # macOS Configurations (nix-darwin)
      # To add a new Mac: copy this stanza, update hostname + host file path
      # ============================================================================
      darwinConfigurations."nathan-macbook" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs // { inherit username useremail darwinPackages sharedPackages neovim-src; };
        modules = [
          ./modules/platforms/darwin.nix
          ./hosts/darwin/nathan-macbook.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              verbose = true;
              backupFileExtension = "backup";
              extraSpecialArgs = inputs // { inherit username darwinPackages sharedPackages neovim-src; };
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
            overlays = [ nix-on-droid.overlays.default ];
          };
        in
        # Same shape as nix-on-droid's templates/advanced: hosts are real
        # modules (so they receive `config`), custom args go through
        # extraSpecialArgs instead of calling the host file by hand.
        nix-on-droid.lib.nixOnDroidConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit corePackages sharedPackages neovim-src; };
          modules = [
            ./modules/platforms/android.nix
            ./hosts/android/default.nix
          ];
        };

      # ============================================================================
      # NixOS Configurations
      # ============================================================================
      nixosConfigurations."rog-ally" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/rog-ally.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                inherit sharedPackages linuxDesktopPackages neovim-src;
                inherit (inputs) caelestia-shell nixgl;
              };
            };
          }
        ];
      };

      # Formatter — all supported systems (`nix fmt` / `make format`)
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      # ============================================================================
      # Linux Home-Manager Configurations (standalone)
      # To add a new host: add mkLinuxHome entry + create hosts/linux/<hostname>.nix
      # ============================================================================
      homeConfigurations = {
        "ubuntu"  = mkLinuxHome { hostname = "ubuntu"; };
        "termux"  = mkLinuxHome { hostname = "termux"; system = "aarch64-linux"; };
      };
    };
}
