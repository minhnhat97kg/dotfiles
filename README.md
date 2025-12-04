# Cross-Platform Dotfiles

Nix configuration for **macOS** (nix-darwin), **Linux** (NixOS), and **Android** (nix-on-droid).

## Structure

```
dotfiles/
├── flake.nix                 # Main configuration entry
├── Makefile                  # Build/encrypt/decrypt commands
├── modules/
│   ├── darwin.nix            # macOS system config
│   ├── linux.nix             # Linux/NixOS system config
│   ├── android.nix           # Android system config
│   └── shared.nix            # Shared home-manager config
├── kitty/                    # Terminal emulator
├── git/                      # Git configuration
├── lazygit/                  # Lazygit TUI
├── nvim/                     # Neovim configuration
│   ├── init.lua
│   ├── lsp/                  # LSP configs (lua, ts, go)
│   └── ftplugin/             # Filetype plugins
├── pspg/                     # PostgreSQL pager
├── qutebrowser/              # Browser config
├── shell/                    # Shell dotfiles
├── sketchybar/               # macOS status bar
├── skhd/                     # macOS hotkey daemon
├── scripts/
│   ├── secrets-sync.sh       # Encrypt secrets to sops format
│   └── load-aliases.sh       # Load shell aliases
└── secrets/
    └── encrypted/            # sops-encrypted secrets
        ├── ssh/
        └── aws/
```

## Quick Start

### macOS

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install)

# Clone and apply
git clone <repo> ~/projects/dotfiles
cd ~/projects/dotfiles
make install
```

### Linux (NixOS)

```bash
# Install NixOS from ISO: https://nixos.org/download.html

# After installation, clone the repo
git clone <repo> ~/dotfiles
cd ~/dotfiles

# Customize hardware configuration
# Copy your hardware-configuration.nix or generate one:
# sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# Create a hardware config by adding this to modules/linux.nix:
# imports = [ ./hardware-configuration.nix ];

# Apply configuration
make install
# or
sudo nixos-rebuild switch --flake .#nixos
```

### Android (Nix-on-Droid)

```bash
# Install from F-Droid: https://f-droid.org/packages/com.termux.nix/
git clone <repo> ~/dotfiles
cd ~/dotfiles
nix-on-droid switch --flake .
```

## Makefile Commands

```bash
make help              # Show all commands

# Configuration
make install           # Apply configuration (auto-detect platform)
make darwin            # Apply macOS config
make linux             # Apply Linux/NixOS config
make android           # Apply Android config
make build             # Build without applying

# Secrets management
make encrypt           # Encrypt all secrets (SSH, AWS, Git)
make encrypt-ssh       # Encrypt SSH keys from ~/.ssh
make encrypt-aws       # Encrypt AWS config from ~/.aws
make decrypt           # Decrypt all secrets
make list-secrets      # List encrypted files

# Maintenance
make check             # Check flake configuration
make update            # Update flake inputs
make format            # Format nix files
make clean             # Clean build artifacts
make gen-key           # Generate/import age key

# Claude Code
claude-init [dir]      # Initialize token-saving workflow in any project
```

## Keybindings

**📖 See [KEYBINDINGS.md](KEYBINDINGS.md) for complete keyboard shortcuts reference**

Quick overview:
- **Tmux resize panes**: `Alt+h/j/k/l` (no prefix needed)
- **Tmux switch windows**: `Alt+,` / `Alt+.`
- **Tmux navigate panes**: `Ctrl+h/j/k/l` (vim-aware)
- **Window manager help**: `Alt+Shift+/` (show all bindings)

## Claude Code Workflow

This dotfiles repo includes a global token-saving workflow for Claude Code that you can use in **any project**.

### Quick Start

```bash
# Initialize in current directory
claude-init

# Or initialize in specific directory
claude-init ~/projects/my-app
```

This creates:
- `CLAUDE.md` - Core project context (<5,000 tokens)
- `docs/progress.md` - Session history tracking
- `docs/workflow.md` - Workflow guide

### Usage

**Start a session:**
```
@CLAUDE.md
@docs/progress.md
```

**During session:**
```
/compact focus on code changes and decisions
```

**End session:**
1. Run `/compact focus on code samples, decisions, and next steps`
2. Append summary to `docs/progress.md`

See `docs/workflow.md` in any initialized project for detailed instructions.

## Features

### Shared (All Platforms)
- **Editor**: Neovim with LSP (Lua, TypeScript, Go, Rust, Java)
- **Terminal**: Tmux with vim navigation and easy pane resizing
- **Shell**: Zsh + oh-my-zsh
- **Languages**: Node.js, Go, Rust, Python, Java (Maven/Gradle)
- **Tools**: fzf, ripgrep, fd, jq, lazygit, direnv
- **Databases**: PostgreSQL 16, MySQL 8.0, pgcli, mycli, pspg
- **HTTP**: httpie, hurl

### Platform-Specific Packages
Some packages are platform-specific and automatically selected:
- **macOS**: `clipboard-jh` for clipboard management
- **Linux**: `xclip` (X11) and `wl-clipboard` (Wayland) for clipboard management

### macOS-Specific
- Yabai (window manager)
- skhd (hotkey daemon)
- Sketchybar (status bar)
- JankyBorders (window borders)
- Kitty terminal
- Kanata keyboard remapper with home row mods

### Linux-Specific
- GNOME desktop environment (default, can be switched to KDE/i3)
- NetworkManager for network management
- PipeWire for audio
- Docker support (optional)
- Kitty terminal
- Full systemd integration
- Kanata keyboard remapper with home row mods

### Android-Specific
- SSH server with auto-generated keys
- Optimized for Termux environment
- Mobile-friendly configuration

## Secrets Management

Secrets are encrypted with [sops](https://github.com/getsops/sops) using age encryption.

### First-time Setup

```bash
# Generate age key
make gen-key

# Encrypt your secrets
make encrypt
```

### Encrypt Secrets

```bash
# Encrypt all
make encrypt

# Encrypt specific directories
make encrypt-ssh                    # ~/.ssh
make encrypt-aws                    # ~/.aws
make encrypt-custom DIR=/path/to    # Custom directory
```

### Decrypt Secrets

```bash
# Decrypt all
make decrypt

# Decrypt to specific locations
make decrypt-ssh SSH_DIR=~/.ssh
make decrypt-aws AWS_DIR=~/.aws
```

## Customization

### Change Username

Edit `flake.nix`:
```nix
username = "your-username";
useremail = "your-email@example.com";
```

### Add Packages

**Shared packages (all platforms)** - Edit `sharedPackages` in `flake.nix`:
```nix
sharedPackages = pkgs: with pkgs; [
  git fzf ripgrep
  # Add packages here
];
```

**Platform-specific packages**:
- macOS only: Edit `darwinPackages` in `flake.nix`
- Linux only: Edit `linuxPackages` in `flake.nix`

### Platform-Specific

**macOS** - Edit `modules/darwin.nix`:
```nix
environment.systemPackages = with pkgs; [
  your-package
];
```

**Linux** - Edit `modules/linux.nix`:
```nix
environment.systemPackages = with pkgs; [
  your-package
];
```

**Android** - Edit `modules/android.nix`:
```nix
environment.packages = with pkgs; [
  your-package
];
```

## Yabai Setup (Apple Silicon)

Yabai requires SIP to be partially disabled for full functionality:

```bash
# Boot into Recovery Mode (hold Power button)
csrutil disable
nvram boot-args=-arm64e_preview_abi

# After reboot
sudo yabai --install-sa
sudo yabai --load-sa
```

## Troubleshooting

### macOS: darwin-rebuild not found

```bash
nix run nix-darwin -- switch --flake .
```

### macOS: skhd not in Accessibility settings

```bash
# Find skhd path
readlink -f /run/current-system/sw/bin/skhd

# Run manually to trigger permission dialog
/nix/store/XXX-skhd-X.X.X/bin/skhd -c /etc/skhdrc

# Grant permission in System Settings > Privacy > Accessibility
# Then restart
launchctl kickstart -k gui/$(id -u)/org.nixos.skhd
```

### Linux: Hardware configuration missing

```bash
# Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > modules/hardware-configuration.nix

# Add to modules/linux.nix:
# imports = [ ./hardware-configuration.nix ];

# Rebuild
sudo nixos-rebuild switch --flake .
```

### Linux: Change desktop environment

Edit `modules/linux.nix` and comment/uncomment the desired desktop:

```nix
# For KDE Plasma
services.xserver.displayManager.sddm.enable = true;
services.xserver.desktopManager.plasma5.enable = true;

# For i3 tiling WM
services.xserver.windowManager.i3.enable = true;
```

### Secrets decryption fails

```bash
# Ensure age key exists
ls ~/.config/sops/age/keys.txt

# Test decryption
make test-decrypt
```

## Maintenance

```bash
# Update flake inputs
make update

# Format nix files
make format

# Garbage collection
nix-collect-garbage -d
```

## License

MIT
