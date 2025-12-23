{ pkgs, lib, sharedPackages, sharedHomeConfig, ... }:
{
  system.stateVersion = "24.05";

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trustedPublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  user.shell = "${pkgs.zsh}/bin/zsh";

  # All packages must be here for Android (not in home.packages)
  # due to nix-env/nix profile compatibility issues
  environment.packages = with pkgs; [
    # Editor & Terminal
    neovim
    tmux

    # Core utilities
    git
    gh
    fzf
    ripgrep
    fd
    jq
    jless
    procps
    gnugrep
    gnused
    gawk
    coreutils
    ncurses

    # Development
    go
    gcc
    gnumake
    nodejs
    delve
    goimports-reviser
    maven
    gradle

    # Rust
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    # Python
    python3
    pipx

    # Shell
    zsh
    oh-my-zsh

    # Network
    openssh
    net-tools
    mosh
    tailscale

    # Secrets
    sops
    age
    yq-go

    # Databases
    postgresql
    mysql80
    mycli
    pgcli
    # pspg - doesn't work on Android/Termux

    # HTTP
    httpie
    hurl

    # Diff/formatting
    delta
    diff-so-fancy

    # Utilities
    fx
    terraform
    direnv
    lazygit
    curl

    # X11 GUI Applications (for use with Termux-X11)
    # X11 libraries
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.xauth
    xorg.xinit
    xorg.xhost
    xorg.xorgserver  # Provides Xvfb for VNC

    # GUI Applications
    xterm
    fluxbox

    # Optional GUI apps (uncomment as needed)
    # firefox
    # gedit
    # xfce.xfce4-terminal

    # VNC (optional, for remote access to Termux-X11 session)
    x11vnc
  ];

  terminal.font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";

  # Secrets decryption activation script
  build.activation.secrets = ''
    # Export paths to required tools for the activation script
    export PATH="${pkgs.sops}/bin:${pkgs.age}/bin:${pkgs.yq-go}/bin:$PATH"

    # Run secrets activation script for Android
    DOTFILES_DIR="$HOME/dotfiles"
    ACTIVATION_SCRIPT="$DOTFILES_DIR/scripts/activate-decrypt-secrets-android.sh"

    if [ -f "$ACTIVATION_SCRIPT" ]; then
      "$ACTIVATION_SCRIPT" "$DOTFILES_DIR"
    else
      echo "⚠️  Warning: Secrets activation script not found: $ACTIVATION_SCRIPT"
    fi
  '';

  # SSH server setup
  build.activation.sshd = ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [ ! -f $HOME/.ssh/ssh_host_ed25519_key ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$HOME/.ssh/ssh_host_ed25519_key" -N ""
    fi

    if [ ! -f $HOME/.ssh/ssh_host_ecdsa_key ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ecdsa -b 521 -f "$HOME/.ssh/ssh_host_ecdsa_key" -N ""
    fi

    if [ ! -f "$HOME/.ssh/android_client_key" ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$HOME/.ssh/android_client_key" -N "" -C "auto-generated-android-client"
      echo "Generated auto-login client key: $HOME/.ssh/android_client_key"
    fi

    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"

    CLIENT_PUBKEY=$(cat "$HOME/.ssh/android_client_key.pub")
    if ! grep -qF "$CLIENT_PUBKEY" "$HOME/.ssh/authorized_keys"; then
      echo "$CLIENT_PUBKEY" >> "$HOME/.ssh/authorized_keys"
      echo "Added auto-login key to authorized_keys"
    fi

    # Always regenerate sshd_config to ensure paths are up-to-date
    cat > "$HOME/.ssh/sshd_config" <<EOF
Port 8022
ListenAddress 0.0.0.0
PidFile $HOME/.ssh/sshd.pid
HostKey $HOME/.ssh/ssh_host_ed25519_key
Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256
Compression no
UseDNS no
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile $HOME/.ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
AllowTcpForwarding yes
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes
XAuthLocation ${pkgs.xorg.xauth}/bin/xauth
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp ${pkgs.openssh}/libexec/sftp-server
EOF

    chmod 600 "$HOME/.ssh/sshd_config"

    # Generate start script with current package paths
    cat > "$HOME/.ssh/start-sshd.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

# Stop any existing sshd process
pkill -f "sshd -f \$HOME/.ssh/sshd_config" 2>/dev/null || true
sleep 0.5

LOGFILE="\$HOME/.ssh/sshd.log"
rm -f "\$LOGFILE"

${pkgs.openssh}/bin/sshd -f "\$HOME/.ssh/sshd_config" -E "\$LOGFILE" || {
  echo "sshd failed to launch." >&2
  cat "\$LOGFILE" >&2
  exit 1
}

sleep 0.3
if pgrep -f "sshd -f \$HOME/.ssh/sshd_config" >/dev/null 2>&1; then
  echo "✓ SSH server started on port 8022"
  echo "  To connect: ssh -p 8022 nix-on-droid@<device-ip>"
  echo "  To stop: ~/.ssh/stop-sshd.sh"
else
  echo "Failed to start SSH server!" >&2
  cat "\$LOGFILE" >&2
  exit 1
fi
EOF
    chmod +x "$HOME/.ssh/start-sshd.sh"

    # Generate stop script
    cat > "$HOME/.ssh/stop-sshd.sh" <<'EOF'
#!/usr/bin/env bash
if pkill -f "sshd -f $HOME/.ssh/sshd_config"; then
  echo "✓ SSH server stopped"
else
  echo "No SSH server running"
fi
EOF
    chmod +x "$HOME/.ssh/stop-sshd.sh"

    # Auto-start SSH server
    echo "Starting SSH server..."
    "$HOME/.ssh/start-sshd.sh" || echo "⚠️  SSH server failed to auto-start. Run ~/.ssh/start-sshd.sh manually"
  '';

  # Termux-X11 setup (requires Termux + termux-x11-nightly)
  build.activation.termux-x11 = ''
    mkdir -p "$HOME/.termux-x11"

    # Create connection guide
    cat > "$HOME/.termux-x11/README.md" <<'EOF'
# Termux-X11 Setup for Nix-on-Droid

## Prerequisites
1. Install Termux from F-Droid
2. Install Termux-X11 app
3. In Termux, run:
   pkg update
   pkg install x11-repo -y
   pkg install termux-x11-nightly -y

## Usage

### In Termux terminal:
termux-x11 :1 -listen tcp -ac &

### In nix-on-droid terminal:
export DISPLAY=127.0.0.1:1
xterm &
# or
fluxbox &
xterm &

### Optional - VNC access:
x11vnc -display :1 -forever -passwd YOUR_PASSWORD &
EOF

    # Create connection helper
    cat > "$HOME/.termux-x11/connect.sh" <<'EOF'
#!/usr/bin/env bash
# Connect nix-on-droid GUI apps to Termux-X11

echo "Termux-X11 Connection Helper"
echo "============================"
echo ""
echo "Make sure you've run in Termux terminal:"
echo "  termux-x11 :1 -listen tcp -ac &"
echo ""

# Set display to Termux-X11
export DISPLAY=127.0.0.1:1

# Test connection
if xdpyinfo > /dev/null 2>&1; then
    echo "✓ Connected to X server at \$DISPLAY"
else
    echo "⚠️  Cannot connect to X server"
    echo "   1. Make sure Termux-X11 app is open"
    echo "   2. Run in Termux: termux-x11 :1 -listen tcp -ac &"
    exit 1
fi

# Start GUI
if [ \$# -gt 0 ]; then
    echo "Starting: \$@"
    "\$@" &
else
    echo "Starting default session..."
    ${pkgs.fluxbox}/bin/fluxbox > "$HOME/.termux-x11/fluxbox.log" 2>&1 &
    sleep 1
    ${pkgs.xterm}/bin/xterm &
fi

echo "✓ GUI started on Termux-X11 display"
EOF
    chmod +x "$HOME/.termux-x11/connect.sh"

    # Create SSH helper
    cat > "$HOME/.termux-x11/ssh-run.sh" <<'EOF'
#!/usr/bin/env bash
# Helper to run GUI apps via SSH on Termux:X11
export DISPLAY=:0

if [ \$# -eq 0 ]; then
    cat <<HELP
Termux:X11 SSH Helper

Usage: termux-x11 <command>

Examples:
  termux-x11 xterm
  termux-x11 firefox

Note: Termux:X11 app must be running on the Android device.
      GUI apps will display on the Android screen.

Current DISPLAY: \$DISPLAY
HELP
    exit 0
fi

echo "Launching \$@ on DISPLAY=\$DISPLAY"
"\$@" > "$HOME/.termux-x11/ssh-app.log" 2>&1 &
echo "✓ Started (PID: \$!)"
echo "  GUI will appear on Android device screen"
EOF
    chmod +x "$HOME/.termux-x11/ssh-run.sh"

    # Create symlinks for easy access
    ln -sf "$HOME/.termux-x11/connect.sh" "$HOME/start-x11"
    ln -sf "$HOME/.termux-x11/ssh-run.sh" "$HOME/termux-x11"

    echo "✓ Termux:X11 configured"
    echo "  Start with: ~/start-x11"
    echo "  SSH helper: ~/termux-x11 <app>"
    echo ""
    echo "  Install Termux:X11 app from:"
    echo "  https://github.com/termux/termux-x11/releases"
  '';

  # VNC server setup (legacy/backup)
  # NOTE: Xvfb cannot run inside nix-on-droid proot due to missing setgid/setuid syscalls
  # See: https://github.com/nix-community/nix-on-droid/issues/75
  # Working approach: Run Xvfb in Termux, use x11vnc from nix to share it
  # The scripts below attempt to run Xvfb in nix but will fail - kept for reference
  build.activation.vnc = ''
    mkdir -p "$HOME/.vnc"
    chmod 700 "$HOME/.vnc"

    # Generate VNC password file if it doesn't exist
    if [ ! -f "$HOME/.vnc/passwd" ]; then
      ${pkgs.x11vnc}/bin/x11vnc -storepasswd vnc123 "$HOME/.vnc/passwd"
      echo "⚠️  Default VNC password set to 'vnc123'. Change it with: x11vnc -storepasswd"
    fi

    # Create xsessions directory for desktop session files
    # TigerVNC >= 1.13 requires desktop session files
    mkdir -p "$HOME/.local/share/xsessions"

    # Create fluxbox desktop session file
    cat > "$HOME/.local/share/xsessions/fluxbox.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Fluxbox
Comment=Lightweight window manager
Exec=${pkgs.fluxbox}/bin/startfluxbox
TryExec=${pkgs.fluxbox}/bin/fluxbox
EOF

    # VNC startup script (xstartup) - fallback for older vncserver versions
    cat > "$HOME/.vnc/xstartup" <<EOF
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Start a minimal window manager
${pkgs.fluxbox}/bin/fluxbox &

# Start a terminal emulator
${pkgs.xterm}/bin/xterm &

# Keep the X session alive
while true; do sleep 1000; done
EOF
    chmod +x "$HOME/.vnc/xstartup"

    # Generate start script with current package paths (using Xvfb + x11vnc)
    cat > "$HOME/.vnc/start-vnc.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

VNC_PORT=5901
DISPLAY_NUM=1
GEOMETRY="1920x1080"
DEPTH=24
XVFB_LOGFILE="\$HOME/.vnc/xvfb.log"
X11VNC_LOGFILE="\$HOME/.vnc/x11vnc.log"

# Stop any existing VNC/X servers
pkill -f "x11vnc.*:\$VNC_PORT" 2>/dev/null || true
pkill -f "Xvfb.*:\$DISPLAY_NUM" 2>/dev/null || true
sleep 0.5

# Clean up any stale lock files
rm -f /tmp/.X\$DISPLAY_NUM-lock
rm -f /tmp/.X11-unix/X\$DISPLAY_NUM
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Start Xvfb (X Virtual Framebuffer)
${pkgs.xorg.xorgserver}/bin/Xvfb :\$DISPLAY_NUM -screen 0 "\$GEOMETRY"x\$DEPTH -nolisten tcp > "\$XVFB_LOGFILE" 2>&1 &
XVFB_PID=\$!
echo \$XVFB_PID > "\$HOME/.vnc/xvfb.pid"

sleep 1

if ! kill -0 \$XVFB_PID 2>/dev/null; then
  echo "Failed to start Xvfb!" >&2
  cat "\$XVFB_LOGFILE" >&2
  exit 1
fi

echo "✓ Xvfb started on display :\$DISPLAY_NUM"

# Set DISPLAY for the session
export DISPLAY=:\$DISPLAY_NUM

# Start window manager and apps
${pkgs.fluxbox}/bin/fluxbox > "\$HOME/.vnc/fluxbox.log" 2>&1 &
${pkgs.xterm}/bin/xterm > "\$HOME/.vnc/xterm.log" 2>&1 &

# Start x11vnc to share the Xvfb display
${pkgs.x11vnc}/bin/x11vnc -display :\$DISPLAY_NUM \\
  -rfbport \$VNC_PORT \\
  -rfbauth "\$HOME/.vnc/passwd" \\
  -forever \\
  -shared \\
  -noxdamage \\
  -ncache 10 \\
  -bg \\
  -o "\$X11VNC_LOGFILE"

sleep 0.5

if ! pgrep -f "x11vnc.*:\$VNC_PORT" > /dev/null; then
  echo "Failed to start x11vnc!" >&2
  cat "\$X11VNC_LOGFILE" >&2
  exit 1
fi

echo "✓ VNC server started on display :\$DISPLAY_NUM (port \$VNC_PORT)"
echo "  To connect: vnc://<device-ip>:\$VNC_PORT"
echo "  Default password: vnc123 (change with: x11vnc -storepasswd)"
echo "  To stop: ~/.vnc/stop-vnc.sh"
echo "  Logs: \$XVFB_LOGFILE, \$X11VNC_LOGFILE"
EOF
    chmod +x "$HOME/.vnc/start-vnc.sh"

    # Generate stop script
    cat > "$HOME/.vnc/stop-vnc.sh" <<'EOF'
#!/usr/bin/env bash
DISPLAY_NUM=1
VNC_PORT=5901

# Kill x11vnc
if pkill -f "x11vnc.*:$VNC_PORT" 2>/dev/null; then
  echo "✓ x11vnc stopped"
else
  echo "x11vnc not running"
fi

# Kill Xvfb
if [ -f "$HOME/.vnc/xvfb.pid" ]; then
  PID=$(cat "$HOME/.vnc/xvfb.pid")
  if kill "$PID" 2>/dev/null; then
    echo "✓ Xvfb stopped (PID $PID)"
  else
    echo "Xvfb PID $PID not running"
  fi
  rm -f "$HOME/.vnc/xvfb.pid"
else
  if pkill -f "Xvfb.*:$DISPLAY_NUM" 2>/dev/null; then
    echo "✓ Xvfb stopped"
  else
    echo "Xvfb not running"
  fi
fi

# Kill window manager and apps
pkill -f "fluxbox" 2>/dev/null || true
pkill -f "xterm" 2>/dev/null || true

# Clean up lock files
rm -f /tmp/.X$DISPLAY_NUM-lock 2>/dev/null || true
rm -f /tmp/.X11-unix/X$DISPLAY_NUM 2>/dev/null || true

echo "✓ VNC server stopped"
EOF
    chmod +x "$HOME/.vnc/stop-vnc.sh"

    # Generate status script
    cat > "$HOME/.vnc/status-vnc.sh" <<'EOF'
#!/usr/bin/env bash
DISPLAY_NUM=1
VNC_PORT=5901

XVFB_RUNNING=false
X11VNC_RUNNING=false

if pgrep -f "Xvfb.*:$DISPLAY_NUM" >/dev/null 2>&1; then
  XVFB_RUNNING=true
fi

if pgrep -f "x11vnc.*:$VNC_PORT" >/dev/null 2>&1; then
  X11VNC_RUNNING=true
fi

if $XVFB_RUNNING && $X11VNC_RUNNING; then
  echo "✓ VNC server is running"
  echo ""
  pgrep -fa "Xvfb.*:$DISPLAY_NUM"
  pgrep -fa "x11vnc.*:$VNC_PORT"
  echo ""
  echo "Connection info:"
  echo "  Display: :$DISPLAY_NUM"
  echo "  Port: $VNC_PORT"
  if command -v ip >/dev/null 2>&1; then
    IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -n1)
    [ -n "$IP" ] && echo "  VNC URL: vnc://$IP:$VNC_PORT"
  fi
elif $XVFB_RUNNING; then
  echo "⚠️  Xvfb is running but x11vnc is not"
  echo "Start with: ~/.vnc/start-vnc.sh"
elif $X11VNC_RUNNING; then
  echo "⚠️  x11vnc is running but Xvfb is not"
  echo "Start with: ~/.vnc/start-vnc.sh"
else
  echo "VNC server is not running"
  echo "Start with: ~/.vnc/start-vnc.sh"
fi
EOF
    chmod +x "$HOME/.vnc/status-vnc.sh"

    echo "VNC server configured. Start with: ~/.vnc/start-vnc.sh"
  '';

  # Home-manager integration
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true;  # Install packages via environment.packages, not nix-env
    config = { config, pkgs, lib, ... }:
      lib.mkMerge [
        (sharedHomeConfig { inherit pkgs lib; })
        {
          home.stateVersion = lib.mkForce "24.05";
          nixpkgs.config.allowUnfree = true;

          # Disable home.packages for Android - packages must be in environment.packages
          # This avoids nix-env/nix profile compatibility issues
          home.packages = lib.mkForce [];

          # Disable programs that are installed via environment.packages
          # to avoid conflicts on Android
          programs.neovim.enable = lib.mkForce false;
          programs.tmux.enable = lib.mkForce false;
          programs.lazygit.enable = lib.mkForce false;

          # Android-specific zsh config
          programs.zsh.initContent = lib.mkAfter ''
            export SHELL=${pkgs.zsh}/bin/zsh
            export TMPDIR=/data/data/com.termux.nix/files/usr/tmp
            if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
              export TERM=xterm-256color
            fi

            # Set default editor since programs.neovim is disabled
            export EDITOR=nvim
            export VISUAL=nvim

            # Set default pager
            export PAGER=less
            export LESS="-R -F -X -S"
          '';

          programs.zsh.shellAliases.copilot = "github-copilot-cli";

          # Manual tmux config since programs.tmux is disabled on Android
          home.file.".config/tmux/tmux.conf".source = ../tmux/tmux.conf;
        }
      ];
  };
}
