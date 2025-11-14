# Mosh vs SSH - Usage Guide

## TL;DR

- **Local network, fast WiFi**: Use SSH (faster, full features)
- **Mobile/unstable network**: Use Mosh (survives disconnects)
- **File transfers**: Always use SSH/SCP
- **Port forwarding**: Always use SSH

## Setup

### Install Mosh on Mac

```bash
brew install mosh
```

### Enable on Android

Already included! Just rebuild:
```bash
nix-on-droid switch --flake ~/dotfiles#default
```

## Usage

### With SSH (Optimized - Recommended for local network)

```bash
# First connection
ssh android

# Subsequent connections (instant with ControlMaster!)
ssh android

# File transfer
scp file.txt android:~/

# Port forwarding
ssh -L 8080:localhost:8080 android
```

### With Mosh (Recommended for mobile/unstable connections)

```bash
# Connect with Mosh (requires SSH running first)
mosh --ssh="ssh -p 8022 -i ~/.ssh/android_client_key" nix-on-droid@<android-ip>

# Or add to ~/.ssh/config and use:
mosh android

# That's it! Now your session survives:
# - Network changes (WiFi → mobile data)
# - IP address changes
# - Laptop sleep/wake
# - Packet loss
```

## Feature Comparison

| Feature | SSH (Optimized) | Mosh |
|---------|----------------|------|
| **Speed on good network** | ⭐⭐⭐⭐⭐ Very fast | ⭐⭐⭐⭐ Fast |
| **Speed on bad network** | ⭐⭐ Freezes | ⭐⭐⭐⭐⭐ Excellent |
| **Roaming** | ❌ Disconnects | ✅ Seamless |
| **Instant reconnect** | ✅ (ControlMaster) | ✅ (Always) |
| **File transfer** | ✅ SCP/RSYNC | ❌ No |
| **Port forwarding** | ✅ Yes | ❌ No |
| **Scrollback** | ✅ Full history | ⚠️ Limited |
| **Latency hiding** | ❌ No | ✅ Local echo |
| **Firewall friendly** | ✅ One port | ⚠️ UDP range |
| **Security** | ✅ Excellent | ✅ Excellent |

## Real-World Scenarios

### Scenario 1: Working from home (same WiFi)
**Use: SSH**
```bash
ssh android
# Fast, full features, ControlMaster for instant reconnects
```

### Scenario 2: Phone tethering while traveling
**Use: Mosh**
```bash
mosh android
# Session survives network hiccups, switching between WiFi/mobile
```

### Scenario 3: Deploying code
**Use: SSH**
```bash
git push android:~/myproject
scp -r dist/ android:~/
```

### Scenario 4: Long-running interactive session on train
**Use: Mosh**
```bash
mosh android
# Tunnels change, IP changes, but session persists
```

### Scenario 5: Running tmux session
**Use: Either!**
```bash
# With SSH (fastest on good network)
ssh android -t tmux attach

# With Mosh (survives network changes)
mosh android -- tmux attach
```

## Optimized SSH Config with Mosh Support

Add to `~/.ssh/config`:

```ssh
Host android
    HostName <android-ip>
    Port 8022
    User nix-on-droid
    IdentityFile ~/.ssh/android_client_key

    # SSH performance optimizations
    Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
    KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
    Compression no
    GSSAPIAuthentication no

    # Connection multiplexing (instant subsequent connections)
    ControlMaster auto
    ControlPath ~/.ssh/control-%r@%h:%p
    ControlPersist 10m

    # Keep alive
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Then use:
```bash
# Fast SSH
ssh android

# Or Mosh (uses SSH config automatically)
mosh android
```

## Performance Testing

### Test SSH speed:
```bash
# Connection time
time ssh android "echo hello"

# Second connection (should be instant with ControlMaster)
time ssh android "echo hello"

# Throughput
ssh android "dd if=/dev/zero bs=1M count=100 2>/dev/null" | pv > /dev/null
```

### Test Mosh responsiveness:
```bash
# Connect with Mosh
mosh android

# Try typing - you'll see instant local echo
# Try disconnecting WiFi - session persists!
```

## My Recommendation

### Daily Setup:

1. **Keep SSH optimized** (what you have now) for:
   - Local network work
   - File transfers
   - Scripts and automation
   - Port forwarding

2. **Use Mosh when**:
   - On mobile/tethered connection
   - Poor WiFi signal
   - Moving between locations
   - Long interactive sessions

### Alias Shortcuts

Add to `~/.zshrc` on Mac:
```bash
# Fast SSH connection
alias android-ssh='ssh android'

# Mosh for unstable connections
alias android-mosh='mosh android'

# SSH with tmux
alias android-tmux='ssh android -t tmux attach || tmux new'

# Mosh with tmux
alias android-mosh-tmux='mosh android -- tmux attach || tmux new'
```

## Technical Details

### How SSH Works:
- TCP connection
- Encryption/decryption per packet
- Waits for ACK before showing output
- Breaks on network change

### How Mosh Works:
- Uses SSH for initial auth, then switches to UDP
- State synchronization protocol (SSP)
- Predictive local echo
- Survives IP changes
- UDP ports 60000-61000

### Why Both?

SSH is **faster and more feature-rich** on stable networks.
Mosh is **more resilient and responsive** on unstable networks.

**Having both gives you the best tool for each situation!**

## Troubleshooting

### Mosh won't connect
```bash
# Make sure SSH works first
ssh android

# Check mosh is installed on both sides
which mosh

# Verbose output
mosh -v android
```

### Mosh is slow
```bash
# Mosh requires UDP ports - check firewall
# For local network, SSH is usually faster anyway
```

### SSH is slow
```bash
# Make sure you're using optimized config
ssh -v android 2>&1 | grep -i "cipher\|mac\|kex"
```

## Conclusion

**Best of both worlds**:
- SSH for speed and features (local network)
- Mosh for resilience (mobile/unstable network)

You now have both! 🚀
