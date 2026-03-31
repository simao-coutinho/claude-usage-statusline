# Claude Usage Statusline

A Claude Code plugin that displays real-time usage percentages and reset countdowns in your terminal status line.

## What it shows

```
5h:29.3% (1h46m) ~2.1%/min out@16:30  7d:36.0% (2d15h)  ctx:10.5%
```

| Indicator | Description |
|-----------|-------------|
| `5h` | 5-hour rolling session usage percentage |
| `7d` | 7-day weekly usage percentage |
| `ctx` | Current context window usage |
| `(Xh Ym)` | Time until the rate limit window resets |
| `~X.X%/min` | Burn rate — how fast you're consuming the 5h limit |
| `out@HH:MM` | Predicted local time when the 5h limit will be exhausted |

## Features

- Burn rate tracking — shows how fast you're consuming the 5h session limit
- Exhaustion prediction — estimates when you'll hit 100% at the current pace
- Holds the last known usage value when the API temporarily returns 0% between updates
- Only resets to 0% when the actual rate limit timer expires
- Shows days for 7d countdown (e.g. `3d02h`)
- Works across macOS, Linux, and Windows (with Git Bash)
- Auto-configures on session start

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `jq` installed and available in PATH
- `awk` installed (standard on macOS/Linux)

## Installation

### Option 1: Install via `/plugins` command (recommended)

Inside Claude Code, type:

```
/plugins add github:simao-coutinho/claude-usage-statusline
```

### Option 2: Install from CLI

```bash
claude plugins add github:simao-coutinho/claude-usage-statusline
```

### Option 3: Install from local path

```bash
claude plugins add /path/to/claude-usage-statusline
```

### Option 4: Manual installation

1. Clone the repository:
   ```bash
   git clone https://github.com/simao-coutinho/claude-usage-statusline.git ~/.claude/plugins/claude-usage-statusline
   ```

2. Add to your `~/.claude/settings.json`:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "sh ~/.claude/plugins/claude-usage-statusline/statusline.sh"
     }
   }
   ```

## How it works

The plugin consists of:

- **`statusline.sh`** — The main script that reads Claude Code's JSON status data from stdin, extracts usage percentages and reset timestamps, and formats them for display.
- **`hooks/`** — A `SessionStart` hook that automatically configures the statusline setting to point to the plugin's script.

### Smart caching

The API occasionally returns 0% between updates. The plugin caches values in `/tmp/.claude_statusline_cache` and only accepts a lower value when the rate limit timer has actually expired. This prevents the status line from flickering to 0% during normal use.

## Uninstall

```bash
claude plugins remove claude-usage-statusline
```

Or manually remove the `statusLine` entry from `~/.claude/settings.json`.

## License

MIT
