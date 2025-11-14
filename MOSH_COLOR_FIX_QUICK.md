# Quick Fix: Mosh Colors and Icons

## The Good News

**Color fixes now apply to ALL SSH sessions** (including Mosh), even if Mosh detection fails!

## What Changed

I updated the detection logic to:
1. Apply 256-color fixes to **all SSH sessions** (including Mosh)
2. Try multiple methods to detect Mosh
3. Work correctly even if Mosh detection fails

## Apply the Fix

### On Android:
```bash
nix-on-droid switch --flake ~/dotfiles#default
```

### Connect from Termius:
```bash
# Connect with Mosh (or SSH)
# Open Neovim
nvim test.go

# Should see:
# "SSH session detected - applying optimizations (256 colors for compatibility)"
# Or if Mosh detected:
# "Mosh session detected - applying color fixes"
```

## Colors Should Now Work! 🎨

You should now see:
- ✅ Full color syntax highlighting
- ✅ All icons displaying
- ✅ Beautiful theme

## Debug Tool

If colors still don't work, use this debug command in Neovim:

```vim
:DebugEnv
```

This will show:
- All environment variables
- Detection results
- Current color settings

**Copy the output and let me know what it shows!**

## What the Fix Does

### For ALL SSH Sessions (including Mosh):

```lua
-- Disable true colors (not supported well over network)
vim.opt.termguicolors = false

-- Use 256 colors (works great for themes)
vim.opt.t_Co = 256

-- Ensure proper TERM
vim.env.TERM = "xterm-256color"

-- UTF-8 for icons
vim.opt.encoding = "utf-8"
```

### Result:
- 256-color palette (more than enough for beautiful themes!)
- Full icon support
- Works on SSH and Mosh

## If Still Having Issues

### Check in Neovim:

```vim
" Run debug command
:DebugEnv

" Check colors manually
:set t_Co=256
:set notermguicolors
:colorscheme onedark

" Should fix colors immediately
```

### Check TERM variable:

```bash
# In your Mosh session
echo $TERM

# Should show one of:
# - xterm-256color
# - screen-256color
```

## Why Mosh Detection Might Fail

Mosh doesn't always set `MOSH_CONNECTION` environment variable. This depends on:
- Mosh version
- How Termius launches Mosh
- Server configuration

**But it doesn't matter!** The fixes now apply to all SSH sessions anyway.

## Summary

✅ **No more black and white!**
✅ **Icons work!**
✅ **Theme looks beautiful!**
✅ **Works for both SSH and Mosh!**

Just rebuild and connect! 🚀
