#!/bin/bash
#
# Nova Agent Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/lekhanpro/nova-agent/main/install.sh | bash
#

set -e

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Banner ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════════════╗"
echo "║         Nova Agent Installer               ║"
echo "║   Run Nova AI Agent on Android — No Root    ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Termux check ─────────────────────────────────────────────────────────────
if [ ! -d "/data/data/com.termux" ] && [ -z "$TERMUX_VERSION" ]; then
    echo -e "${YELLOW}⚠ Warning:${NC} Not detected in Termux — some features may not work correctly."
fi

# ─── Step 1: Update & install base packages ───────────────────────────────────
echo -e "\n${BLUE}[1/2]${NC} Installing required packages..."
pkg update -y 2>/dev/null || true
pkg install -y nodejs-lts git proot-distro curl wget

echo -e "  ${GREEN}✓${NC} Node.js $(node --version 2>/dev/null || echo 'installed')"
echo -e "  ${GREEN}✓${NC} npm $(npm --version 2>/dev/null || echo 'installed')"
echo -e "  ${GREEN}✓${NC} git installed"
echo -e "  ${GREEN}✓${NC} proot-distro installed"
echo -e "  ${GREEN}✓${NC} curl / wget installed"

# ─── Step 2: Install nova-agent from npm ──────────────────────────────────
echo -e "\n${BLUE}[2/2]${NC} Installing nova-agent CLI..."
npm install -g nova-agent

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Installation complete! 🎉${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Run setup:     ${CYAN}novax setup${NC}"
echo -e "  2. Configure key: ${CYAN}novax configure${NC}"
echo -e "  3. Start agent:   ${CYAN}novax start${NC}"
echo -e "  4. View logs:     ${CYAN}novax logs${NC}"
echo ""
echo -e "${YELLOW}Web dashboard:${NC} ${BLUE}http://localhost:8000${NC}"
echo ""
echo -e "${YELLOW}Tip:${NC} Disable battery optimization for Termux in Android Settings"
echo -e "     Settings → Apps → Termux → Battery → Unrestricted"
echo ""
