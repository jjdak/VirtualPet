// Exercise the W6 launcher using an isolated Chromium context and disposable storage.
const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const { createHash } = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE_PATH || 'playwright');

const root = path.resolve(__dirname, '../..');
const review = path.join(root, 'docs/sim/living-world/w6/review');
const storageKey = 'virtualpet-w6';
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

async function startup(server) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(Error('W6 launcher startup timed out')), 8000);
    const fail = error => {
      clearTimeout(timer);
      reject(error);
    };
    const findAddress = chunk => {
      const match = String(chunk).match(/http:\/\/127\.0\.0\.1:\d+/);
      if (match) {
        clearTimeout(timer);
        resolve(match[0]);
      }
    };
    server.stdout.on('data', findAddress);
    server.stderr.on('data', findAddress);
    server.once('error', fail);
    server.once('exit', code => fail(Error('W6 launcher exited with code ' + code)));
  });
}

async function main() {
  const { NAMES, PLACES, RULE_VERSION, mindView, replay } = await import('../web/w6/world.mjs');
  const { cueNames } = await import('../web/w6/tile-view.mjs');
  const checks = [];
  const errors = [];
  const outcome = {};
  const check = async (name, run) => {
    await run();
    checks.push(name);
    console.log('PASS ' + name);
  };
  const server = spawn('./living_world/w6.command', ['--port', '0'], { cwd: root });
  let browser;
  try {
    const base = await startup(server);
    browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, deviceScaleFactor: 1 });
    const page = await context.newPage();
    page.setDefaultTimeout(8000);
    page.on('pageerror', error => errors.push(error.message));
    const control = id => page.locator('#' + id);
    const tick = async () => Number(await control('clock').getAttribute('data-tick'));
    const journal = () => control('events').innerText();
    const saved = () => page.evaluate(key => JSON.parse(localStorage.getItem(key)), storageKey);
    const waitSave = values => page.waitForFunction(({ key, values }) => {
      const recipe = JSON.parse(localStorage.getItem(key));
      return recipe && Object.entries(values).every(([name, value]) =>
        JSON.stringify(recipe[name]) === JSON.stringify(value));
    }, { key: storageKey, values });
    const waitTick = value => page.waitForFunction(wanted => Number(document.querySelector('#clock').dataset.tick) === wanted, value);
    const past = value => page.waitForFunction(previous => Number(document.querySelector('#clock').dataset.tick) > previous, value);
    const picture = async id => createHash('sha256').update(await control(id).evaluate(canvas => canvas.toDataURL())).digest('hex');
    const summaries = async () => [await control('actual-summary').textContent(), await control('baseline-summary').textContent()];
    const resident = id => control('residents').locator('button[data-resident="' + id + '"]');
    const camera = id => control(id).evaluate(canvas => ({
      follow: canvas.dataset.follow,
      x: Number(canvas.dataset.viewX),
      y: Number(canvas.dataset.viewY),
      zoom: Number(canvas.dataset.zoom),
    }));
    const spritePoint = async (map, person) => {
      const { x, y, zoom } = await camera(map);
      const bounds = await control(map).boundingBox();
      return {
        x: bounds.x + bounds.width * (0.5 + (person.x + 0.5 - x) * zoom / 12),
        y: bounds.y + bounds.height * (0.5 + (person.y + 0.5 - y) * zoom / 9),
      };
    };
    const mind = async () => ({
      name: await control('mind-name').innerText(),
      summary: await control('mind-summary').innerText(),
      details: await control('mind-details').textContent(),
      growth: await control('growth-status').innerText(),
      stages: await control('growth-stages').innerText(),
    });
    const checkMind = async (world, id) => {
      const expected = mindView(world, id);
      if (!await control('mind-context').evaluate(details => details.open)) {
        await control('mind-context').locator('summary').click();
      }
      assert(await control('mind-details').isVisible());
      const presented = await mind();
      assert(presented.name.includes(NAMES[id]));
      assert.equal(await control('resident-mind').getAttribute('data-cue'), expected.cue);
      assert(presented.summary.includes(expected.summary), presented.summary);
      const { curiosity, speed, sight } = world.residents[id].traits;
      assert(presented.details.includes('好奇 ' + Math.round(curiosity * 100) + '％'));
      assert(presented.details.includes('走一格用 ' + speed + ' 步'));
      assert(presented.details.includes('能看 ' + sight + ' 格'));
      for (const detail of expected.details) assert(presented.details.includes(detail), detail);
      for (const stage of expected.growth.milestones) {
        assert(presented.stages.includes(stage.title), stage.title);
        assert(presented.stages.includes(stage.description), stage.description);
        const milestone = control('growth-stages').locator('[data-milestone="' + stage.id + '"]');
        assert.equal(await milestone.getAttribute('data-earned-at'), stage.earnedAt == null ? null : String(stage.earnedAt));
      }
      assert(new RegExp(expected.growth.earned + '\\s*[/／]\\s*' + expected.growth.total).test(presented.growth),
        presented.growth);
      return expected;
    };
    const tables = () => page.locator('#trips tbody tr').evaluateAll(rows => rows.map(row => ({
      ordinal: row.dataset.ordinal,
      cells: Array.from(row.cells, cell => cell.innerText),
      trip: Number(row.dataset.trip),
      actual: { ...row.querySelector('[data-branch="actual"]').dataset },
      waiting: { ...row.querySelector('[data-branch="baseline"]').dataset },
    })));
    const pairedTicks = async () => {
      const [actual, baseline] = await Promise.all(['actual-map', 'baseline-map'].map(id => control(id).getAttribute('data-tick')));
      assert.equal(Number(actual), await tick());
      assert.equal(actual, baseline);
    };
    const step = async () => {
      const before = await tick();
      await control('step').click();
      await waitTick(before + 1);
    };
    const fast = async () => {
      const before = await tick();
      await control('fast').click();
      await past(before);
      await control('fast').waitFor({ state: 'visible' });
      await page.waitForFunction(() => !document.querySelector('#fast').disabled);
      return tick();
    };
    const confirm = async (id, accept) => {
      const dialog = page.waitForEvent('dialog');
      const clicked = control(id).click();
      const prompt = await dialog;
      assert.equal(prompt.type(), 'confirm');
      await (accept ? prompt.accept() : prompt.dismiss());
      await clicked;
    };
    const noOverflow = async () => {
      assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
    };
    const screenshot = file => page.screenshot({
      path: path.join(review, file), fullPage: true, animations: 'disabled',
    });

    await fs.mkdir(review, { recursive: true });
    await page.goto(base);
    await page.waitForFunction(() => !document.querySelector('#step').disabled);

    let initialSeed;
    let initialResidents;
    let initialTraits;
    let forkTick;
    let reachedTick;
    let chosenPlace;
    let beforeHint;
    let highest;
    let initialMap;
    await check('fresh world opens paused with four residents and a painted map', async () => {
      await waitTick(0);
      initialSeed = Number(await control('seed').inputValue());
      assert(Number.isInteger(initialSeed));
      initialResidents = await control('residents').innerText();
      initialTraits = (await mind()).details;
      assert.equal(await control('residents').locator('li').count(), 4);
      assert.match(initialResidents, /小岚/);
      assert.match(await page.locator('.journal p').first().innerText(), /可以沉默.*含义没有预设/);
      assert(await control('comparison').isHidden());
      assert(await control('hint').isEnabled());
      initialMap = await picture('actual-map');
      assert(await control('actual-map').evaluate(canvas => {
        const context = canvas.getContext('2d');
        const colors = new Set(context.getImageData(0, 0, canvas.width, canvas.height).data);
        return canvas.width > 0 && canvas.height > 0 && colors.size > 20;
      }));
      await delay(500);
      assert.equal(await tick(), 0);
      await noOverflow();
      await screenshot('opening-desktop.png');
    });

    const reconstitute = (seed, tick) => replay({ version: RULE_VERSION, seed, tick, input: null });
    await check('default follows 小岚; keyboard and actual canvas hit-select residents', async () => {
      assert.equal((await camera('actual-map')).follow, 'B');
      assert.equal(await resident('B').getAttribute('aria-pressed'), 'true');
      assert.match((await mind()).name, /小岚/);
      await resident('A').focus();
      await resident('A').press('Enter');
      assert.equal((await camera('actual-map')).follow, 'A');
      assert.match((await mind()).name, /阿禾/);

      await control('camera').selectOption('overview');
      await page.waitForFunction(() => document.querySelector('#actual-map').dataset.follow === 'overview');
      const person = reconstitute(initialSeed, 0).residents.D;
      await control('actual-map').scrollIntoViewIfNeeded();
      const location = await spritePoint('actual-map', person);
      await page.mouse.click(location.x, location.y);
      assert.equal(await resident('D').getAttribute('aria-pressed'), 'true');
      assert.match((await mind()).name, new RegExp(NAMES.D));
      await control('camera').selectOption('follow');
      await resident('B').click();
      assert.equal((await camera('actual-map')).follow, 'B');
    });

    await check('step, play, and pause show intermediate camera positions during real tile motion', async () => {
      await step();
      let oldPosition;
      let newPosition;
      let moveTick;
      for (let t = 2; t <= 40; t++) {
        oldPosition = reconstitute(initialSeed, t - 1).residents.B;
        newPosition = reconstitute(initialSeed, t).residents.B;
        if (oldPosition.x !== newPosition.x || oldPosition.y !== newPosition.y) {
          moveTick = t;
          break;
        }
      }
      assert(moveTick);
      await page.evaluate(moveTick => {
        const canvas = document.querySelector('#actual-map');
        const frames = [];
        const samplePixels = () => {
          const image = canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height);
          let hash = 0;
          for (let offset = 0; offset < image.data.length; offset += 3692) {
            hash = (Math.imul(hash, 31) + image.data[offset]) >>> 0;
          }
          return hash;
        };
        window.__w6Frames = frames;
        const record = () => {
          const tick = Number(canvas.dataset.tick);
          frames.push([tick, Number(canvas.dataset.viewX), Number(canvas.dataset.viewY),
            tick === moveTick ? samplePixels() : null]);
          if (window.__w6Frames === frames && frames.length < 1500) requestAnimationFrame(record);
        };
        requestAnimationFrame(record);
      }, moveTick);
      await control('play').click();
      await past(moveTick);
      await control('play').click();
      const paused = await tick();
      const frames = await page.evaluate(() => {
        const frames = window.__w6Frames;
        delete window.__w6Frames;
        return frames;
      });
      await delay(550);
      assert.equal(await tick(), paused);
      assert.notEqual(await picture('actual-map'), initialMap);
      const moveFrames = frames.filter(frame => frame[0] === moveTick);
      const axis = oldPosition.x !== newPosition.x ? 1 : 2;
      const tile = axis === 1 ? 'x' : 'y';
      const from = oldPosition[tile] + 0.5;
      const to = newPosition[tile] + 0.5;
      const intermediate = moveFrames.filter(frame => frame[axis] > Math.min(from, to) &&
        frame[axis] < Math.max(from, to));
      assert(new Set(intermediate.map(frame => frame[axis])).size >= 2, JSON.stringify(moveFrames));
      assert(new Set(intermediate.map(frame => frame[3])).size >= 2, 'canvas pixels were unchanged during the move');
      outcome.camera_movement = { tick: moveTick, axis: tile, from, to, intermediate: intermediate.slice(0, 6) };
      await step();
      assert.equal(await tick(), paused + 1);
    });

    await check('a chosen seed opens an unscripted world with its own residents', async () => {
      if (initialSeed !== 7) {
        await control('seed').fill('7');
        await confirm('new-world', true);
        await waitTick(0);
        await waitSave({ seed: 7, tick: 0 });
        await checkMind(reconstitute(7, 0), 'B');
        assert.notEqual((await mind()).details, initialTraits);
        initialSeed = 7;
        initialResidents = await control('residents').innerText();
        initialTraits = (await mind()).details;
        initialMap = await picture('actual-map');
      }
    });

    await check('three consecutive trips advance the world before the player acts', async () => {
      const departures = [];
      for (let index = 0; index < 3; index++) departures.push(await fast());
      assert(departures.every((value, i) => i === 0 || value > departures[i - 1]));
      assert.equal((await saved()).input, null);
      assert(await control('comparison').isHidden());
      forkTick = await tick();
      beforeHint = { text: await journal(), map: await picture('actual-map'), mind: await mind() };
      chosenPlace = 'q';
      await control('place').selectOption(chosenPlace);
      outcome.pre_hint_trip_ticks = departures;
    });

    await check('a repeated click records exactly one suggestion at the chosen tick', async () => {
      await page.evaluate(() => {
        const button = document.querySelector('#hint');
        button.click();
        button.click();
      });
      assert.equal(await tick(), forkTick);
      await waitSave({ input: { tick: forkTick, place: chosenPlace } });
      assert.deepEqual((await saved()).input, { tick: forkTick, place: chosenPlace });
      const fork = replay({ version: RULE_VERSION, seed: initialSeed, tick: forkTick, input: null });
      assert.deepEqual(outcome.pre_hint_trip_ticks, fork.residents.B.trips.slice(-3).map(trip => trip.departure));
      assert(await control('hint').isDisabled());
      assert(await control('comparison').isVisible());
      assert.notEqual(await journal(), beforeHint.text);
      await pairedTicks();
      outcome.input = (await saved()).input;
    });

    await check('both worlds reach several synchronized departures for paired comparison', async () => {
      for (let index = 0; index < 5; index++) {
        await fast();
        await pairedTicks();
      }
      const rows = await tables();
      assert(rows.length >= 3);
      assert(rows.every((row, i) => Number(row.ordinal) === i + 1));
      reachedTick = await tick();
      await waitSave({ tick: reachedTick });
      const recipe = await saved();
      const actual = replay(recipe);
      const waiting = replay({ ...recipe, input: null });
      const tripsAfterFork = world => world.residents.B.trips.filter(trip => trip.departure > forkTick);
      const actualTrips = tripsAfterFork(actual);
      const waitingTrips = tripsAfterFork(waiting);
      assert.equal(rows.length, Math.max(actualTrips.length, waitingTrips.length));
      assert(actualTrips.some((trip, index) => waitingTrips[index] && trip.place !== waitingTrips[index].place));
      assert(actualTrips.some((trip, index) => waitingTrips[index] && trip.departure !== waitingTrips[index].departure));
      assert.notEqual(actualTrips.length, waitingTrips.length);
      for (const [index, row] of rows.entries()) {
        const actualTrip = actualTrips[index];
        const waitingTrip = waitingTrips[index];
        assert.equal(row.trip, (actualTrip ?? waitingTrip).id);
        for (const [trip, text, data] of [
          [actualTrip, row.cells[1], row.actual], [waitingTrip, row.cells[2], row.waiting],
        ]) {
          if (trip) {
            assert.equal(data.place, trip.place);
            assert.equal(Number(data.departure), trip.departure);
            assert.equal(data.reward, String(trip.reward ?? ''));
            assert(text.includes(PLACES[trip.place].name), text);
            assert(text.includes('+' + (trip.departure - forkTick) + ' 步出发'), text);
            const result = trip.arrived == null ? '在路上' : trip.reward > 0 ? '感觉不错'
              : trip.reward < 0 ? '感到不适' : '没有食物';
            assert(text.includes(result), text);
          } else {
            assert.match(text, /此刻还没有对应记录/);
            assert.match(row.cells[3], /还不能对照/);
          }
        }
        if (actualTrip && waitingTrip && actualTrip.departure !== waitingTrip.departure) {
          const delta = actualTrip.departure - waitingTrip.departure;
          assert(row.cells[3].includes((delta > 0 ? '晚' : '早') + ' ' + Math.abs(delta) + ' 步'));
        }
      }
      const latestSignals = actual.events.filter(event => event.type === 'signal');
      assert(latestSignals.length > 0);
      const visibleSignals = await control('events').locator('[data-type="signal"]').allTextContents();
      assert(visibleSignals.length > 0);
      for (const signal of visibleSignals) assert(latestSignals.some(event => signal.endsWith(event.text)));
      outcome.synchronized_events = { actual_trips: actualTrips, waiting_trips: waitingTrips, recent_signal: latestSignals.at(-1) };
      highest = { map: await picture('actual-map'), text: await journal(), rows, summaries: await summaries(),
        mind: await mind() };
      outcome.latest_tick = reachedTick;
      outcome.trip_rows = rows;
      await noOverflow();
      await screenshot('comparison-desktop.png');
    });

    await check('paired inspectors show branch-specific actions, evidence, and cues', async () => {
      const recipe = await saved();
      const actual = await checkMind(replay(recipe), 'B');
      await control('mind-branch').selectOption('baseline');
      const waiting = await checkMind(replay({ ...recipe, input: null }), 'B');
      assert.notEqual(actual.summary, waiting.summary);
      assert.notEqual(actual.cue, waiting.cue);
      assert((await control('actual-summary').textContent()).includes(NAMES.B + cueNames[actual.cue]));
      assert((await control('baseline-summary').textContent()).includes(NAMES.B + cueNames[waiting.cue]));
      await control('mind-branch').selectOption('actual');
      await checkMind(replay(recipe), 'B');
    });

    await check('growth crosses two documented milestones and rewind shows the pre-reminder stage', async () => {
      await resident('C').click();
      const current = await checkMind(replay(await saved()), 'C');
      assert.equal(current.growth.earned, 2);
      const achievements = current.growth.milestones.filter(stage => stage.earnedAt !== null);
      assert(achievements.every(stage => stage.earnedAt > forkTick && stage.earnedAt <= reachedTick));
      outcome.growth_transition = { resident: 'C', from_tick: forkTick, to_tick: reachedTick, achievements };
      await screenshot('resident-growth-desktop.png');
      await control('rewind').click();
      await waitTick(forkTick);
      const previous = await checkMind(reconstitute(initialSeed, forkTick), 'C');
      assert.equal(previous.growth.earned, 0);
      outcome.growth_transition.before = previous.growth.earned;
      outcome.growth_transition.after = current.growth.earned;
      await control('present').click();
      await waitTick(reachedTick);
      await checkMind(replay(await saved()), 'C');
      await resident('B').click();
    });

    await check('rewind reaches the genuine pre-suggestion view and return restores the later view', async () => {
      await control('rewind').click();
      await waitTick(forkTick);
      await pairedTicks();
      assert.equal(await journal(), beforeHint.text);
      assert.deepEqual(await mind(), beforeHint.mind);
      assert.equal(await picture('actual-map'), beforeHint.map);
      assert.equal(await picture('actual-map'), await picture('baseline-map'));
      assert.deepEqual(await tables(), []);
      assert.equal((await saved()).tick, reachedTick);
      assert(await control('hint').isDisabled());
      await control('present').click();
      await waitTick(reachedTick);
      assert.deepEqual(await tables(), highest.rows);
      assert.equal(await journal(), highest.text);
      assert.equal(await picture('actual-map'), highest.map);
    });

    await check('stepping a rewind replays its recorded hint without changing the saved highest tick', async () => {
      await control('rewind').click();
      await waitTick(forkTick);
      await step();
      assert.notEqual(await journal(), beforeHint.text);
      assert.deepEqual((await saved()).input, { tick: forkTick, place: chosenPlace });
      assert.equal((await saved()).tick, reachedTick);
      await pairedTicks();
    });

    await check('reload restores the latest world from a compact replay recipe', async () => {
      const payload = await saved();
      assert.deepEqual(Object.keys(payload).sort(), ['input', 'seed', 'tick', 'version']);
      assert.equal(payload.seed, initialSeed);
      assert.equal(payload.tick, reachedTick);
      outcome.saved_recipe = payload;
      outcome.saved_recipe_bytes = Buffer.byteLength(JSON.stringify(payload));
      await page.reload();
      await waitTick(reachedTick);
      await pairedTicks();
      assert.deepEqual(await tables(), highest.rows);
      assert.deepEqual(await summaries(), highest.summaries);
      assert.equal(await journal(), highest.text);
      assert.equal(await picture('actual-map'), highest.map);
      await delay(550);
      assert.equal(await tick(), reachedTick);
    });

    await check('opening a fresh browser context does not inherit the played world', async () => {
      const fresh = await browser.newContext();
      try {
        const other = await fresh.newPage();
        await other.goto(base);
        await other.waitForFunction(() => document.querySelector('#clock').dataset.tick === '0');
        assert(await other.locator('#comparison').isHidden());
        assert(await other.locator('#hint').isEnabled());
      } finally {
        await fresh.close();
      }
      assert.equal(await tick(), reachedTick);
      assert.deepEqual(await tables(), highest.rows);
    });

    await check('390px and 768px show comparison without horizontal overflow', async () => {
      for (const viewport of [{ width: 390, height: 844 }, { width: 768, height: 1024 }]) {
        await page.setViewportSize(viewport);
        await noOverflow();
        assert(await control('comparison').isVisible());
        await pairedTicks();
        if (viewport.width === 390) {
          await screenshot('comparison-mobile.png');
          await resident('D').focus();
          await resident('D').press('Enter');
          assert.equal((await camera('actual-map')).follow, 'D');
          await checkMind(replay(await saved()), 'D');
          await control('camera').selectOption('overview');
          await control('baseline-map').scrollIntoViewIfNeeded();
          const waiting = replay({ ...(await saved()), input: null });
          const point = await spritePoint('baseline-map', waiting.residents.A);
          await page.mouse.click(point.x, point.y);
          assert.equal(await resident('A').getAttribute('aria-pressed'), 'true');
          assert.equal(await control('resident-mind').getAttribute('data-branch'), 'baseline');
          assert(await control('mind-summary').evaluate(summary => {
            const bounds = summary.getBoundingClientRect();
            return bounds.top >= 0 && bounds.bottom <= innerHeight;
          }));
          await checkMind(waiting, 'A');
          await control('mind-branch').selectOption('actual');
          await control('camera').selectOption('follow');
          await resident('B').click();
        }
      }
    });

    await check('cancel preserves progress; same-seed replay regenerates the opening', async () => {
      await confirm('replay', false);
      assert.equal(await tick(), reachedTick);
      assert.deepEqual(await tables(), highest.rows);
      await confirm('replay', true);
      await waitTick(0);
      assert.equal(Number(await control('seed').inputValue()), initialSeed);
      assert.equal(await control('residents').innerText(), initialResidents);
      assert.equal((await mind()).details, initialTraits);
      assert.equal(await picture('actual-map'), initialMap);
      assert(await control('comparison').isHidden());
      assert((await saved()) === null || (await saved()).input === null);
    });

    await check('a different seed generates a different world at its own start', async () => {
      const otherSeed = initialSeed === 1 ? 2 : 1;
      await step();
      await control('seed').fill(String(otherSeed));
      await confirm('new-world', true);
      await waitTick(0);
      await waitSave({ seed: otherSeed, tick: 0 });
      await checkMind(reconstitute(otherSeed, 0), 'B');
      assert.notEqual((await mind()).details, initialTraits);
      assert(await control('comparison').isHidden());
    });

    await check('no uncaught browser exceptions', () => assert.deepEqual(errors, []));
    const receipt = {
      verified_at: new Date().toISOString(), status: 'passed', checks,
      engine: 'isolated Playwright Chromium headless', browser_version: browser.version(),
      viewports: [[1440, 1000], [390, 844], [768, 1024]],
      page_errors: errors, user_saves_touched: false, owner_accepted: false,
    };
    await fs.writeFile(path.join(review, 'browser-verification.json'), JSON.stringify(receipt, null, 2) + '\n');
    await fs.writeFile(path.join(review, 'browser-outcomes.json'), JSON.stringify(outcome, null, 2) + '\n');
  } finally {
    if (browser) await browser.close();
    server.kill('SIGTERM');
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
