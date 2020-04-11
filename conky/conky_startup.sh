#!/bin/bash
set -xv

sleep 20s
killall conky
#cd "{{ conky_home }}/{{ conky_theme }}"
#conky -p 20 -c "~/{{ conky_theme }}/{{ conky_widget }}" &
./startconky.sh

exit 0
