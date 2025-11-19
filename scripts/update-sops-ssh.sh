#!/usr/bin/env bash
# scripts/update-sops-ssh.sh
# Auto-fill existing SOPS secret placeholder values from real ~/.ssh files.
# Generated at 2025-11-19T08:31:19.538Z
set -euo pipefail

AGE_RECIP="age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas"
SSH_DIR="${HOME}/.ssh"
SOPS_DIR="secrets/ssh"

# Map: sops file -> source key file (key_field always 'key' except config)
declare -A FILE_MAP=(
  ["id_rsa.sops.yaml"]="id_rsa"
  ["id_ed25519.sops.yaml"]="id_ed25519"
  ["cuong_rsa.sops.yaml"]="cuong_rsa"
  ["id_minhnhat97kg.sops.yaml"]="id_minhnhat97kg"
  ["bitbucket-ssh.sops.yaml"]="bitbucket-ssh"
  ["config.sops.yaml"]="config"
)

ensure() {
  command -v sops >/dev/null || { echo "sops not found"; exit 1; }
  command -v yq >/dev/null || command -v yq-go >/dev/null || echo "yq optional (using sed fallback)."
}

indent() {
  sed 's/^/    /'
}

build_yaml() {
  local name="$1" key_field="$2" content_file="$3"
  echo "kind: Secret"
  echo "metadata:"
  echo "  name: $name"
  echo "stringData:"
  echo "  $key_field: |"
  indent < "$content_file"
}

encrypt_yaml() {
  local out="$1"
  sops --encrypt --age "$AGE_RECIP" --in-place "$out" 2>/dev/null || {
    local tmp=$(mktemp)
    sops --encrypt --age "$AGE_RECIP" "$out" > "$tmp" && mv "$tmp" "$out"
  }
}

process_one() {
  local sops_file="$1" src_name="$2"
  local src_path="$SSH_DIR/$src_name"
  local key_field="key"
  local secret_name="ssh-${src_name}"
  [[ "$src_name" == "config" ]] && secret_name="ssh-config" && key_field="key"

  if [[ ! -f "$src_path" ]]; then
    echo "Skip $sops_file (missing $src_path)"
    return
  fi

  local tmp_plain
  tmp_plain=$(mktemp)
  build_yaml "$secret_name" "$key_field" "$src_path" > "$tmp_plain"

  if sops --decrypt "$SOPS_DIR/$sops_file" >/dev/null 2>&1; then
    echo "Updating $sops_file"
  else
    echo "Creating $sops_file"
  fi

  cp "$tmp_plain" "$SOPS_DIR/$sops_file"
  encrypt_yaml "$SOPS_DIR/$sops_file"
  rm -f "$tmp_plain"
}

main() {
  ensure
  mkdir -p "$SOPS_DIR"
  for f in "${!FILE_MAP[@]}"; do
    process_one "$f" "${FILE_MAP[$f]}"
  done
  echo "Complete. Review encrypted *.sops.yaml (metadata + ciphertext)."
}

main "$@"
