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

  # Minimal package set for battery optimization
  # Heavy dev tools moved to devShells - activate with: nix develop ~/dotfiles#<shell-name>
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
    curl

    # Shell
    zsh
    oh-my-zsh

    # Network (essential only)
    openssh
    net-tools

    # Secrets (if needed regularly)
    sops
    age
    yq-go

    # Utilities
    direnv
    lazygit
  ];

  terminal.font = "${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf";

  # Optimized secrets decryption - only run if keys changed
  build.activation.secrets = ''
    export PATH="${pkgs.sops}/bin:${pkgs.age}/bin:${pkgs.yq-go}/bin:$PATH"

    DOTFILES_DIR="$HOME/dotfiles"
    ACTIVATION_SCRIPT="$DOTFILES_DIR/scripts/activate-decrypt-secrets-android.sh"
    SECRETS_MARKER="$HOME/.secrets-decrypted"

    # Only decrypt if marker doesn't exist or activation script is newer
    if [ -f "$ACTIVATION_SCRIPT" ]; then
      if [ ! -f "$SECRETS_MARKER" ] || [ "$ACTIVATION_SCRIPT" -nt "$SECRETS_MARKER" ]; then
        echo "Decrypting secrets..."
        "$ACTIVATION_SCRIPT" "$DOTFILES_DIR" && touch "$SECRETS_MARKER"
      else
        echo "Secrets already decrypted, skipping..."
      fi
    fi
  '';

  # Optimized SSH server setup - only configure if not already done
  build.activation.sshd = ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    SSHD_CONFIGURED="$HOME/.ssh/.sshd-configured"

    # Only run full setup if not already configured
    if [ ! -f "$SSHD_CONFIGURED" ]; then
      echo "Configuring SSH server..."

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
PidFile ~/.ssh/sshd.pid
HostKey ~/.ssh/ssh_host_ed25519_key
Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256
Compression no
UseDNS no
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
      chmod +x "$HOME/.ssh/start-sshd.sh"

      printf '#!/usr/bin/env bash\npkill -f "sshd -f $HOME/.ssh/sshd_config"\n' > $HOME/.ssh/stop-sshd.sh
      chmod +x $HOME/.ssh/stop-sshd.sh

      touch "$SSHD_CONFIGURED"
      echo "SSH server configuration complete"
    else
      echo "SSH server already configured, skipping..."
    fi
  '';

  # Home-manager integration
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true;
    config = { config, pkgs, lib, ... }:
      lib.mkMerge [
        (sharedHomeConfig { inherit pkgs lib; })
        {
          home.stateVersion = "24.05";
          nixpkgs.config.allowUnfree = true;

          home.packages = lib.mkForce [];

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

            export EDITOR=nvim
            export VISUAL=nvim
            export PAGER=less
            export LESS="-R -F -X -S"
          '';

          programs.zsh.shellAliases = {
            copilot = "github-copilot-cli";
            # SSH tunnel management
            tunnel-start = "~/.local/bin/ssh-tunnel";
            tunnel-stop = "pkill -f ssh-tunnel";
            tunnel-status = "pgrep -af ssh-tunnel";
          };

          home.file.".config/tmux/tmux.conf".source = ../tmux/tmux.conf;
        }
      ];
  };
}
