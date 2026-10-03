#!/usr/bin/env bash
# Author: nathan.huynh
# bootstrap.sh — gets a fresh machine ready for `make install`.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<github-user>/dotfiles/main/bootstrap.sh | bash
#   OR: clone repo first, then: ./bootstrap.sh
#
# What this does (each step is skipped if already done):
#   1. Detects the platform (macOS, Ubuntu/Linux, Termux, Android/nix-on-droid)
#   2. Installs what that platform needs before Nix can take over:
#        macOS   Xcode Command Line Tools (git, make) + Homebrew (nix-darwin's
#                homebrew module installs the kitty/alacritty casks through it)
#        Linux   git, curl, make, xz via apt
#        Termux  git, make via pkg
#        Android nothing — nix-on-droid ships Nix; git comes from `nix shell`
#   3. Installs Nix (macOS: official installer; Linux: Determinate Systems)
#   4. Clones the dotfiles repo
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
# Same order as the Makefile's detection, which picks the apply command.
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
  else
    echo "linux"
  fi
}

PLATFORM=$(detect_platform)
log "Detected platform: $PLATFORM ($(uname -s) $(uname -m))"

# ─── Platform prerequisites ───────────────────────────────────────────────────
install_prereqs() {
  case "$PLATFORM" in
    macos)
      if ! xcode-select -p &>/dev/null; then
        log "Installing Xcode Command Line Tools (git, make) — accept the dialog..."
        xcode-select --install || true
        until xcode-select -p &>/dev/null; do sleep 5; done
      fi
      ok "Xcode Command Line Tools present"
      if ! command -v brew &>/dev/null && [ ! -x /opt/homebrew/bin/brew ]; then
        log "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      ok "Homebrew present"
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        log "Installing git, curl, make, xz via apt..."
        sudo apt-get update -qq
        sudo apt-get install -y git curl make xz-utils
      else
        warn "No apt-get — make sure git, curl, make and xz are installed"
      fi
      ;;
    termux)
      log "Installing git, make via pkg..."
      pkg install -y git make
      ;;
    android) ;;
  esac
}

# ─── Install Nix (skip if already installed) ──────────────────────────────────
install_nix() {
  if [ "$PLATFORM" = "termux" ]; then
    # Plain Termux is bionic, not glibc: neither installer supports it.
    command -v nix &>/dev/null || warn "Nix isn't installed and no installer supports plain Termux — install it manually, or use the nix-on-droid app instead"
    return
  fi
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
  if command -v git &>/dev/null; then
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  else
    nix --extra-experimental-features "nix-command flakes" shell nixpkgs#git -c git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
  ok "Dotfiles cloned"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "════════════════════════════════════════"
  echo "  dotfiles bootstrap — $PLATFORM"
  echo "════════════════════════════════════════"
  echo ""

  install_prereqs
  install_nix
  clone_dotfiles

  echo ""
  echo "════════════════════════════════════════"
  ok "Dependencies installed!"
  echo ""
  echo "  Next steps:"
  echo "    1. Restart your shell so 'nix' is on PATH: exec \$SHELL -l"
  case "$PLATFORM" in
    android) echo "    2. cd $DOTFILES_DIR && nix-on-droid switch --flake ." ;;
    linux)   echo "    2. cd $DOTFILES_DIR && make apt-deps && make install" ;;
    *)       echo "    2. cd $DOTFILES_DIR && make install" ;;
  esac
  echo "════════════════════════════════════════"
}

main "$@"
