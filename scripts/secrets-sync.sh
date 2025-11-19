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

# Auto-detect sources by scanning directories
# SSH keys
# Git work config and AWS config are expected in secrets/git and secrets respectively

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

process_ssh_dir() {
  mkdir -p "$SSH_SOPS_DIR"
  for key in id_rsa id_ed25519 cuong_rsa id_minhnhat97kg bitbucket-ssh; do
    local src="$SSH_DIR/$key"
    [[ -f "$src" ]] || { echo "Skip ssh-$key (missing)"; continue; }
    local out="$SSH_SOPS_DIR/${key}.sops.yaml"
    build_yaml "ssh-$key" key "$src" > "$out"
    encrypt_in_place "$out"
    echo "Synced $out"
  done
  # SSH config
  if [[ -f "$SSH_DIR/config" ]]; then
    local out="$SSH_SOPS_DIR/config.sops.yaml"
    build_yaml "ssh-config" key "$SSH_DIR/config" > "$out"
    encrypt_in_place "$out"
    echo "Synced $out"
  fi
}

process_git() {
  mkdir -p "$GIT_SOPS_DIR"
  local src="$GIT_SOPS_DIR/../work.gitconfig"
  if [[ -f "$ROOT_DIR/secrets/git/work.gitconfig" ]]; then
    src="$ROOT_DIR/secrets/git/work.gitconfig"
    local out="$GIT_SOPS_DIR/work.gitconfig.sops.yaml"
    build_yaml "git-work-config" config "$src" > "$out"
    encrypt_in_place "$out"
    echo "Synced $out"
  else
    echo "Skip git-work-config (missing secrets/git/work.gitconfig)"
  fi
}

process_aws() {
  local src="$ROOT_DIR/secrets/aws-config"
  if [[ -f "$src" ]]; then
    local out="$AWS_SOPS_DIR/aws-config.sops.yaml"
    build_yaml "aws-config" config "$src" > "$out"
    encrypt_in_place "$out"
    echo "Synced $out"
  else
    echo "Skip aws-config (missing secrets/aws-config)"
  fi
}

main() {
  need_cmd sops
  mkdir -p "$SSH_SOPS_DIR" "$GIT_SOPS_DIR" "$AWS_SOPS_DIR"
  process_ssh_dir
  process_git
  process_aws
  echo "All secrets processed. Commit only encrypted *.sops.yaml files."
}

main "$@"
