# Hyprland Workspace Manager

Simple manual workspace arrangement script for Hyprland on dual monitor setups. Forces workspace 1 to your internal display while routing all other workspaces to your external monitor.

## Features

- **One-Time Execution**: Run manually or via keybinding to force workspace arrangement
- **Auto-detection**: Automatically detects and uses any connected external monitor
- **Monitor Independence**: Works with any external monitor name (DP-1, DP-6, HDMI-A-1, etc.)
- **Workspace Migration**: Moves existing workspaces to correct monitors before applying bindings
- **Wayland Native**: Built specifically for Hyprland on Wayland

## Requirements

- Hyprland window manager
- `jq` - JSON processor for parsing Hyprland output

### Installing Dependencies

**Arch Linux:**
```bash
sudo pacman -S jq
```

**Ubuntu/Debian:**
```bash
sudo apt install jq
```

## Installation

1. Clone this repository:
```bash
git clone https://github.com/mrlarsendk/hyprland-workspace-manager.git
cd hyprland-workspace-manager
```

2. Make the script executable:
```bash
chmod +x hyprland-workspace-manager.sh
```

3. (Optional) Move to a location in your PATH:
```bash
sudo cp hyprland-workspace-manager.sh /usr/local/bin/hyprland-workspace-manager
```

## Usage

### Basic Command

**Force workspace arrangement:**
```bash
./hyprland-workspace-manager.sh
```

That's it! The script will:
1. Detect your internal monitor (eDP-1) and external monitor
2. Move workspace 1 to the internal monitor (if needed)
3. Move workspaces 2-10 to the external monitor (if needed)
4. Apply persistent bindings to prevent future drift

### Integration with Hyprland

Add one of the following to your `~/.config/hypr/hyprland.conf`:

**Option 1: Run on startup**
```conf
exec-once = /path/to/hyprland-workspace-manager.sh
```

**Option 2: Bind to a keybinding for manual triggering**
```conf
bind = $mainMod, W, exec, /path/to/hyprland-workspace-manager.sh
```

Replace `$mainMod` with your preferred modifier key (e.g., `SUPER`, `ALT`, etc.).

## How It Works

The script performs the following actions:

1. **Detects Monitors**: Automatically identifies your internal display (eDP-1) and any connected external monitor
2. **Moves Workspaces**: Checks current workspace locations and moves them to correct monitors if needed
3. **Binds Workspaces**:
   - Workspace 1 → Internal display (eDP-1) with persistent and default flags
   - Workspaces 2-10 → External monitor with default flag

## Configuration

The internal monitor is hardcoded as `eDP-1`. To change this, edit the script:

```bash
# Monitor names
INTERNAL="eDP-1"  # Change this to your internal monitor name
```

To find your monitor names, run:
```bash
hyprctl monitors
```

## Troubleshooting

**Script doesn't detect external monitor:**
- Run `hyprctl monitors` to verify your monitor is detected by Hyprland
- Ensure both monitors are connected before running the script
- Check that your external monitor name isn't `eDP-1`

**Workspace 1 still moves to external monitor:**
- Run the script again to force the arrangement: `./hyprland-workspace-manager.sh`
- Check for conflicting workspace rules in your Hyprland config
- Consider binding the script to a keybinding for quick access

**Command not found errors:**
- Ensure `jq` is installed: `which jq`
- Install jq if missing: `sudo pacman -S jq` (Arch) or `sudo apt install jq` (Ubuntu/Debian)

## License

MIT License - feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Created for Hyprland users with hybrid laptop/external monitor setups.
