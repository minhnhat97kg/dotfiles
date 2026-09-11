#!/usr/bin/env bash
# Renders both uplinks as one readout: which link is actually carrying traffic,
# and which is merely up.
#
#   ● holds the default route    ○ link up, standing by
#
# Why one custom module rather than the two built-in "network" ones it replaces:
# waybar's network module knows per-interface link state but has nothing to say
# about which interface holds the default route. With cable and wifi both up it
# painted two equally-bright readouts, so the bar could not tell you which one
# was live — which is the whole question when a machine is dual-homed.
#
# The active link is the lowest-metric default route among en*/wl* ONLY. Those
# prefixes are what keep the VPN out of the answer: openvpnclient0 and the
# virbr* bridges also carry default/blanket routes, and waybar reported them as
# ethernet — the original bug the old two-module split worked around. Matching
# physical prefixes fixes it at the source instead.
#
# Ordering is fixed (cable, then wifi) rather than active-first, so a link
# changing state never makes the readout jump sideways under the pointer.
#
# Colour reinforces the glyph, it does not carry the state on its own (style.css
# keeps hue out of state). The spans are inline because one module has to paint
# two segments differently and Pango markup beats CSS there — same reason
# workspaces.sh does it.
set -euo pipefail

FG="#ffffff"     # live
FAINT="#5a5a5a"  # standby / down — same step on the ramp as the rest of the bar

routes="$(ip -j route show default 2>/dev/null || echo '[]')"
addrs="$(ip -j addr 2>/dev/null || echo '[]')"

# Lowest metric wins. An absent "metric" key means metric 0, i.e. highest
# priority, so it must default to 0 and not to some large sentinel.
active="$(jq -r '
  [ .[] | select(.dev | test("^(en|wl)")) ]
  | sort_by(.metric // 0) | .[0].dev // ""
' <<<"$routes")"

# "Up" means operstate UP *and* an IPv4 address: a plugged-in cable with no DHCP
# lease is not a usable uplink and should not claim a slot on the bar.
dev_up() {
    jq -r --arg re "$1" '
      [ .[]
        | select(.ifname | test($re))
        | select(.operstate == "UP")
        | select([.addr_info[]? | select(.family == "inet")] | length > 0)
      ] | .[0].ifname // ""
    ' <<<"$addrs"
}

eth_dev="$(dev_up '^en')"
wifi_dev="$(dev_up '^wl')"

essid=""
signal=""
if [ -n "$wifi_dev" ]; then
    essid="$(nmcli -g GENERAL.CONNECTION dev show "$wifi_dev" 2>/dev/null || true)"
    # The in-use row is marked with "*" in the first field. Parsed with awk
    # rather than grep so a "*" inside an SSID cannot match by accident.
    signal="$(nmcli -t -f IN-USE,SIGNAL dev wifi list ifname "$wifi_dev" 2>/dev/null \
              | awk -F: '$1 == "*" { print $2; exit }' || true)"
fi

jq -nc \
   --arg fg "$FG" --arg faint "$FAINT" \
   --arg active "$active" --arg eth "$eth_dev" --arg wifi "$wifi_dev" \
   --arg essid "$essid" --arg signal "$signal" '
  # @html escapes & < > — the label is rendered as Pango markup, so an SSID
  # containing an ampersand would otherwise break the module outright.
  def seg($live; $label):
    "<span foreground=\"" + (if $live then $fg else $faint end) + "\">"
    + (if $live then "●" else "○" end) + ($label | @html) + "</span>";

  # Two digits keeps 0-99 at a fixed width so the readout never reflows.
  def pct: if . == "" then "--" else (tonumber | floor | if . < 10 then "0" else "" end + tostring) end;

  ($signal | pct) as $sig |
  (if $essid == "" then "wifi" else $essid end) as $name |

  [
    (if $eth  != "" then seg($active == $eth;  "ETH") else empty end),
    (if $wifi != "" then seg($active == $wifi; $name + " " + $sig)
                    else seg(false; "--") end)
  ] as $parts |

  {
    text: ($parts | join("  ")),
    tooltip: (
      [ (if $eth != ""  then (if $active == $eth  then "● " else "○ " end) + $eth  + " — cable"
                        else "○ cable — down" end),
        (if $wifi != "" then (if $active == $wifi then "● " else "○ " end) + $wifi
                             + " — " + $essid + " (" + $sig + "%)"
                        else "○ wifi — disconnected" end),
        "",
        "● carrying traffic   ○ standing by"
      ] | join("\n") | @html
    ),
    class: (if $active == "" then "offline" else "online" end)
  }
'
