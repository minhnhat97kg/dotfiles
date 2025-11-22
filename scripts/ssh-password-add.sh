#!/usr/bin/env bash
# Add SSH password to encrypted storage
# Usage: ssh-password-add.sh <host-alias> <user> <hostname> [port]

set -euo pipefail

HOST_ALIAS="${1:-}"
USER="${2:-}"
HOSTNAME="${3:-}"
PORT="${4:-22}"

PASSWORDS_FILE="${HOME}/.ssh/passwords.yaml"
DOTFILES_DIR="${HOME}/Documents/projects/dotfiles"
PASSWORDS_FILE_ENC="${DOTFILES_DIR}/secrets/encrypted/ssh/passwords.sops.yaml"
AGE_KEY="${HOME}/.config/sops/age/keys.txt"
AGE_PUBKEY="age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas"

if [ -z "$HOST_ALIAS" ] || [ -z "$USER" ] || [ -z "$HOSTNAME" ]; then
    echo "Usage: $0 <host-alias> <user> <hostname> [port]"
    echo ""
    echo "Example:"
    echo "  $0 myserver deploy 192.168.1.100 22"
    exit 1
fi

# Prompt for password
read -s -p "Enter SSH password for ${USER}@${HOSTNAME}: " PASSWORD
echo ""

if [ -z "$PASSWORD" ]; then
    echo "Error: Password cannot be empty"
    exit 1
fi

# Initialize or load existing passwords
if [ -f "$PASSWORDS_FILE_ENC" ]; then
    # Decrypt existing encrypted file
    CURRENT_DATA=$(SOPS_AGE_KEY_FILE="$AGE_KEY" sops --decrypt "$PASSWORDS_FILE_ENC")
else
    CURRENT_DATA="hosts: {}"
fi

# Add new host entry using yq with environment variable to avoid shell escaping issues
UPDATED_DATA=$(echo "$CURRENT_DATA" | yq eval ".hosts.${HOST_ALIAS}.user = \"${USER}\" | .hosts.${HOST_ALIAS}.hostname = \"${HOSTNAME}\" | .hosts.${HOST_ALIAS}.port = ${PORT}" - | \
    PASS="$PASSWORD" yq eval ".hosts.${HOST_ALIAS}.password = env(PASS)" -)

# Save to temp unencrypted file
echo "$UPDATED_DATA" > "$PASSWORDS_FILE"

# Encrypt with SOPS
mkdir -p "$(dirname "$PASSWORDS_FILE_ENC")"
SOPS_AGE_KEY_FILE="$AGE_KEY" SOPS_AGE_RECIPIENTS="$AGE_PUBKEY" sops --encrypt --input-type yaml --output-type yaml "$PASSWORDS_FILE" > "$PASSWORDS_FILE_ENC"

echo "✓ Password encrypted and saved to: $PASSWORDS_FILE_ENC"
echo ""
echo "To connect, use:"
echo "  sshp $HOST_ALIAS"
echo ""
echo "To commit the encrypted file:"
echo "  cd $DOTFILES_DIR"
echo "  git add secrets/encrypted/ssh/passwords.sops.yaml"
echo "  git commit -m \"Add SSH password for $HOST_ALIAS\""
