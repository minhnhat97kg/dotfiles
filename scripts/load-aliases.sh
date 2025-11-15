#!/usr/bin/env bash
# Load aliases from shell/aliases.yaml into zsh

ALIASES_FILE="$HOME/.config/dotfiles/shell/aliases.yaml"

if [ ! -f "$ALIASES_FILE" ]; then
    exit 0
fi

# Check if yq is available
if ! command -v yq &> /dev/null && ! command -v yq-go &> /dev/null; then
    exit 0
fi

YQ_CMD="yq"
command -v yq-go &> /dev/null && YQ_CMD="yq-go"

# Load all aliases
$YQ_CMD eval '.aliases | to_entries | .[] | "alias " + .key + "=\"" + .value + "\""' "$ALIASES_FILE" 2>/dev/null
