#!/bin/bash
# AutoGPT stop script

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⏹  Stopping AutoGPT...${NC}"

# Kill inside proot Ubuntu
proot-distro login ubuntu -- bash -c "
    killed=0

    # Kill by PID file
    if [ -f /tmp/autogpt.pid ]; then
        PID=\$(cat /tmp/autogpt.pid)
        if kill -0 \"\$PID\" 2>/dev/null; then
            kill -SIGTERM \"\$PID\" 2>/dev/null && killed=1
        fi
        rm -f /tmp/autogpt.pid
    fi

    # Kill by process name
    pkill -f 'autogpt' 2>/dev/null && killed=1 || true
    pkill -f 'python.*autogpt' 2>/dev/null || true
    pkill -f 'server.py' 2>/dev/null || true

    sleep 1

    # Force kill if still running
    pkill -9 -f 'autogpt' 2>/dev/null || true

    if [ \$killed -eq 1 ]; then
        echo 'AutoGPT stopped'
    else
        echo 'No AutoGPT process was running'
    fi
" 2>/dev/null || true

echo -e "${GREEN}✓ AutoGPT stopped${NC}"
