"""Diagnose the W3 pairs with unequal physical state at the archived +2640 endpoint."""
from collections import Counter
from dataclasses import dataclass
import hashlib
import json

from w3_long import END, OUTPUT as LONG, SIDES, START, extend_range, rebuild
from w3_influence import ROOT, write_file
from fork_study import ContextWorld, origin_hash
from world import FOODS, HOMES, NAMES

OUT = ROOT/'docs/sim/living-world/w3-endpoint/review'
RADIUS = 80
MAX_LAG = 60
STOP = END + 200


@dataclass(frozen=True)
class Frame:
    pos: tuple
    phase: str
    target: str | None
    departure: str | None
    arrived_home: bool

    def body(self):
        return (self.pos, self.phase, self.target)


def replay(case):
    snapshot = rebuild(case['family'],case)
    assert origin_hash(snapshot) == case['origin_hash']
    travelers = {}
    endpoints = {}
    for side in SIDES:
        world = ContextWorld.restore(snapshot)
        if side == 'hinted':
            world.hint(case['actor'],case['kind'])
        history = {name:{'trips':[], 'frames':{}} for name in NAMES}
        for offset in range(1,STOP+1):
            before = {n:(r.phase,tuple(r.pos)) for n,r in world.residents.items()}
            world.step()
            if offset == START:
                assert origin_hash(world.snapshot()) == case['state_hash_at_240'][side]
            for name,r in world.residents.items():
                phase, pos = before[name]
                journey = history[name]['trips']
                target = r.target if r.phase=='outbound' else None
                choice = r.last_choice
                departing = choice['target'] if choice and choice['tick']==world.tick else None
                if departing:
                    journey.append(dict(depart=offset, place=departing, weather=world.weather,
                                        eat=None, eat_weather=None, reward=None, home=None, rest=None))
                if phase=='outbound' and r.phase=='homebound' and journey:
                    assert tuple(r.pos)==FOODS[journey[-1]['place']]
                    event = next(e for e in reversed(world.events) if e['type']=='experience'
                                 and e['actor']==name and e['tick']==world.tick)
                    journey[-1].update(eat=offset, eat_weather=world.weather, reward=event['reward'])
                arrived = phase=='homebound' and pos!=HOMES[name] and tuple(r.pos)==HOMES[name]
                if arrived and journey:
                    journey[-1]['home'] = offset
                if phase=='homebound' and r.phase=='rest' and journey:
                    journey[-1]['rest'] = offset
                if offset>START:
                    history[name]['frames'][offset] = Frame(tuple(r.pos),r.phase,target,departing,arrived)
                if offset==END:
                    endpoints[side,name] = dict(phase=r.phase,pos=list(r.pos),outbound_target=target,
                                                weather=world.weather)
        for name,h in history.items():
            recorded = [[t['depart'],t['weather'],t['place']] for t in h['trips'] if START<t['depart']<=END]
            assert recorded == case['people'][name]['events'][side]
        travelers[side] = history
    return travelers,endpoints


def exact_lags(left,right):
    """Symmetric check: each branch's original local window must be covered."""
    valid = []
    for lag in range(-MAX_LAG,MAX_LAG+1):
        # Compare the union, not only the central overlap.
        lo = min(END-RADIUS, END-RADIUS-lag)
        hi = max(END+RADIUS, END+RADIUS-lag)
        if all(left[t]==right[t+lag] for t in range(lo,hi+1)):
            if all(sum(frames[t].departure is not None for t in range(END-RADIUS,END+RADIUS+1))>=2
                   for frames in (left,right)):
                valid.append(lag)
    return sorted(valid,key=lambda d:(abs(d),d))


def trip_pair(left,right):
    deltas = {k:right[k]-left[k] for k in ('depart','eat','home','rest')}
    return dict(control=left,hinted=right,delta=deltas,same_place=left['place']==right['place'])


def trip_alignment(left,right):
    """Cover previous/current/next on both sides, including a possible one-trip offset."""
    center_l = max(i for i,t in enumerate(left) if t['depart']<=END)
    center_r = max(i for i,t in enumerate(right) if t['depart']<=END)
    options = []
    for offset in (-1,0,1):
        shift = center_r+offset-center_l
        lo = min(center_l-1,center_r-1-shift)
        hi = max(center_l+1,center_r+1-shift)
        if lo<0 or lo+shift<0 or hi>=len(left) or hi+shift>=len(right):
            continue
        rows = []
        for i in range(lo,hi+1):
            a,b = left[i],right[i+shift]
            if a['rest'] is None or b['rest'] is None or abs(a['depart']-b['depart'])>MAX_LAG:
                break
            rows.append(trip_pair(a,b))
        else:
            lags = [abs(r['delta']['depart']) for r in rows]
            options.append(dict(offset=offset, mismatches=sum(not r['same_place'] for r in rows),
                                max_lag=max(lags),total_lag=sum(lags), trips=rows))
    options.sort(key=lambda a:(a['mismatches'],a['max_lag'],a['total_lag'],abs(a['offset']),a['offset']))
    return left[center_l],right[center_r],options


def diagnose(case):
    replayed,endpoints = replay(case)
    people = {}
    for name in NAMES:
        left,right = (replayed[s][name] for s in SIDES)
        flags = []
        for t in range(START+1,END+1):
            if left['frames'][t].body()!=right['frames'][t].body():
                extend_range(flags,t)
        assert flags==case['people'][name]['behavior_intervals']
        different = left['frames'][END].body()!=right['frames'][END].body()
        assert different==case['people'][name]['behavior_different_at_end']
        a,b,alignments = trip_alignment(left['trips'],right['trips'])
        exact = exact_lags(left['frames'],right['frames'])
        best = alignments[0] if alignments else None
        if not different:
            label = 'same_endpoint'
        elif exact:
            label = 'fixed_lag'
        elif best is None:
            label = 'insufficient'
        elif best['mismatches']==0:
            label = 'matched_sequence'
        else:
            label = 'place_difference'
        # Compare the two actual latest excursions, from departure to physical arrival home.
        latest_routes = [[h['frames'][t] for t in range(j['depart'],j['home']+1)]
                         for h,j in [(left,a),(right,b)]]
        before = {side:dict(Counter(j['place'] for j in replayed[side][name]['trips']
                                    if END-RADIUS < j['depart'] <= END)) for side in SIDES}
        people[name] = dict(latest_route_equal=latest_routes[0]==latest_routes[1],
                latest_departure_lag=b['depart']-a['depart'], latest_home_lag=b['home']-a['home'],
                last80_destinations=before,affected=different, classification=label,latest_same=a['place']==b['place'],
                control=dict(endpoint=endpoints['control',name],latest_trip=a),
                hinted=dict(endpoint=endpoints['hinted',name],latest_trip=b),
                exact_lags=exact, best_alignment=best, candidate_count=len(alignments),
                min_mismatches=best['mismatches'] if best else None,
                nearby={s:[j for j in replayed[s][name]['trips'] if END-RADIUS-MAX_LAG<=j['depart']<=END+RADIUS+MAX_LAG]
                        for s in SIDES})
    return {**{k:case[k] for k in ('family','seed','age','actor','kind','origin_hash')},'people':people}


def summarize(rows):
    affected = [p for r in rows for p in r['people'].values() if p['affected']]
    patterns = Counter()
    latest = Counter()
    for r in rows:
        people = [p for p in r['people'].values() if p['affected']]
        patterns['+'.join(sorted(set(p['classification'] for p in people)))] += 1
        latest['some_different' if any(not p['latest_same'] for p in people) else 'all_same'] += 1
    return dict(pairs=len(rows),affected_people=len(affected),pair_patterns=dict(patterns),
                latest_place_by_pair=dict(latest),latest_same_people=sum(p['latest_same'] for p in affected),
                latest_full_trip_matches=sum(p['latest_route_equal'] for p in affected),
                all_affected_single_common_place_last80=sum(
                    all(all(p['last80_destinations'].values()) and
                        len(set(p['last80_destinations']['control'])|set(p['last80_destinations']['hinted']))==1
                        for p in c['people'].values() if p['affected']) for c in rows),
                person_classifications=dict(Counter(p['classification'] for p in affected)))


def main():
    source = LONG/'cases.jsonl'
    archive = [json.loads(s) for s in source.read_text().splitlines()]
    selected = [r for r in archive if any(p['behavior_different_at_end'] for p in r['people'].values())]
    results = [diagnose(r) for r in selected]
    assert len({(r['family'],r['seed'],r['age'],r['actor'],r['kind']) for r in results})==11
    OUT.mkdir(parents=True,exist_ok=True)
    report = dict(endpoint=END,radius=RADIUS,max_lag=MAX_LAG,stop=STOP,
                  source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(), all=summarize(results),
                  by_family={f:summarize([r for r in results if r['family']==f]) for f in ('primary','reversal')},
                  cases=results)
    write_file(OUT/'diagnosis.json',report)
    print(report['all'])
    for r in results:
        print(r['family'],r['seed'],r['age'],r['actor'],r['kind'],
              [(n,p['classification'],p['control']['latest_trip']['place'],p['hinted']['latest_trip']['place'],
                p['exact_lags'],p['min_mismatches']) for n,p in r['people'].items() if p['affected']])


if __name__=='__main__':
    main()
