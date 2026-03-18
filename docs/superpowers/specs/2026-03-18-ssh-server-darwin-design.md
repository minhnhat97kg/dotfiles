# SSH Server for Darwin — Speed-Optimized Design

**Date:** 2026-03-18
**Status:** Draft

## Overview

Configure macOS's built-in OpenSSH server (sshd) declaratively via nix-darwin's
`services.openssh`, optimized for low-latency remote development over LAN and Tailscale.

## Goals

- Enable SSH server on the Mac for remote development sessions
- Key-based auth only (no passwords)
- Minimize connection establishment time and per-packet overhead
- Fully managed by Nix — no manual `/etc/ssh` editing

## Non-Goals

- Public internet exposure (no port-forwarding, no fail2ban)
- Multiple user accounts
- SFTP-only or restricted shell access

## Architecture

`services.openssh` block added to `modules/platforms/darwin.nix`. nix-darwin exposes
only `enable`, `extraConfig` (a raw string written to
`/etc/ssh/sshd_config.d/100-nix-darwin.conf`), and `hostKeys`. All sshd directives
go inside `extraConfig`. nix-darwin owns the launchd service (`com.openssh.sshd`)
and restarts sshd on `darwin-rebuild switch`.

Authorized keys are added into the **existing** `users.users."${username}"` block in
`darwin.nix` via `openssh.authorizedKeys.keys`, keeping the full SSH server setup in
one place. (They are not machine-specific enough to require the host file, but can be
moved to `Nathan-Macbook.nix` later if multi-host key divergence is needed.)

## Configuration Details

### Service options (`services.openssh`)

nix-darwin's `services.openssh` does **not** expose a `settings` attrset or `ports`
list (those are NixOS-only). All directives are passed as a raw string via `extraConfig`:

```nix
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

> **Note:** `ChallengeResponseAuthentication` was removed in OpenSSH 9.0 (macOS Ventura+).
> Use `KbdInteractiveAuthentication no` instead.

### Authorized keys

Added into the **existing** `users.users."${username}"` block in `darwin.nix`:

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

## Speed Optimizations Rationale

| Setting | Value | Reason |
|---|---|---|
| `Ciphers` | `aes256-gcm`, `chacha20-poly1305` | Both are AEAD ciphers (no separate MAC overhead). `aes256-gcm` listed first — it is faster on M-series hardware due to the dedicated AES co-processor. `chacha20-poly1305` is the fallback for non-AES-accelerated clients |
| `MACs` | `hmac-sha2-256-etm`, `hmac-sha2-512-etm` | ETM (encrypt-then-MAC) is faster and more secure than non-ETM variants; only negotiated as fallback when a non-AEAD cipher is selected. Both 256 and 512 variants included for client compatibility |
| `Compression` | `no` | On fast LAN/Tailscale, compression adds CPU cost with no throughput benefit |
| `UseDNS` | `no` | Eliminates reverse-DNS lookup delay at connection establishment |
| `ClientAliveInterval` | `60` | Keepalive probe sent every 60 seconds |
| `ClientAliveCountMax` | `3` | Drops dead connections after 3 missed probes (3 min total); keeps live sessions alive |
| `MaxSessions` | `10` | Supports SSH ControlMaster multiplexing from clients |

## Files Changed

| File | Change |
|---|---|
| `modules/platforms/darwin.nix` | Add `services.openssh` block; add `openssh.authorizedKeys.keys` to existing `users.users` block |

## Activation

After rebuild:

```bash
darwin-rebuild switch --flake .
```

Verify the service is running:

```bash
sudo launchctl list | grep ssh
```

Test connection from another device:

```bash
ssh nhath@Nathan-Macbook.local   # LAN
ssh nhath@<tailscale-ip>          # Tailscale
```
