// Exercise the self-contained follow-up report with no personal world or server.
const { chromium } = require(process.env.PLAYWRIGHT_MODULE_PATH || 'playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

(async () => {
  const directory = path.resolve(__dirname, '../../docs/sim/living-world/w3-long/review');
  const cases = (await fs.readFile(path.join(directory, 'cases.jsonl'), 'utf8')).trim().split('\n').map(JSON.parse);
  const browser = await chromium.launch({headless:true});
  try {
    const page = await browser.newPage({viewport:{width:1160,height:900}});
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    await page.goto(pathToFileURL(path.join(directory,'index.html')).href);
    assert.equal(await page.locator('#cases option').count(),cases.length);
    const selected = cases[Number(await page.locator('#cases').inputValue())];
    assert.deepEqual([selected.family,selected.seed,selected.age,selected.actor,selected.kind],['reversal',4,480,'A','q']);
    await page.locator('#period').selectOption('4');
    const checkPlot = async (selected,first,last) => {
      const n = Object.values(selected.people).flatMap(p => Object.values(p.events).flat())
                      .filter(([t]) => t >= first && t <= last).length;
      assert.equal(await page.locator('#plot circle,#plot path').count(),n);
    };
    await checkPlot(selected,2161,2640);
    await page.screenshot({path:path.join(directory,'choices.png')});
    await page.locator('#cases').selectOption('0');
    await page.locator('#period').selectOption('0');
    await checkPlot(cases[0],241,720);
    await page.locator('summary').click();
    assert(await page.locator('#raw tr').first().isVisible());
    assert.equal(await page.locator('#counts tr').count(),4);
    await page.setViewportSize({width:390,height:844});
    assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
    assert.deepEqual(errors,[]);
    console.log('Offline Chromium report passed: cohort selection, two source families, period filters, departure counts, raw table and narrow viewport.');
  } finally {
    await browser.close();
  }
})().catch(error=>{console.error(error);process.exitCode=1;});
