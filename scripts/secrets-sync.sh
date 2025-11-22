#!/usr/bin/env bash
# scripts/secrets-sync.sh
# Encrypt secrets based on configuration file
# Usage: ./scripts/secrets-sync.sh [--config CONFIG_FILE]

set -euo pipefail

# Default paths
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$ROOT_DIR/secrets/config.yaml}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${BLUE}[DEBUG]${NC} $1"; }

need_cmd() {
  command -v "$1" >/dev/null || { log_error "Missing required command: $1"; exit 1; }
}

indent() { sed 's/^/    /'; }

# Get yq command (handle both yq-go and yq)
get_yq_cmd() {
  if command -v yq-go &> /dev/null; then
    echo "yq-go"
  elif command -v yq &> /dev/null; then
    echo "yq"
  else
    log_error "yq not found. Please install yq-go or yq"
    exit 1
  fi
}

# Expand tilde in paths
expand_path() {
  local path="$1"
  echo "${path/#\~/$HOME}"
}

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
  local file="$1" age_recip="$2"
  if grep -q '^sops:' "$file" 2>/dev/null; then
    # Already encrypted, re-encrypt
    sops --decrypt "$file" >/dev/null 2>&1 || true
    sops --in-place "$file"
  else
    sops --encrypt --age "$age_recip" --in-place "$file"
  fi
}

# Process a single file
process_file() {
  local src_file="$1"
  local folder_name="$2"
  local output_dir="$3"
  local age_recip="$4"

  if [[ ! -f "$src_file" ]]; then
    log_warn "File not found: $src_file"
    return
  fi

  local basename_file
  basename_file="$(basename "$src_file")"

  # Skip public keys
  if [[ "$basename_file" == *.pub ]]; then
    log_debug "Skipping public key: $basename_file"
    return
  fi

  local out_dir="$output_dir/$folder_name"
  mkdir -p "$out_dir"

  local out_file="$out_dir/${basename_file}.sops.yaml"
  local secret_name="${folder_name}-${basename_file}"

  # Build and encrypt
  build_yaml "$secret_name" "key" "$src_file" > "$out_file"
  encrypt_in_place "$out_file" "$age_recip"

  log_info "Encrypted: $basename_file → $out_file"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Encrypt secrets based on configuration file.

Options:
  -h, --help           Show this help message
  -c, --config FILE    Path to config file (default: secrets/config.yaml)
  -v, --verbose        Enable verbose output

Environment Variables:
  CONFIG_FILE          Path to configuration file

Examples:
  # Encrypt using default config
  $(basename "$0")

  # Use custom config
  $(basename "$0") --config /path/to/config.yaml
EOF
}

main() {
  need_cmd sops

  local YQ_CMD
  YQ_CMD="$(get_yq_cmd)"
  local verbose=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -c|--config)
        CONFIG_FILE="$2"
        shift 2
        ;;
      -v|--verbose)
        verbose=true
        shift
        ;;
      -*)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        log_error "Unexpected argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  # Check config file exists
  if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Config file not found: $CONFIG_FILE"
    exit 1
  fi

  log_info "Using config: $CONFIG_FILE"

  # Read configuration
  local age_recip
  age_recip=$($YQ_CMD eval '.age.recipient' "$CONFIG_FILE")

  local output_base
  output_base=$($YQ_CMD eval '.output_dir' "$CONFIG_FILE")
  output_base="$(expand_path "$output_base")"

  # Make output_base absolute if it's relative
  if [[ "$output_base" != /* ]]; then
    output_base="$ROOT_DIR/$output_base"
  fi

  mkdir -p "$output_base"

  log_info "Age recipient: $age_recip"
  log_info "Output directory: $output_base"
  echo ""

  # Get number of folders
  local folder_count
  folder_count=$($YQ_CMD eval '.folders | length' "$CONFIG_FILE")

  # Process each folder
  for ((i=0; i<folder_count; i++)); do
    local folder_name source_dir files_count

    folder_name=$($YQ_CMD eval ".folders[$i].name" "$CONFIG_FILE")
    source_dir=$($YQ_CMD eval ".folders[$i].source" "$CONFIG_FILE")
    source_dir="$(expand_path "$source_dir")"

    # Make source_dir absolute if it's relative
    if [[ "$source_dir" != /* ]]; then
      source_dir="$ROOT_DIR/$source_dir"
    fi

    log_info "Processing folder: $folder_name (source: $source_dir)"

    if [[ ! -d "$source_dir" ]]; then
      log_warn "Source directory not found: $source_dir"
      continue
    fi

    # Get files list
    files_count=$($YQ_CMD eval ".folders[$i].files | length" "$CONFIG_FILE")

    if [[ "$files_count" == "0" ]] || [[ "$files_count" == "null" ]]; then
      log_warn "No files specified for folder: $folder_name"
      continue
    fi

    # Process each file
    for ((j=0; j<files_count; j++)); do
      local file_name
      file_name=$($YQ_CMD eval ".folders[$i].files[$j]" "$CONFIG_FILE")

      local src_file="$source_dir/$file_name"
      process_file "$src_file" "$folder_name" "$output_base" "$age_recip"
    done

    echo ""
  done

  log_info "Done! Encrypted files are in: $output_base"
  log_info "Remember to commit only the *.sops.yaml files"
}

main "$@"
