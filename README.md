# Cross-Platform Dotfiles

Nix configuration for **macOS** (nix-darwin), **Linux** (standalone home-manager —
Ubuntu, WSL), **Termux**, and **Android** (nix-on-droid). One flake, one set of
package lists, per-host overrides for anything machine-specific.

## Structure

```
dotfiles/
├── flake.nix                   # Main entry: package lists, all host/platform outputs
├── Makefile                    # install / update / apt-deps / qutebrowser-venv commands
├── bootstrap.sh                # Installs Nix + clones this repo
│
├── modules/
│   ├── platforms/              # Per-OS glue (linux.nix, darwin.nix, android.nix)
│   └── home/                   # Shared home-manager modules
│       ├── default.nix         # Imports shell/editor/terminal/git/files — all platforms
│       ├── shell.nix           # zsh + oh-my-zsh
│       ├── editor.nix          # Neovim (built from pinned source)
│       ├── terminal.nix        # alacritty + tmux (real config, symlinked)
│       ├── git.nix             # git config (personal/work conditional includes)
│       ├── files.nix           # SSH, lazygit, direnv, nvim + ~/.scripts symlinks
│       ├── kitty.nix           # kitty config — all hosts (package is per-platform)
│       ├── qutebrowser.nix     # qutebrowser config — macOS + Ubuntu
│       ├── niri.nix            # niri/waybar/fuzzel/mako/kanata — Ubuntu only
│       ├── podman.nix          # rootless podman + docker-API socket — Ubuntu only
│       ├── fcitx5.nix          # IME config only — Ubuntu only
│       └── tui-tools.nix       # btop + superfile — Ubuntu only
│
├── hosts/
│   ├── darwin/                 # One file per Mac (example-macbook.nix is the template)
│   ├── linux/{ubuntu,wsl,termux}.nix
│   ├── linux/ubuntu-apt-deps.sh         # apt packages Nix can't provide on Ubuntu
│   ├── linux/ubuntu-qutebrowser-venv.sh # qutebrowser via pip venv (Nix build crashes)
│   └── android/default.nix
│
├── shared/                     # Real config files, symlinked into ~ by modules/home/*
│   ├── nvim/                   # Neovim config (init.lua, lsp/)
│   ├── tmux/                   # tmux.conf + dark/light palettes + scripts/
│   ├── git/                    # gitconfig + personal/work conditional includes
│   ├── kitty/ qutebrowser/ btop/ superfile/
│   └── scripts/                # Personal utility scripts, symlinked onto PATH
│
├── linux/                      # niri desktop stack raw configs (Ubuntu host)
│   └── niri/ waybar/ fuzzel/ mako/ kanata/ fcitx5/ warpd/ swaylock/
│
└── termux/                     # Termux-specific colors/properties
```

## Quick Start

### macOS

Tiling window management via **yabai** + **skhd** (nix-darwin's `services.yabai`
/ `services.skhd`, config in `hosts/darwin/example-macbook.nix`). Basic
tiling/focus/resize works immediately; the scripting addition (for full
space-switching behavior) needs SIP partially disabled — a manual step, see
the comment above `services.yabai` in that file.

```bash
sh <(curl -L https://nixos.org/nix/install)
git clone <repo> ~/projects/dotfiles
cd ~/projects/dotfiles
make install
```

### Ubuntu Linux (desktop, niri)

The `ubuntu` host is a full niri (Wayland scrollable-tiling compositor) desktop:
niri + waybar + fuzzel + mako + kanata + qutebrowser + tmux + rootless podman,
all Nix-managed.

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh          # installs Nix, nothing else
exec $SHELL -l          # nix now on PATH
make apt-deps           # kitty + fcitx5 — see "Things that stay apt-installed" below
make install            # applies the flake
```

### WSL / Termux

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
exec $SHELL -l
make install             # picks wsl or termux automatically
```

### Android (nix-on-droid)

```bash
# Install from F-Droid: https://f-droid.org/packages/com.termux.nix/
git clone <repo> ~/dotfiles
cd ~/dotfiles
nix-on-droid switch --flake .
```

## Common Commands

```bash
make help              # list all commands (platform auto-detected)
make install           # apply configuration for the detected platform
make darwin            # macOS only
make linux             # Ubuntu only
make wsl               # WSL only
make termux            # Termux only
make android           # Android (nix-on-droid) only
make apt-deps           # Ubuntu only: apt-install kitty + fcitx5 (see below)
make update             # nix flake update
make format             # nix fmt
make check              # nix flake check
make clean              # remove build artifacts
```

## Things that stay apt-installed on Ubuntu (not Nix)

A few packages are deliberately **not** in `linuxDesktopPackages` — Nix can't
provide them cleanly on a non-NixOS system:

- **kitty** — the Nix-built kitty crashes on EGL init (its bundled Mesa/EGL
  doesn't match the host's GPU driver — a common non-NixOS gotcha). Its
  *config* is still Nix-managed (`modules/home/kitty.nix`); only the package
  is apt.
- **fcitx5** (+ frontends) — needs to register GTK/Qt immodules into
  system-wide paths a user-level Nix profile can't reach. Only its config
  (`modules/home/fcitx5.nix`) is Nix-managed.

Run `make apt-deps` (or `./hosts/linux/ubuntu-apt-deps.sh`) once per machine
to install these.

## Customization

Edit `flake.nix`:

```nix
username = "your-username";
useremail = "your-email@example.com";

# Installed on every platform, including Termux:
corePackages = pkgs: with pkgs; [ git fzf ripgrep ... ];

# Dev toolchains, also every platform:
devPackages = pkgs: with pkgs; [ go rustc nodejs ... ];

# Ubuntu desktop only (niri stack, browsers, containers, TUI tools):
linuxDesktopPackages = pkgs: with pkgs; [ niri waybar ... ];
```

Per-machine overrides (hostname, username, home directory) live in
`hosts/<platform>/<hostname>.nix`.

## Troubleshooting

- **`nix: command not found` after `bootstrap.sh`** — the installer only
  patches system-wide shell rc files (`/etc/zshrc`, `/etc/profile.d/nix.sh`),
  which are read once at shell *startup*. Start a fresh shell (`exec $SHELL -l`
  or a new terminal) — `source ~/.zshrc` alone won't pick it up.
- **GUI apps spawned by niri/systemd can't find a Nix binary** — systemd
  `--user`'s own default `PATH` doesn't include `~/.nix-profile/bin` (only
  login shells get that via `/etc/zshrc`). This repo fixes it via an
  `environment.d` file (see `modules/home/niri.nix`) — but on Ubuntu,
  `/usr/lib/environment.d/99-environment.conf` and `990-snapd.conf` sort
  *after* most custom files and silently reset `PATH`, so ours is named
  `zz-nix-path.conf` to sort last. Takes effect on the next full login.
- **`home-manager switch -b backup` collides with an existing `.backup` file
  or a stale systemd `*.wants/` symlink** — pass a different backup extension
  (`-b backup2`) or remove the stale enable-symlink; it'll be recreated.
- **macOS: `darwin-rebuild` not found** → `nix run nix-darwin -- switch --flake .`

## License

MIT
