{ config, pkgs, lib, sharedPackages, sharedHomeConfig, ... }:

# Termux configuration for vanilla Nix installation (not nix-on-droid)
# This uses home-manager directly without the nix-on-droid wrapper.
#
# Usage:
#   1. Install Nix in Termux: bash scripts/bootstrap-termux-nix.sh
#   2. Apply config: home-manager switch --flake ~/projects/dotfiles#termux
#
# Key differences from nix-on-droid:
# - Uses home.packages instead of environment.packages
# - No build.activation scripts (use home.activation instead)
# - More standard home-manager setup

lib.mkMerge [
  # Import shared configuration
  (sharedHomeConfig { inherit pkgs lib; })

  # Termux-specific overrides
  {
    home.stateVersion = "24.05";
    nixpkgs.config.allowUnfree = true;

    # Minimal package set for battery optimization
    # Heavy dev tools available via: nix develop ~/dotfiles#<shell-name>
    home.packages = with pkgs; [
      # Core utilities
      git
      gh
      fzf
      ripgrep
      fd
      jq
      curl
      coreutils
      gnugrep
      gnused
      gawk

      # Network tools
      openssh
      net-tools
      mosh

      # Secrets management
      sops
      age
      yq-go

      # Development (minimal)
      go
      nodejs
      python3

      # Utilities
      direnv
      lazygit
      delta
      diff-so-fancy
    ];

    # Neovim - use shared config
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    # Tmux - use shared config
    programs.tmux = {
      enable = true;
      # Additional termux-specific tmux config
      extraConfig = ''
        # Termux-specific: fix clipboard
        set -g set-clipboard on

        # Fix colors in Termux
        set -ga terminal-overrides ",xterm-256color:Tc"
      '';
    };

    # Git configuration
    programs.git = {
      enable = true;
      delta.enable = true;
    };

    # Zsh configuration
    programs.zsh = {
      enable = true;
      oh-my-zsh.enable = true;

      # Termux-specific environment variables
      initExtra = ''
        # Termux paths
        export PREFIX=/data/data/com.termux/files/usr
        export TMPDIR=$PREFIX/tmp

        # Nix profile
        if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
          . $HOME/.nix-profile/etc/profile.d/nix.sh
        fi

        # Editor
        export EDITOR=nvim
        export VISUAL=nvim

        # Pager
        export PAGER=less
        export LESS="-R -F -X -S"

        # Better colors for Android terminal
        export TERM=xterm-256color

        # Load aliases
        if [ -f "$HOME/.scripts/load-aliases.sh" ]; then
          source "$HOME/.scripts/load-aliases.sh"
        fi
      '';

      shellAliases = {
        # Termux package management
        tpkg = "pkg";
        tup = "pkg update && pkg upgrade";

        # Nix shortcuts
        hm = "home-manager";
        hms = "home-manager switch --flake ~/projects/dotfiles#termux";
        hmb = "home-manager build --flake ~/projects/dotfiles#termux";

        # Development shells
        dev-go = "nix develop ~/projects/dotfiles#go";
        dev-rust = "nix develop ~/projects/dotfiles#rust";
        dev-node = "nix develop ~/projects/dotfiles#node";
        dev-python = "nix develop ~/projects/dotfiles#python";

        # Secrets
        secrets-decrypt = "cd ~/projects/dotfiles && make decrypt";
        secrets-encrypt = "cd ~/projects/dotfiles && make encrypt";

        # SSH shortcuts
        sshd-start = "~/.ssh/start-sshd.sh";
        sshd-stop = "~/.ssh/stop-sshd.sh";
      };
    };

    # SSH configuration
    home.activation.sshSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/.ssh
      $DRY_RUN_CMD chmod 700 $HOME/.ssh

      # Generate SSH host keys if they don't exist
      if [ ! -f $HOME/.ssh/ssh_host_ed25519_key ]; then
        $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t ed25519 \
          -f "$HOME/.ssh/ssh_host_ed25519_key" -N ""
      fi

      if [ ! -f $HOME/.ssh/android_client_key ]; then
        $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t ed25519 \
          -f "$HOME/.ssh/android_client_key" -N "" \
          -C "termux-client-key"
      fi

      # Create authorized_keys if it doesn't exist
      $DRY_RUN_CMD touch $HOME/.ssh/authorized_keys
      $DRY_RUN_CMD chmod 600 $HOME/.ssh/authorized_keys

      # Add client key to authorized_keys if not present
      if [ -f $HOME/.ssh/android_client_key.pub ]; then
        CLIENT_KEY=$(cat $HOME/.ssh/android_client_key.pub)
        if ! grep -qF "$CLIENT_KEY" $HOME/.ssh/authorized_keys 2>/dev/null; then
          $DRY_RUN_CMD echo "$CLIENT_KEY" >> $HOME/.ssh/authorized_keys
        fi
      fi

      # Create sshd_config
      $DRY_RUN_CMD cat > $HOME/.ssh/sshd_config <<'EOF'
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
AllowTcpForwarding yes
PrintMotd no
AcceptEnv LANG LC_*
EOF

      $DRY_RUN_CMD chmod 600 $HOME/.ssh/sshd_config

      # Create start script
      $DRY_RUN_CMD cat > $HOME/.ssh/start-sshd.sh <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

# Kill existing sshd
pkill -f "sshd -f $HOME/.ssh/sshd_config" 2>/dev/null || true
sleep 0.5

# Find sshd from Nix
SSHD=$(which sshd)
if [ -z "$SSHD" ]; then
  echo "Error: sshd not found. Is openssh installed?" >&2
  exit 1
fi

# Start sshd
LOGFILE="$HOME/.ssh/sshd.log"
rm -f "$LOGFILE"

$SSHD -f "$HOME/.ssh/sshd_config" -E "$LOGFILE" || {
  echo "Failed to start sshd" >&2
  cat "$LOGFILE" >&2
  exit 1
}

sleep 0.3
if pgrep -f "sshd -f $HOME/.ssh/sshd_config" >/dev/null 2>&1; then
  echo "✓ SSH server started on port 8022"
  # Get IP address
  IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -n1)
  [ -n "$IP" ] && echo "  Connect: ssh -p 8022 $(whoami)@$IP"
else
  echo "Failed to start SSH server" >&2
  cat "$LOGFILE" >&2
  exit 1
fi
EOS

      $DRY_RUN_CMD chmod +x $HOME/.ssh/start-sshd.sh

      # Create stop script
      $DRY_RUN_CMD cat > $HOME/.ssh/stop-sshd.sh <<'EOS'
#!/usr/bin/env bash
if pkill -f "sshd -f $HOME/.ssh/sshd_config"; then
  echo "✓ SSH server stopped"
else
  echo "No SSH server running"
fi
EOS

      $DRY_RUN_CMD chmod +x $HOME/.ssh/stop-sshd.sh
    '';

    # Secrets decryption activation
    home.activation.secretsDecrypt = lib.hm.dag.entryAfter ["writeBoundary"] ''
      DOTFILES="$HOME/projects/dotfiles"
      DECRYPT_SCRIPT="$DOTFILES/scripts/activate-decrypt-secrets-android.sh"

      if [ -f "$DECRYPT_SCRIPT" ]; then
        if $VERBOSE_ARG; then
          $DRY_RUN_CMD echo "Decrypting secrets..."
        fi
        $DRY_RUN_CMD bash "$DECRYPT_SCRIPT" "$DOTFILES"
      fi
    '';

    # Create scripts directory
    home.file.".scripts" = {
      source = ../scripts;
      recursive = true;
    };

    # Direnv configuration
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Lazygit configuration
    programs.lazygit.enable = true;
  }
]
