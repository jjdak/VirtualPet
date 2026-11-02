// DOM logic doubles only; actual browser evidence lives under results/<run>/review.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync(process.argv[2],'utf8');
const payload=html.match(/<script id="payload" type="application\/json">([\s\S]*?)<\/script>/)[1];
const script=html.match(/<script>\s*([\s\S]*?)<\/script>/)[1];
class Element{constructor(){this.children=[];this.value='';this.textContent='';this.innerHTML=''}append(...nodes){this.children.push(...nodes)}replaceChildren(...nodes){this.children=[...nodes]}}
const names=['payload','scenario','comparator','round','play','jump','description','clock','lefttitle','leftmap','rightmap','leftactors','rightactors','leftevent','rightevent','curve','difference','summary','interval','raw'];
const ids=Object.fromEntries(names.map(k=>[k,new Element()]));ids.payload.textContent=payload;ids.round.value='40';let callback;
const context=vm.createContext({document:{getElementById:id=>ids[id],createElement:()=>new Element()},setInterval:fn=>{callback=fn;return 1},clearInterval:()=>{}});
vm.runInContext(script,context);const data=JSON.parse(payload);let cards=0,profiles=0;
for(const scenario of data.config.scenarios)for(const policy of data.config.policies.filter(p=>p!=='surprise_stale')){ids.scenario.value=scenario;ids.comparator.value=policy;ids.comparator.onchange();assert.equal(ids.summary.children.length,4);
 for(let tick=0;tick<120;tick++){ids.round.value=String(tick);ids.round.oninput();const raw=JSON.parse(ids.raw.textContent);for(const [prefix,mode] of [['left',policy],['right','surprise_stale']]){const row=data.traces[scenario+'/'+mode][tick];assert.deepEqual(raw[prefix],row);assert.ok(ids[prefix+'map'].innerHTML.includes('<svg'));assert.equal(ids[prefix+'actors'].children.length,2);for(const [i,actor] of ['A','B'].entries()){assert.ok(ids[prefix+'actors'].children[i].textContent.includes('累计真实收益 '+row.health[actor].toFixed(1)));cards++}}assert.ok(ids.curve.innerHTML.includes('<svg'));assert.ok(!ids.interval.textContent.includes('NaN'))}
 ids.jump.onclick();const first=data.traces[scenario+'/surprise_stale'].findIndex(r=>r.choices.B.monitor.scheduled);assert.equal(Number(ids.round.value),first<0?40:first);
 ids.round.value='0';ids.round.oninput();ids.play.onclick();for(let i=0;i<10;i++)callback();assert.equal(ids.round.value,'0');callback();assert.equal(ids.round.value,'1');ids.play.onclick();profiles++;
}
console.log(JSON.stringify({passed:true,profiles,actor_cards_checked:cards,playback_transitions:profiles,coverage:'DOM logic doubles; actual browser layout/playback verified separately'}));
