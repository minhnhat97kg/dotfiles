#!/bin/bash
# Emits live CPU package power draw (RAPL) as a waybar custom-module JSON stream.
# Requires /sys/class/powercap/intel-rapl:0/energy_uj to be world-readable
# (see 99-rapl-permissions.rules).

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

    watts=$(awk -v d="$delta" -v t0="$prevtime" -v t1="$currtime" 'BEGIN { printf "%.2f", d / 1000000 / (t1 - t0) }')
    printf '{"text": "%s W", "tooltip": "CPU package power draw (RAPL)"}\n' "$watts"

    prev=$curr
    prevtime=$currtime
done
