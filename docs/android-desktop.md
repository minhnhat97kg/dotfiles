# Android Desktop Environment Setup

Complete XFCE4 desktop environment running on Android via VNC, powered by Nix and nix-on-droid.

## Overview

This configuration provides a full Linux desktop experience on Android devices using:
- **XFCE4** - Lightweight, feature-rich desktop environment
- **TigerVNC** - High-performance VNC server for remote display
- **PulseAudio** - Audio support for desktop applications
- **Firefox** - Full desktop web browser
- **Complete dev environment** - All development tools accessible in GUI

## Features

### Desktop Components
- **Window Manager**: XFCE4 with compositing support
- **File Managers**: Thunar (XFCE), PCManFM (lightweight alternative)
- **Terminal Emulators**: XFCE4 Terminal, xterm
- **Web Browser**: Firefox
- **Audio**: PulseAudio with pavucontrol mixer
- **Utilities**: Screenshot tool, task manager, clipboard manager

### Development Tools (GUI Access)
All terminal-based tools are available in the desktop environment:
- Code editors: Neovim (terminal-based)
- Version control: Git, Lazygit
- Databases: PostgreSQL, MySQL with clients (pgcli, mycli)
- Programming languages: Go, Rust, Python, Node.js, Java
- Build tools: Make, Gradle, Maven

## Quick Start

### 1. Deploy Configuration

```bash
# On your development machine with the dotfiles repo
cd ~/Documents/projects/dotfiles
make android  # Build and deploy to Android device
```

This will:
- Install XFCE4 and all desktop packages
- Configure VNC server with automatic startup scripts
- Set up SSH server for remote access
- Deploy the `android-desktop` management tool

### 2. Start Desktop Environment

On your Android device (in Termux/Nix-on-Droid):

```bash
# Simple command
desktop start

# Or use the full script
android-desktop start
```

### 3. Connect via VNC

**Get connection info:**
```bash
desktop info
```

**Connect from:**
- **Desktop**: RealVNC Viewer, TigerVNC Viewer
- **Mobile**: VNC Viewer app (RealVNC from Play Store/F-Droid)

**Default credentials:**
- Host: `<your-device-ip>:5901`
- Password: `vnc123` (change immediately!)

## Management Commands

The `android-desktop` (alias: `desktop`) tool provides easy management:

```bash
# Desktop management
desktop start       # Start VNC server with XFCE4
desktop stop        # Stop VNC server
desktop restart     # Restart VNC server
desktop status      # Show VNC and SSH status
desktop info        # Show connection details

# Security
desktop password    # Change VNC password

# SSH management
desktop ssh-start   # Start SSH server
desktop ssh-stop    # Stop SSH server
desktop ssh-status  # Check SSH status
```

## Configuration Details

### VNC Server Settings

**Location**: `~/.vnc/`
**Key files**:
- `start-vnc.sh` - Start script (auto-generated)
- `stop-vnc.sh` - Stop script (auto-generated)
- `status-vnc.sh` - Status checker (auto-generated)
- `xstartup` - Session startup script (launches XFCE4)
- `passwd` - VNC password file

**Default settings**:
- Display: `:1`
- Port: `5901`
- Resolution: `1920x1080`
- Color depth: `24-bit`
- Network: Accessible from any device on same network

### SSH Server Settings

**Location**: `~/.ssh/`
**Port**: `8022`
**Authentication**: Public key (auto-generated key at `~/.ssh/android_client_key`)

### XFCE4 Session Startup

The VNC `xstartup` script automatically:
1. Starts D-Bus session bus (required for XFCE)
2. Launches PulseAudio for audio
3. Sets keyboard layout to US
4. Starts XFCE4 session manager
5. Provides fallback terminal if XFCE fails

## Customization

### Change Resolution

Edit `~/.vnc/start-vnc.sh`:
```bash
GEOMETRY="1920x1080"  # Change to your preferred resolution
```

Common resolutions:
- Phone landscape: `1920x1080`, `2560x1440`
- Phone portrait: `1080x1920`
- Tablet: `2048x1536`, `2560x1600`

### Change VNC Password

```bash
# Interactive password change
vncpasswd

# Or use the helper command
desktop password
```

### Customize XFCE4

All XFCE4 settings are persistent in `~/.config/xfce4/`:
- Panel configuration
- Desktop appearance
- Keyboard shortcuts
- Window manager settings

Changes are preserved across VNC restarts.

### Add More Applications

Edit `modules/android.nix` in the dotfiles repo:

```nix
environment.packages = with pkgs; [
  # Add your packages here
  gimp          # Image editor
  libreoffice   # Office suite
  vlc           # Media player
  # ... etc
];
```

Then redeploy:
```bash
make android
```

## Troubleshooting

### VNC Won't Start

**Check logs:**
```bash
cat ~/.vnc/*.log
```

**Common issues:**
1. **Display lock exists**:
   ```bash
   rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
   desktop start
   ```

2. **Port already in use**:
   ```bash
   pkill Xvnc
   desktop start
   ```

### XFCE4 Doesn't Appear

**Verify XFCE4 is running:**
```bash
# In a VNC session terminal
pgrep -fl xfce4-session
```

**If not running, check xstartup:**
```bash
cat ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup
```

**Manually test XFCE4:**
```bash
# Set display
export DISPLAY=:1

# Start D-Bus
eval $(dbus-launch --sh-syntax)

# Try starting XFCE
startxfce4
```

### Audio Not Working

**Start PulseAudio:**
```bash
pulseaudio --start
```

**Check audio devices:**
```bash
pactl list sinks
```

**Use pavucontrol in desktop:**
- Open Applications → Multimedia → PulseAudio Volume Control
- Check output devices and levels

### Black Screen in VNC

**Possible causes:**
1. VNC client compatibility - Try different VNC client
2. Color depth mismatch - Edit `~/.vnc/start-vnc.sh` and change `DEPTH=24` to `DEPTH=16`
3. Resolution too high - Reduce `GEOMETRY` setting

### SSH Connection Refused

**Check SSH server:**
```bash
desktop ssh-status
```

**Restart SSH:**
```bash
desktop ssh-stop
desktop ssh-start
```

**Verify port:**
```bash
# Should show sshd on port 8022
netstat -tlnp | grep 8022
```

## Performance Optimization

### Reduce Resolution for Better Performance

Lower resolutions use less bandwidth and CPU:
```bash
# Edit start script
vim ~/.vnc/start-vnc.sh
# Change: GEOMETRY="1280x720"
```

### Disable Compositing

In XFCE4 desktop:
1. Settings → Window Manager Tweaks
2. Compositor tab
3. Uncheck "Enable display compositing"

### Use Lightweight Alternatives

- **File manager**: Use PCManFM instead of Thunar
- **Terminal**: Use xterm instead of xfce4-terminal
- **Browser**: Consider links2 or w3m for text browsing

## Security Best Practices

### 1. Change Default VNC Password Immediately

```bash
desktop password
# Enter strong password when prompted
```

### 2. Use SSH Tunneling (Recommended)

Instead of exposing VNC to network, tunnel through SSH:

```bash
# On client machine
ssh -p 8022 -L 5901:localhost:5901 nix-on-droid@<device-ip>

# Then connect VNC to localhost:5901
```

### 3. Firewall Rules

If your device supports iptables:
```bash
# Allow only local network VNC access
iptables -A INPUT -p tcp --dport 5901 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 5901 -j DROP
```

### 4. Use VNC over Tailscale/WireGuard

For remote access, use a VPN instead of exposing ports publicly.

## Advanced Usage

### Auto-start VNC on Boot

The VNC server doesn't auto-start by default. To enable:

Add to `~/.zshrc` or `~/.bashrc`:
```bash
# Auto-start VNC if not running
if ! pgrep -f "Xvnc.*:1" >/dev/null 2>&1; then
    ~/.vnc/start-vnc.sh
fi
```

### Multiple VNC Sessions

Run additional VNC servers on different displays:

```bash
vncserver :2 -geometry 1920x1080 -depth 24 -localhost no -rfbport 5902
```

### X11 Forwarding Over SSH

Access individual GUI apps without full desktop:

```bash
# On client
ssh -p 8022 -X nix-on-droid@<device-ip>

# Then run GUI apps
firefox &
```

### Screen Recording/Sharing

Use built-in XFCE4 screenshooter:
- Applications → Accessories → Screenshot

Or install additional tools via `modules/android.nix`:
```nix
simplescreenrecorder  # Screen recording
```

## Integration with Development Workflow

### Use Desktop GUI Tools Alongside Terminal

The desktop environment has full access to your terminal environment:

**Open terminal in XFCE:**
```bash
xfce4-terminal
# Full access to: nvim, git, lazygit, tmux, etc.
```

**Run GUI development tools:**
- Use Firefox for web development/testing
- Open multiple terminals in desktop
- Use graphical file manager for file operations
- Visual database tools (install via packages)

### Accessing Files

Files are shared between terminal and desktop:
- Home directory: Same as terminal (`~`)
- Dotfiles: All your configs are available
- Projects: Access development projects directly

## Package Reference

### Currently Installed Desktop Packages

**Core XFCE4:**
- xfce4-panel - Desktop panel
- xfce4-session - Session manager
- xfce4-settings - System settings
- xfconf - Configuration storage
- xfdesktop - Desktop manager
- xfwm4 - Window manager

**XFCE4 Applications:**
- thunar - File manager
- xfce4-terminal - Terminal emulator
- xfce4-screenshooter - Screenshots
- xfce4-taskmanager - Task/process manager
- xfce4-clipman-plugin - Clipboard manager
- xfce4-pulseaudio-plugin - Audio control

**System:**
- tigervnc - VNC server
- xorg.xorgserver - X11 display server
- dbus - Inter-process communication
- mesa - Graphics libraries
- pulseaudio - Audio server
- pavucontrol - Audio mixer GUI

**Applications:**
- firefox - Web browser
- xterm - Terminal emulator
- pcmanfm - Lightweight file manager

## Comparison with Other Approaches

| Approach | Pros | Cons |
|----------|------|------|
| **Nix-on-Droid + VNC** (This setup) | • Declarative config<br>• Easy package management<br>• Cross-platform dotfiles<br>• Reproducible | • Larger installation<br>• VNC latency |
| **Termux proot-distro** | • Smaller footprint<br>• Multiple distros | • Manual setup<br>• Less integrated |
| **Termux:X11** | • Native Android X11<br>• Better performance | • Requires Termux:X11 app<br>• Less flexible |
| **Linux Deploy (chroot)** | • Traditional Linux<br>• Full systemd | • Requires root<br>• More complex |

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Main project documentation
- [Nix-on-Droid Bootstrap](https://github.com/DianQK/nix-on-termux-bootstrap) - Original inspiration
- [Termux-Desktops](https://github.com/LinuxDroidMaster/Termux-Desktops) - Alternative desktop setups
- [XFCE Documentation](https://docs.xfce.org/) - Official XFCE4 docs

## Contributing

Found issues or have improvements? The configuration is defined in:
- `modules/android.nix` - Main Android configuration
- `scripts/android-desktop.sh` - Management script
- VNC startup scripts - Auto-generated by build activation

## License

This configuration is part of the dotfiles repository and follows the same license.
