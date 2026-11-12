"""W3: paired rollouts from independent restores of one W2 snapshot."""
from hashlib import sha256
import json

from context_world import ContextWorld, WEATHER
from world import FOODS, FOOD_NAMES, NAMES


class SilentWorld(ContextWorld):
    """Keep the fork's prior evidence while suppressing all subsequent delivery."""
    def share(self):
        pass


def origin_hash(snapshot):
    # JSON exported through a browser writes 100.0 as 100. Both restore identically.
    def normalize(value):
        if isinstance(value, dict):
            return {key: normalize(item) for key, item in value.items()}
        if isinstance(value, list):
            return [normalize(item) for item in value]
        if type(value) is float and value.is_integer():
            return int(value)
        return value

    encoded = json.dumps(normalize(snapshot), sort_keys=True, separators=(',', ':'), allow_nan=False)
    return sha256(encoded.encode()).hexdigest()


def body(person, tick):
    choice = person.last_choice
    return {
        'pos': list(person.pos),
        'phase': person.phase,
        'target': person.target if person.phase == 'outbound' else None,
        'choice': choice['target'] if choice and choice['tick'] == tick else None,
    }


def peer_reports(world, peer):
    """Accepted reports only, compared on content and delivery time, ignoring log IDs."""
    reports = []
    for entry in reversed(world.residents[peer].history):
        if entry['tick'] != world.tick:
            break
        if entry['type'] == 'message':
            msg = entry['message']
            reports.append((msg['source'], entry['weather'], msg['tick'], msg['kind'], msg['claim']))
    return sorted(reports)


def describe(reports):
    return [f'{NAMES[source]}第 {tick} 步在{WEATHER[weather]}尝过{FOOD_NAMES[food]}：'
            f'{"有益" if reward == 1 else "不适"}'
            for source, weather, tick, food, reward in reports]


class Differences:
    def __init__(self):
        self.intervals = []
        self.steps = 0
        self.after_hint = 0
        self.choice_splits = 0
        self.first_choice_split = None
        self.different_by_weather = dict.fromkeys(WEATHER, 0)
        self.splits_after_hint = 0

    def observe(self, left, right, offset, hint_end, weather):
        if left['choice'] and right['choice'] and left['choice'] != right['choice']:
            self.choice_splits += 1
            if hint_end is not None and offset > hint_end:
                self.splits_after_hint += 1
            if self.first_choice_split is None:
                self.first_choice_split = offset
        if all(left[key] == right[key] for key in ('phase', 'pos', 'target')):
            return
        self.steps += 1
        self.different_by_weather[weather] += 1
        if hint_end is not None and offset > hint_end:
            self.after_hint += 1
        if self.intervals and self.intervals[-1][1] == offset-1:
            self.intervals[-1][1] = offset
        else:
            self.intervals.append([offset, offset])

    def summary(self, horizon):
        first = self.intervals[0][0] if self.intervals else None
        last = self.intervals[-1][1] if self.intervals else None
        return dict(first=first, last=last, steps=self.steps, at_end=last == horizon,
                    after_hint=self.after_hint, choice_splits=self.choice_splits,
                    first_choice_split=self.first_choice_split, intervals=self.intervals,
                    different_by_weather=self.different_by_weather, splits_after_hint=self.splits_after_hint)


def run_pair(snapshot, actor, kind, horizon, *, frames=False, social=True):
    if actor not in ('A','B') or kind not in (None,'p','q'):
        raise ValueError('请选择一名角色与一个已知地点')
    if type(horizon) is not int or not 1 <= horizon <= 960:
        raise ValueError('观察长度须为 1 至 960 步')
    model = ContextWorld if social else SilentWorld
    control = model.restore(snapshot)
    hinted = model.restore(snapshot)
    start = control.tick
    if kind is not None:
        hinted.hint(actor, kind)
    peer = 'B' if actor == 'A' else 'A'
    trackers = {name: Differences() for name in NAMES}
    output = []
    window_by_weather = dict.fromkeys(WEATHER, 0)
    hint_end = message_first = first_reports = None
    status = 'pending' if kind else None
    for offset in range(horizon + 1):
        if offset:
            control.step()
            hinted.step()
            window_by_weather[control.weather] += 1
        if control.tick != hinted.tick or control.weather != hinted.weather:
            raise RuntimeError('分支时钟或天气不同步')
        if kind and hint_end is None:
            status = hinted.residents[actor].hints[-1]['status']
            if status != 'pending':
                hint_end = offset
        # Decisions on the origin step happened before the intervention.
        tick = control.tick if offset else -1
        left = {name: body(person,tick) for name, person in control.residents.items()}
        right = {name: body(person,tick) for name, person in hinted.residents.items()}
        a = peer_reports(control, peer) if offset else []
        b = peer_reports(hinted, peer) if offset else []
        if a != b and message_first is None:
            message_first = offset
            first_reports = {'control':describe(a), 'hinted':describe(b)}
        for name, tracker in trackers.items():
            tracker.observe(left[name],right[name],offset,hint_end,control.weather)
        if frames:
            output.append(dict(offset=offset, weather=control.weather, control=left, hinted=right,
                               deliveries=dict(control=describe(a),hinted=describe(b))))
    return dict(start=start, horizon=horizon, actor=actor, kind=kind,
                origin_hash=origin_hash(snapshot), hint_end=hint_end, hint_status=status,
                people={name: tracker.summary(horizon) for name, tracker in trackers.items()},
                message_first=message_first, first_reports=first_reports, frames=output, window_by_weather=window_by_weather)


def compare(snapshot, actor, kind, horizon=240, frames=True):
    if kind is None:
        raise ValueError('干预分支需要一条地点建议')
    result = run_pair(snapshot,actor,kind,horizon,frames=frames)
    silent = run_pair(snapshot,actor,kind,horizon,social=False)
    peer = 'B' if actor == 'A' else 'A'
    first = result['people'][peer]['first']
    split = result['people'][peer]['first_choice_split']
    delivery = result['message_first']
    result['relay'] = (delivery is not None and first is not None and delivery < first
                       and split is not None and silent['people'][peer]['steps'] == 0)
    result['silent'] = {'people':silent['people'], 'message_first':silent['message_first']}
    return result
