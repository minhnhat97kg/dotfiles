# Keybindings Reference

Complete reference for all keyboard shortcuts across tmux and neovim.

## Table of Contents
- [Tmux](#tmux)

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

#### Pane Resizing
| Key | Action |
|-----|--------|
| `Prefix+h` | Resize pane left (5 columns) |
| `Prefix+j` | Resize pane down (5 lines) |
| `Prefix+k` | Resize pane up (5 lines) |
| `Prefix+l` | Resize pane right (5 columns) |
| `Ctrl+Shift+h` | Resize pane left (5 columns, no prefix) |
| `Ctrl+Shift+j` | Resize pane down (5 lines, no prefix) |
| `Ctrl+Shift+k` | Resize pane up (5 lines, no prefix) |
| `Ctrl+Shift+l` | Resize pane right (5 columns, no prefix) |

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

### Window Resizing

| Key | Action |
|-----|--------|
| `Alt+h` | Resize window left (decrease width) |
| `Alt+j` | Resize window down (decrease height) |
| `Alt+k` | Resize window up (increase height) |
| `Alt+l` | Resize window right (increase width) |
| `Alt+=` | Equalize all windows |

---

## Quick Reference Summary

### Most Common Operations

**Tmux:**
- Resize panes: `Ctrl+b h/j/k/l` or `Ctrl+Shift+h/j/k/l` (no prefix)
- Switch windows: `Alt+,` / `Alt+.`
- Navigate panes: `Ctrl+h/j/k/l`
- Split panes: `Ctrl+b |` or `Ctrl+b -`



**Neovim:**
- Navigate: `h/j/k/l`
- Switch windows: `Ctrl+h/j/k/l`
- Resize windows: `Alt+h/j/k/l`

---

## Conflict Resolution

The following key combinations are used in multiple contexts:

| Keys | Tmux | Neovim | Context |
|------|------|--------|---------|
| `Alt+h/j/k/l` | - | Resize windows | Neovim only (no conflict) |
| `Ctrl+h/j/k/l` | Navigate panes | Navigate windows | Tmux/Vim integration |
| `Ctrl+Shift+h/j/k/l` | Resize panes | - | Tmux only (no conflict) |

No actual conflicts exist because:
- Tmux uses `Ctrl+Shift` for resize, `Ctrl` for navigation
- Neovim uses `Alt` for resize, `Ctrl` for navigation


---

## Configuration Files

- **Tmux**: `modules/shared.nix` (lines 44-52 for resize bindings)

- **Neovim**: `nvim/init.lua` and related configs

---

## Tips

1. **Tmux pane resize** has two options: `Ctrl+b h/j/k/l` (with prefix) or `Ctrl+Shift+h/j/k/l` (no prefix)
2. **Neovim window resize** uses `Alt+h/j/k/l` (works in terminal with Kitty `macos_option_as_alt both`)
3. **Window navigation** moved to `Alt+,/.` to make room for resize
4. **All keybindings** follow vim-style `hjkl` navigation
5. **Mouse support** is enabled in tmux for clicking and dragging


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





Then rebuild:
```bash
sudo darwin-rebuild switch --flake .
```

Or reload configs manually:
```bash

tmux source-file ~/.config/tmux/tmux.conf  # Reload tmux
# Kitty: Press Cmd+Shift+F5 or restart
```
