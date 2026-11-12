"""Attribute the three archived destination mismatches at the original decision boundary.

No policy changes. Ablations are one-decision probes of copies, never replayed history.
"""
import argparse
from copy import deepcopy
from hashlib import sha256
from itertools import product
import json
import math
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from w3_endpoint import OUT as ENDPOINT, diagnose
from w3_long import OUTPUT as LONG, END, SIDES, rebuild
from w3_influence import ROOT, write_file
from fork_study import ContextWorld, origin_hash
from context_world import WeatherResident
import world as runtime

OUT = ROOT/'docs/sim/living-world/w3-attribution/review'
ORIGINAL_CHOOSE = WeatherResident.choose
REAL_RANDOM = runtime.random.Random
FIELDS = ('family', 'seed', 'age', 'actor', 'kind')


def key(case):
    return tuple(case[k] for k in FIELDS)


def fingerprint(value):
    return sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def draws_for(seed, tick, actor):
    rng = REAL_RANDOM(seed*100003 + tick*97 + (17 if actor == 'B' else 0))
    return [rng.random(), rng.random()]


def probe(person, seed, tick, own=True, messages=True, exploration=True, draws=None):
    """Keep the real tick (including message age) when swapping only random inputs."""
    before = fingerprint(person.snapshot())
    copy = deepcopy(person)
    if not own:
        copy.brain.values = {k: 0.0 for k in runtime.FOODS}
    if not messages:
        copy.brain.inbox = {}
    draws = draws_for(seed, tick, copy.name) if draws is None else list(draws)
    stream = iter(draws)
    rng = SimpleNamespace(Random=lambda _: SimpleNamespace(random=lambda: next(stream)))
    epsilon = runtime.CONFIG['epsilon'] if exploration else 0.0
    with patch.object(runtime, 'random', rng), patch.dict(runtime.CONFIG, epsilon=epsilon):
        target = ORIGINAL_CHOOSE(copy, seed, tick)
    assert fingerprint(person.snapshot()) == before
    assert copy.brain.counts == person.brain.counts
    eligible = list(copy.last_choice['scores']) if target else []
    unknown = [k for k in eligible if copy.brain.counts[k] == 0]
    route = 'unknown' if unknown else 'explore' if draws[0] < epsilon else 'estimated_value'
    pool = unknown or eligible
    scores = copy.last_choice['scores'] if target else {}
    candidates = (eligible if route == 'explore' else
                  [k for k in pool if abs(scores[k]-max(scores[j] for j in pool)) < 1e-12]) if pool else []
    assert target == (candidates[min(int(draws[1]*len(candidates)),len(candidates)-1)] if candidates else None)
    return dict(own=own, messages=messages, exploration=exploration, draws=draws,
                route=route, candidates=candidates, **(copy.last_choice if target else {'target': None}))


def capture(case, mismatches):
    snapshot = rebuild(case['family'], case)
    assert origin_hash(snapshot) == case['origin_hash']
    captured = {}
    for side in SIDES:
        w = ContextWorld.restore(snapshot)
        if side == 'hinted':
            w.hint(case['actor'], case['kind'])
        wanted = {(actor, case['age']+trip[side]['depart']) for actor, trip in mismatches}
        departures = {n: [] for n in runtime.NAMES}
        sources, receipts = {}, {}
        # Seed provenance for reports already present at the fork.
        for name, r in w.residents.items():
            for weather, latest in ((w.weather, r.latest),
                                    ('rain' if w.weather == 'sun' else 'sun', w.reserve[name][1])):
                for m in latest.values():
                    sources[weather, m['source'], m['tick']] = deepcopy(m)
            for e in r.history:
                if e['type'] == 'message':
                    receipts[name,e['weather'],e['message']['id']] = e['tick']

        def observe(person, seed, tick):
            selected = (person.name, tick) in wanted
            saved = deepcopy(person) if selected else None
            evidence = []
            if selected:
                for kind, msg in person.brain.inbox.items():
                    age = tick-msg['tick']
                    effective = 0 <= age <= runtime.CONFIG['message_ttl']
                    weight = person.brain.trust()*math.exp(-age/runtime.CONFIG['message_decay']) if effective else 0.0
                    source = sources.get((person.weather,msg['source'],msg['tick']))
                    received = receipts.get((person.name,person.weather,msg['id']))
                    assert source == msg, ('missing first-hand source', msg)
                    assert received is not None and msg['tick'] <= received < tick
                    evidence.append(dict(**msg, age=age, received_tick=received,
                                         effective=effective, weight=weight, source_verified=True))
                for msg in person.latest.values():
                    assert sources[person.weather,person.name,msg['tick']] == msg
            target = ORIGINAL_CHOOSE(person, seed, tick)
            if selected:
                actual = deepcopy(person.last_choice)
                # Independently reconstruct the score from the pre-choice evidence.
                for kind, score in actual['scores'].items():
                    expected = saved.brain.values[kind]
                    msg = next((m for m in evidence if m['kind'] == kind), None)
                    if msg and msg['effective']:
                        expected = (1-msg['weight'])*expected + msg['weight']*msg['claim']
                    if any(h['kind']==kind and h['status']=='pending' and
                           tick-h['tick']<=runtime.HINT_TTL for h in saved.hints):
                        expected += .65
                    assert expected == score
                baseline = probe(saved, seed, tick)
                assert all(baseline[k] == actual[k] for k in actual)
                recorded = dict(side=side, actor=person.name, tick=tick, offset=tick-case['age'],
                    weather=person.weather, input_sha256=fingerprint(dict(weather=saved.weather, **saved.snapshot())),
                    own_values=dict(saved.brain.values), own_counts=dict(saved.brain.counts),
                    own_latest=deepcopy(saved.latest), trust=saved.brain.trust(), messages=evidence,
                    observed=deepcopy(saved.observed), hints=deepcopy(saved.hints),
                    previous_choice=deepcopy(saved.last_choice), baseline=baseline,
                    ablations=[probe(saved, seed, tick, *flags) for flags in product((False,True), repeat=3)])
                captured[side,person.name,tick] = (saved, recorded)
            return target

        with patch.object(WeatherResident, 'choose', observe):
            while w.tick < case['age'] + max(END, max(t for _,t in wanted)-case['age']):
                w.step()
                offset = w.tick-case['age']
                if offset == 240:
                    assert origin_hash(w.snapshot()) == case['state_hash_at_240'][side]
                for n, r in w.residents.items():
                    if r.last_choice and r.last_choice['tick'] == w.tick and 240 < offset <= END:
                        departures[n].append([offset,w.weather,r.last_choice['target']])
                    for msg in r.latest.values():
                        sources[w.weather,n,msg['tick']] = deepcopy(msg)
                    for e in r.history:
                        if e['type'] == 'message' and e['tick'] == w.tick:
                            receipts[n,e['weather'],e['message']['id']] = e['tick']
        for n in runtime.NAMES:
            assert departures[n] == case['people'][n]['events'][side]
    assert len(captured) == 2*len(mismatches)
    return captured


def investigate(endpoint, original):
    # Reproduce the previously registered alignment; do not select convenient trips.
    assert diagnose(original) == endpoint
    mismatches = [(actor, trip) for actor, p in endpoint['people'].items()
                  if p['classification'] == 'place_difference'
                  for trip in p['best_alignment']['trips'] if not trip['same_place']]
    captured = capture(original, mismatches)
    pairs = []
    for actor, trip in mismatches:
        rows = {}
        for side in SIDES:
            tick = original['age']+trip[side]['depart']
            person, row = captured[side,actor,tick]
            assert row['baseline']['target'] == trip[side]['place']
            other = 'hinted' if side == 'control' else 'control'
            opposite = captured[other,actor,original['age']+trip[other]['depart']][1]
            row['other_branch_draws'] = probe(person, original['seed'], tick,
                                              draws=opposite['baseline']['draws'])
            rows[side] = row
        pairs.append(dict(actor=actor, matched_trip=trip, decisions=rows))
    return dict(**{k:original[k] for k in FIELDS}, comparisons=pairs)


def run(output=OUT):
    source = ENDPOINT/'diagnosis.json'
    endpoint = json.loads(source.read_text())
    originals = {key(c):c for c in map(json.loads,(LONG/'cases.jsonl').read_text().splitlines())}
    selected = [c for c in endpoint['cases'] if any(p['classification']=='place_difference' for p in c['people'].values())]
    rows = [investigate(c, originals[key(c)]) for c in selected]
    decisions = [d for c in rows for pair in c['comparisons'] for d in pair['decisions'].values()]
    result = dict(source_sha256=sha256(source.read_bytes()).hexdigest(),
        long_source_sha256=sha256((LONG/'cases.jsonl').read_bytes()).hexdigest(),
        implementation_sha256={str(p.relative_to(ROOT)):sha256(p.read_bytes()).hexdigest() for p in (
            ROOT/'living_world/src/world.py', ROOT/'living_world/src/context_world.py',
            ROOT/'experiments/adaptive_agents/src/core.py')},
        summary=dict(pairs=len(rows), decisions=len(decisions),
                     exploration_decisions=sum(d['baseline']['route']=='explore' for d in decisions),
                     unique_rng_keys=len({(c['seed'],d['actor'],d['tick']) for c in rows
                                          for p in c['comparisons'] for d in p['decisions'].values()}),
                     unique_input_states=len({d['input_sha256'] for d in decisions}),
                     ablation_probes=sum(len(d['ablations']) for d in decisions),
                     swapped_draw_probes=len(decisions)), cases=rows)
    output.mkdir(parents=True, exist_ok=True)
    write_file(output/'attribution.json', result)
    print(json.dumps(result['summary'], ensure_ascii=False))
    for c in rows:
        for pair in c['comparisons']:
            print('seed',c['seed'],'hint recipient',c['actor'],'chooser',pair['actor'])
            for side,d in pair['decisions'].items():
                b=d['baseline']
                print(side,d['offset'],b['target'],b['route'],b['draws'],b['scores'],
                      'swap draws ->',d['other_branch_draws']['target'])
                print(' own',d['own_values'],'messages',[(m['kind'],m['claim'],m['age'],m['weight']) for m in d['messages']])
                print(' probes',[(int(p['own']),int(p['messages']),int(p['exploration']),p['target']) for p in d['ablations']])
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=OUT)
    run(parser.parse_args().output)
