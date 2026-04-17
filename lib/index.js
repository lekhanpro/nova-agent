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
  ${clr('cyan', 'setup')}         Install proot Ubuntu + Python 3.11 + AutoGPT (~1-2 GB, 5-15 min)
  ${clr('cyan', 'configure')}     Set API keys (OpenAI / Anthropic / Gemini) interactively
  ${clr('cyan', 'start')}         Launch AutoGPT agent in proot container
  ${clr('cyan', 'stop')}          Stop the running AutoGPT agent
  ${clr('cyan', 'restart')}       Stop then start the agent
  ${clr('cyan', 'status')}        Show agent running status and recent log lines
  ${clr('cyan', 'logs')}          Tail live logs (Ctrl+C to stop)
  ${clr('cyan', 'update')}        Pull latest AutoGPT source and reinstall deps
  ${clr('cyan', 'shell')}         Open a bash shell inside the proot Ubuntu container
  ${clr('cyan', 'uninstall')}     Remove proot Ubuntu container and all Nova Agent data
  ${clr('cyan', 'version')}       Print nova-agent version
  ${clr('cyan', 'help')}          Show this help message

${clr('bold', 'QUICK START')}
  1. ${clr('yellow', 'novax setup')}        ← first-time install
  2. ${clr('yellow', 'novax configure')}    ← enter your API key
  3. ${clr('yellow', 'novax start')}        ← launch the agent
  4. ${clr('yellow', 'novax logs')}         ← watch live output

${clr('bold', 'WEB DASHBOARD')}
  ${clr('blue', 'http://localhost:8000')}  (starts with novax start)

${clr('dim', 'Tip: Disable battery optimization for Termux in Android Settings.')}
${clr('dim', '     Settings → Apps → Termux → Battery → Unrestricted')}
`;

// ─── Script map ───────────────────────────────────────────────────────────────
const SCRIPT_MAP = {
  setup:      'setup.sh',
  configure:  'configure.sh',
  start:      'start.sh',
  stop:       'stop.sh',
  status:     'status.sh',
  logs:       'logs.sh',
  update:     'update.sh',
  shell:      'shell.sh',
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
  console.log(clr('cyan', '↺ Restarting AutoGPT...\n'));
  const stopPath = join(SCRIPTS, 'stop.sh');
  execFileSync('chmod', ['+x', stopPath]).catch(() => {});
  spawnSync('bash', [stopPath], { stdio: 'inherit' });
  runScript('start.sh');
}

// ─── Uninstall confirmation ───────────────────────────────────────────────────
function uninstall() {
  console.log(clr('red', '\n⚠  WARNING: This will delete the Ubuntu container and all Nova Agent data.'));
  console.log(clr('yellow', 'Run: proot-distro remove ubuntu  to confirm.\n'));
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
    console.error(`  Run ${clr('cyan', 'novax help')} to see available commands.\n`);
    process.exit(1);
  }

  runScript(scriptFile, rest);
}
