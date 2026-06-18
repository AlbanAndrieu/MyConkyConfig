#!/usr/bin/env bash
# set -xv

# Improved DISPLAY detection: Try common displays or fallback
timeout=30
while [ $timeout -gt 0 ] && [ -z "$DISPLAY" ]; do
  # Check for active displays (adjust if needed)
  for disp in :0 :1; do
    if xset -display $disp q >/dev/null 2>&1; then
      DISPLAY=$disp
      break
    fi
  done
  if [ -z "$DISPLAY" ]; then
    sleep 1
    timeout=$((timeout - 1))
  fi
done

if [ -z "$HOME" ]; then
  echo "No HOME found."
  HOME="/home/albandrieu"
fi

# killall /usr/bin/conky
# pkill -x conky || true
pkill -u "$USER" -x conky || true

if [ "$DESKTOP_SESSION" = "gnome" -o "$DESKTOP_SESSION" = "ubuntu" ]; then
  sleep 20s
fi

export DISPLAY="${DISPLAY:-:0}"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

"${HOME}/.conky/startconky.sh" | tee /var/log/conky.log > /dev/null

echo $$ > ${HOME}/.conky/conky.pid 2>&1

cat ${HOME}/.conky/conky.pid

echo "multitail /var/log/conky.log /var/log/conky/conky_weather.log"

sleep infinity
  
exit 0
