#!/bin/sh
sleep 30

mkdir /home/albandrieu/.cache/oslo || true
mkdir /home/albandrieu/.cache/frankfurt || true
#ls -lrta /opt/conky/bin/conky
#ls -lrta /usr/lib/x86_64-linux-gnu/libcairo.so
#conky -p 5 -c ~/.conky/conky_earthquake &

#conky -p 5 -c ~/.conky/conky_system &
conky -p 5 -c ~/.conky/conky_weather &
conky -p 5 -c ~/.conky/conky_weather_oslo &
conky -p 5 -c ~/.conky/conky_weather_frankfurt &
conky -p 5 -c ~/.conky/conky_market &
conky -p 5 -c ~/.conky/Gotham/Gotham &
conky -p 5 -c ~/.conky/ConkyOrange/conkyrc_orange_4k

#./convert.lua your_config.

exit 0
