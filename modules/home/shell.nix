{ lib, ... }:
{
  programs.zsh = {
    enable = true;
    initContent = lib.mkOrder 550 ''
      export LANG=en_US.UTF-8
      export LC_ALL=en_US.UTF-8
      export GOPATH=$HOME/go
      export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      export PATH="$HOME/.npm-global/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$HOME/.cargo/bin:$PATH"
      export BUN_INSTALL="$HOME/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
      ALIASES_SCRIPT="$HOME/.config/dotfiles/scripts/load-aliases.sh"
      export AWS_REGION=ap-southeast-1
      if [ -f "$ALIASES_SCRIPT" ]; then
        eval "$($ALIASES_SCRIPT)"
      fi
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
      export XDG_CONFIG_HOME="$HOME/.config"
      export PATH="$HOME/.scripts:$PATH"

      # opencode (optional — only if installed)
      [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
      alias claude-api="CLAUDE_CONFIG_DIR=~/.claude-api claude"

      # Ollama server tuning (macOS: also set for GUI via launchd — see modules/platforms/darwin.nix)
      # q8_0 KV cache + flash attention keep 32k context from swapping on 16GB machines;
      # a single loaded model / single parallel slot avoids loading ornith + coder at once.
      # keep_alive is short so the model unloads when idle and stops pinning ~6GB of RAM
      # (resident weights force other apps into swap, which is the real battery cost).
      export OLLAMA_FLASH_ATTENTION=1
      export OLLAMA_KV_CACHE_TYPE=q8_0
      export OLLAMA_MAX_LOADED_MODELS=1
      export OLLAMA_NUM_PARALLEL=1
      export OLLAMA_KEEP_ALIVE=5m

    '';

    shellAliases = {
      ll = "ls -l";
      e = "nvim";
      lg = "lazygit";
      eink = "DISPLAY_MODE=eink nvim";
    };
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };
  };
}
