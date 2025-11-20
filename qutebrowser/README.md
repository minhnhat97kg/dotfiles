# Qutebrowser Multi-Profile Setup

This configuration enables running multiple isolated instances of qutebrowser with separate sessions, history, cookies, and cache.

## Quick Start

After rebuilding your Nix configuration, you can launch qutebrowser profiles using these commands:

```bash
# Launch default profile
qb

# Launch specific profiles
qb-personal
qb-work
qb-dev

# Or use the script directly
qb-profile personal
qb-profile work
qb-profile dev
```

## What's Isolated Per Profile?

Each profile maintains separate:
- **Session state** (open tabs and windows)
- **Browsing history**
- **Cookies and local storage**
- **Cache**
- **Download history**
- **Saved sessions**

## What's Shared Across Profiles?

All profiles share:
- **Configuration** (`config.py` with theme and keybindings)
- **Bookmarks** (can be separated if needed)
- **Quickmarks**
- **Custom userscripts**

## Profile Locations

- **Config**: `~/.config/qutebrowser/config.py` (shared)
- **Profile data**: `~/.local/share/qutebrowser/profiles/<profile-name>/`

Each profile directory contains:
```
~/.local/share/qutebrowser/profiles/
├── default/
│   ├── data/       # cookies, local storage
│   ├── cache/
│   └── sessions/
├── personal/
│   └── ...
├── work/
│   └── ...
└── dev/
    └── ...
```

## Available Profiles

As defined in `profiles.yaml`:

- **default** 🌐 - Default browsing profile
- **personal** 👤 - Personal browsing
- **work** 💼 - Work-related browsing
- **dev** 🔧 - Development and testing

## Adding New Profiles

1. Edit `qutebrowser/profiles.yaml` to add your profile definition
2. Launch with: `qb-profile <new-profile-name>`
3. (Optional) Add an alias in `shell/aliases.yaml`:
   ```yaml
   qb-myprofile: "qb-profile myprofile"
   ```

## Advanced Usage

### Passing Additional Arguments

You can pass qutebrowser arguments after the profile name:

```bash
qb-profile work https://github.com
qb-profile dev --temp-basedir  # Temporary profile
```

### Profile-Specific Configurations

If you need profile-specific settings (different themes, keybindings, etc.), you can:

1. Create profile-specific config files:
   ```bash
   mkdir -p ~/.config/qutebrowser/profiles
   cp ~/.config/qutebrowser/config.py ~/.config/qutebrowser/profiles/work.py
   ```

2. Modify the launcher script to use profile-specific configs when available

### Checking Current Profile

You can identify which profile you're using by checking the window title or running:
```
:message-info "Profile: <profile-name>"
```

## Troubleshooting

### Profile not starting
- Ensure `~/.local/bin` is in your PATH
- Check that `qb-profile` is executable: `chmod +x ~/.local/bin/qb-profile`

### Shared data between profiles
- Each profile's data is isolated in `~/.local/share/qutebrowser/profiles/`
- If you see shared data, check that you're launching with the profile script

### Reset a profile
```bash
rm -rf ~/.local/share/qutebrowser/profiles/<profile-name>
```

## Integration with Nix

The profile system is integrated with your Nix configuration in `flake.nix`:

- Config file: `home.file.".config/qutebrowser/config.py"`
- Profile metadata: `home.file.".config/qutebrowser/profiles.yaml"`
- Launcher script: `home.file.".local/bin/qb-profile"`
- Shell aliases: Defined in `shell/aliases.yaml`

After modifying any qutebrowser files, rebuild with:
```bash
darwin-rebuild switch --flake .#Nhaths-MacBook-Pro
```
