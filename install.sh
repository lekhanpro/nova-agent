#!/bin/bash
#
# Nova Agent — One-Liner Installer
# curl -fsSL https://raw.githubusercontent.com/lekhanpro/nova-agent/main/install.sh | bash
#
# Installs:
#   • Python + Termux:API packages (via pkg)
#   • openai, anthropic, google-generativeai (via pip)
#   • nova_agent.py (core agent script)
#   • novax CLI (via npm)
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${MAGENTA}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║               Nova Agent — Installer                      ║"
echo "║    Your AI assistant with native Android superpowers      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Termux check ─────────────────────────────────────────────────────────────
if [ -z "${TERMUX_VERSION:-}" ] && [ ! -d "/data/data/com.termux" ]; then
    echo -e "${YELLOW}⚠ Warning:${NC} Not running inside Termux."
    echo -e "  Install Termux from ${BLUE}https://f-droid.org/en/packages/com.termux/${NC}"
    echo ""
fi

# ─── Step 1: Install system packages ──────────────────────────────────────────
echo -e "\n${BLUE}[1/3]${NC} Installing Python, Node.js & Termux:API..."
pkg update -y 2>/dev/null | tail -2 || true
pkg install -y python nodejs-lts git curl termux-api 2>/dev/null | tail -5

echo -e "  ${GREEN}✓${NC} Python $(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'installed')"
echo -e "  ${GREEN}✓${NC} Node.js $(node --version 2>/dev/null || echo 'installed')"
echo -e "  ${GREEN}✓${NC} termux-api installed"

# ─── Step 2: Install AI Python libs ───────────────────────────────────────────
echo -e "\n${BLUE}[2/3]${NC} Installing AI provider libraries..."
pip install --upgrade pip -q
pip install openai anthropic google-generativeai rich -q 2>/dev/null | tail -3

echo -e "  ${GREEN}✓${NC} openai / anthropic / google-generativeai"

# ─── Step 3: Install nova-agent npm package ───────────────────────────────────
echo -e "\n${BLUE}[3/3]${NC} Installing nova-agent CLI..."
npm install -g nova-agent 2>/dev/null | tail -3

echo -e "  ${GREEN}✓${NC} novax CLI installed"

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✓ Nova Agent installed! 🎉${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Install Termux:API companion app from F-Droid:"
echo -e "     ${BLUE}https://f-droid.org/en/packages/com.termux.api/${NC}"
echo ""
echo -e "  2. Add your API key:  ${CYAN}novax configure${NC}"
echo -e "  3. Try a query:       ${CYAN}novax ask \"What's my battery?\"${NC}"
echo -e "  4. Interactive mode:  ${CYAN}novax start${NC}"
echo ""
echo -e "${YELLOW}More examples:${NC}"
echo -e "  ${DIM}novax ask \"Take a selfie and describe it\"${NC}"
echo -e "  ${DIM}novax ask \"Where am I right now?\"${NC}"
echo -e "  ${DIM}novax ask \"Read my last 3 SMS messages\"${NC}"
echo -e "  ${DIM}novax ask \"Turn on the flashlight\"${NC}"
echo ""
echo -e "${YELLOW}GitHub:${NC} ${BLUE}https://github.com/lekhanpro/nova-agent${NC}"
echo ""
