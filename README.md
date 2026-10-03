# Cross-Platform Dotfiles

Nix configuration for **macOS** (nix-darwin), **Linux** (standalone home-manager —
Ubuntu), **Termux**, and **Android** (nix-on-droid). One flake, one set of
package lists, per-host overrides for anything machine-specific.

## Structure

### How the pieces fit

A machine's configuration is built from four layers, each in its own place:

```
flake.nix ──► modules/platforms/<os>.nix ──► hosts/<os>/<host>.nix ──► modules/home/*.nix ──► shared/, linux/
  outputs       how this OS runs Nix           which machine             what gets installed      the real config
                (home-manager, nix-darwin,     (user, home dir,          and where its config     files, linked
                 nix-on-droid)                  which roles)             is linked                into ~
```

1. **`flake.nix`**: the entry point. It declares the inputs (nixpkgs,
   home-manager, nix-darwin, nix-on-droid, Caelestia, nixGL) and one output per
   machine: `homeConfigurations.{ubuntu,termux}`,
   `darwinConfigurations.nathan-macbook` and `nixOnDroidConfigurations.default`.
   It doesn't hold any configuration itself.
2. **`modules/platforms/`**: one file per way of running Nix. `linux.nix` is
   standalone home-manager (Ubuntu, Termux), `darwin.nix` is nix-darwin system
   settings, and `android.nix` is nix-on-droid (with its own package list,
   because home-manager packages don't work there).
3. **`hosts/`**: one file per machine, kept small. It sets the user and home
   directory and imports the roles that machine needs. `hosts/linux/ubuntu.nix`,
   for example, is just identity plus `modules/home/linux-desktop.nix`. Scripts
   that need root and only run on one machine (apt packages, fonts) sit next to
   its host file.
4. **`modules/home/`**: home-manager modules, one per tool or role. Each one
   installs what it needs and links its config from `shared/` or `linux/` into
   `~`. `default.nix` is the base every machine imports.
5. **`shared/` and `linux/`**: the config files themselves (`init.lua`,
   `tmux.conf`, `config.kdl`, ...), in each tool's native format, linked
   unchanged. Editing them and running `make install` is all it takes.
   `shared/` is used on more than one platform, `linux/` only by the niri desktop.

Package lists live in **`packages.nix`** so every host draws from the same
lists: `corePackages` + `devPackages` (together `sharedPackages`) on every
host, `linuxDesktopPackages` on the niri desktop, `darwinPackages` on macOS.

### Which modules each host gets

| Module | Ubuntu | macOS | Termux | Android |
|---|:-:|:-:|:-:|:-:|
| `default.nix`: shell, editor, terminal, git, files | ✓ | ✓ | ✓ | ✓ |
| `kitty.nix` | ✓ | ✓ | | |
| `linux-desktop.nix`: niri, gtk, fcitx5, qutebrowser, podman, tui-tools | ✓ | | | |

### Where to change things

| To change… | Edit |
|---|---|
| A package on every machine | `packages.nix` (`corePackages` / `devPackages`) |
| A tool's settings (nvim, tmux, kitty, git, niri, ...) | its file under `shared/` or `linux/` |
| Colours of the whole desktop | `shared/theme/theme.nix` |
| Keybindings of the desktop | `linux/niri/config.kdl` (list in `linux/niri/keybindings.md`) |
| One machine only | `hosts/<os>/<host>.nix` |
| A new machine | new host file + an output in `flake.nix` (see Platform Details) |

### File tree

```
dotfiles/
├── flake.nix                   # Inputs + one output per machine
├── packages.nix                # Package lists (core, dev, linuxDesktop, darwin)
├── Makefile                    # install / update / apt-deps / qutebrowser-venv / sf-fonts
├── bootstrap.sh                # Installs Nix + clones this repo
│
├── modules/
│   ├── platforms/              # How each OS runs Nix: linux.nix, darwin.nix, android.nix
│   └── home/                   # home-manager modules
│       ├── default.nix         # Base for every host: imports the five below + sharedPackages
│       ├── shell.nix           #   zsh + oh-my-zsh
│       ├── editor.nix          #   Neovim (built from pinned source)
│       ├── terminal.nix        #   alacritty + tmux (real config, symlinked)
│       ├── git.nix             #   git config (personal/work conditional includes)
│       ├── files.nix           #   lazygit, direnv, nvim, gh-dash, jiratui, ~/.scripts
│       ├── kitty.nix           # kitty config — Ubuntu + macOS (package is per-platform)
│       ├── linux-desktop.nix   # The niri desktop role — imports the Ubuntu-only modules below
│       ├── niri.nix            #   niri + Caelestia shell + kanata/kanshi/swayidle
│       ├── gtk.nix             #   WhiteSur GTK theme, icons, cursor
│       ├── fcitx5.nix          #   Vietnamese input (config only)
│       ├── qutebrowser.nix     #   qutebrowser config
│       ├── podman.nix          #   rootless podman + docker-API socket
│       └── tui-tools.nix       #   superfile
│
├── hosts/
│   ├── linux/ubuntu.nix        # Ubuntu desktop (+ ubuntu-*.sh: apt deps, qutebrowser venv, SF fonts)
│   ├── linux/termux.nix        # Termux (standalone home-manager, aarch64)
│   ├── darwin/                 # One file per Mac (example-macbook.nix is the template)
│   └── android/default.nix     # nix-on-droid
│
├── shared/                     # Config files used on more than one platform
│   ├── nvim/                   # Neovim (init.lua, lua/, lsp/, colors/)
│   ├── tmux/                   # tmux.conf + scripts/
│   ├── git/                    # gitconfig + personal/work includes
│   ├── theme/theme.nix         # Desktop colours: mode + seed colour
│   ├── kitty/ qutebrowser/ superfile/ gh-dash/ jiratui/
│   └── scripts/                # Personal scripts, linked to ~/.scripts (on PATH)
│
├── linux/                      # Config files for the niri desktop only
│   └── niri/ kanshi/ kanata/ fcitx5/ warpd/ swaylock/
│
└── termux/                     # Termux app settings (copied by hand into ~/.termux)
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
niri + Caelestia shell + kanata + qutebrowser + tmux + rootless podman,
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
make install             # detects Termux -> home-manager switch --flake .#termux
```

Needs Nix installed inside Termux first. For a fully managed Android setup,
prefer nix-on-droid below.

### Android (nix-on-droid)

```bash
# Install from F-Droid: https://f-droid.org/packages/com.termux.nix/
git clone <repo> ~/dotfiles
cd ~/dotfiles
make install             # detects nix-on-droid -> nix-on-droid switch
# or explicitly:
make android
# or:
nix-on-droid switch --flake .
```

## Common Commands

```bash
make help              # list all commands (platform auto-detected)
make install           # apply configuration for the detected platform
make darwin            # macOS only
make linux             # Ubuntu only
make termux            # Termux only
make nix-on-droid      # Android (nix-on-droid) only (alias: make android)
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
  config-generation, which would rewrite it; the JetBrains palette is inlined)
  and `shared/tmux/scripts/` (`cycle-layout.sh`, `autosave.sh`,
  `session-picker.sh`). A bare `tmux` (or `tmux attach`) from a fresh shell
  runs `session-picker.sh` via the `tmux()` wrapper in `shell.nix`: an fzf menu
  of existing sessions plus a "new session" entry (ctrl-n new, ctrl-x kill)
  instead of unconditionally spawning a new session.
- **kitty**: config generated by `modules/home/kitty.nix` for every host
  (platform differences keyed on `isDarwin`); on Ubuntu the *package* stays apt-installed — the Nix-built
  kitty crashes on EGL init because its bundled Mesa doesn't match the host
  GPU driver (a common non-NixOS gotcha). Run `make apt-deps` once to get it.

### Git — `modules/home/git.nix` + `shared/git/`
Base `gitconfig` with conditional `includeIf` blocks for personal vs. work
identities (`shared/git/personal.gitconfig`, `shared/git/work.gitconfig.template` — copy the
template to `~/.config/git/work.gitconfig` and fill in your work email/signing
key; it's gitignored, so the flake can't link it) plus a shared `gitignore_global`.

### Files — `modules/home/files.nix`
Grab-bag of small, shared pieces:
- `programs.lazygit` (plain alias `lg`, not the zsh-integration function).
- `programs.direnv`.
- `~/.scripts/` symlinked and marked executable — anything dropped here lands
  on `PATH` via `shell.nix`.

### niri desktop stack — `modules/home/niri.nix` (Ubuntu only)
The full Wayland tiling-compositor setup, one systemd user unit per piece:
- **niri** — the compositor itself; config in `linux/niri/config.kdl` (see
  `linux/niri/keybindings.md`), plus `linux/niri/scripts/lid.sh` for lid-close/open output
  handling and `linux/niri/scripts/show-monitors.sh` for debugging output layout.
- **Caelestia shell** (Quickshell) — bar, launcher, notifications, OSD,
  dashboard, lock screen and wallpaper in one process (`caelestia.service`).
  Colours come from `shared/theme/theme.nix`; `caelestia-theme-sync` mirrors the
  active palette into tmux and niri's focus ring.
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
- **swayidle** — lock after 5 min idle, blank outputs at 5.5 min, suspend at
  30 min; `loginctl lock-session` and idle timeouts both go to the Caelestia
  lock screen. apt's swaylock (`linux/swaylock/config`) stays as an escape hatch
  if that lock ever can't unlock.
- **warpd** — keyboard-driven pointer control (`linux/warpd/config`).
- **cliphist** — clipboard history, fed by `wl-paste --watch`; browse/restore
  in the Caelestia launcher (Mod+Shift+C).
- Also patches `systemd --user`'s `PATH` (`environment.d/zz-nix-path.conf`) so
  units spawned by niri can find Nix-installed binaries — see the
  Troubleshooting section below.

Power management (AC/battery profiles) is handled system-wide by TLP
(`hosts/linux/ubuntu-apt-deps.sh`), not by home-manager.

### qutebrowser — `modules/home/qutebrowser.nix` (Ubuntu only, config only)
Config: `shared/qutebrowser/config.py`, `quickmarks`, `bookmarks/urls`.
The package is **not** from Nix — same EGL/GPU mismatch as kitty, but fatal
here (the window never paints). It is installed into a pip venv instead via
`hosts/linux/ubuntu-qutebrowser-venv.sh` (`make qutebrowser-venv`), with a
shell alias in `modules/home/linux-desktop.nix` pointing at the venv binary.

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
`superfile` config (`shared/superfile/config.toml`, `hotkeys.toml`). `btop`
is installed with its default config.

### Podman — `modules/home/podman.nix` (Ubuntu only)
Rootless Podman with a Docker-API-compatible socket
(`$XDG_RUNTIME_DIR/podman/podman.sock`), so Docker-SDK tools (e.g. lazydocker)
work against it transparently. Aliases `docker` to `podman`.

## Platform Details

Every platform shares `modules/home/default.nix` (shell, editor, terminal,
git, files — see Component Setup above) and `corePackages`/`devPackages` from
`packages.nix`. What differs is the platform glue in `modules/platforms/` and the
per-host file in `hosts/<platform>/`.

### macOS — `hosts/darwin/example-macbook.nix`
nix-darwin, not home-manager standalone — `flake.nix`'s
`darwinConfigurations` wires `home-manager.darwinModules.home-manager` in
directly.
- kitty config comes from the shared `modules/home/kitty.nix` (imported by
  the host file), with macOS-specific options (`macos_option_as_alt`,
  titlebar color, JetBrainsMono Nerd Font) selected via its `isDarwin` branch.
- `darwinPackages` in `packages.nix` adds `clipboard-jh`, `clipse`, `mosh`, and
  the JetBrains Mono Nerd Font on top of `sharedPackages`. Mosh uses the same
  SSH configuration, keys, and SSH certificates as `ssh`; its session traffic
  additionally needs UDP ports 60000–61000 reachable on the remote host.
- Homebrew is managed by `nix-homebrew` (see the `nix-homebrew` block in
  `modules/platforms/darwin.nix`): it installs/pins Homebrew itself, while the
  nix-darwin `homebrew.*` options declare packages and casks (`kitty`,
  `alacritty`). Taps stay mutable, so `brew tap`/`brew install` work as usual.
  `onActivation` runs `brew update`/upgrade on every `darwin-rebuild switch`;
  cleanup is off, so hand-installed packages are never removed.

To add a second Mac: copy the `darwinConfigurations."nathan-macbook"` stanza
in `flake.nix`, point it at a new `hosts/darwin/<hostname>.nix`.

### Termux — `hosts/linux/termux.nix`
Standalone home-manager targeting `aarch64-linux`, home directory
`/data/data/com.termux/files/home`. Forces `nix.package` back to plain
`pkgs.nix` (overriding whatever `linux.nix` defaults to) and sets
`$TMPDIR`/`$EDITOR`/`$VISUAL`/`$PAGER` to Termux-appropriate paths/values.
`termux/` holds Termux-app-level config (not managed by home-manager):
`termux.properties` and `colors.dark.properties`/`colors.eink.properties`
color schemes, applied by symlinking/copying into `~/.termux/` per Termux's
own conventions.

### Android — `hosts/android/default.nix` (nix-on-droid)
A nix-on-droid config, not standalone home-manager — packages must go through
`environment.packages` rather than `home.packages` (forced to `[ ]` here) to
avoid nix-env/nix-profile conflicts on Android. `programs.neovim`,
`programs.tmux`, and `programs.lazygit` are all force-disabled for the same
reason; tmux's config still arrives via the shared `modules/home/terminal.nix`
recursive symlink and neovim/lazygit are expected to come
from `environment.packages` directly. `neovim-src` is injected through
`home-manager.extraSpecialArgs` (nix-on-droid does not forward its own
`extraSpecialArgs` to home-manager), and the shared placeholder
`~/.ssh/authorized_keys` is unmanaged because the Android activation generates
and appends a real client key to it. Sets `$TMPDIR`, forces `TERM` to
`xterm-256color` over SSH, and defaults `$EDITOR`/`$VISUAL`/`$PAGER` since the
usual home-manager `programs.*` wiring is disabled.

## Customization

Identity is in `flake.nix`:

```nix
username = "your-username";
useremail = "your-email@example.com";
```

Package lists are in `packages.nix`:

```nix
# Installed on every platform, including Termux:
corePackages = pkgs: with pkgs; [ git fzf ripgrep ... ];

# Dev toolchains, also every platform:
devPackages = pkgs: with pkgs; [ go rustc nodejs ... ];

# Ubuntu desktop only (niri stack, browsers, containers, TUI tools):
linuxDesktopPackages = pkgs: with pkgs; [ niri kanata kanshi ... ];

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
- **macOS: `darwin-rebuild` not found** — only on the first run; `make install` falls back to
  `nix run --inputs-from . nix-darwin#darwin-rebuild -- switch --flake .` on its own.

## License

MIT
