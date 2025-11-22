#!/usr/bin/env bash
# scripts/secrets-decrypt.sh
# Decrypt secrets based on configuration file
# Usage: ./scripts/secrets-decrypt.sh [--config CONFIG_FILE] [--yes]

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

# Decrypt a single file
decrypt_file() {
  local encrypted_file="$1"
  local dest_file="$2"
  local age_key_file="$3"
  local permissions="$4"

  if [[ ! -f "$encrypted_file" ]]; then
    log_warn "Encrypted file not found: $encrypted_file"
    return 1
  fi

  # Create destination directory if needed
  local dest_dir
  dest_dir="$(dirname "$dest_file")"
  mkdir -p "$dest_dir"

  # Decrypt the file
  local temp_file="${dest_file}.tmp"
  local error_file="${dest_file}.err"

  # Try Kubernetes Secret format first (with stringData.key)
  if SOPS_AGE_KEY_FILE="$age_key_file" sops --decrypt --extract '["stringData"]["key"]' "$encrypted_file" > "$temp_file" 2> "$error_file"; then
    mv "$temp_file" "$dest_file"
    rm -f "$error_file"
    chmod "$permissions" "$dest_file"
    log_info "Decrypted: $(basename "$encrypted_file") → $dest_file"
    return 0
  fi

  # If that failed with "component not found", try plain YAML format
  if grep -q "component.*not found" "$error_file" 2>/dev/null; then
    rm -f "$error_file"
    if SOPS_AGE_KEY_FILE="$age_key_file" sops --decrypt "$encrypted_file" > "$temp_file" 2> "$error_file"; then
      mv "$temp_file" "$dest_file"
      rm -f "$error_file"
      chmod "$permissions" "$dest_file"
      log_info "Decrypted: $(basename "$encrypted_file") → $dest_file"
      return 0
    fi
  fi

  # Both attempts failed
  log_error "Failed to decrypt: $encrypted_file"
  if [[ -f "$error_file" ]] && [[ -s "$error_file" ]]; then
    log_error "Error details:"
    cat "$error_file" >&2
  fi
  rm -f "$temp_file" "$error_file" "$dest_file"
  return 1
}

# Prompt user for confirmation
prompt_confirmation() {
  local auto_yes="$1"

  if [[ "$auto_yes" == "true" ]]; then
    return 0
  fi

  echo ""
  echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
  echo -e "${YELLOW}  Secret Decryption${NC}"
  echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
  echo ""
  echo "This will decrypt secrets and place them in your filesystem."
  echo "Existing files will be overwritten."
  echo ""
  read -r -p "Do you want to proceed? [y/N] " response
  echo ""

  case "$response" in
    [yY][eE][sS]|[yY])
      return 0
      ;;
    *)
      log_info "Decryption cancelled"
      return 1
      ;;
  esac
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Decrypt secrets based on configuration file.

Options:
  -h, --help           Show this help message
  -c, --config FILE    Path to config file (default: secrets/config.yaml)
  -y, --yes            Skip confirmation prompt
  -v, --verbose        Enable verbose output

Environment Variables:
  CONFIG_FILE          Path to configuration file

Examples:
  # Decrypt with confirmation prompt
  $(basename "$0")

  # Decrypt without confirmation
  $(basename "$0") --yes

  # Use custom config
  $(basename "$0") --config /path/to/config.yaml
EOF
}

main() {
  need_cmd sops

  local YQ_CMD
  YQ_CMD="$(get_yq_cmd)"
  local auto_yes=false
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
      -y|--yes)
        auto_yes=true
        shift
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

  # Check config file exists BEFORE prompting user
  if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Config file not found: $CONFIG_FILE"
    log_error "Expected location: $CONFIG_FILE"
    exit 1
  fi

  # Prompt for confirmation
  if ! prompt_confirmation "$auto_yes"; then
    exit 0
  fi

  log_info "Using config: $CONFIG_FILE"

  # Read configuration
  local age_key_file
  age_key_file=$($YQ_CMD eval '.age.key_file' "$CONFIG_FILE")
  age_key_file="$(expand_path "$age_key_file")"

  if [[ ! -f "$age_key_file" ]]; then
    log_error "Age key file not found: $age_key_file"
    log_error "Please ensure your age key is set up at this location"
    exit 1
  fi

  local output_base
  output_base=$($YQ_CMD eval '.output_dir' "$CONFIG_FILE")
  output_base="$(expand_path "$output_base")"

  # Make output_base absolute if it's relative
  if [[ "$output_base" != /* ]]; then
    output_base="$ROOT_DIR/$output_base"
  fi

  if [[ ! -d "$output_base" ]]; then
    log_error "Encrypted secrets directory not found: $output_base"
    log_error "Please run secrets-sync.sh first to encrypt your secrets"
    exit 1
  fi

  log_info "Age key file: $age_key_file"
  log_info "Encrypted secrets: $output_base"
  echo ""

  # Get number of folders
  local folder_count
  folder_count=$($YQ_CMD eval '.folders | length' "$CONFIG_FILE")

  local total_files=0
  local success_count=0
  local failed_count=0

  # Process each folder
  for ((i=0; i<folder_count; i++)); do
    local folder_name dest_dir files_count permissions

    folder_name=$($YQ_CMD eval ".folders[$i].name" "$CONFIG_FILE")
    dest_dir=$($YQ_CMD eval ".folders[$i].destination" "$CONFIG_FILE")
    dest_dir="$(expand_path "$dest_dir")"

    # Make dest_dir absolute if it's relative
    if [[ "$dest_dir" != /* ]]; then
      dest_dir="$ROOT_DIR/$dest_dir"
    fi

    permissions=$($YQ_CMD eval ".folders[$i].permissions" "$CONFIG_FILE")
    [[ "$permissions" == "null" ]] && permissions="600"

    log_info "Processing folder: $folder_name → $dest_dir"

    # Get files list
    files_count=$($YQ_CMD eval ".folders[$i].files | length" "$CONFIG_FILE")
    log_debug "Files count: $files_count"

    if [[ "$files_count" == "0" ]] || [[ "$files_count" == "null" ]]; then
      log_warn "No files specified for folder: $folder_name"
      continue
    fi

    # Process each file
    for ((j=0; j<files_count; j++)); do
      echo "[DEBUG] Processing file index: $j" >&2
      local file_name
      file_name=$($YQ_CMD eval ".folders[$i].files[$j]" "$CONFIG_FILE")
      echo "[DEBUG] File name: $file_name" >&2

      local encrypted_file="$output_base/$folder_name/${file_name}.sops.yaml"
      local dest_file="$dest_dir/$file_name"

      total_files=$((total_files + 1))

      log_info "Decrypting: $file_name"

      if decrypt_file "$encrypted_file" "$dest_file" "$age_key_file" "$permissions"; then
        success_count=$((success_count + 1))
      else
        failed_count=$((failed_count + 1))
      fi
    done

    echo ""
  done

  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  log_info "Decryption complete!"
  log_info "Total: $total_files | Success: $success_count | Failed: $failed_count"
  echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"

  if [[ $failed_count -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
