#!/bin/bash
# novax update — update nova_agent.py to the latest version

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

AGENT="$PREFIX/lib/nova_agent.py"
BACKUP="${AGENT}.bak"

echo -e "${CYAN}${BOLD}↑ Updating Nova Agent...${NC}"
echo ""

# Backup existing
if [ -f "$AGENT" ]; then
    cp "$AGENT" "$BACKUP"
    echo -e "  Backup saved to: ${YELLOW}${BACKUP}${NC}"
fi

# Download latest
echo -e "  Downloading latest nova_agent.py..."
if curl -fsSL "https://raw.githubusercontent.com/lekhanpro/nova-agent/main/nova_agent.py" \
    -o "$AGENT" 2>/dev/null; then
    chmod +x "$AGENT"
    echo -e "  ${GREEN}✓ nova_agent.py updated${NC}"
else
    # Restore backup on failure
    [ -f "$BACKUP" ] && cp "$BACKUP" "$AGENT"
    echo -e "  ${RED}✗ Download failed — backup restored${NC}"
    exit 1
fi

# Also update npm package if installed
if command -v npm &>/dev/null && npm list -g nova-agent &>/dev/null 2>&1; then
    echo "  Updating npm package..."
    npm install -g nova-agent@latest -q && \
        echo -e "  ${GREEN}✓ npm package updated${NC}" || true
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Nova Agent updated!${NC}"
echo -e "  Try: ${CYAN}novax ask 'What's my battery level?'${NC}"
echo ""
