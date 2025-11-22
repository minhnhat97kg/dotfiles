# Secrets Management

Configuration-driven secret encryption and decryption using SOPS and age.

## Overview

Secrets are managed through a YAML configuration file that defines:
- Which folders contain secrets
- Which files to encrypt/decrypt
- Where to store encrypted versions
- File permissions after decryption

## Quick Start

### First Time Setup

1. **Ensure age key exists:**
   ```bash
   mkdir -p ~/.config/sops/age
   # Copy your age key to ~/.config/sops/age/keys.txt
   ```

2. **Configure secrets:**
   Edit `secrets/config.yaml` to define your secret folders and files.

3. **Encrypt secrets:**
   ```bash
   make encrypt
   ```

4. **Commit encrypted files:**
   ```bash
   git add secrets/encrypted/
   git commit -m "Add encrypted secrets"
   ```

### On New Machine

1. **Copy age key:**
   ```bash
   mkdir -p ~/.config/sops/age
   # Copy keys.txt to ~/.config/sops/age/keys.txt
   ```

2. **Run nix-darwin switch:**
   ```bash
   make switch
   # or
   darwin-rebuild switch --flake .
   ```

   You will be prompted to decrypt secrets automatically!

3. **Or decrypt manually:**
   ```bash
   make decrypt
   ```

## Configuration File

**Location:** `secrets/config.yaml`

**Structure:**
```yaml
# Age encryption configuration
age:
  recipient: age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas
  key_file: ~/.config/sops/age/keys.txt

# Output directory for encrypted secrets
output_dir: ./secrets/encrypted

# Define folders and files to encrypt/decrypt
folders:
  - name: ssh
    source: ~/.ssh
    destination: ~/.ssh
    files:
      - id_rsa
      - id_ed25519
      - passwords.yaml
      - tunnels.yaml
    permissions: "600"

  - name: aws
    source: ~/.aws
    destination: ~/.aws
    files:
      - credentials
      - config
    permissions: "600"

  - name: git
    source: ./secrets/git
    destination: ./secrets/git
    files:
      - buuuk.gitconfig
    permissions: "644"
```

**Fields:**
- `name`: Folder identifier (used for organizing encrypted files)
- `source`: Where to read files from when encrypting
- `destination`: Where to write files when decrypting
- `files`: List of files to process
- `permissions`: chmod permissions (e.g., "600", "644")

## Commands

### Encryption
```bash
# Encrypt all secrets defined in config
make encrypt

# Use custom config file
make encrypt-custom CONFIG=/path/to/config.yaml
```

### Decryption
```bash
# Decrypt with confirmation prompt
make decrypt

# Decrypt without prompt (auto-yes)
make decrypt-yes

# Use custom config file
make decrypt-custom CONFIG=/path/to/config.yaml
```

### Scripts

You can also run the scripts directly:

```bash
# Encrypt
./scripts/secrets-sync.sh
./scripts/secrets-sync.sh --config /path/to/config.yaml

# Decrypt
./scripts/secrets-decrypt.sh
./scripts/secrets-decrypt.sh --yes  # skip confirmation
./scripts/secrets-decrypt.sh --config /path/to/config.yaml
```

## Automatic Decryption

When you run `darwin-rebuild switch` or `nix-on-droid switch`, the system will automatically:

1. Show a prompt asking if you want to decrypt secrets
2. If you answer "yes", decrypt all secrets to their destinations
3. Set proper file permissions
4. Report success/failure

This happens through activation scripts:
- **macOS**: `scripts/activate-decrypt-secrets.sh` (called from `modules/darwin.nix`)
- **Android**: `scripts/activate-decrypt-secrets-android.sh` (called from `modules/android.nix`)

## How It Works

### Encryption Flow

1. Read `secrets/config.yaml`
2. For each folder:
   - For each file in the folder's file list:
     - Read from `source/filename`
     - Wrap in SOPS YAML structure
     - Encrypt with age
     - Save to `output_dir/folder_name/filename.sops.yaml`

### Decryption Flow

1. Read `secrets/config.yaml`
2. For each folder:
   - For each file in the folder's file list:
     - Read from `output_dir/folder_name/filename.sops.yaml`
     - Decrypt using age key
     - Extract file content
     - Write to `destination/filename`
     - Set permissions

### File Structure

```
secrets/
├── config.yaml              # Configuration file
├── encrypted/               # Encrypted secrets (git-tracked)
│   ├── ssh/
│   │   ├── id_rsa.sops.yaml
│   │   ├── id_ed25519.sops.yaml
│   │   ├── passwords.yaml.sops.yaml
│   │   └── tunnels.yaml.sops.yaml
│   ├── aws/
│   │   ├── credentials.sops.yaml
│   │   └── config.sops.yaml
│   └── git/
│       └── buuuk.gitconfig.sops.yaml
└── git/                     # Plain git configs (source)
    └── buuuk.gitconfig
```

## Adding New Secrets

1. **Edit `secrets/config.yaml`:**
   ```yaml
   folders:
     - name: gpg
       source: ~/.gnupg
       destination: ~/.gnupg
       files:
         - private-key.asc
       permissions: "600"
   ```

2. **Encrypt:**
   ```bash
   make encrypt
   ```

3. **Commit:**
   ```bash
   git add secrets/config.yaml secrets/encrypted/gpg/
   git commit -m "Add GPG private key"
   ```

## Security

### Safe to Commit
- `secrets/config.yaml` (no secrets, just paths)
- `secrets/encrypted/**/*.sops.yaml` (encrypted files)
- Any source files in `secrets/` that don't contain actual secrets

### NEVER Commit
- `~/.config/sops/age/keys.txt` (your private age key)
- Any decrypted secrets
- Files in destination directories after decryption

### Age Key Management

**Location:** `~/.config/sops/age/keys.txt`
**Public Key:** `age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas`

⚠️ **BACKUP THIS KEY!** Store it in:
- Password manager (1Password, Bitwarden, etc.)
- Encrypted USB drive
- Secure cloud storage (encrypted)
- Printed paper in a safe

Without this key, you cannot decrypt your secrets!

## Current Secrets

Based on the current `config.yaml`:

### SSH Keys & Configs
- `id_rsa` - Main RSA key
- `id_ed25519` - Ed25519 key
- `passwords.yaml` - Server passwords (see SSH-PASSWORDS.md)
- `tunnels.yaml` - SSH tunnel configurations

### AWS Credentials
- `credentials` - AWS access keys and tokens
- `config` - AWS CLI configuration (profiles, regions, SSO)

### Git Configurations
- `buuuk.gitconfig` - Buuuk-specific git configuration

## Troubleshooting

### "Age key file not found"
Ensure `~/.config/sops/age/keys.txt` exists and contains your private key.

### "Failed to decrypt"
- Check that your age key matches the recipient in `config.yaml`
- Verify encrypted files are not corrupted
- Ensure SOPS is installed: `nix profile install nixpkgs#sops`

### "yq not found"
Install yq: `make deps` or `nix profile install nixpkgs#yq-go`

### Decryption not running automatically
Check that `modules/darwin.nix` contains the activation script and rebuild:
```bash
darwin-rebuild switch --flake .
```
