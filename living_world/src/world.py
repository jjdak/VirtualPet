"""W1 live world. World truth stays in execution; decisions use personal records.

E2's Agent is frozen and reused for value updates and peer message validation.
No model, training, global brain or authored success sequence.
"""
from collections import deque
from copy import deepcopy
import importlib.util
import json
import math
from pathlib import Path
import random

E2_PATH = Path(__file__).resolve().parents[2] / 'experiments/adaptive_agents/src/core.py'
spec = importlib.util.spec_from_file_location('w1_e2_core', E2_PATH)
e2 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e2)

CONFIG = dict(epsilon=.10, alpha=.4, fixed_trust=.6, trust_prior=[3, 2],
              trust_retention=.999, message_ttl=160, message_decay=100)
NAMES = {'A': '阿禾', 'B': '小岚'}
FOODS = {'p': (2, 2), 'q': (8, 2)}
FOOD_NAMES = {'p': '青禾地', 'q': '紫穗地'}
HOMES = {'A': (4, 5), 'B': (6, 5)}
WALLS = {(5, 2), (5, 3)}
WIDTH, HEIGHT = 11, 8
HINT_TTL = 100


def distance(a, b):
    return abs(a[0]-b[0]) + abs(a[1]-b[1])


def path_step(start, goal):
    start, goal = tuple(start), tuple(goal)
    queue, parents = deque([start]), {start: None}
    while queue:
        p = queue.popleft()
        if p == goal:
            while parents[p] is not None and parents[p] != start:
                p = parents[p]
            return list(p)
        for q in ((p[0]-1, p[1]), (p[0]+1, p[1]), (p[0], p[1]-1), (p[0], p[1]+1)):
            if 0 <= q[0] < WIDTH and 0 <= q[1] < HEIGHT and q not in WALLS and q not in parents:
                parents[q] = p
                queue.append(q)
    raise ValueError('目标不可达')


class Resident:
    def __init__(self, name):
        self.name = name
        self.brain = e2.Agent(name, 'recent_trust', CONFIG)
        self.pos = list(HOMES[name])
        self.hunger = 44.0 if name == 'A' else 34.0
        self.energy = 100.0
        self.phase = 'rest'
        self.target = None
        self.reason = '先在营地休息，饿了再出发。'
        self.observed = {}
        self.hints = []
        self.history = []
        self.latest = {}
        self.next_departure = 0
        self.decisions = 0
        self.last_choice = None

    def remember(self, tick, event_type, text, **data):
        self.history.append(dict(tick=tick, type=event_type, text=text, **data))
        self.history = self.history[-80:]

    def choose(self, seed, tick):
        # Only personal memory and public positions are available here.
        rng = random.Random(seed*100003 + tick*97 + (17 if self.name == 'B' else 0))
        explore, tie = rng.random(), rng.random()
        eligible = [k for k in FOODS if not (k in self.observed
                    and not self.observed[k]['available'] and tick-self.observed[k]['tick'] < 60)]
        if not eligible:
            self.reason = '最近见到两处都停供了；先休息，稍后再看看。'
            return None
        scores = {}
        for k in eligible:
            score = self.brain.values[k]
            msg = self.brain.inbox.get(k)
            if msg and 0 <= tick-msg['tick'] <= CONFIG['message_ttl']:
                weight = self.brain.trust()*math.exp(-(tick-msg['tick'])/CONFIG['message_decay'])
                score = (1-weight)*score + weight*msg['claim']
            # A recommendation is a small, expiring bias; not a food outcome.
            if any(h['kind'] == k and h['status'] == 'pending' and tick-h['tick'] <= HINT_TTL
                   for h in self.hints):
                score += .65
            scores[k] = score
        unknown = [k for k in eligible if self.brain.counts[k] == 0]
        if unknown:
            best = max(scores[k] for k in unknown)
            candidates = [k for k in unknown if abs(scores[k]-best) < 1e-12]
            reason = '这里还没有亲自试过，去看看。'
        elif explore < CONFIG['epsilon']:
            candidates = eligible
            reason = '偶尔换一个地方，检查旧经验是否还适用。'
        else:
            best = max(scores.values())
            candidates = [k for k in eligible if abs(scores[k]-best) < 1e-12]
            reason = '比较亲历、近期消息和线索后，选择更值得尝试的地方。'
        target = candidates[min(int(tie*len(candidates)), len(candidates)-1)]
        if any(h['kind'] == target and h['status'] == 'pending' for h in self.hints):
            reason += ' 也考虑了你给的地点建议，结果要亲自验证。'
        self.reason = reason
        self.decisions += 1
        self.last_choice = dict(tick=tick, target=target, scores=scores, reason=reason)
        self.remember(tick, 'decision', f'准备去{FOOD_NAMES[target]}。{reason}', target=target, scores=scores)
        return target

    def snapshot(self):
        return {**deepcopy({k: v for k, v in self.__dict__.items() if k != 'brain'}),
                'brain': self.brain.snapshot()}


class World:
    def __init__(self, seed=42):
        self.seed = seed
        self.tick = 0
        self.resources = {k: dict(available=True, effect=1 if k == 'p' else -1) for k in FOODS}
        self.residents = {k: Resident(k) for k in NAMES}
        self.events = []
        self.sequence = 0
        self.emit('world', '世界开始了。两个人知道地点，但还不知道食物的效果。')

    def emit(self, event_type, text, **extra):
        self.sequence += 1
        self.events.append(dict(id=self.sequence, tick=self.tick, type=event_type, text=text, **extra))
        self.events = self.events[-200:]

    def intervene(self, kind, effect, available):
        if kind not in FOODS or type(effect) is not int or effect not in (-1, 1) or type(available) is not bool:
            raise ValueError('无效环境设置')
        self.resources[kind] = dict(available=available, effect=effect)
        self.emit('environment', f'你改变了{FOOD_NAMES[kind]}：'
                  f'{"开放" if available else "停供"}，食物{"有益" if effect == 1 else "不适"}。角色尚未因此获知效果。',
                  kind=kind, effect=effect, available=available)

    def hint(self, actor, kind):
        if actor not in NAMES or kind not in FOODS:
            raise ValueError('无效角色或地点')
        r = self.residents[actor]
        # Replace pending suggestions; do not accumulate infinite score bonuses.
        for h in r.hints:
            if h['status'] == 'pending':
                h['status'] = 'superseded'
        self.emit('hint', f'你只向{NAMES[actor]}建议：可以去{FOOD_NAMES[kind]}看看。', actor=actor, kind=kind)
        r.hints.append(dict(id=self.sequence, source='player', kind=kind, tick=self.tick, status='pending'))
        r.hints = r.hints[-20:]
        r.remember(self.tick, 'hint', f'你建议去{FOOD_NAMES[kind]}看看；这还不是亲历结论。', kind=kind)

    def before_actions(self):
        pass

    def step(self):
        self.tick += 1
        self.before_actions()
        # No same-tick message delivery until both agents have acted.
        for actor, r in self.residents.items():
            r.brain.begin_round(self.tick)
            r.hunger = min(100.0, r.hunger + .8)
            for h in r.hints:
                if h['status'] == 'pending' and self.tick-h['tick'] > HINT_TTL:
                    h['status'] = 'expired'
                    r.remember(self.tick, 'hint_expired', '那条地点建议已经过时；不再影响选择。')
            # Visibility reveals supply, never hidden food quality.
            for k, pos in FOODS.items():
                if distance(r.pos, pos) <= 1:
                    available = self.resources[k]['available']
                    old = r.observed.get(k)
                    if old is None or old['available'] != available:
                        r.remember(self.tick, 'observe', f'看到{FOOD_NAMES[k]}{"有食物" if available else "暂时停供"}。', kind=k)
                    r.observed[k] = dict(available=available, tick=self.tick)
            if r.phase == 'rest':
                r.energy = min(100.0, r.energy + 5)
                if r.hunger >= 40 and r.energy >= 60 and self.tick >= r.next_departure:
                    r.target = r.choose(self.seed, self.tick)
                    if r.target:
                        r.phase = 'outbound'
                        self.emit('decision', f'{NAMES[actor]}决定去{FOOD_NAMES[r.target]}。', actor=actor)
                    else:
                        r.next_departure = self.tick + 8
            elif r.phase == 'outbound':
                if r.pos != list(FOODS[r.target]):
                    self.move(r, FOODS[r.target])
                else:
                    self.consume(r)
                    r.phase = 'homebound'
            elif r.phase == 'homebound':
                if r.pos != list(HOMES[actor]):
                    self.move(r, HOMES[actor])
                else:
                    r.phase = 'rest'
                    r.target = None
                    r.next_departure = self.tick + 4
                    r.reason = '回营休息；靠近同伴时交流最近的亲历。'
        self.share()
        # Bound duplicate bookkeeping to recent evidence; old messages expire anyway.
        for r in self.residents.values():
            recent_ids = {m['id'] for m in r.brain.inbox.values()} | set(r.brain.pending)
            r.brain.seen.intersection_update(recent_ids)
            r.brain.validated.intersection_update(recent_ids)

    def move(self, r, goal):
        r.pos = path_step(r.pos, goal)
        r.energy = max(0.0, r.energy - 1.5)

    def consume(self, r):
        k = r.target
        if r.pos != list(FOODS[k]):
            raise ValueError('食物不在接触距离内')
        if not self.resources[k]['available']:
            r.observed[k] = dict(available=False, tick=self.tick)
            r.remember(self.tick, 'empty', f'到了{FOOD_NAMES[k]}，没有食物。', kind=k)
            self.emit('empty', f'{NAMES[r.name]}在{FOOD_NAMES[k]}扑空，准备回营。', actor=r.name)
        else:
            reward = self.resources[k]['effect']
            checked = r.brain.experience(k, reward, self.tick)
            r.hunger = max(0.0, r.hunger - (38 if reward == 1 else 14))
            r.energy = min(100.0, max(0.0, r.energy + (8 if reward == 1 else -10)))
            message = dict(id=f'{r.name}:{self.tick}', source=r.name, tick=self.tick, kind=k, claim=reward)
            r.latest[k] = message
            r.remember(self.tick, 'experience', f'亲自在{FOOD_NAMES[k]}取食：{"感觉不错" if reward == 1 else "感到不适"}。',
                       kind=k, reward=reward, validated=checked)
            self.emit('experience', f'{NAMES[r.name]}尝了{FOOD_NAMES[k]}的食物，{"感觉不错" if reward == 1 else "感到不适"}。',
                      actor=r.name, kind=k, reward=reward)
        for h in r.hints:
            if h['kind'] == k and h['status'] == 'pending':
                h['status'] = 'visited'
        r.reason = '已经亲自检查这个地点，回营休息。'

    def share(self):
        a, b = self.residents.values()
        if distance(a.pos, b.pos) > 2:
            return
        # Transfer only first-hand samples, never another person's or player's hint.
        for sender, receiver in ((a, b), (b, a)):
            for msg in sender.latest.values():
                if receiver.brain.receive(msg, self.tick) == 'accepted':
                    receiver.remember(self.tick, 'message', f'{NAMES[sender.name]}说在{FOOD_NAMES[msg["kind"]]}取食后'
                                      f'{"感觉不错" if msg["claim"] == 1 else "感到不适"}；这是对方的经历。', message=deepcopy(msg))
                    self.emit('message', f'{NAMES[sender.name]}向{NAMES[receiver.name]}分享了{FOOD_NAMES[msg["kind"]]}的亲历。',
                              sender=sender.name, receiver=receiver.name, evidence_tick=msg['tick'])

    def snapshot(self):
        return dict(version=1, seed=self.seed, tick=self.tick, resources=deepcopy(self.resources),
                    residents={k: r.snapshot() for k, r in self.residents.items()},
                    events=deepcopy(self.events), sequence=self.sequence)

    @classmethod
    def restore(cls, data):
        validate_snapshot(data)
        w = cls(data['seed'])
        w.tick, w.resources = data['tick'], deepcopy(data['resources'])
        w.events, w.sequence = deepcopy(data['events']), data['sequence']
        for k, d in data['residents'].items():
            r = Resident(k)
            for key, val in d.items():
                if key != 'brain':
                    setattr(r, key, deepcopy(val))
            r.brain = e2.Agent.restore(d['brain'])
            w.residents[k] = r
        return w

    def view(self):
        result = World.snapshot(self)
        result['map'] = dict(width=WIDTH, height=HEIGHT, foods=FOODS, homes=HOMES, walls=sorted(WALLS))
        for k, r in self.residents.items():
            result['residents'][k]['trust'] = r.brain.trust()
            result['residents'][k]['display_name'] = NAMES[k]
        return result


def validate_snapshot(d):
    """Reject malformed state before replacement, including nested executable fields."""
    def require(ok):
        if not ok:
            raise ValueError('存档格式或状态不合法，当前世界未替换')
    def integer(v, lo=0, hi=10**12):
        return type(v) is int and lo <= v <= hi
    def number(v, lo=-1e12, hi=1e12):
        return type(v) in (int, float) and math.isfinite(v) and lo <= v <= hi
    def text(v):
        return isinstance(v, str) and len(v) <= 2000
    def point(v):
        return isinstance(v, list) and len(v) == 2 and integer(v[0], 0, WIDTH-1) and integer(v[1], 0, HEIGHT-1) and tuple(v) not in WALLS
    try:
        require(isinstance(d, dict) and set(d) == {'version', 'seed', 'tick', 'resources', 'residents', 'events', 'sequence'})
        require(type(d['version']) is int and d['version'] == 1 and integer(d['seed'], 0, 999999) and integer(d['tick']) and integer(d['sequence']))
        t = d['tick']
        def message(m, source=None):
            require(isinstance(m, dict) and set(m) == {'id', 'source', 'tick', 'kind', 'claim'})
            require(text(m['id']) and m['source'] in NAMES and (source is None or m['source'] == source)
                    and integer(m['tick'], 0, t) and m['kind'] in FOODS and type(m['claim']) is int and m['claim'] in (-1, 1))
        require(set(d['resources']) == set(FOODS) and set(d['residents']) == set(NAMES))
        for v in d['resources'].values():
            require(set(v) == {'effect', 'available'} and type(v['available']) is bool and type(v['effect']) is int and v['effect'] in (-1, 1))
        for k, r in d['residents'].items():
            require(set(r) == set(Resident(k).snapshot()) and r['name'] == k)
            require(point(r['pos']) and number(r['hunger'], 0, 100) and number(r['energy'], 0, 100))
            require(r['phase'] in ('rest', 'outbound', 'homebound') and (r['target'] is None or r['target'] in FOODS))
            require(r['phase'] == 'rest' or r['target'] in FOODS)
            require(r['phase'] != 'rest' or (r['pos'] == list(HOMES[k]) and r['target'] is None))
            require(text(r['reason']) and integer(r['next_departure'], 0, t+100) and integer(r['decisions']))
            require(isinstance(r['observed'], dict) and set(r['observed']) <= set(FOODS))
            for o in r['observed'].values():
                require(set(o) == {'available', 'tick'} and type(o['available']) is bool and integer(o['tick'], 0, t))
            require(isinstance(r['hints'], list) and len(r['hints']) <= 20)
            for h in r['hints']:
                require(set(h) == {'id', 'source', 'kind', 'tick', 'status'} and integer(h['id'], 0, d['sequence'])
                        and h['source'] == 'player' and h['kind'] in FOODS and integer(h['tick'], 0, t)
                        and h['status'] in ('pending', 'visited', 'expired', 'superseded'))
            require(isinstance(r['latest'], dict) and set(r['latest']) <= set(FOODS))
            for kind, m in r['latest'].items():
                message(m, k)
                require(kind == m['kind'])
            b = r['brain']
            require(set(b) == set(e2.Agent(k, 'recent_trust', CONFIG).snapshot())
                    and b['name'] == k and b['policy'] == 'recent_trust' and b['config'] == CONFIG)
            require(set(b['values']) == set(FOODS) and set(b['counts']) == set(FOODS))
            require(all(number(v, -1, 1) for v in b['values'].values()) and all(integer(v) for v in b['counts'].values()))
            require(isinstance(b['trust_counts'], list) and len(b['trust_counts']) == 2 and all(number(v, .001) for v in b['trust_counts']))
            require(integer(b['validation_count']) and integer(b['matches'], 0, b['validation_count']))
            for field in ('seen', 'validated'):
                require(isinstance(b[field], list) and len(b[field]) <= 1000 and all(text(v) for v in b[field]))
            for field in ('inbox', 'pending'):
                require(isinstance(b[field], dict) and len(b[field]) <= 1000)
                for key, m in b[field].items():
                    message(m, 'B' if k == 'A' else 'A')
                    require(key == (m['kind'] if field == 'inbox' else m['id']))
            require(isinstance(r['history'], list) and len(r['history']) <= 80)
            for h in r['history']:
                require(isinstance(h, dict) and integer(h.get('tick'), 0, t) and text(h.get('text')) and text(h.get('type')))
            c = r['last_choice']
            if c is not None:
                require(set(c) == {'tick', 'target', 'scores', 'reason'} and integer(c['tick'], 0, t)
                        and c['target'] in FOODS and text(c['reason']) and isinstance(c['scores'], dict)
                        and set(c['scores']) <= set(FOODS) and all(number(v, -2, 2) for v in c['scores'].values()))
        require(isinstance(d['events'], list) and len(d['events']) <= 200)
        for event in d['events']:
            require(isinstance(event, dict) and integer(event.get('id'), 1, d['sequence']) and integer(event.get('tick'), 0, t)
                    and text(event.get('text')) and text(event.get('type')))
        # Restrict payload to finite JSON primitives and a bounded document.
        require(len(json.dumps(d, allow_nan=False)) <= 1_000_000)
    except (KeyError, TypeError, OverflowError, AttributeError, RecursionError) as exc:
        raise ValueError('存档字段不完整或类型错误，当前世界未替换') from exc
