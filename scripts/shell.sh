#!/bin/bash
#
# AutoGPT-Termux shell script
# Opens an interactive bash shell inside proot Ubuntu
#

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}Opening proot Ubuntu shell...${NC}"
echo -e "${YELLOW}Type 'exit' to return to Termux.${NC}"
echo ""

exec proot-distro login ubuntu
