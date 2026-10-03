#!/usr/bin/env bash
set -euo pipefail
percent="$(brightnessctl -d intel_backlight -m | cut -d, -f4 | tr -d '%')"
exec python3 "$(dirname "$0")/brightness.py" "$percent"
