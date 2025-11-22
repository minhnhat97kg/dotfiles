#!/usr/bin/env bash
# scripts/activate-decrypt-secrets-android.sh
# Activation script for secrets decryption on Android during nix-on-droid switch
# Usage: ./activate-decrypt-secrets-android.sh [DOTFILES_DIR]

set -euo pipefail

# Parameters
DOTFILES_DIR="${1:-$HOME/dotfiles}"
AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
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

# Check for required commands
check_dependencies() {
  local missing=()
  for cmd in sops yq-go; do
    if ! command -v "$cmd" &> /dev/null; then
      missing+=("$cmd")
    fi
  done

  # Also check for yq if yq-go is missing
  if [[ " ${missing[@]} " =~ " yq-go " ]] && ! command -v yq &> /dev/null; then
    : # yq-go is already in missing list
  elif [[ " ${missing[@]} " =~ " yq-go " ]] && command -v yq &> /dev/null; then
    # Remove yq-go from missing since we have yq
    missing=("${missing[@]/yq-go/}")
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing required commands: ${missing[*]}"
    log_warn "Please install missing packages and rebuild:"
    log_warn "  nix-on-droid switch --flake ."
    return 1
  fi
  return 0
}

# Print header
echo ""
echo "┌────────────────────────────────────────────────────┐"
echo "│  Secrets Management                                │"
echo "└────────────────────────────────────────────────────┘"
echo ""

# Check dependencies first
if ! check_dependencies; then
  echo ""
  exit 0  # Don't fail the build, just skip
fi

# Check if age key exists
if [ ! -f "$AGE_KEY_FILE" ]; then
  log_warn "Age key not found at: $AGE_KEY_FILE"
  echo ""
  echo "Please enter your age private key (it will be saved securely):"
  echo "Paste the entire key including the 'AGE-SECRET-KEY-...' line"
  echo "Press Ctrl+D when done:"
  echo ""

  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$AGE_KEY_FILE")"

  # Read the key from user input
  tee "$AGE_KEY_FILE" > /dev/null

  # Set proper permissions
  chmod 600 "$AGE_KEY_FILE"

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
    if "$DECRYPT_SCRIPT"; then
      log_info "Secrets decryption completed"
    else
      log_warn "Secrets decryption skipped or failed"
    fi
  else
    log_warn "Decrypt script not found: $DECRYPT_SCRIPT"
  fi
  echo ""
fi
