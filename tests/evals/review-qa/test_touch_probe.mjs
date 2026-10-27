import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { existsSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { cleanup } from './touch_probe.mjs';

function childProcess(pid, exits = true) {
  const child = new EventEmitter();
  Object.assign(child, { pid, exitCode: null, signalCode: null, signals: [], detached: [] });
  child.unref = () => child.detached.push('process');
  child.stdout = { unref: () => child.detached.push('stdout') };
  child.stderr = { unref: () => child.detached.push('stderr') };
  child.kill = signal => {
    child.signals.push(signal);
    if (exits) queueMicrotask(() => {
      child.signalCode = signal;
      child.emit('exit', null, signal);
    });
    return true;
  };
  return child;
}

test('shutdown timeout preserves the live browser profile and cleans all other owned resources', async () => {
  const root = mkdtempSync(join(tmpdir(), 'review-qa-cleanup-test-'));
  const liveProfile = mkdtempSync(join(root, 'live-'));
  const stoppedProfile = mkdtempSync(join(root, 'stopped-'));
  const browser = childProcess(101, false);
  const otherBrowser = childProcess(102);
  const fixture = childProcess(103);
  const children = [browser, otherBrowser, fixture];
  const profiles = new Map([[liveProfile, browser], [stoppedProfile, otherBrowser]]);
  try {
    await assert.rejects(cleanup(children, profiles, 20), error => {
      assert.ok(error instanceof AggregateError);
      assert.match(error.message, /cleanup unverified/);
      assert.ok(error.message.includes(liveProfile));
      assert.match(error.message, /process 101/);
      return true;
    });
    for (const child of children) assert.deepEqual(child.signals, ['SIGTERM']);
    assert.deepEqual(browser.detached, ['process', 'stdout', 'stderr']);
    assert.equal(browser.listenerCount('exit'), 0);
    assert.ok(existsSync(liveProfile));
    assert.ok(!existsSync(stoppedProfile));
    assert.deepEqual([...profiles.keys()], [liveProfile]);
    await assert.rejects(cleanup(children, profiles, 20), /cleanup unverified/);
    assert.deepEqual(browser.signals, ['SIGTERM']);
    browser.exitCode = 0;
    await cleanup(children, profiles, 20);
    assert.ok(!existsSync(liveProfile));
    assert.equal(profiles.size, 0);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('graceful shutdown removes profiles without signaling an already exited child', async () => {
  const profile = mkdtempSync(join(tmpdir(), 'review-qa-cleanup-test-'));
  const browser = childProcess(104);
  const exited = childProcess(105);
  exited.exitCode = 0;
  const profiles = new Map([[profile, browser]]);
  try {
    await cleanup([browser, exited], profiles, 20);
    assert.deepEqual(browser.signals, ['SIGTERM']);
    assert.deepEqual(exited.signals, []);
    assert.deepEqual(browser.detached, []);
    assert.equal(profiles.size, 0);
    assert.ok(!existsSync(profile));
  } finally {
    rmSync(profile, { recursive: true, force: true });
  }
});

test('failed browser spawn releases its unused profile', async () => {
  const profile = mkdtempSync(join(tmpdir(), 'review-qa-cleanup-test-'));
  const browser = childProcess(undefined);
  const profiles = new Map([[profile, browser]]);
  try {
    await cleanup([browser], profiles, 20);
    assert.deepEqual(browser.signals, []);
    assert.equal(profiles.size, 0);
    assert.ok(!existsSync(profile));
  } finally {
    rmSync(profile, { recursive: true, force: true });
  }
});
