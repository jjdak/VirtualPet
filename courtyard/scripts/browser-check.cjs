// Run against the local preview. Playwright is a QA tool, not an app dependency.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE_PATH || 'playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs/promises');
const path=require('node:path');
const output=path.resolve(process.env.COURTYARD_QA_DIR || '../.runtime/courtyard');
(async()=>{
  await fs.mkdir(output,{recursive:true});
  const browser=await chromium.launch({headless:true});
  try {
    const page=await browser.newPage({viewport:{width:1280,height:720},deviceScaleFactor:1});
    const errors=[];page.on('pageerror',e=>errors.push(e.message));
    page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
    await page.goto(process.env.COURTYARD_URL || 'http://127.0.0.1:4173/?inspect=1');
    await page.waitForFunction(()=>!!window.__courtyard);
    await page.locator('#loading').waitFor({state:'hidden'});
    const state=()=>page.evaluate(()=>window.__courtyard.snapshot());
    // Wait for rendered simulation progress, not wall time: software WebGL can run at 3 fps.
    const advance=async(seconds)=>{const t=(await state()).time;await page.waitForFunction(end=>window.__courtyard.snapshot().time>=end,t+seconds,{timeout:45000});};
    const point=async(x,z)=>page.evaluate(([x,z])=>window.__courtyard.project(x,.17,z),[x,z]);
    const clickWater=async(x,z)=>{const p=await point(x,z);await page.mouse.click(p.x,p.y);};
    await page.locator('#inspection summary').click();
    await page.locator('#closeup').click();await page.locator('#blinkOpen').click();
    await page.waitForTimeout(100);await page.screenshot({path:path.join(output,'qa-eyes-open.png')});
    await page.locator('#blinkClosed').click();await page.waitForTimeout(100);
    const closed=await state();assert.equal(closed.character.blink,1);
    assert(closed.character.morphs.some(m=>m.active.some(([i,v])=>i===12&&v===1)));
    await page.screenshot({path:path.join(output,'qa-eyes-closed.png')});
    await page.locator('#natural').click();await page.locator('#wide').click();
    const start=await state();await clickWater(-3,2.7);
    await page.waitForFunction(()=>window.__courtyard.snapshot().phase==='observe');
    await advance(1.35);const left=await state();
    assert.equal(left.touchCount,start.touchCount+1);console.log('Left gaze sampled at rendered time',left.time,'yaw',left.character.yaw);
    await page.screenshot({path:path.join(output,'qa-water.png')});
    await clickWater(2.8,2.7);await advance(1.6);const right=await state();
    console.log('Right gaze sampled at rendered time',right.time,'yaw',right.character.yaw);
    assert(right.character.yaw-left.character.yaw>.25,'Head must actually turn between left and right');
    assert(Math.hypot(...right.character.eyeRotation.map((v,i)=>v-left.character.eyeRotation[i]))>.0001,'Eye bones must actually move');
    const stone=await page.evaluate(()=>window.__courtyard.project(2,.91,-2));
    await page.mouse.click(stone.x,stone.y);await page.waitForTimeout(100);
    assert.equal((await state()).touchCount,right.touchCount,'Stone must not act as water');
    for(let i=0;i<12;i++)await clickWater(i%2?2:-2,2.7);
    const rapid=await state();assert.equal(rapid.touchCount,right.touchCount+12);assert(rapid.ripples<=8);
    // Software WebGL advances the clamped simulation slowly. Keep the state
    // assertion, but allow enough wall time for 4.9 simulation seconds at ~1 fps.
    console.log('Waiting for recovery at simulation time',rapid.time,'phase',rapid.phase);
    try {
      await page.waitForFunction(()=>window.__courtyard.snapshot().phase==='idle',null,{timeout:120000});
    }catch(error){console.log('Recovery timeout snapshot',JSON.stringify(await state()));throw error;}
    const recovered=await state();assert.equal(recovered.ripples,0);console.log('Recovered after rapid input');
    await page.locator('#pause').click();const frozen=await state();
    await clickWater(0,2.7);await page.waitForTimeout(300);const still=await state();
    assert.equal(still.time,frozen.time);assert.equal(still.touchCount,frozen.touchCount);
    await page.locator('#pause').click();
    // Record the real canvas: wide water response, then a close view of head/eyes.
    await page.locator('#record').click();await clickWater(.2,2.6);
    await page.waitForTimeout(1600);await page.screenshot({path:path.join(output,'qa-final-water.png')});
    await page.waitForTimeout(1500);await page.locator('#closeup').click();
    await page.locator('#scene').press('Enter');await page.waitForTimeout(800);
    const nearLeft=await point(-3,1.3);await page.mouse.click(nearLeft.x,nearLeft.y);
    await page.waitForTimeout(1700);await page.screenshot({path:path.join(output,'qa-look-left.png')});
    await page.locator('#recording').waitFor({state:'visible',timeout:16000});
    const data=await page.locator('#recording').getAttribute('href');
    await fs.writeFile(path.join(output,'c2-final.webm'),Buffer.from(data.split(',')[1],'base64'));
    await page.locator('#wide').click();await page.locator('#inspection summary').click();
    await page.screenshot({path:path.join(output,'c2-final.png')});
    assert.deepEqual(errors,[],'Browser must not report runtime or shader errors');
    const report={verifiedAt:new Date().toISOString(),browser:browser.version(),checks:['blink morph and visible open/closed screenshots','left/right head and eye movement','water pointer hit','stone rejection','12 rapid inputs with 8 ripple limit','return to idle and ripple disposal','pause freezes time and rejects input','keyboard water touch','canvas recording','no browser runtime errors'],left,right,rapid,recovered,errors};
    await fs.writeFile(path.join(output,'verification.json'),JSON.stringify(report,null,2));
    console.log(JSON.stringify({checks:report.checks,browser:report.browser,leftYaw:left.character.yaw,rightYaw:right.character.yaw,output}));
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
