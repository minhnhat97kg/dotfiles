# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Summary
Cross-platform Nix configuration for macOS (nix-darwin), Linux (NixOS), and Android (nix-on-droid + vanilla Termux Nix). Manages dotfiles, system configuration, and secrets encryption using sops/age.

## Tech Stack
- **Build System**: Nix flakes, Makefile
- **Platforms**: nix-darwin (macOS), NixOS (Linux), nix-on-droid (Android), home-manager (Termux)
- **Secrets**: sops + age encryption
- **Editor**: Neovim with LSP (Lua, TypeScript, Go, Rust, Java)
- **Shell**: Zsh + oh-my-zsh
- **Terminal**: Tmux + Kitty
- **macOS Window Management**: Yabai, skhd, Sketchybar, JankyBorders, Kanata

## Repository Structure
```
dotfiles/
├── flake.nix              # Main entry point with username/email config
├── Makefile               # Commands: install/build/encrypt/decrypt
├── CLAUDE.md              # Project context for Claude Code
├── modules/
│   ├── darwin.nix         # macOS system config
│   ├── linux.nix          # Linux/NixOS system config
│   ├── android.nix        # Android nix-on-droid config (full)
│   ├── android-lite.nix   # Android nix-on-droid config (battery-optimized)
│   ├── termux.nix         # Android vanilla Termux+Nix config
│   └── shared.nix         # Shared home-manager config
├── docs/                  # Documentation
│   ├── progress.md        # Project progress tracking
│   ├── workflow.md        # Development workflow
│   ├── termux-nix-setup.md # Termux vanilla Nix setup guide
│   └── tableplus-to-nvim-db.md
├── scripts/               # Shell scripts (copied to ~/.scripts/)
│   ├── secrets-sync.sh    # Encrypt secrets to sops format
│   ├── secrets-decrypt.sh # Decrypt secrets from sops
│   ├── load-aliases.sh    # Load shell aliases
│   ├── claude-init.sh     # Initialize Claude Code in projects
│   ├── bootstrap-termux-nix.sh # Bootstrap vanilla Nix in Termux
│   ├── cycle-layout.sh    # Cycle yabai layouts
│   ├── toggle-kitty-window.sh  # Toggle floating kitty windows
│   ├── clipse-wrapper.sh  # Clipboard manager wrapper
│   ├── ssh-*.sh           # SSH tunnel and password helpers
│   ├── window-picker.sh   # Window selection UI
│   └── swagger-to-kulala/ # Go tool: Convert OpenAPI/Swagger to kulala.nvim HTTP files
│       ├── main.go
│       ├── go.mod
│       ├── go.sum
│       └── README.md
├── templates/
│   └── claude-code/       # Claude Code project templates
│       ├── CLAUDE.md.template
│       └── docs/          # Template documentation
├── nvim/                  # Neovim configuration
│   ├── init.lua
│   ├── lsp/               # LSP configurations
│   └── ftplugin/          # Filetype plugins
├── kitty/                 # Kitty terminal config
├── git/                   # Git configurations
├── lazygit/               # Lazygit TUI config
├── qutebrowser/           # Qutebrowser browser config
│   ├── qb-picker          # Profile picker script
│   └── qb-picker-gui      # GUI profile picker
├── shell/                 # Shell configuration
│   ├── aliases.yaml.example
│   └── zshrc
├── yabai/                 # Yabai window manager
├── skhd/                  # skhd hotkey daemon
├── sketchybar/            # Sketchybar status bar
├── secrets/encrypted/     # sops-encrypted secrets
│   ├── ssh/               # SSH keys and tunnels
│   └── aws/               # AWS credentials
└── sql/                   # SQL configurations
```

## Key Paths
- Main config: `flake.nix` (username, email, package lists)
- Platform configs:
  - macOS: `modules/darwin.nix`
  - Linux: `modules/linux.nix`
  - Android nix-on-droid: `modules/android.nix`, `modules/android-lite.nix`
  - Android Termux Nix: `modules/termux.nix`
- Shared home config: `modules/shared.nix`
- Neovim: `nvim/init.lua`, `nvim/lsp/`, `nvim/ftplugin/`
- Secrets: `secrets/encrypted/ssh/`, `secrets/encrypted/aws/`
- Age key: `~/.config/sops/age/keys.txt`
- Bootstrap scripts: `scripts/bootstrap-termux-nix.sh`

## Architecture Overview

### Build System Flow
1. **Makefile** - Entry point for common operations, auto-detects platform
2. **flake.nix** - Central configuration defining:
   - User settings (username, email)
   - Package lists (shared, platform-specific)
   - Platform outputs (darwinConfigurations, nixosConfigurations, nixOnDroidConfigurations)
3. **modules/** - Platform-specific Nix modules:
   - `shared.nix` - home-manager config used across all platforms (tmux, zsh, neovim)
   - `darwin.nix` - macOS system config (yabai, skhd, sketchybar, homebrew)
   - `linux.nix` - NixOS system config (GNOME, systemd, hardware)
   - `android.nix` - nix-on-droid config (SSH server, mobile-optimized)

### Secrets Architecture
- **Encryption**: sops-nix encrypts files using age asymmetric encryption
- **Key location**: `~/.config/sops/age/keys.txt` (single private key)
- **Config**: `secrets/config.yaml` defines source/destination mappings
- **Encrypted storage**: `secrets/encrypted/` directory (committed to git)
- **Scripts**:
  - `secrets-sync.sh` - Read config.yaml, encrypt sources to encrypted/
  - `secrets-decrypt.sh` - Read config.yaml, decrypt to destinations
  - Format: Kubernetes Secret YAML with base64-encoded data

### Package Management Strategy
- **sharedPackages** in flake.nix - Cross-platform tools (git, fzf, neovim, go, rust)
- **darwinPackages** in flake.nix - macOS-only (clipboard-jh, JetBrains Mono font)
- **linuxPackages** in flake.nix - Linux-only (xclip, wl-clipboard)
- Platform-specific system packages in respective modules/*.nix files

## Common Commands

### Build & Deploy
```bash
make install      # Auto-detect platform and apply configuration
make darwin       # Apply macOS config (darwin-rebuild switch)
make linux        # Apply NixOS config (nixos-rebuild switch)
make android      # Apply Android nix-on-droid config (full)
make android-lite # Apply Android nix-on-droid config (battery-optimized)
make termux       # Apply Termux vanilla Nix config (home-manager)
make build        # Build without applying (dry run)
```

### Secrets Management
```bash
make deps         # Install yq-go and age if missing
make encrypt      # Encrypt all secrets from sources defined in secrets/config.yaml
make decrypt      # Decrypt all secrets to destinations
make decrypt-yes  # Decrypt without confirmation prompt
```

### Maintenance
```bash
make update       # Update flake inputs (nixpkgs, nix-darwin, etc.)
make format       # Format all nix files with alejandra
make check        # Validate flake configuration
make clean        # Remove build artifacts
```

### API Development with kulala.nvim
```bash
# Convert OpenAPI/Swagger YAML to HTTP request files
swagger-to-kulala -i api.yaml                  # Output to stdout
swagger-to-kulala -i api.yaml -o api.http      # Save to file
swagger-to-kulala -i api.yaml -o output/ -split # Split by tags

# Use in Neovim with kulala.nvim plugin
# - Open .http file in nvim
# - Place cursor on request
# - Execute with kulala commands (e.g., :lua require('kulala').run())
```

## Code Style & Conventions
- **Nix**: 2-space indentation, use `with pkgs;` for package lists
- **Lua (Neovim)**: 2-space indentation, prefer explicit over implicit
- **Shell scripts**: Use bash with set -euo pipefail
- **Naming**: kebab-case for files/directories, camelCase for Nix attributes

## Documentation Guidelines
- **IMPORTANT**: Any structural change, new feature, or significant modification MUST update CLAUDE.md
  - Add new files/directories to "Repository Structure"
  - Document new scripts with descriptions
  - Update "Recent Changes" section with what changed and why
  - Update relevant sections (Key Paths, Common Operations, etc.)
- Keep CLAUDE.md as the single source of truth for project context
- This ensures Claude Code and future contributors have accurate information

## Recent Changes

### 2025-12-23: Termux Vanilla Nix Support
**What changed:**
- Added support for running vanilla Nix in regular Termux (without nix-on-droid app)
- New configuration module: `modules/termux.nix` using home-manager directly
- Bootstrap script: `scripts/bootstrap-termux-nix.sh` for automated Nix installation
- Comprehensive documentation: `docs/termux-nix-setup.md`
- New Makefile target: `make termux`
- Updated `flake.nix` with `homeConfigurations.termux` output

**Why:**
- Provides a lighter alternative to nix-on-droid for users who want simplicity
- Avoids proot overhead for better performance
- Allows using Termux packages alongside Nix packages
- Better compatibility with native Termux environment
- Standard home-manager workflow familiar to Nix users

**Key differences from nix-on-droid:**
- Uses home-manager instead of nix-on-droid module system
- Packages in `home.packages` instead of `environment.packages`
- No system-level configuration (user-only)
- Faster boot time and better performance
- Can coexist with Termux package manager

**How to use:**
```bash
# In regular Termux (not nix-on-droid):
bash scripts/bootstrap-termux-nix.sh
make termux
```

**Documentation:**
- Setup guide: `docs/termux-nix-setup.md`
- Configuration: `modules/termux.nix`
- Platform comparison table in setup guide

## Platform-Specific Notes

### macOS (nix-darwin)
- Yabai scripting addition requires SIP partially disabled on Apple Silicon
- skhd requires Accessibility permission (System Settings > Privacy)
- Kitty terminal installed via Homebrew (cask), config managed by Nix
- After `make install`, yabai LaunchDaemon is automatically reloaded

### Linux (NixOS)
- Hardware configuration must be generated per-machine: `nixos-generate-config`
- Import hardware-configuration.nix in modules/linux.nix
- Desktop environment: GNOME by default (can switch to KDE/i3 in modules/linux.nix)

### Android (nix-on-droid)
- Install nix-on-droid app from F-Droid
- Runs in proot environment with system-level configuration
- Two configs: full (`android.nix`) and lite (`android-lite.nix`)
- SSH server auto-configured with generated keys
- Limitations: Some syscalls don't work (setuid/setgid), Xvfb requires Termux workaround
- See X11/VNC Setup section below for GUI apps

### Android (Termux + vanilla Nix)
- Install Nix directly in regular Termux (not nix-on-droid app)
- Bootstrap: `bash scripts/bootstrap-termux-nix.sh`
- Uses home-manager instead of nix-on-droid framework
- Simpler, faster, better Termux package compatibility
- Can use `pkg` and Nix side-by-side
- See `docs/termux-nix-setup.md` for complete guide

## Important Implementation Details

### Tmux + Neovim Integration
- Seamless navigation between tmux panes and neovim splits using Ctrl+h/j/k/l
- Achieved via `is_vim` detection in tmux config (modules/shared.nix:37-41)
- Tmux pane resize: prefix+h/j/k/l OR Ctrl+Shift+h/j/k/l (no prefix)

### Kitty + skhd Integration
- Kitty must pass through system keybindings to allow skhd to work
- Critical: `cmd+j/k` for space switching, `cmd+r` for reload
- CSI-u protocol disabled to prevent conflicts (kitty/kitty.conf:92)

### Zsh Alias Loading
- Shell aliases dynamically loaded from YAML via `load-aliases.sh`
- Called in zsh initContent (modules/shared.nix:76-79)
- Template: `shell/aliases.yaml.example`

### Work/Personal Git Config Split
- work.gitconfig is optional (conditionally included in git config)
- Build doesn't fail if missing - allows public dotfiles with private work config

## Development Workflow

### Adding New Packages
1. **Shared (all platforms)**: Add to `sharedPackages` list in `flake.nix`
2. **Platform-specific**: Add to `darwinPackages` or `linuxPackages` in `flake.nix`
3. **System-level (nix-darwin/NixOS/nix-on-droid)**: Add to environment.systemPackages in `modules/{darwin,linux,android}.nix`
4. **User-level (Termux)**: Add to `home.packages` in `modules/termux.nix`
5. Apply changes:
   - macOS: `make darwin`
   - Linux: `make linux`
   - Android (nix-on-droid): `make android` or `make android-lite`
   - Android (Termux Nix): `make termux`

### Testing Configuration Changes
```bash
make build        # Build without applying to test for errors
make check        # Validate flake syntax and structure
nix flake check   # Run all flake checks including NixOS tests
```

### Secrets Workflow
```bash
# First time setup
make deps                           # Install dependencies
make gen-key                        # Generate age key

# Edit secrets/config.yaml to define new source/destination mappings
# Add files to source directories (e.g., ~/.ssh/new_key)
make encrypt                        # Encrypt to secrets/encrypted/

# On new machine or after pulling changes
make decrypt                        # Decrypt secrets to destinations
# Or decrypt-yes for non-interactive mode
```

### Custom Go Tools
The repo includes `swagger-to-kulala` built via Nix:
- Source: `scripts/swagger-to-kulala/main.go`
- Built in flake.nix using buildGoModule
- vendorHash must be updated when go.mod changes
- Installed to PATH automatically via flake outputs

## Keybindings

**See [KEYBINDINGS.md](KEYBINDINGS.md) for complete reference**

Quick essentials:
- **Tmux navigate**: `Ctrl+h/j/k/l` (vim-aware, seamless with Neovim)
- **Tmux resize**: `Ctrl-b h/j/k/l` or `Ctrl+Shift+h/j/k/l`
- **Tmux windows**: `Alt+,` / `Alt+.`
- **Yabai spaces**: `Cmd+j/k`
- **Show all**: `Alt+Shift+/` (macOS only)

## Claude Code Workflow

This repo includes a global `claude-init` command for initializing token-efficient Claude Code workflows in any project:
```bash
claude-init [directory]  # Creates CLAUDE.md + docs/ structure
```
- Templates: `templates/claude-code/`
- Implementation: `scripts/claude-init.sh`
- Installed to PATH via `modules/shared.nix`

## X11/VNC Setup (Android/nix-on-droid)

### Overview
The Android configuration supports GUI applications via two methods:
1. **Termux-X11** (recommended): Native Android X11 implementation
2. **VNC Server** (hybrid): Termux VNC + nix x11vnc

Both methods work around [nix-on-droid issue #75](https://github.com/nix-community/nix-on-droid/issues/75) (missing `setgid()`/`setuid()` syscalls in proot) by running the X server in Termux, not in nix-on-droid.

### Architecture

**Termux-X11 Method (Primary):**
- X server runs in Termux (outside nix-on-droid proot)
- Nix GUI apps connect via `DISPLAY=127.0.0.1:1` over loopback
- Requires: Termux + termux-x11-nightly package + Termux-X11 app
- **Status**: ✅ Fully functional

**VNC Method (Alternative):**
- ⚠️ **Important**: Xvfb cannot run inside nix-on-droid proot due to missing setgid/setuid syscalls
- **Working approach**: Run Xvfb in Termux, use x11vnc from nix to share it
- Command (in Termux): `Xvfb :1 -screen 0 1920x1080x24 &`
- Command (in nix): `x11vnc -display 127.0.0.1:1 -passwd PASSWORD -rfbport 5901`
- **Status**: ⚠️ Scripts provided but require manual Termux Xvfb setup

### Quick Start

**Termux-X11:**
```bash
# 1. In Termux terminal:
pkg install termux-x11-nightly
termux-x11 :1 -listen tcp -ac &

# 2. In nix-on-droid:
~/start-x11            # Launches fluxbox + xterm
# OR
~/start-x11 firefox    # Launch specific app
```

**VNC (Hybrid Termux + Nix):**
```bash
# 1. In Termux terminal:
pkg install x11-repo xorg-xvfb
Xvfb :1 -screen 0 1920x1080x24 -ac &

# 2. In nix-on-droid:
export DISPLAY=127.0.0.1:1
x11vnc -display :1 -rfbauth ~/.vnc/passwd -rfbport 5901 -forever -shared &

# 3. Start window manager and apps:
fluxbox &
xterm &

# Connect via VNC client: vnc://<device-ip>:5901
# Default password: vnc123 (change with: x11vnc -storepasswd)

# Note: ~/.vnc/start-vnc.sh attempts to run Xvfb in nix but will fail due to proot limitations
```

### File Locations
- Termux-X11 scripts: `~/.termux-x11/`
  - `connect.sh` - GUI launcher
  - `ssh-run.sh` - SSH helper for remote GUI launch
  - `README.md` - Setup guide
- VNC scripts: `~/.vnc/`
  - `start-vnc.sh`, `stop-vnc.sh`, `status-vnc.sh`
  - `xstartup` - Session startup script
  - Logs: `xvfb.log`, `x11vnc.log`, `fluxbox.log`
- Symlinks:
  - `~/start-x11` → `~/.termux-x11/connect.sh`
  - `~/termux-x11` → `~/.termux-x11/ssh-run.sh`

### Installed GUI Packages
- **Window Manager**: fluxbox
- **Terminal**: xterm
- **X11 Libraries**: libX11, libXext, libXrender, xauth, xinit, xhost
- **VNC Server**: x11vnc

### SSH + X11 Integration
SSH server is configured with X11 forwarding enabled:
```bash
~/.ssh/start-sshd.sh   # Starts SSH on port 8022
ssh -p 8022 -X nix-on-droid@<ip>  # Connect with X11 forwarding
```

Then use `~/termux-x11 <app>` to launch GUI apps that display on the Android screen.

### Troubleshooting

**Termux-X11 connection fails:**
- Ensure Termux-X11 app is running (shows black screen is normal)
- Verify `termux-x11 :1 -listen tcp -ac` is running in Termux
- Check DISPLAY is set: `echo $DISPLAY` should show `127.0.0.1:1`

**VNC won't start:**
- **Known issue**: Xvfb cannot run inside nix-on-droid proot (issue #75)
  - Error: `Failed to activate virtual core keyboard: 2`
  - Cause: Missing `setgid()`/`setuid()` syscalls in proot environment
  - **Solution**: Run Xvfb in Termux, not nix-on-droid (see VNC Hybrid method above)
- Check logs: `cat ~/.vnc/xvfb.log` and `cat ~/.vnc/x11vnc.log`
- Remove stale locks: `rm -f /tmp/.X1-lock /tmp/.X11-unix/X1`
- Verify no conflicting processes: `pgrep -fa Xvfb`

**GUI apps don't display:**
- Test X connection: `xdpyinfo` (should show display info)
- For Termux-X11: Ensure Android app is in foreground
- For VNC: Verify VNC client is connected to correct port

### Implementation Details (modules/android.nix)

**Lines 101-121**: Package installation
- X11 libraries and tools
- Fluxbox window manager
- xterm terminal
- x11vnc server

**Lines 243-356**: Termux-X11 build activation
- Creates helper scripts in `~/.termux-x11/`
- Sets up symlinks for easy access
- Generates README with setup instructions

**Lines 358-558**: VNC build activation
- Generates VNC password file
- Creates Xvfb + x11vnc startup script
- Sets up desktop session files for TigerVNC compatibility
- Creates start/stop/status helper scripts

**Lines 185-188**: SSH X11 forwarding config
```nix
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes
XAuthLocation ${pkgs.xorg.xauth}/bin/xauth
```