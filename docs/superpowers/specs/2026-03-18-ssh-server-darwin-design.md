# SSH Server for Darwin — Speed-Optimized Design

**Date:** 2026-03-18
**Status:** Approved

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

`services.openssh` block added to `modules/platforms/darwin.nix`. nix-darwin owns
the launchd service (`com.openssh.sshd`), generates `/etc/ssh/sshd_config`, and
restarts sshd on `darwin-rebuild switch`. No extra files needed.

Authorized keys are declared via `users.users.${username}.openssh.authorizedKeys.keys`
so the full SSH server setup lives in one place.

## Configuration Details

### Service options (`services.openssh`)

```nix
services.openssh = {
  enable = true;
  ports = [ 22 ];
  settings = {
    PasswordAuthentication = false;
    ChallengeResponseAuthentication = false;
    PermitRootLogin = "no";
    UseDNS = false;
    Compression = false;
    ClientAliveInterval = 60;
    ClientAliveCountMax = 3;
    MaxSessions = 10;
    Ciphers = [ "chacha20-poly1305@openssh.com" "aes256-gcm@openssh.com" ];
    Macs = [ "hmac-sha2-256-etm@openssh.com" "hmac-sha2-512-etm@openssh.com" ];
  };
};
```

### Authorized keys

```nix
users.users.${username}.openssh.authorizedKeys.keys = [
  # TODO: add your public key(s) here
  # e.g. "ssh-ed25519 AAAA... user@device"
];
```

## Speed Optimizations Rationale

| Setting | Value | Reason |
|---|---|---|
| `Ciphers` | `chacha20-poly1305`, `aes256-gcm` | CPU-native on Apple Silicon (no AES-NI bottleneck); both are AEAD so no separate MAC overhead |
| `Macs` | `hmac-sha2-256-etm` (primary) | ETM (encrypt-then-MAC) is faster and more secure; only used as fallback when non-AEAD cipher is negotiated |
| `Compression` | `false` | On fast LAN/Tailscale, compression adds CPU cost with no throughput benefit |
| `UseDNS` | `false` | Eliminates reverse-DNS lookup delay at connection establishment |
| `ClientAliveInterval` | `60` | Drops dead connections within 3 min (60s × 3), keeps live sessions alive |
| `MaxSessions` | `10` | Supports SSH ControlMaster multiplexing from clients |

## Files Changed

| File | Change |
|---|---|
| `modules/platforms/darwin.nix` | Add `services.openssh` block and authorized keys |

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
