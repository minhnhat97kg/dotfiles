#!/usr/bin/env bash
# Clipboard history picker: pick a past clipboard entry via fuzzel and copy it
# back. Populated by the cliphist watcher (systemd --user cliphist.service).
# Bound to Mod+Shift+C in niri.
set -euo pipefail

cliphist list \
  | fuzzel --dmenu --with-nth 2 --prompt 'Clipboard: ' \
  | cliphist decode \
  | wl-copy
