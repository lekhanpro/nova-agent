#!/bin/bash
# AutoGPT status check script

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}Nova Agent Status${NC}"
echo -e "─────────────────────────────────"

RUNNING=0

STATUS=$(proot-distro login ubuntu -- bash -c "
    if pgrep -f 'autogpt' > /dev/null 2>&1; then
        echo 'RUNNING'
    else
        echo 'STOPPED'
    fi
" 2>/dev/null || echo "UNKNOWN")

if echo "$STATUS" | grep -q "RUNNING"; then
    RUNNING=1
    echo -e "  Agent:      ${GREEN}● RUNNING${NC}"
else
    echo -e "  Agent:      ${RED}○ STOPPED${NC}"
fi

# Check web viewer
WEB=$(proot-distro login ubuntu -- bash -c "
    if pgrep -f 'server.py' > /dev/null 2>&1; then echo 'UP'; else echo 'DOWN'; fi
" 2>/dev/null || echo "DOWN")

if echo "$WEB" | grep -q "UP"; then
    echo -e "  Web UI:     ${GREEN}● UP${NC}  → http://localhost:8000"
else
    echo -e "  Web UI:     ${RED}○ DOWN${NC}"
fi

# Check port 8000
if nc -z localhost 8000 2>/dev/null; then
    echo -e "  Port 8000:  ${GREEN}● OPEN${NC}"
else
    echo -e "  Port 8000:  ${YELLOW}○ CLOSED${NC}"
fi

echo -e "─────────────────────────────────"

# Show last 5 log lines
LOG_PATH="/tmp/autogpt.log"
LAST_LOGS=$(proot-distro login ubuntu -- bash -c "
    if [ -f '$LOG_PATH' ]; then
        tail -5 '$LOG_PATH' 2>/dev/null
    else
        echo '(no logs yet)'
    fi
" 2>/dev/null || echo "(proot unavailable)")

echo -e "${YELLOW}Recent logs (last 5 lines):${NC}"
echo "$LAST_LOGS" | while IFS= read -r line; do
    echo -e "  ${BLUE}│${NC} $line"
done
echo ""

exit $([ $RUNNING -eq 1 ] && echo 0 || echo 1)
