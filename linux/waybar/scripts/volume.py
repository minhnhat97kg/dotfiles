#!/usr/bin/env python3
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from barutil import SYM_VOLUME, fmt, readout

percent = int(sys.argv[1])
muted = sys.argv[2] == "true"

# "--" rather than the level: while muted the number is not actionable, and the
# dashes read as "off" without needing a colour to say it.
value = "--" if muted else fmt(percent)

print(
    json.dumps(
        {
            "text": readout(SYM_VOLUME, value),
            "tooltip": f"Volume: {percent}%" + (" (muted)" if muted else ""),
            "class": "muted" if muted else "",
        }
    )
)
