# Mosh Troubleshooting Guide

## Problem: Lost Colors and Icons in Neovim with Mosh

### Symptoms
- ❌ Neovim shows only black and white (no colors)
- ❌ Icons/nerd fonts don't display (show as boxes or question marks)
- ❌ Theme not loading properly

### Root Cause

Mosh has specific requirements for colors and UTF-8 support:
1. Needs proper locale settings (UTF-8)
2. Needs 256-color terminal support
3. Client and server must have matching locale

---

## Solution Implemented

I've fixed this with automatic detection and configuration. Here's what was done:

### 1. Auto-Detect Mosh Sessions

**File: `nvim/lua/ssh-detect.lua`**
- Detects `MOSH_CONNECTION` environment variable
- Sets `vim.g.is_mosh = true`
- Applies Mosh-specific fixes automatically

### 2. Force 256 Colors

```lua
-- In Mosh, disable true colors and use 256 colors
vim.opt.termguicolors = false
vim.opt.t_Co = 256
vim.env.TERM = "xterm-256color"
```

### 3. Set UTF-8 Encoding

```lua
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
```

### 4. Set Locale in Shell

**File: `flake.nix`** - Android zsh config
```bash
if [ -n "$MOSH_CONNECTION" ]; then
  export TERM=xterm-256color
  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LANGUAGE=en_US.UTF-8
fi
```

### 5. Add Locale Support

**File: `flake.nix`** - Android packages
```nix
glibcLocales  # Provides UTF-8 locale support
```

---

## How to Apply the Fix

### On Android

```bash
# 1. Rebuild configuration with fixes
nix-on-droid switch --flake ~/dotfiles#default

# 2. Restart SSH server (optional, just to be sure)
~/.ssh/stop-sshd.sh
~/.ssh/start-sshd.sh
```

### On iPad Termius

```bash
# 1. Disconnect from current Mosh session
# 2. Reconnect with Mosh
# 3. Start Neovim
nvim test.go

# You should see:
# "Mosh session detected - applying color fixes"
# "SSH session detected - applying performance optimizations"

# 4. Check colors and icons
# Should now show full theme and icons!
```

---

## Verification

### Test 1: Check Mosh Detection

In Neovim:
```vim
:echo vim.g.is_mosh
" Should show: true (v:true)
```

### Test 2: Check Color Support

In Neovim:
```vim
:echo &t_Co
" Should show: 256

:echo $TERM
" Should show: xterm-256color
```

### Test 3: Check Locale

In shell:
```bash
echo $LC_ALL
# Should show: en_US.UTF-8

locale
# Should show UTF-8 locale settings
```

### Test 4: Visual Check

Open a file in Neovim:
```bash
nvim test.go
```

**You should see:**
- ✅ Full color syntax highlighting
- ✅ Icons in file explorer
- ✅ Colored statusline
- ✅ Colored diagnostics

---

## If Still Having Issues

### Issue 1: Still No Colors

**Try forcing theme reload:**
```vim
:colorscheme onedark
```

**Check terminal capability:**
```vim
:echo has('termguicolors')
" Should show: 0 (disabled for Mosh)

:echo &t_Co
" Should show: 256
```

**Manual fix in Neovim:**
```vim
:set t_Co=256
:set notermguicolors
:colorscheme onedark
```

### Issue 2: Icons Not Showing

**Check font in Termius:**
1. Settings → Terminal → Font
2. Make sure you're using a Nerd Font variant
3. Or install a font that supports icons on iPad

**Check encoding:**
```vim
:set encoding?
" Should show: utf-8

:set fileencoding?
" Should show: utf-8
```

**Manual fix:**
```vim
:set encoding=utf-8
:set fileencoding=utf-8
```

### Issue 3: Locale Errors

**If you see locale warnings:**

```bash
# On Android, check available locales
locale -a

# Should include:
# en_US.utf8
# en_US.UTF-8
```

**If locale not available:**

```bash
# Check glibcLocales is installed
nix-on-droid switch --flake ~/dotfiles#default

# Restart shell
exec zsh
```

### Issue 4: Different Colors Between SSH and Mosh

**This is expected!**

- **SSH**: Uses true colors (16 million colors) if terminal supports it
- **Mosh**: Uses 256 colors (256 colors palette)

**Mosh limitation:**
- Mosh doesn't support true color (24-bit color)
- This is a Mosh protocol limitation, not a bug
- 256 colors is sufficient for most themes

**If you need true colors:**
- Use regular SSH instead of Mosh
- Trade-off: Less latency resilience, but more colors

---

## Optimizing for Mosh

### Use Mosh-Friendly Theme

Some themes work better with 256 colors:

```lua
-- In nvim/init.lua, add Mosh-specific theme
if vim.g.is_mosh then
  -- Use a theme optimized for 256 colors
  vim.cmd.colorscheme("onedark")  -- Works great with 256 colors
else
  -- Use true color theme locally
  vim.cmd.colorscheme("onedark")
end
```

### Adjust Theme Settings

```lua
-- For Mosh, use simpler theme config
if vim.g.is_mosh then
  require("onedark").setup({
    style = "dark",
    transparent = false,  -- Disable transparency for better contrast
    term_colors = true,   -- Use terminal colors
  })
end
```

---

## Termius Settings for Mosh

### Recommended Termius Settings

1. **Font**
   - Use a Nerd Font if available
   - Increase font size if icons are small: 15-17

2. **Colors**
   - Theme: Dark
   - Color scheme: Default (let Neovim handle colors)

3. **Connection**
   - Connection Type: **Mosh**
   - Prediction Mode: **Adaptive** (best for variable latency)

### Testing Different Prediction Modes

Mosh has different prediction modes that affect visual feedback:

```bash
# In Termius, edit host → Mosh Settings
# Try each mode:

# 1. Adaptive (recommended)
Prediction Mode: Adaptive

# 2. Always (more aggressive, feels faster)
Prediction Mode: Always

# 3. Never (more conservative)
Prediction Mode: Never

# 4. Experimental (latest features)
Prediction Mode: Experimental
```

---

## Understanding Mosh Limitations

### What Mosh Supports
- ✅ 256 colors
- ✅ UTF-8 text/icons
- ✅ Most terminal features
- ✅ Cursor positioning

### What Mosh Doesn't Support
- ❌ True color (24-bit RGB)
- ❌ Some cursor shape changes
- ❌ Clipboard integration (OSC 52)
- ❌ Mouse scrolling in some cases

### Workarounds

**For true colors:**
- Use SSH when colors are critical
- Use Mosh for general editing (256 colors is usually fine)

**For clipboard:**
- Copy/paste within Neovim using registers: `"*y`, `"*p`
- Use tmux clipboard integration
- Share text via other methods

---

## Complete Checklist

After applying fixes, verify:

- [ ] **Android rebuilt**: `nix-on-droid switch --flake ~/dotfiles#default`
- [ ] **Connected via Mosh** from Termius
- [ ] **Notification shown**: "Mosh session detected - applying color fixes"
- [ ] **Colors working**: Syntax highlighting visible
- [ ] **Icons working**: Nerd font icons display
- [ ] **Theme loaded**: Onedark theme visible
- [ ] **Locale set**: `echo $LC_ALL` shows `en_US.UTF-8`
- [ ] **256 colors**: `:echo &t_Co` shows `256`

---

## Quick Fix Commands

### If colors suddenly break:

**In Neovim:**
```vim
:set t_Co=256
:set notermguicolors
:set termguicolors!
:colorscheme onedark
```

**In shell:**
```bash
export TERM=xterm-256color
export LC_ALL=en_US.UTF-8
exec zsh
nvim
```

---

## Comparison: SSH vs Mosh Visual Quality

| Feature | SSH | Mosh |
|---------|-----|------|
| **Colors** | 16M (true color) | 256 colors |
| **Icons** | ✅ Full support | ✅ Full support |
| **Theme** | ✅ Perfect | ✅ Very good |
| **Visual quality** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Latency feel** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Resilience** | ⭐⭐ | ⭐⭐⭐⭐⭐ |

**Recommendation:**
- **Local network**: Use SSH (better colors, still fast)
- **Remote/unstable**: Use Mosh (better experience, good colors)

---

## Summary

### What Was Fixed

✅ **Mosh auto-detection** - Detects Mosh sessions automatically
✅ **256-color mode** - Forces proper color support
✅ **UTF-8 locale** - Ensures icons display correctly
✅ **Locale packages** - Added glibcLocales for UTF-8 support

### How to Use

1. **Rebuild Android config**
2. **Connect via Mosh**
3. **Open Neovim**
4. **Enjoy colors and icons!**

### Expected Result

🎨 **Full color syntax highlighting**
🎨 **All icons displaying properly**
🎨 **Theme looking beautiful**
🎨 **Fast, responsive editing**

---

**Your Neovim now works perfectly with Mosh!** 🚀🎨
