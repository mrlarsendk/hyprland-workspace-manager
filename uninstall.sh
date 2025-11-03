#!/usr/bin/env bash
#
# Uninstaller for Hyprland Workspace Manager
# Removes installed files and optionally removes configuration
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# File locations
LOCAL_BIN="$HOME/.local/bin/hyprland-workspace-manager"
SYSTEM_BIN="/usr/local/bin/hyprland-workspace-manager"
WAYBAR_SCRIPT="$HOME/.config/waybar/scripts/waybar-workspace-manager.sh"
WAYBAR_SCRIPTS_DIR="$HOME/.config/waybar/scripts"
STATE_FILE="$HOME/.cache/workspace-manager-state"
CONFIG_FILE="$HOME/.config/hyprland/workspace-manager.json"

# Parse command-line arguments
DRY_RUN=false
REMOVE_CONFIG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --remove-config)
            REMOVE_CONFIG="yes"
            shift
            ;;
        --keep-config)
            REMOVE_CONFIG="no"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Uninstalls Hyprland Workspace Manager and removes installed files."
            echo ""
            echo "Options:"
            echo "  --dry-run         Show what would be removed without actually removing"
            echo "  --remove-config   Remove configuration file without asking"
            echo "  --keep-config     Keep configuration file without asking"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Files that will be checked for removal:"
            echo "  - $LOCAL_BIN"
            echo "  - $SYSTEM_BIN"
            echo "  - $WAYBAR_SCRIPT"
            echo "  - $STATE_FILE"
            echo "  - $CONFIG_FILE (optional)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "==================================="
if [ "$DRY_RUN" = true ]; then
    echo "Uninstaller (DRY RUN MODE)"
else
    echo "Hyprland Workspace Manager Uninstaller"
fi
echo "==================================="
echo ""

# Track what will be/was removed
FILES_TO_REMOVE=()
DIRS_TO_CHECK=()

# Check for installed files
echo "Scanning for installed files..."
echo ""

if [ -f "$LOCAL_BIN" ]; then
    FILES_TO_REMOVE+=("$LOCAL_BIN")
    echo "  Found: $LOCAL_BIN"
fi

if [ -f "$SYSTEM_BIN" ]; then
    FILES_TO_REMOVE+=("$SYSTEM_BIN")
    echo "  Found: $SYSTEM_BIN"
    if [ ! -w "$SYSTEM_BIN" ]; then
        echo "  ⚠️  Warning: $SYSTEM_BIN requires sudo to remove"
    fi
fi

if [ -f "$WAYBAR_SCRIPT" ]; then
    FILES_TO_REMOVE+=("$WAYBAR_SCRIPT")
    DIRS_TO_CHECK+=("$WAYBAR_SCRIPTS_DIR")
    echo "  Found: $WAYBAR_SCRIPT"
fi

if [ -f "$STATE_FILE" ]; then
    FILES_TO_REMOVE+=("$STATE_FILE")
    echo "  Found: $STATE_FILE"
fi

if [ -f "$CONFIG_FILE" ]; then
    echo "  Found: $CONFIG_FILE (configuration)"
fi

echo ""

# Handle configuration file decision
if [ -f "$CONFIG_FILE" ] && [ -z "$REMOVE_CONFIG" ]; then
    echo "Configuration file found: $CONFIG_FILE"
    echo ""
    read -p "Do you want to remove your configuration file? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REMOVE_CONFIG="yes"
    else
        REMOVE_CONFIG="no"
    fi
    echo ""
fi

if [ "$REMOVE_CONFIG" = "yes" ] && [ -f "$CONFIG_FILE" ]; then
    FILES_TO_REMOVE+=("$CONFIG_FILE")
fi

# Check if anything to remove
if [ ${#FILES_TO_REMOVE[@]} -eq 0 ]; then
    echo "No installed files found. Nothing to uninstall."
    exit 0
fi

# Display what will be removed
echo "The following files will be removed:"
for file in "${FILES_TO_REMOVE[@]}"; do
    echo "  - $file"
done
echo ""

# Dry run mode - exit here
if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN: No files were actually removed."
    echo "Run without --dry-run to perform the uninstallation."
    exit 0
fi

# Confirm removal
if [ -t 0 ]; then  # Only prompt if running interactively
    read -p "Proceed with uninstallation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
    echo ""
fi

# Remove files
echo "Removing files..."
REMOVED_COUNT=0
NEEDS_SUDO=false

for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        if [ -w "$file" ] || [ -w "$(dirname "$file")" ]; then
            rm "$file"
            echo "  ✓ Removed: $file"
            ((REMOVED_COUNT++))
        else
            # Need sudo for this file
            if sudo rm "$file" 2>/dev/null; then
                echo "  ✓ Removed (sudo): $file"
                ((REMOVED_COUNT++))
                NEEDS_SUDO=true
            else
                echo "  ✗ Failed to remove: $file"
            fi
        fi
    fi
done

# Clean up empty directories
for dir in "${DIRS_TO_CHECK[@]}"; do
    if [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]; then
        rmdir "$dir"
        echo "  ✓ Removed empty directory: $dir"
    fi
done

echo ""
echo "==================================="
echo "Uninstallation Complete"
echo "==================================="
echo ""
echo "Summary:"
echo "  Files removed: $REMOVED_COUNT"
if [ "$REMOVE_CONFIG" = "no" ] && [ -f "$CONFIG_FILE" ]; then
    echo "  Configuration preserved: $CONFIG_FILE"
fi
echo ""

# Show manual cleanup instructions
if [ $REMOVED_COUNT -gt 0 ]; then
    echo "Manual cleanup steps:"
    echo ""
    echo "1. If you added waybar integration, remove this from ~/.config/waybar/config:"
    echo '   - Remove "custom/workspace-manager" from "modules-right"'
    echo '   - Remove the "custom/workspace-manager" module configuration'
    echo ""
    echo "2. If you added custom styling, remove this from ~/.config/waybar/style.css:"
    echo '   - Remove #custom-workspace-manager style rules'
    echo ""
    echo "3. If you added Hyprland integration, remove from ~/.config/hypr/hyprland.conf:"
    echo '   - Remove any "exec-once = .../hyprland-workspace-manager" lines'
    echo '   - Remove any keybindings that execute hyprland-workspace-manager'
    echo ""
    echo "4. Restart waybar if it's running: pkill waybar && waybar &"
    echo ""
fi

echo "Thank you for trying Hyprland Workspace Manager!"
