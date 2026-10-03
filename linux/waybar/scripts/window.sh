#!/usr/bin/env bash
# Shows the focused window's APPLICATION NAME, not its title. macOS has no
# window-title module in the menu bar at all: it shows the active app's bold
# name immediately right of the Apple logo, where that app's own menus start.
set -euo pipefail

output="${1:-${WAYBAR_OUTPUT_NAME:-}}"

ws_json="$(niri msg -j workspaces)"
win_json="$(niri msg -j windows)"

jq -c -n --arg output "$output" --argjson ws "$ws_json" --argjson wins "$win_json" '
  # app_id is a reverse-DNS id ("org.wezfurlong.wezterm") or a bare binary name
  # ("firefox"). Prettify: known irregular capitalizations get an override,
  # everything else takes the last dotted segment, splits on - and _, and
  # title-cases each word.
  def prettify:
    . as $id
    | ($id | ascii_downcase) as $lid
    | {
        "wezterm": "WezTerm",
        "org.wezfurlong.wezterm": "WezTerm",
        "code": "VS Code",
        "code-oss": "VS Code",
        "org.gnome.nautilus": "Files",
        "google-chrome": "Chrome",
        "firefox_firefox": "Firefox"
      } as $overrides
    | if $overrides[$lid] then $overrides[$lid]
      else
        ($id | split(".") | last | gsub("[-_]"; " ") | split(" ")) as $words
        | ($words | map(select(length > 0) | (.[0:1] | ascii_upcase) + .[1:]) | join(" "))
      end;
  ($ws | map(select(($output == "" or .output == $output) and .is_active == true)) | first) as $w |
  ($w.active_window_id) as $wid |
  ($wins | map(select(.id == $wid)) | first) as $win |
  if $win == null then
    { text: "", tooltip: "" }
  else
    ($win.app_id // "") as $id |
    # @html escapes & < > — waybar renders labels as Pango markup, so an
    # unescaped ampersand in an app name breaks the module outright.
    {
      text: ($id | prettify | @html),
      tooltip: (($win.title // $id) | @html),
      class: (if $win.is_focused then "niri-window focused" else "niri-window" end)
    }
  end
'
