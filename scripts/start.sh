#!/bin/bash
#
# Nova Agent start script — launches AutoGPT agent inside proot Ubuntu
#

set -uo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Check proot-distro ───────────────────────────────────────────────────────
if ! command -v proot-distro &>/dev/null; then
    echo -e "${RED}✗ proot-distro not found. Run: novax setup${NC}"
    exit 1
fi

# ─── Check Ubuntu is installed ───────────────────────────────────────────────
if ! proot-distro list 2>/dev/null | grep -q "ubuntu"; then
    echo -e "${RED}✗ Ubuntu not installed. Run: novax setup${NC}"
    exit 1
fi

echo -e "${CYAN}${BOLD}⚡ Starting Nova Agent...${NC}"
echo -e "${BLUE}→${NC} Launching proot Ubuntu container"
echo -e "${BLUE}→${NC} Logs: ${CYAN}/tmp/autogpt.log${NC}"
echo -e "${BLUE}→${NC} Web dashboard: ${CYAN}http://localhost:8000${NC}"
echo ""

# ─── Start log web viewer in background ──────────────────────────────────────
proot-distro login ubuntu -- bash -c "
    pkill -f 'server.py' 2>/dev/null || true
    nohup python3 /root/autogpt-web/server.py > /tmp/webserver.log 2>&1 &
    echo 'Log web viewer starting...'
" 2>/dev/null || true

sleep 1

# ─── Start Nova Agent ───────────────────────────────────────────────────────────
proot-distro login ubuntu -- bash -c "
    set -e

    # Find AutoGPT directory
    CLASSIC_DIR='/root/autogpt/classic/original_autogpt'
    if [ ! -d \"\$CLASSIC_DIR\" ]; then
        CLASSIC_DIR='/root/autogpt/autogpt'
    fi
    if [ ! -d \"\$CLASSIC_DIR\" ]; then
        CLASSIC_DIR='/root/autogpt'
    fi

    if [ ! -d \"\$CLASSIC_DIR\" ]; then
        echo 'ERROR: AutoGPT not found. Run: novax setup'
        exit 1
    fi

    cd \"\$CLASSIC_DIR\"

    # Activate venv
    if [ -f 'venv/bin/activate' ]; then
        source venv/bin/activate
    fi

    # Write PID file
    echo \$\$ > /tmp/autogpt.pid

    export PYTHONUNBUFFERED=1
    export TERM=xterm-256color

    echo '════════════════════════════════════════'
    echo '  Nova Agent Starting'
    echo '  Press Ctrl+C to stop'
    echo '════════════════════════════════════════'

    # Launch AutoGPT with logging
    python -m autogpt run --continuous --skip-reprompt 2>&1 | tee /tmp/autogpt.log
"

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo -e "\n${RED}✗ AutoGPT exited with code ${EXIT_CODE}${NC}"
    echo -e "${YELLOW}Check logs: novax logs${NC}"
fi
