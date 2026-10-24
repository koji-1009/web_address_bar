// End-to-end check of package:web_address_bar in the example app. Serves
// build/web (built from lib/main.dart), launches headless Chrome emulating an
// Android phone, drives trusted touch input through the Chrome DevTools
// Protocol, and prints what the app reports and any exception the page threw.
//
// Usage: node tool/example_cdp.mjs [--chrome=path] [--check]
//
// With --check, exits with status 1 unless every scenario ends with the drag
// having reached the app and no pointer down, an idle list, the package active (where enabled), the document
// on the expected snap target, a tap reaching the app, the screen still open
// after a reload and no page exception, for CI.
//
// No npm dependencies: Node's built-in fetch and WebSocket.

import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { mkdtempSync, readFileSync, existsSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, extname, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [key, ...value] = a.replace(/^--/, '').split('=');
    return [key, value.join('=')];
  }),
);
const chromePath = args.chrome ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const webRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../build/web');
const httpPort = 8766;
const debugPort = 9334;

const mime = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.png': 'image/png',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
};

const server = createServer((req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let file = join(webRoot, path);
  if (!file.startsWith(webRoot) || !existsSync(file) || statSync(file).isDirectory()) {
    file = join(webRoot, 'index.html');
  }
  res.writeHead(200, { 'content-type': mime[extname(file)] ?? 'application/octet-stream' });
  res.end(readFileSync(file));
});
await new Promise((r) => server.listen(httpPort, '127.0.0.1', r));

const chrome = spawn(
  chromePath,
  [
    '--headless=new',
    `--remote-debugging-port=${debugPort}`,
    `--user-data-dir=${mkdtempSync(join(tmpdir(), 'example-chrome-'))}`,
    '--no-first-run',
    '--no-default-browser-check',
    // CI runners on Linux cannot give Chrome its own sandbox.
    ...(process.platform === 'linux' ? ['--no-sandbox'] : []),
    'about:blank',
  ],
  { stdio: 'ignore' },
);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function browserWsUrl() {
  for (let i = 0; i < 100; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${debugPort}/json/version`);
      return (await res.json()).webSocketDebuggerUrl;
    } catch {
      await sleep(100);
    }
  }
  throw new Error('Chrome did not start');
}

const ws = new WebSocket(await browserWsUrl());
await new Promise((r) => ws.addEventListener('open', r, { once: true }));
let nextId = 1;
const pending = new Map();
const pageErrors = new Map();
ws.addEventListener('message', (m) => {
  const msg = JSON.parse(m.data);
  if (msg.id && pending.has(msg.id)) {
    const { resolve, reject } = pending.get(msg.id);
    pending.delete(msg.id);
    msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
    return;
  }
  const errors = pageErrors.get(msg.sessionId);
  if (!errors) return;
  if (msg.method === 'Runtime.exceptionThrown') {
    const details = msg.params.exceptionDetails;
    const frames = (details.stackTrace?.callFrames ?? [])
      .slice(0, 6)
      .map((f) => `${f.functionName}@${f.url.split('/').pop()}:${f.lineNumber}`);
    errors.push([details.exception?.description ?? details.text, ...frames].join(' | '));
  } else if (msg.method === 'Runtime.consoleAPICalled' && msg.params.type === 'error') {
    errors.push(msg.params.args.map((a) => a.value ?? a.description).join(' '));
  }
});
function send(method, params = {}, sessionId) {
  const id = nextId++;
  ws.send(JSON.stringify({ id, method, params, sessionId }));
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
}

const androidUa =
  'Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/156.0.0.0 Mobile Safari/537.36';

// Opens the app at `/${page}`, such as `?enable=0#/long-drag`.
async function openPage(page) {
  const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
  pageErrors.set(sessionId, []);
  const s = (method, params) => send(method, params, sessionId);
  await s('Emulation.setUserAgentOverride', { userAgent: androidUa, platform: 'Linux armv8l' });
  await s('Emulation.setDeviceMetricsOverride', {
    width: 412,
    height: 915,
    deviceScaleFactor: 2.625,
    mobile: true,
  });
  await s('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
  await s('Page.enable');
  await s('Runtime.enable');
  await s('Page.navigate', { url: `http://127.0.0.1:${httpPort}/${page}` });
  for (let i = 0; i < 200; i++) {
    const r = await report(s);
    if (r) {
      await sleep(500);
      return { s, sessionId, targetId };
    }
    await sleep(100);
  }
  throw new Error(`page did not become ready for ${page}`);
}

async function report(s) {
  const { result } = await s('Runtime.evaluate', {
    expression:
      'typeof window.$webAddressBarExample === "function" ? window.$webAddressBarExample() : null',
    returnByValue: true,
  });
  return result.value ? JSON.parse(result.value) : null;
}

async function evaluate(s, expression) {
  const { result } = await s('Runtime.evaluate', { expression, returnByValue: true });
  return result.value;
}

async function touch(s, type, x, y) {
  await s('Input.dispatchTouchEvent', {
    type,
    touchPoints: type === 'touchEnd' ? [] : [{ x, y, id: 1 }],
  });
}

// One long, slow drag, as in the #194104 repro: enough events for the engine
// to give up on the semantics placeholder in the middle of it.
async function longDrag(s) {
  const x = 200;
  const from = 750;
  const to = 250;
  const steps = 60;
  await touch(s, 'touchStart', x, from);
  for (let i = 1; i <= steps; i++) {
    await sleep(8);
    await touch(s, 'touchMove', x, from + ((to - from) * i) / steps);
  }
  await touch(s, 'touchEnd');
  await sleep(1500);
}

async function resize(s) {
  for (const height of [800, 915]) {
    await s('Emulation.setDeviceMetricsOverride', {
      width: 412,
      height,
      deviceScaleFactor: 2.625,
      mobile: true,
    });
    await sleep(500);
  }
}

// One tap on the "Tap me" button of the interactive widgets screen.
async function tap(s) {
  const [x, y] = (await report(s)).tapTarget;
  await touch(s, 'touchStart', x, y);
  await sleep(50);
  await touch(s, 'touchEnd');
  await sleep(500);
}

// A tap, then a reload, which has to bring the same screen back with its tap
// count reset.
async function tapAndReload(s) {
  await tap(s);
  await s('Page.reload');
  await sleep(500);
  for (let i = 0; i < 200 && !(await report(s)); i++) {
    await sleep(100);
  }
  await sleep(500);
}

// scrollTop is where the document rests afterwards: 0 without the package; with
// it, the snap target in the middle (bar shown) or, after an upward drag, the
// one 1px below it (bar hidden).
const scenarios = [
  { name: 'stock long drag', page: '?enable=0#/long-drag', run: longDrag, active: false, scrollTop: 0, pointerDowns: 1 },
  { name: 'long drag', page: '#/long-drag', run: longDrag, active: true, scrollTop: 5001, pointerDowns: 1 },
  { name: 'tap', page: '#/interactive', run: tap, active: true, scrollTop: 5000, tapCount: 1 },
  { name: 'reload', page: '#/interactive', run: tapAndReload, active: true, scrollTop: 5000, tapCount: 0 },
  { name: 'collapsed extent', page: '#/collapsed-extent', run: resize, active: true, scrollTop: 5000 },
];

// What --check requires of a scenario's result.
function problems(scenario, result) {
  const found = [];
  const app = result.app ?? {};
  if (result.errors.length > 0) found.push(`${result.errors.length} page exception(s)`);
  if ('pointersDown' in app && app.pointersDown !== 0) found.push(`pointersDown ${app.pointersDown}`);
  if ('listState' in app && app.listState !== 'idle') found.push(`listState ${app.listState}`);
  if ('isActive' in app && app.isActive !== scenario.active) found.push(`isActive ${app.isActive}`);
  if ('tapCount' in scenario && app.tapCount !== scenario.tapCount) found.push(`tapCount ${app.tapCount}`);
  if ('pointerDowns' in scenario && app.pointerDowns !== scenario.pointerDowns) found.push(`pointerDowns ${app.pointerDowns}`);
  const panning = result.bodyTouchAction === 'pan-y';
  if (panning !== scenario.active) found.push(`body touch-action ${result.bodyTouchAction}`);
  if (result.documentScrollTop !== scenario.scrollTop) found.push(`document scrollTop ${result.documentScrollTop}`);
  return found;
}

const results = {};
try {
  for (const scenario of scenarios) {
    const { s, sessionId, targetId } = await openPage(scenario.page);
    await scenario.run(s);
    results[scenario.name] = {
      app: await report(s),
      documentScrollTop: await evaluate(s, 'document.scrollingElement.scrollTop'),
      bodyTouchAction: await evaluate(s, 'getComputedStyle(document.body).touchAction'),
      errors: pageErrors.get(sessionId),
    };
    await send('Target.closeTarget', { targetId });
  }
  console.log(JSON.stringify(results, null, 2));
  if ('check' in args) {
    let failed = false;
    for (const scenario of scenarios) {
      const found = problems(scenario, results[scenario.name]);
      if (found.length > 0) {
        failed = true;
        console.error(`FAIL ${scenario.name}: ${found.join(', ')}`);
      }
    }
    process.exitCode = failed ? 1 : 0;
  }
} finally {
  ws.close();
  chrome.kill();
  server.close();
}
