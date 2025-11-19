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

    # Development
    go
    gcc
    gnumake
    nodejs
    delve
    goimports-reviser

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

    # Databases
    postgresql
    mysql80
    mycli
    pgcli
    pspg

    # HTTP
    httpie
    hurl

    # Diff/formatting
    delta
    diff-so-fancy

    # Utilities
    fx
  ];

  terminal.font = "${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCodeNerdFont-Regular.ttf";

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

    if [ ! -f "$HOME/.ssh/sshd_config" ]; then
      cat <<'EOF' > "$HOME/.ssh/sshd_config"
Port 8022
ListenAddress 0.0.0.0
HostKey ~/.ssh/ssh_host_ed25519_key
Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256
Compression no
UseDNS no
GSSAPIAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile %h/.ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
AllowTcpForwarding yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp ${pkgs.openssh}/libexec/sftp-server
EOF
    fi

    chmod 600 "$HOME/.ssh/sshd_config"

    cat <<'EOS' > "$HOME/.ssh/start-sshd.sh"
#!/usr/bin/env bash
set -euo pipefail
LOGFILE="$HOME/.ssh/sshd.log"
rm -f "$LOGFILE"
${pkgs.openssh}/bin/sshd -f "$HOME/.ssh/sshd_config" -E "$LOGFILE" || {
  echo "sshd failed to launch." >&2
  exit 1
}
sleep 0.3
if pgrep -f "sshd -f $HOME/.ssh/sshd_config" >/dev/null 2>&1; then
  echo "SSH server started on port 8022"
else
  echo "Failed to start SSH server!" >&2
  exit 1
fi
EOS
    $DRY_RUN_CMD chmod +x "$HOME/.ssh/start-sshd.sh"

    printf '#!/usr/bin/env bash\npkill -f "sshd -f $HOME/.ssh/sshd_config"\n' > $HOME/.ssh/stop-sshd.sh
    $DRY_RUN_CMD chmod +x $HOME/.ssh/stop-sshd.sh
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
          home.stateVersion = "24.05";
          nixpkgs.config.allowUnfree = true;

          # Disable home.packages for Android - use environment.packages instead
          # This avoids nix-env/nix profile compatibility issues
          home.packages = lib.mkForce [];

          # Android-specific zsh config
          programs.zsh.initContent = lib.mkAfter ''
            export TMPDIR=/data/data/com.termux.nix/files/usr/tmp
            if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
              export TERM=xterm-256color
            fi
          '';

          programs.zsh.shellAliases.copilot = "github-copilot-cli";
        }
      ];
  };
}
