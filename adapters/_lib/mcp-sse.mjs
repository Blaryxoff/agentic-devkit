#!/usr/bin/env node
import { createRequire } from 'node:module';
import { resolve } from 'node:path';

let client;
let server;
let stopping = false;
process.stdin.once('end', () => stop(0));

function stop(code, message) {
  if (stopping) return;
  stopping = true;
  if (message) process.stderr.write(`MCP SSE bridge: ${message}\n`);
  setTimeout(() => process.exit(code), 1000).unref();
  Promise.allSettled([client?.close(), server?.close()]).then(() => process.exit(code));
}

async function main() {
  const [project, endpoint] = process.argv.slice(2);
  if (!project || !endpoint) throw new Error('usage: mcp-sse.mjs PROJECT_ROOT LOOPBACK_SSE_URL');
  let url;
  try { url = new URL(endpoint); } catch { throw new Error('endpoint must be a loopback HTTP URL'); }
  if (!['http:', 'https:'].includes(url.protocol)
    || !['localhost', '[::1]'].includes(url.hostname) && !/^127\.\d+\.\d+\.\d+$/.test(url.hostname)
    || url.username || url.password) throw new Error('endpoint must be a loopback HTTP URL without credentials');
  let sdk;
  try {
    const projectRequire = createRequire(resolve(project, 'package.json'));
    sdk = createRequire(projectRequire.resolve('nuxt-mcp-dev'));
  } catch { throw new Error('install the project\'s existing nuxt-mcp-dev dependency first'); }
  const { Client } = sdk('@modelcontextprotocol/sdk/client/index.js');
  const { SSEClientTransport } = sdk('@modelcontextprotocol/sdk/client/sse.js');
  const { Server } = sdk('@modelcontextprotocol/sdk/server/index.js');
  const { StdioServerTransport } = sdk('@modelcontextprotocol/sdk/server/stdio.js');
  const { ResultSchema } = sdk('@modelcontextprotocol/sdk/types.js');
  client = new Client({ name: 'devkit-nuxt-sse', version: '1.0.0' });
  const startup = setTimeout(() => stop(1, 'local Nuxt runtime did not connect within 10 seconds'), 10000);
  try {
    await client.connect(new SSEClientTransport(url, {
      fetch: (input, init) => fetch(input, { ...init, redirect: 'error' }),
    }), { timeout: 10000 });
  } catch { throw new Error('cannot connect to local Nuxt runtime; start its dev server first'); }
  finally { clearTimeout(startup); }
  server = new Server(client.getServerVersion() || { name: 'devkit-nuxt-sse', version: '1.0.0' }, {
    capabilities: client.getServerCapabilities(),
    instructions: client.getInstructions(),
  });
  server.fallbackRequestHandler = (request, extra) => client.request(
    { method: request.method, params: request.params }, ResultSchema, { timeout: 60000, signal: extra.signal },
  );
  server.fallbackNotificationHandler = notification => client.notification(notification);
  client.fallbackNotificationHandler = notification => server.notification(notification);
  client.onclose = () => stop(1, 'local Nuxt runtime disconnected');
  server.onclose = () => stop(0);
  client.onerror = () => stop(1, 'local Nuxt runtime transport failed');
  server.onerror = () => stop(1, 'stdio transport failed');
  process.once('SIGINT', () => stop(0));
  process.once('SIGTERM', () => stop(0));
  await server.connect(new StdioServerTransport());
}

main().catch(error => stop(1, error.message.startsWith('Cannot find module')
  ? 'the project\'s nuxt-mcp-dev MCP SDK dependency is unavailable' : error.message));
