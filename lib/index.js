/**
 * Nova Agent CLI — Core Dispatcher
 * Maps CLI commands → shell scripts bundled with the package
 */

import { execFileSync, spawnSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname  = dirname(__filename);
const SCRIPTS    = join(__dirname, '..', 'scripts');

// ─── ANSI colors (no deps needed beyond chalk for non-chalk paths) ────────────
const c = {
  reset:  '\x1b[0m',
  bold:   '\x1b[1m',
  cyan:   '\x1b[36m',
  green:  '\x1b[32m',
  yellow: '\x1b[33m',
  red:    '\x1b[31m',
  blue:   '\x1b[34m',
  dim:    '\x1b[2m',
};

const clr = (color, text) => `${c[color]}${text}${c.reset}`;

// ─── Help text ────────────────────────────────────────────────────────────────
const BANNER = `
${c.cyan}${c.bold}╔═══════════════════════════════════════════════════╗
║          Nova Agent  •  novax CLI          ║
║    Run Nova AI Agent on Android — No Root      ║
╚═══════════════════════════════════════════════════╝${c.reset}
`;

const HELP = `
${BANNER}
${clr('bold', 'USAGE')}
  novax <command> [options]

${clr('bold', 'COMMANDS')}
  ${clr('cyan', 'setup')}         Install Python deps + Termux:API integration (~5 min)
  ${clr('cyan', 'configure')}     Set AI provider, model, and API key interactively
  ${clr('cyan', 'start')}         Launch Nova Agent in interactive chat mode
  ${clr('cyan', 'ask')} "..."     One-shot query — ask anything directly
  ${clr('cyan', 'status')}        Show agent config and Termux:API status
  ${clr('cyan', 'update')}        Update nova_agent.py to the latest version
  ${clr('cyan', 'version')}       Print nova-agent version
  ${clr('cyan', 'help')}          Show this help message

${clr('bold', 'QUICK START')}
  1. ${clr('yellow', 'novax setup')}                       ← install (~5 min)
  2. ${clr('yellow', 'novax configure')}                   ← enter your API key
  3. ${clr('yellow', 'novax ask "What\'s my battery?"')}  ← first query
  4. ${clr('yellow', 'novax start')}                       ← interactive chat mode

${clr('bold', 'ANDROID TOOLS')}
  📷 Camera · 📍 GPS · 💬 SMS · 🔋 Battery · 📇 Contacts
  🔔 Notifications · 🔊 TTS · 📋 Clipboard · 📶 WiFi · 💡 Torch

${clr('bold', 'EXAMPLES')}
  ${clr('dim', 'novax ask "Take a selfie and describe it"')}
  ${clr('dim', 'novax ask "Where am I right now?"')}
  ${clr('dim', 'novax ask "Read my last 5 SMS messages"')}
  ${clr('dim', 'novax ask "Turn on the flashlight"')}

${clr('dim', 'Tip: Install Termux:API from F-Droid for Android hardware access.')}
`;

// ─── Script map ───────────────────────────────────────────────────────────────
const SCRIPT_MAP = {
  setup:      'setup.sh',
  configure:  'configure.sh',
  start:      'start.sh',
  ask:        'ask.sh',
  status:     'status.sh',
  update:     'update.sh',
  logs:       'logs.sh',
  shell:      'shell.sh',
  stop:       'stop.sh',
  uninstall:  'uninstall.sh',
};

// ─── Inline commands (no shell script needed) ─────────────────────────────────
function printVersion() {
  try {
    const pkg = JSON.parse(
      execFileSync('cat', [join(__dirname, '..', 'package.json')], { encoding: 'utf8' })
    );
    console.log(`nova-agent v${pkg.version}`);
  } catch {
    console.log('nova-agent v1.0.0');
  }
}

// ─── Shell script runner ──────────────────────────────────────────────────────
function runScript(scriptFile, extraArgs = []) {
  const scriptPath = join(SCRIPTS, scriptFile);

  if (!existsSync(scriptPath)) {
    console.error(clr('red', `✗ Script not found: ${scriptPath}`));
    console.error(clr('yellow', '  Try reinstalling: npm install -g nova-agent'));
    process.exit(1);
  }

  // Make executable (important after npm install)
  try {
    execFileSync('chmod', ['+x', scriptPath]);
  } catch { /* ignore on Windows */ }

  const result = spawnSync('bash', [scriptPath, ...extraArgs], {
    stdio: 'inherit',
    env:   { ...process.env, FORCE_COLOR: '1' },
  });

  process.exit(result.status ?? 0);
}

// ─── Restart helper ──────────────────────────────────────────────────────────
function restart() {
  console.log(clr('cyan', '↺ Restarting Nova Agent...\n'));
  const stopPath = join(SCRIPTS, 'stop.sh');
  try { execFileSync('chmod', ['+x', stopPath]); } catch { /* ignore */ }
  spawnSync('bash', [stopPath], { stdio: 'inherit' });
  runScript('start.sh');
}

// ─── Uninstall confirmation ───────────────────────────────────────────────────
function uninstall() {
  console.log(clr('red', '\n⚠  WARNING: This will remove nova_agent.py and all config from ~/.nova_agent/'));
  console.log(clr('yellow', 'Run: novax uninstall  to confirm.\n'));
  runScript('uninstall.sh');
}

// ─── Main entry ───────────────────────────────────────────────────────────────
export function run(args) {
  const [cmd, ...rest] = args;

  if (!cmd || cmd === 'help' || cmd === '--help' || cmd === '-h') {
    console.log(HELP);
    process.exit(0);
  }

  if (cmd === 'version' || cmd === '--version' || cmd === '-v') {
    printVersion();
    process.exit(0);
  }

  if (cmd === 'restart') {
    restart();
    return;
  }

  if (cmd === 'uninstall') {
    uninstall();
    return;
  }

  const scriptFile = SCRIPT_MAP[cmd];
  if (!scriptFile) {
    console.error(clr('red', `✗ Unknown command: ${cmd}`));
    console.error(`  Run ${clr('cyan', 'novax help')} to see available commands.`);
    console.error(`\n  ${clr('dim', 'Example: novax ask "What is my battery level?"')}\n`);
    process.exit(1);
  }

  runScript(scriptFile, rest);
}
