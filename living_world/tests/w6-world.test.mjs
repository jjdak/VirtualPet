import assert from 'node:assert/strict';
import test from 'node:test';

import {
  RULE_VERSION, MAX_TICK, GLYPHS, PLACES, cloneWorld, createWorld,
  mindView, replay, replayProgress, step, suggest,
} from '../web/w6/world.mjs';

const until = (world,tick) => {
  while (world.tick<tick) step(world);
  return world;
};
const recipe = world => ({
  version:world.version,seed:world.seed,tick:world.tick,input:world.input,
});
const manhattan = (a,b) => Math.abs(a.x-b.x)+Math.abs(a.y-b.y);

test('four independently seeded resident traits drive movement, sight and exploration',()=>{
  const world=createWorld(7);
  assert.equal(Object.keys(world.residents).length,4);
  assert.notDeepEqual(world.residents.A.traits,world.residents.B.traits);
  assert.notDeepEqual(world.residents.A.traits,createWorld(8).residents.A.traits);
  const slow=world.residents.A;
  assert.equal(slow.traits.speed,2);
  until(world,slow.readyAt);
  const start={x:slow.x,y:slow.y};
  step(world);
  assert.equal(manhattan(start,slow),0);
  step(world);
  assert.equal(manhattan(start,slow),1);
  const firstMove={x:slow.x,y:slow.y};
  step(world);
  assert.equal(manhattan(firstMove,slow),0);
  step(world);
  assert.equal(manhattan(firstMove,slow),1);

  const narrow=createWorld(1);
  narrow.residents.A.x=5;
  narrow.residents.A.y=2;
  const farSighted=cloneWorld(narrow);
  narrow.residents.A.traits.sight=1;
  farSighted.residents.A.traits.sight=3;
  step(narrow);
  step(farSighted);
  assert.equal(narrow.residents.A.seen.p,undefined);
  assert.deepEqual(farSighted.residents.A.seen.p,
                   {tick:1,available:farSighted.places.p.available});

  const picks=[];
  for (let seed=0;seed<16;seed++) {
    const cautious=createWorld(seed);
    const curious=cloneWorld(cautious);
    const [c,d]=[cautious.residents.B,curious.residents.B];
    c.traits.curiosity=0;
    d.traits.curiosity=1;
    picks.push([until(cautious,c.readyAt).residents.B.target,
                until(curious,d.readyAt).residents.B.target]);
  }
  assert(picks.some(([c,d])=>c!==d));
});

test('paths stay inside the map, avoid walls, and emit actual arrivals and return legs',()=>{
  const world=createWorld(42);
  const walls=new Set(world.map.walls.map(([x,y])=>`${x},${y}`));
  const tastes=new Set(), supply=new Set();
  for(let i=0;i<500;i++){
    const previous=Object.fromEntries(Object.entries(world.residents).map(([id,p])=>[id,{x:p.x,y:p.y}]));
    step(world);
    const place=world.places.p;
    tastes.add(place.effect);
    supply.add(place.available);
    for(const person of Object.values(world.residents)){
      assert(manhattan(previous[person.id],person)<=1);
      assert(person.x>=0&&person.x<world.map.width&&person.y>=0&&person.y<world.map.height);
      assert(!walls.has(`${person.x},${person.y}`));
      const trip=person.trips.at(-1);
      if(trip?.arrived===world.tick){
        assert.equal(manhattan(person,PLACES[trip.place]),0);
        assert.equal(person.phase,'homebound');
      }
      if(trip?.returned===world.tick){
        assert.equal(manhattan(person,world.map.homes[person.id]),0);
        assert.equal(person.phase,'rest');
      }
    }
  }
  assert.equal(tastes.size,2);
  assert.equal(supply.size,2);
  assert(world.stats.trips>50);
  assert(Object.values(world.residents).every(person=>person.tripCount>10));
});

test('seeded hint changes the next destination in a same-tick independent fork',()=>{
  const waiting=createWorld(42);
  const actual=cloneWorld(waiting);
  const {readyAt}=actual.residents.B;
  assert(suggest(actual,'q'));
  assert(!suggest(actual,'p'));
  assert.equal(actual.hint.status,'pending');
  assert.equal(waiting.hint,null);
  assert.deepEqual(waiting.residents,actual.residents);
  until(waiting,readyAt);
  until(actual,readyAt);
  assert.equal(actual.residents.B.trips[0].place,'q');
  assert.equal(waiting.residents.B.trips[0].place,'r');
  assert.equal(actual.hint.usedAt,readyAt);
  assert.equal(actual.hint.status,'used');
  assert(!suggest(actual,'q'));
  assert.deepEqual(actual.places,waiting.places);
});

test('a reminder given during a long trip can expire without forcing departure',()=>{
  const waiting=createWorld(3);
  const start=waiting.residents.B.readyAt;
  until(waiting,start);
  const actual=cloneWorld(waiting);
  assert.equal(actual.residents.B.phase,'outbound');
  assert(suggest(actual,'q'));
  until(actual,start+24);
  assert.equal(actual.hint.status,'pending');
  step(actual);
  assert.equal(actual.hint.status,'expired');
  until(waiting,actual.tick);
  assert.deepEqual(actual.residents,waiting.residents);
  assert(actual.events.some(event=>event.type==='hintExpired'&&event.tick===start+25));
});

test('addressed replay rebuilds full consumed and expired states plus same-tick pending input',()=>{
  for(const [seed,inputTick,end] of [[42,0,1400],[3,4,75],[21,116,116],[17,500,501]]){
    const world=until(createWorld(seed),inputTick);
    suggest(world,'q');
    until(world,end);
    assert.deepEqual(replay(recipe(world)),world);
    const ticks=[];
    let result;
    for(const frame of replayProgress(recipe(world),153)){
      ticks.push(frame.tick);
      result=frame;
    }
    assert.equal(ticks.at(-1),end);
    assert(ticks.every((tick,i)=>i===0||tick>ticks[i-1]));
    assert.deepEqual(result,world);
  }
});

test('clone isolation includes mutable learnings, routes, counters, and trip and event rings',()=>{
  const actual=until(createWorld(1632),1600);
  const waiting=cloneWorld(actual);
  const pristine=JSON.stringify(waiting);
  suggest(actual,'p');
  step(actual);
  actual.residents.B.preferences.q.mean=123;
  actual.residents.B.trips[0].reward=456;
  actual.events[0].text='changed';
  actual.map.walls[0][0]=99;
  actual.stats.byGlyph[GLYPHS[0]]=0;
  assert.equal(JSON.stringify(waiting),pristine);
  for(const person of Object.values(waiting.residents)){
    assert(person.trips.length<=24);
    assert(person.tripCount>24);
  }
  assert(waiting.events.length<=64);
  assert(JSON.stringify(waiting).length<60000);
});

test('glyph contents reveal no lookup key and evidence is learned from own arrival only',()=>{
  const world=createWorld(1608);
  assert.deepEqual(Object.values(world.residents).map(p=>Object.keys(p.listening)),[[],[],[],[]]);
  let firstTick;
  let listener;
  for(let i=0;i<160;i++){
    step(world);
    listener=Object.values(world.residents).find(p=>p.incoming);
    if(listener){firstTick=world.tick;break;}
  }
  assert.equal(typeof firstTick,'number');
  assert.deepEqual(Object.keys(listener.incoming).sort(),['glyph','sender','tick']);
  assert(GLYPHS.includes(listener.incoming.glyph));
  assert.deepEqual(listener.listening,{});
  const fields=[listener.incoming.sender,listener.incoming.glyph];
  while(!Object.keys(listener.listening).length) step(world);
  const trip=listener.trips.at(-1);
  const key=[...fields,trip.place].join('/');
  assert.equal(listener.listening[key].lastTick,trip.arrived);
  assert.equal(listener.listening[key].mean,trip.reward);
});

test('sender feedback is earned only through a local encounter and can go unseen',()=>{
  const near=createWorld(41);
  const far=cloneWorld(near);
  far.residents.A.x=0;
  far.residents.A.y=0;
  for(const world of [near,far]){
    world.residents.A.readyAt=30;
    world.feedback.B={sender:'A',context:'B/q/+',action:GLYPHS[0],reward:1,until:2};
  }
  step(near);
  step(far);
  assert.equal(near.residents.A.sending[`B/q/+/${GLYPHS[0]}`].mean,1);
  assert.equal(near.stats.senderFeedback,1);
  assert.deepEqual(far.residents.A.sending,{});
  until(far,3);
  assert.equal(far.stats.feedbackExpired,1);
  assert.deepEqual(far.residents.A.sending,{});
});

test('muting and per-contact permutation preserve real trips and isolate receiving information',()=>{
  const normal=until(createWorld(1608),1600);
  const muted=until(createWorld(1608,{channel:'muted'}),1600);
  const permuted=until(createWorld(1608,{channel:'permuted'}),1600);
  assert.equal(muted.stats.glyphHeard,0);
  assert.equal(muted.stats.changedChoices,0);
  assert(muted.stats.glyphSent>0);
  assert(muted.stats.silence>0);
  assert(muted.stats.senderFeedback>0);
  assert.deepEqual(Object.values(muted.residents).map(p=>Object.keys(p.listening)),[[],[],[],[]]);
  assert(normal.stats.changedChoices>0 && permuted.stats.glyphHeard>0);
  assert.notDeepEqual(normal.stats.byGlyph,permuted.stats.byGlyph);
  assert.deepEqual(normal.places,muted.places);
  assert(normal.residents.B.trips.some(trip=>GLYPHS.includes(trip.glyph)));
});

test('validation rejects corrupt recipes and engine keeps stepping after 100000',()=>{
  const valid={version:RULE_VERSION,seed:1,tick:0,input:null};
  for(const update of [{version:-1},{seed:-1},{tick:1.5},{tick:-1},{tick:MAX_TICK+1},
                        {input:{tick:1,place:'p'}},{input:{tick:0,place:'X'}}]){
    assert.throws(()=>replay({...valid,...update}),RangeError);
  }
  const world=createWorld(7);
  assert.equal(suggest(world,'X'),false);
  assert.equal(world.input,null);
  world.tick=100000;
  assert.equal(step(world),true);
  assert.equal(world.tick,100001);
});

test('thought details expose actual choices, frozen alternatives and previous observations',()=>{
  const world=createWorld(42);
  assert.deepEqual(mindView(world,'B').details,[]);
  assert.equal(mindView(world,'B').cue,'rest');
  suggest(world,'q');
  assert.equal(mindView(world,'B').cue,'hint');
  until(world,world.residents.B.readyAt);
  const view=mindView(world,'B');
  assert.equal(view.cue,'hint');
  assert.equal(view.decision.method,'score');
  assert.equal(view.decision.place,'q');
  assert.equal(view.decision.noHintPlace,'r');
  assert.equal(view.decision.mutedPlace,'q');
  assert.deepEqual(view.decision.hint,{place:'q',tick:0});
  assert(view.decision.known.q.score>view.decision.known.r.score);
  assert.equal(view.decision.known.q.firsthand.count,0);
  assert.equal(view.decision.known.q.supply,null);
  assert.match(view.details.at(-1),/改选红果地/);
  view.decision.known.q.firsthand.count=42;
  while(world.residents.B.phase!=='homebound') step(world);
  const returned=mindView(world,'B');
  assert.equal(returned.cue,'return');
  assert.notEqual(world.residents.B.preferences.q.count,0);
  assert.equal(returned.decision.known.q.firsthand.count,0);
  assert(returned.details.some(line=>line.includes('亲历') && line.includes('紫穗地')));

  const exploration=createWorld(42);
  exploration.residents.B.traits.curiosity=1;
  suggest(exploration,'q');
  until(exploration,exploration.residents.B.readyAt);
  const exploratory=mindView(exploration,'B');
  assert.equal(exploratory.cue,'explore');
  assert.equal(exploratory.decision.place,exploratory.decision.noHintPlace);
  assert(exploratory.details.some(line=>line.includes('触发了探索')));
  assert(Object.values(exploratory.decision.known).every(item=>item.score===null));
});

test('actor-specific growth follows actual travel, food and symbol decisions in each branch',()=>{
  const waiting=createWorld(42);
  const actual=cloneWorld(waiting);
  const growth=(world,id='B')=>mindView(world,id).growth;
  assert.equal(growth(waiting).earned,0);
  suggest(actual,'q');
  until(waiting,14);
  until(actual,14);
  assert.equal(growth(waiting).earned,0);
  step(waiting);
  step(actual);
  assert.equal(growth(waiting).milestones[0].earnedAt,15);
  assert.equal(growth(waiting,'A').earned,0);
  assert.equal(growth(actual).earned,0);

  until(waiting,45);
  assert.equal(growth(waiting).milestones[1].earnedAt,45);
  assert.equal(growth(waiting).milestones[1].progress,3);
  until(waiting,185);
  assert.equal(growth(waiting).milestones[2].earnedAt,null);
  step(waiting);
  assert.equal(growth(waiting).milestones[2].earnedAt,186);
  const {decision,cue}=mindView(waiting,'B');
  assert.equal(cue,'listen');
  assert.equal(decision.place,'p');
  assert.equal(decision.mutedPlace,'q');
  assert.equal(decision.incoming.sender,'C');
  assert(decision.known.p.symbol.count>0);
  assert.equal(growth(until(actual,186)).earned,2);

  const earned=growth(waiting);
  until(waiting,1600);
  assert(waiting.residents.B.trips[0].returned>186);
  assert.deepEqual(growth(waiting),earned);
  assert.deepEqual(growth(replay(recipe(waiting))),earned);
  assert.equal(growth(replay({version:RULE_VERSION,seed:42,tick:0,input:null})).earned,0);
});
