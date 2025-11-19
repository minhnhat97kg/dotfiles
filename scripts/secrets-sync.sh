#!/usr/bin/env bash
# scripts/secrets-sync.sh
# Generic secrets sync - encrypts all files in specified directories to sops format
# Usage: ./scripts/secrets-sync.sh [source_dir1] [source_dir2] ...
# If no directories specified, uses SECRETS_SOURCE_DIRS env var (comma-separated)

set -euo pipefail

AGE_RECIP="${AGE_RECIPIENT:-age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${SECRETS_OUTPUT_DIR:-$ROOT_DIR/secrets/encrypted}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

need_cmd() {
  command -v "$1" >/dev/null || { log_error "Missing required command: $1"; exit 1; }
}

indent() { sed 's/^/    /'; }

# Build YAML structure for sops
build_yaml() {
  local name="$1" field="$2" content_file="$3"
  echo "kind: Secret"
  echo "metadata:"
  echo "  name: $name"
  echo "stringData:"
  echo "  $field: |"
  indent < "$content_file"
}

# Encrypt file in place with sops
encrypt_in_place() {
  local file="$1"
  if grep -q '^sops:' "$file" 2>/dev/null; then
    # Already encrypted, re-encrypt
    sops --decrypt "$file" >/dev/null 2>&1 || true
    sops --in-place "$file"
  else
    sops --encrypt --age "$AGE_RECIP" --in-place "$file"
  fi
}

# Derive secret name from file path
# e.g., ~/.ssh/id_rsa -> ssh-id_rsa
#       ~/secrets/aws-config -> aws-config
derive_secret_name() {
  local file_path="$1"
  local dir_name file_name

  dir_name="$(basename "$(dirname "$file_path")")"
  file_name="$(basename "$file_path")"

  # Remove common extensions
  file_name="${file_name%.enc}"
  file_name="${file_name%.secret}"
  file_name="${file_name%.txt}"

  # Special handling for known directories
  case "$dir_name" in
    .ssh|ssh)
      echo "ssh-${file_name}"
      ;;
    .aws|aws)
      echo "aws-${file_name}"
      ;;
    git|.git|.config)
      echo "git-${file_name}"
      ;;
    *)
      # Use directory prefix if not home or generic
      if [[ "$dir_name" == "$(basename "$HOME")" ]] || [[ "$dir_name" == "secrets" ]]; then
        echo "$file_name"
      else
        echo "${dir_name}-${file_name}"
      fi
      ;;
  esac
}

# Process a single file
process_file() {
  local src_file="$1"
  local output_subdir="${2:-}"

  [[ -f "$src_file" ]] || { log_warn "Skip $src_file (not a file)"; return; }

  # Skip already encrypted sops files
  [[ "$src_file" == *.sops.yaml ]] && { log_warn "Skip $src_file (already sops format)"; return; }

  # Skip public keys, already encrypted files, and known non-secret files
  local basename_file
  basename_file="$(basename "$src_file")"
  case "$basename_file" in
    *.pub|*.enc|known_hosts|authorized_keys|README*|*.md)
      log_warn "Skip $src_file (not a secret or already encrypted)"
      return
      ;;
  esac

  local secret_name
  secret_name="$(derive_secret_name "$src_file")"

  # Determine output path
  local out_dir="$OUTPUT_DIR"
  [[ -n "$output_subdir" ]] && out_dir="$OUTPUT_DIR/$output_subdir"
  mkdir -p "$out_dir"

  local out_file="$out_dir/${basename_file}.sops.yaml"

  # Build and encrypt
  build_yaml "$secret_name" "key" "$src_file" > "$out_file"
  encrypt_in_place "$out_file"

  log_info "Synced: $src_file -> $out_file"
}

# Process all files in a directory
process_directory() {
  local src_dir="$1"

  [[ -d "$src_dir" ]] || { log_warn "Skip $src_dir (not a directory)"; return; }

  # Derive subdirectory name for output
  local subdir_name
  subdir_name="$(basename "$src_dir")"

  # Normalize common directory names
  case "$subdir_name" in
    .ssh) subdir_name="ssh" ;;
    .aws) subdir_name="aws" ;;
    .gnupg) subdir_name="gnupg" ;;
  esac

  log_info "Processing directory: $src_dir -> $OUTPUT_DIR/$subdir_name"

  # Process all regular files (not directories, not hidden by default)
  shopt -s nullglob
  for file in "$src_dir"/*; do
    [[ -f "$file" ]] && process_file "$file" "$subdir_name"
  done
  shopt -u nullglob
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [DIRECTORY...]

Encrypt secrets from source directories to sops-nix format.

Arguments:
  DIRECTORY...    Source directories containing secrets to encrypt

Options:
  -h, --help      Show this help message
  -o, --output    Output directory (default: \$ROOT/secrets/encrypted)
  -r, --recipient Age recipient public key

Environment Variables:
  SECRETS_SOURCE_DIRS   Comma-separated list of source directories
  SECRETS_OUTPUT_DIR    Output directory for encrypted files
  AGE_RECIPIENT         Age public key for encryption

Examples:
  # Encrypt SSH keys
  $(basename "$0") ~/.ssh

  # Encrypt multiple directories
  $(basename "$0") ~/.ssh ~/.aws ~/secrets/git

  # Using environment variable
  SECRETS_SOURCE_DIRS=~/.ssh,~/.aws $(basename "$0")

  # Custom output directory
  $(basename "$0") -o ./my-secrets ~/.ssh
EOF
}

main() {
  need_cmd sops

  local source_dirs=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -o|--output)
        OUTPUT_DIR="$2"
        shift 2
        ;;
      -r|--recipient)
        AGE_RECIP="$2"
        shift 2
        ;;
      -*)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        # Expand ~ in paths
        local expanded_path="${1/#\~/$HOME}"
        source_dirs+=("$expanded_path")
        shift
        ;;
    esac
  done

  # If no directories provided, check environment variable
  if [[ ${#source_dirs[@]} -eq 0 ]]; then
    if [[ -n "${SECRETS_SOURCE_DIRS:-}" ]]; then
      IFS=',' read -r -a source_dirs <<< "$SECRETS_SOURCE_DIRS"
      # Expand ~ in each path
      for i in "${!source_dirs[@]}"; do
        source_dirs[$i]="${source_dirs[$i]/#\~/$HOME}"
      done
    else
      log_error "No source directories specified"
      usage
      exit 1
    fi
  fi

  mkdir -p "$OUTPUT_DIR"

  log_info "Output directory: $OUTPUT_DIR"
  log_info "Age recipient: $AGE_RECIP"
  echo ""

  # Process each directory
  for dir in "${source_dirs[@]}"; do
    process_directory "$dir"
  done

  echo ""
  log_info "Done! Encrypted files are in: $OUTPUT_DIR"
  log_info "Remember to commit only the *.sops.yaml files"
}

main "$@"
