# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Summary
Cross-platform Nix configuration for macOS (nix-darwin) and Android (nix-on-droid). Manages dotfiles, system configuration, and secrets encryption using sops/age.

## Tech Stack
- **Build System**: Nix flakes, Makefile
- **Platforms**: nix-darwin (macOS), nix-on-droid (Android)
- **Secrets**: sops + age encryption
- **Editor**: Neovim with LSP (Lua, TypeScript, Go, Rust, Java)
- **Shell**: Zsh + oh-my-zsh
- **Terminal**: Tmux + Kitty
- **macOS**: Kanata (keyboard customization)

## Repository Structure
```
dotfiles/
├── flake.nix              # Thin top-level: inputs + mkDarwinHost/mkAndroidHost helpers + outputs
├── Makefile               # Commands: install/build/encrypt/decrypt
├── CLAUDE.md              # Project context for Claude Code
├── hosts/                 # One file per machine
│   ├── darwin/
│   │   └── Nathan-Macbook.nix  # Host-specific darwin settings (hostname, packages, files)
│   └── android/
│       └── default.nix         # nix-on-droid host settings (home-manager overrides)
├── modules/
│   ├── platforms/
│   │   ├── darwin.nix     # macOS system config (nix, homebrew, launchd, clipse)
│   │   └── android.nix    # Android system config (packages, SSH server, activation)
│   └── home/              # Shared home-manager config (split by concern)
│       ├── default.nix    # Entry point: imports all home modules + sets stateVersion
│       ├── shell.nix      # Zsh + oh-my-zsh + env vars + aliases
│       ├── editor.nix     # Neovim
│       ├── terminal.nix   # Tmux + plugins + keybindings
│       ├── git.nix        # Git includes + gitconfig file deployments
│       └── files.nix      # Static file deployments (nvim dir, scripts, fzf, lazygit, direnv)
├── docs/                  # Documentation
│   ├── progress.md        # Project progress tracking
│   ├── workflow.md        # Development workflow
│   ├── android-desktop.md # Android desktop (deprecated - removed)
│   ├── ssh-passwords.md   # SSH password management
│   ├── kulala-response-variables-guide.md
│   └── tableplus-to-nvim-db.md
├── scripts/               # Shell scripts (copied to ~/.scripts/)
│   ├── secrets-sync.sh    # Encrypt secrets to sops format
│   ├── secrets-decrypt.sh # Decrypt secrets from sops
│   ├── load-aliases.sh    # Load shell aliases
│   ├── claude-init.sh     # Initialize Claude Code in projects
│   ├── toggle-theme.sh    # Toggle light/dark theme
│   ├── clipse-wrapper.sh  # Clipboard manager wrapper
│   ├── whichkey-fzf.sh    # Keybinding picker with FZF
│   ├── ssh-*.sh           # SSH tunnel and password helpers
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
├── secrets/encrypted/     # sops-encrypted secrets
│   ├── ssh/               # SSH keys and tunnels
│   └── aws/               # AWS credentials
└── sql/                   # SQL configurations
```

## Key Paths
- Main config: `flake.nix` (username, email, package lists, host builders)
- Platform configs: `modules/platforms/{darwin,android}.nix`
- Home-manager config: `modules/home/` (split by concern)
- Host overrides: `hosts/darwin/Nathan-Macbook.nix`, `hosts/android/default.nix`
- Neovim: `nvim/init.lua`, `nvim/lsp/`, `nvim/ftplugin/`
- Secrets: `secrets/encrypted/ssh/`, `secrets/encrypted/aws/`
- Age key: `~/.config/sops/age/keys.txt`

## Architecture Overview

### Build System Flow
1. **Makefile** - Entry point for common operations, auto-detects platform
2. **flake.nix** - Central configuration defining:
   - User settings (username, email)
   - Package lists (shared, platform-specific)
   - Platform outputs (darwinConfigurations, nixOnDroidConfigurations)
   - `mkDarwinHost` / `mkAndroidHost` helpers for adding new machines
3. **modules/platforms/** - System-level Nix modules (nix/homebrew/SSH/activation):
   - `darwin.nix` - macOS system config (homebrew, launchd, clipse, activationScripts)
   - `android.nix` - nix-on-droid system config (SSH server, environment.packages, activation)
4. **modules/home/** - User-level home-manager config shared across platforms:
   - `default.nix` → imports shell/editor/terminal/git/files modules
5. **hosts/** - Machine-specific overrides (hostname, per-host packages, extra files):
   - `hosts/darwin/Nathan-Macbook.nix` - networking.hostName + macOS-specific home files
   - `hosts/android/default.nix` - Android home-manager overrides (mkForce packages, zsh)

### Secrets Architecture
- **Encryption**: sops-nix encrypts files using age asymmetric encryption
- **Key location**: `~/.config/sops/age/keys.txt` (single private key)
- **Config**: `secrets/config.yaml` defines source/destination mappings
- **Encrypted storage**: `secrets/encrypted/` directory (committed to git)
- **Scripts**:
  - `secrets-sync.sh` - Read config.yaml, encrypt sources to encrypted/
  - `secrets-decrypt.sh` - Read config.yaml, decrypt to destinations
  - `secrets-edit.sh` - Interactively enter/paste a secret value and encrypt it (no source file needed)
  - Format: Kubernetes Secret YAML with base64-encoded data

### Package Management Strategy
- **sharedPackages** in flake.nix - Cross-platform tools (git, fzf, neovim, go, rust)
- **darwinPackages** in flake.nix - macOS-only (clipboard-jh, JetBrains Mono font)
- Platform-specific system packages in respective `modules/platforms/*.nix` files

## Common Commands

### Build & Deploy
```bash
make install      # Auto-detect platform and apply configuration
make darwin       # Apply macOS config (darwin-rebuild switch)
make android      # Apply Android config (nix-on-droid switch)
make build        # Build without applying (dry run)
```

### Secrets Management
```bash
make deps         # Install yq-go and age if missing
make encrypt      # Encrypt all secrets from sources defined in secrets/config.yaml
make decrypt      # Decrypt all secrets to destinations
make decrypt-yes  # Decrypt without confirmation prompt
make secret-edit  # Interactively enter/paste a secret and encrypt it
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
- Kitty terminal installed via Homebrew (cask), config managed by Nix
- LaunchDaemons configured for clipse clipboard manager
- After `make install`, system configuration is automatically applied

### Android (nix-on-droid)
- Install from F-Droid, runs in Termux environment
- SSH server auto-configured with generated keys (port 8022)
- Minimal terminal-only setup optimized for battery life
- Optimized package set for mobile/battery constraints

## Important Implementation Details

### Tmux + Neovim Integration
- Seamless navigation between tmux panes and neovim splits using Ctrl+h/j/k/l
- Achieved via `is_vim` detection in tmux config (`modules/home/terminal.nix`)
- Tmux pane resize: prefix+h/j/k/l OR Ctrl+Shift+h/j/k/l (no prefix)


### Zsh Alias Loading
- Shell aliases dynamically loaded from YAML via `load-aliases.sh`
- Called in zsh initContent (`modules/home/shell.nix`)
- Template: `shell/aliases.yaml.example`

### Work/Personal Git Config Split
- work.gitconfig is optional (conditionally included in git config)
- Build doesn't fail if missing - allows public dotfiles with private work config

## Development Workflow

### Adding New Packages
1. **Shared (all platforms)**: Add to `sharedPackages` list in `flake.nix`
2. **macOS-specific**: Add to `darwinPackages` in `flake.nix`
3. **System-level**: Add to `environment.systemPackages` in `modules/platforms/{darwin,android}.nix`
4. Apply changes: `make install`

### Adding a New Mac
1. Create `hosts/darwin/NewMacbook.nix` with host-specific overrides
2. Add `darwinConfigurations."NewMacbook" = mkDarwinHost { hostname = "NewMacbook"; };` in `flake.nix`

### Adding a New Platform
1. Create `modules/platforms/linux.nix` with system config
2. Create `hosts/nixos/hostname.nix` with host overrides
3. Add `nixosConfigurations."hostname" = mkLinuxHost { hostname = "hostname"; };` in `flake.nix`

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

## Claude Code Workflow

This repo includes a global `claude-init` command for initializing token-efficient Claude Code workflows in any project:
```bash
claude-init [directory]  # Creates CLAUDE.md + docs/ structure
```
- Implementation: `scripts/claude-init.sh`
- Installed to PATH via `modules/home/files.nix`