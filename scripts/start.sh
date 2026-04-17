#!/bin/bash
#
# novax start — launch Nova Agent interactive mode
#

MAGENTA='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

AGENT="$PREFIX/lib/nova_agent.py"

if [ ! -f "$AGENT" ]; then
    echo -e "${RED}✗ Nova Agent not installed. Run: novax setup${NC}"
    exit 1
fi

# Check for API key
CONFIG="$HOME/.nova_agent/config.json"
if [ -f "$CONFIG" ]; then
    KEY=$(python3 -c "import json; c=json.load(open('$CONFIG')); print(c.get('api_key',''))" 2>/dev/null)
    if [ -z "$KEY" ]; then
        echo -e "${YELLOW}⚠ No API key configured. Run: novax configure${NC}\n"
    fi
fi

echo -e "${MAGENTA}${BOLD}⚡ Starting Nova Agent...${NC}"
exec python3 "$AGENT" "$@"
