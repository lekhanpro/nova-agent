import 'native_bridge.dart';
import '../constants.dart';

typedef StepCallback  = void Function(int step, String log);
typedef ErrorCallback = void Function(String error);

/// Orchestrates the 8-step AutoGPT environment setup.
class BootstrapService {
  Future<void> run({
    required StepCallback onStep,
    required ErrorCallback onError,
  }) async {
    final steps = AppConstants.setupSteps;

    try {
      // Step 1: Update Termux
      onStep(1, 'Updating Termux packages...');
      await _run('pkg update -y 2>&1 | tail -3 || true');

      // Step 2: Install packages
      onStep(2, 'Installing proot-distro, nodejs, git...');
      await _run('pkg install -y proot-distro curl wget nodejs-lts git 2>&1 | tail -5');

      // Step 3: Install Ubuntu
      onStep(3, 'Installing Ubuntu container (~500 MB)...');
      final ubuntuInstalled = await _run(
        'proot-distro list | grep -q "ubuntu.*installed" && echo "yes" || echo "no"',
      );
      if (!ubuntuInstalled.contains('yes')) {
        await _run('proot-distro install ubuntu 2>&1 | tail -10');
      }

      // Step 4: Python inside Ubuntu
      onStep(4, 'Installing Python 3.11 inside Ubuntu...');
      await _prootRun(r'''
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq software-properties-common
        add-apt-repository -y ppa:deadsnakes/ppa
        apt-get update -qq
        apt-get install -y -qq python3.11 python3.11-venv python3.11-dev \
          python3-pip git build-essential libssl-dev libffi-dev curl nano
      ''');

      // Step 5: Clone AutoGPT
      onStep(5, 'Cloning AutoGPT repository...');
      await _prootRun(r'''
        if [ -d /root/autogpt/.git ]; then
          cd /root/autogpt && git pull origin master 2>&1 | tail -3 || true
        else
          git clone https://github.com/Significant-Gravitas/AutoGPT /root/autogpt 2>&1 | tail -5
        fi
      ''');

      // Step 6: Virtual environment
      onStep(6, 'Setting up Python virtual environment...');
      await _prootRun(r'''
        CLASSIC_DIR=/root/autogpt/classic/original_autogpt
        [ -d "$CLASSIC_DIR" ] || CLASSIC_DIR=/root/autogpt
        cd "$CLASSIC_DIR"
        [ -d venv ] || python3.11 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip wheel setuptools -q
        [ -f requirements.txt ] && pip install -r requirements.txt -q || \
          pip install autogpt openai anthropic google-generativeai click rich pydantic -q
      ''');

      // Step 7: Configure .env
      onStep(7, 'Configuring environment file...');
      await _prootRun(r'''
        CLASSIC_DIR=/root/autogpt/classic/original_autogpt
        [ -d "$CLASSIC_DIR" ] || CLASSIC_DIR=/root/autogpt
        cd "$CLASSIC_DIR"
        if [ ! -f .env ]; then
          [ -f .env.template ] && cp .env.template .env || cat > .env << 'EOF'
OPENAI_API_KEY=
HEADLESS_BROWSER=True
PLAIN_OUTPUT=True
MEMORY_BACKEND=local
ALLOW_DOWNLOADS=False
SPEAK_MODE=False
EOF
        fi
        grep -q HEADLESS_BROWSER .env || echo HEADLESS_BROWSER=True >> .env
        grep -q PLAIN_OUTPUT .env    || echo PLAIN_OUTPUT=True >> .env
        sed -i 's/^HEADLESS_BROWSER=.*/HEADLESS_BROWSER=True/' .env
        sed -i 's/^PLAIN_OUTPUT=.*/PLAIN_OUTPUT=True/' .env
      ''');

      // Step 8: Web log viewer
      onStep(8, 'Installing web log viewer...');
      await _prootRun(r'''
        mkdir -p /root/autogpt-web
        cat > /root/autogpt-web/server.py << 'PYEOF'
import http.server, os, html
LOG_FILE = '/tmp/autogpt.log'
PORT = 8000
HTML = """<!DOCTYPE html><html><head><meta charset="UTF-8">
<title>Nova Agent Logs</title>
<style>body{background:#0d0d0d;color:#e0e0e0;font-family:monospace;padding:16px}
#log{white-space:pre-wrap;font-size:13px;line-height:1.6}
.err{color:#ef4444}.info{color:#22c55e}</style>
<script>async function r(){const t=await(await fetch("/logs")).text();
document.getElementById("log").innerHTML=t.split("\\n").map(l=>
l.includes("ERROR")?"<span class=err>"+l+"</span>":
l.includes("INFO")?"<span class=info>"+l+"</span>":l).join("\\n");
window.scrollTo(0,99999)}setInterval(r,2000);window.onload=r</script>
</head><body><h1>⚡ Nova Agent Live Logs</h1><div id="log">Loading...</div></body></html>"""
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,*a):pass
    def do_GET(self):
        if self.path=="/logs":
            try:d=open(LOG_FILE).read()
            except:d="No logs yet."
            b=d.encode()
            self.send_response(200);self.send_header("Content-Type","text/plain");self.send_header("Content-Length",len(b));self.end_headers();self.wfile.write(b)
        else:
            b=HTML.encode()
            self.send_response(200);self.send_header("Content-Type","text/html");self.send_header("Content-Length",len(b));self.end_headers();self.wfile.write(b)
http.server.HTTPServer(("0.0.0.0",PORT),H).serve_forever()
PYEOF
        chmod +x /root/autogpt-web/server.py
      ''');

    } catch (e) {
      onError(e.toString());
    }
  }

  Future<String> _run(String cmd) => NativeBridge.runCommand(cmd);

  Future<String> _prootRun(String script) {
    final escaped = script.replaceAll('"', r'\"');
    return NativeBridge.runCommand(
      'proot-distro login ubuntu -- bash -c "$script"'.replaceFirst(r'$script', escaped),
    );
  }
}
