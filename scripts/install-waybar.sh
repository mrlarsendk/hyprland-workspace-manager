#!/usr/bin/env bash
#
# Installation Helper for Waybar Integration
# Installs and configures the workspace manager waybar module
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
WAYBAR_SCRIPTS_DIR="$HOME/.config/waybar/scripts"
LOCAL_BIN="$HOME/.local/bin"
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
echo "Installing workspace manager..."

# Create local bin directory
mkdir -p "$LOCAL_BIN"

# Install main workspace manager script to ~/.local/bin
if [ -f "$REPO_ROOT/hyprland-workspace-manager.sh" ]; then
    cp "$REPO_ROOT/hyprland-workspace-manager.sh" "$LOCAL_BIN/hyprland-workspace-manager"
    chmod +x "$LOCAL_BIN/hyprland-workspace-manager"
    echo "✓ Installed main script to $LOCAL_BIN/hyprland-workspace-manager"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
        echo "⚠️  Warning: $LOCAL_BIN is not in your PATH"
        echo "   Add this to your ~/.bashrc or ~/.zshrc:"
        echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
else
    echo "❌ Error: hyprland-workspace-manager.sh not found in $REPO_ROOT"
    exit 1
fi

# Copy default config if needed
CONFIG_DIR="$HOME/.config/hyprland"
CONFIG_FILE="$CONFIG_DIR/workspace-manager.json"
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_FILE" ] && [ -f "$REPO_ROOT/workspace-manager.json" ]; then
    cp "$REPO_ROOT/workspace-manager.json" "$CONFIG_FILE"
    echo "✓ Created default config at $CONFIG_FILE"
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
echo '       "signal": 12,'
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
