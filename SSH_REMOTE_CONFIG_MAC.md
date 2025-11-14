# Quick Mac SSH Config for Remote Low-Latency

## Add This to Your ~/.ssh/config

```ssh
# ============================================================
# Android SSH - Remote Low-Latency Configuration
# ============================================================

# Local Network Connection (fastest)
Host android-local
    HostName <android-local-ip>  # e.g., 192.168.1.100
    Port 8022
    User nix-on-droid
    IdentityFile ~/.ssh/android_client_key

    # Performance optimizations
    Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
    KexAlgorithms curve25519-sha256
    Compression no
    GSSAPIAuthentication no

    # Connection multiplexing (instant reconnects!)
    ControlMaster auto
    ControlPath ~/.ssh/control-%C
    ControlPersist 10m

    # Keep alive
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Remote Connection via Tailscale (RECOMMENDED)
Host android-tailscale
    HostName <tailscale-ip>  # e.g., 100.x.x.x
    Port 8022
    User nix-on-droid
    IdentityFile ~/.ssh/android_client_key

    # Performance optimizations
    Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
    KexAlgorithms curve25519-sha256
    Compression no
    GSSAPIAuthentication no

    # Connection multiplexing
    ControlMaster auto
    ControlPath ~/.ssh/control-%C
    ControlPersist 10m

    # Remote connection keep-alive (more frequent)
    ServerAliveInterval 30
    ServerAliveCountMax 6
    TCPKeepAlive yes

    # Low-latency QoS
    IPQoS lowdelay throughput

# Remote Connection via Public IP/DynDNS
Host android-remote
    HostName <your-public-ip-or-hostname>  # e.g., myphone.duckdns.org
    Port 8022
    User nix-on-droid
    IdentityFile ~/.ssh/android_client_key

    # Performance optimizations
    Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
    KexAlgorithms curve25519-sha256
    Compression no
    GSSAPIAuthentication no

    # Connection multiplexing
    ControlMaster auto
    ControlPath ~/.ssh/control-%C
    ControlPersist 10m

    # Remote connection keep-alive
    ServerAliveInterval 30
    ServerAliveCountMax 6
    TCPKeepAlive yes

    # Low-latency QoS
    IPQoS lowdelay throughput

# Simple alias (use whichever connection method you prefer)
Host android
    HostName <your-preferred-connection>
    Port 8022
    User nix-on-droid
    IdentityFile ~/.ssh/android_client_key

    # Performance optimizations
    Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
    KexAlgorithms curve25519-sha256
    Compression no
    GSSAPIAuthentication no

    # Connection multiplexing
    ControlMaster auto
    ControlPath ~/.ssh/control-%C
    ControlPersist 10m

    # Keep alive
    ServerAliveInterval 30
    ServerAliveCountMax 6
    TCPKeepAlive yes

    # Low-latency QoS
    IPQoS lowdelay throughput
```

## Usage

### SSH Connections
```bash
# Local network (fastest)
ssh android-local

# Via Tailscale VPN (best for remote)
ssh android-tailscale

# Via public IP (if you have port forwarding)
ssh android-remote

# Simple alias
ssh android
```

### Mosh Connections (Best for High Latency)
```bash
# Via Tailscale (recommended)
mosh android-tailscale

# Via public IP
mosh android-remote

# Or simple
mosh android
```

### File Transfers
```bash
# SCP
scp file.txt android:~/

# RSYNC (faster for multiple files)
rsync -avz -e ssh ./myproject/ android:~/myproject/
```

### Port Forwarding
```bash
# Forward remote port 8080 to local 8080
ssh -L 8080:localhost:8080 android

# Reverse forward local port 3000 to remote 3000
ssh -R 3000:localhost:3000 android
```

## Quick Setup Checklist

- [ ] Add SSH config above to `~/.ssh/config`
- [ ] Replace `<android-local-ip>` with your Android's local IP
- [ ] Replace `<tailscale-ip>` with Tailscale IP (if using Tailscale)
- [ ] Replace `<your-public-ip-or-hostname>` with your public IP/DynDNS
- [ ] Install Mosh: `brew install mosh`
- [ ] Test connection: `ssh android`
- [ ] Test Mosh: `mosh android`

## Pro Tips

### Find Your Android's IP

**Local IP:**
```bash
# On Android
ip addr show | grep "inet "
```

**Tailscale IP:**
```bash
# On Android (after installing Tailscale)
tailscale ip
```

### Test Latency
```bash
# Ping test
ping <android-ip>

# Connection speed test
time ssh android "echo hello"

# Second connection (should be instant with ControlMaster)
time ssh android "echo hello"
```

### Best Practices

1. **Local network:** Use `android-local` (fastest)
2. **Remote with Tailscale:** Use `android-tailscale` (secure + fast)
3. **High latency remote:** Use `mosh android-tailscale` (feels instant)
4. **File transfers:** Always use SSH (Mosh doesn't support file transfer)

## What Each Setting Does

```ssh
# Speed optimizations
Ciphers chacha20-poly1305@openssh.com     # Fast encryption for ARM
MACs hmac-sha2-256-etm@openssh.com        # Fast message authentication
KexAlgorithms curve25519-sha256            # Fast key exchange
Compression no                             # Less CPU, lower latency

# Connection reuse (INSTANT subsequent connections)
ControlMaster auto                         # Enable connection sharing
ControlPath ~/.ssh/control-%C              # Socket file location
ControlPersist 10m                         # Keep alive for 10 minutes

# Keep connection alive
ServerAliveInterval 30                     # Send keep-alive every 30s
ServerAliveCountMax 6                      # Disconnect after 6 missed (3min)
TCPKeepAlive yes                           # TCP-level keep-alive

# Quality of Service
IPQoS lowdelay throughput                  # Prioritize low latency

# Fast login
GSSAPIAuthentication no                    # Skip Kerberos (faster)
```

## Troubleshooting

### "Control socket connect: No such file or directory"
```bash
# Clean up stale control sockets
rm ~/.ssh/control-*
```

### Slow first connection
- This is normal! Subsequent connections will be instant with ControlMaster

### Connection keeps dropping
```bash
# Increase keep-alive frequency in ~/.ssh/config
ServerAliveInterval 15  # More frequent
```

### Want to force new connection (bypass ControlMaster)
```bash
ssh -o ControlMaster=no android
```

---

**You're all set! Enjoy low-latency SSH to your Android!** 🚀
