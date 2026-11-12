"""Reproduce W2's paired experience probes and autonomous world comparison."""
from collections import Counter
from copy import deepcopy
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'living_world/src'))
from context_world import ContextWorld, WEATHER
from world import FOODS, NAMES

OUTPUT = ROOT / 'docs/sim/living-world/w2/review'
SEEDS = range(32)


class PooledWorld(ContextWorld):
    """Matched control: same world and chooser, one shared-across-weather bank per person."""
    def swap_evidence(self, name, person):
        pass


def preference(name, weather, history):
    usual = 'p' if weather == 'sun' else 'q'
    reversed_history = (history == 'opposite' and name == 'B') or (history == 'swapped' and name == 'A')
    return ('q' if usual == 'p' else 'p') if reversed_history else usual


def exposures(world_type, history, seed):
    world = world_type(seed)
    order = ('sun', 'rain') if seed % 2 == 0 else ('rain', 'sun')
    # Four arranged contact samples per person. No sharing or hints during exposure.
    for weather in order:
        world.change_weather(weather)
        for food in FOODS:
            for name, person in world.residents.items():
                world.tick += 1
                world.intervene(food, 1 if preference(name, weather, history) == food else -1, True)
                person.pos = list(FOODS[food])
                person.target = food
                world.consume(person)
    return world


def probe(world, name, seed):
    person = deepcopy(world.residents[name])
    # The W1 chooser uses the actor name only to salt its RNG. Match draws for A/B.
    person.name = 'A'
    return person.choose(seed, world.tick+1)


def controlled(world_type):
    totals = Counter()
    example = {}
    for seed in SEEDS:
        choices = {}
        for history in ('opposite', 'swapped', 'same'):
            w = exposures(world_type, history, seed)
            choices[history] = {}
            for weather in WEATHER:
                w.change_weather(weather)
                targets = {name: probe(w, name, seed) for name in NAMES}
                choices[history][weather] = targets
                if history == 'opposite':
                    totals['matches_personal_history'] += sum(targets[n] == preference(n, weather, history) for n in NAMES)
                    totals['opposite_history_different_choices'] += targets['A'] != targets['B']
                if history == 'same':
                    totals['same_history_same_choices'] += targets['A'] == targets['B']
        for weather in WEATHER:
            before = choices['opposite'][weather]
            after = choices['swapped'][weather]
            totals['swap_reverses_both'] += all(after[n] != before[n] for n in NAMES)
        totals['within_person_switch'] += sum(choices['opposite']['sun'][n] != choices['opposite']['rain'][n] for n in NAMES)
        if seed == 0:
            example = choices
    return {'seeds':len(SEEDS), 'matches_denominator':128, 'other_denominator':64,
            'counts':dict(totals), 'seed0_probes':example}


def autonomous(world_type):
    counts = Counter()
    matched_pairs = Counter()
    choices = Counter()
    paired_seed_rates = []
    example = None
    for seed in SEEDS:
        w = world_type(seed)
        recent = {}
        late_good = late_total = 0
        for _ in range(960):
            seq = w.sequence
            w.step()
            if w.tick == 480 and seed == 0 and world_type is ContextWorld:
                example = w.snapshot()
            # A tick can contain multiple actions: preserve their normal event order.
            events = []
            for event in reversed(w.events):
                if event['id'] <= seq:
                    break
                events.append(event)
            for event in reversed(events):
                kind = event['type']
                if kind == 'weather':
                    recent.clear()
                elif kind == 'experience':
                    period = 'warmup' if w.tick <= 160 else 'later'
                    counts[period,w.weather,'meals'] += 1
                    counts[period,w.weather,'beneficial'] += event['reward'] == 1
                    if period == 'later':
                        late_good += event['reward'] == 1
                        late_total += 1
                elif kind == 'decision':
                    name = event['actor']
                    target = w.residents[name].target
                    choices[name,w.weather,target] += 1
                    recent[name] = target
                    if len(recent) == 2:
                        matched_pairs['pairs'] += 1
                        matched_pairs['different'] += recent['A'] != recent['B']
                        recent.clear()
        paired_seed_rates.append(late_good/late_total)
    by_condition = {}
    for period in ('warmup','later'):
        by_condition[period] = {}
        for weather in WEATHER:
            meals = counts[period,weather,'meals']
            good = counts[period,weather,'beneficial']
            by_condition[period][weather] = dict(meals=meals, beneficial=good, rate=good/meals)
    result = dict(episodes=len(SEEDS),steps_per_episode=960, meals=by_condition,
                  mean_seed_later_rate=sum(paired_seed_rates)/len(SEEDS), later_rate_by_seed=paired_seed_rates,
                  same_weather_departure_pairs=dict(matched_pairs),
                  departures={'/'.join(k):v for k,v in sorted(choices.items())})
    return result, example


def playable_example(snapshot):
    """Illustrative follow-up outside the fixed comparison; only use real world actions."""
    w = ContextWorld.restore(snapshot)
    w.set_mode('sun')
    w.intervene('p', -1, True)
    w.intervene('q', 1, True)
    while w.tick < 700:
        w.step()
    saved = w.snapshot()
    next_choices = {}
    while len(next_choices) < 2:
        w.step()
        for name, person in w.residents.items():
            if name not in next_choices and person.last_choice['tick'] == w.tick:
                next_choices[name] = deepcopy(person.last_choice)
    return saved, next_choices


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    results = {}
    for key, model in [('conditioned',ContextWorld),('pooled',PooledWorld)]:
        free, example = autonomous(model)
        results[key] = dict(controlled=controlled(model),free=free)
        if example is not None:
            ContextWorld.restore(example)
            (OUTPUT/'seed0-step480.json').write_text(json.dumps(example, ensure_ascii=False)+'\n')
            demo, next_choices = playable_example(example)
            (OUTPUT/'step700-example.json').write_text(json.dumps(demo,ensure_ascii=False)+'\n')
            results['illustration'] = {'seed':0,'example_tick':700,'next_live_choices':next_choices,
                                       'scope':'Post-hoc illustration, excluded from all comparisons.'}
    diffs = [a-b for a,b in zip(*(results[key]['free']['later_rate_by_seed'] for key in ('conditioned','pooled')))]
    results['paired_later'] = dict(mean_difference=sum(diffs)/len(diffs), wins=sum(d>0 for d in diffs),
                                   ties=diffs.count(0), losses=sum(d<0 for d in diffs))
    (OUTPUT/'comparison.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
    for key in ('conditioned','pooled'):
        print(key,results[key]['controlled']['counts'], results[key]['free']['meals'])
    print('paired', results['paired_later'])


if __name__ == '__main__':
    main()
