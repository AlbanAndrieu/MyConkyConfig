#!/usr/bin/env bash
# Validate the conky setup started by conky/startconky.sh: every config and lua_load script compiles
# (conky 1.10+ configs are Lua), every ~/.conky path they use exists and every helper they run is executable.
set -uo pipefail

command -v luac >/dev/null || { echo "luac is missing: sudo apt install lua5.4" >&2; exit 2; }
conky_dir="$(cd "$(dirname "$0")/../conky" && pwd)"
errors=0

# ~/.conky is a symlink to this conky/ directory.
local_path() { sed -E "s#^(~|\\$\{HOME\}|/home/[^/]+)/\.conky/#${conky_dir}/#" <<<"$1"; }
fail() { echo "ERROR: $*" >&2; errors=$((errors + 1)); }
compiles() { local out; out="$(luac -p "$1" 2>&1)" || fail "${out}"; }

mapfile -t configs < <(sed -nE 's#^[^#]*conky .*-c ([^ ]+).*#\1#p' "${conky_dir}/startconky.sh")
((${#configs[@]})) || fail "no 'conky -c' line in startconky.sh"

for ref in "${configs[@]}"; do
  config="$(local_path "${ref}")"
  name="${config#"${conky_dir}/"}"
  [[ -f "${config}" ]] || { fail "${ref}: missing"; continue; }
  compiles "${config}"

  while read -r lua; do
    [[ -f "$(local_path "${lua}")" ]] || { fail "${name}: lua_load ${lua} missing"; continue; }
    compiles "$(local_path "${lua}")"
  done < <(sed -nE "s#^[[:space:]]*lua_load[[:space:]]*=[[:space:]]*['\"]([^'\"]+)['\"].*#\1#p" "${config}")

  while read -r path; do
    [[ -e "$(local_path "${path}")" ]] || fail "${name}: ${path} missing"
  done < <(grep -oE "(~|/home/[^/]+)/\.conky/[^ }'\"\$)]+" "${config}" | sort -u)

  while read -r helper; do
    [[ -x "$(local_path "${helper}")" ]] || fail "${name}: ${helper} is not executable"
  done < <(grep -oE '\$\{(exec|execi|execpi|texeci)( [0-9]+)? (~|/home/[^/]+)/\.conky/[^ }]+' "${config}" |
    grep -oE '(~|/home/[^/]+)/\.conky/[^ }]+' | sort -u)
done

if ((errors)); then
  echo "conky: ${errors} error(s)" >&2
  exit 1
fi
echo "conky: ${#configs[@]} configs OK"
