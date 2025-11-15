# Minimal Cross-Platform Dotfiles

A minimal, consolidated Nix configuration supporting both **macOS** (via nix-darwin) and **Android** (via nix-on-droid).

## 📁 Structure

```
dotfiles/
├── flake.nix              # Single unified configuration (all platforms)
├── nvim/                  # Neovim editor configuration
│   ├── init.lua          # Minimized Neovim config (630 lines)
│   ├── lsp/              # LSP server configurations
│   │   ├── lua_ls.lua
│   │   ├── ts_ls.lua
│   │   └── golsp.lua
│   └── ftplugin/
│       └── java.lua      # Java-specific settings
├── shell/                 # Shell dotfiles
│   ├── .zshrc            # Zsh configuration
│   ├── .bashrc           # Bash configuration
│   ├── .profile          # Shell profile
│   ├── .zprofile         # Zsh profile
│   └── .ideavimrc        # IdeaVim configuration
├── yabai/yabairc         # macOS window manager
├── skhd/skhdrc           # macOS hotkey daemon
├── zellij/config.kdl     # Terminal multiplexer
├── alacritty/            # Alacritty terminal emulator config
├── kitty/                # Kitty terminal emulator config
├── iterm2/               # iTerm2 configuration
├── fish/                 # Fish shell configuration
├── git/                  # Git global ignore patterns
├── htop/                 # htop system monitor config
├── btop/                 # btop system monitor config
├── lazygit/              # Lazygit TUI configuration
├── lazydocker/           # Lazydocker TUI configuration
├── karabiner/            # Karabiner keyboard customization
├── sketchybar/           # Sketchybar macOS status bar
├── aws/                  # AWS CLI configuration
├── secrets/              # Encrypted secrets (managed by sops)
└── README.md             # This file
```

## 🚀 Quick Start

### macOS Installation

1. **Install Nix**:
   ```bash
   sh <(curl -L https://nixos.org/nix/install)
   ```

2. **Clone this repository**:
   ```bash
   git clone <your-repo> ~/projects/dotfiles
   cd ~/projects/dotfiles
   ```

3. **Apply configuration**:
   ```bash
   nix run nix-darwin -- switch --flake .#Nathan-Macbook --accept-flake-config
   ```

4. **Subsequent updates**:
   ```bash
   darwin-rebuild switch --flake .
   # Or use the Makefile:
   make darwin
   ```

### What Gets Configured

When you run the configuration, home-manager will automatically symlink all configs from this repo to your home directory:

- **Shell configs** → `~/.zshrc`, `~/.bashrc`, `~/.profile`, etc.
- **Terminal emulators** → `~/.config/alacritty/`, `~/.config/kitty/`, `~/.config/iterm2/`
- **Window management** → `~/.config/yabai/`, `~/.config/skhd/`, `~/.config/sketchybar/`
- **Development tools** → `~/.config/nvim/`, `~/.config/lazygit/`, `~/.config/lazydocker/`
- **System monitoring** → `~/.config/htop/`, `~/.config/btop/`
- **And more...** All configs in this repo are automatically linked!

### Android Installation (Nix-on-Droid)

1. **Install Nix-on-Droid app** from F-Droid:
   - https://f-droid.org/packages/com.termux.nix/

2. **Open the app and run**:
   ```bash
   nix-on-droid switch --flake github:your-username/dotfiles
   ```

3. **Or clone locally**:
   ```bash
   git clone <your-repo> ~/dotfiles
   cd ~/dotfiles
   nix-on-droid switch --flake .
   ```

## 🎯 Features

### Shared Across Platforms
- **Editor**: Neovim with LSP support (Lua, TypeScript, Go, Java)
- **Terminal**: Tmux with vim-like navigation
- **Shell**: Zsh with oh-my-zsh
- **Dev Tools**: Go, Rust toolchain, Git
- **Utilities**: fzf, lazygit, direnv

### macOS-Specific
- Yabai (window manager)
- SKHD (hotkey daemon)
- Zellij (terminal multiplexer)
- Harlequin (database GUI)

### Android-Specific
- Optimized for Termux environment
- Touch-friendly terminal fonts
- Mobile-optimized paths

## 📝 Key Changes from Original

### Consolidated Structure
**Before**: 5 separate Nix modules (401 lines)
**After**: 1 unified flake.nix (307 lines)

**Reduction**: ~24% smaller, much easier to maintain

### Removed Modules
- ❌ `modules/core.nix` → Merged into flake.nix
- ❌ `modules/system.nix` → Merged into flake.nix
- ❌ `modules/home.nix` → Merged into flake.nix
- ❌ `modules/host-users.nix` → Merged into flake.nix

### Neovim Configuration
**Before**: 1134 lines with commented code
**After**: 630 lines, clean and modern

**Improvements**:
- Removed ~400 lines of commented Java/Debug configs
- Uses Neovim 0.11+ native `vim.lsp.enable()`
- Removed duplicate autocmds and diagnostics
- Cleaner section headers

### New Capabilities
- ✅ **Android support** via nix-on-droid
- ✅ **Shared configuration** reduces duplication
- ✅ **Platform-specific overrides** where needed
- ✅ **Single source of truth** for all platforms

## 🛠️ Customization

### Change Username/Email
Edit `flake.nix`:
```nix
username = "your-username";
useremail = "your-email@example.com";
```

### Add Packages
Edit the `sharedPackages` function in `flake.nix`:
```nix
sharedPackages = pkgs: with pkgs; [
  git
  fzf
  neovim
  # Add your packages here
  ripgrep
  bat
];
```

### Platform-Specific Packages

**macOS only**:
```nix
# In darwinConfigurations section
environment.systemPackages = with nixpkgs.legacyPackages.aarch64-darwin; [
  your-macos-package
];
```

**Android only**:
```nix
# In nixOnDroidConfigurations section
environment.packages = with nixpkgs.legacyPackages.aarch64-linux; [
  your-android-package
];
```

## 🔧 Maintenance

### Update flake inputs
```bash
nix flake update
```

### Format Nix code
```bash
nix fmt
```

### Garbage collection
Automatic weekly cleanup is enabled. Manual cleanup:
```bash
# macOS
nix-collect-garbage -d

# Android
nix-on-droid on-device nix-collect-garbage -d
```

### Check flake
```bash
nix flake check
```

## 📱 Android-Specific Tips

### Terminal Recommendations
- Use **Termux:Widget** for quick shortcuts
- Enable **Termux:Styling** for better themes
- Install **Termux:API** for device integration

### Building on Android
The first build on Android takes ~30-60 minutes. Subsequent builds are much faster thanks to caching.

### Storage Considerations
Nix-on-Droid requires ~2-3GB of storage. Ensure you have sufficient space before installation.

## 🐛 Troubleshooting

### macOS: "command not found: darwin-rebuild"
```bash
nix run nix-darwin -- switch --flake .
```

### Android: Build failures
```bash
# Clear cache and rebuild
nix-on-droid on-device nix-store --verify --check-contents --repair
```

### LSP not working in Neovim
The LSP configs in `nvim/lsp/` are auto-discovered by Neovim 0.11+. Ensure you have:
```bash
# Install language servers via Mason in Neovim
:Mason
```

## 📚 Resources

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [nix-on-droid](https://github.com/nix-community/nix-on-droid)
- [home-manager](https://github.com/nix-community/home-manager)
- [Neovim 0.11](https://neovim.io/doc/user/news-0.11.html)

## 📄 License

MIT License - Feel free to use and modify.

---

**Note**: This configuration has been minimized and consolidated from a multi-file setup. All the functionality is preserved while significantly reducing complexity and duplication.
