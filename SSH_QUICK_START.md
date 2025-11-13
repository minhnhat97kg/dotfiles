# Zero-Config SSH Server - Quick Start Guide

## Features
- ✅ **No RSA** - Uses Ed25519 and ECDSA only
- ✅ **No passwords** - Auto-generated SSH keys
- ✅ **Zero configuration** - Everything set up automatically
- ✅ **Secure** - Key-based authentication only

## Setup (One-Time)

### On Android (Nix-on-Droid)

1. **Rebuild your configuration:**
   ```bash
   nix-on-droid switch --flake /path/to/dotfiles#default
   ```

2. **Start the SSH server:**
   ```bash
   ~/.ssh/start-sshd.sh
   ```
   This will display connection instructions automatically.

3. **Get the client key:**
   ```bash
   ~/.ssh/show-client-key.sh
   ```
   Copy the entire output and run it on your Mac.

### On Your Mac (Client)

1. **Save the key** (from the output of `show-client-key.sh`):
   ```bash
   cat > ~/.ssh/android_client_key << 'EOF'
   [paste the private key here]
   EOF
   chmod 600 ~/.ssh/android_client_key
   ```

2. **Connect:**
   ```bash
   ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@<android-ip>
   ```

## Daily Use

### On Android
```bash
# Start SSH server
~/.ssh/start-sshd.sh

# Stop SSH server
~/.ssh/stop-sshd.sh

# Show connection info
~/.ssh/show-client-key.sh
```

### On Mac
```bash
# Connect
ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@<android-ip>

# Optional: Add to ~/.ssh/config for easier access
cat >> ~/.ssh/config << 'EOF'
Host android
    HostName <android-ip>
    Port 8022
    User nix-on-droid
    IdentityFile ~/.ssh/android_client_key
EOF

# Then just use:
ssh android
```

## How It Works

1. **Auto-generated keys during activation:**
   - Server host keys: `ssh_host_ed25519_key`, `ssh_host_ecdsa_key`
   - Client key: `android_client_key` (auto-added to `authorized_keys`)

2. **Passwordless authentication:**
   - No password needed
   - Uses the auto-generated Ed25519 key
   - Key is both on Android and copied to your Mac

3. **Security:**
   - No password authentication enabled
   - No RSA keys (modern crypto only)
   - Port 8022 (non-standard for extra security)

## Troubleshooting

### SSH server won't start
```bash
# Check the log
cat ~/.ssh/sshd.log
```

### Can't connect from Mac
```bash
# Verify key permissions
chmod 600 ~/.ssh/android_client_key

# Test connection with verbose output
ssh -v -p 8022 -i ~/.ssh/android_client_key nix-on-droid@<android-ip>
```

### Find Android IP address
```bash
# On Android
ip addr show | grep inet
```
