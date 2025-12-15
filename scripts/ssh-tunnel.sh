#!/usr/bin/env bash
# SSH tunnel management with saved profiles
# Usage: ssh-tunnel <profile-name>
#    or: ssh-tunnel add <profile-name> <host-alias> <port-forwards...>
#    or: ssh-tunnel list

set -euo pipefail

COMMAND="${1:-}"
TUNNELS_FILE="${HOME}/.ssh/tunnels.yaml"
DOTFILES_DIR="${HOME}/Documents/projects/dotfiles"
TUNNELS_FILE_ENC="${DOTFILES_DIR}/secrets/encrypted/ssh/tunnels.sops.yaml"
AGE_KEY="${HOME}/.config/sops/age/keys.txt"
AGE_PUBKEY="age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas"

show_usage() {
    cat <<EOF
Usage:
  ssh-tunnel <profile>                      Connect to saved tunnel
  ssh-tunnel add <profile> <host> <ports>   Save tunnel profile
  ssh-tunnel list                           List tunnels

Examples:
  ssh-tunnel add mysql-prod server1 3306:localhost:3306
  ssh-tunnel mysql-prod
EOF
}

# Load tunnel config
load_config() {
    if [ -f "$TUNNELS_FILE" ]; then
        cat "$TUNNELS_FILE"
    elif [ -f "$TUNNELS_FILE_ENC" ]; then
        SOPS_AGE_KEY_FILE="$AGE_KEY" sops --decrypt "$TUNNELS_FILE_ENC"
    else
        echo "tunnels: {}"
    fi
}

# List tunnels
list_tunnels() {
    local config_data=$(load_config)
    local tunnels=$(echo "$config_data" | yq eval '.tunnels | keys | .[]' - 2>/dev/null)

    if [ -z "$tunnels" ] || [ "$tunnels" = "null" ]; then
        echo "No tunnels configured"
        exit 0
    fi

    while IFS= read -r name; do
        local host=$(echo "$config_data" | yq eval ".tunnels.${name}.host" -)
        local forwards=$(echo "$config_data" | yq eval ".tunnels.${name}.forwards[]" - 2>/dev/null | tr '\n' ' ')
        echo "$name -> $host ($forwards)"
    done <<< "$tunnels"
}

# Add tunnel profile
add_tunnel() {
    local name="$1"
    local host="$2"
    shift 2
    local forwards=("$@")

    [ ${#forwards[@]} -eq 0 ] && { show_usage; exit 1; }

    local current_data=$(load_config)
    current_data=$(echo "$current_data" | yq eval ".tunnels.${name}.host = \"${host}\" | .tunnels.${name}.forwards = []" -)
    for forward in "${forwards[@]}"; do
        current_data=$(echo "$current_data" | yq eval ".tunnels.${name}.forwards += [\"${forward}\"]" -)
    done

    # Save to temp file
    echo "$current_data" > "$TUNNELS_FILE"

    # Encrypt with SOPS
    mkdir -p "$(dirname "$TUNNELS_FILE_ENC")"
    SOPS_AGE_KEY_FILE="$AGE_KEY" SOPS_AGE_RECIPIENTS="$AGE_PUBKEY" sops --encrypt --input-type yaml --output-type yaml "$TUNNELS_FILE" > "$TUNNELS_FILE_ENC"

    echo "✓ Saved: $name"
    echo "Connect: ssh-tunnel $name"
}

# Connect to tunnel
connect_tunnel() {
    local name="$1"
    local config_data=$(load_config)

    local host=$(echo "$config_data" | yq eval ".tunnels.${name}.host" -)
    [ "$host" = "null" ] || [ -z "$host" ] && { echo "Tunnel not found: $name"; exit 1; }

    local forwards=$(echo "$config_data" | yq eval ".tunnels.${name}.forwards[]" - 2>/dev/null)
    [ -z "$forwards" ] && { echo "No forwards configured"; exit 1; }

    local tunnel_args=""
    while IFS= read -r forward; do
        tunnel_args="$tunnel_args -L $forward"
        echo "Forward: $forward"
    done <<< "$forwards"

    # Check if password exists for this host
    if ssh-password-list 2>/dev/null | grep -q "^${host}:"; then
        # Use password-based authentication
        ssh-with-password "$host" $tunnel_args -N
    else
        # Fall back to regular SSH (uses SSH config with keys)
        echo "Using SSH config authentication (key-based)..."
        # Add keepalive settings to prevent connection drops
        ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes $tunnel_args -N "$host"
    fi
}

# Main logic
case "$COMMAND" in
    ""|help|-h|--help)
        show_usage
        exit 0
        ;;
    list|ls)
        list_tunnels
        exit 0
        ;;
    add)
        [ $# -lt 4 ] && { show_usage; exit 1; }
        shift
        add_tunnel "$@"
        ;;
    *)
        connect_tunnel "$COMMAND"
        ;;
esac
