// Independent W3 server and real W2 fixture; never attaches to the owner's W2.
const path=require('node:path'),fs=require('node:fs/promises'),os=require('node:os');
const assert=require('node:assert/strict'),{spawn,execFileSync}=require('node:child_process');
const {createHash}=require('node:crypto');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE_PATH||'playwright');
const root=path.resolve(__dirname,'../..'),review=path.join(root,'docs/sim/living-world/w3/review');
const delay=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
  const tmp=await fs.mkdtemp(path.join(os.tmpdir(),'w3-browser-')),checks=[],errors=[];
  const receipt={verified_at:new Date().toISOString(),status:'running',checks,engine:'isolated Playwright Chromium headless',user_saves_touched:false,owner_accepted:false};
  let server,browser,page,stderr='';
  const check=async(name,fn)=>{await fn();checks.push(name);console.log('PASS '+name);};
  try{
    await fs.mkdir(review,{recursive:true});
    const fixture=path.join(tmp,'w2-origin.json');
    await fs.copyFile(path.join(root,'docs/sim/living-world/w2/review/step700-example.json'),fixture);
    const snapshot=JSON.parse(await fs.readFile(fixture,'utf8'));
    // Match the bytes a browser sends (JSON.stringify normalizes 100.0 to 100).
    await fs.writeFile(fixture,JSON.stringify(snapshot));
    const expected=JSON.parse(execFileSync(process.env.PYTHON||'python3',['-c','import sys,json; sys.path.insert(0,"living_world/src"); from fork_study import compare; s=json.load(open(sys.argv[1])); print(json.dumps(compare(s,"A","q")))',fixture],{cwd:root}));
    server=spawn(process.env.PYTHON||'python3',['living_world/src/fork_server.py','--port','0'],{cwd:root});
    server.stderr.on('data',d=>stderr+=d);
    const base=await new Promise((resolve,reject)=>{const timeout=setTimeout(()=>reject(Error('server startup timeout: '+stderr)),8000);server.stdout.on('data',d=>{const m=String(d).match(/http:\/\/127\.0\.0\.1:\d+/);if(m){clearTimeout(timeout);resolve(m[0]);}});server.once('error',reject);server.once('exit',()=>{clearTimeout(timeout);reject(Error('server exited: '+stderr));});});
    browser=await chromium.launch({headless:true});receipt.browser_version=browser.version();
    page=await browser.newPage({viewport:{width:1420,height:1100},deviceScaleFactor:1});page.setDefaultTimeout(8000);page.on('pageerror',e=>errors.push(e.message));
    await page.goto(base);await page.waitForFunction(()=>!document.querySelector('#load-example').disabled);
    const loadStep700=async()=>{await page.locator('#example').selectOption('step700');const pending=page.waitForResponse(r=>r.url()===base+'/api/compare');await page.locator('#load-example').click();assert((await pending).ok());await page.waitForFunction(()=>!document.querySelector('#compare').disabled);};
    await check('default fixed-grid example fingerprint agrees with the archived study',async()=>{
      const archive=JSON.parse(await fs.readFile(path.join(review,'example-info.json'),'utf8'));
      await page.locator('#example').selectOption('study');const pending=page.waitForResponse(r=>r.url()===base+'/api/compare');await page.locator('#load-example').click();const response=await pending;assert(response.ok());const r=await response.json();await page.waitForFunction(()=>!document.querySelector('#compare').disabled);
      assert.equal(r.origin_hash,archive.origin_hash);assert.equal(r.actor,archive.actor);assert.equal(r.kind,archive.kind);assert.match(await page.locator('#provenance').textContent(),new RegExp(archive.origin_hash));receipt.study_example_sha256=r.origin_hash;
    });
    await check('zero-effect suggestion reports zero post-hint differences rather than implying persistence',async()=>{
      await page.locator('#actor').selectOption('A');await page.locator('#kind').selectOption('q');const pending=page.waitForResponse(r=>r.url()===base+'/api/compare');await page.locator('#compare').click();const response=await pending;assert(response.ok());const r=await response.json();await page.waitForFunction(()=>!document.querySelector('#compare').disabled);
      assert.equal(r.people.A.steps,0);assert.equal(r.people.B.steps,0);assert.match(await page.locator('#hint-end').innerText(),/阿禾的行为不同 0 步，同伴小岚不同 0 步/);assert.doesNotMatch(await page.locator('#hint-end').innerText(),/其后仍有差异/);
    });
    await check('built-in W2 origin renders equal clocks and complete paired metrics',async()=>{
      await loadStep700();assert.match(await page.locator('#source-info').innerText(),/第 700 步/);assert.match(await page.locator('#absolute').innerText(),/第 700 步/);
      assert.match(await page.locator('#provenance').textContent(),new RegExp(expected.origin_hash));assert.equal(await page.locator('#metrics tr').count(),3);
      assert.equal(await page.locator('#control-status').innerText(),await page.locator('#hinted-status').innerText());
      for(const actor of ['A','B']){const row=page.locator('#metrics tr').nth(actor==='A'?1:2);const values=await row.locator('td').allTextContents(),m=expected.people[actor];assert.equal(values[1],m.first===null?'未出现':'+'+m.first);assert.equal(values[2],m.last===null?'未出现':'+'+m.last);assert.equal(values[3],`${m.steps} / 240`);assert.equal(values[6],String(m.after_hint));assert.equal(values[7],String(m.choice_splits));}
    });
    const upload=async(filename)=>{const chooser=page.waitForEvent('filechooser');await page.locator('#import').click();await(await chooser).setFiles(filename);};
    await check('real JSON file chooser import produces the same original fork',async()=>{
      const pending=page.waitForResponse(r=>r.url()===base+'/api/compare');await upload(fixture);assert((await pending).ok());await page.waitForFunction(()=>!document.querySelector('#compare').disabled);
      assert.match(await page.locator('#source-info').innerText(),/导入：w2-origin.json/);assert.match(await page.locator('#provenance').textContent(),new RegExp(expected.origin_hash));
    });
    await check('invalid JSON, wrong schema, malformed W2 and oversize files preserve visible comparison',async()=>{
      const before=await page.locator('#provenance').textContent();
      for(const [contents,text] of [['not JSON','不是有效 JSON'],[JSON.stringify({version:1}),'完整 W2 v2'],[JSON.stringify({version:2}),'存档或请求无效'],[' '.repeat(1000001),'不能超过 1 MB']]){
        const file=path.join(tmp,'invalid.json');await fs.writeFile(file,contents);await upload(file);await page.locator('#notice.error').filter({hasText:text}).waitFor();assert.equal(await page.locator('#provenance').textContent(),before);assert.equal(await page.locator('#play').isEnabled(),true);
      }
    });
    await check('timeline scrubs both maps at the same absolute step and key jumps match data',async()=>{
      for(const n of [0,137,240,13]){await page.locator('#timeline').fill(String(n));assert.match(await page.locator('#clock').innerText(),new RegExp('\\+'+n+' 步'));assert.match(await page.locator('#absolute').innerText(),new RegExp('第 '+(700+n)+' 步'));
        const f=expected.frames[n];for(const side of ['control','hinted']){const rows=page.locator('#'+side+'-status .person');for(const [index,actor] of ['A','B'].entries())assert.match(await rows.nth(index).innerText(),new RegExp('位置 \\('+f[side][actor].pos.join(', ')+'\\)'));}}
      for(const n of [expected.people.A.first,expected.message_first,expected.hint_end,expected.hint_end+1,240].filter(x=>x!==null)){
        await page.locator(`#jumps button[data-offset="${n}"]`).first().click();assert.equal(await page.locator('#timeline').inputValue(),String(n));
      }
      await page.locator(`#jumps button[data-offset="${expected.message_first}"]`).first().click();const f=expected.frames[expected.message_first];for(const side of ['control','hinted'])assert.deepEqual(await page.locator('#'+side+'-deliveries li').allTextContents(),f.deliveries[side]);
      assert.match(await page.locator('#relay').innerText(),/未满足传播证据/);
    });
    await check('play/pause, single-step and the +240 observation boundary are bounded',async()=>{
      await page.locator('#timeline').fill('0');await page.locator('#speed').selectOption('12');await page.locator('#play').click();await page.waitForFunction(()=>Number(document.querySelector('#timeline').value)>2);await page.locator('#play').click();
      const paused=Number(await page.locator('#timeline').inputValue());await delay(160);assert.equal(Number(await page.locator('#timeline').inputValue()),paused);await page.locator('#next').click();assert.equal(Number(await page.locator('#timeline').inputValue()),paused+1);await page.locator('#back').click();assert.equal(Number(await page.locator('#timeline').inputValue()),paused);
      await page.locator('#timeline').fill('239');await page.locator('#play').click();await page.waitForFunction(()=>document.querySelector('#timeline').value==='240'&&document.querySelector('#play').textContent==='播放');assert(await page.locator('#next').isDisabled());
    });
    await check('recipient/place changes only apply to a new fork from the original',async()=>{
      await page.locator('#actor').selectOption('B');await page.locator('#kind').selectOption('p');const pending=page.waitForResponse(r=>r.url()===base+'/api/compare');await page.locator('#compare').click();const response=await pending;assert(response.ok());const actual=await response.json();await page.waitForFunction(()=>!document.querySelector('#compare').disabled);assert.equal(actual.actor,'B');assert.equal(actual.kind,'p');assert.equal(actual.start,700);assert.equal(actual.origin_hash,expected.origin_hash);assert.match(await page.locator('#hint-summary').innerText(),/小岚去青禾地/);assert.equal(await page.locator('#timeline').inputValue(),'0');
      await loadStep700();
    });
    await check('pending calculation blocks duplicates, and failure releases controls with old result retained',async()=>{
      let seen=0;await page.route('**/api/compare',async route=>{seen++;await delay(250);await route.fulfill({status:400,contentType:'application/json',body:JSON.stringify({error:'测试失败恢复'})});});
      const before=await page.locator('#provenance').textContent();await page.locator('#compare').click();assert(await page.locator('#compare').isDisabled());assert(await page.locator('#import').isDisabled());await page.locator('#notice.error').filter({hasText:'测试失败恢复'}).waitFor();assert.equal(await page.locator('#compare').isEnabled(),true);assert.equal(await page.locator('#provenance').textContent(),before);assert.equal(seen,1);await page.unroute('**/api/compare');
    });
    await check('HTTP rejects cross-site, wrong host, invalid inputs and excess body before comparing',async()=>{
      const body={snapshot,actor:'A',kind:'q'};
      for(const headers of [{Origin:'https://example.com'},{Host:'untrusted.example'},{'Sec-Fetch-Site':'cross-site'}])assert.equal((await page.request.post(base+'/api/compare',{headers,data:body})).status(),403);
      assert.equal((await page.request.post(base+'/api/compare',{data:{...body,actor:'C'}})).status(),400);
      assert.equal((await page.request.post(base+'/api/compare',{data:{...body,horizon:999999}})).status(),400);
      assert.equal((await page.request.post(base+'/api/compare',{data:{snapshot:{version:2},actor:'A',kind:'q'}})).status(),400);
      // Send the oversized Content-Length without a body: rejection must happen
      // before reading it. Sending a whole body races the intended early close.
      const status=await new Promise((resolve,reject)=>{const req=require('node:http').request(base+'/api/compare',{method:'POST',headers:{'Content-Type':'application/json','Content-Length':'1050001'}},res=>{res.resume();resolve(res.statusCode);});req.on('error',reject);req.end();});assert.equal(status,400);
      assert.equal((await page.request.get(base+'/../src/context_world.py')).status(),404);
    });
    await check('reversal preset shows report divergence before the peer choice and silent replay evidence',async()=>{
      await page.locator('#example').selectOption('reversal');const pending=page.waitForResponse(r=>r.url()===base+'/api/compare');await page.locator('#load-example').click();const response=await pending;assert(response.ok());const r=await response.json();await page.waitForFunction(()=>!document.querySelector('#compare').disabled);
      assert.equal(r.start,480);assert.equal(r.actor,'A');assert.equal(r.kind,'q');assert.equal(r.message_first,54);assert.equal(r.people.B.first,66);assert.equal(r.relay,true);assert.equal(r.silent.people.B.steps,0);assert.match(await page.locator('#source-info').innerText(),/效果互换/);assert.match(await page.locator('#relay').innerText(),/有传播证据/);
      const archive=JSON.parse(await fs.readFile(path.join(review,'reversal.json'),'utf8'));assert.equal(r.origin_hash,archive.first_relay.origin_hash);assert.match(await page.locator('#provenance').textContent(),new RegExp(archive.first_relay.origin_hash));
      await page.locator('#jumps button[data-offset="54"]').click();assert.equal(await page.locator('#timeline').inputValue(),'54');assert.notDeepEqual(await page.locator('#control-deliveries li').allTextContents(),await page.locator('#hinted-deliveries li').allTextContents());
      await page.locator('#jumps button[data-offset="66"]').click();assert.equal(await page.locator('#timeline').inputValue(),'66');assert.match(await page.locator('#control-status .person').nth(1).innerText(),/两边行为不同/);assert.match(await page.locator('#hinted-status .person').nth(1).innerText(),/两边行为不同/);await page.screenshot({path:path.join(review,'w3-relay.png'),fullPage:true});
      receipt.relay_example={start:r.start,actor:r.actor,kind:r.kind,origin_hash:r.origin_hash,message_first:r.message_first,peer_first:r.people.B.first,silent_peer_steps:r.silent.people.B.steps};
    });
    await check('desktop and narrow maps remain usable with no horizontal overflow',async()=>{
      await loadStep700();await page.locator(`#jumps button[data-offset="${expected.people.A.first}"]`).first().click();await page.screenshot({path:path.join(review,'w3-desktop.png'),fullPage:true});
      assert(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth));await page.setViewportSize({width:390,height:844});assert(await page.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth));assert(await page.locator('#play').isVisible());assert(await page.locator('#import').isVisible());await page.screenshot({path:path.join(review,'w3-narrow.png'),fullPage:true});
    });
    assert.deepEqual(errors,[]);receipt.status='passed';receipt.page_errors=errors;receipt.origin_sha256=expected.origin_hash;
    receipt.not_claimed=['owner subjective acceptance','animated character quality','physical device acceptance','all-browser compatibility'];
    receipt.source_sha256={};for(const file of ['living_world/src/fork_server.py','living_world/src/fork_study.py','living_world/web/w3/index.html','living_world/web/w3/style.css','living_world/web/w3/app.js','living_world/tests/browser-w3.cjs'])receipt.source_sha256[file]=createHash('sha256').update(await fs.readFile(path.join(root,file))).digest('hex');
  }catch(e){receipt.status='failed';receipt.error=e.stack;throw e;}
  finally{
    await fs.writeFile(path.join(review,'browser-verification.json'),JSON.stringify(receipt,null,2)+'\n');if(browser)await browser.close();
    if(server){const exited=new Promise(r=>server.once('exit',r));server.kill('SIGINT');await Promise.race([exited,delay(2000)]);if(server.exitCode===null)server.kill('SIGKILL');}
    await fs.rm(tmp,{recursive:true,force:true});
  }
})().catch(e=>{console.error(e.stack);process.exitCode=1;});
