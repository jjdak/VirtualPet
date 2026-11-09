"""Follow only the W3 pairs censored at +240. Rebuild the fixed archive before continuing."""
from collections import Counter, defaultdict
from hashlib import sha256
import json
from statistics import median

from w3_influence import ROOT, case_row, write_file
from fork_study import ContextWorld, body, origin_hash, run_pair
from world import NAMES

ARCHIVE = ROOT / 'docs/sim/living-world/w3/review'
OUTPUT = ROOT / 'docs/sim/living-world/w3-long/review'
START = 240
WINDOW = 480
END = START + 5 * WINDOW
SIDES = ('control', 'hinted')


def rebuild(family, row):
    world = ContextWorld(row['seed'])
    if family == 'reversal':
        while world.tick < 480:
            world.step()
        world.set_mode('sun')
        world.intervene('p', -1, True)
        world.intervene('q', 1, True)
    while world.tick < row['age']:
        world.step()
    return world.snapshot()


def trajectory_state(person):
    return (person['pos'], person['phase'], person['target'])


def extend_range(intervals, offset):
    if intervals and intervals[-1][1] == offset-1:
        intervals[-1][1] = offset
    else:
        intervals.append([offset, offset])


def dominant(trips):
    if len(trips) < 3:
        return None
    count = Counter(trips)
    place, n = count.most_common(1)[0]
    return place if 3*n >= 2*len(trips) else None


def window_result(events, conditions, begin, end):
    by_weather = {}
    for weather in sorted(conditions):
        trips = {side: [target for t, w, target in events[side] if begin <= t <= end and w == weather]
                 for side in SIDES}
        left, right = (trips[s] for s in SIDES)
        prefs = {s: dominant(trips[s]) for s in SIDES}
        if min(len(left), len(right)) < 3:
            verdict = 'sparse'
        elif None in prefs.values():
            verdict = 'mixed'
        elif prefs['control'] == prefs['hinted']:
            verdict = 'agree'
        else:
            verdict = 'opposite'
        comparisons = list(zip(left, right))
        by_weather[weather] = dict(verdict=verdict, dominant=prefs,
            counts={s:dict(Counter(trips[s])) for s in SIDES},
            matched=len(comparisons), equal=sum(a == b for a,b in comparisons),
            unpaired=abs(len(left)-len(right)))
    labels = {r['verdict'] for r in by_weather.values()}
    # Report component weather verdicts as well when the others have less evidence.
    verdict = next((key for key in ('opposite','sparse','mixed') if key in labels), 'agree')
    return dict(begin=begin, end=end, verdict=verdict, weather=by_weather)


def first_realign(events, initial, spans):
    """Descriptive timing for cases with identifiable, different targets at +240."""
    left, right = (initial[side] for side in SIDES)
    if left is None or right is None or left == right:
        return None
    latest = dict(initial)
    departures = defaultdict(dict)
    for side, trips in events.items():
        for tick, _, place in trips:
            departures[tick][side] = place
    first = reopened = None
    for i, (lo, hi, _) in enumerate(spans):
        if i:
            latest = dict.fromkeys(SIDES)
        for tick in sorted(t for t in departures if lo <= t <= hi):
            latest.update(departures[tick])
            a, b = (latest[side] for side in SIDES)
            if a is None or b is None:
                continue
            if a == b and first is None:
                first = tick
            elif a != b and first is not None and reopened is None:
                reopened = tick
    return dict(first=first, reopen=reopened)


def person_result(events, conditions, intervals, initial, was_different, spans):
    blocks = [window_result(events, w, START+1+i*WINDOW, START+(i+1)*WINDOW)
              for i,w in enumerate(conditions)]
    labels = [b['verdict'] for b in blocks]
    first = next((i for i in range(1,len(labels)) if labels[i-1:i+1] == ['agree','agree']), None)
    last = intervals[-1][1] if intervals else None
    return dict(at_240=was_different, latest_choices_at_240=initial, windows=blocks, events=events,
                behavior_intervals=intervals, last_behavior_difference=last,
                latest_target_realignment=first_realign(events,initial,spans),
                behavior_same_final160=last is None or last <= END-160,
                behavior_different_at_end=last == END, final_preference_agreement=labels[-2:] == ['agree','agree'],
                first_confirmed=None if first is None else blocks[first]['end'],
                later_verdicts=[] if first is None else labels[first+1:])


def follow(family, row):
    actor = row['actor']
    peer = 'B' if actor == 'A' else 'A'
    snapshot = rebuild(family, row)
    if origin_hash(snapshot) != row['origin_hash'] or case_row(snapshot,actor,row['kind']) != row:
        raise ValueError(f'Archived W3 row does not reproduce: {family} {row["seed"]} {row["age"]}')
    prefix = run_pair(snapshot,actor,row['kind'],START,frames=True)['frames']
    worlds = {s: ContextWorld.restore(snapshot) for s in SIDES}
    worlds['hinted'].hint(actor,row['kind'])
    trips = {name: {s:[] for s in SIDES} for name in NAMES}
    intervals = {name:[] for name in NAMES}
    latest = {n:dict.fromkeys(SIDES) for n in NAMES}
    conditions = [set() for _ in range(5)]
    weather_spans = []
    weather = worlds['control'].weather
    for offset in range(END+1):
        if offset:
            for world in worlds.values():
                world.step()
        current = worlds['control'].weather
        if worlds['hinted'].weather != current or any(w.tick != row['age']+offset for w in worlds.values()):
            raise ValueError('Clock or weather mismatch')
        if current != weather:
            latest = {n:dict.fromkeys(SIDES) for n in NAMES}
            weather = current
        if offset > START:
            conditions[(offset-START-1)//WINDOW].add(weather)
            if not weather_spans or weather_spans[-1][2] != weather:
                weather_spans.append([offset,offset,weather])
            else:
                weather_spans[-1][1] = offset
        for name in NAMES:
            states = {}
            for side, world in worlds.items():
                value = body(world.residents[name],world.tick if offset else -1)
                states[side] = trajectory_state(value)
                if offset <= START and (value != prefix[offset][side][name] or weather != prefix[offset]['weather']):
                    raise ValueError('Pre-follow-up trace mismatch')
                if value['choice']:
                    latest[name][side] = value['choice']
                    if offset > START:
                        trips[name][side].append([offset,weather,value['choice']])
            different = states['control'] != states['hinted']
            if offset == START and different != row['recipient' if name==actor else 'peer']['at_end']:
                raise ValueError('Cohort boundary mismatch')
            if offset > START and different:
                extend_range(intervals[name],offset)
        if offset == START:
            split = {name:dict(choices) for name,choices in latest.items()}
            hashes = {s:origin_hash(w.snapshot()) for s,w in worlds.items()}
    people = {n:person_result(trips[n],conditions,intervals[n],split[n],
                              row['recipient' if n==actor else 'peer']['at_end'],weather_spans) for n in NAMES}
    return dict(family=family,seed=row['seed'],age=row['age'],actor=actor,peer=peer,kind=row['kind'],
                origin_hash=row['origin_hash'],state_hash_at_240=hashes,weather=weather_spans,people=people)


def stats(people):
    checkpoints = [Counter(p['windows'][i]['verdict'] for p in people) for i in range(5)]
    observed = [p['first_confirmed'] for p in people if p['first_confirmed'] is not None]
    cells = [cell for p in people for block in p['windows'][-2:] for cell in block['weather'].values()]
    last_trips = [(sum(v['matched']-v['equal'] for b in p['windows'][-2:] for v in b['weather'].values()),
                   sum(v['matched'] for b in p['windows'][-2:] for v in b['weather'].values())) for p in people]
    initial = Counter()
    for p in people:
        a,b = (p['latest_choices_at_240'][s] for s in SIDES)
        initial['unknown' if None in (a,b) else 'same' if a==b else 'different'] += 1
    aligned = [p['latest_target_realignment'] for p in people if p['latest_target_realignment'] is not None]
    delays = [a['first']-START for a in aligned if a['first'] is not None]
    return dict(count=len(people),
        first_target_realignment=dict(eligible=len(aligned), aligned=len(delays),reopened=sum(a['reopen'] is not None for a in aligned),
                                      delay_range=[min(delays),median(delays),max(delays)] if delays else None),
        latest_target_at_240=dict(initial), window_verdicts=checkpoints,
        final_agreement=sum(p['final_preference_agreement'] for p in people),
        ever_confirmed=len(observed),first_confirmed_median=median(observed) if observed else None,
        later_opposite=sum('opposite' in p['later_verdicts'] for p in people),
        later_uncertain=sum(bool({'sparse','mixed'}.intersection(p['later_verdicts'])) for p in people),
        final_choices=dict(matched=sum(v['matched'] for v in cells),equal=sum(v['equal'] for v in cells),
                           unpaired=sum(v['unpaired'] for v in cells),
                           people_with_a_mismatch=sum(d>0 for d,n in last_trips)),
        behavior_same_final160=sum(p['behavior_same_final160'] for p in people),
        behavior_different_at_end=sum(p['behavior_different_at_end'] for p in people))


def main():
    OUTPUT.mkdir(parents=True,exist_ok=True)
    groups = {'primary':[json.loads(line) for line in (ARCHIVE/'pairs.jsonl').read_text().splitlines()],
              'reversal':json.loads((ARCHIVE/'reversal.json').read_text())['pairs']}
    results = []
    summary = {'start':START,'end':END,'window':WINDOW,'families':{}}
    for family, rows in groups.items():
        keys = [(r['seed'],r['age'],r['actor'],r['kind']) for r in rows]
        assert len(set(keys)) == len(keys)
        selected = [r for r in rows if r['recipient']['at_end'] or r['peer']['at_end']]
        cohort = [follow(family,row) for row in selected]
        results.extend(cohort)
        people = [p for case in cohort for p in case['people'].values()]
        summary['families'][family] = dict(original=len(rows), selected=len(cohort),
            both_final_agreement=sum(all(p['final_preference_agreement'] for p in c['people'].values()) for c in cohort),
            both_same_final160=sum(all(p['behavior_same_final160'] for p in c['people'].values()) for c in cohort),
            either_different_at_end=sum(any(p['behavior_different_at_end'] for p in c['people'].values()) for c in cohort),
            affected=stats([p for p in people if p['at_240']]),others=stats([p for p in people if not p['at_240']]),
            recipient_at_240=stats([c['people'][c['actor']] for c in cohort if c['people'][c['actor']]['at_240']]),
            peer_at_240=stats([c['people'][c['peer']] for c in cohort if c['people'][c['peer']]['at_240']]))
    archive_files = ['pairs.jsonl','reversal.json','summary.json']
    summary['archive_commit'] = 'ead23acbed8cdd83dafcbfcb4eb8008a3cf611bb'
    summary['inputs_sha256'] = {f:sha256((ARCHIVE/f).read_bytes()).hexdigest() for f in archive_files}
    write_file(OUTPUT/'summary.json',summary)
    with (OUTPUT/'cases.jsonl').open('w') as f:
        for case in results:
            f.write(json.dumps(case,separators=(',',':'))+'\n')
    template = (ROOT/'living_world/studies/w3_long_view.html').read_text()
    page = template.replace('/*CASES*/',json.dumps(results,separators=(',',':')))
    (OUTPUT/'index.html').write_text(page)
    print([(name,group['selected'],group['both_final_agreement'],group['both_same_final160'])
           for name,group in summary['families'].items()])


if __name__ == '__main__':
    main()
