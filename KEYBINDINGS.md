# Keybindings Reference

Complete reference for all keyboard shortcuts across tmux, skhd (window manager), and vim.

## Table of Contents
- [Tmux](#tmux)
- [skhd (Window Manager)](#skhd-window-manager)
- [Neovim](#neovim)

---

## Tmux

**Prefix Key:** `Ctrl+b`

### Pane Management

#### Pane Navigation (No Prefix Required)
| Key | Action |
|-----|--------|
| `Ctrl+h` | Move to left pane (vim-aware) |
| `Ctrl+j` | Move to down pane (vim-aware) |
| `Ctrl+k` | Move to up pane (vim-aware) |
| `Ctrl+l` | Move to right pane (vim-aware) |

#### Pane Resizing (No Prefix Required)
| Key | Action |
|-----|--------|
| `Alt+h` | Resize pane left (5 columns) |
| `Alt+j` | Resize pane down (5 lines) |
| `Alt+k` | Resize pane up (5 lines) |
| `Alt+l` | Resize pane right (5 columns) |

#### Pane Creation (Prefix Required)
| Key | Action |
|-----|--------|
| `Prefix \|` | Split pane horizontally |
| `Prefix -` | Split pane vertically |
| `Prefix c` | Create new window (in current path) |

#### Pane Control (Prefix Required)
| Key | Action |
|-----|--------|
| `Prefix z` | Toggle pane zoom (maximize/restore) |

### Window Management

#### Window Navigation (No Prefix Required)
| Key | Action |
|-----|--------|
| `Alt+,` | Previous window |
| `Alt+.` | Next window |
| `Alt+1` | Jump to window 1 |
| `Alt+2` | Jump to window 2 |
| `Alt+3` | Jump to window 3 |
| `Alt+4` | Jump to window 4 |
| `Alt+5` | Jump to window 5 |
| `Alt+6` | Jump to window 6 |
| `Alt+7` | Jump to window 7 |
| `Alt+8` | Jump to window 8 |
| `Alt+9` | Jump to window 9 |

### Copy Mode

| Key | Action |
|-----|--------|
| `Prefix [` | Enter copy mode |
| `v` | Begin selection (in copy mode) |
| `y` | Copy selection (in copy mode) |
| `q` | Exit copy mode |

### Configuration

| Key | Action |
|-----|--------|
| `Prefix r` | Reload tmux config |

### Mouse Support

- **Enabled**: Click to select pane, drag to resize, scroll to navigate history
- Right-click on pane for context menu

---

## skhd (Window Manager)

**Modifier Keys:**
- `mod1` = `Alt+Shift`
- `mod2` = `Ctrl+Alt+Shift`

### Layout Management

| Key | Action |
|-----|--------|
| `Alt+Shift+Space` | Cycle layout forward |
| `Ctrl+Alt+Shift+Space` | Cycle layout backward |
| `Alt+Shift+a` | BSP layout (Tall) |
| `Alt+Shift+s` | BSP with 50% ratio (Wide) |
| `Alt+Shift+d` | Stack layout (Fullscreen) |
| `Alt+Shift+f` | Toggle floating terminal |
| `Alt+Shift+w` | Open window picker |
| `Alt+Shift+i` | Show current layout |

### Pane/Window Controls

| Key | Action |
|-----|--------|
| `Alt+Shift+h` | Shrink main pane |
| `Alt+Shift+l` | Expand main pane |
| `Alt+Shift+,` | Balance all panes |
| `Alt+Shift+.` | Balance all panes |

### Window Focus Navigation

| Key | Action |
|-----|--------|
| `Alt+Shift+j` | Focus previous window (counter-clockwise) |
| `Alt+Shift+k` | Focus next window (clockwise) |
| `Alt+Shift+p` | Focus previous screen |
| `Alt+Shift+n` | Focus next screen |

### Window Movement

| Key | Action |
|-----|--------|
| `Ctrl+Alt+Shift+h` | Move window to previous space |
| `Ctrl+Alt+Shift+l` | Move window to next space |
| `Ctrl+Alt+Shift+j` | Swap window counter-clockwise |
| `Ctrl+Alt+Shift+k` | Swap window clockwise |
| `Alt+Shift+Return` | Swap with main window |

### Space/Desktop Management

| Key | Action |
|-----|--------|
| `Ctrl+Alt+Shift+c` | Create new desktop |
| `Ctrl+Alt+Shift+d` | Destroy current desktop (with confirmation) |
| `Ctrl+Alt+Shift+m` | Create desktop and move window to it |

### Space Switching

| Key | Action |
|-----|--------|
| `Cmd+j` | Focus previous space |
| `Cmd+k` | Focus next space |
| `Ctrl+Alt+Shift+1-9` | Move window to space 1-9 and follow |
| `Ctrl+Alt+Shift+0` | Move window to space 10 and follow |

### Screen Management

| Key | Action |
|-----|--------|
| `Ctrl+Alt+Shift+w` | Move window to screen 1 |
| `Ctrl+Alt+Shift+e` | Move window to screen 2 |
| `Ctrl+Alt+Shift+r` | Move window to screen 3 |
| `Ctrl+Alt+Shift+q` | Move window to screen 4 |
| `Ctrl+Alt+Shift+g` | Move window to screen 5 |

### Utility

| Key | Action |
|-----|--------|
| `Alt+Shift+/` | Show keybindings picker (fzf) |
| `Alt+Shift+t` | Toggle float for focused window |
| `Ctrl+Alt+Shift+t` | Toggle global tiling |
| `Alt+Shift+z` | Balance space (re-tile all windows) |
| `Ctrl+Alt+Shift+z` | Restart yabai |
| `Cmd+Shift+r` | Reload skhd config |
| `Alt+Shift+o` | Rotate tree 90° |
| `Alt+Shift+y` | Mirror tree (y-axis) |
| `Alt+Shift+x` | Mirror tree (x-axis) |

---

## Neovim

Neovim keybindings depend on your specific configuration. Common defaults:

### Normal Mode

| Key | Action |
|-----|--------|
| `h/j/k/l` | Move left/down/up/right |
| `w/b` | Next/previous word |
| `0/$` | Start/end of line |
| `gg/G` | Start/end of file |
| `Ctrl+d/u` | Scroll down/up half page |
| `Ctrl+f/b` | Scroll down/up full page |

### Window Navigation (Matches Tmux)

| Key | Action |
|-----|--------|
| `Ctrl+h` | Move to left window |
| `Ctrl+j` | Move to down window |
| `Ctrl+k` | Move to up window |
| `Ctrl+l` | Move to right window |

*Note: When inside tmux, these keys are tmux-aware and will navigate between tmux panes first, then vim windows.*

---

## Quick Reference Summary

### Most Common Operations

**Tmux:**
- Resize panes: `Alt+h/j/k/l`
- Switch windows: `Alt+,` / `Alt+.`
- Navigate panes: `Ctrl+h/j/k/l`
- Split panes: `Ctrl+b |` or `Ctrl+b -`

**Window Manager (skhd):**
- Focus windows: `Alt+Shift+j/k`
- Move windows: `Ctrl+Alt+Shift+h/l`
- Resize panes: `Alt+Shift+h/l`
- Switch spaces: `Cmd+j/k`

**Neovim:**
- Navigate: `h/j/k/l`
- Switch windows: `Ctrl+h/j/k/l`

---

## Conflict Resolution

The following key combinations are used in multiple contexts:

| Keys | Tmux | skhd | Context |
|------|------|------|---------|
| `Alt+h/j/k/l` | Resize panes | - | Tmux only (no conflict) |
| `Alt+Shift+h/j/k/l` | - | Window operations | skhd only (no conflict) |
| `Ctrl+h/j/k/l` | Navigate panes | - | Tmux/Vim integration |

No actual conflicts exist because:
- Tmux uses `Alt` (without Shift)
- skhd uses `Alt+Shift` or `Ctrl+Alt+Shift`
- Different modifier combinations prevent conflicts

---

## Configuration Files

- **Tmux**: `modules/shared.nix` (lines 44-52 for resize bindings)
- **skhd**: `skhd/skhdrc`
- **Neovim**: `nvim/init.lua` and related configs

---

## Tips

1. **Tmux pane resize** now works without prefix - use `Ctrl+Shift+h/j/k/l`
2. **Window navigation** moved to `Alt+,/.` to make room for resize
3. **All keybindings** follow vim-style `hjkl` navigation
4. **Mouse support** is enabled in tmux for clicking and dragging
5. **View all skhd bindings** anytime with `Alt+Shift+/`

---

## Customization

To modify these keybindings:

### Tmux
Edit `modules/shared.nix`:
```nix
extraConfig = ''
  bind -n C-S-h resize-pane -L 5
  bind -n C-S-j resize-pane -D 5
  bind -n C-S-k resize-pane -U 5
  bind -n C-S-l resize-pane -R 5
'';
```

### skhd
Edit `skhd/skhdrc`:
```
alt + shift - h : yabai -m window --ratio rel:-0.05
# Add your bindings here
```

Then rebuild:
```bash
sudo darwin-rebuild switch --flake .
```
