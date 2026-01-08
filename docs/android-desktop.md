# Android Desktop Environment (DEPRECATED)

**⚠️ This feature has been removed as of January 2026**

The XFCE4 desktop environment via VNC has been removed from the Android configuration to minimize system resources and improve battery life.

## Why Removed?

1. **Battery Impact**: VNC server + X11 + XFCE4 consumed significant battery
2. **Resource Heavy**: ~40+ packages for desktop environment
3. **Limited Use Case**: Terminal-only usage is more practical on Android
4. **Better Alternatives**:
   - Use SSH for remote terminal access (still available)
   - Use Android's native apps for browsing/GUI tasks
   - Use JuiceSSH or Termux on Android for local terminal

## What's Still Available

The Android (nix-on-droid) configuration still provides:
- ✅ **SSH Server** (port 8022) - Connect from other devices
- ✅ **Full terminal environment** with tmux, neovim, git, etc.
- ✅ **All development tools** (Go, Rust, Python, Node.js)
- ✅ **Secrets management** via sops/age

## How to Connect

```bash
# From another device
ssh -p 8022 nix-on-droid@<android-ip>

# Auto-generated key is in ~/.ssh/android_client_key
```

## If You Need Desktop Functionality

If you absolutely need a graphical desktop on Android:

### Option 1: Use Termux:X11 (Recommended)
- Install Termux:X11 from F-Droid
- Lighter weight than VNC
- Better performance

### Option 2: Keep Old Version
If you need the old XFCE4 setup, checkout git history:
```bash
git log --all --oneline -- docs/android-desktop.md
git checkout <commit-before-removal> -- modules/android.nix scripts/android-desktop.sh
```

---

**Last desktop version:** Commit prior to VNC removal (January 2026)
**Current focus:** Minimal, battery-efficient terminal environment
