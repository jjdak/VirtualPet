"""Compare clock- and departure-indexed random coupling from every original W3 fork."""
import argparse
from contextlib import contextmanager
from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from w3_long import ARCHIVE, OUTPUT as LONG, END, SIDES, rebuild
from w3_influence import ROOT, compact, write_file
from fork_study import ContextWorld, SilentWorld, Differences, body, origin_hash, peer_reports
from context_world import WeatherResident
import world as runtime

OUT = ROOT/'docs/sim/living-world/w3-coupling/review'
CHOOSE = WeatherResident.choose
RANDOM = runtime.random.Random
MODES = ('clock', 'departure')
KEYS = ('family','seed','age','actor','kind')
TAIL = END-480


def key(row):
    return tuple(row[k] for k in KEYS)


def draws(seed, actor, index):
    rng = RANDOM(seed*100003 + index*97 + (17 if actor=='B' else 0))
    return [rng.random(),rng.random()]


@contextmanager
def fixed_random(values):
    stream = iter(values)
    replacement = SimpleNamespace(Random=lambda _:SimpleNamespace(random=lambda:next(stream)))
    with patch.object(runtime,'random',replacement):
        yield


@contextmanager
def instrument(mode, events, start):
    def choose(person, seed, tick):
        ordinal = person.decisions+1
        randoms = draws(seed, person.name, ordinal if mode=='departure' else tick)
        counts = person.brain.counts
        if mode=='departure':
            with fixed_random(randoms):
                target = CHOOSE(person, seed, tick)
        else:
            target = CHOOSE(person,seed,tick)
        if target:
            choice = person.last_choice
            eligible = list(choice['scores'])
            route = ('unknown' if any(counts[k]==0 for k in eligible) else
                     'explore' if randoms[0]<runtime.CONFIG['epsilon'] else 'estimated_value')
            events.get(id(person),events)[person.name].append(dict(n=ordinal,t=tick-start,weather=person.weather,
                target=target,draws=randoms,route=route,scores=deepcopy(choice['scores'])))
        return target
    with patch.object(WeatherResident,'choose',choose):
        yield


def greedy(person, seed, tick):
    copy = deepcopy(person)
    with fixed_random([.5,.25]), patch.dict(runtime.CONFIG,epsilon=0.0):
        target = CHOOSE(copy,seed,tick)
    return dict(target=target,scores=copy.last_choice['scores'] if target else {})


def memory(left, right, name):
    a,b = (w.residents[name] for w in (left,right))
    banks = {w:{left.weather:p.brain,
              'rain' if left.weather=='sun' else 'sun':w.reserve[name][0]}
             for w,p in ((left,a),(right,b))}
    by_weather = {}
    for weather in ('sun','rain'):
        x,y = (banks[w][weather] for w in (left,right))
        content = lambda brain:{k:(m['source'],m['claim']) for k,m in brain.inbox.items()}
        by_weather[weather] = dict(value_max_gap=max(abs(x.values[k]-y.values[k]) for k in runtime.FOODS),
            counts_equal=x.counts==y.counts, trust_gap=abs(x.trust()-y.trust()),
            message_content_equal=content(x)==content(y),message_records_equal=x.inbox==y.inbox)
    g = {s:greedy(w.residents[name],w.seed,w.tick) for s,w in zip(SIDES,(left,right))}
    return dict(by_weather=by_weather,
                value_difference=any(v['value_max_gap']>1e-9 for v in by_weather.values()),
                count_difference=any(not v['counts_equal'] for v in by_weather.values()),
                greedy=g,greedy_difference=g['control']['target']!=g['hinted']['target'])


def alignment(left, right, mode):
    assert all(b['n']==a['n']+1 for seq in (left,right) for a,b in zip(seq,seq[1:]))
    pairs = list(zip(left,right))
    assert all(a['n']==b['n'] for a,b in pairs)
    if mode=='departure':
        assert all(a['draws']==b['draws'] for a,b in pairs)
    def stat(rows):
        wrong = [(a,b) for a,b in rows if a['target']!=b['target']]
        return dict(matched=len(rows),different=len(wrong),
            weather_different=sum(a['weather']!=b['weather'] for a,b in rows),
            destination_different_same_weather=sum(a['weather']==b['weather'] for a,b in wrong),
            destination_different_other_weather=sum(a['weather']!=b['weather'] for a,b in wrong),
            timing_different=sum(a['t']!=b['t'] for a,b in rows),
            max_abs_lag=max((abs(a['t']-b['t']) for a,b in rows),default=0),
            examples=[dict(control=a,hinted=b) for a,b in wrong[:2]])
    tail = [(a,b) for a,b in pairs if min(a['t'],b['t'])>TAIL]
    extra = left[len(pairs):]+right[len(pairs):]
    return dict(all=stat(pairs),tail=stat(tail),
                counts=[len(left),len(right)],unpaired=len(extra),
                tail_unpaired=sum(x['t']>TAIL for x in extra),
                tail_cross_boundary=sum(min(a['t'],b['t'])<=TAIL<max(a['t'],b['t']) for a,b in pairs))


def run_pair(snapshot, actor, kind, mode, social=True, end=END):
    model = ContextWorld if social else SilentWorld
    worlds = {s:model.restore(snapshot) for s in SIDES}
    if kind is not None:
        worlds['hinted'].hint(actor,kind)
    start = snapshot['active']['tick']
    trackers = {n:Differences() for n in runtime.NAMES}
    events = {s:{n:[] for n in runtime.NAMES} for s in SIDES}
    peer = 'B' if actor=='A' else 'A'
    hint_end = message_first = at240 = None
    sinks={id(p):events[side] for side,w in worlds.items() for p in w.residents.values()}
    with instrument(mode,sinks,start):
        for offset in range(1,end+1):
            for side,w in worlds.items():
                w.step()
            l,r = (worlds[s] for s in SIDES)
            assert l.tick==r.tick==start+offset and l.weather==r.weather
            if kind is not None and hint_end is None and r.residents[actor].hints[-1]['status']!='pending':
                hint_end=offset
            if social and message_first is None and peer_reports(l,peer)!=peer_reports(r,peer):
                message_first=offset
            for n,tracker in trackers.items():
                tracker.observe(body(l.residents[n],l.tick),body(r.residents[n],r.tick),offset,hint_end,l.weather)
            if offset==240:
                at240=deepcopy({n:compact(t.summary(offset)) for n,t in trackers.items()})
    people = {}
    for n,t in trackers.items():
        behavior=compact(t.summary(end))
        behavior['same_final160']=t.steps==0 or t.intervals[-1][1]<=end-160
        people[n]=dict(behavior=behavior,aligned=alignment(events['control'][n],events['hinted'][n],mode),
                       memory=memory(worlds['control'],worlds['hinted'],n))
    return dict(at240=at240,hint_end=hint_end,message_first=message_first,people=people),events


def source_rows():
    return ([dict(family='primary',**json.loads(s)) for s in (ARCHIVE/'pairs.jsonl').read_text().splitlines()]
            +[dict(family='reversal',**r) for r in json.loads((ARCHIVE/'reversal.json').read_text())['pairs']])


def study(row, old_long=None, end=END):
    snapshot=rebuild(row['family'],row)
    assert origin_hash(snapshot)==row['origin_hash']
    results={}
    traces={}
    peer='B' if row['actor']=='A' else 'A'
    for mode in MODES:
        normal,events=run_pair(snapshot,row['actor'],row['kind'],mode,end=end)
        silent,_=run_pair(snapshot,row['actor'],row['kind'],mode,False,end=end)
        if end>=240 and mode=='clock':
            for role,n in [('recipient',row['actor']),('peer',peer)]:
                assert normal['at240'][n]==row[role], (key(row),role)
            assert silent['at240'][peer]['steps']==row['silent_peer_steps']
            assert normal['hint_end']==row['hint_end'] and normal['message_first']==row['message_first']
            if old_long and end==END:
                for n,p in old_long['people'].items():
                    assert normal['people'][n]['behavior']['at_end']==p['behavior_different_at_end']
                    assert normal['people'][n]['behavior']['same_final160']==p['behavior_same_final160']
        # In this world, communication is the only route for a hint to affect the peer.
        assert silent['people'][peer]['behavior']['steps']==0
        for n,p in normal['people'].items():
            p['silent_behavior']=silent['people'][n]['behavior']
            p['silent_greedy_difference']=silent['people'][n]['memory']['greedy_difference']
            p['silent_aligned_differences']=silent['people'][n]['aligned']['all']['different']
        first=normal['people'][peer]['behavior']['first']
        normal['communication_dependent_peer']=(first is not None and normal['message_first'] is not None
                                               and normal['message_first']<first)
        results[mode]=normal
        traces[mode]=events
    return dict(**{k:row[k] for k in KEYS},origin_hash=row['origin_hash'],modes=results),traces


def relay_history(row, result):
    """Reproduce the first registered peer example through its first different choice."""
    peer='B' if row['actor']=='A' else 'A'
    example=result['modes']['departure']['people'][peer]['aligned']['all']['examples'][0]
    stop=max(example[side]['t'] for side in SIDES)
    snapshot=rebuild(row['family'],row)
    branches={}
    for side in SIDES:
        w=ContextWorld.restore(snapshot)
        if side=='hinted':
            w.hint(row['actor'],row['kind'])
        events={n:[] for n in runtime.NAMES}
        with instrument('departure',events,row['age']):
            while w.tick<row['age']+stop:
                w.step()
        branches[side]={n:[e for e in p.history if e['tick']>row['age']]
                        for n,p in w.residents.items()}
    return dict(case={k:row[k] for k in KEYS},stop=stop,peer=peer,
                paired_choice=example,history=branches)


def aggregate(rows,mode):
    result=dict(pairs=len(rows),communication_dependent_peer=sum(r['modes'][mode]['communication_dependent_peer'] for r in rows))
    for role in ('recipient','peer'):
        people=[]
        at240=[]
        for r in rows:
            n=r['actor'] if role=='recipient' else ('B' if r['actor']=='A' else 'A')
            people.append(r['modes'][mode]['people'][n])
            at240.append(r['modes'][mode]['at240'][n])
        result[role]=dict(ever_body_different=sum(p['behavior']['steps']>0 for p in people),
            body_different_at240=sum(p['at_end'] for p in at240),
            body_different_at2640=sum(p['behavior']['at_end'] for p in people),
            body_different_final160=sum(not p['behavior']['same_final160'] for p in people),
            ordinal_choice_difference=sum(p['aligned']['all']['different']>0 for p in people),
            tail_ordinal_choice_difference=sum(p['aligned']['tail']['different']>0 for p in people),
            tail_choice_pairs=sum(p['aligned']['tail']['matched'] for p in people),
            tail_choice_mismatches=sum(p['aligned']['tail']['different'] for p in people),
            tail_same_weather_mismatches=sum(p['aligned']['tail']['destination_different_same_weather'] for p in people),
            tail_other_weather_mismatches=sum(p['aligned']['tail']['destination_different_other_weather'] for p in people),
            tail_unpaired=sum(p['aligned']['tail_unpaired'] for p in people),
            tail_cross_boundary=sum(p['aligned']['tail_cross_boundary'] for p in people),
            tail_empty_pairs=sum(p['aligned']['tail']['matched']==0 for p in people),
            final_own_values_different=sum(p['memory']['value_difference'] for p in people),
            final_counts_different=sum(p['memory']['count_difference'] for p in people),
            final_greedy_choices_different=sum(p['memory']['greedy_difference'] for p in people),
            silent_body_different=sum(p['silent_behavior']['steps']>0 for p in people))
    result['either_body_different_at2640']=sum(any(p['behavior']['at_end'] for p in r['modes'][mode]['people'].values()) for r in rows)
    result['either_tail_ordinal_choice_difference']=sum(any(p['aligned']['tail']['different'] for p in r['modes'][mode]['people'].values()) for r in rows)
    return result


def run(output=OUT,limit=None):
    output.mkdir(parents=True,exist_ok=True)
    originals=source_rows()
    if limit is not None:
        originals=originals[:limit]
    old={key(c):c for c in map(json.loads,(LONG/'cases.jsonl').read_text().splitlines())}
    rows=[]
    examples=[]
    first_peer=False
    with (output/'cases.jsonl').open('w') as f:
        for i,row in enumerate(originals):
            result,traces=study(row,old.get(key(row)))
            rows.append(result)
            f.write(json.dumps(result,ensure_ascii=False,separators=(',',':'))+'\n')
            registered=(row['family']=='reversal' and row['age']==480 and row['kind']=='q'
                        and (row['seed'],row['actor']) in ((15,'B'),(19,'A'),(19,'B')))
            first=(not first_peer and result['modes']['departure']['communication_dependent_peer'])
            if registered or first:
                examples.append(dict(key={k:row[k] for k in KEYS},registered=registered,first_peer=first,trips=traces))
            if first:
                write_file(output/'relay-history.json',relay_history(row,result))
            first_peer=first_peer or first
            if (i+1)%32==0 or i+1==len(originals):
                print(f'completed {i+1}/{len(originals)}',flush=True)
    summary=dict(end=END,tail_begin=TAIL+1,modes=list(MODES),pairs=len(rows),world_trajectories=len(rows)*8,
        source_sha256={str(p.relative_to(ROOT)):sha256(p.read_bytes()).hexdigest() for p in (
            ARCHIVE/'pairs.jsonl',ARCHIVE/'reversal.json',LONG/'cases.jsonl',
            ROOT/'living_world/src/world.py',ROOT/'living_world/src/context_world.py',
            ROOT/'experiments/adaptive_agents/src/core.py')},
        families={family:{mode:aggregate([r for r in rows if r['family']==family],mode) for mode in MODES}
                  for family in ('primary','reversal') if any(r['family']==family for r in rows)},
        cases_sha256=sha256((output/'cases.jsonl').read_bytes()).hexdigest())
    write_file(output/'summary.json',summary)
    write_file(output/'examples.json',examples)
    print(json.dumps(summary['families'],ensure_ascii=False),flush=True)
    return rows,summary


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=OUT)
    parser.add_argument('--limit',type=int)
    args=parser.parse_args()
    run(args.output,args.limit)
