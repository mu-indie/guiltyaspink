#!/bin/bash

THUMB=/tmp/hyde-mpris
fallback_art_file="$HOME/.config/hypr/nowplaying/fallback_album_art.jpg"
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

#clear album art when no media is playing
if [ -z "$active_player" ]; then
  rm -f "${THUMB}.png" "${THUMB}.inf"
  pkill -USR2 hyprlock 2>/dev/null
  exit 0
fi

#get metadata(artist and song title)
raw_title=$(playerctl -p "$active_player" metadata title 2>/dev/null)
raw_artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null)

#display album art
fetch_thumb() {
  artUrl=$(playerctl -p "$active_player" metadata mpris:artUrl 2>/dev/null)
  tmp="${THUMB}.tmp.png"
  
  # display fallback art if no art is found
  if [ -z "$artUrl" ]; then
    cp "$fallback_art_file" "${THUMB}.png"
    pkill -USR2 hyprlock 2>/dev/null
    return 0
  fi

  # Skip if art hasn't changed
  [[ "$artUrl" = "$(cat "${THUMB}.inf" 2>/dev/null)" ]] && return 0
  printf "%s\n" "$artUrl" > "${THUMB}.inf"

  if   [[ "$artUrl" =~ ^https?:// ]];  then curl -so "$tmp" "$artUrl"
  elif [[ "$artUrl" =~ ^file:// ]];    then cp "$(url_decode "${artUrl#file://}")" "$tmp"
  elif [[ "$artUrl" =~ ^data:image ]]; then echo "${artUrl#*,}" | base64 -d > "$tmp"
  else
    cp "$fallback_art_file" "${THUMB}.png"
    pkill -USR2 hyprlock 2>/dev/null
    return 0
  fi

  magick "$tmp" -quality 50 "${THUMB}.png"
  magick "${THUMB}.png" -blur 200x7 -resize 1920x^ -gravity center -extent 1920x1080\! "${THUMB_BLURRED}.png"
  rm -f "$tmp"
  pkill -USR2 hyprlock 2>/dev/null
}
{ fetch_thumb; } || { cp "$fallback_art_file" "${THUMB}.png"; pkill -USR2 hyprlock 2>/dev/null; } &

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