# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Summary
Cross-platform Nix configuration for macOS (nix-darwin), Linux (NixOS), and Android (nix-on-droid). Manages dotfiles, system configuration, and secrets encryption using sops/age.

## Tech Stack
- **Build System**: Nix flakes, Makefile
- **Platforms**: nix-darwin (macOS), NixOS (Linux), nix-on-droid (Android)
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
│   ├── android.nix        # Android system config
│   └── shared.nix         # Shared home-manager config
├── docs/                  # Documentation
│   ├── progress.md        # Project progress tracking
│   ├── workflow.md        # Development workflow
│   ├── android-desktop.md # Android desktop (deprecated - removed)
│   ├── battery-optimization.md # Battery optimization guide for Android
│   ├── ssh-passwords.md   # SSH password management
│   ├── kulala-response-variables-guide.md
│   └── tableplus-to-nvim-db.md
├── scripts/               # Shell scripts (copied to ~/.scripts/)
│   ├── secrets-sync.sh    # Encrypt secrets to sops format
│   ├── secrets-decrypt.sh # Decrypt secrets from sops
│   ├── load-aliases.sh    # Load shell aliases
│   ├── claude-init.sh     # Initialize Claude Code in projects
│   ├── cycle-layout.sh    # Cycle yabai layouts
│   ├── toggle-kitty-window.sh  # Toggle floating kitty windows
│   ├── toggle-theme.sh    # Toggle light/dark theme
│   ├── clipse-wrapper.sh  # Clipboard manager wrapper
│   ├── whichkey-fzf.sh    # Keybinding picker with FZF
│   ├── ssh-*.sh           # SSH tunnel and password helpers
│   ├── window-picker.sh   # Window selection UI
│   ├── activate-decrypt-secrets*.sh  # Activation scripts for secrets
│   └── swagger-to-kulala/ # Go tool: Convert OpenAPI/Swagger to kulala.nvim HTTP files
│       ├── main.go
│       ├── go.mod
│       ├── go.sum
│       └── README.md
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
- Platform configs: `modules/{darwin,linux,android}.nix`
- Shared home config: `modules/shared.nix`
- Neovim: `nvim/init.lua`, `nvim/lsp/`, `nvim/ftplugin/`
- Secrets: `secrets/encrypted/ssh/`, `secrets/encrypted/aws/`
- Age key: `~/.config/sops/age/keys.txt`

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
make android      # Apply Android config (nix-on-droid switch)
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
- Install from F-Droid, runs in Termux environment
- SSH server auto-configured with generated keys (port 8022)
- Minimal terminal-only setup optimized for battery life
- Optimized package set for mobile/battery constraints

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
3. **System-level**: Add to environment.systemPackages in `modules/{darwin,linux,android}.nix`
4. Apply changes: `make install`

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
- Implementation: `scripts/claude-init.sh`
- Installed to PATH via `modules/shared.nix`
- save the plan to use in the future