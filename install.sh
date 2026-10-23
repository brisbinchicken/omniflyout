#!/usr/bin/env bash
# ==============================================================================
# OmniFlyout — Installation Script
# Created by HearneLabs
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$DIR/package"
PLUGIN_ID="org.hearnelabs.omniflyout"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}        OmniFlyout — Plasma 6 Installer             ${NC}"
echo -e "${CYAN}              Created by HearneLabs                 ${NC}"
echo -e "${CYAN}====================================================${NC}"

# Check for kpackagetool6
if ! command -v kpackagetool6 &>/dev/null; then
    echo -e "${RED}Error: kpackagetool6 not found!${NC}"
    echo "Please ensure KDE Plasma 6 is installed on your system."
    exit 1
fi

# Ensure executable permissions on all backend scripts
echo "Setting executable permissions on backend scripts..."
chmod +x "$PACKAGE_DIR"/contents/scripts/*.sh

# Check if already installed
if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -q "$PLUGIN_ID"; then
    echo -e "Upgrading existing OmniFlyout installation (${CYAN}$PLUGIN_ID${NC})..."
    kpackagetool6 -t Plasma/Applet -u "$PACKAGE_DIR"
else
    echo -e "Installing OmniFlyout (${CYAN}$PLUGIN_ID${NC})..."
    kpackagetool6 -t Plasma/Applet -i "$PACKAGE_DIR"
fi

echo -e "\n${GREEN}✔ Successfully installed OmniFlyout!${NC}"
echo -e "To add it to your panel:"
echo -e "  1. Right-click your KDE panel and select '${CYAN}Add Widgets...${NC}'"
echo -e "  2. Search for '${CYAN}OmniFlyout${NC}' and drag it to your panel."
echo -e "\nTo test it immediately in a window, run:"
echo -e "  ${CYAN}plasmawindowed $PLUGIN_ID${NC}"
echo -e "${CYAN}====================================================${NC}"
