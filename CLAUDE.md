# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hyprland Workspace Manager is a simple bash script for manual workspace arrangement in Hyprland dual monitor setups. When executed, it forces workspace 1 to the internal display (eDP-1) and routes all other workspaces (2-10) to an external monitor.

## Architecture

This is a single-file bash script (`hyprland-workspace-manager.sh`) that executes once when run. The script:

1. **Detects monitors**: Automatically identifies the internal monitor (eDP-1) and the first connected external monitor using `hyprctl monitors -j`.

2. **Moves existing workspaces**: Checks if any workspaces are on the wrong monitor and moves them using `hyprctl dispatch moveworkspacetomonitor`.

3. **Applies bindings**: Binds workspace 1 to the internal monitor with `persistent:true` and `default:true` flags, and binds workspaces 2-10 to the external monitor using `hyprctl keyword workspace` commands.

The script requires both monitors to be connected and will exit with an error if either is missing.

## Key Dependencies

- **hyprctl**: Hyprland's IPC tool for querying monitor/workspace state and dispatching commands
- **jq**: JSON parsing for hyprctl output

## Testing the Script

Manual testing requires a Hyprland environment with dual monitors:

```bash
# Run the script to force workspace arrangement
./hyprland-workspace-manager.sh

# Verify bindings were applied
hyprctl workspaces -j | jq '.[] | {id, monitor}'

# Test that it can move workspaces back (manually move workspace 1 first)
hyprctl dispatch moveworkspacetomonitor "1 DP-1"  # Move to external
./hyprland-workspace-manager.sh  # Should move it back to eDP-1
```

## Configuration Points

- **INTERNAL variable** (line 8): Hardcoded to "eDP-1". This is the only monitor name that needs modification for different internal display names.
- **Workspace range** (line 47): Currently binds workspaces 2-10 to external monitor. Adjust the `{2..10}` range if more workspaces are needed.

## Common Development Tasks

When modifying this script:

- Use `hyprctl monitors` to verify monitor detection logic
- Use `hyprctl workspaces -j` to inspect current workspace states
- The script automatically detects the first available external monitor (any monitor that is not eDP-1)

## Integration Points

Users can integrate this script into `~/.config/hypr/hyprland.conf` using:
- `exec-once = /path/to/hyprland-workspace-manager.sh` for startup arrangement
- Bind to a keybinding for manual triggering: `bind = $mainMod, W, exec, /path/to/hyprland-workspace-manager.sh`

For automatic triggering when monitors change, users can create a udev rule or use a separate monitor detection script.
