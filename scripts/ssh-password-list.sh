#!/usr/bin/env bash
# List all stored SSH passwords
# Usage: ssh-password-list.sh

set -euo pipefail

PASSWORDS_FILE="${HOME}/.ssh/passwords.yaml"

if [ ! -f "$PASSWORDS_FILE" ]; then
    echo "No passwords file found at: $PASSWORDS_FILE"
    echo "Run 'make decrypt-ssh' first, or add passwords with: ssh-password-add"
    exit 0
fi

echo "Stored SSH connection profiles:"
echo ""

# The passwords.yaml file is already decrypted, no need for SOPS
yq eval '.hosts | to_entries | .[] | "  " + .key + " -> " + .value.user + "@" + .value.hostname + ":" + (.value.port | tostring)' "$PASSWORDS_FILE"
