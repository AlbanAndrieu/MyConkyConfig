#!/usr/bin/env bash
# Conky markup for quotes from the Yahoo Finance chart API: price, day change and an intraday sparkline.
# Called by conky_market with execpi; a failed fetch shows the last cached quote.
set -uo pipefail

cache=~/.cache/conky/market
mkdir -p "${cache}"

quotes=(
  "TTE.PA|TotalEnergies"
  "^FCHI|CAC 40"
  "^GDAXI|DAX"
  "EXS1.DE|iShares Core DAX"
  "DBXD.DE|Xtrackers DAX"
  "BTC-EUR|Bitcoin"
)

for quote in "${quotes[@]}"; do
  symbol="${quote%%|*}"
  name="${quote#*|}"
  file="${cache}/${symbol}.json"
  curl -s -m 5 -A 'Mozilla/5.0' -o "${file}.new" \
    "https://query1.finance.yahoo.com/v8/finance/chart/${symbol}?range=1d&interval=15m" &&
    jq -e '.chart.result[0].meta.regularMarketPrice' "${file}.new" >/dev/null 2>&1 &&
    mv "${file}.new" "${file}"
  rm -f "${file}.new"

  # Price, change in percent and a 24-point sparkline of the session closes.
  read -r price change spark < <(jq -r '
    .chart.result[0] as $r
    | [$r.indicators.quote[0].close[]? | select(. != null)] as $all
    | ($all | length) as $n
    | (if $n > 24 then [range(0; $n; (($n / 24) | ceil))] | map($all[.]) else $all end) as $s
    | ($s | min) as $lo | ($s | max) as $hi
    | [$r.meta.regularMarketPrice,
       (($r.meta.regularMarketPrice / $r.meta.chartPreviousClose - 1) * 100),
       ($s | map(if $hi == $lo then 3 else ((. - $lo) / ($hi - $lo) * 7 | floor) end)
           | map("▁▂▃▄▅▆▇█"[.:. + 1]) | join(""))]
    | @tsv' "${file}" 2>/dev/null)

  if [[ -z "${price:-}" ]]; then
    echo "\${color 888888}${name}\${alignr}n/a"
    continue
  fi
  color=AAAAAA arrow="="
  if awk -v c="${change}" 'BEGIN {exit !(c >= 0.05)}'; then color=66CC66 arrow="▲"; fi
  if awk -v c="${change}" 'BEGIN {exit !(c <= -0.05)}'; then color=E05A47 arrow="▼"; fi
  LC_NUMERIC=C printf '${color EAEAEA}%s${goto 150}${font DejaVu Sans Mono:size=8}${color %s}%s${font}${alignr}${color EAEAEA}%s  ${color %s}${font DejaVu Sans:size=7}%s${font} %+.2f%%\n' \
    "${name}" "${color}" "${spark}" "$(LC_NUMERIC=C printf '%.2f' "${price}")" "${color}" "${arrow}" "${change}"
done
echo "\${font Ubuntu:size=6}\${color 666666}Yahoo Finance · $(date +%H:%M)\${font}"
