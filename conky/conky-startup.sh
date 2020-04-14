#!/bin/bash
set -xv

#sleep 20s
killall -s SIGKILL conky
#cd "{{ conky_home }}/{{ conky_theme }}"
#conky -p 20 -c "~/{{ conky_theme }}/{{ conky_widget }}" &
$HOME/.conky/startconky.sh

exit 0
