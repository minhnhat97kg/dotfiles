# packages.nix
# Package lists, each a function `pkgs: [ ... ]`. flake.nix hands them to the
# hosts: core + dev everywhere (as sharedPackages), linuxDesktop on the niri
# desktop, darwin on macOS. Android picks its own subset (modules/platforms/android.nix).
{
  # Core packages — installed on ALL platforms including Termux
  corePackages = pkgs: with pkgs; [
    git gh gh-dash fzf ripgrep fd jq jless coreutils
    delta diff-so-fancy
    fx
    ddgr
  ];

  # Minimal dev packages matching nvim language support:
  # Go, Rust, React/JS/TS, Lua + build tools for native plugins/treesitter.
  devPackages = pkgs: with pkgs; [
    gnumake gcc tree-sitter

    # Go
    go gopls delve gofumpt goimports-reviser golangci-lint

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

    # Chạy stack dev nhiều process (ssh tunnel + các service Spring Boot) với
    # dependency ordering + health probe — xem mem-system/src/process-compose.yaml
    process-compose

    # DB clients used by vim-dadbod (psql speaks postgres; add mysql/mariadb
    # client here if a project needs it)
    postgresql
    glow
  ];

  # Wayland desktop stack (niri compositor) — only used by hosts that run a
  # graphical Linux desktop (currently just the `ubuntu` host).
  # kitty and qutebrowser are intentionally NOT here: the Nix builds crash on
  # EGL init on this non-NixOS host (see hosts/linux/ubuntu-apt-deps.sh and
  # hosts/linux/ubuntu-qutebrowser-venv.sh).
  linuxDesktopPackages = pkgs: with pkgs; [
    niri kanata
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
    #             browsed in the Caelestia launcher (Mod+Shift+C).
    warpd cliphist

    # macOS look: WhiteSur GTK theme, icons, cursor (see modules/home/gtk.nix).
    whitesur-gtk-theme whitesur-icon-theme whitesur-cursors

    # Containers — rootless podman + a docker-API-compatible socket
    # (see modules/home/podman.nix) so lazydocker works against it.
    podman podman-compose podman-tui
    lazydocker

    # p7zip: `7z` for hosts/linux/ubuntu-sf-fonts.sh to unpack Apple's font
    # installers (the fonts themselves can't be in nixpkgs — see its header).
    p7zip
  ];

  # macOS-specific packages
  darwinPackages = pkgs: with pkgs; [
    clipboard-jh
    clipse
    mosh          # authenticates through the existing SSH configuration/certificates
    nerd-fonts.jetbrains-mono
    azure-cli
    btop
  ];
}
