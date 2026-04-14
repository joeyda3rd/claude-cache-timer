#!/bin/bash
# Stop hook: stamps the cache expiry time so the statusline can render a live countdown.
# Reads the transcript JSONL, finds the last assistant turn with cache_read_input_tokens > 0,
# and writes (now + TTL) as epoch seconds to /tmp/cache_expiry_<session_id>.

# Change to 300 for the default 5 minute prompt cache TTL.
CACHE_TTL_SECONDS=3600

INPUT=$(cat)

SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "default"')
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // ""')

[ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ] && exit 0

CACHE_READ=$(python3 -c "
import json, sys
hits = 0
with open('$TRANSCRIPT') as f:
    for line in f:
        try:
            d = json.loads(line)
            if d.get('type') == 'assistant':
                hits = d.get('message', {}).get('usage', {}).get('cache_read_input_tokens', 0)
        except:
            pass
print(hits)
" 2>/dev/null)

if [ "${CACHE_READ:-0}" -gt 0 ] 2>/dev/null; then
  echo $(( $(date +%s) + CACHE_TTL_SECONDS )) > "/tmp/cache_expiry_${SESSION_ID}"
fi
