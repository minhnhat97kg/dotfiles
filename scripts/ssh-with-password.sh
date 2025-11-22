#!/usr/bin/env bash
# SSH connection helper with encrypted password storage
# Usage: ssh-with-password.sh <host-alias> [options]
#
# Options:
#   -L <local_port>:<remote_host>:<remote_port>  Local port forwarding
#   -R <remote_port>:<local_host>:<local_port>   Remote port forwarding
#   -D <local_port>                               Dynamic SOCKS proxy
#   -N                                            No command (tunnel only)

set -euo pipefail

HOST_ALIAS="${1:-}"
shift || true  # Remove host-alias from args, keep remaining options

PASSWORDS_FILE="${HOME}/.ssh/passwords.yaml"
AGE_KEY="${HOME}/.config/sops/age/keys.txt"
SSH_EXTRA_ARGS="$@"  # Capture all remaining arguments

if [ -z "$HOST_ALIAS" ]; then
    echo "Usage: $0 <host-alias>"
    echo ""
    echo "Available hosts:"
    if [ -f "$PASSWORDS_FILE" ]; then
        yq eval '.hosts | keys | .[]' "$PASSWORDS_FILE" 2>/dev/null || echo "  (none configured)"
    else
        echo "  (passwords file not found: $PASSWORDS_FILE)"
        echo "  Run 'make decrypt-ssh' or add passwords with: ssh-password-add"
    fi
    exit 1
fi

if [ ! -f "$PASSWORDS_FILE" ]; then
    echo "Error: Passwords file not found: $PASSWORDS_FILE"
    echo "Run 'make decrypt-ssh' first, or create it with: ssh-password-add"
    exit 1
fi

# Extract password from decrypted file
PASSWORD=$(yq eval ".hosts.${HOST_ALIAS}.password" "$PASSWORDS_FILE" 2>/dev/null)

if [ "$PASSWORD" = "null" ] || [ -z "$PASSWORD" ]; then
    echo "Error: No password found for host: $HOST_ALIAS"
    echo ""
    echo "Available hosts:"
    yq eval '.hosts | keys | .[]' "$PASSWORDS_FILE"
    exit 1
fi

# Get additional connection parameters
USER=$(yq eval ".hosts.${HOST_ALIAS}.user" "$PASSWORDS_FILE" 2>/dev/null)
HOSTNAME=$(yq eval ".hosts.${HOST_ALIAS}.hostname" "$PASSWORDS_FILE" 2>/dev/null)
PORT=$(yq eval ".hosts.${HOST_ALIAS}.port" "$PASSWORDS_FILE" 2>/dev/null)

# Default port
if [ "$PORT" = "null" ] || [ -z "$PORT" ]; then
    PORT=22
fi

# Build SSH command
SSH_CMD="ssh"
if [ "$PORT" != "22" ]; then
    SSH_CMD="$SSH_CMD -p $PORT"
fi

# Force password authentication and disable key-based auth
SSH_CMD="$SSH_CMD -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no"

# Add extra arguments (tunnels, etc.)
if [ -n "$SSH_EXTRA_ARGS" ]; then
    SSH_CMD="$SSH_CMD $SSH_EXTRA_ARGS"
fi

# Display connection info
if [ "$USER" != "null" ] && [ -n "$USER" ]; then
    CONNECTION_STR="${USER}@${HOSTNAME}:${PORT}"
else
    CONNECTION_STR="${HOSTNAME}:${PORT}"
fi

# Show tunnel info if present
TUNNEL_INFO=""
if echo "$SSH_EXTRA_ARGS" | grep -q -- "-L"; then
    TUNNEL_INFO=" [Local forwarding]"
elif echo "$SSH_EXTRA_ARGS" | grep -q -- "-R"; then
    TUNNEL_INFO=" [Remote forwarding]"
elif echo "$SSH_EXTRA_ARGS" | grep -q -- "-D"; then
    TUNNEL_INFO=" [SOCKS proxy]"
fi

echo "Connecting to ${HOST_ALIAS} (${CONNECTION_STR})${TUNNEL_INFO}..."

# Connect and capture exit code
if [ "$USER" != "null" ] && [ -n "$USER" ]; then
    sshpass -p "$PASSWORD" $SSH_CMD "${USER}@${HOSTNAME}"
    EXIT_CODE=$?
else
    sshpass -p "$PASSWORD" $SSH_CMD "$HOSTNAME"
    EXIT_CODE=$?
fi

# Notify result
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Connection to ${HOST_ALIAS} closed successfully"
else
    echo "✗ Connection to ${HOST_ALIAS} failed (exit code: $EXIT_CODE)"
    exit $EXIT_CODE
fi
