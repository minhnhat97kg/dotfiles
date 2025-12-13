{
  description = "Cross-platform Nix configuration (macOS, Linux & Android)";

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

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
    # Suppress dirty tree warning once flake config is trusted
    warn-dirty = false;
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-on-droid, home-manager, ... }:
    let
      # User configuration
      username = "nhath";
      useremail = "minhnhat97kg@gmail.com";

      # Custom packages
      swagger-to-kulala = pkgs: pkgs.buildGoModule {
        pname = "swagger-to-kulala";
        version = "1.0.0";
        src = ./scripts/swagger-to-kulala;
        vendorHash = "sha256-g+yaVIx4jxpAQ/+WrGKxhVeliYx7nLQe/zsGpxV4Fn4=";
        meta = with pkgs.lib; {
          description = "Convert Swagger/OpenAPI YAML to kulala.nvim HTTP files";
          homepage = "https://github.com/nhath/dotfiles";
          license = licenses.mit;
        };
      };

      # Shared packages across all platforms
      sharedPackages = pkgs: with pkgs; [
        # Core tools
        git gh fzf ripgrep fd jq jless coreutils

        # Dev - General
        nodejs go delve goimports-reviser maven gradle

        # Dev - Rust
        cargo rustc rustfmt clippy rust-analyzer

        # Dev - Python
        python3 pipx pyenv

        # Cloud & DevOps
        terraform

        # Databases & clients
        postgresql_16 mysql80 pgcli pspg
        # mycli removed due to pyarrow build issues on macOS

        # HTTP / API tools
        httpie hurl (swagger-to-kulala pkgs)

        # Diff & formatting
        delta diff-so-fancy

        # SSH tools
        sshpass

        # Clipboard management (platform-specific, use xclip/wl-clipboard on Linux)
        # clipboard-jh is macOS-only, handled per-platform

        # Utilities
        fx clipse imagemagick
      ];

      # macOS-specific packages
      darwinPackages = pkgs: with pkgs; [
        clipboard-jh
        nerd-fonts.jetbrains-mono
      ];

      # Linux-specific packages (handled in modules/linux.nix)
      linuxPackages = pkgs: with pkgs; [
        xclip
        wl-clipboard
      ];

      # Shared home-manager configuration
      sharedHomeConfig = args: import ./modules/shared.nix (args // { inherit sharedPackages; });

      pkgsDarwin = nixpkgs.legacyPackages.aarch64-darwin;
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
        x86_64-linux.go = let pkgs = nixpkgs.legacyPackages.x86_64-linux; in pkgs.mkShell { buildInputs = [ pkgs.go pkgs.delve pkgs.goimports-reviser pkgs.golangci-lint ]; };
        x86_64-linux.java = let pkgs = nixpkgs.legacyPackages.x86_64-linux; in pkgs.mkShell { buildInputs = [ pkgs.maven pkgs.gradle ]; };
        x86_64-linux.rust = let pkgs = nixpkgs.legacyPackages.x86_64-linux; in pkgs.mkShell { buildInputs = [ pkgs.rustc pkgs.cargo pkgs.clippy pkgs.rustfmt pkgs.rust-analyzer ]; };
      };

      # ============================================================================
      # macOS Configuration (nix-darwin)
      # ============================================================================
      darwinConfigurations."Nathan-Macbook" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs // { inherit username useremail sharedHomeConfig darwinPackages; };
        modules = [
          ./modules/darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              verbose = true;
              extraSpecialArgs = inputs // { inherit username sharedHomeConfig darwinPackages; };
              users.${username} = { pkgs, lib, config, ... }:
                lib.mkMerge [
                  (sharedHomeConfig { inherit pkgs lib; })
                  {
                    home.username = username;
                    home.homeDirectory = "/Users/${username}";
                    home.packages = (darwinPackages pkgs) ++ (with pkgs; [ kitty ]);
                    home.file.".config/kitty/kitty.conf" = {
                      source = ./kitty/kitty.conf;
                      force = true;
                    };
                    home.file.".config/sketchybar/" = { source = ./sketchybar; recursive = true; executable = true; };
                    home.file.".ideavimrc".source = ./shell/.ideavimrc;
                    home.file.".config/skhd/skhdrc".source = ./skhd/skhdrc;
                    home.file.".config/git/ignore".source = ./git/ignore;
                    home.file.".config/lazygit/" = { source = ./lazygit; recursive = true; };
                    home.file.".pspgconf".source = ./pspg/pspgconf;
                    home.file.".config/qutebrowser/config.py".source = ./qutebrowser/config.py;
                    home.file.".config/qutebrowser/profiles.yaml".source = ./qutebrowser/profiles.yaml;
                    # Userscript deployment removed; using command prefill for tab close
                    home.file.".local/bin/qb-profile" = {
                      source = ./qutebrowser/qb-profile;
                      executable = true;
                    };
                    home.file.".local/bin/qb-picker" = {
                      source = ./qutebrowser/qb-picker;
                      executable = true;
                    };
                    home.file.".local/bin/qb-picker-gui" = {
                      source = ./qutebrowser/qb-picker-gui;
                      executable = true;
                    };
                    home.file.".config/qutebrowser/create-qb-launcher.sh" = {
                      source = ./qutebrowser/create-qb-launcher.sh;
                      executable = true;
                    };
                  }
                ];
            };
          }
        ];
      };

      # ============================================================================
      # Linux Configuration (NixOS)
      # ============================================================================
      nixosConfigurations = {
        # x86_64 Linux desktop/laptop
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = inputs // { inherit username useremail sharedHomeConfig linuxPackages; };
          modules = [
            ./modules/linux.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                extraSpecialArgs = inputs // { inherit username sharedHomeConfig linuxPackages; };
                users.${username} = { pkgs, lib, config, ... }:
                  lib.mkMerge [
                    (sharedHomeConfig { inherit pkgs lib; })
                    {
                      home.username = username;
                      home.homeDirectory = "/home/${username}";
                      home.packages = (linuxPackages pkgs) ++ (with pkgs; [ kitty ]);
                      home.file.".config/kitty/kitty.conf" = {
                        source = ./kitty/kitty.conf;
                        force = true;
                      };
                      home.file.".ideavimrc".source = ./shell/.ideavimrc;
                      home.file.".config/git/ignore".source = ./git/ignore;
                      home.file.".config/lazygit/" = { source = ./lazygit; recursive = true; };
                      home.file.".pspgconf".source = ./pspg/pspgconf;
                    }
                  ];
              };
            }
          ];
        };
      };

      # ============================================================================
      # Android Configuration (nix-on-droid)
      # ============================================================================
      nixOnDroidConfigurations.default =
        let
          system = "aarch64-linux";
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        nix-on-droid.lib.nixOnDroidConfiguration {
          inherit pkgs;
          modules = [
            (import ./modules/android.nix {
              inherit pkgs sharedPackages sharedHomeConfig;
              lib = nixpkgs.lib;
            })
          ];
        };

      # Formatter
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.alejandra;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      };
    };
}
