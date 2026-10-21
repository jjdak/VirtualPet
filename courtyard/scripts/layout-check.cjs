// Targeted visual/raycast check for the original layout with refined materials.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE_PATH || 'playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs/promises');
const path=require('node:path');
const output=path.resolve(process.env.COURTYARD_QA_DIR || '../.runtime/courtyard/layout-art');
(async()=>{
  await fs.mkdir(output,{recursive:true});
  const browser=await chromium.launch({headless:true});
  try {
    const page=await browser.newPage({viewport:{width:1280,height:720},deviceScaleFactor:1});
    const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
    await page.goto(process.env.COURTYARD_URL || 'http://127.0.0.1:4173/?inspect=1');
    await page.waitForFunction(()=>!!window.__courtyard);
    await page.locator('#loading').waitFor({state:'hidden'});
    await page.locator('#inspection').evaluate(e=>e.style.display='none');
    const state=()=>page.evaluate(()=>window.__courtyard.snapshot());
    const click=async(x,y,z)=>{const p=await page.evaluate(p=>window.__courtyard.project(...p),[x,y,z]);await page.mouse.click(p.x,p.y);};
    await page.screenshot({path:path.join(output,'preview.png')});
    const before=await state();await click(-2.8,.17,2.7);
    await page.waitForFunction(()=>window.__courtyard.snapshot().phase==='observe');
    const start=(await state()).time;
    await page.waitForFunction(t=>window.__courtyard.snapshot().time>t+1.3,start,{timeout:45000});
    const after=await state();assert.equal(after.touchCount,before.touchCount+1);assert(after.ripples>0);
    assert(Math.abs(after.character.yaw-before.character.yaw)>.15);
    await page.screenshot({path:path.join(output,'water.png')});
    for(const p of [[2,.91,-2],[4.32,.36,2],[0,.17,5]])await click(...p);
    assert.equal((await state()).touchCount,after.touchCount,'Stone, pool rim and outside background must not trigger water');
    await page.locator('#pause').click();const frozen=await state();await click(2.8,.17,2.7);
    assert.equal((await state()).touchCount,frozen.touchCount);await page.locator('#pause').click();
    await page.setViewportSize({width:390,height:844});await page.waitForTimeout(1000);
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth),390);
    await page.screenshot({path:path.join(output,'narrow.png')});
    assert.deepEqual(errors,[]);
    const report={verifiedAt:new Date().toISOString(),checks:['real water input and ripple','head response after notice','stone rejection','pool rim rejection','outside pool rejection','pause rejects input','390px viewport without overflow','no runtime or shader errors'],before,after,errors};
    await fs.writeFile(path.join(output,'verification.json'),JSON.stringify(report,null,2));console.log(JSON.stringify({checks:report.checks,output}));
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
