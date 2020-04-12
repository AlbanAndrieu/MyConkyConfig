#!/bin/sh
sleep 30

mkdir /home/albandrieu/.cache/oslo || true
#conky -p 5 -c ~/.conky/conky_earthquake &

#conky -p 5 -c ~/.conky/conky_system &
conky -p 5 -c ~/.conky/conky_weather &
conky -p 5 -c ~/.conky/conky_weather_oslo &
conky -p 5 -c ~/.conky/conky_market &
conky -p 5 -c ~/.conky/Green\ Apple\ Desktop/Gotham &
conky -p 5 -c ~/.conky/ConkyOrange/conkyrc_orange_4k

exit 0
