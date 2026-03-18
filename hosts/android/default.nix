# Host-specific configuration for nix-on-droid (Android)
{ pkgs, lib, sharedPackages, ... }:
{
  # Home-manager integration
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true; # Install packages via environment.packages, not nix-env
    config = { config, pkgs, lib, ... }: {
      imports = [ ../../modules/home/default.nix ];

      _module.args.sharedPackages = sharedPackages;

      home.stateVersion = lib.mkForce "24.05";
      nixpkgs.config.allowUnfree = true;

      # Disable home.packages for Android - packages must be in environment.packages
      # This avoids nix-env/nix profile compatibility issues
      home.packages = lib.mkForce [ ];

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

        # Desktop environment helper
        export PATH="$HOME/.local/bin:$PATH"
      '';

      # Manual tmux config since programs.tmux is disabled on Android
      home.file.".config/tmux/tmux.conf".source = ../../tmux/tmux.conf;
    };
  };
}
