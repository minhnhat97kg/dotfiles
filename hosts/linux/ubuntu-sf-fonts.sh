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
# Re-running is safe: it overwrites existing files and re-indexes. It does NOT
# delete anything, so if Apple ever renames a font file the old name would be
# left behind alongside the new one — low-impact, so not worth deleting for.
set -euo pipefail

DEST="$HOME/.local/share/fonts/AppleSF"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 7z reads the .dmg and the .pkg payload inside it; both are needed because
# Apple ships a macOS installer, not a font archive. 7z comes from p7zip in
# linuxDesktopPackages (packages.nix).
for cmd in curl 7z; do
  command -v "$cmd" >/dev/null || {
    echo "missing: $cmd  (run 'make install' / 'home-manager switch' — p7zip is in linuxDesktopPackages, flake.nix)" >&2
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
  stage="$WORK/$name"
  curl -fL --progress-bar -o "$stage.dmg" "${DMGS[$name]}"

  # The two dmgs are laid out differently (verified by hand against both
  # downloads): SF-Pro.dmg is an APFS image 7z unwraps in one pass straight to
  # a "Payload" cpio archive; SF-Mono.dmg is an HFS+ image that instead leaves
  # a .pkg file (itself an xar wrapping a gzipped "Payload" cpio) needing one
  # more extraction pass. Handle both by extracting the dmg, then extracting
  # a leftover .pkg if the payload isn't there yet, then always finishing with
  # an explicit cpio extraction (7z doesn't auto-detect cpio without -tcpio).
  mkdir -p "$stage/1"
  7z x -y -o"$stage/1" "$stage.dmg" >/dev/null
  payload="$(find "$stage/1" -name 'Payload*' -print -quit)"
  if [ -z "$payload" ]; then
    pkg="$(find "$stage/1" -name '*.pkg' -print -quit)"
    mkdir -p "$stage/2"
    7z x -y -o"$stage/2" "$pkg" >/dev/null
    payload="$(find "$stage/2" -name 'Payload*' -print -quit)"
  fi
  [ -n "$payload" ] || { echo "could not find Payload in $name.dmg" >&2; exit 1; }

  mkdir -p "$stage/fonts"
  7z x -y -tcpio -o"$stage/fonts" "$payload" >/dev/null

  # `find -exec` exits 0 even with zero matches, so a copy count of 0 (e.g.
  # Apple changes the payload's internal layout) would otherwise fall through
  # silently to "Installed 0 fonts" and a successful exit. Count what was
  # actually copied and fail loudly if it's zero.
  copied=0
  while IFS= read -r -d '' otf; do
    cp -f "$otf" "$DEST/"
    copied=$((copied + 1))
  done < <(find "$stage/fonts" -name '*.otf' -print0)
  [ "$copied" -gt 0 ] || {
    echo "no .otf files found in $name's payload (layout may have changed)" >&2
    exit 1
  }
done

fc-cache -f "$DEST"
echo
echo "Installed $(find "$DEST" -name '*.otf' | wc -l) fonts to $DEST"
fc-match "SF Pro Display"
fc-match "SF Mono"
