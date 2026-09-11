{
  description = "Cross-platform Nix configuration (macOS, Linux, WSL, Termux, Android)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    neovim-src = {
      url = "github:neovim/neovim/v0.12.0";
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

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-on-droid, home-manager, neovim-src, ... }:
    let
      # User configuration
      username = "nhath";
      useremail = "nhath@example.com";

      # Systems this flake supports — used for devShells/formatter so the
      # x86_64-linux Ubuntu host gets `nix develop` / `nix fmt` too.
      forAllSystems = nixpkgs.lib.genAttrs [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];

      # Core packages — installed on ALL platforms including Termux
      corePackages = pkgs: with pkgs; [
        git gh fzf ripgrep fd jq jless coreutils
        delta diff-so-fancy
        fx
        ddgr
      ];

      # Minimal dev packages matching nvim language support:
      # Go, Rust, React/JS/TS, Lua + build tools for native plugins/treesitter.
      devPackages = pkgs: with pkgs; [
        gnumake gcc

        # Go
        go gopls delve gofumpt goimports-reviser

        # Rust
        cargo rustc rustfmt clippy rust-analyzer

        # React / JS / TS
        nodejs typescript typescript-language-server

        # Lua
        lua-language-server stylua

        # Python — uv owns interpreters and per-project venvs (`uv python
        # install 3.13`, `uv sync`), so no python3 interpreter is pinned here;
        # uv downloads its own python-build-standalone builds. Nix only
        # provides the tools that must exist outside any venv: the type
        # checker and the linter/formatter (see nvim's lsp/basedpyright.lua
        # and lsp/ruff.lua).
        uv basedpyright ruff

        # Java / JVM (mem-system: Spring Boot, Maven, Java 21)
        # jdt-language-server ships a `jdtls` wrapper on PATH; nvim's lsp/jdtls.lua
        # invokes it directly (it resolves the JDK from PATH — jdk21 above).
        jdk21 maven jdt-language-server lombok

        # DB clients used by vim-dadbod (psql speaks postgres; add mysql/mariadb
        # client here if a project needs it)
        postgresql
        glow
      ];

      # Shared packages — combined alias for backwards compat (macOS + Android use this)
      sharedPackages = pkgs: (corePackages pkgs) ++ (devPackages pkgs);

      # Wayland desktop stack (niri compositor) — only used by hosts that run a
      # graphical Linux desktop (currently just the `ubuntu` host).
      # NOTE: kitty and qutebrowser are intentionally NOT in this list — both
      # crash on EGL/GPU init on this machine (Nix's bundled Mesa/EGL doesn't
      # match the system's GPU driver, a common non-NixOS issue; qutebrowser's
      # QtWebEngine hits it even harder than kitty). Keep kitty apt-installed
      # (see hosts/linux/ubuntu-apt-deps.sh / `make apt-deps`) and qutebrowser
      # in a pip venv (see hosts/linux/ubuntu-qutebrowser-venv.sh /
      # `make qutebrowser-venv`) — only their configs are Nix-managed
      # (modules/home/kitty.nix, modules/home/qutebrowser.nix).
      linuxDesktopPackages = pkgs: with pkgs; [
        niri waybar fuzzel kanata
        swaynotificationcenter   # notification daemon + control center (see linux/swaync/)
        btop superfile
        brightnessctl
        grim   # screenshots (wlroots-compatible; niri supports the export-dmabuf protocol)
        swayidle
        kanshi   # dynamic output profiles by connected-monitor set (see linux/kanshi/config)

        # Mouseless helpers:
        #   warpd   — keyboard-driven mouse pointer (hint/grid/normal modes).
        #             Uses the kernel uinput device, so it works on niri even
        #             though niri doesn't implement wlr-virtual-pointer. Needs
        #             membership in the "input" group (already set up for kanata).
        #   cliphist — clipboard history, fed by a wl-paste watcher service and
        #             browsed with fuzzel (see clipboard.sh / cliphist.service).
        warpd cliphist

        # Containers — rootless podman + a docker-API-compatible socket
        # (see modules/home/podman.nix) so lazydocker works against it.
        podman podman-compose podman-tui
        lazydocker
      ];

      # Helper to build a standalone home-manager config for Linux
      mkLinuxHome = { hostname, username ? "your-username", system ? "x86_64-linux" }:
        let pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        in home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit corePackages devPackages sharedPackages linuxDesktopPackages neovim-src; };
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
      # Dev Shells — one definition per toolchain, generated for every system
      # ============================================================================
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          go = pkgs.mkShell { buildInputs = with pkgs; [ go gopls delve gofumpt goimports-reviser golangci-lint ]; };
          rust = pkgs.mkShell { buildInputs = with pkgs; [ rustc cargo clippy rustfmt rust-analyzer ]; };
          react = pkgs.mkShell { buildInputs = with pkgs; [ nodejs typescript typescript-language-server ]; };
          lua = pkgs.mkShell { buildInputs = with pkgs; [ lua-language-server stylua ]; };
          python = pkgs.mkShell { buildInputs = with pkgs; [ uv basedpyright ruff ]; };
        });

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

      # Formatter — all supported systems (`nix fmt` / `make format`)
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

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
