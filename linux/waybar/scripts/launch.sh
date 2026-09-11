#!/usr/bin/env bash
# Launch waybar on the "active" monitor, chosen by monitor NAME (niri's
# "make model serial" descriptor) rather than by connector, since connectors
# shuffle when the dock re-enumerates its outputs. Preference order: the built-in
# panel when it is on, else the dock, else the first remaining active monitor.
#
# waybar can only bind a bar to a CONNECTOR name (it does not match monitor
# descriptions), so we resolve the chosen monitor's *current* connector and bake
# that into a runtime copy of the config. That connector is also exported as
# WAYBAR_OUTPUT_NAME so per-output modules (e.g. workspaces.sh) filter correctly.
# We then exec waybar so systemd supervises the real waybar process.
#
# Re-run this (via `systemctl --user restart waybar.service`) whenever the set
# of active outputs changes — e.g. the lid handler does so on open/close.
set -euo pipefail

CONFIG_DIR="$HOME/.config/waybar"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar"
mkdir -p "$RUNTIME_DIR"
RUNTIME_CFG="$RUNTIME_DIR/config.jsonc"

# Monitor-name preferences, most-preferred first. A monitor name is niri's
# "make model serial" descriptor ("Unknown" for a missing serial).
BUILTIN="BOE 0x0AFC Unknown"
DOCK="DO NOT USE - RTK 0x2775 0x20230923"

# Resolve preferences to the connector of the first active matching monitor.
target="$(niri msg -j outputs | BUILTIN="$BUILTIN" DOCK="$DOCK" python3 -c '
import json, os, sys
outs = json.load(sys.stdin)
def name(o): return "%s %s %s" % (o.get("make"), o.get("model"), o.get("serial") or "Unknown")
# connector -> monitor name, active outputs only (off outputs have null logical)
active = {conn: name(o) for conn, o in outs.items() if o.get("logical")}
# 1) preferred monitor names, in order
for want in (os.environ["BUILTIN"], os.environ["DOCK"]):
    for conn, nm in active.items():
        if nm == want:
            print(conn); sys.exit()
# 2) any remaining active output (stable order)
if active:
    print(sorted(active)[0]); sys.exit()
# 3) nothing active: fall back to the built-in connector if known, else eDP-1
for conn, o in outs.items():
    if name(o) == os.environ["BUILTIN"]:
        print(conn); sys.exit()
print("eDP-1")
')"

# Copy the managed config, overriding just the single top-level "output" value.
sed "s#\"output\": *\"[^\"]*\"#\"output\": \"${target}\"#" \
    "$CONFIG_DIR/config.jsonc" > "$RUNTIME_CFG"

# Per-output modules inherit this to know which connector the bar lives on.
export WAYBAR_OUTPUT_NAME="$target"

exec waybar -c "$RUNTIME_CFG" -s "$CONFIG_DIR/style.css"
