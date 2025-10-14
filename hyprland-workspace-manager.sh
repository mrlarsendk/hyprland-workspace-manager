#!/usr/bin/env bash
#
# Hyprland Workspace Manager for Hybrid Dual Monitor Setup
# Ensures workspace 1 stays on eDP-1 (internal) and all others on external monitor
#

# Monitor names
INTERNAL="eDP-1"

# Function to get the current external monitor name
get_external_monitor() {
    # Get all monitors except the internal one
    hyprctl monitors -j | jq -r ".[] | select(.name != \"$INTERNAL\") | .name" | head -n1
}

# Function to bind workspaces to monitors
bind_workspaces() {
    # Wait for monitors to be fully initialized
    sleep 1

    # Check if internal monitor exists
    local internal_exists=$(hyprctl monitors -j | jq -r ".[] | select(.name == \"$INTERNAL\") | .name")
    if [ -z "$internal_exists" ]; then
        echo "Error: Internal monitor $INTERNAL not found."
        echo "Available monitors:"
        hyprctl monitors -j | jq -r '.[].name'
        return 1
    fi

    local external_monitor=$(get_external_monitor)

    # If no external monitor detected, only bind workspace 1
    if [ -z "$external_monitor" ]; then
        echo "No external monitor detected."
        echo "Binding workspace 1 to $INTERNAL only."
        hyprctl keyword workspace "1,monitor:$INTERNAL default:true persistent:true" 2>/dev/null
        return
    fi

    echo "Binding workspaces..."
    echo "Internal monitor: $INTERNAL (workspace 1)"
    echo "External monitor: $external_monitor (workspaces 2-10)"

    # Bind workspace 1 to internal display
    hyprctl keyword workspace "1,monitor:$INTERNAL default:true persistent:true" 2>/dev/null

    # Bind workspaces 2-10 to external monitor
    for i in {2..10}; do
        hyprctl keyword workspace "$i,monitor:$external_monitor default:true" 2>/dev/null
    done

    echo "Workspace bindings applied successfully!"
}

# Function to move workspace 1 back to internal if it gets moved
enforce_workspace_1() {
    local ws1_monitor=$(hyprctl workspaces -j | jq -r '.[] | select(.id == 1) | .monitor')

    if [ "$ws1_monitor" != "$INTERNAL" ] && [ -n "$ws1_monitor" ]; then
        echo "Workspace 1 detected on $ws1_monitor, moving back to $INTERNAL..."
        hyprctl dispatch moveworkspacetomonitor "1 $INTERNAL"
    fi
}

# Function to monitor and maintain workspace arrangement
monitor_workspaces() {
    # Check if HYPRLAND_INSTANCE_SIGNATURE is set
    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        echo "Error: HYPRLAND_INSTANCE_SIGNATURE not set. Monitor mode requires running inside Hyprland."
        exit 1
    fi

    local socket_path="/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

    # Check if socket exists
    if [ ! -S "$socket_path" ]; then
        echo "Error: Hyprland socket not found at $socket_path"
        exit 1
    fi

    echo "Monitoring workspace changes... (Press Ctrl+C to stop)"

    # Subscribe to workspace events
    socat -U - UNIX-CONNECT:"$socket_path" | while read -r line; do
        # Check events related to workspace changes
        if [[ "$line" == workspace* ]] || [[ "$line" == moveworkspace* ]]; then
            enforce_workspace_1
        fi
    done
}

# Main execution
case "${1:-bind}" in
    bind)
        bind_workspaces
        ;;
    enforce)
        enforce_workspace_1
        ;;
    monitor)
        bind_workspaces
        monitor_workspaces
        ;;
    --help|-h)
        echo "Usage: $0 [bind|enforce|monitor]"
        echo ""
        echo "Commands:"
        echo "  bind     - Apply workspace bindings (default)"
        echo "  enforce  - Check and enforce workspace 1 on internal display"
        echo "  monitor  - Continuously monitor and enforce workspace arrangement"
        echo ""
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
