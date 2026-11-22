// Fixed steps and stateless, addressed draws keep independently advanced branches reproducible.
export const RULE_VERSION = 1;
export const MAX_TICK = Number.MAX_SAFE_INTEGER;
export const NAMES = Object.freeze({A:'阿禾', B:'小岚', C:'小苔', D:'阿栗'});
export const GLYPHS = Object.freeze(['◇', '○', '△']);
export const PLACES = Object.freeze({
  p:Object.freeze({id:'p', name:'青禾地', x:2, y:2}),
  q:Object.freeze({id:'q', name:'紫穗地', x:9, y:2}),
  r:Object.freeze({id:'r', name:'红果地', x:9, y:7}),
});
const IDS = Object.keys(NAMES);
const SITES = Object.keys(PLACES);
const ACTIONS = [...GLYPHS, ''];
const CHANNELS = ['normal', 'muted', 'permuted'];
const HINT_TTL = 24;
const MAP = {
  width:12, height:9,
  home:{x:5,y:5},
  homes:{A:{x:5,y:5},B:{x:6,y:5},C:{x:5,y:6},D:{x:6,y:6}},
  walls:[[4,2],[4,3],[5,3],[7,3],[8,3],[3,6],[3,7],[7,6],[7,7],[10,5]],
};

function draw(seed, ...address) {
  let hash = seed ^ 0x811c9dc5;
  for (const character of address.join('/')) {
    hash = Math.imul(hash ^ character.charCodeAt(0), 0x01000193);
  }
  hash = Math.imul(hash ^ (hash >>> 16), 0x7feb352d);
  hash = Math.imul(hash ^ (hash >>> 15), 0x846ca68b);
  return ((hash ^ (hash >>> 16)) >>> 0) / 2 ** 32;
}

function remember(table, key, sample, tick, rate) {
  const entry = table[key] ?? {count:0,mean:0,lastTick:0};
  entry.mean += (sample - entry.mean) * (entry.count ? rate : 1);
  entry.count += 1;
  entry.lastTick = tick;
  table[key] = entry;
}

function emit(world, type, text, extra={}) {
  world.events.push({id:++world.sequence,tick:world.tick,type,text,...extra});
  if (world.events.length > 64) world.events.shift();
}

const distance = (a,b) => Math.abs(a.x-b.x)+Math.abs(a.y-b.y);
const index = (x,y) => y*MAP.width+x;
const walls = new Set(MAP.walls.map(([x,y]) => index(x,y)));
const routes = {};
for (const [id, destination] of Object.entries({...MAP.homes,...PLACES})) {
  const goal = index(destination.x,destination.y);
  const next = {[goal]:goal};
  const queue = [goal];
  for (let cursor=0; cursor<queue.length; cursor++) {
    const current = queue[cursor];
    const x = current % MAP.width, y = Math.floor(current / MAP.width);
    for (const [dx,dy] of [[0,1],[-1,0],[1,0],[0,-1]]) {
      const neighbor = index(x+dx,y+dy);
      if (x+dx<0 || x+dx>=MAP.width || y+dy<0 || y+dy>=MAP.height
          || walls.has(neighbor) || Object.hasOwn(next,neighbor)) continue;
      next[neighbor] = current;
      queue.push(neighbor);
    }
  }
  routes[id] = next;
}

function createResident(seed,id) {
  const trait = key => draw(seed,'trait',id,key);
  return {
    id,name:NAMES[id],...MAP.homes[id],phase:'rest',target:null,
    traits:{curiosity:Math.round((0.12+0.21*trait('curiosity'))*100)/100,
            speed:1+Number(trait('speed')>0.7),sight:1+Math.floor(3*trait('sight'))},
    readyAt:2+Math.floor(6*trait('rest')),nextMove:0,
    preferences:Object.fromEntries(SITES.map(place=>[place,{count:0,mean:0,lastTick:0}])),
    seen:{}, latest:null, incoming:null,
    listening:{}, sending:{}, trips:[],tripCount:0,lastDecision:null,
    achievements:{firstReturn:null,tasted:{},firstSignalChoice:null},
  };
}

function updatePlaces(world) {
  for (const site of Object.values(world.places)) {
    const supplyWindow = Math.floor((world.tick + site.x) / 23);
    const tasteWindow = Math.floor((world.tick + 3*site.y) / 52);
    site.available = draw(world.seed,'supply',site.id,supplyWindow) >= 0.12;
    site.effect = draw(world.seed,'taste',site.id,tasteWindow) >= 0.42 ? 1 : -1;
  }
}

export function createWorld(seed, {channel='normal'}={}) {
  if (!Number.isInteger(seed) || seed<0 || seed>0xffffffff || !CHANNELS.includes(channel)) {
    throw new RangeError('种子或交流方式无效。');
  }
  const world = {
    version:RULE_VERSION,seed,channel,tick:0,map:structuredClone(MAP),
    places:Object.fromEntries(SITES.map(id=>[id,{...PLACES[id]}])),
    residents:Object.fromEntries(IDS.map(id=>[id,createResident(seed,id)])),
    events:[],sequence:0,input:null,hint:null,contacts:{},feedback:{},
    stats:{trips:0,totalReward:0,glyphSent:0,glyphHeard:0,silence:0,senderFeedback:0,
           feedbackExpired:0,glyphChoices:0,changedChoices:0,byGlyph:{},
           byContext:{},byResident:Object.fromEntries(IDS.map(id=>[id,{trips:0,reward:0,changed:0}]))},
  };
  updatePlaces(world);
  emit(world,'world','营地慢慢醒来，四位居民准备各自去觅食。');
  return world;
}

export const cloneWorld = world => structuredClone(world);

export function suggest(world,place) {
  if (world.input || !SITES.includes(place)) return false;
  world.input = {tick:world.tick,place};
  world.hint = {...world.input,status:'pending'};
  emit(world,'hint',`你建议小岚下一趟去${PLACES[place].name}看看。`,{actor:'B',place});
  return true;
}

function observe(person,world) {
  for (const site of Object.values(world.places)) {
    if (distance(person,site) <= person.traits.sight) {
      person.seen[site.id] = {tick:world.tick,available:site.available};
    }
  }
}

function localContact(world,receiver) {
  if (receiver.phase!=='rest' || world.contacts[receiver.id]) return;
  const senders = IDS.filter(id=>id!==receiver.id).map(id=>world.residents[id])
    .filter(sender=>sender.latest && world.tick-sender.latest.tick <= 34
      && distance(sender,receiver)<=2);
  if (!senders.length) return;
  const {seed,tick} = world;
  const sender = senders[Math.floor(draw(seed,'contact',tick,receiver.id)*senders.length)];
  const context = `${receiver.id}/${sender.latest.place}/${sender.latest.reward>0?'+':'-'}`;
  const exploratory = draw(seed,'signal-explore',tick,sender.id,receiver.id)<0.25;
  const action = exploratory
    ? ACTIONS[Math.floor(draw(seed,'signal',tick,sender.id,receiver.id)*ACTIONS.length)]
    : ACTIONS.reduce((best,candidate)=>{
      const score = item => (sender.sending[`${context}/${item}`]?.mean ?? 0)
        + 0.035 * draw(seed,'signal-tie',tick,sender.id,receiver.id,item);
      return score(candidate)>score(best) ? candidate : best;
    });
  // The receiver sees only the sender and the actual glyph. Choice context stays private.
  world.contacts[receiver.id] = {sender:sender.id, context, action};
  const privateContext = `${sender.id}/${context}`;
  const tally = world.stats.byContext[privateContext] ?? {};
  tally[action] = (tally[action] ?? 0)+1;
  world.stats.byContext[privateContext] = tally;
  if (!action) {
    world.stats.silence++;
    return;
  }
  world.stats.glyphSent++;
  if (world.channel === 'muted') return;
  const glyph = world.channel==='permuted'
    ? GLYPHS[Math.floor(draw(seed,'scramble',tick,sender.id,receiver.id)*GLYPHS.length)]
    : action;
  receiver.incoming = {sender:sender.id,glyph,tick};
  world.stats.glyphHeard++;
  world.stats.byGlyph[glyph] = (world.stats.byGlyph[glyph] ?? 0)+1;
  emit(world,'signal',`${sender.name}朝${receiver.name}比了一个 ${glyph}。`,
       {sender:sender.id,receiver:receiver.id,glyph});
}

function eligibleSites(world,person) {
  const eligible = SITES.filter(place=>{
    const seen = person.seen[place];
    return !seen || seen.available || world.tick - seen.tick > 9;
  });
  return eligible.length ? eligible : SITES;
}

function decide(world,person) {
  const {seed,tick} = world;
  const sites = eligibleSites(world,person);
  const incoming = person.incoming ? {...person.incoming} : null;
  const hint = person.id==='B' && world.hint?.status==='pending'
    ? {place:world.hint.place,tick:world.hint.tick}
    : null;
  const explore = draw(seed,'explore',tick,person.id)<person.traits.curiosity;
  const known = Object.fromEntries(SITES.map(place=>{
    const known = person.preferences[place];
    const learned = incoming && person.listening[`${incoming.sender}/${incoming.glyph}/${place}`];
    const seen = person.seen[place];
    return [place,{
      firsthand:{...known}, symbol:learned ? {...learned} : null,
      supply:seen ? {...seen} : null, eligible:sites.includes(place), score:null,
    }];
  }));
  if (explore) {
    const place = sites[Math.floor(draw(seed,'choice',tick,person.id)*sites.length)];
    return {tick,place,method:'explore',incoming,hint,known,mutedPlace:place,noHintPlace:place};
  }
  const scores = Object.fromEntries(sites.map(place=>{
    const {firsthand,symbol} = known[place];
    // Blend only evidence from this resident's visits, discounting old or sparse evidence.
    const weight = symbol ? 0.72*symbol.count/(symbol.count+2)*Math.max(0.22,1-(tick-symbol.lastTick)/170) : 0;
    const own = firsthand.mean*Math.max(0.24,1-(tick-firsthand.lastTick)/135);
    const combined = own*(1-weight)+(symbol?.mean ?? 0)*weight;
    const bonus = hint?.place===place ? 0.52 : 0;
    const tie = 0.10*draw(seed,'choice-tie',tick,person.id,place);
    known[place].score = combined+bonus+tie;
    return [place,{actual:known[place].score, muted:own+bonus+tie, noHint:combined+tie}];
  }));
  const choose = mode=>sites.reduce((best,place)=>scores[place][mode]>scores[best][mode]?place:best);
  return {
    tick,place:choose('actual'),method:'score',incoming,hint,known,
    mutedPlace:choose('muted'),noHintPlace:choose('noHint'),
  };
}

function depart(world,person) {
  const decision = decide(world,person);
  const {place:target,mutedPlace:muted} = decision;
  person.lastDecision = decision;
  if (person.incoming) world.stats.glyphChoices++;
  if (target!==muted) {
    world.stats.changedChoices++;
    world.stats.byResident[person.id].changed++;
    person.achievements.firstSignalChoice ??= world.tick;
  }
  if (person.id==='B' && world.hint?.status==='pending') {
    world.hint = {...world.hint,status:'used',usedAt:world.tick};
  }
  const trip = {id:++person.tripCount,departure:world.tick,arrived:null,place:target,
                reward:null,returned:null,glyph:person.incoming?.glyph ?? null,mutedPlace:muted};
  person.trips.push(trip);
  if (person.trips.length>24) person.trips.shift();
  person.target = target;
  person.phase = 'outbound';
  person.nextMove = world.tick + person.traits.speed;
  emit(world,'departure',`${person.name}出发去${PLACES[target].name}。`,
       {actor:person.id,trip:trip.id,place:target});
}

function rewardAt(world,person,place,tick) {
  const site = world.places[place];
  if (!site.available) return 0;
  const taste = draw(world.seed,'food-person',person.id,place);
  const bite = draw(world.seed,'bite',person.id,place,tick);
  return Math.round((0.76*site.effect+0.36*(taste-0.5)+0.12*(bite-0.5))*100)/100;
}

function experience(world,person,trip) {
  const {tick} = world;
  const reward = rewardAt(world,person,trip.place,tick);
  trip.arrived = tick;
  trip.reward = reward;
  remember(person.preferences,trip.place,reward,tick,0.39);
  if (person.incoming) {
    const {sender,glyph} = person.incoming;
    remember(person.listening,`${sender}/${glyph}/${trip.place}`,reward,tick,0.31);
  }
  if (reward!==0) {
    person.latest = {place:trip.place,reward,tick};
    person.achievements.tasted[trip.place] ??= tick;
  }
  world.stats.trips++;
  world.stats.totalReward += reward;
  world.stats.byResident[person.id].trips++;
  world.stats.byResident[person.id].reward += reward;
  person.phase = 'homebound';
  const outcome = reward>0?'尝到了合口的食物':reward<0?'尝了以后不舒服':'没有找到食物';
  emit(world,'experience',`${person.name}在${PLACES[trip.place].name}${outcome}。`,
       {actor:person.id,trip:trip.id,place:trip.place,reward});
}

function returnHome(world,person,trip) {
  const {tick} = world;
  trip.returned = tick;
  person.achievements.firstReturn ??= tick;
  person.phase = 'rest';
  person.target = null;
  person.readyAt = tick+4+Number(trip.reward<0);
  // A visible reaction, usable only if the original sender actually meets the listener again.
  const contact = world.contacts[person.id];
  if (contact) {
    world.feedback[person.id] = {...contact,reward:Math.sign(trip.reward),until:tick+8};
    delete world.contacts[person.id];
  }
  person.incoming = null;
  emit(world,'return',`${person.name}回到营地休息。`,
       {actor:person.id,trip:trip.id,place:trip.place,reward:trip.reward});
}

function exchangeFeedback(world) {
  for (const person of Object.values(world.residents)) {
    const feedback = world.feedback[person.id];
    if (!feedback) continue;
    const sender = world.residents[feedback.sender];
    if (world.tick>feedback.until) {
      world.stats.feedbackExpired++;
      delete world.feedback[person.id];
    } else if (distance(sender,person)<=2) {
      remember(sender.sending,`${feedback.context}/${feedback.action}`,feedback.reward,world.tick,0.25);
      world.stats.senderFeedback++;
      delete world.feedback[person.id];
    }
  }
}

function act(world,person) {
  if (person.phase==='rest') {
    if (world.tick>=person.readyAt) depart(world,person);
    return;
  }
  if (world.tick<person.nextMove) return;
  const trip = person.trips.at(-1);
  const outward = person.phase==='outbound';
  const destination = outward ? PLACES[trip.place] : MAP.homes[person.id];
  const next = routes[outward?trip.place:person.id][index(person.x,person.y)];
  person.x = next % MAP.width;
  person.y = Math.floor(next/MAP.width);
  person.nextMove = world.tick+person.traits.speed;
  if (distance(destination,person)!==0) return;
  if (outward) experience(world,person,trip);
  else returnHome(world,person,trip);
}

function growthView({firstReturn,tasted,firstSignalChoice}) {
  const count = Object.keys(tasted).length;
  const milestones = [
    {id:'first-return',title:'初次归营',description:'完成一趟觅食并回到营地。',
     progress:Number(firstReturn!==null),target:1,earnedAt:firstReturn},
    {id:'tasted-all',title:'尝遍三处',description:'亲自在三处觅食地尝到过食物。',
     progress:count,target:SITES.length,earnedAt:count===SITES.length?Math.max(...Object.values(tasted)):null},
    {id:'signal-choice',title:'循着一次线索',description:'曾因自己学到的符号经验而改选目的地。',
     progress:Number(firstSignalChoice!==null),target:1,earnedAt:firstSignalChoice},
  ];
  return {earned:milestones.filter(item=>item.earnedAt!==null).length,total:milestones.length,milestones};
}

const outcome = reward => reward>0?'尝到了合口的食物':reward<0?'吃了有些不舒服':'没有找到食物';

function decisionNotes(decision,phase) {
  if (!decision) return [];
  const {place,tick,method,known,incoming,hint,mutedPlace,noHintPlace} = decision;
  const prefix = phase==='rest'?'上一趟出发':'这一趟出发';
  const site = PLACES[place].name;
  const possible = SITES.filter(id=>known[id].eligible).map(id=>PLACES[id].name);
  const notes = [method==='explore'
    ? `${prefix}在第 ${tick} 步触发了探索，从${possible.join('、')}中抽到${site}。`
    : `${prefix}在第 ${tick} 步比较了可选地点的估分，${site}得分最高。`];
  if (method==='score') {
    notes.push(...SITES.map(id=>{
      const {firsthand,symbol,supply,eligible,score} = known[id];
      const observation = supply ? `第 ${supply.tick} 步看到${supply.available?'有':'没有'}食物` : '还没看到供给';
      const personal = firsthand.count
        ? `亲自查看过 ${firsthand.count} 次，最近一次在第 ${firsthand.lastTick} 步，亲历估值 ${firsthand.mean.toFixed(2)}`
        : '还没亲自查看过';
      const evidence = symbol ? `，收到同一人的同一符号后曾去过 ${symbol.count} 次，估值 ${symbol.mean.toFixed(2)}` : '';
      return `${PLACES[id].name}：${personal}，${observation}${evidence}；${eligible?`出发估分 ${score.toFixed(2)}`:'当时跳过'}。`;
    }));
  }
  if (incoming) {
    const changed = mutedPlace!==place;
    notes.push(`出发前看到了${NAMES[incoming.sender]}的 ${incoming.glyph}。${changed
      ? `在当时只去掉这个符号，会改选${PLACES[mutedPlace].name}。`
      : '在当时只去掉这个符号，目的地相同。'}`);
  }
  if (hint) notes.push(noHintPlace!==place
    ? `在当时只去掉你对${PLACES[hint.place].name}的提醒，会改选${PLACES[noHintPlace].name}。`
    : `出发前收到了你对${PLACES[hint.place].name}的提醒。在当时只去掉提醒，目的地相同。`);
  return notes;
}

export function mindView(world,id) {
  const person = world.residents[id];
  if (!person) throw new RangeError('没有这位居民。');
  const {phase,lastDecision,incoming,trips} = person;
  const current = trips.at(-1);
  const hint = id==='B' && world.hint?.status==='pending' ? world.hint : null;
  const details = [];
  let cue = 'rest';
  let summary = '在营地休息，等下一趟觅食。';
  if (phase==='outbound') {
    cue = lastDecision.method==='explore'?'explore'
      : lastDecision.place!==lastDecision.noHintPlace?'hint'
      : lastDecision.place!==lastDecision.mutedPlace?'listen':'forage';
    summary = `正走向${PLACES[current.place].name}。`;
  } else if (phase==='homebound') {
    cue = 'return';
    summary = `在${PLACES[current.place].name}${outcome(current.reward)}，正在回营地。`;
  } else if (incoming) {
    cue = 'listen';
    summary = `在营地休息，第 ${incoming.tick} 步看见${NAMES[incoming.sender]}比了一个 ${incoming.glyph}。`;
  } else if (hint) {
    cue = 'hint';
    summary = `在营地休息，还记着你对${PLACES[hint.place].name}的提醒。`;
  }
  if (hint && (phase!=='rest' || incoming)) details.push(`下一趟觅食前还有对${PLACES[hint.place].name}的提醒。`);
  for (const visit of trips.filter(trip=>trip.arrived!==null).slice(-2).reverse()) {
    details.push(`第 ${visit.arrived} 步亲历：在${PLACES[visit.place].name}${outcome(visit.reward)}。`);
  }
  details.push(...decisionNotes(lastDecision,phase));
  return {cue,summary,details,decision:structuredClone(lastDecision),growth:growthView(person.achievements)};
}

export function step(world) {
  if (world.tick>=MAX_TICK) return false;
  world.tick++;
  updatePlaces(world);
  if (world.hint?.status==='pending' && world.tick-world.hint.tick>HINT_TTL) {
    world.hint.status = 'expired';
    emit(world,'hintExpired','小岚还没再次出发，这条地点建议已经过时。',{actor:'B',place:world.hint.place});
  }
  const people = Object.values(world.residents);
  for (const person of people) observe(person,world);
  exchangeFeedback(world);
  for (const person of people) localContact(world,person);
  for (const person of people) act(world,person);
  return true;
}

export function* replayProgress({version,seed,tick,input}, chunkSize=512) {
  if (version!==RULE_VERSION || !Number.isSafeInteger(tick) || tick<0
      || (input!==null && (!input || !Number.isSafeInteger(input.tick) || input.tick<0 ||
                           input.tick>tick || !SITES.includes(input.place)))) {
    throw new RangeError('这份重放的版本、步数或玩家输入无效。');
  }
  if (!Number.isSafeInteger(chunkSize) || chunkSize<1) throw new RangeError('重放批次大小无效。');
  const world = createWorld(seed);
  while (true) {
    if (input?.tick===world.tick) suggest(world,input.place);
    if (world.tick===tick || (world.tick>0 && world.tick%chunkSize===0)) yield world;
    if (world.tick===tick) return;
    step(world);
  }
}

export function replay(recipe) {
  let result;
  for (const world of replayProgress(recipe)) result = world;
  return result;
}
