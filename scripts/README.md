# Scripts Directory

Utility scripts for dotfiles management and system automation.

## Secrets Management

### `secrets-sync.sh`
Encrypt secrets based on configuration file.

**Usage:**
```bash
./scripts/secrets-sync.sh                    # Use default config
./scripts/secrets-sync.sh -c custom.yaml     # Use custom config
```

**What it does:**
- Reads `secrets/config.yaml`
- Encrypts files using SOPS and age
- Saves encrypted files to `secrets/encrypted/`

### `secrets-decrypt.sh`
Decrypt secrets to their destinations.

**Usage:**
```bash
./scripts/secrets-decrypt.sh                 # With confirmation prompt
./scripts/secrets-decrypt.sh --yes           # Auto-confirm
./scripts/secrets-decrypt.sh -c custom.yaml  # Use custom config
```

**What it does:**
- Reads `secrets/config.yaml`
- Decrypts files using age key
- Restores files to destination paths
- Sets proper permissions

### `activate-decrypt-secrets.sh`
Activation script for macOS during `darwin-rebuild switch`.

**Usage:**
```bash
./scripts/activate-decrypt-secrets.sh [DOTFILES_DIR] [USERNAME]
```

**What it does:**
1. Checks if age key exists at `~/.config/sops/age/keys.txt`
2. If missing, prompts user to paste age private key
3. Validates age key format
4. Runs `secrets-decrypt.sh` with user confirmation
5. Reports success/failure

**Called by:** `modules/darwin.nix` (system.activationScripts.extraActivation)

### `activate-decrypt-secrets-android.sh`
Activation script for Android during `nix-on-droid switch`.

**Usage:**
```bash
./scripts/activate-decrypt-secrets-android.sh [DOTFILES_DIR]
```

**What it does:**
Same as macOS version but adapted for Android environment:
- No sudo required (single user)
- Default dotfiles location: `~/dotfiles`
- Age key at `~/.config/sops/age/keys.txt`

**Called by:** `modules/android.nix` (build.activation.secrets)

## SSH Password Management

### `ssh-with-password.sh`
SSH with password lookup from encrypted YAML file.

**Usage:**
```bash
ssh-with-password [user@]host
sshp [user@]host                    # Using alias
```

**Requirements:**
- Passwords file: `~/.ssh/passwords.yaml` (decrypted from secrets)
- `sshpass` package

**Example passwords.yaml:**
```yaml
servers:
  - name: prod-server
    host: 192.168.1.100
    user: admin
    password: secret123
```

### `ssh-password-add.sh`
Add new SSH password entry.

**Usage:**
```bash
ssh-password-add
sshp-add                            # Using alias
```

**Interactive prompts for:**
- Server name
- Hostname/IP
- Username
- Password (hidden input)

### `ssh-password-list.sh`
List all saved SSH password entries.

**Usage:**
```bash
ssh-password-list
sshp-list                           # Using alias
```

### `ssh-tunnel.sh`
Create SSH tunnel with password from YAML.

**Usage:**
```bash
ssh-tunnel [name]
sshp-tunnel [name]                  # Using alias
```

**Requirements:**
- Tunnels file: `~/.ssh/tunnels.yaml` (decrypted from secrets)

**Example tunnels.yaml:**
```yaml
tunnels:
  - name: db-tunnel
    host: jump-server.com
    user: tunneluser
    password: secret
    local_port: 5432
    remote_host: db.internal
    remote_port: 5432
```

## Window Manager

### `whichkey-fzf.sh`
Display keybindings in fzf picker.

**Usage:**
```bash
./scripts/whichkey-fzf.sh
# Or press: Alt+Shift+/
```

**What it does:**
- Reads `scripts/whichkey_bindings.txt`
- Shows keybindings in interactive fzf picker
- Allows searching and filtering

### `cycle-layout.sh`
Cycle through yabai window layouts.

**Usage:**
```bash
./scripts/cycle-layout.sh forward
./scripts/cycle-layout.sh backward
./scripts/cycle-layout.sh current     # Show current layout
```

**Layouts:**
- bsp → vertical → horizontal → master-stack → stack → float

### `window-picker.sh`
Interactive window picker using fzf.

**Usage:**
```bash
./scripts/window-picker.sh
# Or press: Alt+Shift+w
```

## Shell Integration

### `load-aliases.sh`
Load dynamic shell aliases from git configs.

**Usage:**
```bash
eval "$(./scripts/load-aliases.sh)"
```

**Called by:** `~/.zshrc` (configured in `modules/shared.nix`)

**What it does:**
- Scans git configs for [alias] sections
- Generates shell aliases dynamically
- Provides git shortcuts

## Script Organization

```
scripts/
├── README.md                              # This file
│
├── Secrets Management
│   ├── secrets-sync.sh                    # Encrypt secrets
│   ├── secrets-decrypt.sh                 # Decrypt secrets
│   ├── activate-decrypt-secrets.sh        # macOS activation
│   └── activate-decrypt-secrets-android.sh # Android activation
│
├── SSH Utilities
│   ├── ssh-with-password.sh               # SSH with password lookup
│   ├── ssh-password-add.sh                # Add password entry
│   ├── ssh-password-list.sh               # List entries
│   └── ssh-tunnel.sh                      # Create SSH tunnel
│
├── Window Manager (macOS)
│   ├── whichkey-fzf.sh                    # Keybinding picker
│   ├── cycle-layout.sh                    # Cycle layouts
│   └── window-picker.sh                   # Window picker
│
└── Shell Integration
    ├── load-aliases.sh                    # Dynamic alias loading
    └── whichkey_bindings.txt              # Keybinding definitions
```

## Adding New Scripts

1. Create script in `scripts/` directory
2. Make it executable: `chmod +x scripts/your-script.sh`
3. Add shebang: `#!/usr/bin/env bash`
4. Use `set -euo pipefail` for safety
5. Document in this README
6. If needed, add to PATH via nix config

## Installation

Scripts are automatically installed via nix home-manager:
- **Location**: `~/.scripts/` (symlinked)
- **PATH**: Some scripts available in `~/.local/bin/`
- **Configuration**: `modules/shared.nix`

No manual installation needed when using nix-darwin or nix-on-droid!
