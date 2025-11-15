#!/usr/bin/env bash
# Generic script to encrypt secrets based on secrets.yaml config

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$DOTFILES_DIR/secrets.yaml"

# Check dependencies (use yq-go if available, otherwise yq)
YQ_CMD=""
if command -v yq-go &> /dev/null; then
    YQ_CMD="yq-go"
elif command -v yq &> /dev/null; then
    YQ_CMD="yq"
else
    echo "Error: yq is required but not installed"
    echo "Install: nix-env -iA nixpkgs.yq-go"
    exit 1
fi

if ! command -v age &> /dev/null; then
    echo "Error: age is required but not installed"
    echo "Install: brew install age"
    exit 1
fi

# Check config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Get age public key from config
AGE_PUBKEY=$($YQ_CMD eval '.age.public_key' "$CONFIG_FILE")

if [ -z "$AGE_PUBKEY" ] || [ "$AGE_PUBKEY" = "null" ]; then
    echo "Error: age.public_key not found in $CONFIG_FILE"
    exit 1
fi

# Parse and process each secret
echo "Encrypting secrets based on $CONFIG_FILE"
echo ""

total=$($YQ_CMD eval '.secrets | length' "$CONFIG_FILE")
encrypted_count=0
copied_count=0
skipped_count=0

for i in $(seq 0 $((total - 1))); do
    name=$($YQ_CMD eval ".secrets[$i].name" "$CONFIG_FILE")
    source=$($YQ_CMD eval ".secrets[$i].source" "$CONFIG_FILE")
    encrypted=$($YQ_CMD eval ".secrets[$i].encrypted" "$CONFIG_FILE")
    should_encrypt=$($YQ_CMD eval ".secrets[$i].encrypt" "$CONFIG_FILE")

    # Expand ~ in paths
    source="${source/#\~/$HOME}"
    encrypted="$DOTFILES_DIR/$encrypted"

    echo "[$((i+1))/$total] $name"

    # Check if source exists
    if [ ! -f "$source" ]; then
        echo "  ⚠️  Source not found: $source (skipping)"
        skipped_count=$((skipped_count + 1))
        echo ""
        continue
    fi

    # Create directory for encrypted file
    mkdir -p "$(dirname "$encrypted")"

    if [ "$should_encrypt" = "true" ]; then
        # Encrypt the file
        cat "$source" | age -r "$AGE_PUBKEY" > "$encrypted"
        echo "  ✓ Encrypted: $source → $encrypted"
        encrypted_count=$((encrypted_count + 1))
    else
        # Just copy the file (no encryption)
        cp "$source" "$encrypted"
        echo "  ✓ Copied: $source → $encrypted"
        copied_count=$((copied_count + 1))
    fi

    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:"
echo "  Encrypted: $encrypted_count"
echo "  Copied:    $copied_count"
echo "  Skipped:   $skipped_count"
echo "  Total:     $total"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
