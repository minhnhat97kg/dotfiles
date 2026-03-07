#!/usr/bin/env bash
# scripts/secrets-edit.sh
# Interactively enter or update a secret value and encrypt it with sops/age.
# Usage: ./scripts/secrets-edit.sh [--config CONFIG_FILE]

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$ROOT_DIR/secrets/config.yaml}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

need_cmd() {
  command -v "$1" >/dev/null || { log_error "Missing required command: $1"; exit 1; }
}

get_yq_cmd() {
  if command -v yq-go &>/dev/null; then echo "yq-go"
  elif command -v yq &>/dev/null; then echo "yq"
  else log_error "yq not found. Install yq-go or yq."; exit 1
  fi
}

expand_path() { echo "${1/#\~/$HOME}"; }

# List all folder/file combos from config
list_secrets() {
  local YQ_CMD="$1"
  local folder_count
  folder_count=$($YQ_CMD eval '.folders | length' "$CONFIG_FILE")

  echo ""
  echo -e "${CYAN}Available secrets:${NC}"
  echo ""

  local idx=0
  for ((i=0; i<folder_count; i++)); do
    local folder_name files_count
    folder_name=$($YQ_CMD eval ".folders[$i].name" "$CONFIG_FILE")
    files_count=$($YQ_CMD eval ".folders[$i].files | length" "$CONFIG_FILE")

    for ((j=0; j<files_count; j++)); do
      local file_name
      file_name=$($YQ_CMD eval ".folders[$i].files[$j]" "$CONFIG_FILE")
      printf "  %2d) %s/%s\n" "$idx" "$folder_name" "$file_name"
      idx=$((idx + 1))
    done
  done

  echo ""
  echo -e "  ${YELLOW}n) Enter a custom folder/file name${NC}"
  echo ""
}

# Build parallel arrays of folder_name and file_name
build_index() {
  local YQ_CMD="$1"
  local folder_count
  folder_count=$($YQ_CMD eval '.folders | length' "$CONFIG_FILE")

  FOLDER_NAMES=()
  FILE_NAMES=()
  DESTINATIONS=()
  PERMISSIONS=()

  for ((i=0; i<folder_count; i++)); do
    local folder_name dest perm files_count
    folder_name=$($YQ_CMD eval ".folders[$i].name" "$CONFIG_FILE")
    dest=$($YQ_CMD eval ".folders[$i].destination" "$CONFIG_FILE")
    perm=$($YQ_CMD eval ".folders[$i].permissions" "$CONFIG_FILE")
    [[ "$perm" == "null" ]] && perm="600"
    files_count=$($YQ_CMD eval ".folders[$i].files | length" "$CONFIG_FILE")

    for ((j=0; j<files_count; j++)); do
      local file_name
      file_name=$($YQ_CMD eval ".folders[$i].files[$j]" "$CONFIG_FILE")
      FOLDER_NAMES+=("$folder_name")
      FILE_NAMES+=("$file_name")
      DESTINATIONS+=("$dest")
      PERMISSIONS+=("$perm")
    done
  done
}

# Read multiline input until user types a terminator on its own line
read_secret_value() {
  local secret_name="$1"
  echo ""
  echo -e "${YELLOW}Enter value for ${CYAN}${secret_name}${NC}"
  echo -e "${YELLOW}(Paste content, then press Enter and type ${CYAN}EOF${YELLOW} on a new line to finish):${NC}"
  echo ""

  local lines=()
  while IFS= read -r line; do
    [[ "$line" == "EOF" ]] && break
    lines+=("$line")
  done

  # Join with newlines
  local value
  value="$(printf '%s\n' "${lines[@]}")"
  echo "$value"
}

# Encrypt a value string into the sops yaml file
encrypt_value() {
  local folder_name="$1"
  local file_name="$2"
  local value="$3"
  local age_recip="$4"
  local output_base="$5"

  local out_dir="$output_base/$folder_name"
  mkdir -p "$out_dir"

  local out_file="$out_dir/${file_name}.sops.yaml"
  local secret_name="${folder_name}-${file_name}"
  local tmp_file="${out_file}.tmp"

  # Write plain YAML structure
  {
    echo "kind: Secret"
    echo "metadata:"
    echo "  name: $secret_name"
    echo "stringData:"
    echo "  key: |"
    echo "$value" | sed 's/^/    /'
  } > "$tmp_file"

  # Encrypt with sops
  if [[ -f "$out_file" ]] && grep -q '^sops:' "$out_file" 2>/dev/null; then
    log_warn "Existing encrypted file found — overwriting."
  fi

  SOPS_AGE_RECIPIENTS="$age_recip" sops --encrypt --age "$age_recip" "$tmp_file" > "$out_file"
  rm -f "$tmp_file"

  log_info "Encrypted → $out_file"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Interactively enter or update a secret value and encrypt it.

Options:
  -h, --help           Show this help message
  -c, --config FILE    Path to config file (default: secrets/config.yaml)

Examples:
  $(basename "$0")
  $(basename "$0") --config /path/to/config.yaml
EOF
}

main() {
  need_cmd sops

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      -c|--config) CONFIG_FILE="$2"; shift 2 ;;
      *) log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Config file not found: $CONFIG_FILE"
    exit 1
  fi

  local YQ_CMD
  YQ_CMD="$(get_yq_cmd)"

  local age_recip output_base
  age_recip=$($YQ_CMD eval '.age.recipient' "$CONFIG_FILE")
  output_base=$($YQ_CMD eval '.output_dir' "$CONFIG_FILE")
  output_base="$(expand_path "$output_base")"
  [[ "$output_base" != /* ]] && output_base="$ROOT_DIR/$output_base"

  # Build index arrays
  declare -a FOLDER_NAMES FILE_NAMES DESTINATIONS PERMISSIONS
  build_index "$YQ_CMD"

  # Show menu
  list_secrets "$YQ_CMD"

  local choice
  read -r -p "Select secret number (or 'n' for custom): " choice
  echo ""

  local folder_name file_name

  if [[ "$choice" == "n" || "$choice" == "N" ]]; then
    read -r -p "Folder name (e.g. ssh, aws): " folder_name
    read -r -p "File name (e.g. id_rsa, credentials): " file_name
  elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -lt "${#FOLDER_NAMES[@]}" ]]; then
    folder_name="${FOLDER_NAMES[$choice]}"
    file_name="${FILE_NAMES[$choice]}"
  else
    log_error "Invalid selection."
    exit 1
  fi

  echo -e "Selected: ${CYAN}${folder_name}/${file_name}${NC}"

  # Read secret value from user
  local value
  value="$(read_secret_value "${folder_name}/${file_name}")"

  if [[ -z "$value" ]]; then
    log_error "Empty value — aborting."
    exit 1
  fi

  encrypt_value "$folder_name" "$file_name" "$value" "$age_recip" "$output_base"

  echo ""
  log_info "Done! Commit the updated file in secrets/encrypted/${folder_name}/${file_name}.sops.yaml"
}

main "$@"
