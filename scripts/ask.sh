#!/bin/bash
#
# novax ask — send a one-shot query to Nova Agent
# Usage: novax ask "What's my battery level?"

MAGENTA='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

AGENT="$PREFIX/lib/nova_agent.py"

if [ ! -f "$AGENT" ]; then
    echo -e "${RED}✗ Nova Agent not installed. Run: novax setup${NC}"
    exit 1
fi

if [ -z "$1" ]; then
    echo -e "${MAGENTA}Usage: novax ask \"your question here\"${NC}"
    echo ""
    echo -e "Examples:"
    echo -e "  novax ask \"What's my battery level?\""
    echo -e "  novax ask \"Take a selfie and describe what you see\""
    echo -e "  novax ask \"Where am I right now?\""
    echo -e "  novax ask \"Read my last 3 SMS messages\""
    echo -e "  novax ask \"Turn on the flashlight\""
    exit 1
fi

exec python3 "$AGENT" "$@"
