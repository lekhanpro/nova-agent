#!/bin/bash
#
# Nova Agent — Complete Setup
# Installs Python, Termux:API, and all dependencies directly in Termux.
# No root required. No proot. No 2GB Ubuntu download.
# Simple Mode: ~5 minutes | Full AutoGPT Mode: ~15 minutes (optional)
#

set -uo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

STEP=0
TOTAL=6

# ─── Helpers ─────────────────────────────────────────────────────────────────
step() { STEP=$((STEP+1)); echo -e "\n${CYAN}${BOLD}[${STEP}/${TOTAL}]${NC} ${BOLD}$1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "\n${RED}${BOLD}✗ ERROR:${NC} $1\n${RED}Fix the error above and re-run: novax setup${NC}"; exit 1; }

# ─── Banner ──────────────────────────────────────────────────────────────────
echo -e "${MAGENTA}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║               Nova Agent — Setup Wizard                   ║"
echo "║    Your AI assistant with native Android superpowers      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${DIM}Mode: Simple (Termux-native, no proot, ~5 min, ~200 MB)${NC}"
echo -e "  ${DIM}For full AutoGPT mode run: novax setup --full${NC}"
echo ""

# ─── Detect Termux ───────────────────────────────────────────────────────────
if [ -z "${TERMUX_VERSION:-}" ] && [ ! -d "/data/data/com.termux" ]; then
    warn "Not detected in Termux. Some Android tools may not work."
fi

# ─── STEP 1: Update Termux ───────────────────────────────────────────────────
step "Updating Termux packages"
pkg update -y 2>&1 | tail -3 || warn "pkg update had warnings — continuing"
ok "Termux packages updated"

# ─── STEP 2: Install system packages ─────────────────────────────────────────
step "Installing Python, git, and Termux:API"
pkg install -y python git curl termux-api 2>&1 | tail -5 || fail "Failed to install packages"
ok "Python $(python3 --version 2>/dev/null | cut -d' ' -f2)"
ok "git $(git --version | cut -d' ' -f3)"
ok "termux-api installed"
echo -e "  ${YELLOW}⬡${NC} Also install ${BOLD}Termux:API companion app${NC} from F-Droid:"
echo -e "    ${BLUE}https://f-droid.org/en/packages/com.termux.api/${NC}"

# ─── STEP 3: Install Python dependencies ─────────────────────────────────────
step "Installing AI provider libraries"
pip install --upgrade pip -q
pip install openai anthropic google-generativeai rich -q 2>&1 | tail -5 \
    || fail "Failed to install Python packages"
ok "openai"
ok "anthropic"
ok "google-generativeai"
ok "rich"

# ─── STEP 4: Setup nova-agent config directory ───────────────────────────────
step "Creating Nova Agent config directory"
CONFIG_DIR="$HOME/.nova_agent"
mkdir -p "$CONFIG_DIR"

# Create default config if not present
if [ ! -f "$CONFIG_DIR/config.json" ]; then
    cat > "$CONFIG_DIR/config.json" << 'EOF'
{
  "provider": "openai",
  "model": "gpt-4o-mini",
  "api_key": "",
  "tts": false,
  "stream": true
}
EOF
    ok "Config created at ~/.nova_agent/config.json"
else
    ok "Config already exists — preserving your settings"
fi

# ─── STEP 5: Install nova_agent.py ───────────────────────────────────────────
step "Installing nova_agent.py"

AGENT_DEST="$PREFIX/lib/nova_agent.py"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try local copy first (when running from git repo)
if [ -f "$SCRIPT_DIR/../nova_agent.py" ]; then
    cp "$SCRIPT_DIR/../nova_agent.py" "$AGENT_DEST"
    ok "Copied from local repo"
elif [ -f "$SCRIPT_DIR/../../nova_agent.py" ]; then
    cp "$SCRIPT_DIR/../../nova_agent.py" "$AGENT_DEST"
    ok "Copied from local repo"
else
    # Download from GitHub
    curl -fsSL "https://raw.githubusercontent.com/lekhanpro/nova-agent/main/nova_agent.py" \
        -o "$AGENT_DEST" || fail "Failed to download nova_agent.py"
    ok "Downloaded from GitHub"
fi

chmod +x "$AGENT_DEST"

# ─── STEP 6: Grant Termux:API permissions ────────────────────────────────────
step "Checking Termux:API permissions"
echo -e "  ${YELLOW}Grant the following permissions to Termux:API app on first use:${NC}"
echo -e "  ${DIM}• Camera         — for take_photo tool${NC}"
echo -e "  ${DIM}• Location (GPS) — for get_location tool${NC}"
echo -e "  ${DIM}• Read SMS       — for list_sms tool${NC}"
echo -e "  ${DIM}• Read Contacts  — for get_contacts tool${NC}"
echo -e "  ${DIM}• Notifications  — for send_notification tool${NC}"

# Quick test of termux-battery-status (doesn't need permissions)
BATT=$(termux-battery-status 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{d[\"percentage\"]}%')" 2>/dev/null || echo "?")
if [ "$BATT" != "?" ]; then
    ok "Termux:API working — Battery: $BATT"
else
    warn "Termux:API companion app may not be installed yet"
    echo -e "    Install from: ${BLUE}https://f-droid.org/en/packages/com.termux.api/${NC}"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✓ Nova Agent setup complete! All ${TOTAL}/${TOTAL} steps done.${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Add your API key:  ${CYAN}novax configure${NC}"
echo -e "  2. Start the agent:   ${CYAN}novax start${NC}"
echo -e "  3. Try a command:     ${CYAN}novax ask 'What's my battery level?'${NC}"
echo ""
echo -e "${YELLOW}Example queries:${NC}"
echo -e "  ${DIM}novax ask 'Take a selfie and describe it'${NC}"
echo -e "  ${DIM}novax ask 'Where am I right now?'${NC}"
echo -e "  ${DIM}novax ask 'Read my last 5 SMS messages'${NC}"
echo -e "  ${DIM}novax ask 'Send me a notification in 1 minute'${NC}"
echo ""
echo -e "${YELLOW}Termux:API companion app (required for Android tools):${NC}"
echo -e "  ${BLUE}https://f-droid.org/en/packages/com.termux.api/${NC}"
echo ""
