#!/bin/sh
sleep 10

# First run as sudo

sudo touch /var/log/conky.log
sudo chown albandrieu:albandrieu /var/log/conky/
sudo chown albandrieu:albandrieu /var/log/conky.log

sudo mkdir -p /var/log/conky/ || true

mkdir -p /home/albandrieu/.cache/conky/oslo/ || true
mkdir -p /home/albandrieu/.cache/conky/frankfurt/ || true

#ls -lrta /opt/conky/bin/conky
#ls -lrta /usr/lib/x86_64-linux-gnu/libcairo.so
#conky -p 5 -c ~/.conky/conky_earthquake &

#conky -p 5 -c ~/.conky/conky_system &
conky -p 5 -c ~/.conky/conky_weather > /var/log/conky/conky_weather.log 2>&1 &
conky -p 5 -c ~/.conky/conky_weather_oslo >> /var/log/conky/conky_weather.log 2>&1 &
conky -p 5 -c ~/.conky/conky_weather_frankfurt >> /var/log/conky/conky_weather.log 2>&1 &
#conky -p 5 -c ~/.conky/conky_market &
conky -p 5 -c ~/.conky/Gotham/Gotham >> /var/log/conky/conky_weather.log 2>&1 &
conky -p 5 -c ~/.conky/ConkyOrange/conkyrc_orange_4k >> /var/log/conky/conky_weather.log 2>&1

#./convert.lua your_config.

exit 0
