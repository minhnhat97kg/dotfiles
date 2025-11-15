#!/usr/bin/env bash
# Generic script to decrypt secrets based on secrets.yaml config

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

# Get age private key from config
AGE_KEY=$($YQ_CMD eval '.age.private_key' "$CONFIG_FILE")
AGE_KEY="${AGE_KEY/#\~/$HOME}"

if [ ! -f "$AGE_KEY" ]; then
    echo "Error: Age private key not found: $AGE_KEY"
    echo "Please ensure your age key exists at this location"
    exit 1
fi

# Parse and process each secret
echo "Decrypting secrets based on $CONFIG_FILE"
echo ""

total=$($YQ_CMD eval '.secrets | length' "$CONFIG_FILE")
decrypted_count=0
copied_count=0
skipped_count=0

for i in $(seq 0 $((total - 1))); do
    name=$($YQ_CMD eval ".secrets[$i].name" "$CONFIG_FILE")
    source=$($YQ_CMD eval ".secrets[$i].source" "$CONFIG_FILE")
    encrypted=$($YQ_CMD eval ".secrets[$i].encrypted" "$CONFIG_FILE")
    should_encrypt=$($YQ_CMD eval ".secrets[$i].encrypt" "$CONFIG_FILE")
    mode=$($YQ_CMD eval ".secrets[$i].mode" "$CONFIG_FILE")

    # Expand ~ in paths
    source="${source/#\~/$HOME}"
    encrypted="$DOTFILES_DIR/$encrypted"

    echo "[$((i+1))/$total] $name"

    # Check if encrypted file exists
    if [ ! -f "$encrypted" ]; then
        echo "  ⚠️  Encrypted file not found: $encrypted (skipping)"
        skipped_count=$((skipped_count + 1))
        echo ""
        continue
    fi

    # Create directory for source file
    mkdir -p "$(dirname "$source")"

    if [ "$should_encrypt" = "true" ]; then
        # Decrypt the file
        age --decrypt -i "$AGE_KEY" "$encrypted" > "$source"
        echo "  ✓ Decrypted: $encrypted → $source"
        decrypted_count=$((decrypted_count + 1))
    else
        # Just copy the file (was not encrypted)
        cp "$encrypted" "$source"
        echo "  ✓ Copied: $encrypted → $source"
        copied_count=$((copied_count + 1))
    fi

    # Set permissions
    chmod "$mode" "$source"
    echo "  ✓ Permissions: $mode"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:"
echo "  Decrypted: $decrypted_count"
echo "  Copied:    $copied_count"
echo "  Skipped:   $skipped_count"
echo "  Total:     $total"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
