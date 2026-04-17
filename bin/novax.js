#!/usr/bin/env node
/**
 * novax — Nova Agent CLI
 * Entry point: dispatches commands to shell scripts inside scripts/
 */

import { run } from '../lib/index.js';

run(process.argv.slice(2));
