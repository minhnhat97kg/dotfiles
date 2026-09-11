#!/bin/bash
# Emits live CPU package power draw (RAPL) as a waybar custom-module JSON stream.
# Requires /sys/class/powercap/intel-rapl:0/energy_uj to be world-readable
# (see 99-rapl-permissions.rules).
#
# Rendered as a bare wattage on one row. No caption: it sits alone above the
# control stack, and "%.2f W" changed width as the value moved, which reflowed
# the column every two seconds.

zone=/sys/class/powercap/intel-rapl:0/energy_uj
maxval=$(cat /sys/class/powercap/intel-rapl:0/max_energy_range_uj)

prev=$(cat "$zone")
prevtime=$EPOCHREALTIME

while true; do
    sleep 2
    curr=$(cat "$zone")
    currtime=$EPOCHREALTIME

    delta=$(( curr - prev ))
    if [ "$delta" -lt 0 ]; then
        delta=$(( delta + maxval ))
    fi

    # Rounded to a whole watt and clamped to three digits.
    watts=$(awk -v d="$delta" -v t0="$prevtime" -v t1="$currtime" 'BEGIN {
        w = d / 1000000 / (t1 - t0)
        if (w > 999) w = 999
        if (w < 0) w = 0
        printf "%d", w + 0.5
    }')

    jq -nc --arg w "$watts" \
        '{text: ($w + "W"), tooltip: "CPU package power draw (RAPL)"}'

    prev=$curr
    prevtime=$currtime
done
