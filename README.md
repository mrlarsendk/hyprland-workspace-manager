# Hyprland Workspace Manager

Automatic workspace arrangement script for Hyprland on dual monitor setups. Ensures workspace 1 stays on your internal display while all other workspaces go to your external monitor.

## Features

- **Persistent Workspace 1**: Forces workspace 1 to always stay on the internal display (eDP-1)
- **Auto-detection**: Automatically detects and uses any connected external monitor
- **Monitor Independence**: Works with any external monitor name (DP-1, DP-6, HDMI-A-1, etc.)
- **Continuous Monitoring**: Optional mode to enforce workspace arrangement in real-time
- **Wayland Native**: Built specifically for Hyprland on Wayland

## Requirements

- Hyprland window manager
- `jq` - JSON processor for parsing Hyprland output
- `socat` - For monitoring mode (optional)

### Installing Dependencies

**Arch Linux:**
```bash
sudo pacman -S jq socat
```

**Ubuntu/Debian:**
```bash
sudo apt install jq socat
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

### Basic Commands

**Apply workspace bindings (one-time):**
```bash
./hyprland-workspace-manager.sh bind
```

**Enforce workspace 1 on internal display:**
```bash
./hyprland-workspace-manager.sh enforce
```

**Continuous monitoring mode:**
```bash
./hyprland-workspace-manager.sh monitor
```

**Show help:**
```bash
./hyprland-workspace-manager.sh --help
```

### Integration with Hyprland

Add one of the following to your `~/.config/hypr/hyprland.conf`:

**Option 1: Apply bindings on startup (recommended)**
```conf
exec-once = /path/to/hyprland-workspace-manager.sh bind
```

**Option 2: Continuous monitoring (more proactive)**
```conf
exec-once = /path/to/hyprland-workspace-manager.sh monitor
```

### Automatic Re-application on Monitor Change

To automatically reapply workspace bindings when monitors change, add this to your Hyprland config:

```conf
# Reapply workspace bindings when a monitor is connected/disconnected
exec-once = socat -U - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do if [[ "$line" == monitor* ]]; then /path/to/hyprland-workspace-manager.sh bind; fi; done &
```

## How It Works

The script performs the following actions:

1. **Detects Monitors**: Automatically identifies your internal display (eDP-1) and any connected external monitor
2. **Binds Workspaces**:
   - Workspace 1 → Internal display (eDP-1) with persistent flag
   - Workspaces 2-10 → External monitor
3. **Enforces Rules**: In monitor mode, watches for workspace changes and prevents workspace 1 from being moved

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
- Check that your monitor name isn't `eDP-1`

**Workspace 1 still moves to external monitor:**
- Use monitor mode: `./hyprland-workspace-manager.sh monitor`
- Check for conflicting workspace rules in your Hyprland config

**Command not found errors:**
- Ensure `jq` is installed: `which jq`
- For monitor mode, ensure `socat` is installed: `which socat`

## License

MIT License - feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Created for Hyprland users with hybrid laptop/external monitor setups.
