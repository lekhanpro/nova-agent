/**
 * Nova Agent postinstall script
 * Runs after: npm install -g nova-agent
 * Makes all shell scripts executable.
 */

import { readdirSync, chmodSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname  = dirname(__filename);
const SCRIPTS    = join(__dirname, '..', 'scripts');

const c = {
  reset:  '\x1b[0m',
  green:  '\x1b[32m',
  yellow: '\x1b[33m',
  cyan:   '\x1b[36m',
  bold:   '\x1b[1m',
};

console.log(`\n${c.cyan}${c.bold}Nova Agent${c.reset} installed successfully! 🎉`);

// Make scripts executable
if (existsSync(SCRIPTS)) {
  try {
    const files = readdirSync(SCRIPTS).filter(f => f.endsWith('.sh'));
    for (const file of files) {
      chmodSync(join(SCRIPTS, file), 0o755);
    }
    console.log(`${c.green}✓${c.reset} Shell scripts are executable (${files.length} scripts)`);
  } catch (err) {
    // Non-fatal — chmod may not work on Windows
    console.log(`${c.yellow}⚠${c.reset} Could not chmod scripts (okay on Windows): ${err.message}`);
  }
}

// Also chmod bin/
const binFile = join(__dirname, '..', 'bin', 'novax.js');
if (existsSync(binFile)) {
  try {
    chmodSync(binFile, 0o755);
    console.log(`${c.green}✓${c.reset} CLI binary is executable`);
  } catch { /* ignore */ }
}

console.log(`
${c.bold}Next steps:${c.reset}
  1. Run setup:     ${c.cyan}novax setup${c.reset}
  2. Add API key:   ${c.cyan}novax configure${c.reset}
  3. Start agent:   ${c.cyan}novax start${c.reset}
  4. View help:     ${c.cyan}novax help${c.reset}
`);
