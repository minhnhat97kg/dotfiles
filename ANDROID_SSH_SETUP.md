# Android SSH Server Setup Guide

## Overview

This guide explains how to set up and use the SSH server on your Android device with nix-on-droid.

## Initial Setup

### 1. Apply Configuration

First, apply the nix-on-droid configuration which will set up SSH:

```bash
cd ~/dotfiles
nix-on-droid switch --flake .
```

This will:
- Install OpenSSH
- Generate SSH host keys (RSA and ED25519)
- Create SSH configuration files
- Set up the authorized_keys file

### 2. Add Your Public Key

To allow connections from your computer, add your public key:

```bash
# On your Android device
echo "your-public-key-here" >> ~/.ssh/authorized_keys

# Or copy from your computer
cat ~/.ssh/id_ed25519.pub | ssh android-device "cat >> ~/.ssh/authorized_keys"
```

### 3. Start SSH Server

```bash
# Start the SSH server
sshd -f ~/.ssh/sshd_config

# Check if it's running
pgrep sshd
```

## SSH Server Configuration

### Default Settings

- **Port**: 8022 (standard SSH port 22 can't be used without root)
- **Host Keys**:
  - RSA: `~/.ssh/ssh_host_rsa_key`
  - ED25519: `~/.ssh/ssh_host_ed25519_key`
- **Config File**: `~/.ssh/sshd_config`
- **Authorized Keys**: `~/.ssh/authorized_keys`

### Configuration File Location

The SSH server configuration is at `~/.ssh/sshd_config`:

```bash
# View configuration
cat ~/.ssh/sshd_config

# Edit configuration
nvim ~/.ssh/sshd_config
```

## Usage

### Starting SSH Server

```bash
# Start SSH server
sshd -f ~/.ssh/sshd_config

# Start in foreground (for debugging)
sshd -f ~/.ssh/sshd_config -D

# Start with debug logging
sshd -f ~/.ssh/sshd_config -d
```

### Stopping SSH Server

```bash
# Find SSH server process
pgrep sshd

# Kill SSH server
pkill sshd

# Or kill specific process
kill $(pgrep sshd)
```

### Connecting from Another Device

```bash
# Get your device's IP address (on Android)
ip addr show

# Connect from another device
ssh -p 8022 username@192.168.x.x

# Or add to your ~/.ssh/config on computer:
cat >> ~/.ssh/config << EOF
Host android
    HostName 192.168.x.x
    Port 8022
    User your-username
    IdentityFile ~/.ssh/id_ed25519
EOF

# Then connect simply with:
ssh android
```

## Helper Scripts

### Auto-Start SSH Script

Create a script to start SSH automatically:

```bash
# Create startup script
cat > ~/start-sshd.sh << 'EOF'
#!/usr/bin/env bash
# Start SSH server if not already running
if ! pgrep -x sshd > /dev/null; then
    sshd -f ~/.ssh/sshd_config
    echo "SSH server started on port 8022"
else
    echo "SSH server already running"
fi
EOF

chmod +x ~/start-sshd.sh

# Run it
~/start-sshd.sh
```

### SSH Server Status Script

```bash
# Create status script
cat > ~/sshd-status.sh << 'EOF'
#!/usr/bin/env bash
if pgrep -x sshd > /dev/null; then
    echo "✓ SSH server is running"
    echo "PID: $(pgrep sshd)"
    echo "Port: 8022"
    ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print "IP: " $2}'
else
    echo "✗ SSH server is not running"
    echo "Start with: sshd -f ~/.ssh/sshd_config"
fi
EOF

chmod +x ~/sshd-status.sh

# Run it
~/sshd-status.sh
```

## Network Configuration

### Local Network Access

Your Android device needs to be on the same network as the computer you're connecting from:

```bash
# On Android - Check IP address
ip addr show wlan0 | grep "inet "

# Example output:
# inet 192.168.1.100/24
```

### Port Forwarding (Optional)

To access from outside your local network:

1. Find your Android device's local IP
2. Configure port forwarding on your router:
   - External Port: 2222 (or any available port)
   - Internal Port: 8022
   - Internal IP: Your Android device's IP

⚠️ **Security Warning**: Only do this if you:
- Use strong key-based authentication
- Keep your device updated
- Understand the security implications

## Troubleshooting

### SSH Server Won't Start

```bash
# Check for errors
sshd -f ~/.ssh/sshd_config -d

# Common issues:
# 1. Port already in use
lsof -i :8022

# 2. Permission issues
chmod 700 ~/.ssh
chmod 600 ~/.ssh/ssh_host_*_key
chmod 644 ~/.ssh/ssh_host_*_key.pub
chmod 600 ~/.ssh/sshd_config
chmod 600 ~/.ssh/authorized_keys
```

### Can't Connect from Computer

```bash
# Test from Android device first
ssh -p 8022 localhost

# Check if firewall is blocking
# (Usually not an issue on Android)

# Verify IP address
ip addr show

# Check SSH server is listening
netstat -tuln | grep 8022
```

### Permission Denied (publickey)

```bash
# Check authorized_keys format
cat ~/.ssh/authorized_keys

# Should look like:
# ssh-ed25519 AAAAC3... your@computer
# ssh-rsa AAAAB3... your@computer

# Check permissions
ls -la ~/.ssh/authorized_keys
# Should be: -rw------- (600)
```

## Security Best Practices

### 1. Key-Based Authentication Only

The default configuration disables password authentication:

```
PasswordAuthentication no
```

Never enable password authentication - use SSH keys only.

### 2. Use Strong Keys

```bash
# Generate a strong ED25519 key (on your computer)
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_android

# Or a strong RSA key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_android
```

### 3. Restrict Access

Edit `~/.ssh/sshd_config` to add:

```
# Allow only specific users
AllowUsers your-username

# Disable root login (already default)
PermitRootLogin no

# Limit connection attempts
MaxAuthTries 3
MaxSessions 2
```

### 4. Keep Software Updated

```bash
# Update nix-on-droid regularly
nix-on-droid switch --flake . --update-input nixpkgs
```

## Integration with Development

### Use as Remote Development Server

```bash
# On your computer - VSCode Remote SSH
# Install "Remote - SSH" extension
# Connect to: android device

# Use with rsync
rsync -avz -e "ssh -p 8022" ~/project/ android:~/project/

# Use with git
git remote add android ssh://android:8022/~/repos/project.git
```

### File Transfer

```bash
# SCP (from computer to Android)
scp -P 8022 file.txt android:~/

# SCP (from Android to computer)
scp -P 8022 ~/file.txt computer:~/

# SFTP
sftp -P 8022 android
```

## Advanced Configuration

### Change Default Port

Edit `~/.ssh/sshd_config`:

```
Port 9022  # Change from 8022
```

Then restart SSH server.

### Add Banner

Create a banner file:

```bash
cat > ~/.ssh/banner << 'EOF'
╔══════════════════════════════════════╗
║     Welcome to Android SSH Server    ║
║        Powered by Nix-on-Droid       ║
╚══════════════════════════════════════╝
EOF
```

Add to `~/.ssh/sshd_config`:

```
Banner ~/.ssh/banner
```

### Enable Logging

Add to `~/.ssh/sshd_config`:

```
LogLevel VERBOSE
SyslogFacility AUTH
```

## Automated Startup

### Using Termux:Boot (Recommended)

1. Install Termux:Boot from F-Droid
2. Create startup script:

```bash
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/start-sshd << 'EOF'
#!/data/data/com.termux/files/usr/bin/sh
sshd -f $HOME/.ssh/sshd_config
EOF

chmod +x ~/.termux/boot/start-sshd
```

3. Reboot device - SSH will start automatically

### Manual Startup Reminder

Add to `~/.zshrc`:

```bash
# Auto-start SSH server
if ! pgrep -x sshd > /dev/null; then
    echo "SSH server not running. Start with: ~/start-sshd.sh"
fi
```

## References

- [OpenSSH Documentation](https://www.openssh.com/)
- [Nix-on-Droid Wiki](https://github.com/nix-community/nix-on-droid/wiki)
- [SSH Best Practices](https://infosec.mozilla.org/guidelines/openssh)

---

## Quick Reference

```bash
# Start SSH server
sshd -f ~/.ssh/sshd_config

# Stop SSH server
pkill sshd

# Check status
pgrep sshd

# View logs (if configured)
cat ~/.ssh/sshd.log

# Connect from computer
ssh -p 8022 user@device-ip

# Add public key
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

# Get device IP
ip addr show wlan0 | grep "inet "
```

---

**Status**: ✅ SSH Server Configured

**Default Port**: 8022

**Authentication**: Public key only (secure)

**Auto-start**: Configure with Termux:Boot or manual script
