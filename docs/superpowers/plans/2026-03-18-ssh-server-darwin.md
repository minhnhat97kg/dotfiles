# SSH Server for Darwin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable and speed-optimize macOS's built-in SSH server via nix-darwin's `services.openssh` for LAN and Tailscale remote development.

**Architecture:** Add `services.openssh` block to `modules/platforms/darwin.nix` with speed-optimized directives (`aes256-gcm` cipher, no compression, no DNS). Extend the existing `users.users.${username}` block to declare authorized SSH keys. No new files needed.

**Tech Stack:** nix-darwin, OpenSSH 9.x (macOS Ventura+)

---

## File Structure

| File | Responsibility |
|---|---|
| `modules/platforms/darwin.nix` | Platform-wide Darwin config including SSH server and user SSH keys |

**Changes:** Two additive blocks in a single file (no splits needed — config is small and cohesive).

---

## Task 1: Enable SSH Server with Speed Optimizations

**Files:**
- Modify: `modules/platforms/darwin.nix:28-56` (add `services.openssh` block after homebrew config)

- [ ] **Step 1: Read current darwin.nix to identify insertion point**

File: `modules/platforms/darwin.nix`

Look for the `launchd.user.agents.clipse` block. It ends with closing braces and a semicolon (`};` on line 55). The SSH config block will be inserted right after this block and before the `system.primaryUser = username;` line (line 57).

- [ ] **Step 2: Add services.openssh block**

Insert this block after line 55 (after the clipse launchd config):

```nix
  # SSH Server — speed-optimized for LAN and Tailscale
  services.openssh = {
    enable = true;
    extraConfig = ''
      Port 22
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      PermitRootLogin no
      UseDNS no
      Compression no
      ClientAliveInterval 60
      ClientAliveCountMax 3
      MaxSessions 10
      Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
      MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
    '';
  };
```

This goes inside the top-level attribute set (same level as `nix`, `programs.zsh`, `homebrew`, etc.).

- [ ] **Step 3: Verify the file syntax is valid**

Run: `nix flake check`

Expected: No errors related to darwin.nix syntax.

- [ ] **Step 4: Commit**

```bash
git add modules/platforms/darwin.nix
git commit -m "feat: enable speed-optimized SSH server via services.openssh

- Add services.openssh with aes256-gcm cipher (faster on M-series)
- Disable password auth, DNS lookup, compression for speed
- Set keepalive (60s interval, 3 probes) and max sessions for multiplexing
- Keys-only auth ready for authorized_keys configuration

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Add Authorized SSH Keys to User

**Files:**
- Modify: `modules/platforms/darwin.nix:59-63` (extend `users.users."${username}"` block)

- [ ] **Step 1: Read the users.users block**

Current block in darwin.nix (lines 59-63):

```nix
users.users."${username}" = {
  home = "/Users/${username}";
  description = username;
  shell = pkgs.zsh;
};
```

- [ ] **Step 2: Add openssh.authorizedKeys.keys**

Extend the block to include:

```nix
users.users."${username}" = {
  home = "/Users/${username}";
  description = username;
  shell = pkgs.zsh;
  openssh.authorizedKeys.keys = [
    # TODO: add your public key(s) here
    # e.g. "ssh-ed25519 AAAA... user@device"
  ];
};
```

The `openssh.authorizedKeys.keys` is a list of public key strings. The TODO placeholder allows the user to fill in keys later without blocking the implementation.

- [ ] **Step 3: Verify syntax**

Run: `nix flake check`

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add modules/platforms/darwin.nix
git commit -m "feat: declare SSH authorized keys in darwin.nix

Add openssh.authorizedKeys.keys to users.users.nhath with TODO
placeholder for public keys. Keys will be managed declaratively
once user provides them.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Test the Configuration

**Files:**
- N/A (existing files only)

- [ ] **Step 1: Dry-run the Nix config**

Run: `nix flake check`

Expected: PASS — no evaluation errors.

- [ ] **Step 2: Build the darwin system (dry-run to catch errors early)**

Run: `darwin-rebuild dry-activate --flake . 2>&1 | head -50`

Expected: Output shows the system configuration was evaluated successfully; no errors about missing keys or invalid syntax.

If successful, the `/etc/ssh/sshd_config.d/100-nix-darwin.conf` file is generated in the Nix store. You won't see its exact path in the dry-activate output, but you can verify it was created by checking the system build:

```bash
darwin-rebuild dry-activate --flake . 2>&1 | grep -i "sshd_config"
```

Expected: Some reference to the sshd config generation (or no output if grep finds nothing — the absence of errors is what matters).

- [ ] **Step 3: Verify sshd_config syntax that will be generated**

If dry-activate succeeded with no errors, the config syntax is correct. The actual file will be activated in Task 4.

---

## Task 4: Rebuild and Activate

**Files:**
- N/A (rebuild applies config)

> **Note:** This step requires sudo and will restart sshd. Do this when you have physical access to the Mac or can recover if something goes wrong.

- [ ] **Step 1: Run darwin-rebuild switch**

Run: `darwin-rebuild switch --flake .`

Expected:
- System configuration is updated
- sshd restarts (no error output expected if successful)
- The command completes without errors

- [ ] **Step 2: Verify sshd is running**

Run: `sudo launchctl list | grep ssh`

Expected output (example):
```
-	0	com.openssh.sshd
```

The `-` in the first column means the service is running continuously.

- [ ] **Step 3: Verify sshd config was applied**

Run: `sudo cat /etc/ssh/sshd_config.d/100-nix-darwin.conf | grep -E "^(Port|Ciphers|MACs|Compression|UseDNS)"`

Expected output (example):
```
Port 22
Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
Compression no
UseDNS no
```

- [ ] **Step 4: Test SSH connection from local Mac (localhost)**

Run: `ssh -v nhath@localhost 2>&1 | head -20`

Expected: Connection succeeds or fails with "Permission denied (publickey)" — the important part is that SSH is listening and responding. If authorized_keys is empty, you'll get permission denied (expected). If SSH isn't running, you'll see "Connection refused".

> **Troubleshooting:** If you see "Connection refused":
> - Check `sudo launchctl list | grep ssh` again
> - Run `sudo log stream --level=debug --predicate 'process == "sshd"'` to see sshd logs
> - Check `/var/log/system.log` for errors during launch

- [ ] **Step 5: Commit the successful rebuild**

Run: `git status`

Expected: Clean (no untracked files, nothing to commit). The rebuild is recorded in system state, not git.

```bash
git log --oneline -2
```

Should show the two commits from Tasks 1 and 2.

---

## Task 5: Add Your Public Keys and Test Remote Connection

**Files:**
- Modify: `modules/platforms/darwin.nix:68-74` (fill in authorized_keys TODO)

- [ ] **Step 1: Get your public key(s)**

You need the public SSH key from the device you'll be connecting from (e.g., Android phone, another Mac, or Linux box).

On the client device:

```bash
cat ~/.ssh/id_ed25519.pub
# or
cat ~/.ssh/id_rsa.pub
```

Copy the full output (e.g., `ssh-ed25519 AAAA...`).

- [ ] **Step 2: Add the public key to authorized_keys list**

Edit `modules/platforms/darwin.nix`, replace the TODO block:

```nix
users.users."${username}" = {
  home = "/Users/${username}";
  description = username;
  shell = pkgs.zsh;
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAA... your@device"  # Replace with your actual key
  ];
};
```

If you have multiple keys (e.g., from phone and laptop), add each as a separate string:

```nix
openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... phone"
  "ssh-ed25519 BBBB... laptop"
];
```

- [ ] **Step 3: Dry-run the config**

Run: `nix flake check`

Expected: PASS.

- [ ] **Step 4: Rebuild with new keys**

Run: `darwin-rebuild switch --flake .`

Expected: Completes successfully.

- [ ] **Step 5: Test remote connection**

From the client device (phone, another Mac, etc.):

**Over LAN:**
```bash
ssh nhath@Nathan-Macbook.local
```

**Over Tailscale** (if you have it running):
```bash
ssh nhath@<tailscale-ip>
```

Expected: You are logged in to the Mac shell without entering a password (key-based auth).

If you see "Permission denied (publickey)", the key is not in the authorized_keys list. Check:
- The key string is copied exactly (no newlines or extra spaces)
- The format is correct (starts with `ssh-ed25519` or `ssh-rsa`)
- Run `cat ~/.ssh/authorized_keys` on the Mac to verify the key is there

- [ ] **Step 6: Commit**

```bash
git add modules/platforms/darwin.nix
git commit -m "feat: add authorized SSH keys

Add nhath's public keys for remote SSH access. Keys are managed
declaratively via nix-darwin, enabling key-based auth to Mac
over LAN and Tailscale.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Testing Checklist

Before declaring this complete:

- [ ] `nix flake check` passes
- [ ] `darwin-rebuild switch` completes without errors
- [ ] `sudo launchctl list | grep ssh` shows `com.openssh.sshd` running
- [ ] `sudo cat /etc/ssh/sshd_config.d/100-nix-darwin.conf` contains the speed optimizations (aes256-gcm cipher, no compression, no DNS)
- [ ] SSH listens on port 22: `netstat -an | grep 22` or `lsof -i :22` shows `sshd` listening
- [ ] Local key-based connection works: `ssh nhath@localhost` succeeds or fails with permission denied (not connection refused)
- [ ] Remote key-based connection works over LAN: `ssh nhath@Nathan-Macbook.local` from another device
- [ ] Remote key-based connection works over Tailscale: `ssh nhath@<tailscale-ip>` from another device (if Tailscale is available)

---

## Rollback (if needed)

If something goes wrong after rebuild:

1. **Revert commits:**
   ```bash
   git reset --hard HEAD~2
   ```

2. **Rebuild to previous state:**
   ```bash
   darwin-rebuild switch --flake .
   ```

3. **Verify sshd restarted:**
   ```bash
   sudo launchctl list | grep ssh
   ```

The system will revert to the SSH config before these changes (either disabled or whatever was there before).

---

## Notes for Implementer

- **No test suite:** This is infrastructure config (Nix), not application code. Testing is done via rebuild + verification (Tasks 3–5).
- **Speed optimizations are safe:** The ciphers and settings are widely supported by modern SSH clients. If an old client can't connect, it will show a cipher negotiation error, not silently fail.
- **Keys are optional during development:** Task 5 can be deferred; the SSH server will be running and listening after Task 4, just without any authorized keys. Add keys when you have them.
- **LAN access via mDNS:** The hostname `Nathan-Macbook.local` is automatically published by macOS. If it doesn't resolve on your LAN, use the Mac's IP address directly (e.g., `ssh nhath@192.168.1.X`).
