{ pkgs, lib, ... }:
{
  system.stateVersion = "24.05";

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nix-on-droid.cachix.org"
    ];
    trustedPublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
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
    # maven  # removed: heavy JVM tool, slow on aarch64 — use project-specific nix shells instead
    # gradle # removed: heavy JVM tool, slow on aarch64 — use project-specific nix shells instead

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
    # mosh      # removed: requires utempter/utmp write access unavailable on Android
    # tailscale # removed: needs kernel TUN + root daemon, cannot run on nix-on-droid

    # Databases
    postgresql
    # mysql80 # removed: does not build on aarch64-linux
    # mycli   # removed: pyarrow build issues on aarch64
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

    # dbus    # removed: requires system D-Bus daemon unavailable in nix-on-droid userspace
  ];

  terminal.font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";

  # SSH server setup
  # Runs on every `nix-on-droid switch`. Idempotent: keys are only generated
  # if missing; sshd_config and scripts are always regenerated to keep
  # Nix store paths current after package upgrades.
  build.activation.sshd = ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # ── Host keys (server identity) ──────────────────────────────────────
    if [ ! -f "$HOME/.ssh/ssh_host_ed25519_key" ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 \
        -f "$HOME/.ssh/ssh_host_ed25519_key" -N ""
      echo "Generated SSH host key (ED25519)"
    fi

    # ── Client keypair (auto-login from Mac) ─────────────────────────────
    # This keypair is generated once. The public key goes into authorized_keys
    # on this device. The private key is what you copy to your Mac.
    if [ ! -f "$HOME/.ssh/android_client_key" ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 \
        -f "$HOME/.ssh/android_client_key" -N "" \
        -C "nix-on-droid-auto-client"
      echo "Generated client keypair: $HOME/.ssh/android_client_key"
    fi

    # ── authorized_keys ──────────────────────────────────────────────────
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    CLIENT_PUBKEY=$(cat "$HOME/.ssh/android_client_key.pub")
    if ! grep -qF "$CLIENT_PUBKEY" "$HOME/.ssh/authorized_keys"; then
      echo "$CLIENT_PUBKEY" >> "$HOME/.ssh/authorized_keys"
      echo "Added client public key to authorized_keys"
    fi

    # ── sshd_config ──────────────────────────────────────────────────────
    # Always regenerated so Nix store paths (sftp-server, etc.) stay valid.
    cat > "$HOME/.ssh/sshd_config" << 'SSHD_EOF'
Port 8022
ListenAddress 0.0.0.0
PidFile PLACEHOLDER_HOME/.ssh/sshd.pid
HostKey PLACEHOLDER_HOME/.ssh/ssh_host_ed25519_key
AuthorizedKeysFile PLACEHOLDER_HOME/.ssh/authorized_keys

# Security
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
UseDNS no
GSSAPIAuthentication no
X11Forwarding no
PrintMotd no

# Performance
Compression no
TCPKeepAlive yes

# Forwarding
AllowTcpForwarding yes

# Ciphers (modern, fast)
Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256

AcceptEnv LANG LC_*
SSHD_EOF

    # Substitute $HOME (heredoc cannot expand vars inside single-quoted EOF)
    ${pkgs.gnused}/bin/sed -i \
      "s|PLACEHOLDER_HOME|$HOME|g" \
      "$HOME/.ssh/sshd_config"

    # Append sftp subsystem with current Nix store path
    echo "Subsystem sftp ${pkgs.openssh}/libexec/sftp-server" \
      >> "$HOME/.ssh/sshd_config"

    chmod 600 "$HOME/.ssh/sshd_config"

    # ── start-sshd.sh ────────────────────────────────────────────────────
    cat > "$HOME/.ssh/start-sshd.sh" << 'START_EOF'
#!/usr/bin/env bash
set -euo pipefail

PIDFILE="$HOME/.ssh/sshd.pid"
LOGFILE="$HOME/.ssh/sshd.log"
SSHD_BIN="PLACEHOLDER_SSHD"
CONFIG="$HOME/.ssh/sshd_config"

# Kill any existing instance
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID"
    sleep 0.3
  fi
  rm -f "$PIDFILE"
fi

rm -f "$LOGFILE"
"$SSHD_BIN" -f "$CONFIG" -E "$LOGFILE"

# Wait up to 2 seconds for PID file
for i in $(seq 1 20); do
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  DEVICE_IP=$(ip route get 1 2>/dev/null | awk '/src/{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}' || echo "<device-ip>")
  echo "✓ SSH server started (PID $(cat "$PIDFILE"))"
  echo ""
  echo "── Connection Methods ────────────────────────────────────────────"
  echo "  Wi-Fi:    ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@''${DEVICE_IP}"
  echo "  USB:      adb forward tcp:8022 tcp:8022"
  echo "            ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@localhost"
  echo "  Tailscale: ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@<tailscale-ip>"
  echo "─────────────────────────────────────────────────────────────────"
  echo ""
  echo "  Client private key to copy to Mac:"
  echo "    $HOME/.ssh/android_client_key"
  echo "  (scp it or cat it and paste into ~/.ssh/android_client_key on Mac)"
else
  echo "✗ SSH server failed to start" >&2
  cat "$LOGFILE" >&2
  exit 1
fi
START_EOF

    # Substitute sshd binary path (cannot interpolate Nix vars inside heredoc)
    ${pkgs.gnused}/bin/sed -i \
      "s|PLACEHOLDER_SSHD|${pkgs.openssh}/bin/sshd|g" \
      "$HOME/.ssh/start-sshd.sh"
    chmod +x "$HOME/.ssh/start-sshd.sh"

    # ── stop-sshd.sh ─────────────────────────────────────────────────────
    cat > "$HOME/.ssh/stop-sshd.sh" << 'STOP_EOF'
#!/usr/bin/env bash
PIDFILE="$HOME/.ssh/sshd.pid"
if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    rm -f "$PIDFILE"
    echo "✓ SSH server stopped"
  else
    rm -f "$PIDFILE"
    echo "SSH server was not running (stale PID file removed)"
  fi
else
  echo "SSH server is not running"
fi
STOP_EOF
    chmod +x "$HOME/.ssh/stop-sshd.sh"

    # ── status-sshd.sh ───────────────────────────────────────────────────
    cat > "$HOME/.ssh/status-sshd.sh" << 'STATUS_EOF'
#!/usr/bin/env bash
PIDFILE="$HOME/.ssh/sshd.pid"
if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "✓ SSH server running (PID $PID, port 8022)"
  else
    echo "✗ SSH server not running (stale PID file)"
  fi
else
  echo "✗ SSH server not running"
fi
STATUS_EOF
    chmod +x "$HOME/.ssh/status-sshd.sh"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  SSH server configured. Auto-starts on shell open."
    echo "  Manual control:"
    echo "    ~/.ssh/start-sshd.sh   — start"
    echo "    ~/.ssh/stop-sshd.sh    — stop"
    echo "    ~/.ssh/status-sshd.sh  — status"
    echo ""
    echo "  Client key for Mac: $HOME/.ssh/android_client_key"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  '';
}
