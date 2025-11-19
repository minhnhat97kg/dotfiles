   #!/usr/bin/env bash
# NOTE: Corrected formatting
# Created at 2025-11-19T08:27:11.617Z
# Convert local ~/.ssh keys/config into sops-encrypted YAML secrets for sops-nix.
set -euo pipefail
   AGE_RECIP="age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas"
SSH_DIR="${HOME}/.ssh"
   SOPS_DIR="secrets/ssh"

   encrypt_file() {
  local name="$1" src="$2" yaml="$3" key_field="${4:-key}"
  if [ ! -f "$src" ]; then
       echo "Skip $name (missing $src)"
    return
  fi
  tmp=$(mktemp)
  {
    echo "kind: Secret"
    echo "metadata:"; echo "  name: $name"; echo "stringData:"; echo "  $key_field: |"; sed 's/^/    /' "$src"; echo "sops:"; echo "  age:"; echo "    - recipient: $AGE_RECIP"; echo "      enc: PLACEHOLDER"; echo "  encrypted_regex: '^(stringData)$'"; echo "  version: 3.8.0"; } > "$tmp"; mv "$tmp" "$yaml"; echo "Encrypting $yaml"; sops --encrypt --age "$AGE_RECIP" --in-place "$yaml"; }

   mkdir -p "$SOPS_DIR"
encrypt_file ssh-id_rsa "$SSH_DIR/id_rsa" "$SOPS_DIR/id_rsa.sops.yaml"
encrypt_file ssh-id_ed25519 "$SSH_DIR/id_ed25519" "$SOPS_DIR/id_ed25519.sops.yaml"
encrypt_file ssh-cuong_rsa "$SSH_DIR/cuong_rsa" "$SOPS_DIR/cuong_rsa.sops.yaml"
encrypt_file ssh-id_minhnhat97kg "$SSH_DIR/id_minhnhat97kg" "$SOPS_DIR/id_minhnhat97kg.sops.yaml"
encrypt_file ssh-bitbucket "$SSH_DIR/bitbucket-ssh" "$SOPS_DIR/bitbucket-ssh.sops.yaml"
encrypt_file ssh-config "$SSH_DIR/config" "$SOPS_DIR/config.sops.yaml" key
echo "Done. Review encrypted YAML and commit."
