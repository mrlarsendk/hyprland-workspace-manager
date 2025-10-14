# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hyprland Workspace Manager is a bash script that automatically manages workspace arrangement for Hyprland dual monitor setups. It ensures workspace 1 stays on the internal display (eDP-1) while routing all other workspaces (2-10) to an external monitor.

## Architecture

This is a single-file bash script (`hyprland-workspace-manager.sh`) with three core functions:

1. **get_external_monitor()**: Detects any connected external monitor by querying `hyprctl monitors -j` and filtering out the internal monitor (eDP-1). Returns the first non-internal monitor found.

2. **bind_workspaces()**: Applies workspace-to-monitor bindings via `hyprctl keyword workspace` commands. Workspace 1 is bound to the internal monitor with `persistent:true` and `default:true` flags. Workspaces 2-10 are bound to the external monitor if one is detected.

3. **enforce_workspace_1()**: Checks if workspace 1 has been moved away from the internal monitor and moves it back using `hyprctl dispatch moveworkspacetomonitor`.

4. **monitor_workspaces()**: Uses `socat` to subscribe to Hyprland's socket2 event stream, watching for `workspace*` and `moveworkspace*` events to trigger enforcement.

The script operates in three modes via command-line argument: `bind` (one-time binding), `enforce` (one-time check), and `monitor` (continuous enforcement).

## Key Dependencies

- **hyprctl**: Hyprland's IPC tool for querying monitor/workspace state and dispatching commands
- **jq**: JSON parsing for hyprctl output
- **socat**: Unix socket communication for event monitoring (monitor mode only)

## Testing the Script

Manual testing requires a Hyprland environment with dual monitors:

```bash
# Test workspace binding
./hyprland-workspace-manager.sh bind

# Verify bindings were applied
hyprctl workspaces -j | jq '.[] | {id, monitor}'

# Test enforcement (try moving workspace 1 to external monitor first)
hyprctl dispatch moveworkspacetomonitor "1 DP-1"  # Adjust monitor name
./hyprland-workspace-manager.sh enforce

# Test monitoring mode (requires socat)
./hyprland-workspace-manager.sh monitor
# In another terminal, try: hyprctl dispatch moveworkspacetomonitor "1 DP-1"
```

## Configuration Points

- **INTERNAL variable** (line 8): Hardcoded to "eDP-1". This is the only monitor name that needs modification for different internal display names.
- **Workspace range** (line 36): Currently binds workspaces 2-10 to external monitor. Adjust the `{2..10}` range if more workspaces are needed.

## Common Development Tasks

When modifying this script:

- Use `hyprctl monitors` to verify monitor detection logic
- Use `hyprctl workspaces -j` to inspect current workspace states
- The Hyprland socket path is: `/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock`
- Event format from socket2: Each line is a plain text event like `workspace>>2` or `moveworkspace>>workspace,monitor`

## Integration Points

Users typically integrate this script into `~/.config/hypr/hyprland.conf` using:
- `exec-once = /path/to/hyprland-workspace-manager.sh bind` for startup binding
- `exec-once = /path/to/hyprland-workspace-manager.sh monitor` for continuous enforcement

The script can also be triggered via monitor change events using socat to watch for `monitor*` events on socket2.
