#!/usr/bin/env bash
# bootstrap.sh — installs Nix and clones the dotfiles repo on a fresh machine.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<github-user>/dotfiles/main/bootstrap.sh | bash
#   OR: clone repo first, then: ./bootstrap.sh
#
# What this does:
#   1. Detects the OS (macOS, WSL, Termux, Android, Linux)
#   2. Installs Nix (Determinate Systems installer), if not already present
#   3. Clones the dotfiles repo
#
# Applying the configuration is left to `make install` inside the cloned repo.
set -euo pipefail

DOTFILES_REPO="https://github.com/<github-user>/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

log()  { echo "▶ $*"; }
ok()   { echo "✓ $*"; }
warn() { echo "⚠ $*"; }
die()  { echo "✗ $*" >&2; exit 1; }

# ─── Detect platform ──────────────────────────────────────────────────────────
# Only used for the log line below — Nix itself is installed the same way
# everywhere, since the Determinate Systems installer detects OS + arch on
# its own. `make install` does its own platform detection for the actual
# apply step.
detect_platform() {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      return
      ;;
  esac

  if command -v nix-on-droid &>/dev/null; then
    echo "android"
  elif [ -d /data/data/com.termux ] || [ -n "${TERMUX_VERSION:-}" ]; then
    echo "termux"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "linux"
  fi
}

PLATFORM=$(detect_platform)
log "Detected platform: $PLATFORM ($(uname -s) $(uname -m))"

# ─── Install Nix (skip if already installed) ──────────────────────────────────
install_nix() {
  if command -v nix &>/dev/null; then
    ok "Nix already installed: $(nix --version)"
    return
  fi

  if [ "$PLATFORM" = "macos" ]; then
    # Official installer on macOS: nix-darwin manages the Nix daemon itself
    # (modules/platforms/darwin.nix sets nix.enable = true), which conflicts
    # with the Determinate installer's separately-managed daemon.
    log "Installing Nix via the official installer (nix-darwin will manage the daemon)..."
    sh <(curl -L https://nixos.org/nix/install)
  else
    log "Installing Nix via Determinate Systems installer (auto-selects the build for $(uname -s)/$(uname -m))..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  fi

  # Source nix into current shell
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  ok "Nix installed: $(nix --version)"
}

# ─── Clone dotfiles ───────────────────────────────────────────────────────────
clone_dotfiles() {
  if [ -d "$DOTFILES_DIR/.git" ]; then
    log "Dotfiles already cloned at $DOTFILES_DIR, pulling latest..."
    git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not pull — continuing with existing state"
    return
  fi

  log "Cloning dotfiles to $DOTFILES_DIR..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  ok "Dotfiles cloned"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "════════════════════════════════════════"
  echo "  dotfiles bootstrap — $PLATFORM"
  echo "════════════════════════════════════════"
  echo ""

  install_nix
  clone_dotfiles

  echo ""
  echo "════════════════════════════════════════"
  ok "Dependencies installed!"
  echo ""
  echo "  Next steps:"
  echo "    1. Restart your shell so 'nix' is on PATH: exec \$SHELL -l"
  echo "    2. cd $DOTFILES_DIR && make install"
  echo "════════════════════════════════════════"
}

main "$@"
