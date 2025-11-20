#!/bin/bash
# Front app plugin
# Use provided $INFO (fast) or fallback if empty
APP="$INFO"
if [ -z "$APP" ]; then
  # Fallback using lsappinfo (no AppleScript permissions needed)
  APP=$(lsappinfo front | awk -F '"' '/"name"/ {print $4; exit}')
fi
# Fallback if NAME not provided (manual test run)
[ -z "$NAME" ] && NAME=front_app
sketchybar --set $NAME label="$APP"