// Isolated DOM logic test, not a browser rendering or timing test.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync(process.argv[2],'utf8');
const payload=html.match(/<script id="payload" type="application\/json">([\s\S]*?)<\/script>/)[1];
const script=html.match(/<script>\s*([\s\S]*?)<\/script>/)[1];
class Element{constructor(){this.children=[];this.value='';this.textContent='';this.innerHTML=''}append(...nodes){this.children.push(...nodes)}replaceChildren(...nodes){this.children=[...nodes]}}
const ids=Object.fromEntries(['payload','scenario','policy','round','play','description','clock','actors','map','chart','message','trustnote','summary','raw'].map(k=>[k,new Element()]));ids.payload.textContent=payload;
let callback;
const context=vm.createContext({document:{getElementById:id=>ids[id],createElement:()=>new Element()},setInterval:fn=>{callback=fn;return 1},clearInterval:()=>{}});
vm.runInContext(script,context);
const data=JSON.parse(payload);let cards=0;
for(const scenario of data.config.scenarios)for(const policy of data.config.policies){ids.scenario.value=scenario;ids.policy.value=policy;ids.policy.onchange();assert.equal(ids.summary.children.length,4);
 for(let t=0;t<120;t++){ids.round.value=String(t);ids.round.oninput();const row=data.traces[scenario+'/'+policy][t];assert.equal(ids.actors.children.length,2);assert.ok(ids.map.innerHTML.includes('<svg'));assert.ok(ids.chart.innerHTML.includes('<svg'));
  for(const [i,a] of ['A','B'].entries()){assert.ok(ids.actors.children[i].children[1].textContent.includes('累计收益：'+row.health[a]+'\n'));cards++}
  assert.deepEqual(JSON.parse(ids.raw.textContent),row);
 }
 ids.round.value='0';ids.round.oninput();ids.play.onclick();for(let i=0;i<10;i++)callback();assert.ok(ids.clock.textContent.includes('已回营并交谈'));assert.equal(ids.round.value,'0');callback();assert.equal(ids.round.value,'1');ids.play.onclick();
}
console.log(JSON.stringify({passed:true,actor_cards_checked:cards,profiles:16,playback_transitions:16,coverage:'DOM logic test doubles; no browser layout/timing claim'}));
