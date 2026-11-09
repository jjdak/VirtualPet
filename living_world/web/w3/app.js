'use strict';
const $=id=>document.getElementById(id);
const names={A:'阿禾',B:'小岚'}, places={p:'青禾地',q:'紫穗地'}, phases={rest:'营地休息',outbound:'前往食物地',homebound:'返回营地'}, weather={sun:'晴天',rain:'雨天'};
const foods={p:[2,2],q:[8,2]},homes={A:[4,5],B:[6,5]},colors={A:'#bd7d4b',B:'#5c879a'};
let snapshot=null,result=null,offset=0,busy=false,timer=null,sourceLabel='';
const at=n=>n===null||n===undefined?'未出现':`+${n}`;
const el=(tag,text,cls)=>{const node=document.createElement(tag);node.textContent=text;if(cls)node.className=cls;return node;};
function notice(text,error=false){$('notice').textContent=text;$('notice').classList.toggle('error',error);}
function stop(){if(timer)clearInterval(timer);timer=null;$('play').textContent='播放';}
function controls(){
  for(const id of ['example','load-example','import','actor','kind','compare'])$(id).disabled=busy||(!snapshot&&['compare','actor','kind'].includes(id));
  for(const id of ['back','play','next','speed','timeline'])$(id).disabled=busy||!result;
  $('back').disabled=busy||!result||offset===0;$('next').disabled=busy||!result||offset===result.horizon;
  for(const button of $('jumps').querySelectorAll('button'))button.disabled=busy;
}
async function request(path,body){
  const controller=new AbortController(), timeout=setTimeout(()=>controller.abort(),15000);
  try{
    const response=await fetch(path,{signal:controller.signal,...(body?{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}:{})});
    const value=await response.json();if(!response.ok)throw Error(value.error||'本机服务请求失败');return value;
  }catch(e){if(e.name==='AbortError')throw Error('计算请求超时，请确认本机服务仍在运行。');throw e;}finally{clearTimeout(timeout);}
}
function updateSource(){const w=snapshot.active;$('source-info').textContent=`${sourceLabel} · 原档第 ${w.tick} 步 · 种子 ${w.seed} · ${weather[snapshot.weather]}`;}
async function runCompare(candidate=snapshot,label=sourceLabel){
  if(busy||!candidate)return false;stop();busy=true;controls();notice('从原档恢复两个世界，计算接下来的 240 步…');
  try{
    const value=await request('/api/compare',{snapshot:candidate,actor:$('actor').value,kind:$('kind').value});
    snapshot=candidate;sourceLabel=label;result=value;offset=0;updateSource();renderFindings();render();
    notice('对照已生成。滑动时间轴或跳到关键时刻，查看两边同一步的行动。');return true;
  }catch(e){notice(e.message,true);return false;}finally{busy=false;controls();}
}
async function loadExample(){
  if(busy)return;stop();busy=true;controls();notice('读取完整 W2 示例…');
  let candidate;
  try{candidate=await request('/api/example?kind='+$('example').value);$('actor').value=candidate.info.actor;$('kind').value=candidate.info.kind;}
  catch(e){notice(e.message,true);}
  finally{busy=false;controls();}
  if(candidate)await runCompare(candidate.snapshot,candidate.label);
}
function different(a,b){return a.phase!==b.phase||a.target!==b.target||a.pos[0]!==b.pos[0]||a.pos[1]!==b.pos[1];}
function draw(side,frame){
  const canvas=$(side+'-map'),ctx=canvas.getContext('2d'),world=frame[side],xy=p=>[50+p[0]*56,36+p[1]*47];
  ctx.fillStyle=frame.weather==='rain'?'#dce8e8':'#e4eddb';ctx.fillRect(0,0,660,430);
  for(let x=0;x<11;x++)for(let y=0;y<8;y++){const [px,py]=xy([x,y]);ctx.fillStyle='#bfcfba';ctx.beginPath();ctx.arc(px,py,1.2,0,Math.PI*2);ctx.fill();}
  const label=(text,x,y,color='#617564',size=14)=>{ctx.fillStyle=color;ctx.font=`${size}px -apple-system,"PingFang SC",sans-serif`;ctx.textAlign='center';ctx.fillText(text,x,y);};
  ctx.fillStyle='#dfd5b8';ctx.beginPath();ctx.roundRect(225,246,210,66,25);ctx.fill();label('营地',330,335,'#8b896e',12);
  for(const pos of [[5,2],[5,3]]){const [x,y]=xy(pos);ctx.fillStyle='#b9d0c2';ctx.beginPath();ctx.roundRect(x-22,y-22,44,44,14);ctx.fill();}
  label('浅池',330,221,'#81998d',11);
  for(const [k,pos] of Object.entries(foods)){const [x,y]=xy(pos);ctx.fillStyle=k==='p'?'#c8d7ad':'#d7cbd6';ctx.beginPath();ctx.roundRect(x-38,y-29,76,58,18);ctx.fill();label(k==='p'?'✦  ✦':'✦  ✦',x,y+5,k==='p'?'#819a5e':'#a38a9e',22);label(places[k],x,y-43,'#4e6856');}
  for(const actor of ['A','B']){
    const person=world[actor],other=world[actor==='A'?'B':'A'],[x0,y]=xy(person.pos),x=x0+(person.pos[0]===other.pos[0]&&person.pos[1]===other.pos[1]?(actor==='A'?-9:9):0);
    const target=person.phase==='homebound'?homes[actor]:(person.target?foods[person.target]:null);
    if(target){const [tx,ty]=xy(target);ctx.strokeStyle=colors[actor]+'80';ctx.lineWidth=2;ctx.setLineDash([4,6]);ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(tx,ty);ctx.stroke();ctx.setLineDash([]);}
    if(different(frame.control[actor],frame.hinted[actor])){ctx.strokeStyle='#ac9659';ctx.lineWidth=3;ctx.beginPath();ctx.arc(x,y,20,0,Math.PI*2);ctx.stroke();}
    ctx.fillStyle=colors[actor];ctx.beginPath();ctx.arc(x,y,14,0,Math.PI*2);ctx.fill();label(actor,x,y+5,'#fffaf0');label(names[actor],x,y-25,colors[actor],12);
  }
  label(weather[frame.weather],52,27,'#617b72',12);label('位置与行动不同的角色以金环标出',330,409,'#7e907a',11);
}
function render(){
  if(!result)return;const frame=result.frames[offset];$('timeline').value=offset;
  $('clock').textContent=`分支后 +${offset} 步`;$('absolute').textContent=`原世界第 ${result.start+offset} 步 · ${weather[frame.weather]} · 两边同步`;
  $('hint-summary').textContent=`右 / 建议${names[result.actor]}去${places[result.kind]}`;
  for(const side of ['control','hinted']){
    draw(side,frame);const holder=$(side+'-status');holder.replaceChildren();
    for(const actor of ['A','B']){const person=frame[side][actor],diff=different(frame.control[actor],frame.hinted[actor]),row=el('div','','person'+(diff?' different':''));
      row.append(el('strong',`${actor} ${names[actor]}`));const detail=el('div',`${phases[person.phase]||person.phase}${person.target?' · '+places[person.target]:''}`);detail.append(el('div',`位置 (${person.pos.join(', ')}) · ${diff?'两边行为不同':'两边行为相同'}${person.choice?' · 本步出发：'+places[person.choice]:''}`,'detail'));row.append(detail);holder.append(row);}
    const deliveries=frame.deliveries[side],list=$(side+'-deliveries');list.replaceChildren(...(deliveries.length?deliveries:['本步没有该方向的报告送达。']).map(text=>el('li',text)));
  }
  controls();
}
function jump(n){stop();offset=Math.max(0,Math.min(result.horizon,Number(n)));render();}
function renderFindings(){
  $('timeline').max=result.horizon;const wrap=el('div','','metric-wrap'),table=el('table','','metric-table'),head=el('tr');
  for(const text of ['角色','首次不同','最后观测不同','不同步数','差异区间','末步仍不同','建议结束后不同','同一步改选'])head.append(el('th',text));table.append(head);
  for(const actor of ['A','B']){const m=result.people[actor];let intervals=0,was=false;for(const f of result.frames){const diff=different(f.control[actor],f.hinted[actor]);if(diff&&!was)intervals++;was=diff;}
    const row=el('tr');for(const text of [`${actor} ${names[actor]}${actor===result.actor?'（收件人）':'（同伴）'}`,at(m.first),at(m.last),`${m.steps} / ${result.horizon}`,String(intervals),m.at_end?'是 · 观察截断':'否',String(m.after_hint),String(m.choice_splits)])row.append(el('td',text));table.append(row);}
  wrap.append(table);$('metrics').replaceChildren(wrap);
  const status={visited:'已亲自到访',expired:'建议已到期',superseded:'被其他建议替代'}[result.hint_status]||'建议结束';
  const peer=result.actor==='A'?'B':'A';
  $('hint-end').textContent=result.hint_end===null?'右边这条建议在观察窗内尚未结束；没有窗内“结束后”时段。':`右边 ${at(result.hint_end)}：${status}。此后收件人${names[result.actor]}的行为不同 ${result.people[result.actor].after_hint} 步，同伴${names[peer]}不同 ${result.people[peer].after_hint} 步。`;
  $('relay').textContent=`给同伴的实际报告首次不同：${at(result.message_first)}。${result.relay?`有传播证据：报告先不同，随后${names[peer]}的行为不同；关闭双方后续交流后，同伴行为保持一致。`:'本对照未满足传播证据条件；不据此断言建议一定经交流影响了同伴。'}`;
  $('provenance').textContent=`存档内容指纹（数值规范化 SHA-256）: ${result.origin_hash} · 分支第 ${result.start} 步 · 观察 ${result.horizon} 步 · 本次收件人 ${result.actor} / 地点 ${result.kind}`;
  const jumps=$('jumps');jumps.replaceChildren();const add=(text,n)=>{if(n===null||n===undefined)return;const b=el('button',`${text} ${at(n)}`);b.dataset.offset=n;b.onclick=()=>jump(n);jumps.append(b);};
  add('分支',0);add('收件人首次不同',result.people[result.actor].first);add('报告首次不同',result.message_first);add('同伴首次不同',result.people[peer].first);add('建议结束',result.hint_end);if(result.hint_end!==null&&result.hint_end<result.horizon)add('建议结束后',result.hint_end+1);add('观察末步',result.horizon);
}
$('load-example').onclick=loadExample;$('compare').onclick=()=>runCompare();$('import').onclick=()=>$('file').click();
$('file').onchange=async()=>{const file=$('file').files[0];if(!file||busy)return;stop();try{
  if(file.size>1000000)throw Error('存档不能超过 1 MB');let value;try{value=JSON.parse(await file.text());}catch{throw Error('文件不是有效 JSON，原对照已保留。');}
  if(!value||value.version!==2)throw Error('请导入完整 W2 v2 存档，原对照已保留。');await runCompare(value,'导入：'+file.name);
}catch(e){notice(e.message,true);}finally{$('file').value='';controls();}};
$('timeline').oninput=()=>jump($('timeline').value);$('back').onclick=()=>jump(offset-1);$('next').onclick=()=>jump(offset+1);
function start(){if(!result||busy)return;if(offset===result.horizon)offset=0;timer=setInterval(()=>{offset=Math.min(result.horizon,offset+1);render();if(offset===result.horizon)stop();},500/Number($('speed').value));$('play').textContent='暂停';render();}
$('play').onclick=()=>{if(timer)stop();else start();};$('speed').onchange=()=>{if(timer){stop();start();}};
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});controls();loadExample();
