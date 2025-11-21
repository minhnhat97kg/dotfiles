if [[ ! "$PATH" == *"/usr/local/opt/fzf/bin"* ]]; then
  export PATH="/usr/local/opt/fzf/bin:$PATH"
fi
source <(fzf --zsh)
