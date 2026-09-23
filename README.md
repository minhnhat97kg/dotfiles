# Cross-Platform Dotfiles

Nix configuration for **macOS** (nix-darwin), **Linux** (standalone home-manager —
Ubuntu), **Termux**, and **Android** (nix-on-droid). One flake, one set of
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
│       ├── niri.nix            # niri/waybar/fuzzel/swaync/kanata — Ubuntu only
│       ├── podman.nix          # rootless podman + docker-API socket — Ubuntu only
│       ├── fcitx5.nix          # IME config only — Ubuntu only
│       └── tui-tools.nix       # btop + superfile — Ubuntu only
│
├── hosts/
│   ├── darwin/                 # One file per Mac (example-macbook.nix is the template)
│   ├── linux/{ubuntu,termux}.nix
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
│   └── niri/ waybar/ fuzzel/ swaync/ kanata/ fcitx5/ warpd/ swaylock/
│
└── termux/                     # Termux-specific colors/properties
```

## Quick Start

### macOS

```bash
sh <(curl -L https://nixos.org/nix/install)
git clone <repo> ~/projects/dotfiles
cd ~/projects/dotfiles
make install
```

### Ubuntu Linux (desktop, niri)

The `ubuntu` host is a full niri (Wayland scrollable-tiling compositor) desktop:
niri + waybar + fuzzel + swaync + kanata + qutebrowser + tmux + rootless podman,
all Nix-managed.

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh          # installs Nix, nothing else
exec $SHELL -l          # nix now on PATH
make apt-deps           # kitty + fcitx5 — see "Things that stay apt-installed" below
make install            # applies the flake
```

### Termux

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
exec $SHELL -l
make install             # picks termux automatically
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

## Component Setup (one by one)

Every component below is a home-manager module in `modules/home/` that
symlinks a config from this repo into `~/.config/...` (or manages a
`systemd --user` unit). They're additive — imported per-host in
`hosts/<platform>/<hostname>.nix` — so a host only gets what it imports.

### Shell — `modules/home/shell.nix`
zsh + oh-my-zsh (`robbyrussell` theme). Sets up `GOPATH`/`GOROOT`, npm/cargo/bun
global bin dirs, `~/.scripts` on `PATH`, AWS region, and sources
`~/.config/dotfiles/scripts/load-aliases.sh` if present (an optional,
untracked, per-machine alias file). Shared across every platform.

### Editor — `modules/home/editor.nix` + `shared/nvim/`
Neovim built from pinned source, config symlinked from `shared/nvim/` (`init.lua`,
`lsp/gopls.lua`, `lsp/ts_ls.lua`). `nvim-pack-lock.json` is deliberately
excluded from the managed symlink (`files.nix`) since Neovim rewrites it at
runtime via `vim.pack` — a read-only Nix-store symlink there would break on
every update.

### Terminal — `modules/home/terminal.nix` + `modules/home/kitty.nix`
- **Alacritty**: JetBrainsMono Nerd Font, buttonless window, configured
  directly via `programs.alacritty.settings` (no separate config file).
- **tmux**: real `shared/tmux/tmux.conf` symlinked verbatim (not home-manager's
  config-generation, which would rewrite it) + `dark.conf`/`light.conf` themes
  and `shared/tmux/scripts/` (`cycle-layout.sh`, plus `git-summary.sh` which
  feeds the status bar's working-tree diff segment — files changed, +/- lines,
  hidden on a clean tree).
- **kitty**: config generated by `modules/home/kitty.nix` for every host
  (platform differences keyed on `isDarwin`); on Ubuntu the *package* stays apt-installed — the Nix-built
  kitty crashes on EGL init because its bundled Mesa doesn't match the host
  GPU driver (a common non-NixOS gotcha). Run `make apt-deps` once to get it.

### Git — `modules/home/git.nix` + `shared/git/`
Base `gitconfig` with conditional `includeIf` blocks for personal vs. work
identities (`shared/git/personal.gitconfig`, `shared/git/work.gitconfig.template` — copy the
template to `work.gitconfig` and fill in your work email/signing key, it's
gitignored) plus a shared `gitignore_global`.

### Files — `modules/home/files.nix`
Grab-bag of small, shared pieces:
- `~/.ssh/authorized_keys` seeded from a placeholder (replace the key before
  relying on it).
- `programs.lazygit` (plain alias `lg`, not the zsh-integration function).
- `programs.direnv`.
- `~/.scripts/` symlinked and marked executable — anything dropped here lands
  on `PATH` via `shell.nix`.

### niri desktop stack — `modules/home/niri.nix` (Ubuntu only)
The full Wayland tiling-compositor setup, one systemd user unit per piece:
- **niri** — the compositor itself; config in `linux/niri/config.kdl` (see
  `linux/niri/keybindings.md`), plus `linux/niri/scripts/lid.sh` for lid-close/open output
  handling and `linux/niri/scripts/show-monitors.sh` for debugging output layout.
- **waybar** — status bar (`linux/waybar/config.jsonc`, `style.css`).
  Supervised directly by systemd so `Restart=always` actually works across a
  compositor restart; `linux/waybar/scripts/launch.sh` picks the active output
  (built-in vs. external) before `exec`-ing waybar, and `watch-reload.sh`
  restarts it whenever the config changes. Scripts under `linux/waybar/scripts/`
  back the individual modules (volume, brightness, power-draw, workspaces,
  powermenu, quickmenu, window title).
- **fuzzel** — app launcher / dmenu replacement (`linux/fuzzel/fuzzel.ini`), plus
  `linux/fuzzel/scripts/` for clipboard history, a "smart" launcher, and a
  window-switcher.
- **swaync** — notification daemon + control center (`linux/swaync/`). Runs as a
  supervised `swaync.service`; the panel is `Mod+N`, DND is `Mod+Ctrl+N`, and the
  waybar `custom/notification` module renders its push feed.
- **kanata** — keyboard remapper (`linux/kanata/kanata.kbd`: Caps→Esc/Ctrl + a
  Space tap-hold nav layer). Needs `/dev/uinput` read/write — add your user to
  the `input` group and set up a matching udev rule yourself (outside
  home-manager's reach, requires root); this repo only manages the config and
  the `kanata.service` unit. Explicitly excludes fcitx5-lotus's virtual
  "Lotus-Uinput-Server" device to avoid a feedback loop with its Uinput typing
  mode (see the fcitx5 section below).
- **kanshi** — applies an output layout profile matching whichever monitors
  are currently connected (`linux/kanshi/config`), talking to niri over
  wlr-output-management.
- **swayidle + swaylock** — lock after 5 min idle, blank outputs at 5.5 min,
  suspend at 30 min; swayidle is the single owner of swaylock so
  `loginctl lock-session` (e.g. the waybar powermenu) and idle timeouts both
  route through the same lock/unlock handlers. swaylock's appearance comes
  from `linux/swaylock/config`; the package stays apt-installed (the Nix build lacks
  PAM, so it can never actually unlock).
- **warpd** — keyboard-driven pointer control (`linux/warpd/config`).
- **cliphist** — clipboard history, fed by `wl-paste --watch`; browse/restore
  via fuzzel (Mod+Shift+C).
- Also patches `systemd --user`'s `PATH` (`environment.d/zz-nix-path.conf`) so
  units spawned by niri can find Nix-installed binaries — see the
  Troubleshooting section below.

Power management (AC/battery profiles) is handled system-wide by TLP
(`hosts/linux/ubuntu-apt-deps.sh`), not by home-manager.

### qutebrowser — `modules/home/qutebrowser.nix` (config only)
Config (`shared/qutebrowser/config.py`, `quickmarks`, `bookmarks/urls`) is shared
across platforms, but the *package* is per-host:
- macOS: plain Nix package.
- Ubuntu: **not** from Nix — same EGL/GPU mismatch as kitty, but fatal here
  (the window never paints). Installed into a pip venv instead via
  `hosts/linux/ubuntu-qutebrowser-venv.sh` (`make qutebrowser-venv`), with a
  shell alias in `hosts/linux/ubuntu.nix` pointing at the venv binary.

### fcitx5 — `modules/home/fcitx5.nix` (Ubuntu only, config only)
Vietnamese input via the fcitx5-lotus (Unikey-style) addon —
`linux/fcitx5/conf/lotus.conf` for its typing behavior (Telex, spell-check, macros,
mode hotkeys) and `linux/fcitx5/config` for global fcitx5 settings. `profile` is
seeded once on first run (`home.activation`) and then left alone — fcitx5
rewrites it at runtime to record the active input method, so it can't be a
managed symlink. The package and GTK/Qt frontend modules stay apt-installed
(`make apt-deps`) since they need to register into system-wide immodule paths
a user-level Nix profile can't reach.

> `lotus.conf`'s `Mode` is set to `Preedit`, not one of the `Uinput`
> variants — the Uinput modes need raw keyboard device access, which kanata
> already holds exclusively, so Lotus's composition/hotkeys silently no-op
> under it. Preedit composes over fcitx5's Wayland text-input protocol and
> doesn't compete with kanata for the device. (`Surrounding Text` would too,
> but niri's text-input relay never advertises that capability, so it
> silently produces nothing — see `linux/fcitx5/conf/lotus.conf`.)

### TUI tools — `modules/home/tui-tools.nix` (Ubuntu only)
`btop` (`shared/btop/btop.conf`) and `superfile` (`shared/superfile/config.toml`,
`hotkeys.toml`).

### Podman — `modules/home/podman.nix` (Ubuntu only)
Rootless Podman with a Docker-API-compatible socket
(`$XDG_RUNTIME_DIR/podman/podman.sock`), so Docker-SDK tools (e.g. lazydocker)
work against it transparently. Aliases `docker` to `podman`.

## Platform Details

Every platform shares `modules/home/default.nix` (shell, editor, terminal,
git, files — see Component Setup above) via `corePackages`/`devPackages` in
`flake.nix`. What differs is the platform glue in `modules/platforms/` and the
per-host file in `hosts/<platform>/`.

### macOS — `hosts/darwin/example-macbook.nix`
nix-darwin, not home-manager standalone — `flake.nix`'s
`darwinConfigurations` wires `home-manager.darwinModules.home-manager` in
directly.
- kitty config comes from the shared `modules/home/kitty.nix` (imported by
  the host file), with macOS-specific options (`macos_option_as_alt`,
  titlebar color, JetBrainsMono Nerd Font) selected via its `isDarwin` branch.
- qutebrowser is the plain Nix package here (no EGL/GPU issue on macOS, unlike
  Ubuntu — see the qutebrowser component above).
- `darwinPackages` in `flake.nix` adds `clipboard-jh`, `clipse`, `mosh`, and
  the JetBrains Mono Nerd Font on top of `sharedPackages`. Mosh uses the same
  SSH configuration, keys, and SSH certificates as `ssh`; its session traffic
  additionally needs UDP ports 60000–61000 reachable on the remote host.

To add a second Mac: copy the `darwinConfigurations."nathan-macbook"` stanza
in `flake.nix`, point it at a new `hosts/darwin/<hostname>.nix`.

### Termux — `hosts/linux/termux.nix`
Standalone home-manager targeting `aarch64-linux`, home directory
`/data/data/com.termux/files/home`. Forces `nix.package` back to plain
`pkgs.nix` (overriding whatever `linux.nix` defaults to) and sets
`$TMPDIR`/`$EDITOR`/`$VISUAL`/`$PAGER` to Termux-appropriate paths/values.
`termux/` holds Termux-app-level config (not home-manager-managed):
`termux.properties` and `colors.dark.properties`/`colors.eink.properties`
color schemes, applied by symlinking/copying into `~/.termux/` per Termux's
own conventions.

### Android — `hosts/android/default.nix` (nix-on-droid)
A nix-on-droid config, not standalone home-manager — packages must go through
`environment.packages` rather than `home.packages` (forced to `[ ]` here) to
avoid nix-env/nix-profile conflicts on Android. `programs.neovim`,
`programs.tmux`, and `programs.lazygit` are all force-disabled for the same
reason; tmux gets its config via a plain file symlink instead
(`home.file.".config/tmux/tmux.conf"`) and neovim/lazygit are expected to come
from `environment.packages` directly. Sets `$TMPDIR`, forces `TERM` to
`xterm-256color` over SSH, and defaults `$EDITOR`/`$VISUAL`/`$PAGER` since the
usual home-manager `programs.*` wiring is disabled.

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

# macOS only, on top of sharedPackages:
darwinPackages = pkgs: with pkgs; [ clipboard-jh clipse ... ];
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
