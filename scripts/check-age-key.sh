#!/usr/bin/env bash
# scripts/check-age-key.sh
# Ensure ~/.config/sops/age/keys.txt exists before install.
# If missing, prompts user to paste the key or derive it from id_ed25519.

set -euo pipefail

AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [[ -f "$AGE_KEY_FILE" ]]; then
  log_info "Age key found at $AGE_KEY_FILE"
  exit 0
fi

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Age key not found: $AGE_KEY_FILE${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo ""
echo "How do you want to set up the age key?"
echo ""
echo "  1) Paste the key content (from password manager / backup)"
echo "  2) Derive from ~/.ssh/id_ed25519 (requires ssh-to-age)"
echo "  3) Generate a new key (first-time setup only)"
echo "  4) Abort"
echo ""
read -r -p "Choice [1-4]: " choice
echo ""

mkdir -p "$(dirname "$AGE_KEY_FILE")"

case "$choice" in
  1)
    echo -e "${CYAN}Paste your age private key below.${NC}"
    echo -e "${CYAN}It starts with 'AGE-SECRET-KEY-...'. Type EOF on a new line when done.${NC}"
    echo ""
    local_lines=()
    while IFS= read -r line; do
      [[ "$line" == "EOF" ]] && break
      local_lines+=("$line")
    done
    printf '%s\n' "${local_lines[@]}" > "$AGE_KEY_FILE"
    chmod 600 "$AGE_KEY_FILE"
    log_info "Age key saved to $AGE_KEY_FILE"
    ;;

  2)
    SSH_KEY="$HOME/.ssh/id_ed25519"
    if [[ ! -f "$SSH_KEY" ]]; then
      log_error "SSH key not found: $SSH_KEY"
      exit 1
    fi
    if ! command -v ssh-to-age &>/dev/null; then
      log_warn "ssh-to-age not found. Installing via nix..."
      nix profile install nixpkgs#ssh-to-age
    fi
    ssh-to-age -private-key -i "$SSH_KEY" > "$AGE_KEY_FILE"
    chmod 600 "$AGE_KEY_FILE"
    log_info "Age key derived from $SSH_KEY and saved to $AGE_KEY_FILE"
    echo ""
    echo -e "${CYAN}Your age public key (recipient):${NC}"
    ssh-to-age < "${SSH_KEY}.pub"
    echo ""
    log_warn "Make sure secrets/config.yaml uses this recipient if you re-encrypt."
    ;;

  3)
    if ! command -v age-keygen &>/dev/null; then
      log_warn "age-keygen not found. Installing via nix..."
      nix profile install nixpkgs#age
    fi
    age-keygen -o "$AGE_KEY_FILE"
    chmod 600 "$AGE_KEY_FILE"
    log_info "New age key generated at $AGE_KEY_FILE"
    echo ""
    echo -e "${CYAN}Your age public key (recipient):${NC}"
    age-keygen -y "$AGE_KEY_FILE"
    echo ""
    log_warn "Update secrets/config.yaml with this recipient, then re-encrypt all secrets."
    ;;

  4)
    log_warn "Aborted. Age key is required to decrypt secrets."
    exit 1
    ;;

  *)
    log_error "Invalid choice."
    exit 1
    ;;
esac

echo ""
log_info "Age key is ready. Continuing with install..."
