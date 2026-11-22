// Rebuild the fixed held-seed receipt with: node living_world/studies/w6-signals.mjs
import {writeFile} from 'node:fs/promises';
import {createWorld, GLYPHS, RULE_VERSION, step} from '../web/w6/world.mjs';

const SEEDS = Array.from({length:32},(_,index)=>1601+index);
const CHANNELS = ['normal','muted','permuted'];
const WARMUP = 2000;
const END = 4000;
const MEASURES = ['trips','totalReward','glyphSent','glyphHeard','silence','glyphChoices',
                  'changedChoices','senderFeedback','feedbackExpired'];

function interval(after,before,keys) {
  return Object.fromEntries(keys.map(key=>[key,(after[key]??0)-(before[key]??0)]));
}

function stableContexts(after,before) {
  let eligible=0, sameDominantGlyph=0;
  for (const [context, all] of Object.entries(after)) {
    const first = before[context] ?? {};
    const second = interval(all,first,['',...GLYPHS]);
    const strongest = counts => {
      const entries = Object.entries(counts).sort((a,b)=>b[1]-a[1]);
      const total = entries.reduce((sum,[,count])=>sum+count,0);
      return {total,action:entries[0]?.[0],share:total?entries[0][1]/total:0};
    };
    const a = strongest(first), b = strongest(second);
    if (a.total<8 || b.total<8) continue;
    eligible++;
    if (a.action && a.action===b.action && a.share>=0.6 && b.share>=0.6) sameDominantGlyph++;
  }
  return {eligible,sameDominantGlyph};
}

function run(seed,channel) {
  const world = createWorld(seed,{channel});
  while (world.tick<WARMUP) step(world);
  const first = structuredClone(world.stats);
  while (world.tick<END) step(world);
  const stats = interval(world.stats,first,MEASURES);
  return {
    ...stats, meanReward:stats.totalReward/stats.trips,
    byGlyph:interval(world.stats.byGlyph,first.byGlyph,GLYPHS),
    contextStability:stableContexts(world.stats.byContext,first.byContext),
  };
}

const seeds = SEEDS.map(seed=>({seed, ...Object.fromEntries(
  CHANNELS.map(channel=>[channel,run(seed,channel)]))}));
const sum = (items, key) => items.reduce((total,row)=>total+row[key],0);
const aggregate = Object.fromEntries(CHANNELS.map(channel=>{
  const rows=seeds.map(seed=>seed[channel]);
  const counts=Object.fromEntries(MEASURES.map(key=>[key,sum(rows,key)]));
  return [channel,{
    ...counts, meanReward:counts.totalReward/counts.trips,
    meanRewardPerSeed:sum(rows,'meanReward')/seeds.length,
    changedPerHeardDeparture:counts.glyphChoices ? counts.changedChoices/counts.glyphChoices : 0,
    byGlyph:Object.fromEntries(GLYPHS.map(glyph=>[glyph,sum(rows.map(row=>row.byGlyph),glyph)])),
    contextStability:{
      eligible:sum(rows.map(row=>row.contextStability),'eligible'),
      sameDominantGlyph:sum(rows.map(row=>row.contextStability),'sameDominantGlyph'),
    },
  }];
}));
const paired = Object.fromEntries(CHANNELS.slice(1).map(channel=>{
  const deltas = seeds.map(seed=>seed.normal.meanReward-seed[channel].meanReward);
  return [channel,{
    meanDelta:deltas.reduce((a,b)=>a+b,0)/deltas.length,
    positive:deltas.filter(x=>x>0).length, equal:deltas.filter(x=>x===0).length,
    negative:deltas.filter(x=>x<0).length,
  }];
}));
const receipt = {
  ruleVersion:RULE_VERSION, seedSelection:'All seeds 1601–1632, contiguous held-out range',
  warmup:WARMUP, end:END,
  definitions:{
    outcomes:'Real food arrivals in the evaluation interval (including unavailable food with reward zero).',
    normal:'Original glyph received. Sender and listener learn online.',
    muted:'Sender still chooses a glyph or silence and gets local feedback; listeners receive no glyph. Replay learns independently from tick zero.',
    permuted:'Independently permute glyph identities at each contact, without changing silence; online learners are retained.',
    changedChoices:'At the actual departure, mask only that listener’s glyph in the frozen state and reuse the same exploration and tie-breaking draws. Count a changed destination; the alternative was not executed.',
    contextStability:'For sender–receiver–latest site–reward sign contexts with eight or more observed contact actions in both intervals, count contexts with the same non-silent modal action at 60% or more in both. Includes silence in the denominator and measures sender behavior, not listener decoding.',
  },
  aggregate, pairedNormalMinus:paired, seeds,
};
await writeFile(new URL('../../docs/sim/living-world/w6/review/signals.json',import.meta.url),
                JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify({aggregate,paired},null,2));
