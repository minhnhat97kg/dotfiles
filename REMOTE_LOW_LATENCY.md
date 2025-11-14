# Remote Low-Latency SSH Configuration

## Overview

For **remote connections** (over internet, not local WiFi), you need different optimizations than local network. This guide covers making your Android SSH server accessible remotely with the lowest possible latency.

## Table of Contents

1. [Network Setup Options](#network-setup-options)
2. [SSH Optimizations for Remote](#ssh-optimizations-for-remote)
3. [Mosh for Remote (Best for High Latency)](#mosh-for-remote)
4. [TCP Tuning](#tcp-tuning)
5. [Connection Methods Comparison](#connection-methods-comparison)

---

## Network Setup Options

### Option 1: Tailscale/Wireguard VPN (RECOMMENDED)

**Best for: Security + Speed + Easy Setup**

#### Why VPN?
- ✅ Direct peer-to-peer connection (lowest latency)
- ✅ No port forwarding needed
- ✅ Encrypted tunnel
- ✅ Works behind NAT/firewalls
- ✅ Stable IP address for your Android

#### Setup Tailscale (Easiest)

**On Android:**
```bash
# Add to flake.nix environment.packages
tailscale

# After rebuild, start Tailscale
sudo tailscaled
tailscale up
```

**On Mac:**
```bash
brew install tailscale
tailscale up
```

**Connect:**
```bash
# Your Android gets a stable 100.x.x.x IP
ssh -p 8022 nix-on-droid@100.x.x.x
```

**Latency:** Near-direct connection (adds ~5-10ms vs direct)

---

### Option 2: Port Forwarding + Dynamic DNS

**Best for: Home network with public IP**

#### Setup:
1. **Configure router port forwarding:**
   - External port: 8022
   - Internal IP: Your Android's local IP
   - Internal port: 8022

2. **Get your public IP:**
   ```bash
   curl ifconfig.me
   ```

3. **Use Dynamic DNS (if IP changes):**
   - Services: No-IP, DuckDNS, Cloudflare
   - Get hostname like: myphone.duckdns.org

4. **Connect:**
   ```bash
   ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@myphone.duckdns.org
   ```

**Security Warning:** Exposing SSH to internet - use strong keys only!

---

### Option 3: Reverse SSH Tunnel

**Best for: When you can't forward ports (behind CGNAT/strict firewall)**

#### Setup:

**You need a VPS/cloud server with public IP.**

**On Android:**
```bash
# Create reverse tunnel to VPS
ssh -R 8022:localhost:8022 user@your-vps.com -N -f
```

**On Mac:**
```bash
# Connect through VPS
ssh -p 8022 nix-on-droid@your-vps.com
```

**Latency:** Adds VPS hop (~20-50ms extra)

---

## SSH Optimizations for Remote

### Current Config (Already Optimized!)

Your current SSH config is **already optimized** for low latency:

```ssh
# In flake.nix sshd_config
Ciphers chacha20-poly1305@openssh.com        # Fast encryption
MACs hmac-sha2-256-etm@openssh.com           # Fast authentication
KexAlgorithms curve25519-sha256              # Fast key exchange
Compression no                                # Less CPU, lower latency
UseDNS no                                     # Skip DNS lookups
```

### Additional Remote Optimizations

For **even lower latency** on remote connections, add these to your **Mac's ~/.ssh/config**:

```ssh
Host android-remote
    HostName <public-ip-or-hostname>
    Port 8022
    User nix-on-droid
    IdentityFile ~/.ssh/android_client_key

    # Performance (already matching server)
    Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
    KexAlgorithms curve25519-sha256
    Compression no
    GSSAPIAuthentication no

    # TCP optimizations for remote connections
    TCPKeepAlive yes
    ServerAliveInterval 30
    ServerAliveCountMax 6

    # Connection multiplexing (reuse connection)
    ControlMaster auto
    ControlPath ~/.ssh/control-%C
    ControlPersist 10m

    # Reduce latency for interactive use
    IPQoS lowdelay throughput
```

---

## Mosh for Remote (BEST for High Latency)

### Why Mosh is Better for Remote

On **high-latency connections** (>50ms), Mosh provides:
- ✅ **Instant local echo** - typing feels instant even with 200ms+ latency
- ✅ **Survives disconnects** - network hiccups don't kill session
- ✅ **Roaming** - switch from WiFi to mobile data seamlessly
- ✅ **No freezing** - works smoothly even with packet loss

### Setup Mosh for Remote

**On Android (already included in your config):**
```bash
# Mosh is already in environment.packages
# Just rebuild
nix-on-droid switch --flake ~/dotfiles#default
```

**On Mac:**
```bash
brew install mosh
```

**Connect with Mosh:**

```bash
# Method 1: Direct (if you have public IP/port forwarding)
mosh --ssh="ssh -p 8022 -i ~/.ssh/android_client_key" nix-on-droid@<public-ip>

# Method 2: Through SSH config
mosh android-remote

# Method 3: Through Tailscale (best!)
mosh --ssh="ssh -p 8022 -i ~/.ssh/android_client_key" nix-on-droid@100.x.x.x
```

**Add to ~/.ssh/config for easy Mosh:**

```ssh
Host android-mosh
    HostName <public-ip-or-tailscale-ip>
    Port 8022
    User nix-on-droid
    IdentityFile ~/.ssh/android_client_key
```

Then just:
```bash
mosh android-mosh
```

### Mosh Port Requirements

Mosh uses **UDP ports 60000-61000**.

**If using port forwarding, forward UDP 60000-61000 to your Android.**

**With Tailscale/VPN: No extra ports needed!** (another reason to use VPN)

---

## TCP Tuning

### On Mac (Client-side tuning)

Add to `~/.ssh/config`:

```ssh
# Enable TCP Fast Open (reduces handshake latency)
# Requires macOS 10.11+
Host *
    # TCP optimizations
    IPQoS lowdelay throughput
    TCPKeepAlive yes
```

### On Android (Server-side tuning)

For advanced users, you can tune TCP parameters:

```bash
# Add to a startup script or activation
# Increase TCP buffer sizes for high-latency connections
sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216'
sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216'

# Enable TCP Fast Open
sysctl -w net.ipv4.tcp_fastopen=3

# BBR congestion control (if kernel supports)
sysctl -w net.ipv4.tcp_congestion_control=bbr
```

**Note:** Android/Termux may not allow these without root.

---

## Connection Methods Comparison

### For Remote Connections

| Method | Latency | Ease of Setup | Security | Works Behind NAT |
|--------|---------|---------------|----------|------------------|
| **Tailscale VPN** | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐⭐⭐ Very Easy | ⭐⭐⭐⭐⭐ Excellent | ✅ Yes |
| **Mosh over VPN** | ⭐⭐⭐⭐⭐ Best for high latency | ⭐⭐⭐⭐ Easy | ⭐⭐⭐⭐⭐ Excellent | ✅ Yes |
| **SSH + Port Forward** | ⭐⭐⭐⭐ Good | ⭐⭐⭐ Medium | ⭐⭐⭐⭐ Good | ⚠️ Needs router access |
| **Mosh + Port Forward** | ⭐⭐⭐⭐⭐ Best for high latency | ⭐⭐ Complex (many ports) | ⭐⭐⭐⭐ Good | ⚠️ Needs router access |
| **Reverse SSH Tunnel** | ⭐⭐⭐ OK (VPS hop) | ⭐⭐ Requires VPS | ⭐⭐⭐⭐ Good | ✅ Yes |

---

## Recommended Setup (My Opinion)

### Best Overall: **Tailscale + Mosh**

1. **Install Tailscale** (easy VPN setup)
2. **Use Mosh for interactive work** (feels instant even on high latency)
3. **Use SSH for file transfers** (scp/rsync don't work with Mosh)

### Setup Commands:

**Add Tailscale to flake.nix:**
```nix
environment.packages = with pkgs; [
  # ... existing packages
  tailscale
];
```

**Connect:**
```bash
# Interactive work (instant feel even with lag)
mosh --ssh="ssh -p 8022 -i ~/.ssh/android_client_key" nix-on-droid@100.x.x.x

# File transfers
scp -P 8022 -i ~/.ssh/android_client_key file.txt nix-on-droid@100.x.x.x:~/

# Tmux sessions (best of both worlds)
mosh android-tailscale -- tmux attach
```

---

## Testing Your Latency

### Check Current Latency:

```bash
# Ping your Android
ping <android-ip>

# SSH connection time
time ssh android-remote "echo hello"

# Interactive feel test (with Mosh vs SSH)
# Type in both and compare responsiveness
ssh android-remote
mosh android-remote
```

### Expected Latencies:

| Connection Type | Typical Latency |
|-----------------|----------------|
| Local WiFi | 1-5ms |
| Tailscale (same city) | 10-20ms |
| Tailscale (cross-country) | 50-100ms |
| Port Forward (same ISP) | 10-30ms |
| Port Forward (different ISP) | 30-100ms |
| Mobile data | 30-150ms |
| Reverse tunnel (VPS) | 50-200ms |

**With Mosh:** Typing feels instant regardless of latency! 🚀

---

## Troubleshooting

### High Latency Issues

```bash
# Trace route to find slow hops
traceroute <android-ip>

# Check if using optimal cipher
ssh -v android-remote 2>&1 | grep "cipher:"
# Should see: chacha20-poly1305

# Test with/without compression
ssh -o Compression=yes android-remote "time ls"
ssh -o Compression=no android-remote "time ls"
```

### Mosh Not Working Remotely

```bash
# Check UDP ports are open
# Test from Mac
nc -u -v <android-ip> 60001

# Make sure mosh-server is in PATH on Android
which mosh-server

# Verbose Mosh output
mosh -v android-remote
```

### Connection Drops

```bash
# Increase keep-alive frequency
# In ~/.ssh/config
ServerAliveInterval 15  # Send keep-alive every 15s
ServerAliveCountMax 3   # Disconnect after 3 missed
```

---

## Summary

**For Low-Latency Remote Connection:**

1. **Network:** Use Tailscale VPN (easiest + fastest)
2. **Interactive work:** Use Mosh (feels instant)
3. **File transfers:** Use SSH with optimized config (already done!)
4. **Long sessions:** Mosh + tmux (survives everything)

**Your current SSH config is already optimized!** Just need to:
1. Choose network setup (Tailscale recommended)
2. Use Mosh for interactive work on high-latency connections

See `MOSH_VS_SSH.md` for more details on when to use each tool!
