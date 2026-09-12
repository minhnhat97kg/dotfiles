{ ... }:
{
  home.file.".ssh/authorized_keys" = {
    text = ''
      ssh-ed25519 AAAA_REPLACE_WITH_PUBLIC_KEY user@example-device
    '';
  };

  programs.lazygit = {
    enable = true;
    enableZshIntegration = false; # Disable lg() function, use simple alias instead
  };

  programs.direnv.enable = true;

  home.file.".config/nvim/" = {
    # Keep vim.pack's lockfile writable. Neovim writes
    # ~/.config/nvim/nvim-pack-lock.json on startup/update, so it must not be
    # symlinked into the read-only Nix store.
    source = builtins.filterSource
      (path: _type: builtins.baseNameOf path != "nvim-pack-lock.json")
      ../../shared/nvim;
    recursive = true;
    force = true;
  };
  home.file.".scripts/" = {
    source = ../../shared/scripts;
    recursive = true;
    executable = true;
    force = true;
  };
}

