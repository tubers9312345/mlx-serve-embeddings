# Running mlx-serve with launchd

This guide covers setting up mlx-serve as a macOS launchd user agent so it starts automatically at login and restarts on failure.

## Overview

launchd is macOS's native service manager. A **user agent** (installed in `~/Library/LaunchAgents/`) runs under your user account and starts when you log in -- no root or sudo required.

## Files

- `launchd/com.agrande.mlx-serve.plist` -- the launchd job definition

## Prerequisites

Before installing, make sure the server runs correctly via `./start_embeddings.sh` first. The launchd config uses the same command and flags.

## Installation

### 1. Review and customize the plist

Open `launchd/com.agrande.mlx-serve.plist` and verify these values match your environment:

| Key | Current Value | What to check |
|-----|--------------|---------------|
| `ProgramArguments[0]` | `/opt/homebrew/bin/uv` | Path to your `uv` binary (`which uv`) |
| `WorkingDirectory` | `/path/to/mlx-serve` | Absolute path to this repo |
| `StandardOutPath` | `.../mlx-serve/logs/launchd-stdout.log` | Must be an existing directory |
| `StandardErrorPath` | `.../mlx-serve/logs/launchd-stderr.log` | Must be an existing directory |
| `--model-path` | `mlx-community/Qwen3-Embedding-4B-4bit-DWQ` | Your desired model |
| `--port` | `8000` | Port to listen on |

### 2. Ensure logs directory exists

```bash
mkdir -p logs
```

### 3. Symlink the plist into LaunchAgents

```bash
ln -sf "$(pwd)/launchd/com.agrande.mlx-serve.plist" \
    ~/Library/LaunchAgents/com.agrande.mlx-serve.plist
```

### 4. Load the agent

```bash
launchctl load ~/Library/LaunchAgents/com.agrande.mlx-serve.plist
```

The server will start immediately (`RunAtLoad` is enabled) and will auto-start on every future login.

## Management Commands

### Check status

```bash
launchctl list | grep mlx-serve
```

Output columns: `PID`, `last exit status`, `label`. A non-`-` PID means it's running.

### Stop the server

```bash
launchctl stop com.agrande.mlx-serve
```

Note: because `KeepAlive` is configured, launchd will restart the process after `ThrottleInterval` (10 seconds). To fully stop it, unload first.

### Start the server

```bash
launchctl start com.agrande.mlx-serve
```

### Unload (disable until next load)

```bash
launchctl unload ~/Library/LaunchAgents/com.agrande.mlx-serve.plist
```

This stops the process and prevents launchd from managing it until you `load` again.

### Reload after plist changes

```bash
launchctl unload ~/Library/LaunchAgents/com.agrande.mlx-serve.plist
launchctl load ~/Library/LaunchAgents/com.agrande.mlx-serve.plist
```

## Viewing Logs

```bash
# Server application logs (from --log-file)
tail -f logs/embeddings_server.log

# launchd stdout/stderr (startup errors, crashes)
tail -f logs/launchd-stdout.log
tail -f logs/launchd-stderr.log
```

If the server fails to start, check `launchd-stderr.log` first -- it captures errors from `uv` and the process itself.

## Behavior Details

| Setting | Value | Effect |
|---------|-------|--------|
| `RunAtLoad` | `true` | Starts when the plist is loaded and on login |
| `KeepAlive.SuccessfulExit` | `false` | Restarts only on non-zero exit (crash). Clean shutdown stays stopped. |
| `ThrottleInterval` | `10` | Waits 10 seconds before restarting a crashed process |

## Uninstalling

```bash
launchctl unload ~/Library/LaunchAgents/com.agrande.mlx-serve.plist
rm ~/Library/LaunchAgents/com.agrande.mlx-serve.plist
```

## Compatibility with start_embeddings.sh

When using launchd, you don't need `start_embeddings.sh` -- launchd manages the process lifecycle. However, the two approaches conflict on PID tracking:

- `start_embeddings.sh` writes to `embeddings_server.pid`
- launchd tracks PID internally

If switching to launchd, stop any running instance from `start_embeddings.sh` first:

```bash
kill $(cat embeddings_server.pid) 2>/dev/null
rm -f embeddings_server.pid
```

## Troubleshooting

**Server won't start (exit code 127)**
- The `uv` binary path in the plist is wrong. Run `which uv` and update `ProgramArguments[0]`.

**Server starts then immediately exits**
- Check `logs/launchd-stderr.log` for error details.
- Ensure `uv sync` has been run and dependencies are installed.
- Verify the model name is correct and accessible.

**Port already in use**
- Another instance may be running via `start_embeddings.sh`. Kill it first.
- Or change `--port` in the plist to a different port.

**Logs not appearing**
- Ensure `logs/` directory exists: `mkdir -p logs`
- Check file permissions on the logs directory.
