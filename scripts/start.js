/**
 * @license
 * Copyright 2025 Google
 * SPDX-License-Identifier: Apache-2.0
 */
import { spawn, execSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFileSync } from 'node:fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const pkg = JSON.parse(readFileSync(join(root, 'package.json'), 'utf-8'));

// Try build-status check, but don't crash if absent
try {
  execSync('node ./scripts/check-build-status.js', { stdio: 'inherit', cwd: root });
} catch { /* noop */ }

const argv = process.argv.slice(2);
const nodeArgs = [];

// Optional sandbox detection
let sandboxCommand;
try {
  sandboxCommand = execSync('node scripts/sandbox_command.js', { cwd: root }).toString().trim();
} catch { /* noop */ }

// Debugger support
if (process.env.DEBUG && !sandboxCommand) {
  if (process.env.SANDBOX) {
    const dbg = process.env.DEBUG_PORT || '9229';
    nodeArgs.push(`--inspect-brk=0.0.0.0:${dbg}`);
  } else {
    nodeArgs.push('--inspect-brk');
  }
}

// Detect if we're starting a server-like command
const serverish = argv.some(a => /^(serve|server|a2a-server|start)$/i.test(a));

// Host/Port (Railway uses $PORT)
const HOST = process.env.HOST || '0.0.0.0';
const PORT = process.env.PORT || process.env.GEMINI_PORT || process.env.CODER_AGENT_PORT || '8080';

// Keep A2A readers in sync
if (!process.env.CODER_AGENT_PORT) {
  process.env.CODER_AGENT_PORT = String(PORT);
}

// CLI entry (the CLI package directory)
nodeArgs.push(join(root, 'packages', 'cli'));

// Forward user args
nodeArgs.push(...argv);

// Inject host/port flags if needed
if (serverish) {
  const hasHost = argv.some(a => a === '--host' || a.startsWith('--host='));
  const hasPort = argv.some(a => a === '--port' || a.startsWith('--port='));
  if (!hasHost) nodeArgs.push('--host', HOST);
  if (!hasPort) nodeArgs.push('--port', String(PORT));
}

// ---- ADDed debug lines: right before spawn ----
console.log('[start] HOST=%s PORT=%s CODER_AGENT_PORT=%s', HOST, PORT, process.env.CODER_AGENT_PORT);
console.log('[start] launching:', ['node', ...nodeArgs].map(x => (/\s/.test(x) ? `"${x}"` : x)).join(' '));

// Env for child
const env = {
  ...process.env,
  CLI_VERSION: pkg.version,
  DEV: 'true',
};
if (process.env.DEBUG) env.GEMINI_CLI_NO_RELAUNCH = 'true';

// Launch
const child = spawn('node', nodeArgs, { stdio: 'inherit', env });
child.on('close', (code) => process.exit(code ?? 0));
