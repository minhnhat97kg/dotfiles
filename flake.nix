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
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # home-manager for user configuration
    home-manager = {
      url = "github:nix-community/home-manager";
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
          gh # GitHub CLI
          fzf
          # neovim - configured via programs.neovim instead
          ripgrep # rg - fast grep alternative
          fd # fast find alternative
          jq # JSON processor
          jless # JSON viewer

          # Shell & Terminal
          # tmux - configured via programs.tmux instead
          tmuxinator
          ranger # File manager
          htop # Process viewer
          coreutils # GNU core utilities

          # Development - General
          go
          delve # Go debugger
          goimports-reviser # Go imports formatter
          maven
          gradle
          nodejs # Node.js runtime

          # Development - Rust
          cargo
          rustc
          rustfmt
          clippy
          rust-analyzer

          # Development - Python
          python3
          pipx

          # Development - Ruby
          rbenv
          ruby

          # Cloud & DevOps
          terraform

          # Database Tools
          postgresql
          mysql80
          redis
          mycli # MySQL CLI client
          pgcli # PostgreSQL CLI client
          usql # Universal SQL CLI
          pspg # PostgreSQL pager
          # dblab # Database lab - currently broken, build fails

          # API & HTTP Tools
          httpie
          hurl # HTTP testing tool

          # Container Tools
          podman
          lazydocker

          # Security & Auth
          aws-vault # AWS credential manager

          # File & Text Processing
          # git-delta # Better git diff

          # Monitoring & System
          # watchman # File watching

          # Utilities
          fx # JSON viewer
        ];

      # Shared home-manager configuration
      sharedHomeConfig =
        { pkgs, ... }:
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
              initExtraBeforeCompInit = ''
                export GOPATH=$HOME/go
                export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
              '';
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
            ];

            # Host & user configuration
            networking.hostName = "Nathan-Macbook";
            networking.computerName = "Nathan-Macbook";

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
              { pkgs, ... }:
              nixpkgs.lib.mkMerge [
                (sharedHomeConfig { inherit pkgs; })
                {
                  home.username = username;
                  home.homeDirectory = "/Users/${username}";

                  # macOS-specific home files
                  home.file.".config/yabai/yabairc".source = ./yabai/yabairc;
                  home.file.".config/zellij/config.kdl".source = ./zellij/config.kdl;

                  # macOS-specific packages
                  home.packages = with pkgs; [
                    # Development Tools (macOS GUI)
                    alacritty # Terminal emulator

                    # Hardware/Embedded Development
                    qmk # Keyboard firmware

                    # Additional Tools
                    localstack # Local AWS cloud stack
                  ];

                  programs.zellij.enable = true;
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

                # Development tools
                go

                # Shell
                zsh
                oh-my-zsh

                # SSH Server
                openssh
                net-tools
              ];

              # Terminal configuration
              terminal.font = "${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCodeNerdFont-Regular.ttf";

              # Build activation script to set up SSH server
              build.activation.sshd = ''
                mkdir -p "$HOME/.ssh"
                chmod 700 "$HOME/.ssh"

                # Create SSH host keys if they don't exist
                if [ ! -f $HOME/.ssh/ssh_host_rsa_key ]; then
                  ${pkgs.openssh}/bin/ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/ssh_host_rsa_key" -N ""
                fi
                if [ ! -f $HOME/.ssh/ssh_host_ed25519_key ]; then
                  ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$HOME/.ssh/ssh_host_ed25519_key" -N ""
                fi

                # Create sshd_config if it doesn't exist
                if [ ! -f "$HOME/.ssh/sshd_config" ]; then
                  cat <<'EOF' > "$HOME/.ssh/sshd_config"
# SSH Server Configuration for Nix-on-Droid
Port 8022
ListenAddress 0.0.0.0

# Host keys
HostKey ~/.ssh/ssh_host_rsa_key
HostKey ~/.ssh/ssh_host_ed25519_key

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
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
                touch "$HOME/.ssh/authorized_keys"
                chmod 600 "$HOME/.ssh/authorized_keys"

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
  echo "SSH server started successfully!"
  echo ""
  echo "Connection information:"
  echo "======================="
  echo "Port: 8022"
  echo "User: nix-on-droid"
  echo ""
  echo "Device IP addresses:" 
  if command -v ip >/dev/null 2>&1; then
    ip -4 addr show | grep -oE '(?<=inet )([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '^127\.' | while read -r ip; do
      echo "  ssh -p 8022 nix-on-droid@$ip"
    done
  elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig | grep 'inet ' | awk '{print $2}' | grep -v '^127\.' | while read -r ip; do
      echo "  ssh -p 8022 nix-on-droid@$ip"
    done
  else
    echo "  (No ip/ifconfig available to enumerate addresses)"
  fi
  echo ""
  echo "Make sure your public key is in: $HOME/.ssh/authorized_keys"
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

                echo "SSH server setup complete!"
                echo "To start SSH server, run: ~/.ssh/start-sshd.sh"
                echo "  Or with absolute path: ${pkgs.openssh}/bin/sshd -f ~/.ssh/sshd_config"
                echo "To stop SSH server, run: ~/.ssh/stop-sshd.sh"
                echo "To add your public key, add it to: ~/.ssh/authorized_keys"
                echo "SSH will be available on port 8022"
              '';

              # Home-manager integration
              home-manager = {
                backupFileExtension = "hm-bak";
                useGlobalPkgs = true;
                config =
                  { config, pkgs, ... }:
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
                        initExtraBeforeCompInit = ''
                          export GOPATH=$HOME/go
                          export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

                          # Termux-specific
                          export TMPDIR=/data/data/com.termux.nix/files/usr/tmp
                        '';
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
