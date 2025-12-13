# Dotfiles Project Context

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
│   └── tableplus-to-nvim-db.md
├── scripts/               # Shell scripts (copied to ~/.scripts/)
│   ├── secrets-sync.sh    # Encrypt secrets to sops format
│   ├── secrets-decrypt.sh # Decrypt secrets from sops
│   ├── load-aliases.sh    # Load shell aliases
│   ├── claude-init.sh     # Initialize Claude Code in projects
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
- Platform configs: `modules/{darwin,linux,android}.nix`
- Shared home config: `modules/shared.nix`
- Neovim: `nvim/init.lua`, `nvim/lsp/`, `nvim/ftplugin/`
- Secrets: `secrets/encrypted/ssh/`, `secrets/encrypted/aws/`
- Age key: `~/.config/sops/age/keys.txt`

## Common Operations

### Installation & Build
```bash
make install      # Auto-detect platform and apply
make darwin       # Apply macOS config
make linux        # Apply Linux/NixOS config
make build        # Build without applying
```

### Secrets Management
```bash
make encrypt      # Encrypt all secrets (SSH, AWS, Git)
make decrypt      # Decrypt all secrets
make gen-key      # Generate/import age key
```

### Maintenance
```bash
make update       # Update flake inputs
make format       # Format nix files
make check        # Check flake configuration
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

## Package Management
- **Shared packages (all platforms)**: Edit `sharedPackages` in `flake.nix`
- **Platform-specific**: Edit `darwinPackages`, `linuxPackages` in `flake.nix`
- **System packages**: Edit respective `modules/*.nix` files

## Known Issues & TODOs
- Yabai requires SIP partially disabled on Apple Silicon
- skhd needs manual Accessibility permission grant on macOS
- Linux hardware config must be generated per-machine
- Work.gitconfig is optional (personal/work config split)

## Testing Secrets
```bash
make test-decrypt    # Test decryption without writing files
```

## Quick Keybindings Reference

### Tmux Pane Management
- **Navigate panes**: `Ctrl+h/j/k/l` (vim-aware, seamless with Neovim)
- **Resize panes**: `Ctrl-b` then `h/j/k/l` (prefix + hjkl)
- **Alternative resize**: `Ctrl+Shift+h/j/k/l` (no prefix needed, from plugins)
- **Switch windows**: `Alt+,` / `Alt+.`
- **Reload config**: `Ctrl-b` then `r`

### Neovim Window Management
- **Navigate windows**: `Ctrl+h/j/k/l` (seamless with tmux panes)
- **Resize windows**: `Alt+h/j/k/l` (horizontal/vertical resize)
- **Equalize windows**: `Alt+=`

### Yabai Window Manager
- **Resize windows**: `Alt+Shift+h/l` (horizontal only)
- **Focus windows**: `Alt+Shift+j/k` (cycle through windows)
- **Switch spaces**: `Cmd+j/k` (previous/next space)
- **Show all bindings**: `Alt+Shift+/`

### Important: Kitty Terminal Configuration
Kitty must explicitly pass through certain keybindings to allow system-level hotkeys (skhd) to work:
- `cmd+j`, `cmd+k` - Passed to skhd for space switching (kitty/kitty.conf:102-103)
- `cmd+r` - Passed to skhd for config reload (kitty/kitty.conf:106)
- `enable_csi_u no` - Disabled to prevent keyboard protocol conflicts (kitty/kitty.conf:92)

Full reference: `KEYBINDINGS.md`

## Claude Code Workflow (NEW)
Global token-saving workflow available via `claude-init` command:
- Templates in: `templates/claude-code/`
- Script: `scripts/claude-init.sh`
- Installed to PATH via: `modules/shared.nix`
- Usage: `claude-init [directory]` - initializes CLAUDE.md and docs/ in any project

## Recent Changes
- **FIXED**: Resolved keybinding conflicts between Kitty, tmux, and skhd
  - Restored Kitty configuration to pass `cmd+j/k` to skhd for space switching (kitty/kitty.conf:102-103)
  - Re-enabled `enable_csi_u no` to prevent CSI-u keyboard protocol conflicts (kitty/kitty.conf:92)
  - Fixed yabai window resize to use `--resize` instead of `--ratio` (works for all window states) (skhd/skhdrc:41-44)
  - Verified tmux pane resize bindings: `prefix+h/j/k/l` and alternative `Ctrl+Shift+h/j/k/l`
  - Updated CLAUDE.md with comprehensive keybinding reference for tmux, Neovim, and yabai
- **NEW**: Added `swagger-to-kulala` Go tool for converting OpenAPI/Swagger specs to kulala.nvim HTTP files
  - Supports both OpenAPI 3.x and Swagger 2.0
  - Generates example request bodies from schemas with $ref resolution
  - Split by tags feature for organized output
  - Built and distributed via Nix flake
  - Full documentation in `scripts/swagger-to-kulala/README.md`
- Moved scripts from `~/.scripts/` into tracked `./scripts/` directory
  - Added `clipse-wrapper.sh` (clipboard manager wrapper)
  - Added `toggle-kitty-window.sh` (floating window management)
- Added global Claude Code workflow initializer (`claude-init` command)
- Created templates/claude-code/ with CLAUDE.md template and workflow docs
- Added comprehensive documentation in `docs/` (progress.md, workflow.md)
- Added Linux platform support (modules/linux.nix)
- Added qutebrowser launcher scripts (qb-picker, qb-picker-gui)
- Added kitty terminal configuration (kitty/kitty.conf)
- Fixed work.gitconfig handling (optional in nix build)
- Enhanced secrets decryption to support both Kubernetes Secret and plain YAML formats
