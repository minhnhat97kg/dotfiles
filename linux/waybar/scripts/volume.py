#!/usr/bin/env python3
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from barutil import render_bar

ICON_MUTED = chr(0xF026)
ICON_LOW = chr(0xF027)
ICON_HIGH = chr(0xF028)

percent = int(sys.argv[1])
muted = sys.argv[2] == "true"
expanded = os.path.exists(os.path.expanduser("~/.cache/waybar/volume_expanded"))

if muted:
    icon = ICON_MUTED
elif percent < 50:
    icon = ICON_LOW
else:
    icon = ICON_HIGH

if expanded:
    rows = render_bar(percent)
    text = icon + "\n" + "\n".join(rows)
else:
    text = icon

klass = "muted" if muted else ""
print(json.dumps({"text": text, "tooltip": f"Volume: {percent}%", "class": klass}))
