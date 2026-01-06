# Battery Optimization Guide for nix-on-droid

This guide explains how to use the battery-optimized configuration and manage development tools on-demand.

## Quick Start

### Switch to Battery-Optimized Configuration

```bash
# Switch to lite (battery-optimized) configuration
nix-on-droid switch --flake ~/dotfiles#lite

# Switch back to full configuration
nix-on-droid switch --flake ~/dotfiles#default
```

### Manage SSH Tunnels

```bash
# Stop running tunnels (saves battery)
tunnel-stop

# Check if tunnels are running
tunnel-status

# Start a specific tunnel when needed
tunnel-start fl-dev
```

## What Changed?

### Lite Configuration (`android-lite.nix`)

**Removed from always-installed packages:**
- Development tools: Go, Rust, Java/Maven/Gradle, Node.js (moved to devShells)
- Databases: PostgreSQL, MySQL, mycli, pgcli (moved to devShells)
- HTTP tools: httpie, hurl (moved to devShells)
- Large utilities: terraform, delta, diff-so-fancy, fx (moved to devShells)
- Heavy fonts: Nerd Fonts (replaced with standard JetBrains Mono)

**Kept as always-installed:**
- Core: neovim, tmux, git, gh, fzf, ripgrep, fd, jq, curl
- Shell: zsh, oh-my-zsh
- Network: openssh
- Secrets: sops, age, yq-go
- Utilities: direnv, lazygit

**Optimizations:**
- Activation scripts now skip if already configured (faster rebuilds)
- Lighter font package
- Minimal package set reduces memory usage

## Using Development Tools On-Demand

Development tools are now available via `nix develop` shells. Activate them only when needed:

### Available DevShells

```bash
# Go development
dev-go
# Includes: go, delve, goimports-reviser, gcc, gnumake

# Rust development
dev-rust
# Includes: rustc, cargo, clippy, rustfmt, rust-analyzer, gcc

# Java development
dev-java
# Includes: maven, gradle, jdk

# Database tools
dev-db
# Includes: postgresql, mysql80, mycli, pgcli

# Web/HTTP tools
dev-web
# Includes: httpie, hurl, nodejs

# Full development environment (all tools)
dev-full
# Includes: All of the above plus terraform, delta, diff-so-fancy, fx
```

### How to Use DevShells

```bash
# Enter a development shell
dev-go

# Now you have access to Go tools
go version
dlv version

# Exit the shell when done
exit

# Or run a single command in the shell
nix develop ~/dotfiles#go --command go build
```

### Tips for Maximum Battery Savings

1. **Stop SSH tunnels when not needed**
   ```bash
   tunnel-stop
   ```

2. **Exit development shells when done**
   ```bash
   exit  # from dev shell
   ```

3. **Use lite configuration as default**
   ```bash
   nix-on-droid switch --flake ~/dotfiles#lite
   ```

4. **Only activate dev tools when actively coding**
   - Don't run `dev-full` unless you need everything
   - Use specific shells (dev-go, dev-rust, etc.) for targeted work

5. **Check running processes periodically**
   ```bash
   pgrep -af .  # See all processes
   tunnel-status  # Check for tunnels
   ```

## Estimated Battery Impact

Based on typical usage:

| Configuration | Estimated Battery Life | Use Case |
|--------------|----------------------|----------|
| Full (android.nix) | Baseline | Heavy development work |
| Lite + no tunnels | +30-40% improvement | Light editing, git work |
| Lite + dev shell | +15-20% improvement | Focused development |
| Lite + SSH tunnel | +10-15% improvement | Remote development |

**Note:** Actual battery life depends on many factors including screen-on time, CPU usage, and background processes.

## Troubleshooting

### "Command not found" after switching to lite

You're probably trying to use a tool that's now in a devShell. Check which shell you need:
```bash
# See all available shells
nix flake show ~/dotfiles

# Activate the appropriate shell
dev-go    # for Go tools
dev-rust  # for Rust tools
dev-db    # for database tools
```

### Switching back to full configuration

```bash
nix-on-droid switch --flake ~/dotfiles#default
```

### Checking current configuration

```bash
# See what's installed
nix-env -q

# Check flake
cat ~/.config/nixpkgs/flake.nix 2>/dev/null || echo "Using flake from ~/dotfiles"
```

## Reverting Changes

If you want to go back to the original setup:

```bash
# Switch to default (full) configuration
nix-on-droid switch --flake ~/dotfiles#default

# The original android.nix is unchanged
```

Both configurations are available:
- `~/dotfiles/modules/android.nix` - Full configuration (unchanged)
- `~/dotfiles/modules/android-lite.nix` - Battery-optimized configuration (new)
