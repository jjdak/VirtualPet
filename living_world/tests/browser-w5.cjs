// Verify W5 through the actual controls in an isolated Chromium session.
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const fs = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE_PATH || 'playwright');

const root = path.resolve(__dirname, '../..');
const review = path.join(root, 'docs/sim/living-world/w5/review');
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

async function main() {
  const checks = [];
  const errors = [];
  const evidence = {};
  const check = async (name, run) => {
    await run();
    checks.push(name);
    console.log('PASS ' + name);
  };
  const server = spawn('./living_world/w5.command', ['--port', '0'], { cwd: root });
  let browser;
  try {
    const base = await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(Error('W5 server startup timed out')), 8000);
      server.stdout.on('data', chunk => {
        const url = String(chunk).match(/http:\/\/127\.0\.0\.1:\d+/);
        if (url) {
          clearTimeout(timer);
          resolve(url[0]);
        }
      });
      server.once('error', reject);
      server.once('exit', code => {
        clearTimeout(timer);
        reject(Error('W5 server exited with code ' + code));
      });
    });
    browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({ viewport: { width: 1420, height: 1000 }, deviceScaleFactor: 1 });
    const page = await context.newPage();
    page.setDefaultTimeout(8000);
    page.on('pageerror', error => errors.push(error.message));
    const requests = [];
    const endpoint = base + '/api/frame';
    const isFrame = item => item.url() === endpoint;
    page.on('request', request => {
      if (isFrame(request)) requests.push(request.postDataJSON());
    });
    const button = id => page.locator('#' + id);
    const submit = async action => {
      const pending = page.waitForResponse(isFrame);
      await action();
      const response = await pending;
      assert(response.ok(), await response.text());
      const frame = await response.json();
      const clock = frame.elapsed ? '第 ' + frame.elapsed + ' 步' : '开场';
      await page.waitForFunction(text => document.querySelector('#clock').textContent.trim() === text, clock);
      return frame;
    };
    const click = id => submit(() => button(id).click());
    const restart = () => click('replay');
    const screenshot = file => page.screenshot({ path: path.join(review, file), fullPage: true, animations: 'disabled' });
    const checkResult = async (frame, expected, labels) => {
      assert(frame.ended);
      assert.deepEqual(frame.result, expected);
      await button('result').waitFor({ state: 'visible' });
      const result = await button('result').innerText();
      for (const label of labels) assert.match(result, label);
      for (const id of ['hint', 'play', 'step']) assert(await button(id).isDisabled());
    };
    const visibleEvents = () => button('events').innerText();
    const assertOrder = (visible, labels) => {
      let previous = -1;
      for (const label of labels) {
        const afterPrevious = visible.slice(previous + 1).search(label);
        assert.notEqual(afterPrevious, -1, visible);
        previous += afterPrevious + 1;
      }
    };
    const summarize = frame => ({
      start: frame.start,
      events: frame.events.filter(event => ['experience', 'hint', 'message', 'decision'].includes(event.type)),
      result: frame.result,
    });

    await fs.mkdir(review, { recursive: true });
    await check('fork opens paused with present evidence only and no result in the frame', async () => {
      const initial = await submit(() => page.goto(base));
      assert.deepEqual(requests, [{ opening: 'fork', elapsed: 0, hint: null }]);
      assert.equal(initial.start, 336);
      assert(!Object.hasOwn(initial, 'result'));
      assert(initial.events.every(event => event.tick <= initial.start));
      assert(await button('result').isHidden());
      assert.match(await visibleEvents(), /阿禾.*紫穗/);
      assert.doesNotMatch(await visibleEvents(), /小岚.*(?:出发|决定)/);
      await screenshot('opening-desktop.png');
      await delay(2800);
      assert.equal(requests.length, 1);
    });

    await check('continuous waiting resolves the fork at +2 with green and no speaker', async () => {
      const first = await click('play');
      assert.equal(first.elapsed, 1);
      assert(!Object.hasOwn(first, 'result'));
      const finish = await page.waitForResponse(isFrame);
      assert(finish.ok());
      const waited = await finish.json();
      await checkResult(waited, {
        actual: { offset: 2, kind: 'p' }, waiting: { offset: 2, kind: 'p' },
        first: null, waiting_first: null,
      }, [/青禾/]);
      assert.deepEqual(requests.slice(1).map(item => item.elapsed), [1, 2]);
      evidence.fork_wait = summarize(waited);
    });

    await check('early purple reminder is a current event and changes fork departure', async () => {
      await restart();
      const reminder = await click('hint');
      assert.deepEqual(reminder.hint, { offset: 0, kind: 'q' });
      assert(!Object.hasOwn(reminder, 'result'));
      assert(await button('result').isHidden());
      assert(await button('hint').isDisabled());
      await click('step');
      const early = await click('step');
      await checkResult(early, {
        actual: { offset: 2, kind: 'q' }, waiting: { offset: 2, kind: 'p' },
        first: { speaker: 'player', offset: 0 }, waiting_first: null,
      }, [/紫穗/, /青禾/, /你/]);
      assertOrder(await visibleEvents(), [/阿禾.*紫穗/, /你.*紫穗/, /小岚.*(?:出发|决定)/]);
      await screenshot('fork-result-desktop.png');
      evidence.fork_early = summarize(early);
    });

    await check('last-moment double click submits one reminder and the step boundary stays exact', async () => {
      await restart();
      await click('step');
      const before = requests.length;
      await page.route('**/api/frame', async route => {
        await delay(160);
        await route.continue();
      });
      const reminder = await submit(() => page.evaluate(() => {
        const hint = document.querySelector('#hint');
        hint.click();
        hint.click();
      }));
      await page.unroute('**/api/frame');
      assert.equal(requests.length, before + 1);
      assert.deepEqual(reminder.hint, { offset: 1, kind: 'q' });
      const last = await click('step');
      await checkResult(last, {
        actual: { offset: 2, kind: 'q' }, waiting: { offset: 2, kind: 'p' },
        first: { speaker: 'player', offset: 1 }, waiting_first: null,
      }, [/紫穗/, /青禾/]);
      assert.equal(last.events.filter(event => event.type === 'hint').length, 1);
      evidence.fork_last_moment = summarize(last);
    });

    await check('camp can pause, resume, and accept a reminder after the natural relay', async () => {
      const opening = await submit(() => button('opening').selectOption('camp'));
      assert.equal(opening.start, 536);
      const position = await button('person-a').getAttribute('style');
      const first = await click('play');
      assert.equal(first.elapsed, 1);
      await button('play').click();
      const before = requests.length;
      await delay(2800);
      assert.equal(requests.length, before);
      const resumed = await click('play');
      assert.equal(resumed.elapsed, 2);
      await button('play').click();
      const relay = await click('step');
      assert.equal(relay.elapsed, 3);
      assert.notDeepEqual(relay.people.A.pos, opening.people.A.pos);
      assert.notEqual(await button('person-a').getAttribute('style'), position);
      const report = relay.events.find(event => event.type === 'message' && event.sender === 'A');
      assert.equal(report.tick, 539);
      assert.equal(report.evidence_tick, 536);
      assert(!Object.hasOwn(relay, 'result'));
      assert(await button('result').isHidden());
      assert(await button('hint').isEnabled());
      const late = await click('hint');
      assert.deepEqual(late.hint, { offset: 3, kind: 'q' });
      let ended = late;
      for (let elapsed = 4; elapsed <= 10; elapsed++) {
        ended = await click('step');
        assert.equal(ended.elapsed, elapsed);
      }
      await checkResult(ended, {
        actual: { offset: 10, kind: 'q' }, waiting: { offset: 10, kind: 'q' },
        first: { speaker: 'A', offset: 3 }, waiting_first: { speaker: 'A', offset: 3 },
      }, [/阿禾/, /紫穗/]);
      assertOrder(await visibleEvents(), [/阿禾.*紫穗/, /阿禾.*(?:告诉|分享|向小岚).*紫穗/, /你.*紫穗/, /小岚.*(?:出发|决定)/]);
      evidence.camp_late = summarize(ended);
      await page.setViewportSize({ width: 390, height: 844 });
      assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      await screenshot('camp-result-mobile.png');
    });

    await check('camp can finish on a narrow screen without a player reminder', async () => {
      let waited = await restart();
      for (let elapsed = 1; elapsed <= 10; elapsed++) {
        waited = await click('step');
        assert.equal(waited.elapsed, elapsed);
      }
      await checkResult(waited, {
        actual: { offset: 10, kind: 'q' }, waiting: { offset: 10, kind: 'q' },
        first: { speaker: 'A', offset: 3 }, waiting_first: { speaker: 'A', offset: 3 },
      }, [/阿禾/, /紫穗/]);
      assert(!waited.events.some(event => event.type === 'hint'));
      assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      evidence.camp_wait = summarize(waited);
    });

    await check('failed request preserves the current scene and retry applies the reminder once', async () => {
      await restart();
      const previous = await visibleEvents();
      let failures = 0;
      const fail = async route => {
        failures++;
        await route.abort('failed');
      };
      await page.route('**/api/frame', fail);
      await button('hint').click();
      await button('retry').waitFor({ state: 'visible' });
      assert.equal(failures, 1);
      assert.match(await button('status').innerText(), /连不上|失败|没能|出错|重试/);
      assert.equal(await visibleEvents(), previous);
      assert(await button('result').isHidden());
      await page.unroute('**/api/frame', fail);
      const retried = await click('retry');
      assert.deepEqual(retried.hint, { offset: 0, kind: 'q' });
      assert.equal(retried.events.filter(event => event.type === 'hint').length, 1);
      assert(await button('retry').isHidden());
      assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
    });

    await check('another tab on the same origin starts clean, and replay and reload restore the opening', async () => {
      const other = await context.newPage();
      const pending = other.waitForResponse(isFrame);
      await other.goto(base);
      const independent = await (await pending).json();
      assert.equal(independent.start, 336);
      assert.equal(independent.hint, null);
      assert(await other.locator('#result').isHidden());
      assert(await page.locator('#hint').isDisabled());
      await other.close();
      const replayed = await restart();
      assert.equal(replayed.start, 536);
      assert.equal(replayed.elapsed, 0);
      assert.equal(replayed.hint, null);
      const reloaded = await submit(() => page.reload());
      assert.equal(reloaded.elapsed, 0);
      assert.equal(reloaded.hint, null);
      assert(await button('result').isHidden());
      assert(await button('hint').isEnabled());
    });

    await check('no uncaught browser exceptions', () => assert.deepEqual(errors, []));
    const receipt = {
      verified_at: new Date().toISOString(), status: 'passed', checks,
      engine: 'isolated Playwright Chromium headless', browser_version: browser.version(),
      desktop_viewport: [1420, 1000], narrow_viewport: [390, 844],
      page_errors: errors, user_saves_touched: false, owner_accepted: false,
    };
    await fs.writeFile(path.join(review, 'browser-verification.json'), JSON.stringify(receipt, null, 2) + '\n');
    await fs.writeFile(path.join(review, 'browser-outcomes.json'), JSON.stringify(evidence, null, 2) + '\n');
  } finally {
    if (browser) await browser.close();
    server.kill('SIGTERM');
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
