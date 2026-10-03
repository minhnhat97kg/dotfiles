#!/usr/bin/env python3
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from barutil import SYM_VOLUME_HIGH, SYM_VOLUME_LOW, SYM_VOLUME_MUTE, fmt, readout

percent = int(sys.argv[1])
muted = sys.argv[2] == "true"

# The icon itself carries mute/level, like a macOS speaker glyph — not just
# one fixed note icon with a number next to it.
if muted or percent == 0:
    symbol = SYM_VOLUME_MUTE
elif percent < 50:
    symbol = SYM_VOLUME_LOW
else:
    symbol = SYM_VOLUME_HIGH

# "--" rather than the level: while muted the number is not actionable, and the
# dashes read as "off" without needing a colour to say it.
value = "--" if muted else fmt(percent)

print(
    json.dumps(
        {
            "text": readout(symbol, value),
            "tooltip": f"Volume: {percent}%" + (" (muted)" if muted else ""),
            "class": "muted" if muted else "",
        }
    )
)
