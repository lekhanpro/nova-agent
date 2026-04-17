#!/bin/bash
#
# Nova Agent configure script
# Interactive wizard for API key setup inside the proot Ubuntu .env
#

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║         Nova Agent  ·  Configuration          ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Find .env inside proot Ubuntu ───────────────────────────────────────────
ENV_PATHS=(
    '/root/autogpt/classic/original_autogpt/.env'
    '/root/autogpt/autogpt/.env'
    '/root/autogpt/.env'
)

ENV_FILE=""
for p in "${ENV_PATHS[@]}"; do
    FOUND=$(proot-distro login ubuntu -- bash -c "[ -f '$p' ] && echo yes || echo no" 2>/dev/null || echo no)
    if echo "$FOUND" | grep -q "yes"; then
        ENV_FILE="$p"
        break
    fi
done

if [ -z "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠ .env file not found inside Ubuntu container.${NC}"
    echo -e "  Have you run ${CYAN}novax setup${NC} yet?"
    echo -e "  Using default path: /root/autogpt/.env"
    ENV_FILE='/root/autogpt/.env'
fi

echo -e "${BLUE}→${NC} Editing: ${CYAN}${ENV_FILE}${NC} (inside Ubuntu container)"
echo ""

# ─── Interactive prompts ──────────────────────────────────────────────────────
echo -e "${YELLOW}Press ENTER to keep existing value. Enter 'skip' to leave blank.${NC}"
echo ""

prompt_key() {
    local label="$1"
    local key_name="$2"
    local current
    current=$(proot-distro login ubuntu -- bash -c \
        "grep -E '^${key_name}=' '${ENV_FILE}' 2>/dev/null | cut -d= -f2- | head -1" \
        2>/dev/null || echo "")

    local masked=""
    if [ -n "$current" ] && [ "$current" != "your_openai_api_key_here" ]; then
        masked="${current:0:8}...${current: -4}"
        echo -e "  ${label}: ${BLUE}[current: ${masked}]${NC}"
    else
        echo -e "  ${label}: ${YELLOW}[not set]${NC}"
    fi

    read -r -p "  Enter new value (or ENTER to keep): " new_val
    if [ -z "$new_val" ] || [ "$new_val" = "skip" ]; then
        echo -e "  ${BLUE}↷${NC} Keeping existing value"
        return
    fi

    # Set the value inside Ubuntu
    proot-distro login ubuntu -- bash -c "
        if grep -q '^${key_name}=' '${ENV_FILE}' 2>/dev/null; then
            sed -i 's|^${key_name}=.*|${key_name}=${new_val}|' '${ENV_FILE}'
        else
            echo '${key_name}=${new_val}' >> '${ENV_FILE}'
        fi
    " 2>/dev/null && echo -e "  ${GREEN}✓${NC} ${key_name} updated" || \
      echo -e "  ${RED}✗${NC} Failed to update ${key_name}"
}

echo -e "${BOLD}── API Keys ────────────────────────────────────────────${NC}"
prompt_key "OpenAI API Key   " "OPENAI_API_KEY"
echo ""
prompt_key "Anthropic API Key" "ANTHROPIC_API_KEY"
echo ""
prompt_key "Google API Key   " "GOOGLE_API_KEY"
echo ""

# ─── Model choice ─────────────────────────────────────────────────────────────
echo -e "${BOLD}── LLM Model ───────────────────────────────────────────${NC}"
echo -e "  Choose default model:"
echo -e "  ${CYAN}1${NC}) gpt-4o-mini     (OpenAI — fast, cheap)"
echo -e "  ${CYAN}2${NC}) gpt-4o          (OpenAI — best quality)"
echo -e "  ${CYAN}3${NC}) claude-3-haiku  (Anthropic — fast)"
echo -e "  ${CYAN}4${NC}) claude-3-5-sonnet (Anthropic — best)"
echo -e "  ${CYAN}5${NC}) gemini-1.5-flash (Google — fast, free tier)"
echo -e "  ${CYAN}6${NC}) Keep current"
read -r -p "  Choice [1-6]: " model_choice

MODEL=""
case "$model_choice" in
    1) MODEL="gpt-4o-mini" ;;
    2) MODEL="gpt-4o" ;;
    3) MODEL="claude-3-haiku-20240307" ;;
    4) MODEL="claude-3-5-sonnet-20241022" ;;
    5) MODEL="gemini-1.5-flash" ;;
    *) echo -e "  ${BLUE}↷${NC} Keeping current model" ;;
esac

if [ -n "$MODEL" ]; then
    proot-distro login ubuntu -- bash -c "
        if grep -q '^SMART_LLM_MODEL=' '${ENV_FILE}' 2>/dev/null; then
            sed -i 's|^SMART_LLM_MODEL=.*|SMART_LLM_MODEL=${MODEL}|' '${ENV_FILE}'
        else
            echo 'SMART_LLM_MODEL=${MODEL}' >> '${ENV_FILE}'
        fi
        if grep -q '^FAST_LLM_MODEL=' '${ENV_FILE}' 2>/dev/null; then
            sed -i 's|^FAST_LLM_MODEL=.*|FAST_LLM_MODEL=${MODEL}|' '${ENV_FILE}'
        else
            echo 'FAST_LLM_MODEL=${MODEL}' >> '${ENV_FILE}'
        fi
    " 2>/dev/null && echo -e "  ${GREEN}✓${NC} Model set to: ${MODEL}"
fi

echo ""

# ─── Memory backend ───────────────────────────────────────────────────────────
echo -e "${BOLD}── Memory Backend ──────────────────────────────────────${NC}"
echo -e "  ${CYAN}1${NC}) local   (default — no extra setup)"
echo -e "  ${CYAN}2${NC}) redis   (faster, requires Redis)"
echo -e "  ${CYAN}3${NC}) Keep current"
read -r -p "  Choice [1-3]: " mem_choice

case "$mem_choice" in
    1) MEM="local" ;;
    2) MEM="redis" ;;
    *) MEM="" ;;
esac

if [ -n "$MEM" ]; then
    proot-distro login ubuntu -- bash -c "
        if grep -q '^MEMORY_BACKEND=' '${ENV_FILE}' 2>/dev/null; then
            sed -i 's|^MEMORY_BACKEND=.*|MEMORY_BACKEND=${MEM}|' '${ENV_FILE}'
        else
            echo 'MEMORY_BACKEND=${MEM}' >> '${ENV_FILE}'
        fi
    " 2>/dev/null && echo -e "  ${GREEN}✓${NC} Memory backend: ${MEM}"
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✓ Configuration saved!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Start the agent: ${CYAN}novax start${NC}"
echo ""
