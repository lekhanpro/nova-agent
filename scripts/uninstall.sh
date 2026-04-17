#!/bin/bash
# novax uninstall — remove nova_agent.py and config

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${RED}${BOLD}"
echo "╔═══════════════════════════════════════════╗"
echo "║       Nova Agent  ·  Uninstall            ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${RED}⚠ This will remove:${NC}"
echo -e "  • ${YELLOW}$PREFIX/lib/nova_agent.py${NC}"
echo -e "  • ${YELLOW}~/.nova_agent/config.json${NC} (API keys + settings)"
echo ""
read -r -p "Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}↷ Uninstall cancelled.${NC}"
    exit 0
fi

rm -f "$PREFIX/lib/nova_agent.py" && echo -e "${GREEN}✓ nova_agent.py removed${NC}"
rm -rf "$HOME/.nova_agent"        && echo -e "${GREEN}✓ Config removed${NC}"

echo ""
echo -e "${YELLOW}To also remove the npm package:${NC}"
echo -e "  ${CYAN}npm uninstall -g nova-agent${NC}"
echo ""
echo -e "${GREEN}Done. Thanks for using Nova Agent!${NC}"
echo ""
