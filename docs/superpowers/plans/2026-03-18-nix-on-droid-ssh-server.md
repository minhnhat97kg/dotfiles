# Nix-on-Droid SSH Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure nix-on-droid as an SSH server accessible from Mac via Wi-Fi, USB (adb), and Tailscale, with auto-start on every shell open (PID-guarded) and manual start/stop scripts.

**Architecture:** The `build.activation.sshd` hook (runs on `nix-on-droid switch`) generates host keys, an auto-login client keypair, `sshd_config`, and helper scripts. The `environment.loginShellInit` snippet auto-starts sshd on every shell open using a PID file guard to prevent duplicate processes. The README is updated with a dedicated Android SSH section covering all three connection methods.

**Tech Stack:** nix-on-droid, OpenSSH (`pkgs.openssh`), bash, adb (for USB method), Tailscale Android app (for VPN method)

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `modules/platforms/android.nix` | Modify | Add `build.activation.sshd` + `environment.loginShellInit` |
| `README.md` | Modify | Add Android SSH Server section with connection instructions |

---

### Task 1: Implement `build.activation.sshd` in android.nix

**Files:**
- Modify: `modules/platforms/android.nix`

This activation block runs every time `nix-on-droid switch` is executed. It is idempotent — it only generates keys if they don't exist, but always rewrites `sshd_config` and the helper scripts (so Nix store paths stay current after upgrades).

- [ ] **Step 1: Open `modules/platforms/android.nix`** and locate the closing `}` brace. The file currently ends at line 202. All new SSH content goes between `terminal.font = ...` (line 101) and the final `}`.

- [ ] **Step 2: Replace the existing `build.activation.sshd` block (lines 103-201) with this implementation:**

```nix
  # SSH server setup
  # Runs on every `nix-on-droid switch`. Idempotent: keys are only generated
  # if missing; sshd_config and scripts are always regenerated to keep
  # Nix store paths current after package upgrades.
  build.activation.sshd = ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # ── Host keys (server identity) ──────────────────────────────────────
    if [ ! -f "$HOME/.ssh/ssh_host_ed25519_key" ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 \
        -f "$HOME/.ssh/ssh_host_ed25519_key" -N ""
      echo "Generated SSH host key (ED25519)"
    fi

    # ── Client keypair (auto-login from Mac) ─────────────────────────────
    # This keypair is generated once. The public key goes into authorized_keys
    # on this device. The private key is what you copy to your Mac.
    if [ ! -f "$HOME/.ssh/android_client_key" ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 \
        -f "$HOME/.ssh/android_client_key" -N "" \
        -C "nix-on-droid-auto-client"
      echo "Generated client keypair: $HOME/.ssh/android_client_key"
    fi

    # ── authorized_keys ──────────────────────────────────────────────────
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    CLIENT_PUBKEY=$(cat "$HOME/.ssh/android_client_key.pub")
    if ! grep -qF "$CLIENT_PUBKEY" "$HOME/.ssh/authorized_keys"; then
      echo "$CLIENT_PUBKEY" >> "$HOME/.ssh/authorized_keys"
      echo "Added client public key to authorized_keys"
    fi

    # ── sshd_config ──────────────────────────────────────────────────────
    # Always regenerated so Nix store paths (sftp-server, etc.) stay valid.
    cat > "$HOME/.ssh/sshd_config" << 'SSHD_EOF'
Port 8022
ListenAddress 0.0.0.0
PidFile PLACEHOLDER_HOME/.ssh/sshd.pid
HostKey PLACEHOLDER_HOME/.ssh/ssh_host_ed25519_key
AuthorizedKeysFile PLACEHOLDER_HOME/.ssh/authorized_keys

# Security
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
UseDNS no
GSSAPIAuthentication no
X11Forwarding no
PrintMotd no

# Performance
Compression no
TCPKeepAlive yes

# Forwarding
AllowTcpForwarding yes

# Ciphers (modern, fast)
Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256

AcceptEnv LANG LC_*
SSHD_EOF

    # Substitute $HOME (heredoc cannot expand vars inside single-quoted EOF)
    ${pkgs.gnused}/bin/sed -i \
      "s|PLACEHOLDER_HOME|$HOME|g" \
      "$HOME/.ssh/sshd_config"

    # Append sftp subsystem with current Nix store path
    echo "Subsystem sftp ${pkgs.openssh}/libexec/sftp-server" \
      >> "$HOME/.ssh/sshd_config"

    chmod 600 "$HOME/.ssh/sshd_config"

    # ── start-sshd.sh ────────────────────────────────────────────────────
    cat > "$HOME/.ssh/start-sshd.sh" << 'START_EOF'
#!/usr/bin/env bash
set -euo pipefail

PIDFILE="$HOME/.ssh/sshd.pid"
LOGFILE="$HOME/.ssh/sshd.log"
SSHD_BIN="PLACEHOLDER_SSHD"
CONFIG="$HOME/.ssh/sshd_config"

# Kill any existing instance
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID"
    sleep 0.3
  fi
  rm -f "$PIDFILE"
fi

rm -f "$LOGFILE"
"$SSHD_BIN" -f "$CONFIG" -E "$LOGFILE"

# Wait up to 2 seconds for PID file
for i in $(seq 1 20); do
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  DEVICE_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || echo "<device-ip>")
  echo "✓ SSH server started (PID $(cat "$PIDFILE"))"
  echo ""
  echo "── Connection Methods ────────────────────────────────────────────"
  echo "  Wi-Fi:    ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@${DEVICE_IP}"
  echo "  USB:      adb forward tcp:8022 tcp:8022"
  echo "            ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@localhost"
  echo "  Tailscale: ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@<tailscale-ip>"
  echo "─────────────────────────────────────────────────────────────────"
  echo ""
  echo "  Client private key to copy to Mac:"
  echo "    $HOME/.ssh/android_client_key"
  echo "  (scp it or cat it and paste into ~/.ssh/android_client_key on Mac)"
else
  echo "✗ SSH server failed to start" >&2
  cat "$LOGFILE" >&2
  exit 1
fi
START_EOF

    # Substitute sshd binary path (cannot interpolate Nix vars inside heredoc)
    ${pkgs.gnused}/bin/sed -i \
      "s|PLACEHOLDER_SSHD|${pkgs.openssh}/bin/sshd|g" \
      "$HOME/.ssh/start-sshd.sh"
    chmod +x "$HOME/.ssh/start-sshd.sh"

    # ── stop-sshd.sh ─────────────────────────────────────────────────────
    cat > "$HOME/.ssh/stop-sshd.sh" << 'STOP_EOF'
#!/usr/bin/env bash
PIDFILE="$HOME/.ssh/sshd.pid"
if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID"
    rm -f "$PIDFILE"
    echo "✓ SSH server stopped"
  else
    rm -f "$PIDFILE"
    echo "SSH server was not running (stale PID file removed)"
  fi
else
  echo "SSH server is not running"
fi
STOP_EOF
    chmod +x "$HOME/.ssh/stop-sshd.sh"

    # ── status-sshd.sh ───────────────────────────────────────────────────
    cat > "$HOME/.ssh/status-sshd.sh" << 'STATUS_EOF'
#!/usr/bin/env bash
PIDFILE="$HOME/.ssh/sshd.pid"
if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "✓ SSH server running (PID $PID, port 8022)"
  else
    echo "✗ SSH server not running (stale PID file)"
  fi
else
  echo "✗ SSH server not running"
fi
STATUS_EOF
    chmod +x "$HOME/.ssh/status-sshd.sh"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  SSH server configured. Auto-starts on shell open."
    echo "  Manual control:"
    echo "    ~/.ssh/start-sshd.sh   — start"
    echo "    ~/.ssh/stop-sshd.sh    — stop"
    echo "    ~/.ssh/status-sshd.sh  — status"
    echo ""
    echo "  Client key for Mac: $HOME/.ssh/android_client_key"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  '';
```

- [ ] **Step 3: Verify the file is syntactically valid**

```bash
cd ~/dotfiles
nix-instantiate --parse modules/platforms/android.nix
```
Expected: no errors, prints the parsed expression.

- [ ] **Step 4: Commit**

```bash
git add modules/platforms/android.nix
git commit -m "feat(android): add SSH server activation — host keys, client keypair, sshd_config, start/stop/status scripts"
```

---

### Task 2: Add `environment.loginShellInit` auto-start to android.nix

**Files:**
- Modify: `modules/platforms/android.nix`

This block runs inside every new shell (every time the nix-on-droid app opens a terminal). The PID file guard ensures sshd only starts if it is not already running — opening multiple tabs will not spawn duplicate daemons.

- [ ] **Step 1: Add `environment.loginShellInit` to `modules/platforms/android.nix`**

Add this block immediately after the `build.activation.sshd = '' ... '';` closing block, before the final `}`:

```nix
  # Auto-start SSH server on every shell open.
  # PID file guard prevents duplicate processes when opening multiple tabs.
  environment.loginShellInit = ''
    _sshd_autostart() {
      local PIDFILE="$HOME/.ssh/sshd.pid"
      local SSHD_BIN="${pkgs.openssh}/bin/sshd"
      local CONFIG="$HOME/.ssh/sshd_config"

      # Already running?
      if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
        return 0
      fi

      # sshd_config not yet generated (first run before activation)
      if [ ! -f "$CONFIG" ]; then
        return 0
      fi

      rm -f "$PIDFILE"
      "$SSHD_BIN" -f "$CONFIG" -E "$HOME/.ssh/sshd.log" 2>/dev/null || true
    }
    _sshd_autostart
  '';
```

- [ ] **Step 2: Verify parse**

```bash
cd ~/dotfiles
nix-instantiate --parse modules/platforms/android.nix
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add modules/platforms/android.nix
git commit -m "feat(android): auto-start SSH server on shell open via loginShellInit (PID-guarded)"
```

---

### Task 3: Update README.md with Android SSH Server section

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Find the Android Quick Start section in README.md** (currently ends at `nix-on-droid switch --flake .`).

- [ ] **Step 2: Replace the Android section with the expanded version below:**

Find:
```markdown
### Android (Nix-on-Droid)

```bash
# Install from F-Droid: https://f-droid.org/packages/com.termux.nix/
git clone <repo> ~/dotfiles
cd ~/dotfiles
nix-on-droid switch --flake .
```
```

Replace with:
```markdown
### Android (Nix-on-Droid)

```bash
# Install from F-Droid: https://f-droid.org/packages/com.termux.nix/
git clone <repo> ~/dotfiles
cd ~/dotfiles
nix-on-droid switch --flake .
```

#### SSH Server (connect from Mac)

SSH server starts automatically on every shell open. After running `nix-on-droid switch`:

```bash
# Check status
~/.ssh/status-sshd.sh

# Manual control
~/.ssh/start-sshd.sh    # start (shows connection info)
~/.ssh/stop-sshd.sh     # stop
```

**First-time setup — copy the client key to your Mac:**

```bash
# On Android: display the private key
cat ~/.ssh/android_client_key

# On Mac: paste it into a file and set permissions
mkdir -p ~/.ssh
# paste the key content into ~/.ssh/android_client_key
chmod 600 ~/.ssh/android_client_key
```

**Connect from Mac:**

| Method | Command |
|--------|---------|
| **Wi-Fi** | `ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@<device-ip>` |
| **USB** | `adb forward tcp:8022 tcp:8022` → `ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@localhost` |
| **Tailscale** | Install [Tailscale](https://tailscale.com/download/android) on Android → `ssh -p 8022 -i ~/.ssh/android_client_key nix-on-droid@<tailscale-ip>` |

> **Tip:** Add to `~/.ssh/config` on Mac for easy access:
> ```
> Host droid
>   HostName <device-ip>       # or Tailscale IP
>   Port 8022
>   User nix-on-droid
>   IdentityFile ~/.ssh/android_client_key
> ```
> Then just: `ssh droid`
```

- [ ] **Step 3: Fix the stale Android feature bullet** in the Features section.

Find:
```markdown
- **Android**: XFCE4 desktop environment via VNC
```

Replace with:
```markdown
- **Android**: SSH server (Wi-Fi, USB, Tailscale), auto-start on shell open
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add Android SSH server setup guide to README"
```

---

### Task 4: End-to-end verification

**Files:** none (verification only)

- [ ] **Step 1: Dry-run build the android flake output**

```bash
cd ~/dotfiles
nix build .#nixOnDroidConfigurations.default.activationPackage --dry-run 2>&1 | head -30
```
Expected: no eval errors. May show "would build" or "already built".

- [ ] **Step 2: Verify the full file parses correctly as part of the flake**

```bash
nix eval .#nixOnDroidConfigurations.default.activationPackage --apply builtins.isAttrs
```
Expected: `true`

- [ ] **Step 3: Verify README has no broken markdown (optional lint)**

```bash
# If markdownlint is available:
markdownlint README.md
# Otherwise just cat to visually inspect
grep -n "SSH" README.md
```
Expected: SSH section visible in grep output.

- [ ] **Step 4: Final commit summary**

```bash
git log --oneline -4
```
Expected: 3 feature commits visible (activation, loginShellInit, README).
