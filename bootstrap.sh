#!/usr/bin/env bash
# bootstrap.sh — OTG dotfiles setup for any Linux machine or Termux
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/minhnhat97kg/dotfiles/main/bootstrap.sh | bash
#   OR: clone repo first, then: ./bootstrap.sh
#
# What this does:
#   1. Installs Nix (Determinate Systems installer)
#   2. (home-manager applied via 'nix run' — no separate install needed)
#   3. Clones dotfiles
#   4. Prompts for age private key → decrypts SSH keys + git configs
#   5. Applies home-manager config for the detected platform
set -euo pipefail

DOTFILES_REPO="https://github.com/minhnhat97kg/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

log()  { echo "▶ $*"; }
ok()   { echo "✓ $*"; }
warn() { echo "⚠ $*"; }
die()  { echo "✗ $*" >&2; exit 1; }

# ─── Detect platform ──────────────────────────────────────────────────────────
detect_platform() {
  if command -v nix-on-droid &>/dev/null; then
    echo "android"
  elif [ -d /data/data/com.termux ] || [ -n "$TERMUX_VERSION" ]; then
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
  # We use `nix run` from the flake itself so the home-manager version always
  # matches the pinned input in flake.lock — no global install needed.
  ok "home-manager will be applied via 'nix run' (no global install required)"
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

# ─── Setup age key + decrypt secrets ──────────────────────────────────────────
setup_secrets() {
  AGE_KEY_DIR="$HOME/.config/sops/age"
  AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"

  if [ -f "$AGE_KEY_FILE" ]; then
    ok "Age key already present at $AGE_KEY_FILE"
  else
    echo ""
    echo "  ┌─────────────────────────────────────────────────┐"
    echo "  │  Paste your age PRIVATE key below.              │"
    echo "  │  It starts with: AGE-SECRET-KEY-1...            │"
    echo "  │  Press Enter then Ctrl+D when done.             │"
    echo "  └─────────────────────────────────────────────────┘"
    echo ""
    mkdir -p "$AGE_KEY_DIR"
    # Read multi-line input until EOF (Ctrl+D)
    AGE_KEY_CONTENT=$(cat)
    if [ -z "$AGE_KEY_CONTENT" ]; then
      warn "No age key entered — skipping secrets decryption."
      warn "Run 'cd ~/dotfiles && make decrypt' later to restore SSH keys and git configs."
      return
    fi
    printf '%s\n' "$AGE_KEY_CONTENT" > "$AGE_KEY_FILE"
    chmod 600 "$AGE_KEY_FILE"
    ok "Age key saved to $AGE_KEY_FILE"
  fi

  # Install sops + yq if missing (needed by make decrypt)
  log "Installing decrypt dependencies (sops, yq)..."
  command -v sops &>/dev/null || nix profile install nixpkgs#sops
  command -v yq   &>/dev/null || nix profile install nixpkgs#yq-go

  log "Decrypting secrets (SSH keys, git configs)..."
  cd "$DOTFILES_DIR"
  make decrypt-yes
  ok "Secrets decrypted — SSH keys and git configs restored."
}

# ─── Apply home-manager config ────────────────────────────────────────────────
apply_config() {
  log "Applying home-manager config for platform: $PLATFORM..."
  cd "$DOTFILES_DIR"

  case "$PLATFORM" in
    termux)
      nix run 'github:nix-community/home-manager' -- switch --flake .#termux
      ;;
    wsl)
      nix run 'github:nix-community/home-manager' -- switch --flake .#wsl
      ;;
    android)
      nix-on-droid switch --flake .
      ;;
    linux)
      nix run 'github:nix-community/home-manager' -- switch --flake .#ubuntu
      ;;
    *)
      die "Unknown platform: $PLATFORM"
      ;;
  esac

  ok "Configuration applied!"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "════════════════════════════════════════"
  echo "  dotfiles OTG bootstrap — $PLATFORM"
  echo "════════════════════════════════════════"
  echo ""

  install_nix
  clone_dotfiles
  setup_secrets
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
