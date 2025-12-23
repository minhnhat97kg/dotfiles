# Termux Nix Setup Guide

This guide explains how to use vanilla Nix in Termux without the nix-on-droid app.

## Table of Contents
- [Overview](#overview)
- [nix-on-droid vs Termux Nix](#nix-on-droid-vs-termux-nix)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Development Shells](#development-shells)
- [Troubleshooting](#troubleshooting)

## Overview

You have three options for using Nix on Android:

1. **nix-on-droid (Full)** - Complete setup with all packages and features
   - App: nix-on-droid from F-Droid
   - Config: `modules/android.nix`
   - Command: `make android`

2. **nix-on-droid (Lite)** - Battery-optimized with minimal packages
   - App: nix-on-droid from F-Droid
   - Config: `modules/android-lite.nix`
   - Command: `make android-lite`

3. **Termux Nix (Vanilla)** - Nix installed directly in Termux ⭐ **This guide**
   - App: Regular Termux from F-Droid
   - Config: `modules/termux.nix`
   - Command: `make termux`

## nix-on-droid vs Termux Nix

### Key Differences

| Feature | nix-on-droid | Termux Nix |
|---------|--------------|------------|
| **Installation** | Install app from F-Droid | Bootstrap script |
| **Environment** | Runs in proot | Native Termux |
| **Configuration** | `nix-on-droid` module | `home-manager` module |
| **Packages** | `environment.packages` | `home.packages` |
| **Build command** | `nix-on-droid switch` | `home-manager switch` |
| **Activation** | `build.activation.*` | `home.activation.*` |
| **System config** | ✅ Yes | ❌ No (user only) |
| **Simplicity** | More complex | Simpler |
| **Boot time** | Slower (proot) | Faster |
| **Compatibility** | Some limitations | Better |

### Why Choose Termux Nix?

**Pros:**
- ✅ Simpler setup - just bootstrap Nix in existing Termux
- ✅ Faster startup (no proot overhead)
- ✅ Better compatibility with Termux packages
- ✅ Can use `pkg` and Nix side-by-side
- ✅ More standard Nix/home-manager workflow
- ✅ Easier to debug (no proot layer)

**Cons:**
- ❌ No system-level configuration
- ❌ Manual Nix installation required
- ❌ Need to manage two package managers (Termux + Nix)

### Why Choose nix-on-droid?

**Pros:**
- ✅ All-in-one solution
- ✅ System-level configuration
- ✅ Declarative everything
- ✅ Official nix-on-droid community support

**Cons:**
- ❌ Heavier (runs in proot)
- ❌ Some syscalls don't work (setuid/setgid)
- ❌ Can't run Xvfb natively (need Termux workaround)
- ❌ More complex debugging

## Installation

### Prerequisites

1. Install Termux from F-Droid
2. Make sure you're in **regular Termux** (not nix-on-droid)

### Bootstrap Nix

Run the bootstrap script:

```bash
# Download dotfiles (if not already cloned)
git clone https://github.com/yourusername/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles

# Run bootstrap script
bash scripts/bootstrap-termux-nix.sh
```

The script will:
1. Install Termux dependencies (wget, curl, git, etc.)
2. Install Nix using the official installer
3. Enable flakes and configure Nix
4. Install home-manager
5. Apply the Termux configuration

### Manual Installation

If you prefer to install manually:

```bash
# 1. Install Termux packages
pkg update
pkg install wget curl git gnupg xz-utils which

# 2. Install Nix
curl -L https://nixos.org/nix/install -o /tmp/nix-install.sh
sh /tmp/nix-install.sh --no-daemon

# 3. Source Nix profile
. ~/.nix-profile/etc/profile.d/nix.sh

# 4. Enable flakes
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf <<EOF
experimental-features = nix-command flakes
warn-dirty = false
EOF

# 5. Clone dotfiles
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles

# 6. Apply configuration
home-manager switch --flake .#termux
# OR
make termux
```

## Configuration

### Package Management

The Termux configuration (`modules/termux.nix`) includes a **minimal package set** for battery optimization:

**Included packages:**
- Core: git, gh, fzf, ripgrep, fd, jq, curl
- Network: openssh, net-tools, mosh
- Secrets: sops, age, yq-go
- Dev (minimal): go, nodejs, python3
- Utils: direnv, lazygit, delta

**Heavy dev tools** are available via development shells (see below).

### Customization

Edit `modules/termux.nix` to:
- Add packages to `home.packages`
- Configure shell aliases
- Set environment variables
- Add activation scripts

Example:
```nix
home.packages = with pkgs; [
  # Add your packages here
  htop
  neofetch
];
```

### Applying Changes

After editing configuration:

```bash
cd ~/projects/dotfiles
make termux

# OR manually:
home-manager switch --flake .#termux
```

## Usage

### Common Commands

```bash
# Apply configuration
make termux
hms  # Shortcut for home-manager switch

# Build without applying
home-manager build --flake ~/projects/dotfiles#termux

# Update packages
cd ~/projects/dotfiles
make update
make termux

# Secrets management
make encrypt
make decrypt
```

### Shell Aliases

Configured aliases:

```bash
# Termux package management
tpkg         # pkg
tup          # pkg update && pkg upgrade

# Nix shortcuts
hm           # home-manager
hms          # home-manager switch --flake ~/projects/dotfiles#termux
hmb          # home-manager build --flake ~/projects/dotfiles#termux

# Development shells (see below)
dev-go       # nix develop ~/projects/dotfiles#go
dev-rust     # nix develop ~/projects/dotfiles#rust
dev-node     # nix develop ~/projects/dotfiles#node
dev-python   # nix develop ~/projects/dotfiles#python

# Secrets
secrets-decrypt  # Decrypt secrets
secrets-encrypt  # Encrypt secrets

# SSH
sshd-start   # Start SSH server on port 8022
sshd-stop    # Stop SSH server
```

### SSH Server

SSH server is automatically configured:

```bash
# Start SSH server
sshd-start
# Output: ✓ SSH server started on port 8022
#         Connect: ssh -p 8022 <username>@<ip>

# Stop SSH server
sshd-stop

# Connect from another machine
ssh -p 8022 <username>@<device-ip>

# Auto-generated key for passwordless login
~/.ssh/android_client_key
```

## Development Shells

Heavy development tools (Java, Gradle, Maven, Rust toolchains, etc.) are not installed by default to save battery and storage.

Instead, use **development shells** for project work:

```bash
# Enter Go development environment
dev-go
# or: nix develop ~/projects/dotfiles#go

# Available shells:
dev-go        # Go, Delve, goimports-reviser
dev-rust      # Rust, Cargo, Clippy, rust-analyzer
dev-node      # Node.js, npm, yarn
dev-python    # Python3, pip, pipx
```

When you exit the dev shell, those tools are gone (saving resources).

### Creating Project-Specific Shells

For a project, create a `flake.nix` or `shell.nix`:

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "aarch64-linux"; };
    in {
      devShells.aarch64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          go
          gopls
          delve
        ];
      };
    };
}
```

Then:
```bash
cd ~/my-project
nix develop
# Or with direnv:
direnv allow
```

## Troubleshooting

### Nix commands not found

Source the Nix profile:
```bash
. ~/.nix-profile/etc/profile.d/nix.sh
```

Add to `~/.zshrc` or `~/.bashrc`:
```bash
if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
  . ~/.nix-profile/etc/profile.d/nix.sh
fi
```

### home-manager not found

Install home-manager:
```bash
nix run home-manager/master -- init --switch
```

### Configuration errors

Check syntax:
```bash
cd ~/projects/dotfiles
nix flake check
```

Build without applying:
```bash
home-manager build --flake .#termux
```

### Nix store full

Clean up old generations:
```bash
nix-collect-garbage -d
```

### Reverting to nix-on-droid

If you want to switch back to nix-on-droid:

1. Uninstall Nix from Termux:
   ```bash
   rm -rf ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nix
   ```

2. Install nix-on-droid app from F-Droid

3. Use the nix-on-droid configuration:
   ```bash
   cd ~/projects/dotfiles
   make android      # Full config
   # OR
   make android-lite # Lite config
   ```

## Comparison with nix-on-droid Commands

| Task | nix-on-droid | Termux Nix |
|------|--------------|------------|
| Apply config | `nix-on-droid switch` | `home-manager switch` |
| Build config | `nix-on-droid build` | `home-manager build` |
| List generations | `nix-on-droid generations` | `home-manager generations` |
| Rollback | `nix-on-droid rollback` | `home-manager rollback` |
| Flake check | `nix flake check` | `nix flake check` |
| Update inputs | `nix flake update` | `nix flake update` |

## Additional Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Termux Wiki](https://wiki.termux.com/)
- [nix-on-droid Documentation](https://github.com/nix-community/nix-on-droid)
