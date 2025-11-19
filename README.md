# Cross-Platform Dotfiles

Nix configuration for **macOS** (nix-darwin) and **Android** (nix-on-droid).

## Structure

```
dotfiles/
├── flake.nix                 # Main configuration entry
├── Makefile                  # Build/encrypt/decrypt commands
├── modules/
│   ├── darwin.nix            # macOS system config
│   ├── android.nix           # Android system config
│   └── shared.nix            # Shared home-manager config
├── alacritty/                # Terminal emulator
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
```

## Features

### Shared (All Platforms)
- **Editor**: Neovim with LSP (Lua, TypeScript, Go, Rust, Java)
- **Terminal**: Tmux with vim navigation
- **Shell**: Zsh + oh-my-zsh
- **Languages**: Node.js, Go, Rust, Python, Java (Maven/Gradle)
- **Tools**: fzf, ripgrep, fd, jq, lazygit, direnv
- **Databases**: PostgreSQL, MySQL, pgcli, mycli, pspg
- **HTTP**: httpie, hurl

### macOS-Specific
- Yabai (window manager)
- skhd (hotkey daemon)
- Sketchybar (status bar)
- JankyBorders (window borders)
- Alacritty terminal

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

Edit `sharedPackages` in `flake.nix`:
```nix
sharedPackages = pkgs: with pkgs; [
  git fzf ripgrep
  # Add packages here
];
```

### Platform-Specific

**macOS** - Edit `modules/darwin.nix`:
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

### darwin-rebuild not found

```bash
nix run nix-darwin -- switch --flake .
```

### skhd not in Accessibility settings

```bash
# Find skhd path
readlink -f /run/current-system/sw/bin/skhd

# Run manually to trigger permission dialog
/nix/store/XXX-skhd-X.X.X/bin/skhd -c /etc/skhdrc

# Grant permission in System Settings > Privacy > Accessibility
# Then restart
launchctl kickstart -k gui/$(id -u)/org.nixos.skhd
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
