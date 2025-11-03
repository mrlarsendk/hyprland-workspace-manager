#!/usr/bin/env bash
#
# Hyprland Workspace Manager - Simple One-Time Execution
# Forces workspace 1 to eDP-1 (internal) and all others to external monitor
#

# Monitor names
INTERNAL="eDP-1"

# Check if internal monitor exists
internal_exists=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$INTERNAL\") | .name")
if [ -z "$internal_exists" ]; then
    echo "Error: Internal monitor $INTERNAL not found."
    echo "Available monitors:"
    hyprctl monitors -j | jq -r '.[].name'
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

echo "Detected monitors:"
echo "  Internal: $INTERNAL"
echo "  External: $external_monitor"
echo ""

# Move workspace 1 to internal monitor if it's on the wrong monitor
ws1_monitor=$(hyprctl workspaces -j | jq -r '.[] | select(.id == 1) | .monitor')
if [ "$ws1_monitor" != "$INTERNAL" ] && [ -n "$ws1_monitor" ]; then
    echo "Moving workspace 1 from $ws1_monitor to $INTERNAL..."
    hyprctl dispatch moveworkspacetomonitor "1 $INTERNAL"
fi

# Bind workspace 1 to internal display with persistent and default flags
echo "Binding workspace 1 to $INTERNAL..."
hyprctl keyword workspace "1,monitor:$INTERNAL,persistent:true,default:true" 2>/dev/null

# Bind workspaces 2-10 to external monitor
echo "Binding workspaces 2-10 to $external_monitor..."
for i in {2..10}; do
    # Move workspace to external monitor if it exists and is on the wrong monitor
    ws_monitor=$(hyprctl workspaces -j | jq -r ".[] | select(.id == $i) | .monitor")
    if [ -n "$ws_monitor" ] && [ "$ws_monitor" != "$external_monitor" ]; then
        echo "  Moving workspace $i from $ws_monitor to $external_monitor..."
        hyprctl dispatch moveworkspacetomonitor "$i $external_monitor"
    fi

    # Apply binding
    hyprctl keyword workspace "$i,monitor:$external_monitor,default:true" 2>/dev/null
done

echo ""
echo "✓ Workspace arrangement complete!"
echo "  Workspace 1  → $INTERNAL"
echo "  Workspaces 2-10 → $external_monitor"
