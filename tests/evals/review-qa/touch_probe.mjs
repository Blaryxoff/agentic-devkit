import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const directory = dirname(fileURLToPath(import.meta.url));
const children = new Set();
const profiles = new Map();
const closures = new WeakMap();
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));

function launch(command, args) {
  const child = spawn(command, args, { stdio: ['ignore', 'pipe', 'pipe'] });
  children.add(child);
  return child;
}

function stop(child, timeout) {
  if (!child.pid || child.exitCode !== null || child.signalCode !== null) return Promise.resolve();
  if (closures.has(child)) return closures.get(child);
  const promise = new Promise((resolve, reject) => {
    const onExit = () => { clearTimeout(deadline); resolve(); };
    const deadline = setTimeout(() => {
      child.off('exit', onExit);
      child.unref();
      child.stdout?.unref?.();
      child.stderr?.unref?.();
      reject(new Error(`owned process ${child.pid} did not exit after SIGTERM; cleanup unverified`));
    }, timeout);
    child.once('exit', onExit);
    child.kill('SIGTERM');
  });
  closures.set(child, promise);
  return promise;
}

export async function cleanup(ownedChildren = children, ownedProfiles = profiles, timeout = 4000) {
  const outcomes = await Promise.allSettled([...ownedChildren].map(child => stop(child, timeout)));
  const failures = outcomes.filter(outcome => outcome.status === 'rejected').map(outcome => outcome.reason);
  for (const [profile, child] of ownedProfiles) {
    if (child.pid && child.exitCode === null && child.signalCode === null) {
      failures.push(new Error(`preserved profile ${profile} for live process ${child.pid}; cleanup unverified`));
      continue;
    }
    try {
      rmSync(profile, { recursive: true, force: true });
      ownedProfiles.delete(profile);
    } catch (error) {
      failures.push(error);
    }
  }
  if (failures.length) throw new AggregateError(failures,
    `cleanup unverified: ${failures.map(error => error.message).join('; ')}`);
}

function outputMatch(child, stream, pattern) {
  return new Promise((resolve, reject) => {
    let buffer = '';
    const timer = setTimeout(() => finish(new Error('process startup deadline exceeded')), 5000);
    const onError = error => finish(error);
    const onExit = () => finish(new Error(`process exited during startup: ${buffer.slice(-500)}`));
    const onData = chunk => {
      buffer += chunk;
      const match = buffer.match(pattern);
      if (match) finish(null, match);
    };
    const finish = (error, match) => {
      clearTimeout(timer);
      stream.off('data', onData);
      child.off('error', onError);
      child.off('exit', onExit);
      error ? reject(error) : resolve(match);
    };
    stream.on('data', onData);
    child.once('error', onError);
    child.once('exit', onExit);
  });
}

async function eventually(read, accepts, label) {
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    const result = await read();
    if (accepts(result)) return result;
    await pause(25);
  }
  throw new Error(`${label}: observed condition did not settle`);
}

async function connect(url) {
  const socket = new WebSocket(url);
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('CDP connection deadline exceeded')), 5000);
    socket.addEventListener('open', () => { clearTimeout(timer); resolve(); }, { once: true });
    socket.addEventListener('error', () => { clearTimeout(timer); reject(new Error('CDP connection failed')); }, { once: true });
  });
  let sequence = 0;
  const pending = new Map();
  socket.addEventListener('message', event => {
    const message = JSON.parse(event.data);
    const item = pending.get(message.id);
    if (!item) return;
    pending.delete(message.id);
    clearTimeout(item.timer);
    message.error ? item.reject(new Error(JSON.stringify(message.error))) : item.resolve(message.result);
  });
  const ask = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++sequence;
    const timer = setTimeout(() => { pending.delete(id); reject(new Error(`${method} deadline exceeded`)); }, 5000);
    pending.set(id, { resolve, reject, timer });
    socket.send(JSON.stringify({ id, method, params }));
  });
  const evaluate = async expression => {
    const result = await ask('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
    return result.result.value;
  };
  return { ask, evaluate, close: () => socket.close() };
}

function chromePath() {
  for (const candidate of [process.env.CHROME, '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    'google-chrome', 'google-chrome-stable', 'chromium', 'chromium-browser'].filter(Boolean)) {
    if (existsSync(candidate)) return candidate;
    const found = spawnSync('which', [candidate], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    if (found.status === 0) return found.stdout.trim();
  }
  return null;
}

async function probe(chrome, mode) {
  const fixture = launch(process.env.PYTHON || 'python3', [join(directory, 'runtime_fixture.py'),
    '--case', 'C020', '--mode', mode, '--max-seconds', '60']);
  const match = await outputMatch(fixture, fixture.stdout, /([^\n]+)\n/);
  const { url } = JSON.parse(match[1]);
  const profile = mkdtempSync(join(tmpdir(), 'review-qa-touch-'));
  const args = ['--headless=new', '--no-first-run', '--no-default-browser-check',
    '--disable-gpu', '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank'];
  if (process.getuid?.() === 0) args.push('--no-sandbox');
  const browser = launch(chrome, args);
  profiles.set(profile, browser);
  const endpoint = await outputMatch(browser, browser.stderr, /DevTools listening on (ws:\/\/[^\s]+)/);
  const origin = `http://127.0.0.1:${new URL(endpoint[1]).port}`;
  const pages = await eventually(async () => (await fetch(origin + '/json/list')).json(),
    pages => pages.some(page => page.type === 'page'), 'browser target');
  const cdp = await connect(pages.find(page => page.type === 'page').webSocketDebuggerUrl);
  const observations = [];
  try {
    const version = await cdp.ask('Browser.getVersion');
    await cdp.ask('Page.enable');
    await cdp.ask('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 1, mobile: true });
    await cdp.ask('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 1 });
    for (const location of ['center', 'edge']) {
      await cdp.ask('Page.navigate', { url: url + '/touch' });
      await eventually(() => cdp.evaluate("document.readyState === 'complete' && !!document.getElementById('details-tab')"),
        Boolean, 'touch page');
      const point = await cdp.evaluate(`(() => { const r=document.getElementById('details-tab').getBoundingClientRect();
        return {x:r.x+${location === 'center' ? 'r.width/2' : '4'},y:r.y+r.height/2}; })()`);
      const hit = await cdp.evaluate(`document.elementFromPoint(${point.x},${point.y}).id`);
      const before = (await (await fetch(url + '/state')).json()).actions.length;
      await cdp.ask('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ ...point, radiusX: 1, radiusY: 1, force: 1 }] });
      await cdp.ask('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
      const state = await eventually(async () => (await fetch(url + '/state')).json(),
        state => state.actions.length > before, 'server action');
      const visible = await cdp.evaluate("!document.getElementById('details').hidden");
      const events = await cdp.evaluate('window.touchEvents');
      const expected = mode === 'clean' ? 'details-tab' : 'overlay';
      assert.equal(hit, expected);
      assert.equal(visible, mode === 'clean');
      assert.ok(events.some(event => event.target === expected && event.trusted && event.pointerType === 'touch'));
      assert.equal(state.actions.at(-1).target, expected);
      assert.equal(state.actions.at(-1).trusted, true);
      assert.equal(state.actions.at(-1).pointerType, 'touch');
      observations.push({ location, point, hit, visible, events, server: state.actions.at(-1) });
    }
    return { case: 'C020', mode, method: 'Chromium CDP trusted touch dispatch', version,
      profile: { width: 390, height: 844, scale: 1, mobile: true, actualDevice: false }, observations };
  } finally {
    cdp.close();
    const ownedProfiles = new Map([[profile, browser]]);
    await cleanup([browser, fixture], ownedProfiles);
    profiles.delete(profile);
    for (const closed of [origin, url]) {
      await assert.rejects(fetch(closed, { signal: AbortSignal.timeout(1000) }));
    }
  }
}

async function main() {
  let terminating = false;
  async function terminate(code) {
    if (terminating) return;
    terminating = true;
    try { await cleanup(); } catch (error) { console.error(error.stack); }
    process.exit(code);
  }
  process.once('SIGTERM', () => terminate(143));
  process.once('SIGINT', () => terminate(130));
  const watchdog = setTimeout(() => terminate(124), 40000);
  try {
    const chrome = chromePath();
    if (!chrome || typeof WebSocket === 'undefined') {
      console.log(JSON.stringify({ status: 'blocked', cause: 'Chrome or Node built-in WebSocket unavailable' }));
      process.exitCode = 2;
    } else {
      const runs = [];
      for (const mode of ['fault', 'clean']) runs.push(await probe(chrome, mode));
      console.log(JSON.stringify({ status: 'passed', time: new Date().toISOString(),
        scope: 'synthetic fixture behavior; no agent benchmark or Safari/native acceptance', runs, cleanup: 'verified' }, null, 2));
    }
  } catch (error) {
    console.error(error.stack);
    process.exitCode = 1;
  } finally {
    clearTimeout(watchdog);
    try { await cleanup(); } catch (error) {
      console.error(error.stack);
      process.exitCode = 1;
    }
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
