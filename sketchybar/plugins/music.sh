#!/bin/bash
# Music (Now Playing) plugin
INFO=$(osascript <<'EOF'
tell application "Music"
  if it is running then
    if player state is playing then
      set track_name to name of current track
      set artist_name to artist of current track
      return artist_name & " - " & track_name
    else
      return ""
    end if
  else
    return ""
  end if
end tell
EOF
)
if [ -z "$INFO" ]; then
  sketchybar --set $NAME label="" icon=󰝚
else
  sketchybar --set $NAME label="$INFO" icon=󰝚
fi
