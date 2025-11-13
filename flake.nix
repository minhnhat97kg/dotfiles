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
          neovim
          ripgrep # rg - fast grep alternative
          fd # fast find alternative
          jq # JSON processor
          jless # JSON viewer

          # Shell & Terminal
          tmux
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
          goreleaser
          go-task # Task runner

          # Database Tools
          postgresql
          mysql80
          redis
          mycli # MySQL CLI client
          pgcli # PostgreSQL CLI client
          usql # Universal SQL CLI
          pspg # PostgreSQL pager
          dblab # Database lab

          # API & HTTP Tools
          httpie
          hurl # HTTP testing tool

          # Container Tools
          podman
          lazydocker

          # Security & Auth
          gnupg
          stripe-cli
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
              initExtra = ''
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
                  "https://mirror.sjtu.edu.cn/nix-channels/store"
                  "https://nix-community.cachix.org"
                ];
                trusted-public-keys = [
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
      nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
        modules = [
          {
            # Nix-on-droid specific settings
            system.stateVersion = "24.05";

            # Allow unfree packages
            nixpkgs.config.allowUnfree = true;

            # Nix configuration
            nix = {
              extraOptions = ''
                experimental-features = nix-command flakes
              '';

              substituters = [
                "https://nix-community.cachix.org"
                "https://cache.nixos.org"
              ];

              trustedPublicKeys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
            };

            # User configuration
            user.shell = "${nixpkgs.legacyPackages.aarch64-linux.zsh}/bin/zsh";

            # Android-specific environment
            environment.packages = with nixpkgs.legacyPackages.aarch64-linux; [
              # Core utilities
              git
              neovim
              tmux
              fzf

              # Development tools
              go

              # Shell
              zsh
              oh-my-zsh

              # SSH Server
              openssh
            ];

            # Terminal configuration
            terminal.font = "${nixpkgs.legacyPackages.aarch64-linux.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCodeNerdFont-Regular.ttf";

            # Build activation script to set up SSH server
            build.activation.sshd = ''
              $DRY_RUN_CMD mkdir -p $HOME/.ssh
              $DRY_RUN_CMD chmod 700 $HOME/.ssh

              # Create SSH host keys if they don't exist
              if [ ! -f $HOME/.ssh/ssh_host_rsa_key ]; then
                $DRY_RUN_CMD ${nixpkgs.legacyPackages.aarch64-linux.openssh}/bin/ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/ssh_host_rsa_key -N ""
              fi
              if [ ! -f $HOME/.ssh/ssh_host_ed25519_key ]; then
                $DRY_RUN_CMD ${nixpkgs.legacyPackages.aarch64-linux.openssh}/bin/ssh-keygen -t ed25519 -f $HOME/.ssh/ssh_host_ed25519_key -N ""
              fi

              # Create sshd_config if it doesn't exist
              if [ ! -f $HOME/.ssh/sshd_config ]; then
                $DRY_RUN_CMD cat > $HOME/.ssh/sshd_config << 'EOF'
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
              Subsystem sftp ${nixpkgs.legacyPackages.aarch64-linux.openssh}/libexec/sftp-server
              EOF
              fi

              $DRY_RUN_CMD chmod 600 $HOME/.ssh/sshd_config
              $DRY_RUN_CMD touch $HOME/.ssh/authorized_keys
              $DRY_RUN_CMD chmod 600 $HOME/.ssh/authorized_keys

              echo "SSH server setup complete!"
              echo "To start SSH server, run: sshd -f ~/.ssh/sshd_config"
              echo "To add your public key, add it to: ~/.ssh/authorized_keys"
              echo "SSH will be available on port 8022"
            '';

            # Home-manager integration for Android
            home-manager = {
              config =
                { pkgs, ... }:
                nixpkgs.lib.mkMerge [
                  (sharedHomeConfig { inherit pkgs; })
                  {
                    home.username = username;
                    home.homeDirectory = "/data/data/com.termux.nix/files/home";

                    # Android-specific shell configuration
                    programs.zsh.initExtra = ''
                      # Android-specific paths
                      export GOPATH=$HOME/go
                      export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

                      # Termux-specific
                      export TMPDIR=/data/data/com.termux.nix/files/usr/tmp
                    '';
                  }
                ];
              useGlobalPkgs = true;
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
