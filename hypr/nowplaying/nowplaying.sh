#!/bin/bash

THUMB=/tmp/hyde-mpris
THUMB_BLURRED=/tmp/hyde-mpris-blurred

escape() { echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# Pick highest-priority active player
active_player=""
priority=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  status=$(playerctl -p "$p" status 2>/dev/null | tr '[:upper:]' '[:lower:]')
  title=$(playerctl -p "$p" metadata title 2>/dev/null)
  cur=0
  [ "$status" = "playing" ] && cur=3
  [ "$status" = "paused" ]  && cur=2
  [ -n "$title" ] && [ $cur -eq 0 ] && cur=1
  [ $cur -gt $priority ] && active_player="$p" && priority=$cur
done <<< "$(playerctl -l 2>/dev/null)"

if [ -z "$active_player" ]; then exit 0; fi

raw_title=$(playerctl -p "$active_player" metadata title 2>/dev/null)
raw_artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null)

fetch_thumb() {
  artUrl=$(playerctl -p "$active_player" metadata mpris:artUrl 2>/dev/null)
  [ -z "$artUrl" ] && return 1

  # Skip if art hasn't changed
  [[ "$artUrl" = "$(cat "${THUMB}.inf" 2>/dev/null)" ]] && return 0
  printf "%s\n" "$artUrl" > "${THUMB}.inf"

  tmp="${THUMB}.tmp.png"

  if   [[ "$artUrl" =~ ^https?:// ]]; then curl -so "$tmp" "$artUrl"
  elif [[ "$artUrl" =~ ^file:// ]];   then cp "$(url_decode "${artUrl#file://}")" "$tmp"
  elif [[ "$artUrl" =~ ^data:image ]]; then echo "${artUrl#*,}" | base64 -d > "$tmp"
  else return 1
  fi

  magick "$tmp" -quality 50 "${THUMB}.png"
  magick "${THUMB}.png" -blur 200x7 -resize 1920x^ -gravity center -extent 1920x1080\! "${THUMB_BLURRED}.png"
  rm -f "$tmp"
  pkill -USR2 hyprlock 2>/dev/null
}

{ fetch_thumb; } || { rm -f "${THUMB}.png" "${THUMB}.inf"; } &

case "$1" in
  --title)
    title=$(escape "$raw_title")
    if [ ${#title} -gt 20 ]; then
      echo "${title:0:20}…"
    else
      echo "$title"
    fi
    ;;
  --artist) escape "$raw_artist" ;;
  *) exit 0 ;;
esac