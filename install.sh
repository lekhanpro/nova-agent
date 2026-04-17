#!/bin/bash
#
# AutoGPT-Termux Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/lekhanpro/autogpt-termux/main/install.sh | bash
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
echo "║         AutoGPT-Termux Installer               ║"
echo "║   Run AutoGPT AI Agent on Android — No Root    ║"
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

# ─── Step 2: Install autogpt-termux from npm ──────────────────────────────────
echo -e "\n${BLUE}[2/2]${NC} Installing autogpt-termux CLI..."
npm install -g autogpt-termux

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Installation complete! 🎉${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Run setup:     ${CYAN}autogptx setup${NC}"
echo -e "  2. Configure key: ${CYAN}autogptx configure${NC}"
echo -e "  3. Start agent:   ${CYAN}autogptx start${NC}"
echo -e "  4. View logs:     ${CYAN}autogptx logs${NC}"
echo ""
echo -e "${YELLOW}Web dashboard:${NC} ${BLUE}http://localhost:8000${NC}"
echo ""
echo -e "${YELLOW}Tip:${NC} Disable battery optimization for Termux in Android Settings"
echo -e "     Settings → Apps → Termux → Battery → Unrestricted"
echo ""
