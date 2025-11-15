# Secrets Management (Config-Driven)

All secrets are managed via a simple YAML configuration file (`secrets.yaml`). Just define what to encrypt/decrypt and let the scripts handle it.

## Quick Start

### Add a New Secret

1. **Edit `secrets.yaml`:**
   ```yaml
   secrets:
     - name: my-secret-key
       source: ~/.myapp/secret.key
       encrypted: secrets/myapp/secret.key.enc
       mode: "600"
       encrypt: true
   ```

2. **Encrypt it:**
   ```bash
   make encrypt-all
   ```

3. **Commit the encrypted file:**
   ```bash
   git add secrets/myapp/secret.key.enc
   git commit -m "Add my secret key"
   ```

### Use on New Machine

1. **Copy age key:**
   ```bash
   mkdir -p ~/.config/sops/age
   # Copy keys.txt to ~/.config/sops/age/keys.txt
   ```

2. **Decrypt everything:**
   ```bash
   make decrypt-all
   # All secrets restored to their original locations!
   ```

## Configuration File

**Location:** `secrets.yaml` (in repo root)

**Format:**
```yaml
secrets:
  - name: unique-name           # Descriptive name
    source: ~/path/to/file      # Where the file lives
    encrypted: secrets/file.enc # Where to store encrypted version
    mode: "600"                 # File permissions (chmod)
    encrypt: true              # true = encrypt, false = just copy

age:
  public_key: age1...          # Age public key for encryption
  private_key: ~/.config/sops/age/keys.txt  # Age private key path
```

## Commands

```bash
# Decrypt all secrets
make decrypt-all

# Encrypt all secrets
make encrypt-all

# Test without changing your system
make test-decrypt

# Apply config and decrypt
make switch
```

## Current Secrets

All secrets defined in `secrets.yaml`:

### AWS Configuration

**Files:**
- **aws-config** - AWS CLI configuration (SSO URLs, regions) - **NOT encrypted** (no secrets)
- **aws-credentials** - AWS credentials with access keys - **ENCRYPTED**

**SSO Profiles (Recommended):**
Uses temporary tokens, no static keys stored:
- `buuuk-dev`, `buuuk-test`, `bi-dev` - Buuuk organization
- `jpas-uat-admin`, `jpas-sit-admin` - JPAS admin access
- `jpas-uat-dev`, `jpas-sit-dev` - JPAS developer access
- `jpas-uat-devops`, `jpas-sit-devops` - JPAS DevOps access

**Static Key Profiles:**
Encrypted in `aws-credentials`:
- `fl-dev`, `fl-prod` - First Luxury environments
- `fl-up-deploy`, `fl-up-deploy-2` - Deployment keys
- `first-luxury-dev` - Development account
- `mfa` - MFA configuration

**Usage:**
```bash
# SSO profiles - login first
aws sso login --profile buuuk-dev
aws s3 ls --profile buuuk-dev

# Static key profiles - work immediately
aws s3 ls --profile fl-dev
aws ec2 describe-instances --profile fl-prod
```

**Login URLs:**
- Buuuk: https://buuuk-dev.awsapps.com/start
- JPAS: https://d-9667464356.awsapps.com/start

### SSH Keys
- **ssh-id_rsa** - Main RSA key (encrypted)
- **ssh-id_ed25519** - Ed25519 key (encrypted)
- **ssh-cuong_rsa** - Cuong's RSA key (encrypted)
- **ssh-id_minhnhat97kg** - GitHub key (encrypted)
- **ssh-bitbucket** - Bitbucket key (encrypted)
- **ssh-config** - SSH config file (encrypted)

## How It Works

1. **Encryption** (`make encrypt-all`):
   - Reads `secrets.yaml`
   - For each secret with `encrypt: true`:
     - Reads file from `source`
     - Encrypts with age
     - Saves to `encrypted` location
   - For secrets with `encrypt: false`:
     - Just copies the file

2. **Decryption** (`make decrypt-all`):
   - Reads `secrets.yaml`
   - For each secret:
     - Reads encrypted file
     - Decrypts (if needed)
     - Writes to `source` location
     - Sets file permissions from `mode`

## Adding New Secrets

To add a new secret (example: GPG key):

1. **Add to `secrets.yaml`:**
   ```yaml
   - name: gpg-private-key
     source: ~/.gnupg/private-keys-v1.d/KEYID.key
     encrypted: secrets/gpg/private.key.enc
     mode: "600"
     encrypt: true
   ```

2. **Encrypt:**
   ```bash
   make encrypt-all
   ```

3. **Commit:**
   ```bash
   git add secrets.yaml secrets/gpg/private.key.enc
   git commit -m "Add GPG private key"
   ```

That's it! The next `make decrypt-all` will restore it.

## Security

✅ **Safe to commit:**
- `secrets.yaml` (configuration only)
- All `*.enc` files (encrypted)
- Files with `encrypt: false` that contain no secrets

❌ **NEVER commit:**
- `~/.config/sops/age/keys.txt` (encryption key)
- Any decrypted secrets

## Age Encryption Key

**Location:** `~/.config/sops/age/keys.txt`
**Public Key:** `age1h7y2etdv5r0nclaaavral84gcdd2kvvcu2h8yes3e3k3fcp03fzq306yas`

⚠️ **BACKUP THIS KEY!** Store it in:
- Password manager
- Encrypted USB drive
- Secure cloud storage
- Printed paper in safe

Without this key, you cannot decrypt your secrets!
