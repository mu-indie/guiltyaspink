#!/bin/bash
capacity=$(cat /sys/class/power_supply/BAT0/capacity)
status=$(cat /sys/class/power_supply/BAT0/status)

if [[ "$status" == "Charging" ]]; then
  icon="󰂄"
  color="#a6e3a1"  
elif [ "$capacity" -ge 90 ]; then icon="󰁹"; color="#a6e3a1"
elif [ "$capacity" -ge 70 ]; then icon="󰂀"; color="#a6e3a1"
elif [ "$capacity" -ge 50 ]; then icon="󰁾"; color="#cba6f7"
elif [ "$capacity" -ge 30 ]; then icon="󰁼"; color="#fab387"
elif [ "$capacity" -ge 10 ]; then icon="󰁺"; color="#f38ba8"
else icon="󰂃"; color="#f38ba8"
fi

echo "<span foreground='${color}'>${icon}</span> ${capacity}%"