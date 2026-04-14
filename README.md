# claude-cache-timer

A live cache warmth countdown for the Claude Code statusline.

The Anthropic prompt cache holds your conversation context for a bounded window after the last API call. Hitting a warm cache is meaningfully cheaper and faster than cold reads, so knowing whether your session is inside that window changes how you work. Before `refreshInterval` landed in Claude Code 2.1.97, the statusline only rendered on conversation events, which meant any time based display was stale the moment you needed it most.

This repo wires up a simple countdown that ticks every second.

Background and motivation: [anthropics/claude-code#5685](https://github.com/anthropics/claude-code/issues/5685).

## What you get

A block in your statusline that looks like one of these:

```
cache 58:14   (green, first 5 minutes after a cache hit)
cache 23:07   (yellow, middle of the window)
cache 0:42    (red, last 5 minutes)
❄             (snowflake, cache has expired)
```

Defaults assume a 1 hour cache TTL. If you are on the default 5 minute TTL, see the tuning section below.

## How it works

1. A `Stop` hook inspects the transcript after each assistant turn, looks at `cache_read_input_tokens` on the last assistant message, and if it is nonzero, writes an epoch expiry timestamp to `/tmp/cache_expiry_<session_id>`.
2. The statusline script reads that file on every render, computes the remaining seconds, and prints a colored `M:SS` countdown.
3. `statusLine.refreshInterval: 1` in `settings.json` causes Claude Code to re-invoke the statusline every second, so the countdown actually ticks.

No background processes, no daemons, no polling loops. The statusline is stateless and the hook only runs on assistant stops.

## Install

```bash
# 1. Copy the hook
mkdir -p ~/.claude/hooks
cp hooks/cache-timestamp.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/cache-timestamp.sh

# 2. Copy the statusline
mkdir -p ~/.claude/statusline
cp statusline/cache-timer.sh ~/.claude/statusline/
chmod +x ~/.claude/statusline/cache-timer.sh
```

Then edit `~/.claude/settings.json` and merge in:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/absolute/path/to/.claude/statusline/cache-timer.sh",
    "refreshInterval": 1
  },
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/absolute/path/to/.claude/hooks/cache-timestamp.sh"
          }
        ]
      }
    ]
  }
}
```

Restart Claude Code. The countdown appears after the first assistant turn that registers a cache read.

## Integrating with an existing statusline

If you already have a custom statusline, you do not need the script in `statusline/`. Drop the cache block from that file into your own script and keep the hook and the `refreshInterval` field.

## Tuning the window

The hook writes `now + 3600` as the expiry. If you are not using the extended 1 hour cache TTL (`cache_control.ttl: "1h"` on your cached blocks), change `3600` to `300` in `hooks/cache-timestamp.sh` to match the default 5 minute TTL. You may also want to adjust the green and yellow thresholds in `statusline/cache-timer.sh` so the colors map onto the shorter window.

## Notes

* The expiry is stamped at the end of the assistant turn, which is a small amount later than the actual API call. For a 1 hour window the skew is not meaningful. For a 5 minute window you lose a second or two off the real warmth.
* Session ID comes from Claude Code itself, so two parallel sessions will not stomp each other's timers.
* `/tmp` is fine for this. It is per session state with no value across reboots.

## License

MIT.
