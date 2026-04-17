#!/bin/bash
# novax status — show Nova Agent config and Termux:API health

MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

CONFIG="$HOME/.nova_agent/config.json"
AGENT="$PREFIX/lib/nova_agent.py"

echo -e "${MAGENTA}${BOLD}Nova Agent — Status${NC}"
echo -e "───────────────────────────────────────────"

# ── Installation ──────────────────────────────────────────────────────────────
if [ -f "$AGENT" ]; then
    echo -e "  Agent:       ${GREEN}✓ Installed${NC} ($AGENT)"
else
    echo -e "  Agent:       ${RED}✗ Not installed${NC} — run: novax setup"
fi

# ── Config ────────────────────────────────────────────────────────────────────
if [ -f "$CONFIG" ]; then
    PROVIDER=$(python3 -c "import json; c=json.load(open('$CONFIG')); print(c.get('provider','?'))" 2>/dev/null || echo "?")
    MODEL=$(python3 -c "import json; c=json.load(open('$CONFIG')); print(c.get('model','?'))" 2>/dev/null || echo "?")
    HAS_KEY=$(python3 -c "import json; c=json.load(open('$CONFIG')); print('yes' if c.get('api_key') else 'no')" 2>/dev/null || echo "no")
    TTS=$(python3 -c "import json; c=json.load(open('$CONFIG')); print(c.get('tts',False))" 2>/dev/null || echo "False")

    echo -e "  Provider:    ${CYAN}${PROVIDER}${NC}"
    echo -e "  Model:       ${CYAN}${MODEL}${NC}"
    echo -e "  API Key:     $([ "$HAS_KEY" = "yes" ] && echo "${GREEN}✓ Set${NC}" || echo "${RED}✗ Not set${NC} — run: novax configure")"
    echo -e "  TTS:         ${DIM}${TTS}${NC}"
else
    echo -e "  Config:      ${YELLOW}⚠ Not configured${NC} — run: novax configure"
fi

echo -e "───────────────────────────────────────────"

# ── Termux:API health check ────────────────────────────────────────────────────
echo -e "${BOLD}Termux:API Tools:${NC}"

check_tool() {
    local name="$1"
    local cmd="$2"
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} ${name} (${DIM}${cmd}${NC})"
    else
        echo -e "  ${RED}✗${NC} ${name} ${DIM}— install Termux:API from F-Droid${NC}"
    fi
}

check_tool "Camera"        "termux-camera-photo"
check_tool "Location"      "termux-location"
check_tool "SMS"           "termux-sms-list"
check_tool "Battery"       "termux-battery-status"
check_tool "Contacts"      "termux-contact-list"
check_tool "Notifications" "termux-notification"
check_tool "TTS"           "termux-tts-speak"
check_tool "Clipboard"     "termux-clipboard-get"
check_tool "Torch"         "termux-torch"
check_tool "WiFi"          "termux-wifi-connectioninfo"

echo -e "───────────────────────────────────────────"

# ── Quick battery test ────────────────────────────────────────────────────────
if command -v termux-battery-status &>/dev/null; then
    BATT=$(termux-battery-status 2>/dev/null | python3 -c \
        "import sys,json; d=json.load(sys.stdin); print(f'{d[\"percentage\"]}% ({d[\"status\"]})')" 2>/dev/null || echo "unavailable")
    echo -e "  Battery: ${GREEN}${BATT}${NC}"
fi

echo ""
echo -e "  ${DIM}Quick test: novax ask \"What's my battery level?\"${NC}"
echo ""
