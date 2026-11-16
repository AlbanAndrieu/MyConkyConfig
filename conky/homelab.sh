#!/usr/bin/env bash
# Conky markup for the homelab: pfSense latency, TrueNAS health, Prometheus targets, Gatus and alerts.
# Read-only HTTP queries with short timeouts; it never touches the NFS mounts.
set -uo pipefail

prom="${HOMELAB_PROMETHEUS:-http://172.17.0.24:9090}"
alertmanager="${HOMELAB_ALERTMANAGER:-http://172.17.0.24:9093}"
gateway="${HOMELAB_GATEWAY:-172.17.0.1}"
green=66CC66 orange=FFA300 red=E05A47 grey=666666

query_json() { curl -s -m 3 -G "${prom}/api/v1/query" --data-urlencode "query=$1"; }
query() { query_json "$1" | jq -r '.data.result[0].value[1] // empty' 2>/dev/null; }
ping_ms() { ping -c 1 -W 1 "$1" 2>/dev/null | sed -nE 's/.*time=([0-9.]+).*/\1/p'; }
int() { LC_NUMERIC=C printf '%.0f' "${1:-0}"; }
# Green below the warning threshold, orange up to the critical one, red beyond.
level() { awk -v v="${1:-0}" -v w="$2" -v c="$3" -v g="${green}" -v o="${orange}" -v r="${red}" \
  'BEGIN {print (v >= c) ? r : (v >= w) ? o : g}'; }
# Ubuntu has • but no ● or ▲; a font switch at line start makes conky undersize the window.
row() { printf '${color %s}•${goto 24}${color EAEAEA}%s${goto 110}${color AAAAAA}%s\n' "$1" "$2" "$3"; }
detail() { printf '${goto 110}${color %s}%s\n' "${2:-888888}" "$1"; }

echo '${font GE Inspira:pixelsize=22}${color FFA300}HOMELAB${font}${voffset -4}${color 666666}${hr 1}'

# pfSense exports no metrics yet (pfSenseMetricsMissing): measure it from here.
gw="$(ping_ms "${gateway}")"
wan="$(ping_ms 1.1.1.1)"
start=$(date +%s%N)
getent hosts api.openweathermap.org >/dev/null && dns="$((($(date +%s%N) - start) / 1000000)) ms" || dns=KO
if [[ -z "${gw}" ]]; then color="${red}"; elif [[ -z "${wan}" || "${dns}" == KO ]]; then color="${orange}"; else color="$(level "${wan}" 50 150)"; fi
row "${color}" pfSense "gw ${gw:-–} ms · wan ${wan:-–} ms · dns ${dns}"

if [[ "$(query 'up{job="truenas_node"}')" != 1 ]]; then
  row "${grey}" TrueNAS "Prometheus or node_exporter unreachable"
else
  cpu="$(int "$(query '100 - avg(rate(node_cpu_seconds_total{job="truenas_node",mode="idle"}[5m])) * 100')")"
  mem="$(int "$(query '100 * (1 - node_memory_MemAvailable_bytes{job="truenas_node"} / node_memory_MemTotal_bytes{job="truenas_node"})')")"
  load="$(LC_NUMERIC=C printf '%.1f' "$(query 'node_load1{job="truenas_node"}')")"
  free="$(numfmt --to=iec --suffix=B "$(int "$(query 'node_filesystem_avail_bytes{job="truenas_node",mountpoint="/mnt/cpool"}')")")"
  pools="$(query 'count(node_zfs_zpool_state{job="truenas_node",state="online"})')"
  online="$(query 'count(node_zfs_zpool_state{job="truenas_node",state="online"} == 1)')"
  color="$(level "$((cpu > mem ? cpu : mem))" 85 95)"
  [[ "${online:-0}" != "${pools:-0}" ]] && color="${red}"
  row "${color}" TrueNAS "cpu ${cpu}% · ram ${mem}% · load ${load}"
  detail "cpool ${free} free · pools ${online:-0}/${pools:-0} online"
fi

targets="$(query 'count(up)')"
if [[ -z "${targets}" ]]; then
  row "${grey}" Prometheus "unreachable"
else
  up="$(query 'count(up == 1)')"
  down="$(query_json 'up == 0' | jq -r '[.data.result[].metric.job | sub("_(bazarr|lidarr|prowlarr|radarr|sonarr)$"; "")] | unique | join(", ")')"
  row "$(level "$((targets - up))" 1 5)" Prometheus "${up}/${targets} targets up"
  if [[ -n "${down}" ]]; then
    fold -s -w 56 <<<"down: ${down}" | while read -r line; do detail "${line}" 888888; done
  fi
fi

endpoints="$(query 'count(gatus_results_endpoint_success)')"
if [[ -n "${endpoints}" ]]; then
  failing="$(query_json 'gatus_results_endpoint_success == 0' | jq -r '[.data.result[].metric.name] | join(", ")')"
  bad="$(query 'count(gatus_results_endpoint_success == 0)')"
  row "$(level "${bad:-0}" 1 3)" Gatus "$((endpoints - ${bad:-0}))/${endpoints} endpoints ok"
  [[ -n "${failing}" ]] && detail "${failing:0:58}" 888888
fi

alerts="$(curl -s -m 3 "${alertmanager}/api/v2/alerts?active=true&silenced=false&inhibited=false")"
if ! jq -e 'type == "array"' <<<"${alerts}" >/dev/null 2>&1; then
  row "${grey}" Alerts "Alertmanager unreachable"
else
  read -r critical warning info < <(jq -r '[map(select(.labels.severity == "critical")), map(select(.labels.severity == "warning")),
    map(select(.labels.severity != "critical" and .labels.severity != "warning"))] | map(length) | @tsv' <<<"${alerts}")
  color="${green}"
  ((warning)) && color="${orange}"
  ((critical)) && color="${red}"
  row "${color}" Alerts "${critical} critical · ${warning} warning · ${info} info"
  jq -r --arg r "${red}" --arg o "${orange}" '
    sort_by({critical: 0, warning: 1}[.labels.severity] // 2) | .[:5][]
    | ({critical: $r, warning: $o}[.labels.severity] // "888888") as $c
    | "${goto 110}${color \($c)}• \(.labels.alertname)${alignr}${color 666666}\(.labels.instance // "")"
    ' <<<"${alerts}"
fi
echo "\${font Ubuntu:size=6}\${color 666666}Prometheus · Alertmanager · $(date +%H:%M)\${font}"
