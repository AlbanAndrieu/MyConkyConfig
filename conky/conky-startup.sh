#!/bin/bash
set -xv

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

if [ -z "$DISPLAY" ]; then
  echo "No DISPLAY found, exiting."
  # DISPLAY=:1
  exit 2
fi

export DISPLAY

if [ -z "$HOME" ]; then
  echo "No HOME found."
  HOME="/home/albandrieu"
fi

killall /usr/bin/conky
rm -f "${HOME}/.conky/conky.pid"
  
if [ "$DESKTOP_SESSION" = "gnome" -o "$DESKTOP_SESSION" = "ubuntu" ]; then
  sleep 20s
  #cd "/home/albandrieu/.conky/Gotham"
  # conky -p 20 -c "/home/albandrieu/.conky/Gotham/Gotham" &
fi

"${HOME}/.conky/startconky.sh" | tee /var/log/conky.log > /dev/null

# echo $! > "${HOME}/.conky/conky.pid"
echo $$ > "${HOME}/.conky/conky.pid"

echo "multitail /var/log/conky.log /var/log/conky/conky_weather.log"
  
exit 0
