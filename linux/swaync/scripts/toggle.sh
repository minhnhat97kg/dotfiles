#!/usr/bin/env bash
# Toggles for the swaync buttons-grid, plus the label sync that draws their state.
#
# STATE IS DRAWN WITH CHARACTERS, NOT CSS. A button reads "[x] Wifi" when on and
# "[ ] Wifi" when off, the same way the bar spells its state with [·] / [3] / [-]
# rather than by recolouring. swaync has no command-driven label widget (verified
# against the 0.12.6 schema: every widget's `label`/`text` is a static string), so
# the only way to get a live character is to rewrite the label in the config and
# reload — `swaync-client -R` re-renders button labels, which is what makes this
# work at all.
#
# That is why swaync runs against a RUNTIME COPY of config.json (see launch.sh):
# the managed ~/.config/swaync/config.json is a read-only nix store symlink and
# cannot be edited in place. Same trick as waybar's launch.sh.
#
# Because the label is the indicator, these are `normal` buttons, not `toggle`
# ones — there is no :checked state to style and no update-command to keep in
# step. The trade-off: a change made OUTSIDE this script (e.g. `nmcli radio wifi
# off` in a terminal) will not redraw the label until the next click or restart.
#
# Usage: toggle.sh <wifi|bluetooth|dnd> <toggle|get>
#        toggle.sh sync [--no-reload]
set -euo pipefail

RUNTIME_CFG="${XDG_RUNTIME_DIR:-/tmp}/swaync/config.json"

# Every query is wrapped in `timeout` because this script runs on the service
# startup path (launch.sh seeds the labels before exec'ing swaync) and MUST NOT
# be able to block it.
#
# The dnd case is the one that actually bit: `swaync-client -D` waits for the
# org.erikreider.swaync.cc bus name, which does not exist yet while launch.sh is
# still running — so the launcher blocked forever waiting on the daemon it was
# about to exec, and swaync never started at all. A bounded wait plus the
# "false" default is correct either way, since swaync always begins with dnd off.
state() {
  case "$1" in
    wifi)      [ "$(timeout 2 nmcli radio wifi 2>/dev/null)" = "enabled" ] && echo true || echo false ;;
    bluetooth) timeout 2 bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo true || echo false ;;
    dnd)       timeout 1 swaync-client -D 2>/dev/null || echo false ;;
  esac
}

# Rewrite every state-carrying label in the runtime config from live state, then
# ask swaync to re-read it. --no-reload is for launch.sh, before swaync is up.
sync_labels() {
  [ -f "$RUNTIME_CFG" ] || return 0
  DND="$(state dnd)" WIFI="$(state wifi)" BT="$(state bluetooth)" \
  CFG="$RUNTIME_CFG" python3 - <<'PY'
import json, os
cfg_path = os.environ["CFG"]
mark = lambda on: "[x]" if on == "true" else "[ ]"
labels = {
    "dnd":       f'{mark(os.environ["DND"])} Do Not Disturb',
    "wifi":      f'{mark(os.environ["WIFI"])} Wifi',
    "bluetooth": f'{mark(os.environ["BT"])} Bluetooth',
}
with open(cfg_path) as f:
    cfg = json.load(f)
# Match buttons by the command they run, so renaming a label never breaks this.
for grid in cfg.get("widget-config", {}).values():
    for act in grid.get("actions", []) if isinstance(grid, dict) else []:
        cmd = act.get("command", "")
        for key, text in labels.items():
            if f"toggle.sh {key} toggle" in cmd:
                act["label"] = text
with open(cfg_path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
  [ "${1:-}" = "--no-reload" ] || swaync-client -R >/dev/null 2>&1 || true
}

case "${1:-}/${2:-}" in
  wifi/toggle)
    [ "$(state wifi)" = "true" ] && nmcli radio wifi off || nmcli radio wifi on
    sync_labels ;;
  bluetooth/toggle)
    [ "$(state bluetooth)" = "true" ] && bluetoothctl power off || bluetoothctl power on
    sync_labels ;;
  # -dn/-df rather than -d so the requested state is explicit and cannot drift.
  dnd/toggle)
    # -dn/-df echo the new state; silenced so a button click leaves no stray
    # output for swaync's script-fail-notify to pick up.
    if [ "$(state dnd)" = "true" ]; then swaync-client -df -sw >/dev/null
    else swaync-client -dn -sw >/dev/null; fi
    sync_labels ;;

  wifi/get|bluetooth/get|dnd/get)
    state "$1" ;;

  sync/*)
    sync_labels "${2:-}" ;;
  *)
    echo "usage: ${0##*/} <wifi|bluetooth|dnd> <toggle|get> | sync [--no-reload]" >&2
    exit 2 ;;
esac
