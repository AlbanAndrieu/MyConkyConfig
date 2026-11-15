#!/bin/bash
sudo zpool status | tee ~/.conky/zpool_status >/dev/null
if grep -q DEGRADED ~/.conky/zpool_status; then
	cat ~/.conky/zpool_status
fi
