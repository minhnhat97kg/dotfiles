{ ... }:
{
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
  # gh-dash: `D` on a PR opens it in nvim's Diffview (needs repoPaths).
  home.file.".config/gh-dash/config.yml" = {
    source = ../../shared/gh-dash/config.yml;
    force = true;
  };
  # jiratui itself comes from `make jiratui` (uv tool; nixpkgs lags behind).
  # Its config (work Jira site/account) and token live only in ~/.config/jiratui,
  # untracked; the token is read by the `jiratui` function in shell.nix.
  home.file.".scripts/" = {
    source = ../../shared/scripts;
    recursive = true;
    executable = true;
    force = true;
  };
}

