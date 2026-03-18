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
}
