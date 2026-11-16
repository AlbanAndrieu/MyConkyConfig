#!/usr/bin/env bash
# Conky markup for quotes from the Yahoo Finance chart API: price, day and one-year change, one-year sparkline.
# Called by conky_market with execpi; a failed fetch shows the last cached quote.
set -uo pipefail

cache=~/.cache/conky/market
mkdir -p "${cache}"
green=66CC66 red=E05A47 grey=AAAAAA

quotes=(
  "TTE.PA|TotalEnergies"
  "^FCHI|CAC 40"
  "^GDAXI|DAX"
  "EXS1.DE|iShares Core DAX"
  "DBXD.DE|Xtrackers DAX"
  "BTC-EUR|Bitcoin"
)

# Green above +0.05 %, red below -0.05 %, grey in between.
trend() { awk -v c="$1" -v g="${green}" -v r="${red}" -v n="${grey}" 'BEGIN {print (c >= 0.05) ? g : (c <= -0.05) ? r : n}'; }

echo "\${font Ubuntu:size=7}\${color 666666}\${goto 120}1 year\${goto 280}price\${goto 350}day\${alignr}1 year\${font}"
for quote in "${quotes[@]}"; do
  symbol="${quote%%|*}"
  name="${quote#*|}"
  file="${cache}/${symbol}.json"
  curl -s -m 5 -A 'Mozilla/5.0' -o "${file}.new" \
    "https://query1.finance.yahoo.com/v8/finance/chart/${symbol}?range=1y&interval=1d" &&
    jq -e '.chart.result[0].meta.regularMarketPrice' "${file}.new" >/dev/null 2>&1 &&
    mv "${file}.new" "${file}"
  rm -f "${file}.new"

  read -r price day year spark < <(jq -r '
    .chart.result[0] as $r
    | [$r.timestamp, $r.indicators.quote[0].close] | transpose | map(select(.[1] != null)) as $bars
    | ($bars | map(.[1])) as $all
    | $r.meta.regularMarketPrice as $p
    # Once the session has started the last daily bar is today, so the previous close is the one before.
    | (if ($bars[-1][0] / 86400 | floor) == ($r.meta.regularMarketTime / 86400 | floor)
       then $all[-2] else $all[-1] end) as $prev
    | ($all | length) as $n
    | (if $n > 24 then [range(0; $n; (($n / 24) | ceil))] | map($all[.]) + [$all[-1]] else $all end) as $s
    | ($s | min) as $lo | ($s | max) as $hi
    | [$p, ($p / $prev - 1) * 100, ($p / $all[0] - 1) * 100,
       ($s | map(if $hi == $lo then 3 else ((. - $lo) / ($hi - $lo) * 7 | floor) end)
           | map("▁▂▃▄▅▆▇█"[.:. + 1]) | join(""))]
    | @tsv' "${file}" 2>/dev/null)

  if [[ -z "${price:-}" ]]; then
    echo "\${color 888888}${name}\${alignr}n/a"
    continue
  fi
  day_color="$(trend "${day}")" year_color="$(trend "${year}")"
  arrow="="
  [[ "${day_color}" == "${green}" ]] && arrow="▲"
  [[ "${day_color}" == "${red}" ]] && arrow="▼"
  LC_NUMERIC=C printf '${color EAEAEA}%s${goto 120}${font DejaVu Sans Mono:size=7}${color %s}%s${font}${goto 280}${color EAEAEA}%.2f${goto 350}${color %s}${font DejaVu Sans:size=7}%s${font} %+.2f%%${alignr}${color %s}%+.1f%%\n' \
    "${name}" "${year_color}" "${spark}" "${price}" "${day_color}" "${arrow}" "${day}" "${year_color}" "${year}"
done
echo "\${font Ubuntu:size=6}\${color 666666}Yahoo Finance · $(date +%H:%M)\${font}"
