# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hyprland Workspace Manager is a configurable bash script for workspace arrangement in Hyprland dual monitor setups. It uses JSON configuration to define different workspace layouts for different external monitors, allowing users to have monitor-specific workspace arrangements.

## Architecture

The project consists of:

1. **hyprland-workspace-manager.sh**: Main bash script that executes once when run
2. **workspace-manager.json**: Default JSON configuration file with monitor profiles

### Script Flow

1. **Configuration Management**:
   - Checks for user config at `~/.config/hyprland/workspace-manager.json`
   - Creates default config from `workspace-manager.json` if not found
   - Reads internal monitor name and workspace profiles from JSON

2. **Monitor Detection**:
   - Identifies internal monitor and first connected external monitor using `hyprctl monitors -j`
   - Selects appropriate workspace profile based on external monitor name
   - Falls back to "default" profile if no specific profile exists

3. **Workspace Arrangement**:
   - Moves existing workspaces to their configured monitors using `hyprctl dispatch moveworkspacetomonitor`
   - Applies persistent bindings using `hyprctl keyword workspace` commands
   - Workspace 1 gets `persistent:true` flag on internal monitor

### Configuration Format

The JSON config allows polymorphic behavior based on connected monitor:

```json
{
  "internal_monitor": "eDP-1",
  "profiles": {
    "HDMI-A-1": { "name": "...", "internal_workspaces": [...], "external_workspaces": [...] },
    "default": { ... }
  }
}
```

Each profile defines which workspaces go on internal vs external monitors.

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

- **User config location**: `~/.config/hyprland/workspace-manager.json`
- **Default config**: `workspace-manager.json` in the repository root
- **Internal monitor**: Configured via JSON `internal_monitor` field (default: "eDP-1")
- **Workspace ranges**: Defined per-profile in JSON using `internal_workspaces` and `external_workspaces` arrays
- **Adding new monitors**: Create new profile entries in the JSON config with the monitor name as key

## Common Development Tasks

When modifying this script:

- Use `hyprctl monitors` to verify monitor detection logic
- Use `hyprctl workspaces -j` to inspect current workspace states
- Validate JSON config: `jq . ~/.config/hyprland/workspace-manager.json`
- Test with different monitors by editing the config and running the script
- The script automatically detects the first available external monitor (any monitor not matching internal_monitor)

## Integration Points

### Hyprland Integration

Users can integrate this script into `~/.config/hypr/hyprland.conf` using:
- `exec-once = /path/to/hyprland-workspace-manager.sh` for startup arrangement
- Bind to a keybinding for manual triggering: `bind = $mainMod, W, exec, /path/to/hyprland-workspace-manager.sh`

For automatic triggering when monitors change, users can create a udev rule or use a separate monitor detection script.

### Waybar Integration

The project includes waybar integration for visual profile switching:

**Components:**
- `scripts/waybar-workspace-manager.sh`: Waybar custom module script
- `scripts/install-waybar.sh`: Installation helper
- `examples/waybar-config-example.json`: Example waybar config
- `examples/waybar-style-example.css`: Example CSS styling

**Architecture:**
1. Main script writes state file to `~/.cache/workspace-manager-state` after applying profiles
2. Waybar module reads state file and outputs JSON for display
3. On click, waybar module shows wofi/rofi menu with available profiles
4. Selecting a profile runs main script with `--profile` flag
5. Main script signals waybar (RTMIN+12) after changes for instant updates

**State File Format:**
```json
{
  "profile": "DP-7",
  "name": "Office DisplayPort Monitor",
  "monitor": "DP-7",
  "internal_workspaces": [1],
  "external_workspaces": [2, 3, 4, 5, 6, 7, 8, 9, 10],
  "timestamp": 1234567890
}
```

**Command-Line Flags:**
- `--profile <name>`: Force a specific profile instead of auto-detection
- `--help`: Show usage information
