# TablePlus to Neovim Database Migration Guide

## Overview

This guide explains how to migrate database connections from TablePlus to Neovim's vim-dadbod-ui plugin, specifically for PostgreSQL databases accessed through SSH tunnels.

## TablePlus Connection String Format

TablePlus uses a custom URL format:
```
postgresql+ssh://[ssh-user]@[ssh-host]/[db-user]:[db-password]@[db-host]/[db-name]?[parameters]
```

### Example TablePlus URL
```
postgresql+ssh://jumper@52.77.121.64/jppass_dev:3hJJT2InP886yqXspLCRW8Jd88j17lm2@rhaegal.cluster-c1gplrml8j1m.ap-southeast-1.rds.amazonaws.com/jppass_dev?statusColor=BDCCF4&env=development&name=JPP&tLSMode=0&usePrivateKey=true&safeModeLevel=0&advancedSafeModeLevel=0&driverVersion=0&lazyload=false
```

### Parsed Components
- **SSH User**: `jumper`
- **SSH Host**: `52.77.121.64`
- **Database User**: `jppass_dev`
- **Database Password**: `3hJJT2InP886yqXspLCRW8Jd88j17lm2`
- **Database Host**: `rhaegal.cluster-c1gplrml8j1m.ap-southeast-1.rds.amazonaws.com`
- **Database Name**: `jppass_dev`
- **Connection Name**: `JPP` (from name parameter)

## Solution: SSH Tunnel Approach

### 1. SSH Configuration

Add to `~/.ssh/config`:

```ssh
Host jpp-db-tunnel
  Hostname 52.77.121.64
  User jumper
  IdentityFile ~/.ssh/id_rsa
  LocalForward 5433 rhaegal.cluster-c1gplrml8j1m.ap-southeast-1.rds.amazonaws.com:5432
```

**Explanation**:
- `LocalForward 5433` - Local port on your machine
- `rhaegal.cluster-c1gplrml8j1m.ap-southeast-1.rds.amazonaws.com:5432` - Remote database host and port
- The tunnel forwards localhost:5433 → remote RDS through the jump server

### 2. Neovim Configuration

Add to `nvim/init.lua` in the `vim-dadbod-ui` plugin's `init` function:

```lua
init = function()
  -- Database connections
  vim.g.dbs = {
    JPP_dev = "postgresql://jppass_dev:3hJJT2InP886yqXspLCRW8Jd88j17lm2@localhost:5433/jppass_dev"
  }

  -- UI configuration
  vim.g.db_ui_use_nerd_fonts = 1
  -- ... rest of config
end
```

**Connection String Format**:
```
postgresql://[db-user]:[db-password]@localhost:[local-port]/[db-name]
```

## Usage

### Starting the SSH Tunnel

```bash
# Start in background
ssh -f -N jpp-db-tunnel

# Or start in foreground (useful for debugging)
ssh -N jpp-db-tunnel
```

**Flags**:
- `-f` - Run in background
- `-N` - Don't execute remote commands (tunnel only)

### Verify Tunnel is Running

```bash
# Check if tunnel process is active
ps aux | grep "ssh.*jpp-db-tunnel"

# Check if port 5433 is listening
lsof -i :5433
```

### Using in Neovim

1. **Open Database UI**:
   ```
   <leader>Du
   ```

2. **Select Connection**:
   - Navigate to `JPP_dev` in the connection list
   - Press `<Enter>` to expand

3. **Execute Queries**:
   - `<leader>Db` - Execute query (works in normal and visual mode)
   - `<leader>Ds` - Save query
   - `<leader>Df` - Find buffer
   - `<leader>Dr` - Rename buffer
   - `<leader>Dl` - Last query info

### Stopping the Tunnel

```bash
# Kill the SSH tunnel process
pkill -f "ssh.*jpp-db-tunnel"

# Or find and kill manually
ps aux | grep "ssh.*jpp-db-tunnel"
kill [PID]
```

## Troubleshooting

### Tunnel Won't Start

```bash
# Check if port 5433 is already in use
lsof -i :5433

# Try a different local port in SSH config
LocalForward 5434 rhaegal.cluster-c1gplrml8j1m.ap-southeast-1.rds.amazonaws.com:5432
```

### Connection Fails in Neovim

1. Verify tunnel is running: `lsof -i :5433`
2. Test connection manually:
   ```bash
   psql "postgresql://jppass_dev:3hJJT2InP886yqXspLCRW8Jd88j17lm2@localhost:5433/jppass_dev"
   ```
3. Check Neovim logs: `:messages`

### SSH Key Issues

```bash
# Ensure SSH key exists and has correct permissions
ls -la ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# Test SSH connection to jump host
ssh jumper@52.77.121.64
```

## Helper Scripts

### Tunnel Management Script

Create `~/.local/bin/db-tunnel`:

```bash
#!/bin/bash

TUNNEL_NAME="jpp-db-tunnel"

case "$1" in
  start)
    if pgrep -f "ssh.*$TUNNEL_NAME" > /dev/null; then
      echo "Tunnel already running"
    else
      ssh -f -N "$TUNNEL_NAME"
      echo "Tunnel started"
    fi
    ;;
  stop)
    if pkill -f "ssh.*$TUNNEL_NAME"; then
      echo "Tunnel stopped"
    else
      echo "No tunnel running"
    fi
    ;;
  status)
    if pgrep -f "ssh.*$TUNNEL_NAME" > /dev/null; then
      echo "Tunnel is running"
      lsof -i :5433
    else
      echo "Tunnel is not running"
    fi
    ;;
  restart)
    $0 stop
    sleep 1
    $0 start
    ;;
  *)
    echo "Usage: db-tunnel {start|stop|status|restart}"
    exit 1
    ;;
esac
```

Make it executable:
```bash
chmod +x ~/.local/bin/db-tunnel
```

Usage:
```bash
db-tunnel start   # Start the tunnel
db-tunnel stop    # Stop the tunnel
db-tunnel status  # Check tunnel status
db-tunnel restart # Restart the tunnel
```

## Conversion Reference

### General TablePlus → vim-dadbod Format

**TablePlus**:
```
postgresql+ssh://[ssh-user]@[ssh-host]/[db-user]:[db-password]@[db-host]/[db-name]?name=[conn-name]
```

**Steps**:
1. Extract SSH connection details → SSH config with LocalForward
2. Extract database connection details → vim-dadbod connection string
3. Use localhost:[local-port] in the connection string

**vim-dadbod**:
```lua
vim.g.dbs = {
  [conn-name] = "postgresql://[db-user]:[db-password]@localhost:[local-port]/[db-name]"
}
```

## Additional Connections

To add more connections, follow the same pattern:

1. **Add SSH tunnel** to `~/.ssh/config`:
   ```ssh
   Host another-db-tunnel
     Hostname [ssh-host]
     User [ssh-user]
     IdentityFile ~/.ssh/id_rsa
     LocalForward [local-port] [db-host]:[db-port]
   ```

2. **Add connection** to `nvim/init.lua`:
   ```lua
   vim.g.dbs = {
     JPP_dev = "postgresql://...",
     Another_DB = "postgresql://[user]:[pass]@localhost:[local-port]/[dbname]"
   }
   ```

## Advantages of vim-dadbod

- **Native Vim integration** - Edit queries with full Vim power
- **Fast query execution** - No GUI overhead
- **Version control friendly** - Save queries as plain SQL files
- **Keyboard-driven workflow** - No mouse required
- **Lightweight** - Minimal resource usage
- **Integration with pspg** - Beautiful table rendering in terminal

## Resources

- [vim-dadbod](https://github.com/tpope/vim-dadbod)
- [vim-dadbod-ui](https://github.com/kristijanhusak/vim-dadbod-ui)
- [vim-dadbod-completion](https://github.com/kristijanhusak/vim-dadbod-completion)
- [pspg - PostgreSQL pager](https://github.com/okbob/pspg)
