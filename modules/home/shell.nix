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

      # Homebrew (installed by nix-homebrew — see modules/platforms/darwin.nix).
      # Nix puts the `brew` wrapper on PATH but not the formulae CLIs it
      # installs, which live under /opt/homebrew. Guarded so Linux/Android
      # shells (no Homebrew) skip it.
      [ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

      # opencode (optional — only if installed)
      [ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"
      alias claude-api="CLAUDE_CONFIG_DIR=~/.claude-api claude"
      # Bare `jiratui` opens the UI on the "Have to do" filter (id 6 in its config).
      jiratui() { (( $# )) || set -- ui -j 6; JIRA_API_TOKEN="$(cat ~/.config/jiratui/token 2>/dev/null)" command jiratui "$@"; }

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

      # Bare `tmux` (or `tmux attach`) from a fresh shell opens the session
      # picker — existing sessions + a "new session" entry — instead of always
      # spawning a new session. Everything else, and anything already inside
      # tmux, passes straight through to the real binary. The picker lives in
      # shared/tmux/scripts/session-picker.sh.
      tmux() {
        if [[ -n "$TMUX" || ! -t 0 || ! -t 1 ]]; then
          command tmux "$@"
          return
        fi
        case "$1" in
          ""|attach|a|at|attach-session)
            if (( $# > 1 )); then
              command tmux "$@"
            else
              "$HOME/.config/tmux/scripts/session-picker.sh"
            fi
            ;;
          *)
            command tmux "$@"
            ;;
        esac
      }

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
