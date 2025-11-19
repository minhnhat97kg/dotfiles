{
  description = "Cross-platform Nix configuration (macOS & Android)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # macOS support
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Android support via nix-on-droid
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # home-manager for user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix for secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      nix-on-droid,
      home-manager,
      ...
    }:
    let
      # User configuration
      username = "nhath";
      useremail = "minhnhat97kg@gmail.com";

      # Shared packages across all platforms
      sharedPackages =
        pkgs: with pkgs; [
          # Core tools
          git
          gh
          fzf
          ripgrep
          fd
          jq

          # Dev essentials
          nodejs
          go
          cargo rustc rustfmt clippy rust-analyzer
          python3 pipx

          # Diff & formatting
          delta diff-so-fancy

          # Utilities
          fx jless
        ];

      # Shared home-manager configuration
      sharedHomeConfig =
        { pkgs, lib, ... }:
        {
          home.stateVersion = "24.05";

          # Allow unfree packages in home-manager
          nixpkgs.config.allowUnfree = true;

          home.packages = sharedPackages pkgs;

          programs = {
            neovim = {
              enable = true;
              defaultEditor = true;
            };

            tmux = {
              enable = true;
              keyMode = "vi";
              mouse = true;
              plugins = with pkgs.tmuxPlugins; [
                better-mouse-mode
                yank
                {
                  plugin = catppuccin;
                  extraConfig = ''
                    set -g default-terminal "tmux-256color"
                    set-option -ga terminal-overrides ",xterm-256color:Tc"
                    set -g @catppuccin_flavor "mocha"
                    set -g @catppuccin_window_status_style "rounded"
                  '';
                }
              ];
              extraConfig = ''
                set -sg escape-time 0
                setw -g mode-keys vi
                bind-key -T copy-mode-vi v send-keys -X begin-selection
                bind c new-window -c "#{pane_current_path}"
                bind | split-window -h -c "#{pane_current_path}"
                bind - split-window -v -c "#{pane_current_path}"

                # Pane border highlighting
                set -g pane-border-style "fg=#313244"
                set -g pane-active-border-style "fg=#89b4fa,bold"

                # Dim inactive panes
                set -g window-style "fg=#585b70,bg=#181825"
                set -g window-active-style "fg=#cdd6f4,bg=#1e1e2e"

                # Vim-like pane navigation
                is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
                bind -n C-h run "($is_vim && tmux send-keys C-h) || tmux select-pane -L"
                bind -n C-j run "($is_vim && tmux send-keys C-j) || tmux select-pane -D"
                bind -n C-k run "($is_vim && tmux send-keys C-k) || tmux select-pane -U"
                bind -n C-l run "($is_vim && tmux send-keys C-l) || tmux select-pane -R"
              '';
            };

            zsh = {
              enable = true;
              initContent = lib.mkMerge [
                (lib.mkOrder 550 ''
                  export GOPATH=$HOME/go
                  export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

                  # npm global packages directory (avoid writing to Nix store)
                  export NPM_CONFIG_PREFIX="$HOME/.npm-global"
                  export PATH="$HOME/.npm-global/bin:$PATH"
                '')
                ''
                  # Load aliases from YAML config if available
                  ALIASES_SCRIPT="$HOME/.config/dotfiles/scripts/load-aliases.sh"
                  if [ -f "$ALIASES_SCRIPT" ]; then
                    eval "$($ALIASES_SCRIPT)"
                  fi
                ''
              ];
              shellAliases = {
                ll = "ls -l";
                lg = "lazygit";
                e = "nvim";
              };
              oh-my-zsh = {
                enable = true;
                theme = "robbyrussell";
              };
            };

            lazygit.enable = true;
            direnv.enable = true;
          };

          home.file.".config/nvim/" = {
            source = ./nvim;
            recursive = true;
          };

          # Git configuration
          programs.git = {
            enable = true;
            includes = [
              { path = "~/.config/git/gitconfig"; }
              {
                condition = "gitdir:~/work/**";
                path = "~/.config/git/work.gitconfig";
              }
              {
                condition = "gitdir:~/projects/**";
                path = "~/.config/git/minhnhat97kg.gitconfig";
              }
            ];
          };

          home.file.".config/git/gitconfig".source = ./git/gitconfig;
          home.file.".config/git/minhnhat97kg.gitconfig".source = ./git/minhnhat97kg.gitconfig;
          home.file.".gitignore_global".source = ./git/gitignore_global;

          # Shell aliases script
          home.file.".config/dotfiles/scripts/load-aliases.sh" = {
            source = ./scripts/load-aliases.sh;
            executable = true;
          };
        };
    in
    {
      # ============================================================================
      # macOS Configuration (nix-darwin)
      # ============================================================================
      darwinConfigurations."Nathan-Macbook" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = inputs // {
          inherit username useremail;
        };

        modules = [
          # Core nix settings
          {
            system.stateVersion = 5;
            nixpkgs.config.allowUnfree = true;
            nixpkgs.hostPlatform = "aarch64-darwin";

            nix = {
              enable = true;
              package = nixpkgs.legacyPackages.aarch64-darwin.nix;

              gc = {
                automatic = true;
                options = "--delete-older-than 7d";
              };

              settings = {
                experimental-features = [
                  "nix-command"
                  "flakes"
                ];
                substituters = [
                  "https://cache.nixos.org"
                  "https://mirror.sjtu.edu.cn/nix-channels/store"
                  "https://nix-community.cachix.org"
                ];
                trusted-public-keys = [
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
              };
            };

            # macOS-specific settings
            programs.zsh.enable = true;
            environment.systemPackages = with nixpkgs.legacyPackages.aarch64-darwin; [
              nixfmt-rfc-style
              yabai
              skhd
              sketchybar
              jankyborders
              jq # Required for skhd keybindings
              qutebrowser
            ];

            # Window management services
            services.yabai = {
              enable = true;
              enableScriptingAddition = false; # Requires SIP to be disabled
              config = {
                external_bar = "all:32:0"; # Reserve space for sketchybar
                layout = "bsp";
                top_padding = 10;
                bottom_padding = 10;
                left_padding = 10;
                right_padding = 10;
                window_gap = 10;
                mouse_follows_focus = "off";
                focus_follows_mouse = "off";
                mouse_modifier = "fn";
                mouse_action1 = "move";
                mouse_action2 = "resize";
                mouse_drop_action = "swap";
                window_origin_display = "default";
                window_placement = "second_child";
                window_shadow = "on";
                window_opacity = "off";
                window_opacity_duration = "0.0";
                active_window_opacity = "1.0";
                normal_window_opacity = "0.90";
                auto_balance = "off";
                split_ratio = "0.50";
                window_border = "off";
                window_border_width = 6;
                active_window_border_color = "0xff775759";
                normal_window_border_color = "0xff555555";
              };
              extraConfig = ''
                # Exclusions - apps to not manage
                yabai -m rule --add app="^System Settings$" manage=off
                yabai -m rule --add app="^System Preferences$" manage=off
                yabai -m rule --add app="^Archive Utility$" manage=off
                yabai -m rule --add app="^App Store$" manage=off
                yabai -m rule --add app="^Activity Monitor$" manage=off
                yabai -m rule --add app="^Calculator$" manage=off
                yabai -m rule --add app="^Dictionary$" manage=off
                yabai -m rule --add app="^Software Update$" manage=off
                yabai -m rule --add app="^About This Mac$" manage=off
                yabai -m rule --add app="^Finder$" title="(Co(py|nnect)|Move|Info|Pref)" manage=off

                echo "yabai configuration loaded.."
              '';
            };

            services.skhd = {
              enable = true;
              skhdConfig = builtins.readFile ./skhd/skhdrc;
            };

            services.sketchybar = {
              enable = true;
              config = builtins.readFile ./sketchybar/sketchybarrc;
            };

            # JankyBorders service (window borders)
            launchd.user.agents.jankyborders = {
              serviceConfig = {
                ProgramArguments = [
                  "${nixpkgs.legacyPackages.aarch64-darwin.jankyborders}/bin/borders"
                  "active_color=0xff89b4fa"
                  "inactive_color=0xff6c7086"
                  "width=5.0"
                  "style=round"
                ];
                KeepAlive = true;
                RunAtLoad = true;
                StandardOutPath = "/tmp/jankyborders.out.log";
                StandardErrorPath = "/tmp/jankyborders.err.log";
              };
            };

            # Host & user configuration
            networking.hostName = "Nathan-Macbook";
            networking.computerName = "Nathan-Macbook";

            # Primary user for services like yabai/skhd
            system.primaryUser = username;

            users.users."${username}" = {
              home = "/Users/${username}";
              description = username;
              shell = nixpkgs.legacyPackages.aarch64-darwin.zsh;
            };

            nix.settings.trusted-users = [ username ];
          }

          # Home-manager integration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = false;
            home-manager.verbose = true;
            home-manager.extraSpecialArgs = inputs // {
              inherit username;
            };
            home-manager.users.${username} =
              { pkgs, lib, config, ... }:
              nixpkgs.lib.mkMerge [
                (sharedHomeConfig { inherit pkgs lib; })
                {
                  home.username = username;
                  home.homeDirectory = "/Users/${username}";

                  # Terminal emulator (Alacritty only)
                  home.file.".config/alacritty/alacritty.toml".source = ./alacritty/alacritty.toml;

                  # Window management
                  home.file.".config/sketchybar/" = {
                    source = ./sketchybar;
                    recursive = true;
                  };

                  # Shell configurations (zsh managed by programs.zsh in shared config)
                  home.file.".ideavimrc".source = ./shell/.ideavimrc;

                  # Git configuration
                  home.file.".config/git/ignore".source = ./git/ignore;

                  # Development tools
                  home.file.".config/lazygit/" = {
                    source = ./lazygit;
                    recursive = true;
                  };

                  # Database tools
                  home.file.".pspgconf".source = ./pspg/pspgconf;

                  # Browser (qutebrowser)
                  home.file.".qutebrowser/config.py".source = ./qutebrowser/config.py;

                  # Decrypt AWS configuration on activation
                  home.activation.decryptAwsConfig =
                    let
                      awsConfigFile = ./secrets/aws-config.enc;
                      awsCredsFile = ./secrets/aws-credentials;
                      ageKey = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
                    in
                    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                      if [ -f ${ageKey} ]; then
                        echo "Decrypting AWS configuration..."
                        $DRY_RUN_CMD mkdir -p $HOME/.aws

                        if [ -f ${awsConfigFile} ]; then
                          ${pkgs.age}/bin/age --decrypt -i ${ageKey} ${awsConfigFile} > $HOME/.aws/config
                          $DRY_RUN_CMD chmod 644 $HOME/.aws/config
                          echo "  ✓ AWS config decrypted"
                        fi

                        if [ -f ${awsCredsFile} ]; then
                          ${pkgs.age}/bin/age --decrypt -i ${ageKey} ${awsCredsFile} > $HOME/.aws/credentials
                          $DRY_RUN_CMD chmod 600 $HOME/.aws/credentials
                          echo "  ✓ AWS credentials decrypted"
                        fi
                      fi
                    '';

                  # Decrypt SSH keys on activation
                  home.activation.decryptSshKeys =
                    let
                      secretsDir = ./secrets/ssh;
                      ageKey = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
                    in
                    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                      if [ -d ${secretsDir} ] && [ -f ${ageKey} ]; then
                        echo "Decrypting SSH keys..."
                        $DRY_RUN_CMD mkdir -p $HOME/.ssh

                        for encrypted in ${secretsDir}/*.enc; do
                          if [ -f "$encrypted" ]; then
                            filename=$(basename "$encrypted" .enc)
                            echo "  → $filename"
                            ${pkgs.age}/bin/age --decrypt -i ${ageKey} "$encrypted" > $HOME/.ssh/$filename
                            $DRY_RUN_CMD chmod 600 $HOME/.ssh/$filename
                          fi
                        done

                        echo "✓ SSH keys decrypted"
                      fi
                    '';

                  # Decrypt git work config on activation
                  home.activation.decryptGitWorkConfig =
                    let
                      secretsFile = ./secrets/git/work.gitconfig.enc;
                      ageKey = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
                    in
                    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                      if [ -f ${secretsFile} ] && [ -f ${ageKey} ]; then
                        echo "Decrypting git work config..."
                        $DRY_RUN_CMD mkdir -p $HOME/.config/git
                        ${pkgs.age}/bin/age --decrypt -i ${ageKey} ${secretsFile} > $HOME/.config/git/work.gitconfig
                        $DRY_RUN_CMD chmod 644 $HOME/.config/git/work.gitconfig
                        echo "✓ Git work config decrypted"
                      fi
                    '';


                  # macOS-specific packages
                  home.packages = with pkgs; [
                    alacritty # Terminal emulator
                  ];
                }
              ];
          }
        ];
      };

      # ============================================================================
      # Android Configuration (nix-on-droid)
      # ============================================================================
      nixOnDroidConfigurations.default =
        let
          system = "aarch64-linux";
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        nix-on-droid.lib.nixOnDroidConfiguration {
          inherit pkgs;
          modules = [
            {
              # Nix-on-droid specific settings
              system.stateVersion = "24.05";

              # Nix configuration
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

              # User configuration
              user.shell = "${pkgs.zsh}/bin/zsh";

              # Android-specific environment
              environment.packages = with pkgs; [
                # Core utilities
                git
                # neovim - configured via home-manager programs.neovim
                # tmux - configured via home-manager programs.tmux
                fzf
                procps # Provides pkill, pgrep, ps, etc.
                gnugrep # Provides grep command
                gnused # Provides sed command
                gawk # Provides awk command
                coreutils # Provides cat, chmod, mkdir, etc.

                # Development tools
                go
                gcc
                gnumake # Provides make command

                # Shell
                zsh
                oh-my-zsh

                # SSH Server
                openssh
                net-tools

                # Mosh (Mobile Shell) - for unstable connections
                mosh

                # Tailscale - VPN for remote access
                tailscale
              ];

              # Terminal configuration
              terminal.font = "${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCodeNerdFont-Regular.ttf";

              # Build activation script to set up SSH server
              build.activation.sshd = ''
                mkdir -p "$HOME/.ssh"
                chmod 700 "$HOME/.ssh"

                # Create SSH host keys if they don't exist (Ed25519 only - modern, secure alternative to RSA)
                if [ ! -f $HOME/.ssh/ssh_host_ed25519_key ]; then
                  ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$HOME/.ssh/ssh_host_ed25519_key" -N ""
                fi

                # Optional: Create ECDSA key as fallback for older clients
                if [ ! -f $HOME/.ssh/ssh_host_ecdsa_key ]; then
                  ${pkgs.openssh}/bin/ssh-keygen -t ecdsa -b 521 -f "$HOME/.ssh/ssh_host_ecdsa_key" -N ""
                fi

                # Generate auto-login client key if it doesn't exist
                if [ ! -f "$HOME/.ssh/android_client_key" ]; then
                  ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$HOME/.ssh/android_client_key" -N "" -C "auto-generated-android-client"
                  echo "Generated auto-login client key: $HOME/.ssh/android_client_key"
                fi

                # Auto-add client public key to authorized_keys for passwordless login
                touch "$HOME/.ssh/authorized_keys"
                chmod 600 "$HOME/.ssh/authorized_keys"

                CLIENT_PUBKEY=$(cat "$HOME/.ssh/android_client_key.pub")
                if ! grep -qF "$CLIENT_PUBKEY" "$HOME/.ssh/authorized_keys"; then
                  echo "$CLIENT_PUBKEY" >> "$HOME/.ssh/authorized_keys"
                  echo "Added auto-login key to authorized_keys"
                fi

                # Create sshd_config if it doesn't exist
                if [ ! -f "$HOME/.ssh/sshd_config" ]; then
                  cat <<'EOF' > "$HOME/.ssh/sshd_config"
# SSH Server Configuration for Nix-on-Droid
Port 8022
ListenAddress 0.0.0.0

# Host keys (Ed25519 only for speed - Ed25519 is faster than ECDSA)
HostKey ~/.ssh/ssh_host_ed25519_key

# Performance optimizations
# Use faster ciphers (chacha20 is optimized for mobile CPUs)
Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes128-ctr
# Use faster MAC algorithms
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
# Use faster key exchange algorithms
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256
# Disable compression (uses CPU, adds latency on fast networks)
Compression no
# Reduce DNS lookups
UseDNS no
# Faster login
GSSAPIAuthentication no

# Authentication (key-based only for security)
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile %h/.ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no

# Forwarding
AllowTcpForwarding yes
X11Forwarding no

# Other settings
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp ${pkgs.openssh}/libexec/sftp-server
EOF
                fi

                chmod 600 "$HOME/.ssh/sshd_config"

                # Create helper script to start SSH server with connection info
                cat <<'EOS' > "$HOME/.ssh/start-sshd.sh"
#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/.ssh/sshd.log"
rm -f "$LOGFILE"
${pkgs.openssh}/bin/sshd -f "$HOME/.ssh/sshd_config" -E "$LOGFILE" || {
  echo "sshd failed to launch. Log:" >&2
  if [ -f "$LOGFILE" ]; then
    while IFS= read -r line; do printf '  %s\n' "$line"; done < "$LOGFILE" >&2 || true
  else
    echo "  (log file missing)" >&2
  fi
  exit 1
}

sleep 0.3
if pgrep -f "sshd -f $HOME/.ssh/sshd_config" >/dev/null 2>&1; then
  echo "✓ SSH server started successfully!"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ZERO-CONFIG CONNECTION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "On your Mac/client, run this ONE command:"
  echo ""
  # Android-compatible IP detection
  if command -v ip >/dev/null 2>&1; then
    ip -4 addr show 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}' | grep -v '^127\.' | head -n1 | while read -r ipaddr; do
      echo "  scp -P 8022 ~/.ssh/android_client_key* $ipaddr:~/.ssh/ && ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@$ipaddr"
    done
  elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig 2>/dev/null | grep 'inet ' | awk '{print $2}' | sed 's/addr://' | grep -v '^127\.' | head -n1 | while read -r ipaddr; do
      echo "  scp -P 8022 ~/.ssh/android_client_key* $ipaddr:~/.ssh/ && ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@$ipaddr"
    done
  fi
  echo ""
  echo "This will:"
  echo "  1. Copy the auto-generated key to your client"
  echo "  2. Connect automatically (no password needed!)"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Alternative: Manual setup"
  echo "-------------------------"
  echo "1. Copy this file from Android to your Mac:"
  echo "   $HOME/.ssh/android_client_key"
  echo ""
  echo "2. Then connect with:"
  if command -v ip >/dev/null 2>&1; then
    ip -4 addr show 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}' | grep -v '^127\.' | while read -r ipaddr; do
      echo "   ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@$ipaddr"
    done
  elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig 2>/dev/null | grep 'inet ' | awk '{print $2}' | sed 's/addr://' | grep -v '^127\.' | while read -r ipaddr; do
      echo "   ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@$ipaddr"
    done
  fi
  echo ""
  echo "Log file: $LOGFILE"
else
  echo "Failed to start SSH server!" >&2
  echo "Last 50 log lines:" >&2
  if [ -f "$LOGFILE" ]; then
    tail -n 50 "$LOGFILE" 2>/dev/null | while IFS= read -r line; do printf '  %s\n' "$line"; done >&2
  else
    echo "  (no log)" >&2
  fi
  exit 1
fi
EOS
                $DRY_RUN_CMD chmod +x "$HOME/.ssh/start-sshd.sh"

                # Create helper script to stop SSH server
                printf '#!/usr/bin/env bash\npkill -f "sshd -f $HOME/.ssh/sshd_config"\n' > $HOME/.ssh/stop-sshd.sh
                $DRY_RUN_CMD chmod +x $HOME/.ssh/stop-sshd.sh

                # Create helper script to display the private key for easy copying
                cat <<'SHOW_KEY' > "$HOME/.ssh/show-client-key.sh"
#!/usr/bin/env bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CLIENT KEY (Copy this to your Mac)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run this on your Mac to save the key:"
echo ""
echo "cat > ~/.ssh/android_client_key << 'EOF'"
cat "$HOME/.ssh/android_client_key"
echo "EOF"
echo "chmod 600 ~/.ssh/android_client_key"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SHOW_KEY
                $DRY_RUN_CMD chmod +x "$HOME/.ssh/show-client-key.sh"

                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "  SSH Server Setup Complete!"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "Quick start:"
                echo "  1. Start SSH:  ~/.ssh/start-sshd.sh"
                echo "  2. Show key:   ~/.ssh/show-client-key.sh"
                echo "  3. Stop SSH:   ~/.ssh/stop-sshd.sh"
                echo ""
                echo "Features:"
                echo "  • Auto-generated Ed25519 keys (no RSA)"
                echo "  • Zero-config passwordless login"
                echo "  • Port 8022"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              '';

              # Home-manager integration
              home-manager = {
                backupFileExtension = "hm-bak";
                useGlobalPkgs = true;
                config =
                  { config, pkgs, lib, ... }:
                  {
                    # Note: home.username and home.homeDirectory are automatically
                    # managed by nix-on-droid and should not be set here
                    home.stateVersion = "24.05";

                    # Allow unfree packages
                    nixpkgs.config.allowUnfree = true;

                    # Shared packages
                    home.packages = sharedPackages pkgs;

                    # Programs configuration
                    programs = {
                      neovim = {
                        enable = true;
                        defaultEditor = true;
                      };

                      tmux = {
                        enable = true;
                        keyMode = "vi";
                        mouse = true;
                        plugins = with pkgs.tmuxPlugins; [
                          better-mouse-mode
                          yank
                          {
                            plugin = catppuccin;
                            extraConfig = ''
                              set -g default-terminal "tmux-256color"
                              set-option -ga terminal-overrides ",xterm-256color:Tc"
                              set -g @catppuccin_flavor "mocha"
                              set -g @catppuccin_window_status_style "rounded"
                            '';
                          }
                        ];
                        extraConfig = ''
                          set -sg escape-time 0
                          setw -g mode-keys vi
                          bind-key -T copy-mode-vi v send-keys -X begin-selection
                          bind c new-window -c "#{pane_current_path}"
                          bind | split-window -h -c "#{pane_current_path}"
                          bind - split-window -v -c "#{pane_current_path}"

                          # Pane border highlighting
                          set -g pane-border-style "fg=#313244"
                          set -g pane-active-border-style "fg=#89b4fa,bold"

                          # Dim inactive panes
                          set -g window-style "fg=#585b70,bg=#181825"
                          set -g window-active-style "fg=#cdd6f4,bg=#1e1e2e"

                          # Vim-like pane navigation
                          is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
                          bind -n C-h run "($is_vim && tmux send-keys C-h) || tmux select-pane -L"
                          bind -n C-j run "($is_vim && tmux send-keys C-j) || tmux select-pane -D"
                          bind -n C-k run "($is_vim && tmux send-keys C-k) || tmux select-pane -U"
                          bind -n C-l run "($is_vim && tmux send-keys C-l) || tmux select-pane -R"
                        '';
                      };

                      zsh = {
                        enable = true;
                        initContent = lib.mkOrder 550 ''
                          export GOPATH=$HOME/go
                          export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

                          # Global npm prefix for Copilot CLI
                          export NPM_CONFIG_PREFIX="$HOME/.npm-global"
                          export PATH="$HOME/.npm-global/bin:$PATH"

                          # Termux-specific
                          export TMPDIR=/data/data/com.termux.nix/files/usr/tmp

                          # SSH session optimization - set TERM for better compatibility
                          if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
                            export TERM=xterm-256color
                          fi
                        '';
                        shellAliases = {
                          ll = "ls -l";
                          lg = "lazygit";
                          e = "nvim";
                          copilot = "github-copilot-cli";
                        };
                        oh-my-zsh = {
                          enable = true;
                          theme = "robbyrussell";
                        };
                      };

                      lazygit.enable = true;
                      direnv.enable = true;
                    };

                    # Neovim config
                    home.file.".config/nvim/" = {
                      source = ./nvim;
                      recursive = true;
                    };
                  };
              };
            }
          ];
        };

      # Formatter
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.alejandra;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      };
    };
}
