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

## Common Commands

```bash
# Configuration
make install           # Apply configuration (auto-detect platform)
make build             # Build without applying

# Secrets
make encrypt           # Encrypt all secrets
make decrypt           # Decrypt all secrets

# Maintenance
make update            # Update flake inputs
make help              # Show all available commands
```

**See CLAUDE.md for complete command reference and detailed documentation**

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete project reference for Claude Code
- **[KEYBINDINGS.md](KEYBINDINGS.md)** - Keyboard shortcuts reference
- **[docs/](docs/)** - Additional guides (Android desktop, battery optimization, etc.)

## Features

- **Cross-platform**: macOS (nix-darwin), Linux (NixOS), Android (nix-on-droid)
- **Editor**: Neovim with LSP support
- **Terminal**: Tmux + Kitty with vim-aware navigation
- **Shell**: Zsh + oh-my-zsh
- **Development**: Go, Rust, Python, Node.js, Java
- **Secrets**: Encrypted with sops/age
- **macOS**: Yabai, skhd, Sketchybar window management
- **Android**: XFCE4 desktop environment via VNC

**See CLAUDE.md for complete feature list**

## Customization

Edit `flake.nix` to change username, email, or add packages:

```nix
username = "your-username";
useremail = "your-email@example.com";

# Add to sharedPackages for all platforms
sharedPackages = pkgs: with pkgs; [
  git fzf ripgrep
  # Add your packages here
];
```

**See CLAUDE.md for detailed customization guide**

## Troubleshooting

**See CLAUDE.md for detailed troubleshooting guide**

Common issues:
- macOS: `darwin-rebuild` not found → `nix run nix-darwin -- switch --flake .`
- macOS: skhd permissions → Grant Accessibility in System Settings
- Linux: Hardware config missing → `nixos-generate-config`
- Secrets fail → Check `~/.config/sops/age/keys.txt` exists

## License

MIT
