'use strict';
const $=id=>document.getElementById(id);
const names={A:'阿禾',B:'小岚'},places={p:'青禾地',q:'紫穗地'},phases={rest:'营地休息',outbound:'前往食物地',homebound:'返回营地'},weather={sun:'晴天',rain:'雨天'};
const foods={p:[2,2],q:[8,2]},homes={A:[4,5],B:[6,5]},colors={A:'#bd7d4b',B:'#5c879a'};
const stages=['给出线索','获得亲历','告诉同伴','同伴的选择'];
let snapshot=null,result=null,offset=0,busy=false,timer=null,sourceLabel='',guidedTarget=null;
const at=n=>n===null||n===undefined?'未出现':`+${n}`;
const el=(tag,text='',cls)=>{const node=document.createElement(tag);node.textContent=text;if(cls)node.className=cls;return node;};
function notice(text,error=false){$('notice').textContent=text;$('notice').classList.toggle('error',error);}
function stop(){if(timer)clearInterval(timer);timer=null;guidedTarget=null;$('play').textContent='播放';$('story-next').textContent=offset===result?.horizon?'从头再看':'看下一段';}
function controls(){
  for(const id of ['example','load-example','import','actor','kind','compare'])$(id).disabled=busy||(!snapshot&&['compare','actor','kind'].includes(id));
  for(const id of ['back','play','next','speed','timeline','story-next'])$(id).disabled=busy||!result;
  $('back').disabled=busy||!result||offset===0;$('next').disabled=busy||!result||offset===result.horizon;
  for(const button of document.querySelectorAll('#jumps button,#story-steps button'))button.disabled=busy||!result;
}
async function request(path,body){
  const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),15000);
  try{const response=await fetch(path,{signal:controller.signal,...(body?{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}:{})});const value=await response.json();if(!response.ok)throw Error(value.error||'本机服务请求失败');return value;}
  catch(e){if(e.name==='AbortError')throw Error('计算请求超时，请确认本机服务仍在运行。');throw e;}finally{clearTimeout(timeout);}
}
function updateSource(){$('source-info').textContent=`${sourceLabel} · 原档第 ${snapshot.active.tick} 步 · ${weather[snapshot.weather]}`;}
async function runCompare(candidate=snapshot,label=sourceLabel){
  if(busy||!candidate)return;stop();busy=true;controls();notice('正在给出线索，并观察两个世界接下来的经历…');
  try{const value=await request('/api/compare',{snapshot:candidate,actor:$('actor').value,kind:$('kind').value});snapshot=candidate;sourceLabel=label;result=value;offset=0;updateSource();render();$('compare').textContent='从原档重新给出';notice('线索已给出。点“看下一段”，跟着这段经历走。');}
  catch(e){notice(e.message+' 当前画面与原档已保留。',true);}finally{busy=false;controls();}
}
async function loadExample(){
  if(busy)return;stop();busy=true;controls();notice('准备起点…');
  try{const value=await request('/api/example?kind='+$('example').value);snapshot=value.snapshot;sourceLabel=value.label;result=null;offset=0;$('actor').value=value.info.actor;$('kind').value=value.info.kind;updateSource();render();$('compare').textContent='给出这条线索';notice('场景已准备好，还没有人收到你的线索。');}
  catch(e){notice(e.message+' 当前画面与原档已保留。',true);}finally{busy=false;controls();}
}
function different(a,b){return a.phase!==b.phase||a.target!==b.target||a.pos[0]!==b.pos[0]||a.pos[1]!==b.pos[1];}
function preview(){const world={};for(const [name,p] of Object.entries(snapshot.active.residents))world[name]={pos:p.pos,phase:p.phase,target:p.phase==='outbound'?p.target:null,choice:null};return {weather:snapshot.weather,control:world,hinted:world,deliveries:{control:[],hinted:[]}};}
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
function markStory(frame){
  if(!result)return;const node=result.story.nodes.find(n=>n.offset===offset);if(!node)return;
  const ctx=$('hinted-map').getContext('2d'),xy=p=>[50+p[0]*56,36+p[1]*47],actor=result.actor,peer=result.story.peer;
  const point=node.key==='experience'?foods[result.kind]:frame.hinted[node.key==='choice'?peer:actor].pos;
  const [x,y]=xy(point);ctx.strokeStyle='#426c59';ctx.lineWidth=3;
  if(node.key==='delivery'){const [tx,ty]=xy(frame.hinted[peer].pos);ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(tx,ty);ctx.stroke();ctx.beginPath();ctx.arc(tx,ty,21,0,Math.PI*2);ctx.stroke();}
  else{ctx.beginPath();ctx.arc(x,y,27,0,Math.PI*2);ctx.stroke();}
  const label={hint:'你的线索',experience:'亲自尝过',delivery:'亲历送达',choice:'这一步作出选择'}[node.key];
  ctx.fillStyle='#f8fbef';ctx.fillRect(220,351,220,30);ctx.fillStyle='#315843';ctx.font='14px -apple-system,"PingFang SC",sans-serif';ctx.textAlign='center';ctx.fillText(label,330,371);
  $('hinted-map').setAttribute('aria-label','有建议世界地图 · '+label);
}
function storyCopy(node){
  const {actor,peer,kind}=result.story,a=names[actor],b=names[peer],place=places[kind],e=node.event;
  if(node.key==='hint')return [`你告诉${a}：去${place}看看`,`他收到的是地点建议，还不是事实。接下来要靠自己走过去、尝一尝。`,'另一边没有收到建议，两人的原有记忆相同。'];
  if(node.key==='experience')return [`${a}亲自尝过了${place}`,`${weather[e.weather]}，这次取食${e.reward>0?'让他感到舒适':'让他感到不适'}。他现在有了一条自己的经历。`,node.same_in_control?'无建议世界的他，也在同一步得到相同亲历；这一步尚不能算你的线索带来的差异。':'这是亲历记录；是否传到同伴，要等两人相遇。'];
  if(node.key==='delivery')return [`${a}把这段经历告诉了${b}`,`两人相遇。${b}收到：${weather[e.report.weather||e.weather]}的${place}，${a}亲自尝过后${e.report.claim>0?'感觉不错':'感觉不适'}。`,`传的是刚才那条亲历，不是把你的建议当事实。收到消息，也不等于一定会改选。`];
  const d=e.event,p=e.report_test,target=places[d.target];
  if(e.supported)return [`${b}改去${target}了`,`之前去${places[d.previous_target]}，这次出发选了${target}。同一步，无建议世界的${b}仍选${places[e.control_choice.target]}。`,`核对这一次决定：只去掉${a}这条亲历报告，他会选${places[p.without_report_target]}。这条报告改变了本次选择。`];
  let proof=!p.changes_target?'只去掉这条报告，他仍选同一地点；不能说这条报告改变了决定。':!e.control_choice?'两边没有同时出发，不能把出发时差当成改选证据。':'报告影响了本次决定，但完整对照不足以把改选归因于这次干预。';
  if(d.route==='explore')proof='这次触发了偶尔探索，不能把选择归功于收到的消息。';
  if(d.route==='unknown')proof='这次优先尝试还没有亲历的地点，不能说是消息让他改选。';
  return [`${b}这次选择${target}`,`他带着收到的经历作了决定。${d.previous_target===d.target?'这次仍去之前的地点。':'这里只展示实际选择，不预设一定改选。'}`,proof];
}
function renderStory(){
  const nodes=result?.story.nodes||stages.map((_,i)=>({key:String(i),offset:null}));
  const seen=nodes.filter(n=>result&&n.offset!==null&&n.offset<=offset);
  const missing=result&&offset===result.horizon?nodes.find(n=>n.offset===null):null;
  const focus=missing||seen.at(-1);const holder=$('story-steps');holder.replaceChildren();
  nodes.forEach((node,i)=>{const reached=seen.includes(node),button=el('button','','story-step'+(reached?' reached':'')+(node===focus?' active':''));button.dataset.stage=i;button.setAttribute('aria-current',node===focus?'step':'false');
    button.append(el('span',String(i+1).padStart(2,'0'),'step-number'),el('strong',reached&&node.key==='choice'&&node.event.supported?'同伴改选':stages[i]),el('small',reached?`已发生 · ${at(node.offset)}`:result&&offset===result.horizon?'本轮未出现':'尚未走到这一段'));
    button.onclick=()=>jump(node.offset??result.horizon);holder.append(button);});
  let copy=['先把一个地点，告诉一个人','两边从同一刻出发。右边听到你的建议，左边照常生活。','这是选出的机制示例。换一个建议，结果可能不同。'];
  if(focus&&result){if(missing){const reason={experience:missing.empty_visit?'到过建议地点，但那里没有食物；没有可分享的取食亲历。':result.hint_status==='expired'?'线索已到期，期间没有在建议地点获得取食亲历。':'观察期间，没有在建议有效期内获得该地点的取食亲历。',delivery:'已经亲历，但这条报告没有在观察窗内送达同伴。',choice:'报告已经送达，但观察窗内没有记录到同伴带着这条有效报告作决定。'}[missing.key];copy=['这条过程停在这里',reason,'没有发生的环节保持空白；不代表观察窗之后也永远不会发生。'];}else copy=storyCopy(focus);}
  $('story-title').textContent=copy[0];$('story-text').textContent=copy[1];$('story-evidence').textContent=copy[2];
  $('story-kicker').textContent=!result?'还没有给出线索':missing?'观察结束 · 未完成整条过程':`已看到 ${at(focus.offset)} · ${stages[nodes.indexOf(focus)]}`;
  $('story-state').textContent=!result?'起点已就绪，等待你的干预。':`已看到 ${seen.length} / 4 段${offset===result.horizon?' · 240 步观察结束':seen.length===4?' · 可以继续观察后续':' · 其余过程继续观察'}`;
  $('story-next').textContent=timer&&guidedTarget!==null?'暂停这一段':offset===result?.horizon?'从头再看':'看下一段';
}
function render(){
  if(!snapshot)return;const frame=result?result.frames[offset]:preview();$('timeline').value=offset;
  $('clock').textContent=result?`给线索后 +${offset} 步`:'准备出发';$('absolute').textContent=`原世界第 ${(result?.start??snapshot.active.tick)+offset} 步 · ${weather[frame.weather]} · 两边同步`;
  $('hint-summary').textContent=result?`右 / 建议${names[result.actor]}去${places[result.kind]}`:'右 / 尚未给出';
  for(const side of ['control','hinted']){draw(side,frame);const holder=$(side+'-status');holder.replaceChildren();
    for(const actor of ['A','B']){const p=frame[side][actor],diff=different(frame.control[actor],frame.hinted[actor]),row=el('div','','person'+(diff?' different':''));row.append(el('strong',names[actor]));const detail=el('div',`${phases[p.phase]}${p.target?' · '+places[p.target]:''}`);detail.append(el('div',`${diff?'两边行动不同':'两边行动相同'}${p.choice?' · 本步出发：'+places[p.choice]:''}`,'detail'));row.append(detail);holder.append(row);}
    const list=$(side+'-deliveries'),deliveries=frame.deliveries[side];list.replaceChildren(...(deliveries.length?deliveries:['本步没有该方向的报告送达。']).map(text=>el('li',text)));}
  $('hinted-map').setAttribute('aria-label','有建议世界地图');markStory(frame);renderStory();
  const finished=result&&offset===result.horizon;$('full-results').hidden=!finished;
  if(finished)renderFindings();else{for(const id of ['metrics','hint-end','relay','jumps'])$(id).replaceChildren();$('full-results').open=false;}
  $('provenance').textContent=result?`存档指纹：${result.origin_hash} · 第 ${result.start} 步分支 · 观察 ${result.horizon} 步`:'';
  controls();
}
function jump(n){if(!result||busy)return;stop();offset=Math.max(0,Math.min(result.horizon,Number(n)));render();}
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
function start(target=null){if(!result||busy)return;stop();if(offset===result.horizon)offset=0;guidedTarget=target;timer=setInterval(()=>{offset=Math.min(guidedTarget??result.horizon,offset+1);if(offset===(guidedTarget??result.horizon))stop();render();},500/Number($('speed').value));$('play').textContent='暂停';render();}
$('load-example').onclick=loadExample;$('compare').onclick=()=>runCompare();$('import').onclick=()=>$('file').click();
$('file').onchange=async()=>{const file=$('file').files[0];if(!file||busy)return;stop();try{if(file.size>1000000)throw Error('存档不能超过 1 MB');let value;try{value=JSON.parse(await file.text());}catch{throw Error('文件不是有效 JSON，原画面已保留。');}if(!value||value.version!==2)throw Error('请导入完整 W2 v2 存档，原画面已保留。');await runCompare(value,'导入：'+file.name);}catch(e){notice(e.message,true);}finally{$('file').value='';controls();}};
for(const id of ['actor','kind'])$(id).onchange=()=>{stop();$('compare').textContent=result?'应用新线索':'给出这条线索';notice(result?`选项待应用；当前仍显示告诉${names[result.actor]}去${places[result.kind]}的过程。`:'线索尚未给出，点击按钮后应用。');};
$('example').onchange=()=>{stop();notice('起点选项待应用；点击“准备场景”后切换，当前画面保留。');};
$('timeline').oninput=()=>jump($('timeline').value);$('back').onclick=()=>jump(offset-1);$('next').onclick=()=>jump(offset+1);
$('play').onclick=()=>{if(timer)stop();else start();};$('speed').onchange=()=>{if(timer){const target=guidedTarget;start(target);}};
$('story-next').onclick=()=>{if(timer){stop();return;}if(offset===result.horizon){jump(0);return;}const next=result.story.nodes.find(n=>n.offset!==null&&n.offset>offset);start(next?.offset??result.horizon);};
document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});controls();loadExample();
