# Git Configuration

## Files

- `gitconfig` - Main git configuration (aliases, delta, difftool, etc.)
- `minhnhat97kg.gitconfig` - Personal git identity for ~/projects/** directories
- `work.gitconfig.template` - Template for work git identity
- `gitignore_global` - Global gitignore patterns

## Setup Work Configuration

The work.gitconfig is used for repositories in `~/work/**` directories.

1. Create your work config from the template:
   ```bash
   cp git/work.gitconfig.template git/work.gitconfig
   ```

2. Edit `git/work.gitconfig` with your work email and name:
   ```bash
   nvim git/work.gitconfig
   ```

3. Rebuild nix configuration:
   ```bash
   make install
   ```

The work.gitconfig file is gitignored so your work email won't be committed to the repository.

## Git Identity by Directory

The configuration automatically uses different git identities based on directory:

- `~/work/**` → `work.gitconfig` (work email/name)
- `~/projects/**` → `minhnhat97kg.gitconfig` (personal email/name)
- Default → `gitconfig` (no user settings, will prompt)
