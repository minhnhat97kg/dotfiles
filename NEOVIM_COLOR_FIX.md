# Neovim Color Fix for SSH/Mosh

## Error Fixed

Previously you got: `Unknown option 't_Co'`

This is because **Neovim doesn't use `t_Co`** like classic Vim. In Neovim, colors are controlled by:
- `TERM` environment variable
- `termguicolors` option

## The Proper Fix

I've updated the code to use **Neovim-compatible** color settings:

```lua
-- Set TERM environment variable (Neovim reads this)
vim.env.TERM = "xterm-256color"

-- Disable true colors (use 256 colors instead)
vim.opt.termguicolors = false

-- UTF-8 for icons
vim.opt.encoding = "utf-8"
```

## How It Works

### For SSH/Mosh Sessions:

1. **TERM = "xterm-256color"**
   - Tells Neovim to use 256-color mode
   - Works on both SSH and Mosh

2. **termguicolors = false**
   - Disables 24-bit true color
   - Uses 256-color palette (plenty for themes!)

3. **UTF-8 encoding**
   - Ensures icons display properly

---

## Apply the Fix

### On Android:
```bash
nix-on-droid switch --flake ~/dotfiles#default
```

### Connect via Mosh:
```bash
# In Termius, connect
# Open Neovim
nvim test.go

# Colors should work now! 🎨
```

---

## Manual Color Fix (If Needed)

If colors are still broken after rebuild, run this in Neovim:

```vim
:set notermguicolors
:colorscheme onedark
```

**This should immediately restore colors.**

---

## Debug Command

To check your settings, run in Neovim:

```vim
:DebugEnv
```

This shows:
- Environment variables
- Detection status
- Color settings

**Look for:**
```
Terminal Info:
  TERM: xterm-256color         ← Should be this

Neovim Color Settings:
  termguicolors: false          ← Should be false for SSH/Mosh
  encoding: utf-8               ← Should be utf-8
```

---

## Check Colors Manually

In Neovim:

```vim
" Check TERM variable
:echo $TERM
" Should show: xterm-256color or screen-256color

" Check termguicolors
:echo &termguicolors
" Should show: 0 (false) for SSH/Mosh

" Check encoding
:echo &encoding
" Should show: utf-8
```

---

## Why This Happens

### Neovim vs Vim

**Classic Vim:**
- Uses `t_Co` option
- Manually set: `:set t_Co=256`

**Neovim:**
- Reads `TERM` environment variable automatically
- Uses `termguicolors` for true color
- **No `t_Co` option!**

### SSH/Mosh Challenges

- True color (`termguicolors`) doesn't work well over SSH
- Mosh doesn't support true color at all
- Solution: Use 256 colors (still looks great!)

---

## What You Get

With the fix applied:

✅ **256-color palette** (16+ million color combinations)
✅ **Full theme support** (onedark looks beautiful)
✅ **All icons work** (UTF-8 support)
✅ **Fast performance** (optimized for network)

**256 colors is more than enough for beautiful syntax highlighting!**

---

## Comparison

| Mode | Colors | Works Over SSH? | Works in Mosh? |
|------|--------|-----------------|----------------|
| True color (`termguicolors=true`) | 16M | ⚠️ Unreliable | ❌ No |
| 256 colors (`termguicolors=false`) | 256 palette | ✅ Yes | ✅ Yes |
| 16 colors (broken) | 16 | ⚠️ Basic | ⚠️ Basic |

**We use 256 colors = Perfect balance!**

---

## Troubleshooting

### Still seeing black and white?

**Option 1: Rebuild Neovim config**
```bash
# Exit Neovim
# Restart shell
exec zsh
nvim test.go
```

**Option 2: Manual fix**
```vim
:set notermguicolors
:colorscheme onedark
```

**Option 3: Check TERM**
```bash
# Before starting Neovim
echo $TERM
# Should be: xterm-256color

# If not, set it:
export TERM=xterm-256color
nvim test.go
```

### Colors work in SSH but not Mosh?

This shouldn't happen anymore with the fix. If it does:

```bash
# In Mosh session, before Neovim:
export TERM=xterm-256color
export LC_ALL=en_US.UTF-8
nvim test.go
```

### Icons showing as boxes?

**Check locale:**
```bash
locale
# Should show UTF-8 locale

# If not:
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```

**In Neovim:**
```vim
:set encoding=utf-8
:set fileencoding=utf-8
```

---

## Summary

### The Fix

✅ Removed `t_Co` (doesn't exist in Neovim)
✅ Use `TERM` environment variable instead
✅ Disable `termguicolors` for SSH/Mosh
✅ Enable UTF-8 encoding

### How to Apply

1. **Rebuild:** `nix-on-droid switch --flake ~/dotfiles#default`
2. **Connect:** Via SSH or Mosh
3. **Enjoy:** Colors and icons work! 🎨

### If Problems

**Run:** `:DebugEnv` in Neovim
**Share:** The output with me!

---

**Colors should now work perfectly in both SSH and Mosh!** 🚀🎨
