#!/usr/bin/env bash
# bootstrap.sh — OTG dotfiles setup for any Linux machine or Termux
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/nhath/dotfiles/main/bootstrap.sh | bash
#   OR: clone repo first, then: ./bootstrap.sh
#
# Assumptions:
#   - You have manually placed your age key at ~/.config/sops/age/keys.txt
#     (copy it before running, or run: make decrypt after bootstrap)
#   - Internet access available
set -euo pipefail

DOTFILES_REPO="https://github.com/nhath/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

log()  { echo "▶ $*"; }
ok()   { echo "✓ $*"; }
warn() { echo "⚠ $*"; }
die()  { echo "✗ $*" >&2; exit 1; }

# ─── Detect platform ──────────────────────────────────────────────────────────
detect_platform() {
  if [ -d /data/data/com.termux ]; then
    echo "termux"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "linux"
  fi
}

PLATFORM=$(detect_platform)
log "Detected platform: $PLATFORM"

# ─── Install Nix (skip if already installed) ──────────────────────────────────
install_nix() {
  if command -v nix &>/dev/null; then
    ok "Nix already installed: $(nix --version)"
    return
  fi

  log "Installing Nix via Determinate Systems installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

  # Source nix into current shell
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  ok "Nix installed: $(nix --version)"
}

# ─── Install home-manager ─────────────────────────────────────────────────────
install_home_manager() {
  if command -v home-manager &>/dev/null; then
    ok "home-manager already installed"
    return
  fi

  log "Installing home-manager..."
  nix profile install nixpkgs#home-manager
  ok "home-manager installed"
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

# ─── Check age key ────────────────────────────────────────────────────────────
check_age_key() {
  AGE_KEY="$HOME/.config/sops/age/keys.txt"
  if [ -f "$AGE_KEY" ]; then
    ok "Age key found at $AGE_KEY"
    return
  fi

  warn "Age key NOT found at $AGE_KEY"
  echo ""
  echo "  To decrypt secrets, you need to copy your age private key:"
  echo "    mkdir -p ~/.config/sops/age"
  echo "    # Copy your key content into:"
  echo "    nano ~/.config/sops/age/keys.txt"
  echo ""
  echo "  Continuing without secrets — run 'make decrypt' from $DOTFILES_DIR later."
}

# ─── Apply home-manager config ────────────────────────────────────────────────
apply_config() {
  log "Applying home-manager config for platform: $PLATFORM..."
  cd "$DOTFILES_DIR"

  case "$PLATFORM" in
    termux)
      home-manager switch --flake .#termux
      ;;
    wsl)
      home-manager switch --flake .#wsl
      ;;
    linux)
      home-manager switch --flake .#ubuntu
      ;;
    *)
      die "Unknown platform: $PLATFORM"
      ;;
  esac

  ok "home-manager config applied!"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "════════════════════════════════════════"
  echo "  dotfiles OTG bootstrap — $PLATFORM"
  echo "════════════════════════════════════════"
  echo ""

  install_nix
  install_home_manager
  clone_dotfiles
  check_age_key
  apply_config

  echo ""
  echo "════════════════════════════════════════"
  ok "Bootstrap complete!"
  echo ""
  echo "  Next steps:"
  echo "    1. Restart your shell: exec zsh"
  if [ ! -f "$HOME/.config/sops/age/keys.txt" ]; then
    echo "    2. Copy age key, then: cd ~/dotfiles && make decrypt"
  fi
  echo "════════════════════════════════════════"
}

main "$@"
