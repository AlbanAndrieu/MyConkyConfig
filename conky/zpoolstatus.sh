#!/bin/bash
sudo zpool status > ~/.conky/zpool_status 
if [ ! -z `cat ~/.conky/zpool_status | grep "DEGRADED"` ]; then 
	cat ~/.conky/zpool_status
fi
