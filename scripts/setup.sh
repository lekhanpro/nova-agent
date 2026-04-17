#!/bin/bash
#
# Nova Agent Setup Script
# Installs proot-distro Ubuntu + Python 3.11 + AutoGPT Classic
# Runs inside Termux (no root required)
#

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

STEP=0
TOTAL=8

# ─── Helpers ──────────────────────────────────────────────────────────────────
step() {
    STEP=$((STEP + 1))
    echo -e "\n${CYAN}${BOLD}[${STEP}/${TOTAL}]${NC} ${BOLD}$1${NC}"
}

ok() {
    echo -e "  ${GREEN}✓${NC} $1"
}

warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

fail() {
    echo -e "\n${RED}${BOLD}✗ ERROR:${NC} $1"
    echo -e "${RED}Setup failed at step ${STEP}/${TOTAL}. Please fix the error above and re-run.${NC}"
    exit 1
}

# ─── Banner ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║          Nova Agent Environment Setup              ║"
echo "║  Installing: proot-distro → Ubuntu → Python → AutoGPT  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "This will install approximately ${YELLOW}1-2 GB${NC} of data."
echo -e "Estimated time: ${YELLOW}5-15 minutes${NC} depending on your connection."
echo ""

# ─── Arch detection ───────────────────────────────────────────────────────────
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64)
        PROOT_ARCH="arm64"
        ok "Detected architecture: arm64 (aarch64)"
        ;;
    armv7l|armv8l)
        PROOT_ARCH="armhf"
        ok "Detected architecture: armhf (armv7)"
        ;;
    x86_64)
        PROOT_ARCH="amd64"
        ok "Detected architecture: amd64 (x86_64)"
        ;;
    *)
        fail "Unsupported architecture: $ARCH. Only arm64, armv7, x86_64 are supported."
        ;;
esac

# ─── STEP 1: Update Termux packages ──────────────────────────────────────────
step "Updating Termux packages"
pkg update -y 2>&1 | tail -3 || warn "pkg update had warnings — continuing"
ok "Termux packages updated"

# ─── STEP 2: Install required Termux packages ─────────────────────────────────
step "Installing proot-distro, curl, wget, nodejs"
pkg install -y proot-distro curl wget nodejs-lts git 2>&1 | tail -5 || fail "Failed to install Termux packages"
ok "proot-distro $(proot-distro --version 2>/dev/null | head -1 || echo 'installed')"
ok "nodejs $(node --version 2>/dev/null || echo 'installed')"
ok "git $(git --version | cut -d' ' -f3)"

# ─── STEP 3: Install Ubuntu via proot-distro ──────────────────────────────────
step "Installing Ubuntu Linux container"
if proot-distro list 2>/dev/null | grep -q "ubuntu.*installed"; then
    warn "Ubuntu already installed — skipping re-install"
else
    echo -e "  ${BLUE}→${NC} Downloading Ubuntu rootfs for ${PROOT_ARCH}..."
    proot-distro install ubuntu 2>&1 | grep -E "(Download|Extract|Install|✓|error)" || true
    ok "Ubuntu installed successfully"
fi

# ─── STEP 4: Inside Ubuntu — install Python 3.11 + build tools ───────────────
step "Installing Python 3.11 inside Ubuntu"
proot-distro login ubuntu -- bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq 2>&1 | tail -2
    apt-get install -y -qq software-properties-common 2>&1 | tail -2
    add-apt-repository -y ppa:deadsnakes/ppa 2>&1 | tail -2
    apt-get update -qq 2>&1 | tail -2
    apt-get install -y -qq python3.11 python3.11-venv python3.11-dev python3-pip \
        git build-essential libssl-dev libffi-dev curl wget nano 2>&1 | tail -5
    python3.11 --version
    echo 'Python 3.11 ready'
" || fail "Failed to install Python 3.11 inside Ubuntu"
ok "Python 3.11 installed inside Ubuntu"

# ─── STEP 5: Clone AutoGPT repository ────────────────────────────────────────
step "Cloning AutoGPT Classic repository"
proot-distro login ubuntu -- bash -c "
    set -e
    AUTOGPT_DIR='/root/autogpt'
    if [ -d \"\$AUTOGPT_DIR/.git\" ]; then
        echo 'AutoGPT already cloned — updating...'
        cd \"\$AUTOGPT_DIR\"
        git pull origin master 2>&1 | tail -3 || git pull origin main 2>&1 | tail -3 || true
    else
        echo 'Cloning AutoGPT...'
        git clone https://github.com/Significant-Gravitas/AutoGPT \"\$AUTOGPT_DIR\" 2>&1 | tail -5
    fi
    echo 'AutoGPT repo ready'
" || fail "Failed to clone AutoGPT repository"
ok "AutoGPT repository ready"

# ─── STEP 6: Install Python dependencies ─────────────────────────────────────
step "Setting up Python virtual environment & installing dependencies"
proot-distro login ubuntu -- bash -c "
    set -e
    CLASSIC_DIR='/root/autogpt/classic/original_autogpt'

    # Ensure the classic dir exists (repo structure may vary)
    if [ ! -d \"\$CLASSIC_DIR\" ]; then
        # Try alternate locations
        if [ -d '/root/autogpt/autogpt' ]; then
            CLASSIC_DIR='/root/autogpt/autogpt'
        elif [ -d '/root/autogpt' ]; then
            CLASSIC_DIR='/root/autogpt'
        fi
    fi

    echo \"Using AutoGPT dir: \$CLASSIC_DIR\"
    cd \"\$CLASSIC_DIR\"

    # Create venv
    if [ ! -d 'venv' ]; then
        python3.11 -m venv venv
        echo 'Virtual environment created'
    else
        echo 'Virtual environment exists — skipping'
    fi

    # Install deps
    source venv/bin/activate
    pip install --upgrade pip wheel setuptools -q
    if [ -f 'requirements.txt' ]; then
        pip install -r requirements.txt -q 2>&1 | tail -5
    else
        # Install core autogpt deps if requirements.txt missing
        pip install autogpt openai anthropic google-generativeai click rich pydantic -q
    fi
    echo 'Dependencies installed'
" || fail "Failed to install Python dependencies"
ok "Python dependencies installed"

# ─── STEP 7: Configure .env ───────────────────────────────────────────────────
step "Configuring AutoGPT environment"
proot-distro login ubuntu -- bash -c "
    set -e
    CLASSIC_DIR='/root/autogpt/classic/original_autogpt'
    if [ ! -d \"\$CLASSIC_DIR\" ]; then
        CLASSIC_DIR='/root/autogpt'
    fi
    cd \"\$CLASSIC_DIR\"

    # Create .env from template if not present
    if [ ! -f '.env' ]; then
        if [ -f '.env.template' ]; then
            cp .env.template .env
            echo '.env created from template'
        else
            cat > .env << 'ENVEOF'
# Nova Agent Configuration
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=
GOOGLE_API_KEY=
HEADLESS_BROWSER=True
PLAIN_OUTPUT=True
MEMORY_BACKEND=local
ALLOW_DOWNLOADS=False
SPEAK_MODE=False
DEBUG_MODE=False
TEMPERATURE=0
EXECUTE_LOCAL_COMMANDS=False
RESTRICT_TO_WORKSPACE=True
USER_AGENT=Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36
ENVEOF
            echo '.env created with defaults'
        fi
    else
        echo '.env already exists — patching settings'
    fi

    # Patch critical Termux-compatibility settings
    sed -i 's/^HEADLESS_BROWSER=.*/HEADLESS_BROWSER=True/' .env
    sed -i 's/^PLAIN_OUTPUT=.*/PLAIN_OUTPUT=True/' .env

    # Add if missing
    grep -q 'HEADLESS_BROWSER' .env || echo 'HEADLESS_BROWSER=True' >> .env
    grep -q 'PLAIN_OUTPUT' .env    || echo 'PLAIN_OUTPUT=True'    >> .env

    echo '.env configured'
" || fail "Failed to configure .env"
ok ".env configured for Termux compatibility"

# ─── STEP 8: Install log web server ───────────────────────────────────────────
step "Setting up log web viewer (localhost:8000)"
proot-distro login ubuntu -- bash -c "
    set -e
    mkdir -p /root/autogpt-web
    cat > /root/autogpt-web/server.py << 'PYEOF'
#!/usr/bin/env python3
\"\"\"Minimal log web viewer for AutoGPT — serves live logs on localhost:8000\"\"\"
import http.server, os, html, time, threading

LOG_FILE = '/tmp/autogpt.log'
PORT = 8000

HTML_TEMPLATE = '''<!DOCTYPE html>
<html><head>
<meta charset=\"UTF-8\">
<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">
<title>Nova Agent Live Logs</title>
<style>
body{background:#0d0d0d;color:#e0e0e0;font-family:monospace;padding:16px;margin:0}
h1{color:#7c3aed;font-size:1.2em}
#log{white-space:pre-wrap;font-size:13px;line-height:1.6}
.err{color:#ef4444}.warn{color:#f59e0b}.info{color:#22c55e}.dbg{color:#6b7280}
</style>
<script>
function colorize(line){
  if(line.includes('[ERROR]')||line.includes('ERROR'))
    return '<span class=\"err\">'+line+'</span>';
  if(line.includes('[WARN]')||line.includes('WARNING'))
    return '<span class=\"warn\">'+line+'</span>';
  if(line.includes('[INFO]')||line.includes('INFO'))
    return '<span class=\"info\">'+line+'</span>';
  if(line.includes('[DEBUG]')||line.includes('DEBUG'))
    return '<span class=\"dbg\">'+line+'</span>';
  return line;
}
async function refresh(){
  const r=await fetch('/logs');
  const t=await r.text();
  const lines=t.split('\\n').map(colorize).join('\\n');
  document.getElementById('log').innerHTML=lines;
  window.scrollTo(0,document.body.scrollHeight);
}
setInterval(refresh,2000);
window.onload=refresh;
</script>
</head><body>
<h1>⚡ Nova Agent Live Logs</h1>
<div id="log">Loading...</div>
</body></html>'''

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        if self.path == '/logs':
            try:
                with open(LOG_FILE, 'r', errors='replace') as f:
                    data = f.read()
            except FileNotFoundError:
                data = 'No logs yet. Start Nova Agent with: novax start'
            body = data.encode()
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.send_header('Content-Length', len(body))
            self.end_headers()
            self.wfile.write(body)
        else:
            body = HTML_TEMPLATE.encode()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', len(body))
            self.end_headers()
            self.wfile.write(body)

if __name__ == '__main__':
    server = http.server.HTTPServer(('0.0.0.0', PORT), Handler)
    print(f'Nova Agent Log Viewer running at http://localhost:{PORT}')
    server.serve_forever()
PYEOF
    chmod +x /root/autogpt-web/server.py
    echo 'Log web viewer installed'
" || fail "Failed to set up log web viewer"
ok "Log web viewer ready at localhost:8000"

# ─── Complete ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✓ Nova Agent setup complete! All ${TOTAL}/${TOTAL} steps done.${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Add your API key:  ${CYAN}novax configure${NC}"
echo -e "  2. Start the agent:   ${CYAN}novax start${NC}"
echo -e "  3. View live logs:    ${CYAN}novax logs${NC}"
echo -e "  4. Open dashboard:    ${CYAN}novax status${NC}"
echo ""
