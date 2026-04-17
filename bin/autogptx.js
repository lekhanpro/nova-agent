#!/usr/bin/env node
/**
 * autogptx — AutoGPT-Termux CLI
 * Entry point: dispatches commands to shell scripts inside scripts/
 */

import { run } from '../lib/index.js';

run(process.argv.slice(2));
