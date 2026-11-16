import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createServer } from 'node:http';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const project = resolve(process.argv[2] || process.cwd());
const projectRequire = createRequire(resolve(project, 'package.json'));
const sdk = createRequire(projectRequire.resolve('nuxt-mcp-dev'));
const { Server } = sdk('@modelcontextprotocol/sdk/server/index.js');
const { SSEServerTransport } = sdk('@modelcontextprotocol/sdk/server/sse.js');
const { Client } = sdk('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = sdk('@modelcontextprotocol/sdk/client/stdio.js');
const { ToolListChangedNotificationSchema } = sdk('@modelcontextprotocol/sdk/types.js');
const bridge = fileURLToPath(new URL('../adapters/_lib/mcp-sse.mjs', import.meta.url));
const rejected = spawnSync(process.execPath, [bridge, project, 'https://example.test/sse'], { encoding: 'utf8', timeout: 5000 });
assert.equal(rejected.status, 1);
assert.equal(rejected.stdout, '');
assert.match(rejected.stderr, /loopback/);

let upstream;
let transport;
const http = createServer(async (request, response) => {
  if (request.url === '/sse') {
    upstream = new Server({ name: 'fixture-nuxt', version: '1.0.0' }, { capabilities: { tools: {}, resources: {}, prompts: {} } });
    upstream.fallbackRequestHandler = async request => {
      if (request.method === 'tools/list') return { tools: [{ name: 'nuxt-echo', inputSchema: { type: 'object' } }] };
      if (request.method === 'tools/call') return { content: [{ type: 'text', text: request.params.arguments.value }] };
      if (request.method === 'resources/list') return { resources: [] };
      if (request.method === 'prompts/list') return { prompts: [] };
      throw new Error('Unexpected fixture method');
    };
    transport = new SSEServerTransport('/message', response);
    await upstream.connect(transport);
  } else if (request.url?.startsWith('/message?')) {
    await transport.handlePostMessage(request, response);
  } else {
    response.writeHead(404).end();
  }
});
await new Promise(resolve => http.listen(0, '127.0.0.1', resolve));
const client = new Client({ name: 'bridge-test', version: '1.0.0' });
let notified;
const notification = new Promise(resolve => { notified = resolve; });
client.setNotificationHandler(ToolListChangedNotificationSchema, notified);
const stdio = new StdioClientTransport({ command: process.execPath, args: [bridge, project, `http://127.0.0.1:${http.address().port}/sse`], stderr: 'pipe' });
let stderr = '';
stdio.stderr.on('data', data => { stderr += data; });
try {
  await client.connect(stdio, { timeout: 5000 });
  assert.deepEqual(client.getServerCapabilities(), { tools: {}, resources: {}, prompts: {} });
  assert.equal((await client.listTools()).tools[0].name, 'nuxt-echo');
  assert.equal((await client.callTool({ name: 'nuxt-echo', arguments: { value: 'proxy works' } })).content[0].text, 'proxy works');
  assert.deepEqual(await client.listResources(), { resources: [] });
  assert.deepEqual(await client.listPrompts(), { prompts: [] });
  await upstream.notification({ method: 'notifications/tools/list_changed' });
  await Promise.race([notification, new Promise((_, reject) => setTimeout(() => reject(new Error('notification not forwarded')), 2000))]);
  assert.equal(stderr, '');
} finally {
  await client.close();
  await upstream?.close();
  http.closeAllConnections();
  await new Promise(resolve => http.close(resolve));
}
console.log('mcp-sse: local SSE tools, resources, prompts, notifications, and remote rejection passed');
