#!/bin/bash
#
# AutoGPT-Termux uninstall script
# Removes proot Ubuntu container and all AutoGPT data
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${RED}${BOLD}"
echo "╔═════════════════════════════════════════════╗"
echo "║         AutoGPT-Termux  ·  Uninstall        ║"
echo "╚═════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${RED}⚠ WARNING: This will permanently delete:${NC}"
echo -e "  • The Ubuntu proot container (~1-2 GB)"
echo -e "  • All AutoGPT data, memory, and logs"
echo -e "  • API keys stored in .env"
echo ""
read -r -p "Are you sure? Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}↷ Uninstall cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Stopping agent...${NC}"
proot-distro login ubuntu -- bash -c "
    pkill -9 -f 'autogpt' 2>/dev/null || true
    pkill -9 -f 'server.py' 2>/dev/null || true
" 2>/dev/null || true

echo -e "${YELLOW}Removing Ubuntu container...${NC}"
proot-distro remove ubuntu --force 2>/dev/null || \
    proot-distro remove ubuntu 2>/dev/null || true

echo -e "${GREEN}✓ Ubuntu container removed${NC}"
echo ""
echo -e "${YELLOW}To remove the autogptx CLI itself:${NC}"
echo -e "  ${CYAN}npm uninstall -g autogpt-termux${NC}"
echo ""
echo -e "${GREEN}Done. Thanks for using AutoGPT-Termux!${NC}"
echo ""
