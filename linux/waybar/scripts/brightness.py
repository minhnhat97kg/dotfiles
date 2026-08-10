#!/usr/bin/env python3
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from barutil import render_bar

ICON = chr(0xF185)  # fa-sun_o

percent = int(sys.argv[1])
expanded = os.path.exists(os.path.expanduser("~/.cache/waybar/brightness_expanded"))

if expanded:
    rows = render_bar(percent)
    text = ICON + "\n" + "\n".join(rows)
else:
    text = ICON

print(json.dumps({"text": text, "tooltip": f"Brightness: {percent}%"}))
