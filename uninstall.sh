#!/usr/bin/env bash
# ==============================================================================
# OmniFlyout — Uninstallation Script
# Created by HearneLabs
# ==============================================================================
set -e

PLUGIN_ID="org.hearnelabs.omniflyout"
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Uninstalling OmniFlyout ($PLUGIN_ID)...${NC}"

if kpackagetool6 -t Plasma/Applet -r "$PLUGIN_ID" 2>/dev/null; then
    echo -e "${GREEN}✔ Successfully uninstalled OmniFlyout.${NC}"
else
    echo -e "${RED}OmniFlyout is not currently installed.${NC}"
fi
