#!/usr/bin/env bash
#
# Hyprland Workspace Manager - Configurable Workspace Arrangement
# Uses JSON config to define different workspace layouts per external monitor
#

# Configuration file location
CONFIG_DIR="$HOME/.config/hyprland"
CONFIG_FILE="$CONFIG_DIR/workspace-manager.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG="$SCRIPT_DIR/workspace-manager.json"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Copy default config if user config doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    if [ -f "$DEFAULT_CONFIG" ]; then
        echo "Creating default config at $CONFIG_FILE"
        cp "$DEFAULT_CONFIG" "$CONFIG_FILE"
        echo "You can customize monitor profiles by editing: $CONFIG_FILE"
        echo ""
    else
        echo "Error: Default config not found at $DEFAULT_CONFIG"
        echo "Please ensure workspace-manager.json exists in the script directory."
        exit 1
    fi
fi

# Read configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Get internal monitor from config
INTERNAL=$(jq -r '.internal_monitor' "$CONFIG_FILE")

# Check if internal monitor exists
internal_exists=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$INTERNAL\") | .name")
if [ -z "$internal_exists" ]; then
    echo "Error: Internal monitor $INTERNAL not found."
    echo "Available monitors:"
    hyprctl monitors -j | jq -r '.[].name'
    echo ""
    echo "Update internal_monitor in: $CONFIG_FILE"
    exit 1
fi

# Get the external monitor (first non-internal monitor)
external_monitor=$(hyprctl monitors -j | jq -r ".[] | select(.name != \"$INTERNAL\") | .name" | head -n1)

# Check if external monitor exists
if [ -z "$external_monitor" ]; then
    echo "Error: No external monitor detected."
    echo "Only internal monitor $INTERNAL is connected."
    exit 1
fi

# Get profile for this monitor (fall back to default if not found)
profile_exists=$(jq -r ".profiles[\"$external_monitor\"] // empty" "$CONFIG_FILE")
if [ -z "$profile_exists" ]; then
    echo "No specific profile found for $external_monitor, using default"
    profile_name="default"
else
    profile_name="$external_monitor"
fi

# Read workspace configuration from profile
profile_display_name=$(jq -r ".profiles[\"$profile_name\"].name" "$CONFIG_FILE")
internal_workspaces=($(jq -r ".profiles[\"$profile_name\"].internal_workspaces[]" "$CONFIG_FILE"))
external_workspaces=($(jq -r ".profiles[\"$profile_name\"].external_workspaces[]" "$CONFIG_FILE"))

echo "Detected monitors:"
echo "  Internal: $INTERNAL"
echo "  External: $external_monitor"
echo ""
echo "Using profile: $profile_display_name"
echo "  Internal workspaces: ${internal_workspaces[*]}"
echo "  External workspaces: ${external_workspaces[*]}"
echo ""

# Move and bind internal workspaces
for ws in "${internal_workspaces[@]}"; do
    # Move workspace to internal monitor if it exists and is on the wrong monitor
    ws_monitor=$(hyprctl workspaces -j | jq -r ".[] | select(.id == $ws) | .monitor")
    if [ -n "$ws_monitor" ] && [ "$ws_monitor" != "$INTERNAL" ]; then
        echo "Moving workspace $ws from $ws_monitor to $INTERNAL..."
        hyprctl dispatch moveworkspacetomonitor "$ws $INTERNAL"
    fi

    # Apply binding (workspace 1 gets persistent flag)
    if [ "$ws" -eq 1 ]; then
        hyprctl keyword workspace "$ws,monitor:$INTERNAL,persistent:true,default:true" 2>/dev/null
    else
        hyprctl keyword workspace "$ws,monitor:$INTERNAL,default:true" 2>/dev/null
    fi
done

# Move and bind external workspaces
for ws in "${external_workspaces[@]}"; do
    # Move workspace to external monitor if it exists and is on the wrong monitor
    ws_monitor=$(hyprctl workspaces -j | jq -r ".[] | select(.id == $ws) | .monitor")
    if [ -n "$ws_monitor" ] && [ "$ws_monitor" != "$external_monitor" ]; then
        echo "Moving workspace $ws from $ws_monitor to $external_monitor..."
        hyprctl dispatch moveworkspacetomonitor "$ws $external_monitor"
    fi

    # Apply binding
    hyprctl keyword workspace "$ws,monitor:$external_monitor,default:true" 2>/dev/null
done

echo ""
echo "✓ Workspace arrangement complete!"
echo "  Workspaces ${internal_workspaces[*]} → $INTERNAL"
echo "  Workspaces ${external_workspaces[*]} → $external_monitor"
