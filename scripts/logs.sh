#!/bin/bash
#
# AutoGPT-Termux logs script
# Tails the AutoGPT live log file. Ctrl+C to stop.
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

LOG_PATH='/tmp/autogpt.log'

echo -e "${CYAN}${BOLD}AutoGPT Live Logs${NC}"
echo -e "${BLUE}─────────────────────────────────────────────${NC}"
echo -e "  File: ${CYAN}${LOG_PATH}${NC} (inside Ubuntu container)"
echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop tailing"
echo -e "${BLUE}─────────────────────────────────────────────${NC}"
echo ""

# Check if log file exists
FILE_EXISTS=$(proot-distro login ubuntu -- bash -c \
    "[ -f '$LOG_PATH' ] && echo yes || echo no" 2>/dev/null || echo "no")

if echo "$FILE_EXISTS" | grep -q "no"; then
    echo -e "${YELLOW}⚠ No log file yet.${NC}"
    echo -e "  Start the agent first: ${CYAN}autogptx start${NC}"
    echo -e "  Waiting for logs to appear..."
    echo ""
fi

# Stream logs from inside proot container
# We use a loop + sleep to poll so Ctrl+C works cleanly from Termux
proot-distro login ubuntu -- bash -c "
    LOG='${LOG_PATH}'
    # Create if missing so tail -f works immediately
    touch \"\$LOG\" 2>/dev/null || true
    tail -n 50 -f \"\$LOG\"
"
