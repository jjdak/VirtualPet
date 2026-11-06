// Isolated real-browser acceptance. Never connects to the owner's running world.
const path=require('node:path'), fs=require('node:fs/promises'), os=require('node:os');
const assert=require('node:assert/strict'), {spawn}=require('node:child_process');
const {createHash}=require('node:crypto');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE_PATH||'playwright');
const root=path.resolve(__dirname,'../..');
const w2=process.argv.includes('--w2');
const review=path.join(root,'docs/sim/living-world',w2?'w2/review':'review');
const serverFile=w2?'living_world/src/context_server.py':'living_world/src/server.py';
const tickOf=save=>w2?save.active.tick:save.tick;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
  const tmp=await fs.mkdtemp(path.join(os.tmpdir(),'w1-browser-'));
  let server,browser,page,stderr='';const checks=[],errors=[];
  const check=async(name,fn)=>{await fn();checks.push(name);console.log('PASS '+name);};
  const receipt={verified_at:new Date().toISOString(),status:'running',engine:'isolated Playwright Chromium headless',checks,owner_accepted:false};
  try{
    server=spawn(process.env.PYTHON||'python3',[serverFile,'--port','0','--save-dir',path.join(tmp,'saves')],{cwd:root});
    server.stderr.on('data',d=>stderr+=d);
    const base=await new Promise((resolve,reject)=>{const timeout=setTimeout(()=>reject(Error('server startup timed out')),8000);server.stdout.on('data',d=>{const m=String(d).match(/http:\/\/127\.0\.0\.1:\d+/);if(m){clearTimeout(timeout);resolve(m[0]);}});server.on('error',reject);server.once('exit',()=>{clearTimeout(timeout);reject(Error('server exited: '+stderr));});});
    browser=await chromium.launch({headless:true});receipt.browser_version=browser.version();
    page=await browser.newPage({acceptDownloads:true,viewport:{width:1280,height:960},deviceScaleFactor:1});
    page.setDefaultTimeout(6000);page.setDefaultNavigationTimeout(8000);page.on('pageerror',e=>errors.push(e.message));
    const current=async()=>{const r=await page.request.get(base+'/api/state',{timeout:4000});assert(r.ok());return r.json();};
    const snapshot=async()=>{const r=await page.request.get(base+'/api/export',{timeout:4000});assert(r.ok());return r.json();};
    const clickCommand=async(selector,action)=>{
      const answer=page.waitForResponse(r=>r.url()===base+'/api/command'&&r.request().postDataJSON()?.action===action,{timeout:6000});
      await page.locator(selector).click();const response=await answer;assert(response.ok(),await response.text());
      await page.waitForFunction(()=>!document.querySelector('#play').disabled);return response.json();
    };
    const confirmCommand=async(selector,action)=>{
      await page.locator(selector).click();await page.locator('#confirm-dialog').waitFor({state:'visible'});
      return clickCommand('#confirm-accept',action);
    };
    await page.goto(base);await page.locator('#status').filter({hasText:'世界已暂停'}).waitFor();
    await check('single-recipient hint, environment change, and save during a journey',async()=>{
      await page.locator('#hint-place').selectOption('q');await clickCommand('#hint','hint');
      await page.locator('#q-effect').selectOption('1');await clickCommand('#apply-q','environment');
      for(let i=0;i<4;i++)await clickCommand('#step','step');
      const state=await current();assert.equal(state.world.tick,4);assert.equal(state.world.residents.A.hints.length,1);assert.equal(state.world.residents.B.hints.length,0);
      assert.equal(state.world.residents.A.phase,'outbound');await clickCommand('#save','save');
    });
    let saved, exportedPath=path.join(tmp,'downloaded-world.json');
    await check('real JSON browser download equals the complete paused world',async()=>{
      saved=await snapshot();const wait=page.waitForEvent('download',{timeout:8000});await page.locator('#export').click();const download=await wait;
      await download.saveAs(exportedPath);assert.equal(await download.failure(),null);
      const bytes=await fs.readFile(exportedPath);assert.deepEqual(JSON.parse(bytes),saved);
      receipt.download={filename:download.suggestedFilename(),bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex'),tick:tickOf(saved)};
    });
    const chooseFile=async(filename)=>{const wait=page.waitForEvent('filechooser',{timeout:6000});await page.locator('#import').click();const chooser=await wait;await chooser.setFiles(filename);};
    await check('file chooser import cancelled without changing the world',async()=>{
      await clickCommand('#step','step');const before=await snapshot();await chooseFile(exportedPath);
      await page.locator('#confirm-dialog').waitFor({state:'visible'});await page.locator('#confirm-cancel').click();
      await page.locator('#confirm-dialog').waitFor({state:'hidden'});assert.deepEqual(await snapshot(),before);
    });
    await check('downloaded file imported through chooser restores both memories and journey exactly',async()=>{
      await chooseFile(exportedPath);await page.locator('#confirm-dialog').waitFor({state:'visible'});await clickCommand('#confirm-accept','import');
      assert.deepEqual(await snapshot(),saved);assert.equal((await current()).running,false);
      await page.reload();await page.locator('#status').filter({hasText:'世界已暂停'}).waitFor();assert.deepEqual(await snapshot(),saved);
    });
    await check('invalid JSON and invalid-schema imports leave state intact',async()=>{
      const invalid=path.join(tmp,'invalid.json');await fs.writeFile(invalid,'not json');await chooseFile(invalid);
      await page.waitForFunction(()=>document.querySelector('#notice').classList.contains('error'));assert.deepEqual(await snapshot(),saved);
      await fs.writeFile(invalid,JSON.stringify({version:99}));await chooseFile(invalid);await page.locator('#confirm-dialog').waitFor({state:'visible'});
      const response=page.waitForResponse(r=>r.url().endsWith('/api/command')&&r.status()===400);await page.locator('#confirm-accept').click();await response;
      await page.waitForFunction(()=>!document.querySelector('#play').disabled);assert.deepEqual(await snapshot(),saved);
    });
    await check('oversize file rejected before world replacement',async()=>{
      const big=path.join(tmp,'oversize.json');await fs.writeFile(big,' '.repeat(1000001));await chooseFile(big);
      await page.locator('#notice').filter({hasText:'不能超过 1 MB'}).waitFor();assert.deepEqual(await snapshot(),saved);
    });
    await check('manual load cancellation and acceptance preserve expected state',async()=>{
      await clickCommand('#step','step');const before=await snapshot();await page.locator('#load').click();await page.locator('#confirm-dialog').waitFor({state:'visible'});
      await page.locator('#confirm-cancel').click();assert.deepEqual(await snapshot(),before);
      await confirmCommand('#load','load');assert.deepEqual(await snapshot(),saved);
    });
    await check('ten play/pause cycles stop ticks, repeated single steps advance exactly once',async()=>{
      const speed=page.waitForResponse(r=>r.url().endsWith('/api/command')&&r.request().postDataJSON()?.action==='speed');await page.locator('#speed').selectOption('4');await speed;
      for(let i=0;i<10;i++){
        const old=(await current()).world.tick;await clickCommand('#play','play');
        await page.waitForFunction(old=>Number(document.querySelector('#clock').textContent.match(/第 (\d+) 步/)[1])>old,old);
        const paused=await clickCommand('#play','pause');await delay(180);assert.equal((await current()).world.tick,paused.world.tick);
        const step=await clickCommand('#step','step');assert.equal(step.world.tick,paused.world.tick+1);
      }
    });
    await check('pending-command controls reject duplicate pointer activation',async()=>{
      let seen=0;await page.route('**/api/command',async route=>{seen++;await delay(500);await route.continue();});
      const response=page.waitForResponse(r=>r.url().endsWith('/api/command'));await page.locator('#play').click();
      assert(await page.locator('#play').isDisabled());assert(await page.locator('#step').isDisabled());assert(await page.locator('#load').isDisabled());
      const box=await page.locator('#play').boundingBox();await page.mouse.click(box.x+box.width/2,box.y+box.height/2);
      await response;await page.waitForFunction(()=>!document.querySelector('#play').disabled);assert.equal(seen,1);
      await page.unroute('**/api/command');await clickCommand('#play','pause');
    });
    await check('eight-second command timeout releases controls and resumes state polling',async()=>{
      let held;await page.route('**/api/command',async route=>{held=route;});
      await page.locator('#play').click();await page.locator('#notice').filter({hasText:'请求超时'}).waitFor({timeout:10000});
      assert.equal(await page.locator('#play').isDisabled(),false);assert.equal((await current()).running,false);
      await held.abort().catch(()=>{});await page.unroute('**/api/command');await clickCommand('#step','step');
    });
    await check('new-world cancellation and confirmation keep manual save recoverable',async()=>{
      const before=await snapshot();await page.locator('#new').click();await page.locator('#confirm-dialog').waitFor({state:'visible'});await page.locator('#confirm-cancel').click();assert.deepEqual(await snapshot(),before);
      await confirmCommand('#new','new');assert.equal(tickOf(await snapshot()),0);assert.equal((await current()).running,false);
      await confirmCommand('#load','load');assert.deepEqual(await snapshot(),saved);
    });
    if(w2){
      await check('open a lived-in W2 sample and inspect both personal weather memories',async()=>{
        await chooseFile(path.join(review,'seed0-step480.json'));
        await clickCommand('#confirm-accept','import');
        const state=await current();
        assert.equal(state.world.tick,480);
        for(const actor of ['B','A']){
          await page.locator('#select-'+actor).click();
          assert.match(await page.locator('#context-memory').innerText(),/晴天/);
          for(const weather of ['sun','rain']){
            const row=page.locator('#context-memory tr').filter({hasText:weather==='sun'?'晴天':'雨天'});
            const memory=state.world.residents[actor].context_memory[weather];
            for(const [index,food] of ['p','q'].entries()){
              const cell=await row.locator('td').nth(index).innerText();
              assert.equal(cell,memory.counts[food]?`${memory.values[food].toFixed(2)}（${memory.counts[food]} 次）`:'未尝过');
            }
          }
        }
      });
      await check('weather controls isolate effect edits and preserve personal hints',async()=>{
        const oldSun=(await current()).world.resources.q.effect;
        await clickCommand('#weather-rain','weather');
        assert.match(await page.locator('#weather-title').innerText(),/雨天/);
        await page.locator('#q-effect').selectOption('-1');await clickCommand('#apply-q','environment');
        await clickCommand('#hint','hint');
        await clickCommand('#weather-sun','weather');
        assert.equal((await current()).world.resources.q.effect,oldSun);
        await clickCommand('#weather-rain','weather');assert.equal((await current()).world.resources.q.effect,-1);
        await clickCommand('#weather-auto','weather');
        const active=(await current()).world;
        assert.equal(active.change_at,active.tick+80);
        assert.equal(active.residents.A.hints.at(-1).source,'player');
      });
      await check('playable example restores known histories without giving the actors an action command',async()=>{
        await confirmCommand('#weather-example','example');
        const active=await current();
        assert.equal(active.running,false);
        assert.equal(active.world.tick,700);
        assert.equal(active.world.weather,'sun');
        assert(active.world.residents.A.brain.values.p>active.world.residents.B.brain.values.p);
      });
    }
    await check('desktop and narrow layout have no horizontal overflow; screenshot captured',async()=>{
      await page.screenshot({path:path.join(review,w2?'w2-desktop.png':'w1-desktop.png'),fullPage:true});
      await page.setViewportSize({width:390,height:844});await delay(600);
      assert(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth));
      assert(await page.locator('#hint').isVisible());assert(await page.locator('#import').isVisible());
      await page.screenshot({path:path.join(review,w2?'w2-narrow.png':'w1-narrow.png'),fullPage:true});
      await page.setViewportSize({width:1280,height:960});
    });
    assert.deepEqual(errors,[]);receipt.status='passed';receipt.page_errors=errors;receipt.control_cycles=10;
    receipt.not_claimed=['manual IAB download support (earlier tool blocked)','owner subjective acceptance','all-browser or mobile device compatibility'];
    receipt.user_saves_touched=false;
    receipt.source_sha256={};for(const f of ['living_world/web/app.js','living_world/web/index.html','living_world/web/style.css','living_world/src/server.py','living_world/tests/browser-check.cjs',...(w2?['living_world/src/context_world.py',serverFile]:[])])receipt.source_sha256[f]=createHash('sha256').update(await fs.readFile(path.join(root,f))).digest('hex');
  }catch(e){receipt.status='failed';receipt.error=e.stack;throw e;}
  finally{
    await fs.writeFile(path.join(review,'browser-verification.json'),JSON.stringify(receipt,null,2)+'\n');
    if(browser)await browser.close();
    if(server){const exited=new Promise(r=>server.once('exit',r));server.kill('SIGINT');await Promise.race([exited,delay(2000)]);if(server.exitCode===null)server.kill('SIGKILL');}
    await fs.rm(tmp,{recursive:true,force:true});
  }
})().catch(e=>{console.error(e.stack);process.exitCode=1});
