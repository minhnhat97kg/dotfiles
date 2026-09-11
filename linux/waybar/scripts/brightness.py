#!/usr/bin/env python3
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from barutil import SYM_BRIGHT, fmt, readout

percent = int(sys.argv[1])

print(
    json.dumps(
        {
            "text": readout(SYM_BRIGHT, fmt(percent)),
            "tooltip": f"Brightness: {percent}%",
        }
    )
)
