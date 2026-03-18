# Fix WSL & nix-on-droid New Machine Setup

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all known issues that cause failures when setting up on WSL and nix-on-droid (Android) as a new machine.

**Architecture:** Each fix is a targeted edit to a specific nix/bash file. No new abstractions introduced. Changes stay within the existing module/host structure: platform-specific fixes go in `hosts/linux/wsl.nix` or `hosts/android/default.nix`; shared fixes go in `flake.nix` or `bootstrap.sh`. All fixes are surgical — YAGNI, no refactoring beyond the problem.

**Tech Stack:** Nix flakes, home-manager (standalone), nix-on-droid, bash

---

## Chunk 1: bootstrap.sh fixes

### Task 1: Fix home-manager version mismatch in bootstrap.sh

**Files:**
- Modify: `bootstrap.sh`

**Problem:** `nix profile install nixpkgs#home-manager` installs whatever home-manager version is in nixpkgs HEAD, which differs from the `home-manager` input pinned in `flake.lock`. This causes `error: home-manager version mismatch` when running `home-manager switch`.

**Fix:** Use `nix run` instead of installing home-manager globally. This uses the flake's own pinned home-manager to apply the config.

- [ ] **Step 1: Replace `install_home_manager` function and update `apply_config` to use `nix run`**

In `bootstrap.sh`, replace the `install_home_manager` function:

```bash
# ─── Install home-manager ─────────────────────────────────────────────────────
install_home_manager() {
  # We use `nix run` from the flake itself so the home-manager version always
  # matches the pinned input in flake.lock — no global install needed.
  ok "home-manager will be applied via 'nix run' (no global install required)"
}
```

And update `apply_config` to use `nix run`:

```bash
# ─── Apply home-manager config ────────────────────────────────────────────────
apply_config() {
  log "Applying home-manager config for platform: $PLATFORM..."
  cd "$DOTFILES_DIR"

  case "$PLATFORM" in
    termux)
      nix run home-manager -- switch --flake .#termux
      ;;
    wsl)
      nix run home-manager -- switch --flake .#wsl
      ;;
    android)
      nix-on-droid switch --flake .
      ;;
    linux)
      nix run home-manager -- switch --flake .#ubuntu
      ;;
    *)
      die "Unknown platform: $PLATFORM"
      ;;
  esac

  ok "Configuration applied!"
}
```

- [ ] **Step 2: Add android detection to `detect_platform`**

Replace the existing `detect_platform` function:

```bash
detect_platform() {
  if [ -d /data/data/com.termux ]; then
    # Termux (standard) — check for nix-on-droid vs plain Termux
    if command -v nix-on-droid &>/dev/null; then
      echo "android"
    else
      echo "termux"
    fi
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "linux"
  fi
}
```

- [ ] **Step 3: Update main() to skip home-manager install step and add android to next-steps**

Update the `main()` next-steps output:

```bash
main() {
  echo ""
  echo "════════════════════════════════════════"
  echo "  dotfiles OTG bootstrap — $PLATFORM"
  echo "════════════════════════════════════════"
  echo ""

  install_nix
  clone_dotfiles
  setup_secrets
  apply_config

  echo ""
  echo "════════════════════════════════════════"
  ok "Bootstrap complete!"
  echo ""
  echo "  Next steps:"
  echo "    1. Restart your shell: exec zsh"
  if [ ! -f "$HOME/.config/sops/age/keys.txt" ]; then
    echo "    2. Copy age key, then: cd ~/dotfiles && make decrypt"
  fi
  echo "════════════════════════════════════════"
}
```

- [ ] **Step 4: Verify the script parses cleanly**

```bash
bash -n bootstrap.sh
```
Expected: no output (no syntax errors)

- [ ] **Step 5: Commit**

```bash
git add bootstrap.sh
git commit -m "fix(bootstrap): use nix run for home-manager to avoid version mismatch; add android detection"
```

---

## Chunk 2: WSL fixes

### Task 2: Fix WSL DISPLAY and remove clipse

**Files:**
- Modify: `hosts/linux/wsl.nix`
- Modify: `flake.nix`

**Problems:**
1. `DISPLAY=$(cat /etc/resolv.conf | ...)` unconditionally overwrites `DISPLAY` — on modern WSL2 with WSLg, the system already sets `DISPLAY` correctly and this breaks it. On WSL without GUI it produces a dangling value.
2. `clipse` (clipboard manager requiring Wayland/X11 compositor) is in `devPackages` which is used by WSL. It crashes on WSL without WSLg.

- [ ] **Step 1: Fix the DISPLAY export in `hosts/linux/wsl.nix` to be conditional**

Replace the `programs.zsh.initContent` block in `hosts/linux/wsl.nix`:

```nix
# WSL-specific shell config
programs.zsh.initContent = lib.mkAfter ''
  # WSL: Open browser via Windows default
  export BROWSER="wslview"

  # Fix DISPLAY for GUI apps — only set if not already provided by WSLg
  if [ -z "$DISPLAY" ] && [ -f /etc/resolv.conf ]; then
    export DISPLAY=$(awk '/nameserver/{print $2; exit}' /etc/resolv.conf):0.0
  fi
'';
```

- [ ] **Step 2: Remove `clipse` from `devPackages` in `flake.nix` and add it to `darwinPackages` only**

In `flake.nix`, remove `clipse` from `devPackages`:

```nix
# Dev packages — installed on Linux (Ubuntu/WSL) and macOS, NOT Termux
devPackages = pkgs: with pkgs; [
  # Languages
  nodejs go delve goimports-reviser
  cargo rustc rustfmt clippy rust-analyzer
  python3 pipx

  # Cloud & DB
  terraform
  postgresql_16 mysql80 pgcli pspg

  # Utilities
  imagemagick
  # clipse removed — requires Wayland/X11 compositor; added to darwinPackages instead
];
```

Add `clipse` to `darwinPackages`:

```nix
# macOS-specific packages
darwinPackages = pkgs: with pkgs; [
  clipboard-jh
  clipse
  nerd-fonts.jetbrains-mono
];
```

- [ ] **Step 3: Add `wslu` to WSL packages so `wslview` is available via Nix**

In `hosts/linux/wsl.nix`, add a WSL-specific package list:

```nix
# hosts/linux/wsl.nix
# Home-manager config for WSL (Windows Subsystem for Linux)
{ pkgs, lib, sharedPackages, ... }:
{
  home.username = "nhath";
  home.homeDirectory = "/home/nhath";
  home.stateVersion = "24.11";

  _module.args.sharedPackages = sharedPackages;

  # WSL-specific packages
  home.packages = [ pkgs.wslu ];

  # WSL-specific shell config
  programs.zsh.initContent = lib.mkAfter ''
    # WSL: Open browser via Windows default
    export BROWSER="wslview"

    # Fix DISPLAY for GUI apps — only set if not already provided by WSLg
    if [ -z "$DISPLAY" ] && [ -f /etc/resolv.conf ]; then
      export DISPLAY=$(awk '/nameserver/{print $2; exit}' /etc/resolv.conf):0.0
    fi
  '';
}
```

- [ ] **Step 4: Check flake syntax**

```bash
nix flake check --no-build 2>&1 | head -40
```
Expected: no parse errors (evaluation errors about missing secrets are OK)

- [ ] **Step 5: Commit**

```bash
git add hosts/linux/wsl.nix flake.nix
git commit -m "fix(wsl): conditional DISPLAY, add wslu, move clipse to darwin-only"
```

---

## Chunk 3: nix-on-droid package list fixes

### Task 3: Remove packages that fail or are useless on nix-on-droid

**Files:**
- Modify: `hosts/android/default.nix`

**Problems:**
- `mysql80` — does not build on aarch64-linux (Android). Will cause build failure.
- `dbus` — requires system D-Bus daemon. Not available in nix-on-droid userspace. Installs but errors at runtime.
- `tailscale` — needs kernel TUN + root daemon. Cannot run on nix-on-droid.
- `mosh` — needs utempter/utmp write access. Fails silently or errors on Android.
- `mycli` — was already removed from macOS devPackages due to pyarrow build issues; same issue applies on aarch64.
- `gradle` / `maven` — very heavy JVM build tools; rarely needed on a phone and slow to build on aarch64.

- [ ] **Step 1: Remove problematic packages from `environment.packages` in `hosts/android/default.nix`**

Replace the `environment.packages` block:

```nix
# All packages must be here for Android (not in home.packages)
# due to nix-env/nix profile compatibility issues
environment.packages = with pkgs; [
  # Editor & Terminal
  neovim
  tmux

  # Core utilities
  git
  gh
  fzf
  ripgrep
  fd
  jq
  jless
  procps
  gnugrep
  gnused
  gawk
  coreutils
  ncurses

  # Development
  go
  gcc
  gnumake
  nodejs
  delve
  goimports-reviser
  # maven/gradle removed — heavy JVM tools, slow on aarch64, use project-specific nix shells instead

  # Rust
  cargo
  rustc
  rustfmt
  clippy
  rust-analyzer

  # Python
  python3
  pipx

  # Shell
  zsh
  oh-my-zsh

  # Network
  openssh
  net-tools
  # mosh removed — requires utempter/utmp which is unavailable in nix-on-droid
  # tailscale removed — requires kernel TUN + root daemon, cannot run on nix-on-droid

  # Secrets
  sops
  age
  yq-go

  # Databases
  postgresql
  # mysql80 removed — does not build on aarch64-linux
  # mycli removed — pyarrow build issues on aarch64 (same as macOS)
  pgcli
  # pspg — doesn't work on Android/Termux

  # HTTP
  httpie
  hurl

  # Diff/formatting
  delta
  diff-so-fancy

  # Utilities
  fx
  terraform
  direnv
  lazygit
  curl
  # dbus removed — requires system D-Bus daemon unavailable in nix-on-droid
];
```

- [ ] **Step 2: Check nix-on-droid flake evaluation (dry run)**

```bash
nix eval .#nixOnDroidConfigurations.default.config.environment.packages --apply 'pkgs: builtins.length pkgs' 2>&1 | tail -5
```
Expected: a number (count of packages), no evaluation errors

- [ ] **Step 3: Commit**

```bash
git add hosts/android/default.nix
git commit -m "fix(android): remove packages that fail or are unusable on nix-on-droid (mysql80, dbus, tailscale, mosh, mycli)"
```

---

## Chunk 4: Add nix-on-droid binary cache

### Task 4: Add nix-on-droid cachix to Android config

**Files:**
- Modify: `modules/platforms/android.nix`

**Problem:** `nix-community.cachix.org` is listed but `nix-on-droid.cachix.org` is missing. This cache contains pre-built nix-on-droid-specific packages. Without it, every `nix-on-droid switch` on a new device compiles everything from source — extremely slow on a phone (hours vs minutes).

- [ ] **Step 1: Add nix-on-droid cache to `modules/platforms/android.nix`**

Replace the `nix` block in `modules/platforms/android.nix`:

```nix
nix = {
  extraOptions = ''
    experimental-features = nix-command flakes
  '';
  substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://nix-on-droid.cachix.org"
  ];
  trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqvHJ9XCp+nidK7qkMQrU="
  ];
};
```

- [ ] **Step 2: Verify nix syntax**

```bash
nix-instantiate --parse modules/platforms/android.nix
```
Expected: AST output without errors

- [ ] **Step 3: Commit**

```bash
git add modules/platforms/android.nix
git commit -m "fix(android): add nix-on-droid.cachix.org binary cache for faster new-device setup"
```

---

## Chunk 5: Final validation

### Task 5: Validate all changes together

- [ ] **Step 1: Run flake check (no build)**

```bash
nix flake check --no-build 2>&1 | grep -v "^warning" | head -40
```
Expected: no parse/evaluation errors

- [ ] **Step 2: Dry-run WSL config build**

```bash
nix build .#homeConfigurations.wsl.activationPackage --dry-run 2>&1 | tail -10
```
Expected: lists derivations to build, no errors

- [ ] **Step 3: Dry-run Ubuntu config build (sanity check devPackages)**

```bash
nix build .#homeConfigurations.ubuntu.activationPackage --dry-run 2>&1 | tail -10
```
Expected: lists derivations to build, no errors

- [ ] **Step 4: Verify bootstrap.sh is valid bash**

```bash
bash -n bootstrap.sh && echo "OK: no syntax errors"
```
Expected: `OK: no syntax errors`

- [ ] **Step 5: Final commit (if any loose changes remain)**

```bash
git status
# Only commit if there are uncommitted changes
git add -p
git commit -m "chore: final cleanup after wsl/android setup fixes"
```
