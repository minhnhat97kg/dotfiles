#!/usr/bin/env bash
# scripts/secrets-sync.sh
# Unified secret sync (generate/update sops-encrypted secrets) - 2025-11-19T08:33:05.120Z
# Combines previous migration & update scripts.
# Requires: sops, age key (public recipient already embedded), optional yq.

set -euo pipefail
AGE_RECIP="age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SSH_DIR="$HOME/.ssh"
SECRETS_DIR="$ROOT_DIR/secrets"
SSH_SOPS_DIR="$SECRETS_DIR/ssh"
GIT_SOPS_DIR="$SECRETS_DIR/git"
AWS_SOPS_DIR="$SECRETS_DIR"

# Definition format:
# folder:type:source_file:target_sops_filename:mode[:stringData_field]
# folder key maps to handling logic; currently only 'ssh', 'git', 'aws'.
SOURCES=(
  "ssh:id_rsa:id_rsa:id_rsa.sops.yaml:0600"
  "ssh:id_ed25519:id_ed25519:id_ed25519.sops.yaml:0600"
  "ssh:cuong_rsa:cuong_rsa:cuong_rsa.sops.yaml:0600"
  "ssh:id_minhnhat97kg:id_minhnhat97kg:id_minhnhat97kg.sops.yaml:0600"
  "ssh:bitbucket-ssh:bitbucket-ssh:bitbucket-ssh.sops.yaml:0600"
  "ssh:config:config:config.sops.yaml:0600:key"  # SSH config (field name key)
  "aws:config:aws-config:aws-config.sops.yaml:0644:config" # AWS config (field name config)
  "git:work.gitconfig:work.gitconfig:work.gitconfig.sops.yaml:0644:config" # work gitconfig
)

need_cmd() { command -v "$1" >/dev/null || { echo "Missing required command: $1"; exit 1; }; }

indent() { sed 's/^/    /'; }

build_yaml() {
  local name="$1" field="$2" content_file="$3"
  echo "kind: Secret"
  echo "metadata:"; echo "  name: $name"
  echo "stringData:"; echo "  $field: |"; indent < "$content_file"
}

encrypt_in_place() {
  local file="$1"
  # If file already has a sops block, use edit/encrypt appropriately.
  if grep -q '^sops:' "$file" 2>/dev/null; then
    # Re-encrypt via round-trip to ensure metadata updates (editor mode writes plaintext then encrypts).
    sops --decrypt "$file" >/dev/null 2>&1 || true
    sops --in-place "$file"
  else
    sops --encrypt --age "$AGE_RECIP" --in-place "$file"
  fi
}

process_source() {
  local spec="$1"
  IFS=':' read -r kind type src target mode field <<<"$spec"
  local source_path
  local out_dir
  local name
  local field_name="key"

  case "$kind" in
    ssh)
      out_dir="$SSH_SOPS_DIR"; source_path="$SSH_DIR/$src"; name="ssh-$src" ;;
    git)
      out_dir="$GIT_SOPS_DIR"; source_path="$ROOT_DIR/secrets/git/$src"; name="git-work-config" ;;
    aws)
      out_dir="$AWS_SOPS_DIR"; source_path="$ROOT_DIR/secrets/$src"; name="aws-config" ;;
    *) echo "Unknown kind: $kind"; return 1 ;;
  esac

  [[ -n "$field" ]] && field_name="$field"
  mkdir -p "$out_dir"
  local target_path="$out_dir/$target"

  if [[ ! -f "$source_path" ]]; then
    echo "Skip $target (missing source: $source_path)"
    return
  fi

  local tmp_plain; tmp_plain=$(mktemp)
  build_yaml "$name" "$field_name" "$source_path" > "$tmp_plain"
  mv "$tmp_plain" "$target_path"
  encrypt_in_place "$target_path"
  chmod "$mode" "$target_path" || true
  echo "Synced $target_path (mode $mode)"
}

main() {
  need_cmd sops
  mkdir -p "$SSH_SOPS_DIR" "$GIT_SOPS_DIR" "$AWS_SOPS_DIR"
  for s in "${SOURCES[@]}"; do
    process_source "$s"
  done
  echo "All secrets processed. Commit only encrypted *.sops.yaml files."
}

main "$@"
