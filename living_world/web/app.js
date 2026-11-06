'use strict';
const $ = id => document.getElementById(id);
const names = {A:'阿禾',B:'小岚'}, places = {p:'青禾地',q:'紫穗地'};
const phases = {rest:'营地休息',outbound:'前往食物地',homebound:'返回营地'};
const hintStates = {pending:'待考虑',visited:'已亲自到访',expired:'已过时',superseded:'被新建议替代'};
const weatherNames = {sun:'晴天', rain:'雨天'};
let displayedWeather = null;
let state = null, selected = 'A', serial = Promise.resolve(), flashUntil = 0, busy = false, confirming = false;
function notice(text, error=false){$('notice').textContent=text;$('notice').classList.toggle('error',error);flashUntil=Date.now()+6000;}
function updateControls(){
  for(const id of ['play','step','speed','weather-sun','weather-rain','weather-auto','weather-example','p-open','p-effect','apply-p','q-open','q-effect','apply-q','hint-actor','hint-place','hint','slot','save','load','export','import','new'])
    $(id).disabled=busy||confirming||!state;
  if(state&&!busy&&!confirming){$('step').disabled=state.running;$('load').disabled=!state.slots.find(x=>x.slot===$('slot').value)?.exists;}
}
function request(path, body){
  const run=async()=>{
    const controller=new AbortController(), timer=setTimeout(()=>controller.abort(),8000);
    try{
      const response=await fetch(path,{signal:controller.signal,...(body?{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}:{})});
      const data=await response.json();if(!response.ok)throw new Error(data.error||'请求失败');return data;
    }catch(e){if(e.name==='AbortError')throw new Error('请求超时，操作结果尚未确认。请等待状态重新连接后检查，不要重复提交。');throw e;}
    finally{clearTimeout(timer);}
  };
  const result=serial.then(run,run);serial=result.catch(()=>{});return result;
}
async function command(body, message, sync=false){
  if(busy||confirming||!state)return false;
  busy=true;updateControls();
  try{state=await request('/api/command',body);render(sync);if(message)notice(message);return true;}
  catch(e){notice(e.message,true);return false;}
  finally{busy=false;updateControls();}
}
function confirmReplacement(text){
  if(busy||confirming||!state)return Promise.resolve(false);
  confirming=true;updateControls();$('confirm-text').textContent=text;
  const dialog=$('confirm-dialog');dialog.returnValue='';dialog.showModal();
  return new Promise(resolve=>{dialog.onclose=()=>{confirming=false;updateControls();resolve(dialog.returnValue==='confirm');};});
}
function item(tag, text, cls){const e=document.createElement(tag);e.textContent=text;if(cls)e.className=cls;return e;}
function renderWeather(w, resident){
  const enabled = Boolean(w.weather);
  $('weather-panel').hidden = !enabled;
  $('context-panel').hidden = !enabled;
  if(!enabled) return;
  document.title = '两个人的小世界 · W2';
  document.querySelector('.top .eyebrow').textContent = '生活实验 / W2';
  $('weather-title').textContent = '当前' + weatherNames[w.weather];
  $('weather-status').textContent = w.auto_weather ? `第 ${w.change_at} 步变天` : '你已固定天气';
  $('evidence-heading').textContent = weatherNames[w.weather] + '的亲历与听说';
  for(const mode of ['sun','rain','auto']){
    const selected = w.auto_weather ? mode==='auto' : mode===w.weather;
    $('weather-'+mode).setAttribute('aria-pressed',String(selected));
  }
  const rows = Object.entries(resident.context_memory).sort(([a],[b]) => b.localeCompare(a));
  $('context-memory').replaceChildren(...rows.map(([weather,memory]) => {
    const row = document.createElement('tr');
    row.append(item('th',weatherNames[weather]));
    for(const k of ['p','q']){
      const n = memory.counts[k];
      row.append(item('td',n ? `${memory.values[k].toFixed(2)}（${n} 次）` : '未尝过'));
    }
    return row;
  }));
}
function render(sync=false){
  const w=state.world,r=w.residents[selected];
  $('status').textContent=state.running?'生活进行中':'世界已暂停';$('clock').textContent=`第 ${w.tick} 步 · 种子 ${w.seed}`;
  $('play').textContent=state.running?'暂停':'开始生活';$('step').disabled=state.running;$('speed').value=state.speed;
  if(state.error)notice(state.error,true);
  else if(Date.now()>flashUntil){$('notice').textContent=state.running?'世界由本机服务持续推进。离开页面前可以暂停；每 20 步自动保存。':'可以先改变一处环境，或给一个人线索，再开始观察。';$('notice').classList.remove('error');}
  if(w.weather!==displayedWeather){sync=true;displayedWeather=w.weather;}
  renderWeather(w,r);
  if(sync)for(const k of ['p','q']){$(`${k}-open`).checked=w.resources[k].available;$(`${k}-effect`).value=w.resources[k].effect;}
  for(const slot of state.slots){const opt=$('slot').querySelector(`[value="${slot.slot}"]`);opt.textContent=`存档 ${slot.slot.slice(-1)}${slot.exists?' · 已保存':' · 空'}`;}
  $('load').disabled=!state.slots.find(x=>x.slot===$('slot').value)?.exists;
  for(const k of ['A','B'])$(`select-${k}`).setAttribute('aria-pressed',String(selected===k));
  $('person-name').textContent=names[selected];$('phase').textContent=phases[r.phase];$('reason').textContent=r.reason;
  for(const key of ['hunger','energy']){$(key).value=r[key];$(`${key}-text`).textContent=Math.round(r[key]);}
  $('beliefs').replaceChildren();
  for(const k of ['p','q']){
    const box=item('div','','belief');box.append(item('strong',places[k]));
    box.append(item('div',r.brain.counts[k]?`亲历 ${r.brain.counts[k]} 次 · 估计 ${r.brain.values[k].toFixed(2)}（−1 不适 / +1 有益）`:'尚无亲历 · 好坏未知'));
    const obs=r.observed[k];box.append(item('small',obs?`第 ${obs.tick} 步看到${obs.available?'有供应':'停供'}；此后可能改变`:'尚未近距离查看供应'));
    const msg=r.brain.inbox[k];box.append(item('small',msg?`${names[msg.source]}在第 ${msg.tick} 步的经历：${msg.claim===1?'有益':'不适'}${w.tick-msg.tick>160?'（消息已过时）':'（转述，非本人亲历）'}`:'没有同伴消息'));
    $('beliefs').append(box);
  }
  $('trust').textContent=`对同伴消息的可靠度估计：${Math.round(r.trust*100)}%。经自己的取食结果验证 ${r.brain.validation_count} 条；不用于判断对方动机。`;
  $('hints').replaceChildren();
  if(!r.hints.length)$('hints').append(item('p','还没有收到你的地点建议。'));
  for(const h of r.hints.slice(-3).reverse())$('hints').append(item('p',`第 ${h.tick} 步 · 你推荐${places[h.kind]} · ${hintStates[h.status]}`));
  $('memories').replaceChildren();
  for(const entry of r.history.slice(-8).reverse()){const li=item('li',entry.text);li.prepend(item('time',`第 ${entry.tick} 步`));$('memories').append(li);}
  if(!r.history.length)$('memories').append(item('li','还没有外出经历。'));
  $('events').replaceChildren();
  for(const e of w.events.slice(-12).reverse()){const li=item('li',e.text);li.prepend(item('time',`第 ${e.tick} 步`));$('events').append(li);}
  updateControls();draw();
}
const canvas=$('world'), ctx=canvas.getContext('2d');
function round(x,y,w,h,r,fill,stroke){ctx.beginPath();ctx.roundRect(x,y,w,h,r);if(fill){ctx.fillStyle=fill;ctx.fill();}if(stroke){ctx.strokeStyle=stroke;ctx.stroke();}}
function label(text,x,y,size=15,color='#62745c'){ctx.fillStyle=color;const displaySize=Math.max(size,(size>=17?13:size>=12?10:9)*1000/Math.max(320,canvas.clientWidth));ctx.font=`${displaySize}px -apple-system, "PingFang SC", sans-serif`;ctx.textAlign='center';ctx.fillText(text,x,y);}
function draw(){
  if(!state)return;
  const w=state.world;ctx.clearRect(0,0,1000,680);
  const gradient=ctx.createLinearGradient(0,0,1000,680);gradient.addColorStop(0,w.weather==='rain'?'#dbe9ed':'#e5ecda');gradient.addColorStop(1,w.weather==='rain'?'#c8dadd':'#d7e3cb');ctx.fillStyle=gradient;ctx.fillRect(0,0,1000,680);
  const xy=pos=>[90+pos[0]*82,65+pos[1]*77];
  // Quiet terrain marks are decorative; navigation uses the visible fixed grid.
  for(let x=0;x<11;x++)for(let y=0;y<8;y++){const [px,py]=xy([x,y]);ctx.fillStyle='#c5d2b9';ctx.beginPath();ctx.arc(px,py,1.5,0,Math.PI*2);ctx.fill();}
  ctx.strokeStyle='#eef1e2';ctx.lineWidth=32;ctx.lineCap='round';
  for(const [home,food] of [[[4,5],[2,2]],[[6,5],[8,2]]]){const [hx,hy]=xy(home),[fx,fy]=xy(food);ctx.beginPath();ctx.moveTo(hx,hy);ctx.lineTo(fx,hy);ctx.lineTo(fx,fy);ctx.stroke();}
  const [cx,cy]=xy([5,5]);round(cx-135,cy-47,270,105,32,'#e4d8ba');label('营 地',cx,cy+86,17,'#978d6d');
  for(const [k,pos] of Object.entries(w.map.homes)){const [x,y]=xy(pos);round(x-23,y-15,46,30,9,'#d3c39f');label(names[k],x,y+43,12,'#9e916e');}
  for(const pos of w.map.walls){const [x,y]=xy(pos);round(x-34,y-34,68,68,24,'#b5cabb','#adc2b0');round(x-25,y-26,50,50,19,'#c5d7c9');}
  label('浅池 · 不可通行',500,360,12,'#8b9e89');
  for(const [k,pos] of Object.entries(w.map.foods)){
    const [x,y]=xy(pos),resource=w.resources[k];round(x-59,y-53,118,104,28,resource.available?'#c6d6ad':'#d5d7c3');
    for(let i=0;i<5;i++){const px=x-34+(i%3)*32,py=y-23+Math.floor(i/3)*35;ctx.strokeStyle='#99af80';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(px,py+13);ctx.lineTo(px,py-8);ctx.stroke();ctx.fillStyle=resource.available?(k==='p'?'#859f61':'#a58a9f'):'#b3b69b';ctx.beginPath();ctx.ellipse(px-5,py-1,8,4,-.5,0,Math.PI*2);ctx.ellipse(px+5,py-7,8,4,.5,0,Math.PI*2);ctx.fill();}
    label(places[k],x,y-75,20,'#4f6747');label(`${resource.available?'开放':'停供'} · ${resource.effect===1?'有益':'食后不适'}`,x,y+78,13,'#7d8a6c');
  }
  for(const [k,r] of Object.entries(w.residents)){
    const [x0,y]=xy(r.pos),other=w.residents[k==='A'?'B':'A'];const x=x0+(r.pos[0]===other.pos[0]&&r.pos[1]===other.pos[1]?(k==='A'?-13:13):0);
    if(r.target){const target=r.phase==='homebound'?w.map.homes[k]:w.map.foods[r.target];const [tx,ty]=xy(target);ctx.strokeStyle=k==='A'?'#b68b5955':'#6f94a355';ctx.lineWidth=2;ctx.setLineDash([5,8]);ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(tx,ty);ctx.stroke();ctx.setLineDash([]);}
    ctx.fillStyle='#68745222';ctx.beginPath();ctx.ellipse(x,y+15,22,9,0,0,Math.PI*2);ctx.fill();
    if(selected===k){ctx.strokeStyle='#fffdf4';ctx.lineWidth=4;ctx.beginPath();ctx.arc(x,y-4,23,0,Math.PI*2);ctx.stroke();}
    ctx.fillStyle=k==='A'?'#c98a52':'#668fa0';ctx.beginPath();ctx.arc(x,y-4,17,0,Math.PI*2);ctx.fill();label(k,x,y+1,14,'#fffaf0');
    round(x-35,y-58,70,25,9,'#fafbf0e8');label(names[k],x,y-41,12,'#53664c');
  }
  if(w.weather)label(weatherNames[w.weather],85,48,19,'#526a65');
  label('圆点为角色位置 · 虚线为目标方向，不代表实际路径',500,654,11,'#8c9c7e');
}
$('play').onclick=()=>command({action:state?.running?'pause':'play'});
$('step').onclick=()=>command({action:'step'});
$('speed').onchange=()=>command({action:'speed',value:Number($('speed').value)});
$('weather-example').onclick=async()=>{
  if(await confirmReplacement('载入晴天第 700 步的双人示例。当前世界会保存为恢复副本。')){
    await command({action:'example'},'示例已暂停。点击开始，观察阿禾和小岚接下来分别去哪里。',true);
  }
};
for(const mode of ['sun','rain','auto'])$('weather-'+mode).onclick=()=>command({action:'weather',mode},'天气设置已更新。',true);
for(const k of ['p','q'])$(`apply-${k}`).onclick=()=>command({action:'environment',weather:state?.world.weather,kind:k,effect:Number($(`${k}-effect`).value),available:$(`${k}-open`).checked},`${places[k]}已改变。角色需要靠近或取食后才会发现。`,true);
$('hint').onclick=()=>command({action:'hint',actor:$('hint-actor').value,kind:$('hint-place').value},'线索只交给了选定角色；不会立即中断正在进行的行动。');
for(const k of ['A','B'])$(`select-${k}`).onclick=()=>{selected=k;if(state)render();};
$('slot').onchange=()=>{if(state)render();};
$('save').onclick=()=>command({action:'save',slot:$('slot').value},'已保存当前世界，包括双方记忆和途中行动。');
$('load').onclick=async()=>{if(await confirmReplacement('读取会替换当前世界并暂停。替换前的状态会另存为恢复副本。'))command({action:'load',slot:$('slot').value},'已恢复存档，世界暂停。点击“开始生活”继续。',true);};
$('new').onclick=async()=>{if(await confirmReplacement('开始新的世界？现有手动存档会保留，当前状态会保存为恢复副本。'))command({action:'new',seed:42},'新世界已建立。',true);};
$('export').onclick=async()=>{try{const data=await request('/api/export');const url=URL.createObjectURL(new Blob([JSON.stringify(data,null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download=`world-w${data.version}-step-${data.active?.tick ?? data.tick}.json`;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),60000);notice('已请求下载存档，请在浏览器下载列表中确认文件。');}catch(e){notice(e.message,true);}};
$('import').onclick=()=>$('file').click();
$('file').onchange=async()=>{const f=$('file').files[0];if(!f)return;try{if(f.size>1000000)throw new Error('存档不能超过 1 MB');const world=JSON.parse(await f.text());if(await confirmReplacement('导入会替换当前世界并暂停。当前状态会另存为恢复副本。'))await command({action:'import',world},'存档已导入；世界保持暂停。',true);}catch(e){notice(e.message,true);}finally{$('file').value='';}};
async function poll(){if(busy||confirming){setTimeout(poll,500);return;}try{const first=!state;state=await request('/api/state');render(first);if(first)notice(state.running?'已连接正在运行的世界；可随时暂停。':state.world.tick?'已连接保留的世界，当前暂停。点击“开始生活”继续。':'两个角色还没有亲历。准备好后，点击“开始生活”。');}catch(e){notice(`连接中断：${e.message}。请检查本机启动窗口。`,true);}setTimeout(poll,500);}
updateControls();poll();
