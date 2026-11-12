"""Fixed W3 paired experiment. Run from the repository root with Python 3."""
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
from statistics import median
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'living_world/src'))
from context_world import ContextWorld
from fork_study import compare, origin_hash

OUT = ROOT/'docs/sim/living-world/w3/review'
AGES = (0, 60, 180)
HORIZON = 240


def write_file(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False)+'\n')


def observations(values):
    if not values:
        return None
    return {'min':min(values), 'median':median(values), 'max':max(values)}


def summarize(rows):
    data = {'pairs':len(rows), 'different_reports':sum(r['message_first'] is not None for r in rows),
            'supported_relay':sum(r['relay'] for r in rows),
            'silent_peer_changed':sum(bool(r['silent_peer_steps']) for r in rows),
            'window_by_weather':{w:sum(r['window_by_weather'][w] for r in rows) for w in ('sun','rain')},
            'hint_end_status':dict(Counter(r['hint_status'] for r in rows))}
    for role in ('recipient','peer'):
        changed = [r[role] for r in rows if r[role]['steps']]
        data[role] = {
            'changed':len(changed), 'unchanged':len(rows)-len(changed),
            'after_hint':sum(bool(m['after_hint']) for m in changed),
            'same_tick_split_after_hint':sum(bool(m['splits_after_hint']) for m in changed),
            'different_by_weather':{w:sum(m['different_by_weather'][w] for m in changed) for w in ('sun','rain')},
            'different_at_240':sum(m['at_end'] for m in changed),
            'multiple_intervals':sum(m['interval_count'] > 1 for m in changed),
            'same_tick_different_choice':sum(bool(m['choice_splits']) for m in changed),
            'first_given_change':observations([m['first'] for m in changed]),
            'last_given_change':observations([m['last'] for m in changed]),
            'different_steps_given_change':observations([m['steps'] for m in changed]),
            'different_steps_after_hint_given_change':observations([m['after_hint'] for m in changed]),
        }
    return data


def compact(person):
    data = dict(person)
    data['interval_count'] = len(data.pop('intervals'))
    return data


def case_row(snapshot, actor, kind):
    result = compare(snapshot,actor,kind,HORIZON,frames=False)
    peer = 'B' if actor == 'A' else 'A'
    return dict(seed=snapshot['active']['seed'], age=result['start'], actor=actor, kind=kind,
                origin_hash=result['origin_hash'], hint_end=result['hint_end'], hint_status=result['hint_status'],
                message_first=result['message_first'], relay=result['relay'], recipient=compact(result['people'][actor]),
                peer=compact(result['people'][peer]), silent_peer_steps=result['silent']['people'][peer]['steps'],
                window_by_weather=result['window_by_weather'])


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    first_direct = first_relay = None
    for seed in range(32):
        world = ContextWorld(seed)
        for age in AGES:
            while world.tick < age:
                world.step()
            snapshot = world.snapshot()
            expected_hash = origin_hash(snapshot)
            for actor in ('A','B'):
                for kind in ('p','q'):
                    row = case_row(snapshot,actor,kind)
                    assert row['origin_hash'] == expected_hash
                    rows.append(row)
                    item = (snapshot, row)
                    if first_direct is None and row['recipient']['steps']:
                        first_direct = item
                    if first_relay is None and row['relay']:
                        first_relay = item
            assert origin_hash(snapshot) == expected_hash
    sample_snapshot, sample = first_relay or first_direct or (ContextWorld(0).snapshot(),rows[0])
    write_file(OUT/'example.json',sample_snapshot)
    write_file(OUT/'example-info.json',sample)
    result = {
        'protocol':{'seeds':list(range(32)),'fork_ages':AGES,'horizon':HORIZON,
                    'order':['seed','fork age','actor A/B','place p/q']},
        'all':summarize(rows),
        'by_age':{str(age):summarize([r for r in rows if r['age']==age]) for age in AGES},
        'by_actor_and_place':{actor+kind:summarize([r for r in rows if r['actor']==actor and r['kind']==kind])
                              for actor in ('A','B') for kind in ('p','q')},
        'by_age_actor_place':{f'{age}/{actor}/{kind}':summarize([r for r in rows if (r['age'],r['actor'],r['kind'])==(age,actor,kind)])
                              for age in AGES for actor in ('A','B') for kind in ('p','q')},
        'example':sample,
        'source_sha256':{str(p.relative_to(ROOT)):sha256(p.read_bytes()).hexdigest() for p in
                         [Path(__file__).resolve(), ROOT/'living_world/src/fork_study.py',
                          ROOT/'living_world/src/context_world.py',ROOT/'living_world/src/world.py',
                          ROOT/'experiments/adaptive_agents/src/core.py']},
    }
    with (OUT/'pairs.jsonl').open('w') as file:
        for row in rows:
            file.write(json.dumps(row,separators=(',',':'))+'\n')
    write_file(OUT/'summary.json',result)
    print(json.dumps(result['all'],indent=2))
    print('Example',sample['seed'],sample['age'],sample['actor'],sample['kind'])


if __name__ == '__main__':
    main()
