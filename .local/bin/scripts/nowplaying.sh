#!/bin/bash
status=$(playerctl status 2>/dev/null)
case "$status" in
    Playing) icon="󰏤" ;;
    Paused)  icon="󰐊" ;;
    *)       icon="󰓛" ;;
esac

title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)

if [ -z "$title" ]; then
    echo ""
else
    if [ ${#title} -gt 30 ]; then
        title="${title:0:30}…"
    fi
    echo "$icon $title"
    echo "$artist"
fi