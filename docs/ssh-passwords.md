# SSH Password Management

Store passwords encrypted, connect without typing them.

## Quick Start

```bash
# Add server password
sshp-add myserver user 192.168.1.100 22

# Connect
sshp myserver

# List servers
sshp-list
```

## Tunnels

```bash
# Save tunnel
sshp-tunnel add mysql-prod server1 3306:db.internal:3306

# Connect
sshp-tunnel mysql-prod

# List
sshp-tunnel list
```

## Commands

```
sshp <alias>                       Connect to server
sshp-add <alias> <user> <host>     Add password
sshp-list                          List servers
sshp-tunnel <profile>              Connect to tunnel
sshp-tunnel add <profile> <host>   Save tunnel
sshp-tunnel list                   List tunnels
```

## How It Works

- Passwords encrypted in `secrets/encrypted/ssh/passwords.sops.yaml`
- Tunnels encrypted in `secrets/encrypted/ssh/tunnels.sops.yaml`
- Decrypted to `~/.ssh/*.yaml` with `make decrypt-ssh`

## Sync

```bash
# Push
git add secrets/encrypted/ssh/*.sops.yaml
git commit -m "Update SSH configs"
git push

# Pull
git pull
make decrypt-ssh
```

## Security

✅ Commit: `secrets/encrypted/ssh/*.sops.yaml`
❌ Never: `~/.ssh/*.yaml`, `~/.config/sops/age/keys.txt`
