"""Diagnose count and phase differences in the 26 departure-coupled endpoint pairs."""
import argparse
from collections import Counter
from copy import deepcopy
from hashlib import sha256
import json
import math
from pathlib import Path
from unittest.mock import patch

from w3_coupling import (OUT as COUPLING, END, SIDES, ContextWorld, WeatherResident,
                        instrument, key, rebuild, source_rows, study, runtime, write_file)
from w3_influence import ROOT
from fork_study import body, origin_hash

OUT=ROOT/'docs/sim/living-world/w3-rhythm/review'
STOP=END+600
BODY_FIELDS=('pos','phase','target','hunger','energy','next_departure')


def physical(r):
    return (tuple(r.pos),r.phase,r.target if r.phase=='outbound' else None,r.hunger,r.energy)


def equivalent(a,b):
    return a[:3]==b[:3] and all(math.isclose(x,y,abs_tol=1e-8,rel_tol=0) for x,y in zip(a[3:],b[3:]))


def predicted_lag(a,b):
    """Exact hunger ledger identity at the two same-ordinal departures."""
    x,y=a['ledger'],b['ledger']
    return (38*(y['good']-x['good'])+14*(y['bad']-x['bad'])
            +y['upper_loss']-x['upper_loss']-y['lower_gain']+x['lower_gain']
            +b['hunger']-a['hunger'])/.8


def synchronize(left,right,ordinal=False):
    """A one-time study intervention. Keep evidence, including personal food counts."""
    def evidence(w):
        return dict(active={n:{k:v for k,v in r.snapshot().items()
                               if k not in (*BODY_FIELDS,'decisions')}
                            for n,r in w.residents.items()},reserve=w.snapshot()['reserve'])
    before=evidence(right)
    for n,r in right.residents.items():
        source=left.residents[n]
        for field in BODY_FIELDS+(('decisions',) if ordinal else ()):
            setattr(r,field,deepcopy(getattr(source,field)))
    assert evidence(right)==before


def continuation(snapshots,mode):
    worlds={s:ContextWorld.restore(snapshots[s]) for s in SIDES}
    if mode!='natural':
        synchronize(worlds['control'],worlds['hinted'],mode=='body_and_ordinal')
    events={s:{n:[] for n in runtime.NAMES} for s in SIDES}
    sinks={id(p):events[s] for s,w in worlds.items() for p in w.residents.values()}
    stats={n:dict(different_steps=0,first=None,last=None,simultaneous_choice_splits=0) for n in runtime.NAMES}
    start=worlds['control'].tick
    with instrument('departure',sinks,start):
        for t in range(1,601):
            for w in worlds.values():
                w.step()
            for n,out in stats.items():
                a,b=(body(w.residents[n],w.tick) for w in worlds.values())
                if any(a[k]!=b[k] for k in ('pos','phase','target')):
                    out['different_steps']+=1
                    out['first']=t if out['first'] is None else out['first']
                    out['last']=t
                out['simultaneous_choice_splits']+=bool(a['choice'] and b['choice'] and a['choice']!=b['choice'])
    for n in runtime.NAMES:
        stats[n]['different_at_end']=stats[n]['last']==600
        # The nth post-probe choices are descriptive; absolute ordinals are retained in events.
        a,b=(events[s][n] for s in SIDES)
        stats[n]['departure_counts']=[len(a),len(b)]
        stats[n]['sequence_differences']=sum(x['target']!=y['target'] for x,y in zip(a,b))
    return dict(people=stats,end_hashes={s:origin_hash(w.snapshot()) for s,w in worlds.items()})


def replay(row):
    snapshot=rebuild(row['family'],row)
    assert origin_hash(snapshot)==row['origin_hash']
    histories={}
    endpoints={}
    endpoint_snapshots={}
    final_hashes={}
    for side in SIDES:
        w=ContextWorld.restore(snapshot)
        if side=='hinted':
            w.hint(row['actor'],row['kind'])
        start=w.tick
        initial={n:r.hunger for n,r in w.residents.items()}
        books={n:dict(good=0,bad=0,upper_loss=0.0,lower_gain=0.0) for n in runtime.NAMES}
        trips={n:[] for n in runtime.NAMES}
        frames={n:{} for n in runtime.NAMES}
        events={n:[] for n in runtime.NAMES}
        blockers={n:[] for n in runtime.NAMES}
        with instrument('departure',events,start):
            wrapped=WeatherResident.choose
            def record(person,seed,tick):
                t=tick-start
                ledger=deepcopy(books[person.name])
                expected=(initial[person.name]+.8*t-38*ledger['good']-14*ledger['bad']
                          -ledger['upper_loss']+ledger['lower_gain'])
                assert math.isclose(person.hunger,expected,abs_tol=1e-8,rel_tol=0)
                data=dict(n=person.decisions+1,depart=t,hunger=person.hunger,energy=person.energy,
                    next_allowed=person.next_departure-start,preceding_blockers=blockers[person.name],
                    ledger=ledger,arrive_food=None,eat=None,reward=None,home=None,rest=None)
                target=wrapped(person,seed,tick)
                assert target is not None  # All registered food supplies remain open.
                data.update(target=target,route=events[person.name][-1]['route'])
                trips[person.name].append(data)
                return target
            with patch.object(WeatherResident,'choose',record):
                for t in range(1,STOP+1):
                    before={n:dict(pos=tuple(r.pos),phase=r.phase,hunger=r.hunger) for n,r in w.residents.items()}
                    for n,r in w.residents.items():
                        books[n]['upper_loss']+=max(0.0,r.hunger+.8-100)
                    w.step()
                    for n,r in w.residents.items():
                        previous=before[n]
                        journey=trips[n][-1] if trips[n] else None
                        if previous['phase']=='outbound' and r.phase=='homebound':
                            event=next(e for e in reversed(w.events) if e['type']=='experience' and e['actor']==n and e['tick']==w.tick)
                            reward=event['reward']
                            reduction=38 if reward==1 else 14
                            books[n]['good' if reward==1 else 'bad']+=1
                            books[n]['lower_gain']+=max(0.0,reduction-min(100,previous['hunger']+.8))
                            if journey:
                                journey.update(eat=t,reward=reward)
                        if journey:
                            if r.phase=='outbound' and tuple(r.pos)==runtime.FOODS[r.target] and journey['arrive_food'] is None:
                                journey['arrive_food']=t
                            if previous['phase']=='homebound' and previous['pos']!=runtime.HOMES[n] and tuple(r.pos)==runtime.HOMES[n]:
                                journey['home']=t
                            if previous['phase']=='homebound' and r.phase=='rest':
                                journey['rest']=t
                        if r.phase=='rest':
                            blockers[n]=([k for k,blocked in [('hunger',r.hunger<40),('energy',r.energy<60),
                                           ('timer',w.tick<r.next_departure)] if blocked] if previous['phase']=='rest' else ['phase'])
                        else:
                            blockers[n]=['phase']
                        frames[n][t]=physical(r)
                        expected=(initial[n]+.8*t-38*books[n]['good']-14*books[n]['bad']
                                  -books[n]['upper_loss']+books[n]['lower_gain'])
                        assert math.isclose(r.hunger,expected,abs_tol=1e-8,rel_tol=0)
                    if t==END:
                        endpoint_snapshots[side]=deepcopy(w.snapshot())
                        endpoints[side]={n:dict(pos=list(r.pos),phase=r.phase,target=r.target,
                            departures=r.decisions,postfork_departures=len(trips[n]),hunger=r.hunger,energy=r.energy,
                            latest_trip=deepcopy(trips[n][-1]),ledger=deepcopy(books[n])) for n,r in w.residents.items()}
        for journeys in trips.values():
            for a,b in zip(journeys,journeys[1:]):
                a['next_depart']=b['depart']
                a['cycle']=b['depart']-a['depart']
                a['wait_after_rest']=b['depart']-a['rest']
        histories[side]=dict(trips=trips,frames=frames,events=events)
        final_hashes[side]=origin_hash(w.snapshot())
    return histories,endpoints,endpoint_snapshots,final_hashes


def paired_trips(left,right,frames):
    pairs=[]
    for a,b in zip(left,right):
        assert a['n']==b['n']
        assert a['ledger']['good']+a['ledger']['bad']==b['ledger']['good']+b['ledger']['bad']
        lag=b['depart']-a['depart']
        prediction=predicted_lag(a,b)
        assert math.isclose(lag,prediction,abs_tol=1e-7,rel_tol=0)
        complete=all(t.get('cycle') is not None for t in (a,b))
        same_cycle=complete and a['cycle']==b['cycle']
        same_state_cycle=same_cycle and all(equivalent(frames['control'][a['depart']+j],frames['hinted'][b['depart']+j])
                                              for j in range(a['cycle']))
        pairs.append(dict(n=a['n'],control_depart=a['depart'],hinted_depart=b['depart'],lag=lag,
            same_place=a['target']==b['target'],target=[a['target'],b['target']],
            complete=complete,cycle=[a.get('cycle'),b.get('cycle')],same_state_cycle=same_state_cycle,
            bad_delta=b['ledger']['bad']-a['ledger']['bad'],predicted_lag=prediction,
            hunger_delta=b['hunger']-a['hunger'],upper_loss_delta=b['ledger']['upper_loss']-a['ledger']['upper_loss'],
            lower_gain_delta=b['ledger']['lower_gain']-a['ledger']['lower_gain']))
    return pairs


def analyze(row,archive):
    # Full prior result (both RNG modes and silent controls) must still reproduce.
    previous,traces=study(row)
    assert previous==archive
    histories,endpoints,snapshots,end_hashes=replay(row)
    for side in SIDES:
        for n in runtime.NAMES:
            assert [t for t in histories[side]['events'][n] if t['t']<=END]==traces['departure'][side][n]
    affected={n for n,p in archive['modes']['departure']['people'].items() if p['behavior']['at_end']}
    people={}
    for n in runtime.NAMES:
        a,b=(endpoints[s][n] for s in SIDES)
        actual=any(a[k]!=b[k] for k in ('pos','phase')) or (a['target'] if a['phase']=='outbound' else None)!=(b['target'] if b['phase']=='outbound' else None)
        assert actual==(n in affected)
        if n not in affected:
            continue
        trips={s:histories[s]['trips'][n] for s in SIDES}
        frames={s:histories[s]['frames'][n] for s in SIDES}
        paired=paired_trips(trips['control'],trips['hinted'],frames)
        tail=[p for p in paired if min(p['control_depart'],p['hinted_depart'])>END-480 and max(p['control_depart'],p['hinted_depart'])<=END]
        extended=[p for p in paired if min(p['control_depart'],p['hinted_depart'])>END-480 and p['complete']]
        assert tail and extended
        cross=[p for p in paired if min(p['control_depart'],p['hinted_depart'])<=END<max(p['control_depart'],p['hinted_depart'])]
        # Every departure observed by the old endpoint must acquire its counterpart.
        assert max(p['n'] for p in paired)>=max(a['departures'],b['departures'])
        count_delta=b['departures']-a['departures']
        assert count_delta==sum(1 if p['hinted_depart']<=END else -1 for p in cross)
        first_lag=next((p for p in paired if p['lag']),None)
        changes=[dict(n=y['n'],before=x['lag'],after=y['lag'],delta=y['lag']-x['lag'],
                      previous_targets=x['target'],bad_delta_before=x['bad_delta'],bad_delta_after=y['bad_delta'])
                 for x,y in zip(paired,paired[1:]) if x['lag']!=y['lag']]
        people[n]=dict(endpoint={s:endpoints[s][n] for s in SIDES},count_delta=count_delta,
            count_class='same_count' if count_delta==0 else 'different_count',
            tail_pairs=len(tail),tail_lags=sorted({p['lag'] for p in tail}),
            tail_same_places=all(p['same_place'] for p in tail),
            extended_pairs=len(extended),extended_lags=sorted({p['lag'] for p in extended}),
            extended_same_places=all(p['same_place'] for p in extended),
            extended_same_state_cycles=all(p['same_state_cycle'] for p in extended),
            first_nonzero_lag=first_lag,lag_changes=changes,endpoint_crossings=cross,
            trips=trips,paired=paired)
    probes={m:continuation(snapshots,m) for m in ('natural','body_only','body_and_ordinal')}
    assert probes['natural']['end_hashes']==end_hashes
    return dict(**{k:row[k] for k in ('family','seed','age','actor','kind')},people=people,probes=probes)


def summary(rows):
    people=[p for r in rows for p in r['people'].values()]
    return dict(pairs=len(rows),affected_people=len(people),
        count_classes=dict(Counter(p['count_class'] for p in people)),
        pair_count_classes=dict(Counter('different_count' if any(p['count_delta'] for p in r['people'].values()) else 'same_count' for r in rows)),
        tail_lag_distribution=dict(Counter(str(p['tail_lags']) for p in people)),
        extended_stable_lags=sum(len(p['extended_lags'])==1 for p in people),
        extended_same_places=sum(p['extended_same_places'] for p in people),
        extended_identical_body_cycles=sum(p['extended_same_state_cycles'] for p in people),
        all_original_endpoint_trips_paired=True,
        probes={mode:dict(any_body_difference_pairs=sum(any(p['different_steps'] for p in r['probes'][mode]['people'].values()) for r in rows),
            endpoint_different_pairs=sum(any(p['different_at_end'] for p in r['probes'][mode]['people'].values()) for r in rows),
            sequence_difference_pairs=sum(any(p['sequence_differences'] or len(set(p['departure_counts']))>1 for p in r['probes'][mode]['people'].values()) for r in rows))
            for mode in ('natural','body_only','body_and_ordinal')})


def run(output=OUT):
    source=COUPLING/'cases.jsonl'
    archive=[json.loads(s) for s in source.read_text().splitlines()]
    selected=[r for r in archive if any(p['behavior']['at_end'] for p in r['modes']['departure']['people'].values())]
    assert len(selected)==26
    originals={key(r):r for r in source_rows()}
    results=[]
    output.mkdir(parents=True,exist_ok=True)
    with (output/'cases.jsonl').open('w') as f:
        for i,row in enumerate(selected):
            result=analyze(originals[key(row)],row)
            results.append(result)
            f.write(json.dumps(result,ensure_ascii=False,separators=(',',':'))+'\n')
            print(f'completed {i+1}/{len(selected)}',flush=True)
    result=dict(endpoint=END,stop=STOP,source_sha256=sha256(source.read_bytes()).hexdigest(),
                cases_sha256=sha256((output/'cases.jsonl').read_bytes()).hexdigest(),summary=summary(results))
    write_file(output/'summary.json',result)
    print(json.dumps(result['summary'],ensure_ascii=False),flush=True)
    return results,result


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=OUT)
    run(parser.parse_args().output)
