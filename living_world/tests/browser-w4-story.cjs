// Isolated W4 experience QA; no owner world or save files are opened.
const path=require('node:path'),fs=require('node:fs/promises'),os=require('node:os');
const assert=require('node:assert/strict'),{spawn}=require('node:child_process');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE_PATH||'playwright');
const root=path.resolve(__dirname,'../..'),review=path.join(root,'docs/sim/living-world/w4-story/review');
const delay=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 const tmp=await fs.mkdtemp(path.join(os.tmpdir(),'w4-story-')),checks=[],errors=[];
 const receipt={verified_at:new Date().toISOString(),status:'running',checks,engine:'isolated Playwright Chromium headless',user_saves_touched:false,owner_accepted:false};
 let server,browser,page,stderr='';
 const check=async(name,fn)=>{await fn();checks.push(name);console.log('PASS '+name);};
 try{
  await fs.mkdir(review,{recursive:true});
  server=spawn(process.env.PYTHON||'python3',['living_world/src/fork_server.py','--port','0'],{cwd:root});server.stderr.on('data',d=>stderr+=d);
  const base=await new Promise((resolve,reject)=>{const timeout=setTimeout(()=>reject(Error('server startup timeout: '+stderr)),8000);server.stdout.on('data',d=>{const m=String(d).match(/http:\/\/127\.0\.0\.1:\d+/);if(m){clearTimeout(timeout);resolve(m[0]);}});server.once('error',reject);server.once('exit',()=>{clearTimeout(timeout);reject(Error('server exited: '+stderr));});});
  browser=await chromium.launch({headless:true});receipt.browser_version=browser.version();
  page=await browser.newPage({viewport:{width:1420,height:1200},deviceScaleFactor:1});page.setDefaultTimeout(8000);page.on('pageerror',e=>errors.push(e.message));
  let requests=0;page.on('request',r=>{if(r.url().endsWith('/api/compare'))requests++;});
  await page.goto(base);await page.waitForFunction(()=>!document.querySelector('#compare').disabled);
  const submit=async()=>{const pending=page.waitForResponse(r=>r.url()===base+'/api/compare');await page.locator('#compare').click();const response=await pending;assert(response.ok());const data=await response.json();await page.waitForFunction(()=>!document.querySelector('#compare').disabled);return data;};
  const prepare=async(kind)=>{await page.locator('#example').selectOption(kind);await page.locator('#load-example').click();await page.waitForFunction(()=>!document.querySelector('#compare').disabled);};
  const stage=i=>page.locator(`#story-steps [data-stage="${i}"]`);
  await check('initial preparation sends no hint; maps equal and playback waits for player',async()=>{
   assert.equal(requests,0);assert(await page.locator('#play').isDisabled());assert.match(await page.locator('#story-title').innerText(),/先把一个地点/);assert.equal(await page.locator('#control-status').innerText(),await page.locator('#hinted-status').innerText());assert(await page.locator('#full-results').isHidden());
  });
  const result=await submit();
  await check('explicit hint starts at zero; future outcome and metrics are not narrated',async()=>{
   assert.deepEqual(result.story.nodes.map(n=>n.offset),[0,56,59,66]);assert.match(await page.locator('#story-title').innerText(),/你告诉阿禾/);
   assert.equal(await stage(3).locator('strong').innerText(),'同伴的选择');assert.equal(await page.locator('#metrics').innerText(),'');assert.doesNotMatch(await page.locator('.story-focus').innerText(),/改去|536|去掉/);
   await fs.writeFile(path.join(review,'example-story.json'),JSON.stringify({origin_hash:result.origin_hash,start:result.start,story:result.story},null,2)+'\n');
  });
  await check('guided playback stops at actual +56 experience, +59 delivery, +66 choice',async()=>{
   await page.locator('#speed').selectOption('12');
   for(const [step,text] of [[56,'亲自尝过了'],[59,'告诉了小岚'],[66,'小岚改去紫穗地了']]){
    await page.locator('#story-next').click();await page.waitForFunction(n=>document.querySelector('#timeline').value===String(n)&&document.querySelector('#play').textContent==='播放',step);await delay(90);assert.equal(await page.locator('#timeline').inputValue(),String(step));assert.match(await page.locator('#story-title').innerText(),new RegExp(text));
   }
   assert.match(await page.locator('#story-evidence').innerText(),/只去掉阿禾这条亲历报告，他会选青禾地/);
   assert.match(await page.locator('#story-text').innerText(),/同一步，无建议世界的小岚仍选青禾地/);
   assert.match(await page.locator('#hinted-map').getAttribute('aria-label'),/作出选择/);
   await page.screenshot({path:path.join(review,'choice-desktop.png'),fullPage:true});
  });
  await check('cards rewind exact events; delivery is distinct from first differing message',async()=>{
   await stage(2).click();assert.equal(await page.locator('#timeline').inputValue(),'59');assert.match(await page.locator('#story-evidence').innerText(),/刚才那条亲历/);assert.match(await page.locator('#hinted-map').getAttribute('aria-label'),/亲历送达/);
   await stage(1).click();assert.equal(await page.locator('#timeline').inputValue(),'56');assert.equal(await stage(3).locator('strong').innerText(),'同伴的选择');
   await stage(0).click();assert.equal(await page.locator('#timeline').inputValue(),'0');assert.doesNotMatch(await page.locator('.story-focus').innerText(),/改去|只去掉/);
  });
  await check('play pause single-step guide-speed changes and end boundary remain bounded',async()=>{
   await page.locator('#story-next').click();await page.waitForFunction(()=>Number(document.querySelector('#timeline').value)>2);await page.locator('#speed').selectOption('4');await page.locator('#story-next').click();const paused=await page.locator('#timeline').inputValue();await delay(180);assert.equal(await page.locator('#timeline').inputValue(),paused);
   await page.locator('#next').click();assert.equal(Number(await page.locator('#timeline').inputValue()),Number(paused)+1);await page.locator('#back').click();assert.equal(await page.locator('#timeline').inputValue(),paused);
   await page.locator('#timeline').fill('239');await page.locator('#play').click();await page.waitForFunction(()=>document.querySelector('#timeline').value==='240'&&document.querySelector('#play').textContent==='播放');assert(await page.locator('#next').isDisabled());assert(await page.locator('#full-results').isVisible());await page.locator('#full-results summary').click();assert.equal(await page.locator('#metrics tr').count(),3);
   await page.locator('#timeline').fill('65');assert(await page.locator('#full-results').isHidden());assert.equal(await page.locator('#metrics').innerText(),'');assert.equal(await stage(3).locator('strong').innerText(),'同伴的选择');
  });
  await check('pending selectors never relabel old intervention and apply only on success',async()=>{
   await page.locator('#actor').selectOption('B');await page.locator('#kind').selectOption('p');assert.match(await page.locator('#notice').innerText(),/待应用.*阿禾去紫穗地/);assert.match(await page.locator('#hint-summary').innerText(),/阿禾去紫穗地/);
   const next=await submit();assert.equal(next.actor,'B');assert.equal(next.kind,'p');assert.equal(next.origin_hash,result.origin_hash);assert.match(await page.locator('#story-title').innerText(),/你告诉小岚/);assert.equal(await page.locator('#timeline').inputValue(),'0');
  });
  await check('calculation and example failures retain current story and restore controls',async()=>{
   const before=await page.locator('#story-title').innerText();let seen=0;
   await page.route('**/api/compare',async route=>{seen++;await delay(250);await route.fulfill({status:400,contentType:'application/json',body:JSON.stringify({error:'测试失败恢复'})});});
   await page.locator('#compare').click();assert(await page.locator('#compare').isDisabled());assert(await page.locator('#import').isDisabled());await page.locator('#notice.error').waitFor();assert.equal(await page.locator('#story-title').innerText(),before);assert.equal(seen,1);assert(await page.locator('#compare').isEnabled());await page.unroute('**/api/compare');
   await page.route('**/api/example?*',r=>r.fulfill({status:400,contentType:'application/json',body:JSON.stringify({error:'测试起点失败'})}));await page.locator('#load-example').click();await page.locator('#notice.error').filter({hasText:'测试起点失败'}).waitFor();assert.equal(await page.locator('#story-title').innerText(),before);await page.unroute('**/api/example?*');
  });
  await check('zero-effect example does not claim a causal intervention or forced success',async()=>{
   await prepare('study');await page.locator('#actor').selectOption('A');await page.locator('#kind').selectOption('q');const noEffect=await submit();assert.equal(noEffect.people.A.steps,0);assert.equal(noEffect.people.B.steps,0);assert.equal(noEffect.story.supported,false);
   await stage(1).click();assert.match(await page.locator('#story-evidence').innerText(),/也在同一步得到相同亲历/);await stage(3).click();assert.doesNotMatch(await page.locator('#story-title').innerText(),/改去/);assert.doesNotMatch(await page.locator('#story-evidence').innerText(),/这条报告改变了本次选择/);
  });
  const upload=async(content)=>{const fixture=path.join(tmp,'import.json');await fs.writeFile(fixture,content);const chooser=page.waitForEvent('filechooser');await page.locator('#import').click();await(await chooser).setFiles(fixture);};
  await check('valid W2 import works; invalid oversized and malformed saves retain story',async()=>{
   const saved=await fs.readFile(path.join(root,'docs/sim/living-world/w2/review/step700-example.json'),'utf8');await upload(saved);await page.waitForFunction(()=>document.querySelector('#source-info').textContent.includes('导入：'));assert.match(await page.locator('#absolute').innerText(),/第 700 步/);
   const before=await page.locator('#provenance').textContent();
   for(const content of ['not json',JSON.stringify({version:1}),JSON.stringify({version:2}),' '.repeat(1000001)]){await upload(content);await page.locator('#notice.error').waitFor();assert.equal(await page.locator('#provenance').textContent(),before);assert(await page.locator('#play').isEnabled());}
  });
  await check('expired hint ends at missing experience without inventing downstream events',async()=>{
   const saved=JSON.parse(await fs.readFile(path.join(root,'docs/sim/living-world/w2/review/step700-example.json'),'utf8'));
   // Use the real server validation path; disable supply and defer departure within valid bounds.
   for(const r of Object.values(saved.active.resources))r.available=false;
   for(const p of Object.values(saved.active.residents)){p.pos=p.name==='A'?[4,5]:[6,5];p.phase='rest';p.target=null;p.next_departure=saved.active.tick+100;p.hunger=0;p.observed={p:{available:false,tick:saved.active.tick},q:{available:false,tick:saved.active.tick}};}
   const pending=page.waitForResponse(r=>r.url()===base+'/api/compare');await upload(JSON.stringify(saved));const response=await pending;assert(response.ok(),await response.text());const ended=await response.json();assert.equal(ended.story.supported,false);await page.waitForFunction(()=>!document.querySelector('#compare').disabled);await page.locator('#timeline').fill('240');assert.match(await page.locator('#story-title').innerText(),/停在这里/);assert.match(await page.locator('#story-text').innerText(),/到期|没有食物|没有.*亲历/);
  });
  await check('HTTP rejects cross-site wrong-host invalid payload and excessive body',async()=>{
   const snapshot=JSON.parse(await fs.readFile(path.join(root,'docs/sim/living-world/w3/review/reversal-example.json'),'utf8')),data={snapshot,actor:'A',kind:'q'};
   for(const headers of [{Origin:'https://example.com'},{Host:'untrusted.example'},{'Sec-Fetch-Site':'cross-site'}])assert.equal((await page.request.post(base+'/api/compare',{headers,data})).status(),403);
   assert.equal((await page.request.post(base+'/api/compare',{data:{...data,actor:'C'}})).status(),400);
   assert.equal((await page.request.post(base+'/api/compare',{data:{...data,horizon:9999}})).status(),400);
   // Header-only probe verifies rejection before upload; avoids client EPIPE when the server closes early.
   const oversized=await new Promise((resolve,reject)=>{const req=require('node:http').request(base+'/api/compare',{method:'POST',headers:{'Content-Type':'application/json','Content-Length':'1050001'}},res=>{res.resume();res.on('end',()=>resolve(res.statusCode));});req.on('error',reject);req.end();});assert.equal(oversized,400);
  });
  await check('390px layout has no horizontal overflow and all four steps remain reachable',async()=>{
   await prepare('reversal');await submit();await stage(3).click();await page.setViewportSize({width:390,height:844});assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));assert.equal(await page.locator('#story-steps button').count(),4);await page.screenshot({path:path.join(review,'choice-mobile.png'),fullPage:true});await stage(0).click();assert.match(await page.locator('#story-title').innerText(),/你告诉阿禾/);
  });
  await check('no uncaught browser exceptions',async()=>assert.deepEqual(errors,[]));receipt.status='passed';
 }catch(e){receipt.status='failed';receipt.error=e.stack;process.exitCode=1;console.error(e);}finally{
  if(browser)await browser.close();if(server)server.kill('SIGTERM');await fs.rm(tmp,{recursive:true,force:true});receipt.page_errors=errors;await fs.writeFile(path.join(review,'browser-verification.json'),JSON.stringify(receipt,null,2)+'\n');
 }
})();
