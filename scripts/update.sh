#!/bin/bash
#
# Nova Agent update script
# Pulls latest AutoGPT source and reinstalls Python deps
#

set -uo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}↑ Updating AutoGPT...${NC}"
echo ""

STEP=0
step() { STEP=$((STEP+1)); echo -e "\n${CYAN}${BOLD}[${STEP}/3]${NC} ${BOLD}$1${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "\n${RED}${BOLD}✗ $1${NC}"; exit 1; }

# ─── STEP 1: Stop agent if running ──────────────────────────────────────────
step "Stopping agent (if running)"
proot-distro login ubuntu -- bash -c "
    pkill -f 'autogpt' 2>/dev/null || true
    pkill -f 'server.py' 2>/dev/null || true
    sleep 1
" 2>/dev/null || true
ok "Agent stopped"

# ─── STEP 2: Pull latest AutoGPT source ─────────────────────────────────────
step "Pulling latest AutoGPT source"
proot-distro login ubuntu -- bash -c "
    set -e
    AUTOGPT_DIR='/root/autogpt'
    if [ ! -d \"\$AUTOGPT_DIR/.git\" ]; then
        echo 'AutoGPT not cloned yet. Run: novax setup'
        exit 1
    fi
    cd \"\$AUTOGPT_DIR\"
    git fetch origin 2>&1 | tail -3
    git pull origin master 2>&1 | tail -5 || git pull origin main 2>&1 | tail -5
    echo 'Source updated'
" || fail "Failed to pull AutoGPT source — check your network"
ok "Source up to date"

# ─── STEP 3: Reinstall Python deps ──────────────────────────────────────────
step "Reinstalling Python dependencies"
proot-distro login ubuntu -- bash -c "
    set -e
    CLASSIC_DIR='/root/autogpt/classic/original_autogpt'
    [ -d \"\$CLASSIC_DIR\" ] || CLASSIC_DIR='/root/autogpt/autogpt'
    [ -d \"\$CLASSIC_DIR\" ] || CLASSIC_DIR='/root/autogpt'

    cd \"\$CLASSIC_DIR\"
    [ -f 'venv/bin/activate' ] && source venv/bin/activate

    pip install --upgrade pip -q
    [ -f 'requirements.txt' ] && pip install -r requirements.txt -q 2>&1 | tail -5 \
        || pip install autogpt openai anthropic google-generativeai -q
    echo 'Dependencies updated'
" || fail "Failed to update Python deps"
ok "Dependencies updated"

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✓ Nova Agent update complete!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Start the agent: ${CYAN}novax start${NC}"
echo ""
