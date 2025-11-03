# Hyprland Workspace Manager

Configurable workspace arrangement script for Hyprland on dual monitor setups. Uses JSON configuration to define different workspace layouts for different external monitors.

## Features

- **JSON Configuration**: Define custom workspace arrangements per external monitor
- **Monitor-Specific Profiles**: Different layouts for home monitor, office monitor, etc.
- **Auto-detection**: Automatically detects connected monitors and applies the right profile
- **Waybar Integration**: Visual indicator and quick profile switching from your status bar
- **Workspace Migration**: Moves existing workspaces to correct monitors before applying bindings
- **One-Time Execution**: Run manually or via keybinding to force workspace arrangement
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

3. (Optional) Make the script accessible from anywhere:

**Option A: Symbolic link (recommended)**
```bash
sudo ln -s "$(pwd)/hyprland-workspace-manager.sh" /usr/local/bin/hyprland-workspace-manager
```

**Option B: Copy to PATH**
```bash
sudo cp hyprland-workspace-manager.sh /usr/local/bin/hyprland-workspace-manager
```

**Choosing between symlink and copy:**

*Symlink benefits:*
- Get updates automatically with `git pull` - no need to re-install
- Single source of truth - changes in the repo are immediately active
- Easier if you want to modify the script yourself
- No file duplication

*Symlink considerations:*
- Breaks if you move or delete the repository directory
- Requires being careful with `git reset --hard` or branch switching

*Copy benefits:*
- Independent of the repository - can move/delete the repo freely
- More stable if you don't need updates

Choose symlink if you want easy updates and plan to keep the repository. Choose copy if you want a standalone installation.

## Uninstallation

To remove Hyprland Workspace Manager from your system, use the provided uninstall script:

```bash
./uninstall.sh
```

The uninstaller will:
1. Scan for installed files in common locations
2. Ask whether you want to remove your configuration file (or keep it for future use)
3. Remove all installed components
4. Provide instructions for manual cleanup of waybar/Hyprland configs

### Uninstall Options

**Preview what will be removed (dry run):**
```bash
./uninstall.sh --dry-run
```

**Remove everything including configuration:**
```bash
./uninstall.sh --remove-config
```

**Keep your configuration file:**
```bash
./uninstall.sh --keep-config
```

**Get help:**
```bash
./uninstall.sh --help
```

### What Gets Removed

The uninstaller removes:
- Main script from `~/.local/bin/` or `/usr/local/bin/`
- Waybar integration script from `~/.config/waybar/scripts/`
- State file from `~/.cache/workspace-manager-state`
- Configuration file from `~/.config/hyprland/workspace-manager.json` (optional)

### Manual Cleanup

After uninstallation, you should manually remove any references in:
- `~/.config/waybar/config` - Remove the `custom/workspace-manager` module
- `~/.config/waybar/style.css` - Remove any custom styling for the module
- `~/.config/hypr/hyprland.conf` - Remove `exec-once` or keybinding entries

The uninstaller will provide specific instructions for these manual steps.

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

## Configuration

The script uses a JSON configuration file located at `~/.config/hyprland/workspace-manager.json`. On first run, a default configuration will be automatically created.

### Configuration File Structure

```json
{
  "internal_monitor": "eDP-1",
  "profiles": {
    "HDMI-A-1": {
      "name": "HDMI Monitor",
      "internal_workspaces": [1, 2, 3, 4, 5],
      "external_workspaces": [6, 7, 8, 9, 10]
    },
    "DP-7": {
      "name": "Office DisplayPort Monitor",
      "internal_workspaces": [1],
      "external_workspaces": [2, 3, 4, 5, 6, 7, 8, 9, 10]
    },
    "default": {
      "name": "Default Configuration",
      "internal_workspaces": [1],
      "external_workspaces": [2, 3, 4, 5, 6, 7, 8, 9, 10]
    }
  }
}
```

### Customizing Profiles

1. **Edit the config file**:
   ```bash
   nano ~/.config/hyprland/workspace-manager.json
   ```

2. **Add a new monitor profile**:
   - Find your monitor name: `hyprctl monitors`
   - Add a new profile with your monitor's name
   - Define which workspaces go on internal vs external

3. **Example: Split workspaces evenly**:
   ```json
   "HDMI-A-1": {
     "name": "Home Monitor",
     "internal_workspaces": [1, 2, 3, 4, 5],
     "external_workspaces": [6, 7, 8, 9, 10]
   }
   ```

4. **Example: Most workspaces on external**:
   ```json
   "DP-1": {
     "name": "Main Work Monitor",
     "internal_workspaces": [1],
     "external_workspaces": [2, 3, 4, 5, 6, 7, 8, 9, 10]
   }
   ```

The script will automatically use the appropriate profile when you connect different monitors. If no specific profile exists for a monitor, it will use the "default" profile.

## Waybar Integration

The workspace manager can be integrated with waybar for a visual interface to switch between profiles.

### Features

- **Visual Indicator**: Shows current profile in your waybar
- **Click to Switch**: Click the icon to open a menu with available profiles
- **Tooltip**: Hover to see detailed workspace configuration
- **Auto-Update**: Updates automatically when profiles change

### Installation

Run the installation helper:
```bash
./scripts/install-waybar.sh
```

This will:
1. Copy the waybar module script to `~/.config/waybar/scripts/`
2. Show you the configuration to add to your waybar config
3. Provide example CSS styling

### Manual Installation

1. **Copy the script**:
   ```bash
   cp scripts/waybar-workspace-manager.sh ~/.config/waybar/scripts/
   chmod +x ~/.config/waybar/scripts/waybar-workspace-manager.sh
   ```

2. **Add to waybar config** (`~/.config/waybar/config`):
   ```json
   {
       "modules-right": ["...", "custom/workspace-manager", "..."],

       "custom/workspace-manager": {
           "format": " {}",
           "return-type": "json",
           "interval": 30,
           "exec": "~/.config/waybar/scripts/waybar-workspace-manager.sh status",
           "on-click": "~/.config/waybar/scripts/waybar-workspace-manager.sh menu",
           "signal": 12,
           "escape": true
       }
   }
   ```

3. **(Optional) Add styling** to `~/.config/waybar/style.css`:
   ```css
   #custom-workspace-manager {
       padding: 0 10px;
       color: #a6e3a1;
   }

   #custom-workspace-manager.inactive {
       color: #6c7086;
   }
   ```

4. **Restart waybar**:
   ```bash
   pkill waybar && waybar &
   ```

### Requirements

The waybar integration requires either **wofi** (recommended for Wayland) or **rofi** for the profile selection menu:

```bash
# Arch Linux
sudo pacman -S wofi

# Ubuntu/Debian
sudo apt install wofi
```

See `examples/` directory for complete config and style examples.

## How It Works

The script performs the following actions:

1. **Loads Configuration**: Reads workspace profiles from `~/.config/hyprland/workspace-manager.json`
2. **Detects Monitors**: Identifies your internal display and connected external monitor
3. **Selects Profile**: Chooses the appropriate workspace layout based on the external monitor name
4. **Moves Workspaces**: Relocates existing workspaces to their configured monitors
5. **Applies Bindings**: Sets persistent workspace-to-monitor bindings

### Finding Your Monitor Names

To find your monitor names for configuration:
```bash
hyprctl monitors
```

Look for the `name` field in the output. Common names include:
- `eDP-1` - Internal laptop display
- `HDMI-A-1` - HDMI port
- `DP-1`, `DP-2`, etc. - DisplayPort connections

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

**Wrong workspace configuration applied:**
- Check which monitor is detected: `hyprctl monitors`
- Verify your config has a profile for that monitor: `cat ~/.config/hyprland/workspace-manager.json`
- Add a new profile for your monitor or update the "default" profile

**Configuration file errors:**
- Validate JSON syntax: `jq . ~/.config/hyprland/workspace-manager.json`
- Delete and re-run script to regenerate default: `rm ~/.config/hyprland/workspace-manager.json && ./hyprland-workspace-manager.sh`

## License

MIT License - feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Created for Hyprland users with hybrid laptop/external monitor setups.
