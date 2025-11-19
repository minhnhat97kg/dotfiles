#!/usr/bin/env bash
# minimal secrets-sync 2025-11-19T15:00:36Z

set -euo pipefail
AGE_RECIP="age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SSH_DIR="$HOME/.ssh"
SECRETS_DIR="$ROOT_DIR/secrets"
SSH_SOPS_DIR="$SECRETS_DIR/ssh"
GIT_SOPS_DIR="$SECRETS_DIR/git"
AWS_SOPS_DIR="$SECRETS_DIR"


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
  local keys=()
  if [[ -n "${SSH_KEYS:-}" ]]; then IFS=',' read -r -a keys <<<"$SSH_KEYS"; else for f in $SSH_DIR/id_* $SSH_DIR/*_rsa $SSH_DIR/bitbucket-ssh; do [[ -f "$f" ]] && keys+=("$(basename "$f")"); done; fi
  local uniq=(); declare -A seen; for k in "${keys[@]}"; do [[ -n "${seen[$k]:-}" ]] || { uniq+=("$k"); seen[$k]=1; }; done
  for key in "${uniq[@]}"; do
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
  local base="$ROOT_DIR/secrets/git"
  if [[ -d "$base" ]]; then
    for f in "$base"/*.gitconfig; do
      [[ -f "$f" ]] || continue
      local name="git-$(basename "$f" .gitconfig)"
      local out="$GIT_SOPS_DIR/$(basename "$f").sops.yaml"
      build_yaml "$name" config "$f" > "$out"
      encrypt_in_place "$out"
      echo "Synced $out"
    done
  else
    echo "Skip git (directory $base missing)"
  fi
}

process_aws() {
  # aws-* auto
  local base="$ROOT_DIR/secrets"
  shopt -s nullglob
  for f in "$base"/aws-* "$base"/*-aws-config" "$base"/aws-config; do
    [[ -f "$f" ]] || continue
    local tag="$(basename "$f")"
    local name="${tag%%.*}" # strip extension if any
    local out="$AWS_SOPS_DIR/${tag}.sops.yaml"
    build_yaml "$name" config "$f" > "$out"
    encrypt_in_place "$out"
    echo "Synced $out"
  done
  shopt -u nullglob
}

main() {
  need_cmd sops
  # Optional extra dirs SOURCES_DIRS
  local default_dirs=("$SSH_DIR" "$ROOT_DIR/secrets/git" "$ROOT_DIR/secrets")
  local extra=()
  if [[ -n "${SOURCES_DIRS:-}" ]]; then IFS=',' read -r -a extra <<<"$SOURCES_DIRS"; fi
  local all=("${default_dirs[@]}" "${extra[@]}")
  mkdir -p "$SSH_SOPS_DIR" "$GIT_SOPS_DIR" "$AWS_SOPS_DIR"
  process_ssh_dir
  process_git
  process_aws
  for d in "${all[@]}"; do
    [[ -d "$d" ]] || continue
    # Generic catch-all: encrypt any *.secret, *.secret.txt, *.secret.env files
    shopt -s nullglob
    for f in "$d"/*.secret "$d"/*.secret.*; do
      [[ -f "$f" ]] || continue
      local tag="$(basename "$f")"
      local name="generic-${tag%%.*}"
      local out="$SECRETS_DIR/${tag}.sops.yaml"
      build_yaml "$name" value "$f" > "$out"
      encrypt_in_place "$out"
      echo "Synced generic $out"
    done
    shopt -u nullglob
  done
  echo "All secrets processed. Commit only encrypted *.sops.yaml files."
}

main "$@"
