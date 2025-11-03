#!/usr/bin/env bash
#
# Waybar Module for Hyprland Workspace Manager
# Displays current workspace profile and allows switching via menu
#

# Configuration
STATE_FILE="$HOME/.cache/workspace-manager-state"
CONFIG_FILE="$HOME/.config/hyprland/workspace-manager.json"

# Find the workspace manager script in PATH
MANAGER_SCRIPT="$(command -v hyprland-workspace-manager 2>/dev/null)"
if [ -z "$MANAGER_SCRIPT" ]; then
    # Fallback: look for it in common locations
    if [ -x "$HOME/.local/bin/hyprland-workspace-manager" ]; then
        MANAGER_SCRIPT="$HOME/.local/bin/hyprland-workspace-manager"
    elif [ -x "/usr/local/bin/hyprland-workspace-manager" ]; then
        MANAGER_SCRIPT="/usr/local/bin/hyprland-workspace-manager"
    fi
fi

# Icon (Nerd Font)
ICON=""

# Function to get current state
get_status() {
    # Check if state file exists
    if [ ! -f "$STATE_FILE" ]; then
        jq -nc '{"text": "N/A", "tooltip": "No profile applied yet\nRun workspace manager to initialize", "class": "inactive"}'
        return
    fi

    # Read state file
    if ! state=$(cat "$STATE_FILE" 2>/dev/null); then
        jq -nc '{"text": "ERR", "tooltip": "Error reading state file", "class": "error"}'
        return
    fi

    # Parse state
    profile_name=$(echo "$state" | jq -r '.name // "Unknown"')
    monitor=$(echo "$state" | jq -r '.profile // "Unknown"')
    internal_ws=$(echo "$state" | jq -r '.internal_workspaces // [] | map(tostring) | join(", ")')
    external_ws=$(echo "$state" | jq -r '.external_workspaces // [] | map(tostring) | join(", ")')

    # Build tooltip (using actual newlines, not \n literals)
    tooltip="Profile: $profile_name
Monitor: $monitor
Internal: [$internal_ws]
External: [$external_ws]"

    # Output JSON (compact format for waybar)
    jq -nc \
        --arg text "$monitor" \
        --arg tooltip "$tooltip" \
        '{"text": $text, "tooltip": $tooltip, "class": "active"}'
}

# Function to show menu and apply selection
show_menu() {
    # Check if config exists
    if [ ! -f "$CONFIG_FILE" ]; then
        notify-send "Workspace Manager" "Config file not found: $CONFIG_FILE" -u critical
        exit 1
    fi

    # Get currently connected monitors
    if ! command -v hyprctl &> /dev/null; then
        notify-send "Workspace Manager" "hyprctl not found" -u critical
        exit 1
    fi

    connected_monitors=$(hyprctl monitors -j | jq -r '.[].name')

    # Get internal monitor from config
    internal_monitor=$(jq -r '.internal_monitor' "$CONFIG_FILE")

    # Build list of available profiles
    profiles=()

    # Add profiles for currently connected external monitors
    for monitor in $connected_monitors; do
        if [ "$monitor" != "$internal_monitor" ]; then
            profile_name=$(jq -r ".profiles[\"$monitor\"].name // empty" "$CONFIG_FILE")
            if [ -n "$profile_name" ]; then
                profiles+=("$monitor|$profile_name")
            fi
        fi
    done

    # Always add default profile
    default_name=$(jq -r '.profiles["default"].name // "Default Configuration"' "$CONFIG_FILE")
    profiles+=("default|$default_name")

    # Check if we have any profiles
    if [ ${#profiles[@]} -eq 0 ]; then
        notify-send "Workspace Manager" "No profiles available" -u normal
        exit 0
    fi

    # Format menu items
    menu_items=""
    for profile in "${profiles[@]}"; do
        monitor_id=$(echo "$profile" | cut -d'|' -f1)
        profile_name=$(echo "$profile" | cut -d'|' -f2)
        menu_items+="$profile_name ($monitor_id)\n"
    done

    # Show menu using tui-selector, wofi, or rofi
    if command -v tui-selector &> /dev/null; then
        selected=$(echo -e "$menu_items" | tui-selector --prompt "Select Workspace Profile")
    elif command -v wofi &> /dev/null; then
        selected=$(echo -e "$menu_items" | wofi --dmenu --prompt "Select Workspace Profile:" --width 400 --height 300)
    elif command -v rofi &> /dev/null; then
        selected=$(echo -e "$menu_items" | rofi -dmenu -i -p "Select Workspace Profile:" -theme-str 'window {width: 400px;}')
    else
        notify-send "Workspace Manager" "No menu selector found. Please install tui-selector, wofi, or rofi." -u critical
        exit 1
    fi

    # Check if user made a selection
    if [ -z "$selected" ]; then
        exit 0
    fi

    # Extract monitor ID from selection
    selected_monitor=$(echo "$selected" | grep -oP '\(.*\)' | tr -d '()')

    # Apply the profile
    if [ -x "$MANAGER_SCRIPT" ]; then
        "$MANAGER_SCRIPT" --profile "$selected_monitor" && \
        notify-send "Workspace Manager" "Applied profile: $selected" -u low

        # Signal waybar to update
        pkill -RTMIN+12 waybar 2>/dev/null
    else
        notify-send "Workspace Manager" "Manager script not found or not executable: $MANAGER_SCRIPT" -u critical
        exit 1
    fi
}

# Main execution
case "${1:-status}" in
    status)
        get_status
        ;;
    menu)
        show_menu
        ;;
    --help|-h)
        echo "Usage: $0 [status|menu]"
        echo ""
        echo "Commands:"
        echo "  status - Output current profile status as JSON (for waybar)"
        echo "  menu   - Show profile selection menu and apply"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
