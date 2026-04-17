#!/bin/bash
#
# novax configure — interactive API key and settings wizard
#

MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

CONFIG_DIR="$HOME/.nova_agent"
CONFIG="$CONFIG_DIR/config.json"
mkdir -p "$CONFIG_DIR"

# Defaults
PROVIDER="openai"
MODEL="gpt-4o-mini"
API_KEY=""
TTS="false"

# Load existing config
if [ -f "$CONFIG" ]; then
    PROVIDER=$(python3 -c "import json; c=json.load(open('$CONFIG')); print(c.get('provider','openai'))" 2>/dev/null || echo "openai")
    MODEL=$(python3 -c "import json; c=json.load(open('$CONFIG')); print(c.get('model','gpt-4o-mini'))" 2>/dev/null || echo "gpt-4o-mini")
    API_KEY=$(python3 -c "import json; c=json.load(open('$CONFIG')); print(c.get('api_key',''))" 2>/dev/null || echo "")
    TTS=$(python3 -c "import json; c=json.load(open('$CONFIG')); print(str(c.get('tts',False)).lower())" 2>/dev/null || echo "false")
fi

echo -e "${MAGENTA}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           Nova Agent — Configuration Wizard               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${DIM}Press ENTER to keep your existing value.${NC}\n"

# ─── Provider ────────────────────────────────────────────────────────────────
echo -e "${BOLD}AI Provider:${NC}"
echo -e "  ${CYAN}1${NC}) OpenAI     (GPT-4o-mini, GPT-4o)               ${DIM}[current: ${PROVIDER}]${NC}"
echo -e "  ${CYAN}2${NC}) Anthropic  (Claude 3 Haiku, Claude 3.5 Sonnet)"
echo -e "  ${CYAN}3${NC}) Google     (Gemini 1.5 Flash, Gemini 1.5 Pro)"
read -r -p "  Choice [1-3, ENTER to keep]: " prov_choice

case "$prov_choice" in
    1) PROVIDER="openai"    ;;
    2) PROVIDER="anthropic" ;;
    3) PROVIDER="gemini"    ;;
    *) echo -e "  ${DIM}Keeping: ${PROVIDER}${NC}" ;;
esac

# ─── Model ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Model:${NC} ${DIM}[current: ${MODEL}]${NC}"
case "$PROVIDER" in
    openai)
        echo -e "  ${CYAN}1${NC}) gpt-4o-mini  ${DIM}(fast, cheap, recommended)${NC}"
        echo -e "  ${CYAN}2${NC}) gpt-4o       ${DIM}(best quality, more expensive)${NC}"
        read -r -p "  Choice [1-2, ENTER to keep]: " m_choice
        case "$m_choice" in
            1) MODEL="gpt-4o-mini" ;;
            2) MODEL="gpt-4o"      ;;
        esac
        ;;
    anthropic)
        echo -e "  ${CYAN}1${NC}) claude-3-haiku-20240307       ${DIM}(fast, cheap)${NC}"
        echo -e "  ${CYAN}2${NC}) claude-3-5-sonnet-20241022    ${DIM}(best quality)${NC}"
        read -r -p "  Choice [1-2, ENTER to keep]: " m_choice
        case "$m_choice" in
            1) MODEL="claude-3-haiku-20240307"     ;;
            2) MODEL="claude-3-5-sonnet-20241022"  ;;
        esac
        ;;
    gemini)
        echo -e "  ${CYAN}1${NC}) gemini-1.5-flash  ${DIM}(fast, free tier)${NC}"
        echo -e "  ${CYAN}2${NC}) gemini-1.5-pro    ${DIM}(best quality)${NC}"
        read -r -p "  Choice [1-2, ENTER to keep]: " m_choice
        case "$m_choice" in
            1) MODEL="gemini-1.5-flash" ;;
            2) MODEL="gemini-1.5-pro"   ;;
        esac
        ;;
esac

# ─── API Key ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}API Key:${NC}"
case "$PROVIDER" in
    openai)    echo -e "  Get key: ${CYAN}https://platform.openai.com/api-keys${NC}" ;;
    anthropic) echo -e "  Get key: ${CYAN}https://console.anthropic.com/${NC}" ;;
    gemini)    echo -e "  Get key: ${CYAN}https://aistudio.google.com/app/apikey${NC}" ;;
esac

MASKED=""
if [ -n "$API_KEY" ]; then
    MASKED="${API_KEY:0:8}...${API_KEY: -4}"
fi
read -r -p "  Enter API key ${DIM}[current: ${MASKED:-not set}]${NC}: " new_key
[ -n "$new_key" ] && API_KEY="$new_key"

# ─── TTS ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Text-to-Speech (speak agent responses aloud):${NC} ${DIM}[current: ${TTS}]${NC}"
read -r -p "  Enable TTS? [y/N]: " tts_choice
case "$tts_choice" in
    y|Y) TTS="true" ;;
    n|N) TTS="false" ;;
esac

# ─── Save ─────────────────────────────────────────────────────────────────────
python3 - << PYEOF
import json
config = {
    "provider": "$PROVIDER",
    "model": "$MODEL",
    "api_key": "$API_KEY",
    "tts": $TTS,
    "stream": True
}
with open("$CONFIG", "w") as f:
    json.dump(config, f, indent=2)
print("Config saved.")
PYEOF

echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✓ Configuration saved!${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Provider: ${CYAN}${PROVIDER}${NC}  |  Model: ${CYAN}${MODEL}${NC}"
echo ""
echo -e "  Start the agent: ${CYAN}novax start${NC}"
echo -e "  Quick query:     ${CYAN}novax ask 'What's my battery?'${NC}"
echo ""
