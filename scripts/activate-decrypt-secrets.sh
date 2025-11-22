#!/usr/bin/env bash
# scripts/activate-decrypt-secrets.sh
# Activation script for secrets decryption during nix switch/build
# Usage: ./activate-decrypt-secrets.sh [DOTFILES_DIR] [USERNAME]

set -euo pipefail

# Parameters
DOTFILES_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
USERNAME="${2:-$USER}"
AGE_KEY_FILE="/Users/${USERNAME}/.config/sops/age/keys.txt"
DECRYPT_SCRIPT="$DOTFILES_DIR/scripts/secrets-decrypt.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Print header
echo ""
echo "┌────────────────────────────────────────────────────┐"
echo "│  Secrets Management                                │"
echo "└────────────────────────────────────────────────────┘"
echo ""

# Check if age key exists
if [ ! -f "$AGE_KEY_FILE" ]; then
  log_warn "Age key not found at: $AGE_KEY_FILE"
  echo ""
  echo "Please enter your age private key (it will be saved securely):"
  echo "Paste the entire key including the 'AGE-SECRET-KEY-...' line"
  echo "Press Ctrl+D when done:"
  echo ""

  # Create directory if it doesn't exist
  sudo -u "$USERNAME" mkdir -p "$(dirname "$AGE_KEY_FILE")"

  # Read the key from user input
  sudo -u "$USERNAME" tee "$AGE_KEY_FILE" > /dev/null

  # Set proper permissions
  sudo -u "$USERNAME" chmod 600 "$AGE_KEY_FILE"

  echo ""
  log_info "Age key saved to: $AGE_KEY_FILE"
  echo ""
fi

# Validate age key format
if [ -f "$AGE_KEY_FILE" ]; then
  if ! grep -q "AGE-SECRET-KEY-" "$AGE_KEY_FILE" 2>/dev/null; then
    log_error "Invalid age key format in: $AGE_KEY_FILE"
    echo ""
    echo "The key file should contain a line starting with 'AGE-SECRET-KEY-'"
    echo "Please fix the key file and run the command again."
    echo ""
    exit 1
  fi

  # Run decrypt script if it exists (it will prompt for confirmation)
  if [ -f "$DECRYPT_SCRIPT" ]; then
    if sudo -u "$USERNAME" "$DECRYPT_SCRIPT"; then
      log_info "Secrets decryption completed"
    else
      log_warn "Secrets decryption skipped or failed"
    fi
  else
    log_warn "Decrypt script not found: $DECRYPT_SCRIPT"
  fi
  echo ""
fi
