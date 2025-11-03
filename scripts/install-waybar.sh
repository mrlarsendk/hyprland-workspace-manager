#!/usr/bin/env bash
#
# Installation Helper for Waybar Integration
# Installs and configures the workspace manager waybar module
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAYBAR_SCRIPTS_DIR="$HOME/.config/waybar/scripts"
WAYBAR_CONFIG="$HOME/.config/waybar/config"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"

echo "==================================="
echo "Waybar Integration Installer"
echo "==================================="
echo ""

# Check if waybar is installed
if ! command -v waybar &> /dev/null; then
    echo "❌ Waybar is not installed."
    echo "Please install waybar first:"
    echo "  Arch: sudo pacman -S waybar"
    echo "  Ubuntu/Debian: sudo apt install waybar"
    exit 1
fi

echo "✓ Waybar is installed"

# Check for menu tool (wofi or rofi)
if command -v wofi &> /dev/null; then
    echo "✓ Wofi found (will be used for menus)"
    MENU_TOOL="wofi"
elif command -v rofi &> /dev/null; then
    echo "✓ Rofi found (will be used for menus)"
    MENU_TOOL="rofi"
else
    echo "⚠️  Neither wofi nor rofi found"
    echo "Please install one of them for menu functionality:"
    echo "  Arch: sudo pacman -S wofi"
    echo "  Ubuntu/Debian: sudo apt install wofi"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "Installing waybar module..."

# Create waybar scripts directory
mkdir -p "$WAYBAR_SCRIPTS_DIR"

# Copy waybar module script
if [ -f "$SCRIPT_DIR/waybar-workspace-manager.sh" ]; then
    cp "$SCRIPT_DIR/waybar-workspace-manager.sh" "$WAYBAR_SCRIPTS_DIR/"
    chmod +x "$WAYBAR_SCRIPTS_DIR/waybar-workspace-manager.sh"
    echo "✓ Copied waybar module script to $WAYBAR_SCRIPTS_DIR"
else
    echo "❌ Error: waybar-workspace-manager.sh not found in $SCRIPT_DIR"
    exit 1
fi

echo ""
echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Add this module to your waybar config ($WAYBAR_CONFIG):"
echo ""
echo '   "modules-right": ["...", "custom/workspace-manager", "..."],'
echo ""
echo '   "custom/workspace-manager": {'
echo '       "format": " {}",'
echo '       "return-type": "json",'
echo '       "interval": 30,'
echo '       "exec": "~/.config/waybar/scripts/waybar-workspace-manager.sh status",'
echo '       "on-click": "~/.config/waybar/scripts/waybar-workspace-manager.sh menu",'
echo '       "signal": 8,'
echo '       "escape": true'
echo '   }'
echo ""
echo "2. (Optional) Add custom styling to your waybar style ($WAYBAR_STYLE):"
echo ""
echo '   #custom-workspace-manager {'
echo '       padding: 0 10px;'
echo '       color: #a6e3a1;'
echo '   }'
echo ''
echo '   #custom-workspace-manager.inactive {'
echo '       color: #6c7086;'
echo '   }'
echo ''
echo '   #custom-workspace-manager.error {'
echo '       color: #f38ba8;'
echo '   }'
echo ""
echo "3. Restart waybar: pkill waybar && waybar &"
echo ""
echo "4. Run the workspace manager to initialize: hyprland-workspace-manager"
echo ""
echo "For more information, see the README.md"
