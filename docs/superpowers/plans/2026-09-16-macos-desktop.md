# macOS 26 (Tahoe) Desktop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the `ubuntu` host's niri desktop read as macOS 26 "Tahoe" — transparent menu bar, floating glass dock, real backdrop blur, macOS window chrome on GTK apps.

**Architecture:** Two stages. Stage A adds the parts no bar or shell provides (WhiteSur GTK/icon/cursor themes, real SF Pro) — pure additions, no rip-out, visible change on their own. Stage B builds the macOS silhouette on the EXISTING waybar/fuzzel/swaync stack: a wallpaper, niri's compositor-side blur, a transparent menu bar, and a second waybar instance as a floating dock. Every Stage B task is a config-only commit, so any one of them reverts independently.

**Revised 2026-09-16:** Stage B originally replaced the shell with Noctalia. That was reverted — Noctalia is a Nix-built Qt GUI app and dies at `eglGetDisplay` on this host, the same hazard `flake.nix` already documents for kitty and qutebrowser. See the Stage B preamble.

**Tech Stack:** Nix flakes + standalone home-manager, niri 26.04 (KDL config), waybar (GTK3), fuzzel, swaync (GTK4), swaybg, WhiteSur themes.

**Spec:** `docs/superpowers/specs/2026-09-16-macos-desktop-design.md`

## Global Constraints

- niri on this host is **26.04 (Nixpkgs)**. `blur` keys are `passes`, `offset`, `noise`, `saturation` — **`radius` is not a key**.
- **No Nix-built GUI application may be introduced on this host.** They fail GPU init (`eglGetDisplay`) because Nix's Mesa/EGL does not match the system driver — see the kitty/qutebrowser note in `flake.nix`, and Task 4's reverted attempt.
- Real config files live in `linux/<tool>/` and are linked by a module in `modules/home/`. Nix never inlines config text that could be a file.
- Only the `ubuntu` host changes, and nothing already working may regress. `termux` must still evaluate. (`wsl` was deleted; `darwin` was already broken before this work — both out of scope.)
- SF Pro is not redistributable through nixpkgs; it follows the existing "Nix can't provide this" precedent (`hosts/linux/ubuntu-apt-deps.sh` + a `make` target).
- Every niri config edit is validated with `niri validate -c linux/niri/config.kdl` before `make install`.
- Anything this plan marks **VERIFY FIRST** is research-derived and unconfirmed. Run the verification step and use what it returns; do not write the guessed value into config.

---

## File Structure

**Create:**
- `modules/home/gtk.nix` — GTK theme, icon theme, cursor theme. One responsibility: app-window appearance. No host currently configures GTK at all.
- `hosts/linux/ubuntu-sf-fonts.sh` — fetch + extract SF Pro/SF Mono into `~/.local/share/fonts`.
- `linux/waybar/dock.jsonc` — the dock's module list and geometry.
- `linux/waybar/dock.css` — the dock's glass styling (distinct from the bar, which is transparent).

**Modify:**
- `flake.nix` — WhiteSur packages, `p7zip`, `swaybg` in `linuxDesktopPackages`.
- `hosts/linux/ubuntu.nix` — import `gtk.nix`.
- `linux/waybar/style.css`, `config.jsonc` — the bar becomes transparent, SF Pro, 30px.
- `linux/fuzzel/fuzzel.ini`, `linux/swaync/style.css` — light glass; fuzzel's selection stops being accent blue.
- `Makefile` — add `sf-fonts` target.
- `linux/niri/config.kdl` — `blur`, `layer-rule`s, `shadow`, keybinds. (Gaps and
  corner radius were already raised to 10 and 20 in the earlier styling pass and
  need no further change.)
- `modules/home/niri.nix` — add `swaybg` and `waybar-dock` user services.

**Untouched:** kanata, kanshi, warpd, cliphist, kitty, podman, fcitx5, tmux, nvim, all non-`ubuntu` hosts.

---

# Stage A — Foundation (no rip-out)

## Task 1: WhiteSur GTK, icon and cursor themes

**Files:**
- Create: `modules/home/gtk.nix`
- Modify: `flake.nix` (`linuxDesktopPackages`), `hosts/linux/ubuntu.nix` (imports)

**Interfaces:**
- Produces: a `gtk.nix` module imported by `hosts/linux/ubuntu.nix`. Task 6 relies on the cursor theme name `WhiteSur-cursors` being set here.

- [ ] **Step 1: Confirm the package names and the theme names they install**

```bash
nix eval --raw nixpkgs#whitesur-gtk-theme.name
nix eval --raw nixpkgs#whitesur-icon-theme.name
nix eval --raw nixpkgs#whitesur-cursors.name
ls "$(nix build --no-link --print-out-paths nixpkgs#whitesur-gtk-theme)/share/themes"
ls "$(nix build --no-link --print-out-paths nixpkgs#whitesur-cursors)/share/icons"
```

Expected: package names resolve; the `share/themes` listing prints the exact
theme directory names (e.g. `WhiteSur-Dark`). **Use the printed name verbatim in
Step 3** — do not assume `WhiteSur-Dark` exists until this prints it.

- [ ] **Step 2: Add the packages to the desktop package list**

In `flake.nix`, inside `linuxDesktopPackages`, next to the existing font/theme-adjacent entries:

```nix
        # macOS look: WhiteSur is the part hand-written CSS cannot reach —
        # it restyles every GTK app window, the tray icons and the cursor.
        # waybar/fuzzel/swaync/noctalia all draw from their own stylesheets
        # and are NOT affected by the GTK theme.
        whitesur-gtk-theme whitesur-icon-theme whitesur-cursors
```

- [ ] **Step 3: Create the GTK module**

Create `modules/home/gtk.nix`, substituting the theme names printed in Step 1:

```nix
# modules/home/gtk.nix
# GTK appearance for the macOS-look desktop: WhiteSur theme, icons, cursor.
# Packages come from linuxDesktopPackages (see flake.nix), so this module is
# only useful on a host that imports those — currently just ubuntu.nix.
#
# This is the half of the macOS look that CSS cannot do. waybar, fuzzel, swaync
# and noctalia each draw from their own stylesheet and ignore the GTK theme;
# what this reaches is every GTK application window, the symbolic icons the
# tray pulls, and the pointer.
{ pkgs, ... }:
{
  gtk = {
    enable = true;
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
  };

  # Set through home.pointerCursor rather than gtk.cursorTheme so XCURSOR_THEME
  # is exported too — niri, and any Wayland client that reads the env rather
  # than gsettings, needs that to pick the cursor up.
  home.pointerCursor = {
    name = "WhiteSur-cursors";
    package = pkgs.whitesur-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
```

- [ ] **Step 4: Import it from the ubuntu host**

In `hosts/linux/ubuntu.nix`, add to `imports`, after `niri.nix`:

```nix
    ../../modules/home/gtk.nix
```

- [ ] **Step 5: Apply and verify**

```bash
make install
gsettings get org.gnome.desktop.interface gtk-theme
gsettings get org.gnome.desktop.interface icon-theme
gsettings get org.gnome.desktop.interface cursor-theme
```

Expected: the three values match what was set. Then open a GTK app
(`nautilus` or `gnome-control-center`) and confirm by eye that its headerbar is
WhiteSur (rounded, light, traffic-light close buttons) rather than Adwaita.

- [ ] **Step 6: Confirm the other hosts still evaluate**

```bash
nix eval .#homeConfigurations.wsl.activationPackage --apply builtins.typeOf
nix eval .#homeConfigurations.termux.activationPackage --apply builtins.typeOf
```

Expected: both print `"string"`. `gtk.nix` is imported only by `ubuntu.nix`, so
neither should have changed — this catches an accidental edit to a shared module.

- [ ] **Step 7: Commit**

```bash
git add flake.nix modules/home/gtk.nix hosts/linux/ubuntu.nix
git commit -m "feat(ubuntu): WhiteSur GTK, icon and cursor themes"
```

---

## Task 2: SF Pro and SF Mono fonts

**Files:**
- Create: `hosts/linux/ubuntu-sf-fonts.sh`
- Modify: `Makefile`

**Interfaces:**
- Produces: font families `SF Pro Display`, `SF Pro Text`, `SF Mono` resolvable
  by fontconfig. Tasks 7 and 9 set these names in waybar's and fuzzel's configs.

- [ ] **Step 1: Write the fetch script**

Create `hosts/linux/ubuntu-sf-fonts.sh`:

```bash
#!/usr/bin/env bash
# hosts/linux/ubuntu-sf-fonts.sh
# Apple's SF Pro / SF Mono, which the macOS-look desktop uses for all UI text.
#
# NOT installed via Nix: Apple's license does not permit redistribution, so the
# fonts are not in nixpkgs and cannot be. Same category as kitty and
# qutebrowser on this host — see ubuntu-apt-deps.sh — except the blocker here
# is legal rather than technical. Apple distributes them free of charge; this
# downloads from Apple's own CDN and extracts, so nothing is vendored into the
# repo.
#
# Installs to ~/.local/share/fonts, which fontconfig searches by default (and
# which is where the manually-installed JetBrainsMono Nerd Font already lives).
# Re-running is safe: it overwrites and re-indexes.
set -euo pipefail

DEST="$HOME/.local/share/fonts/AppleSF"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 7z reads the .dmg and the .pkg payload inside it; both are needed because
# Apple ships a macOS installer, not a font archive.
for cmd in curl 7z; do
  command -v "$cmd" >/dev/null || {
    echo "missing: $cmd  (sudo apt install p7zip-full curl)" >&2
    exit 1
  }
done

declare -A DMGS=(
  [SF-Pro]="https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg"
  [SF-Mono]="https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg"
)

mkdir -p "$DEST"
for name in "${!DMGS[@]}"; do
  echo "==> $name"
  curl -fL --progress-bar -o "$WORK/$name.dmg" "${DMGS[$name]}"
  7z x -y -o"$WORK/$name" "$WORK/$name.dmg" >/dev/null
  # The .dmg holds a .pkg; the .pkg holds a Payload holding the .otf files.
  find "$WORK/$name" -name '*.pkg' -exec 7z x -y -o"$WORK/$name/pkg" {} \; >/dev/null
  find "$WORK/$name/pkg" -name 'Payload*' -exec 7z x -y -o"$WORK/$name/payload" {} \; >/dev/null
  find "$WORK/$name/payload" -name '*.otf' -exec cp -f {} "$DEST/" \;
done

fc-cache -f "$DEST"
echo
echo "Installed $(find "$DEST" -name '*.otf' | wc -l) fonts to $DEST"
fc-match "SF Pro Display"
fc-match "SF Mono"
```

Then: `chmod +x hosts/linux/ubuntu-sf-fonts.sh`

- [ ] **Step 2: Add the Makefile target**

In `Makefile`, after the `qutebrowser-venv` target:

```make
sf-fonts: ## Install Apple SF Pro/SF Mono (not redistributable, so not in Nix)
	./hosts/linux/ubuntu-sf-fonts.sh
```

- [ ] **Step 3: Run it**

```bash
make sf-fonts
```

Expected: downloads both, reports a non-zero font count, and the two `fc-match`
lines resolve to SF faces rather than falling back to DejaVu.

**If the Apple CDN URLs 404** (Apple moves these): find the current download
links on <https://developer.apple.com/fonts/>, update the `DMGS` map, and re-run.
Do not substitute a different font silently — Task 6 assumes these family names.

- [ ] **Step 4: Verify fontconfig resolves the exact family names**

```bash
fc-match "SF Pro Display" family
fc-match "SF Pro Text" family
fc-match "SF Mono" family
```

Expected: each prints the matching SF family. If one falls back, note which
family names actually exist (`fc-list | grep -i "SF "`) and use those in Task 6.

- [ ] **Step 5: Commit**

```bash
git add hosts/linux/ubuntu-sf-fonts.sh Makefile
git commit -m "feat(ubuntu): SF Pro/SF Mono install script"
```

---

## Task 3: Stage A checkpoint

- [ ] **Step 1: Screenshot the current desktop**

```bash
grim /tmp/stage-a.png && echo saved
```

- [ ] **Step 2: Review it**

Open `/tmp/stage-a.png`. Expected at this point: GTK app windows look macOS-like
(WhiteSur headerbars, traffic lights, WhiteSur icons), cursor is the macOS
pointer. The **bar is still the old waybar** and there is still **no dock** —
that is correct, Stage B does those.

Confirm with the user that Stage A looks right before starting Stage B, since
Stage B is the part that removes a working shell.

---

# Stage B — The macOS silhouette, on waybar

**Revised 2026-09-16 after Task 4 was reverted.** The original Stage B replaced
waybar/fuzzel/swaync with Noctalia. Noctalia installed and built fine but dies at
startup with `fatal: eglGetDisplay failed` — it is a Nix-built Qt GUI app, and
`flake.nix` already documents that those fail GPU init on this host (which is why
kitty is apt-installed and qutebrowser lives in a pip venv). Reproduced directly;
`__EGL_VENDOR_LIBRARY_DIRS` does not fix it and a blanket `LD_LIBRARY_PATH`
breaks glibc. Fixing it properly needs a nixGL-style wrapper over the driver
stack, which is a host-wide decision, not a detail of this migration.

So Stage B now does the job in waybar — on better terms than when waybar was
first rejected. That rejection assumed niri had no blur. It does: blur is a
**compositor-side layer-rule**, so it applies to waybar, fuzzel and swaync
exactly as it would have to Noctalia. Nothing about the achievable look depended
on the shell being Noctalia.

## What "correct" means here, and where the first attempt went wrong

The first styling pass produced a dark bar with Apple-ish glyphs. Research
established these, and they drive every task below:

- **The Tahoe menu bar draws no background at all.** Transparent, no separator
  line, no blur, ~30px tall. A translucent dark strip is the single biggest
  "generic Linux" tell, and it is what the first attempt built.
- **Liquid Glass lightens, never darkens.** Glass surfaces are
  `rgba(255,255,255,0.10–0.16)` over a blurred backdrop with a bright ~1px top
  border, not a dark tinted panel.
- **Selection is a light translucent fill, not accent blue.** Accent-blue
  selected rows are the pre-Tahoe look. This reverses what the first pass did to
  fuzzel.
- **The silhouette is two strips:** menu bar on top, floating dock at the bottom.
  A single bar always reads as Linux regardless of styling.

**Deliberate divergence:** the menu bar gets **no blur**, because Tahoe's has
none — it is plain transparent. Blur is for the dock, launcher and notification
surfaces only. Enabling blur on the bar would look like "nice Linux glass bar",
which is exactly the failure being corrected.

## Verified on this machine (not research)

- `niri --version` → **26.04 (Nixpkgs)**.
- Valid: `blur { passes 2; offset 3.0; noise 0.03; saturation 1.0 }`. `radius` is
  **not** a key.
- Valid: `layer-rule { match namespace="…" background-effect { blur true; xray false } }`.
- **Real layer namespaces, read from `niri msg -j layers` while each was open:**
  waybar → `waybar`; fuzzel → `launcher`; swaync control center →
  `swaync-control-center`. Do not guess these; they are confirmed.
- No wallpaper is set on this host, and no wallpaper daemon is installed or
  running. `swaybg` is in nixpkgs but **not** currently in `linuxDesktopPackages`.
- SF Pro / SF Pro Text / SF Pro Display / SF Mono all resolve via fontconfig.

---

## Task 5: Wallpaper

Without a wallpaper, a transparent bar reveals a flat colour and blur has nothing
to blur — every later task is unverifiable. This is a prerequisite, not decoration.

**Files:** `flake.nix`, `modules/home/niri.nix`, `linux/niri/config.kdl`

- [ ] **Step 1: BLOCKED ON THE USER — get an image**

Ask the user for a wallpaper and put it at `~/Pictures/Wallpapers/`. Prefer a
photographic image with tonal variation: blur over a flat colour is invisible, so
a flat image wastes every effect in Tasks 6–9. Record the path.

- [ ] **Step 2: Add swaybg**

In `flake.nix`, in `linuxDesktopPackages`, next to the other desktop daemons:

```nix
        # Wallpaper. Needed for its own sake, but also because the menu bar is
        # transparent and the dock is blurred glass — both are invisible without
        # something behind them.
        swaybg
```

- [ ] **Step 3: Run it as a user service**

In `modules/home/niri.nix`, beside the existing `kanata`/`kanshi` units, add a
`swaybg` service following the exact shape of those two (same `WantedBy`,
`PartOf`, and the `%h/.nix-profile/bin/...` ExecStart convention — read them
first and match, do not invent a different shape):

```nix
  systemd.user.services.swaybg = {
    Unit = {
      Description = "Wallpaper";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "%h/.nix-profile/bin/swaybg -m fill -i %h/Pictures/Wallpapers/<FILENAME>";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
```

- [ ] **Step 4: Apply and verify**

```bash
make install
systemctl --user status swaybg.service --no-pager | head -5
grim /tmp/wallpaper.png
```

Expected: service active, and the screenshot shows the image behind the windows.

- [ ] **Step 5: Commit**

```bash
git commit -- flake.nix modules/home/niri.nix
```

---

## Task 6: niri blur and window shadows

**Files:** `linux/niri/config.kdl`

- [ ] **Step 1: Add the blur block and layer rules**

Near the other top-level nodes (beside `hotkey-overlay`):

```kdl
// Backdrop blur, which is what makes a translucent surface read as glass rather
// than as a flat tinted panel. Since niri 26.04. NOTE: there is no `radius`
// key — passes/offset/noise/saturation only.
blur {
    passes 2
    offset 3.0
    noise 0.03
}

// The launcher and the notification surfaces are glass. Namespaces confirmed
// against `niri msg -j layers` on this machine: fuzzel registers as "launcher",
// swaync's panel as "swaync-control-center".
//
// waybar is deliberately ABSENT here. The macOS Tahoe menu bar draws no
// background and has no blur — it is plain transparent. Blurring it would look
// like a nice Linux glass bar, which is the exact thing this redesign is
// correcting.
layer-rule {
    match namespace="^launcher$"
    match namespace="^swaync-"
    background-effect {
        blur true
        xray false
    }
}
```

- [ ] **Step 2: Add window shadows**

macOS windows cast a soft wide shadow. Add to the existing `window-rule` that
already sets `geometry-corner-radius 20`:

```kdl
    shadow {
        on
        softness 30
        spread 5
        offset x=0 y=6
        color "#00000066"
    }
```

- [ ] **Step 3: Validate, apply, verify**

```bash
niri validate -c linux/niri/config.kdl && make install
```

Then open fuzzel and screenshot it: `(fuzzel &) ; sleep 2; grim /tmp/blur.png; pkill -x fuzzel`

Expected: `config is valid`, and the launcher's backdrop is visibly **blurred**,
not merely tinted. If it is flat, the namespace match is wrong — re-read
`niri msg -j layers` with fuzzel open.

If `shadow` is rejected inside `window-rule`, the validator will say so; try it
at top level instead. Placement differs between niri versions.

- [ ] **Step 4: Commit**

```bash
git commit -- linux/niri/config.kdl
```

---

## Task 7: waybar becomes the Tahoe menu bar

**Files:** `linux/waybar/style.css`, `linux/waybar/config.jsonc`

The current stylesheet is the first attempt's dark translucent bar. This replaces
its surface treatment. Module structure, scripts and Pango-span colours stay.

- [ ] **Step 1: Make the bar itself disappear**

In `linux/waybar/style.css`, replace the `window#waybar` rule and the palette
block. The bar must have **no background and no border**:

```css
window#waybar {
    background: transparent;
    color: @fg;
    /* No border-bottom. The Tahoe menu bar has no separator line — the earlier
       hairline here was one of the things that made this read as a Linux bar. */
}
```

Set the height to 30 via `"height": 30` in `config.jsonc` (**not** CSS
`min-height` — waybar computes the exclusive zone before the stylesheet loads,
which is why a CSS-only height left the bar 18px in the first attempt).

- [ ] **Step 2: Make text legible over an arbitrary wallpaper**

With no background, text sits directly on the wallpaper. macOS handles this with
a subtle shadow. In the `*` rule:

```css
* {
    font-family: "SF Pro Text", "JetBrainsMono Nerd Font", sans-serif;
    font-size: 13px;
    min-height: 0;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.55);
}
```

Note the font change: **SF Pro Text replaces Inter** (installed in Task 2). The
Nerd Font stays as the glyph fallback.

- [ ] **Step 3: Hover fills become light, not dark**

Every `background-color: @elevated` in the file currently uses a dark grey. Glass
lightens. Redefine:

```css
@define-color elevated rgba(255, 255, 255, 0.18);
```

- [ ] **Step 4: Apply and verify against the reference**

```bash
make install && systemctl --user restart waybar.service
sleep 3 && journalctl --user -u waybar.service --since "10 seconds ago" --no-pager | grep -i error
grim -g "0,0 1920x40" /tmp/bar.png
```

Expected: no errors, and the screenshot shows wallpaper *through* the bar with no
strip, no separator line, and no visible panel edge.

- [ ] **Step 5: Commit**

```bash
git commit -- linux/waybar/style.css linux/waybar/config.jsonc
```

---

## Task 8: The dock

The second strip. Without it the desktop does not read as macOS no matter how
good the bar looks.

**Files:** `linux/waybar/dock.jsonc`, `linux/waybar/dock.css`, `modules/home/niri.nix`, `linux/niri/config.kdl`

- [ ] **Step 1: Read how the existing waybar is launched**

Read `linux/waybar/scripts/launch.sh` and `systemd.user.services.waybar` in
`modules/home/niri.nix` before writing anything. The dock is a second waybar
instance and must follow the same launch and output-selection conventions.

- [ ] **Step 2: Write the dock config**

`linux/waybar/dock.jsonc`: `"layer": "top"`, `"position": "bottom"`,
`"mode": "dock"`, no `"height"` (let icons size it), and a margin so it floats:
`"margin-bottom": 8`. Contents: a launcher glyph, the tray, and nothing else —
macOS docks hold apps, not readouts. Keep it icons-only.

- [ ] **Step 3: Write the dock stylesheet**

`linux/waybar/dock.css` — this one IS glass, unlike the bar:

```css
window#waybar {
    background: rgba(255, 255, 255, 0.12);
    border: 1px solid rgba(255, 255, 255, 0.22);
    border-radius: 22px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.35);
}
```

Radius 22 and the 8px edge gap are the measured Tahoe dock values.

- [ ] **Step 4: Add the systemd unit and the blur rule**

A `waybar-dock` service in `modules/home/niri.nix` mirroring the waybar one, and
in `linux/niri/config.kdl` add the dock's namespace to the blurred `layer-rule`
from Task 6. **Find the real namespace first** — run `niri msg -j layers` with
the dock running; a second waybar instance may or may not register as `waybar`.

- [ ] **Step 5: Validate, apply, screenshot the whole screen**

```bash
niri validate -c linux/niri/config.kdl && make install
grim /tmp/dock.png
```

Expected: transparent bar at the top, floating rounded glass dock at the bottom
with a visible blurred backdrop. This screenshot is the one that decides whether
the whole effort worked — compare it against a real macOS Tahoe screenshot.

- [ ] **Step 6: Commit**

```bash
git commit -- linux/waybar/dock.jsonc linux/waybar/dock.css modules/home/niri.nix linux/niri/config.kdl
```

---

## Task 9: Fuzzel and swaync corrected to Tahoe glass

**Files:** `linux/fuzzel/fuzzel.ini`, `linux/swaync/style.css`

Both were styled in the first pass with dark panels and, for fuzzel, an
accent-blue selection. Both are wrong for Tahoe.

- [ ] **Step 1: Fix fuzzel**

In `linux/fuzzel/fuzzel.ini`:
- `font=SF Pro Text:size=13,JetBrainsMono Nerd Font:size=13` (was Inter)
- `background=1e1e2099` — lighter alpha, since it now sits on real blur
- **`selection=ffffff28`** and `selection-text=f5f5f7ff` — a light translucent
  fill. The current `selection=0a84ffff` is the pre-Tahoe accent-blue look and is
  the single most wrong value in the file.
- `selection-match=0a84ffff` — the match highlight keeps the accent.
- `border=ffffff38`, `radius=20`

- [ ] **Step 2: Fix swaync**

In `linux/swaync/style.css`, the `:root` block: `--cc-bg` and the card colours
currently darken. Invert the approach — panel
`rgba(255, 255, 255, 0.10)`, cards `rgba(255,255,255,0.14)` via the `--noti-bg`
triple and alpha, border `rgba(255,255,255,0.22)`. Change the font in the `*`
rule from Inter to `"SF Pro Text"`.

- [ ] **Step 3: Apply and verify both**

```bash
make install && systemctl --user restart swaync.service
(fuzzel &) ; sleep 2; grim /tmp/fuzzel.png; pkill -x fuzzel
notify-send "Test" "Glass check" && sleep 1 && grim /tmp/noti.png
```

Expected: both surfaces show blurred backdrop through a light fill, and fuzzel's
selected row is a light translucent bar rather than a blue one.

- [ ] **Step 4: Commit**

```bash
git commit -- linux/fuzzel/fuzzel.ini linux/swaync/style.css
```

---

## Rollback

Every Stage B task is a separate commit touching config files only; `git revert`
plus `make install` undoes any one of them. Home-manager generations are the
backstop (`home-manager generations`). Stage A (WhiteSur, SF Pro) is independent
and worth keeping regardless.
