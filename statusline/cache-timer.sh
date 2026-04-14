#!/bin/bash
# Minimal statusline that renders a live cache warmth countdown.
# Pair with hooks/cache-timestamp.sh and set "refreshInterval": 1 in settings.json.

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "default"')

_CACHE_EXP_FILE="/tmp/cache_expiry_${SESSION_ID}"

if [ -f "$_CACHE_EXP_FILE" ]; then
  _CACHE_EXP=$(cat "$_CACHE_EXP_FILE" 2>/dev/null)
  _NOW=$(date +%s)
  _REMAIN=$(( ${_CACHE_EXP:-0} - _NOW ))

  if [ "$_REMAIN" -gt 0 ]; then
    _MM=$(( _REMAIN / 60 ))
    _SS=$(( _REMAIN % 60 ))
    # Assumes a 1 hour window:
    #   green  first 5 minutes (remain > 55:00)
    #   yellow middle           (5:00 < remain <= 55:00)
    #   red    last 5 minutes   (remain <= 5:00)
    if   [ "$_REMAIN" -gt 3300 ]; then _COLOR="\033[32m"
    elif [ "$_REMAIN" -gt 300 ];  then _COLOR="\033[33m"
    else                               _COLOR="\033[31m"
    fi
    printf '%bcache %d:%02d\033[0m\n' "$_COLOR" "$_MM" "$_SS"
  else
    printf '\xe2\x9d\x84\n'
  fi
else
  printf '\033[90mcache idle\033[0m\n'
fi
