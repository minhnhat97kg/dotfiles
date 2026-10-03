# Host-specific configuration for nix-on-droid (Android)
{ config, pkgs, lib, sharedPackages, neovim-src, ... }:
{
  # nix-on-droid's own `installPackages` activation script
  # (modules/environment/path.nix) parses `nix profile list` with
  # `cut -d ' ' -f 4`, which only matches the single-line output of Nix < 2.18.
  # Nix >= 2.18 prints a multi-line format (`Name: ...`), so the extraction is
  # empty and `xargs` invokes `nix profile remove` with no arguments, aborting
  # activation with:
  #
  #   nix profile remove
  #   error: No packages specified.
  #
  # It also fails right before with `nix-env -q` inside
  # `setPriorityHomeManagerPath`, because a `nix profile`-style profile is
  # unreadable by `nix-env`.
  #
  # This override removes by the known element name and only calls remove when
  # the element is actually present, so it works on both old and new Nix.
  # `build.activation` is `types.attrs` (shallow `//` merge), so a per-key
  # mkForce is ignored and upstream's definition wins. mkAfter orders this
  # definition last, replacing only installPackages.
  build.activation = lib.mkAfter { installPackages = ''
    if [[ -e "${config.user.home}/.nix-profile/manifest.json" ]]; then
      # manual removal and installation as two non-atomic steps is required
      # because of https://github.com/NixOS/nix/issues/6349

      nix_previous="$(command -v nix)"

      if $nix_previous profile list 2>/dev/null | grep -q 'nix-on-droid-path'; then
        $DRY_RUN_CMD $nix_previous profile remove nix-on-droid-path $VERBOSE_ARG
      fi

      $DRY_RUN_CMD $nix_previous profile install ${config.environment.path}

      unset nix_previous
    else
      $DRY_RUN_CMD nix-env --install ${config.environment.path}
    fi
  ''; };

  # Home-manager integration
  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true; # Install packages via environment.packages, not nix-env
    # modules/home/default.nix and editor.nix take `sharedPackages` and
    # `neovim-src` as module arguments, but nix-on-droid does NOT forward its
    # own extraSpecialArgs to home-manager. Without this it fails evaluation
    # with "called without required argument 'neovim-src'" and the switch never
    # completes.
    extraSpecialArgs = { inherit neovim-src sharedPackages; };
    config = { config, pkgs, lib, ... }: {
      imports = [ ../../modules/home/default.nix ];

      home.stateVersion = lib.mkForce "24.05";

      # Disable home.packages for Android - packages must be in environment.packages
      # This avoids nix-env/nix profile compatibility issues
      home.packages = lib.mkForce [ ];

      # Disable programs that are installed via environment.packages
      # to avoid conflicts on Android
      programs.neovim.enable = lib.mkForce false;
      programs.tmux.enable = lib.mkForce false;
      programs.lazygit.enable = lib.mkForce false;

      # The shared files.nix installs a placeholder ~/.ssh/authorized_keys.
      # modules/platforms/android.nix generates a real client key and appends it
      # to that same file during activation; a read-only Nix-store symlink would
      # make those appends fail, so leave the file unmanaged on Android.
      home.file.".ssh/authorized_keys".enable = lib.mkForce false;

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

      # tmux config is already supplied by the shared modules/home/terminal.nix,
      # which recursively symlinks the whole shared/tmux directory.
    };
  };
}
