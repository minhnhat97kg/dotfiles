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

    # VNC Server
    tigervnc
    xorg.xauth
    xvfb-run
    fluxbox
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
GSSAPIAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile $HOME/.ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
AllowTcpForwarding yes
X11Forwarding no
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

  # VNC server setup
  build.activation.vnc = ''
    mkdir -p "$HOME/.vnc"
    chmod 700 "$HOME/.vnc"

    # Generate VNC password file if it doesn't exist
    if [ ! -f "$HOME/.vnc/passwd" ]; then
      echo "vnc123" | ${pkgs.tigervnc}/bin/vncpasswd -f > "$HOME/.vnc/passwd"
      chmod 600 "$HOME/.vnc/passwd"
      echo "⚠️  Default VNC password set to 'vnc123'. Change it with: vncpasswd"
    fi

    # VNC startup script (xstartup)
    cat > "$HOME/.vnc/xstartup" <<EOF
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Start a minimal window manager
${pkgs.fluxbox}/bin/fluxbox &

# Optional: start a terminal emulator if available
# ${pkgs.xterm}/bin/xterm &

# Keep the X session alive
while true; do sleep 1000; done
EOF
    chmod +x "$HOME/.vnc/xstartup"

    # Generate start script with current package paths
    cat > "$HOME/.vnc/start-vnc.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

VNC_PORT=5901
DISPLAY_NUM=1
GEOMETRY="1920x1080"
DEPTH=24

# Stop any existing VNC server on this display
${pkgs.tigervnc}/bin/vncserver -kill :\$DISPLAY_NUM 2>/dev/null || true
sleep 0.5

# Clean up any stale lock files
rm -f /tmp/.X\$DISPLAY_NUM-lock
rm -f /tmp/.X11-unix/X\$DISPLAY_NUM

# Start VNC server
${pkgs.tigervnc}/bin/vncserver :\$DISPLAY_NUM \\
  -geometry \$GEOMETRY \\
  -depth \$DEPTH \\
  -localhost no \\
  -rfbport \$VNC_PORT \\
  || {
    echo "Failed to start VNC server!" >&2
    exit 1
  }

sleep 0.5

if pgrep -f "Xvnc.*:\$DISPLAY_NUM" >/dev/null 2>&1; then
  echo "✓ VNC server started on display :\$DISPLAY_NUM (port \$VNC_PORT)"
  echo "  To connect: vnc://<device-ip>:\$VNC_PORT"
  echo "  Default password: vnc123 (change with: vncpasswd)"
  echo "  To stop: ~/.vnc/stop-vnc.sh"
else
  echo "Failed to start VNC server!" >&2
  exit 1
fi
EOF
    chmod +x "$HOME/.vnc/start-vnc.sh"

    # Generate stop script
    cat > "$HOME/.vnc/stop-vnc.sh" <<'EOF'
#!/usr/bin/env bash
DISPLAY_NUM=1
if ${pkgs.tigervnc}/bin/vncserver -kill :$DISPLAY_NUM 2>/dev/null; then
  echo "✓ VNC server stopped (display :$DISPLAY_NUM)"
else
  echo "No VNC server running on display :$DISPLAY_NUM"
fi
rm -f /tmp/.X$DISPLAY_NUM-lock 2>/dev/null || true
rm -f /tmp/.X11-unix/X$DISPLAY_NUM 2>/dev/null || true
EOF
    chmod +x "$HOME/.vnc/stop-vnc.sh"

    # Generate status script
    cat > "$HOME/.vnc/status-vnc.sh" <<'EOF'
#!/usr/bin/env bash
if pgrep -fa "Xvnc.*:1" >/dev/null 2>&1; then
  echo "✓ VNC server is running"
  pgrep -fa "Xvnc.*:1"
  echo ""
  echo "Connection info:"
  echo "  Display: :1"
  echo "  Port: 5901"
  if command -v ip >/dev/null 2>&1; then
    IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -n1)
    [ -n "$IP" ] && echo "  VNC URL: vnc://$IP:5901"
  fi
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
