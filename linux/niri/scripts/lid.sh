#!/usr/bin/env bash
# Laptop lid switch handler, wired to niri's switch-events (see config.kdl).
#
# niri (25.08+) natively turns the built-in panel OFF on lid-close and back ON
# on lid-open, and keeps it on when it is the ONLY active output. We used to
# drive that toggle ourselves too, which just fought the compositor and is why
# the settle-polling below had to exist. Now this handler only does the parts
# niri can't:
#
#   close -> once niri has dropped the built-in, slide the dock monitor into the
#            built-in's vacated slot
#   open  -> move the dock monitor back home before niri re-enables the built-in
#
# ...and in both cases restart waybar so its launcher re-picks the active output:
# the bar binds to a single connector, so it lives on the built-in when the lid
# is open and hops to an external monitor when the lid is closed.
#
# Monitors are addressed by NAME (niri's "make model serial" descriptor), never
# by connector (eDP-1, DP-1, DP-2): connectors shuffle when the dock re-enumerates
# its outputs, but the monitor identity is stable.
set -euo pipefail

BUILTIN="BOE 0x0AFC Unknown"                # the laptop's built-in panel
DOCK="DO NOT USE - RTK 0x2775 0x20230923"   # RTK dock / capture monitor

# The dock's two positions. Home = centered under the two Dells on row 2
# (matches kanshi/config's "docked" profile). While the lid is shut it takes
# over the built-in's vacated slot to the dock's right (2987,1080).
DOCK_HOME_X=854;  DOCK_HOME_Y=1080
DOCK_LID_X=2987;  DOCK_LID_Y=1080

# niri keys `outputs` by connector; the monitor name is make/model/serial, with
# "Unknown" standing in for a missing serial. These helpers match on that name.

# True if some monitor OTHER than the built-in is currently active. This decides
# whether niri will actually drop the built-in on close (it won't if the built-in
# is the only display) — i.e. whether there's anything for this handler to do.
external_active() {
    niri msg -j outputs | BUILTIN="$BUILTIN" python3 -c '
import json, os, sys
builtin = os.environ["BUILTIN"]
outs = json.load(sys.stdin)
def name(o): return "%s %s %s" % (o.get("make"), o.get("model"), o.get("serial") or "Unknown")
n = sum(1 for o in outs.values() if name(o) != builtin and o.get("logical"))
sys.exit(0 if n else 1)
'
}

# True if the named monitor is currently active (has a logical region).
output_active() {
    niri msg -j outputs | NAME="$1" python3 -c '
import json, os, sys
target = os.environ["NAME"]
outs = json.load(sys.stdin)
def name(o): return "%s %s %s" % (o.get("make"), o.get("model"), o.get("serial") or "Unknown")
sys.exit(0 if any(name(o) == target and o.get("logical") for o in outs.values()) else 1)
'
}

# Wait until niri's built-in panel reaches state `want` (on|off), so we don't
# restart waybar while niri is still applying its own lid toggle. Without this,
# the launcher can still see the built-in as active, bake waybar onto it, and the
# bar then renders on a dying output -> no visible bar.
wait_for_builtin() {
    local want="$1" i state
    for i in $(seq 1 50); do   # up to ~5s
        state="$(niri msg -j outputs | BUILTIN="$BUILTIN" python3 -c '
import json, os, sys
builtin = os.environ["BUILTIN"]
outs = json.load(sys.stdin)
def name(o): return "%s %s %s" % (o.get("make"), o.get("model"), o.get("serial") or "Unknown")
on = any(name(o) == builtin and o.get("logical") for o in outs.values())
print("on" if on else "off")
')"
        [ "$state" = "$want" ] && return 0
        sleep 0.1
    done
    return 0   # give up gracefully; restart anyway
}

case "${1:-}" in
    close)
        if external_active; then
            wait_for_builtin off   # niri is dropping the built-in; wait for it
            # Slide the dock into the built-in's now-empty slot (if present).
            if output_active "$DOCK"; then
                niri msg output "$DOCK" position set "$DOCK_LID_X" "$DOCK_LID_Y"
            fi
        else
            echo "lid.sh: no external output active, niri keeps built-in on" >&2
            exit 0   # nothing changed, so no waybar restart needed
        fi
        ;;
    open)
        # Move the dock home first so it doesn't overlap the built-in on power-on.
        if output_active "$DOCK"; then
            niri msg output "$DOCK" position set "$DOCK_HOME_X" "$DOCK_HOME_Y"
        fi
        wait_for_builtin on   # niri re-enables the built-in; wait for it
        ;;
    *) echo "usage: lid.sh {close|open}" >&2; exit 1 ;;
esac

systemctl --user restart waybar.service
