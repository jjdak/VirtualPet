"""A short W5 scene from a prepared W2 world, through B's next departure."""
from functools import lru_cache

from context_world import ContextWorld
from fork_server import example
from world import FOODS, HEIGHT, HOMES, WIDTH, WALLS

OPENINGS = ('fork', 'camp')
MAX_STEPS = 32


@lru_cache(maxsize=len(OPENINGS))
def origin(opening):
    if opening == 'fork':
        world = ContextWorld(1)
        world.set_mode('sun')
        world.intervene('q', 1, True)
        world.residents['B'].hunger = 36.4
        end = 336
    elif opening == 'camp':
        world = ContextWorld.restore(example('reversal')['snapshot'])
        world.hint('A', 'q')
        end = 536
    else:
        raise ValueError('没有这个开场。')
    while world.tick < end:
        world.step()
    report = world.residents['A'].latest['q']
    heard = world.residents['B'].brain.inbox.get('q', {})
    if report['tick'] != end or heard.get('id') == report['id']:
        raise RuntimeError('开场没有停在这条亲历送达之前。')
    return world.snapshot()


class Scene:
    def __init__(self, opening):
        self.world = ContextWorld.restore(origin(opening))
        self.start, self.sequence = self.world.tick, self.world.sequence
        self.departure = None
        self.hint = None

    def advance(self, elapsed, hint=None):
        if self.world.tick - self.start > elapsed:
            raise ValueError('本幕只能向前等待。')
        while True:
            offset = self.world.tick - self.start
            if hint and hint['offset'] == offset:
                if self.departure:
                    raise ValueError('提醒必须发生在小岚出发之前。')
                if self.hint:
                    raise ValueError('本幕只能提醒一次。')
                self.world.hint('B', hint['kind'])
                self.hint = hint
            if offset == elapsed:
                return
            self.step()

    def step(self):
        if self.departure:
            raise ValueError('小岚已出发，本幕到此结束。')
        self.world.step()
        last = self.world.residents['B'].last_choice
        if last and last['tick'] == self.world.tick:
            self.departure = {'offset': self.world.tick - self.start, 'kind': last['target']}

    def events(self):
        return [event for event in self.world.events
                if event['id'] > self.sequence or (
                    event['tick'] == self.start and event['type'] == 'experience'
                    and event['actor'] == 'A' and event['kind'] == 'q')]

    def speech(self):
        # Only count the player's reminder and A's specific report in this scene.
        for event in self.events():
            if event['type'] == 'decision' and event['actor'] == 'B':
                break
            if event['type'] == 'hint':
                return {'speaker': 'player', 'offset': event['tick'] - self.start}
            if (event['type'] == 'message' and event['sender'] == 'A'
                    and event['evidence_tick'] == self.start):
                return {'speaker': 'A', 'offset': event['tick'] - self.start}
        return None

    def public_view(self):
        return dict(
            start=self.start, elapsed=self.world.tick - self.start, weather=self.world.weather,
            food={kind: {'available': item['available']} for kind, item in self.world.resources.items()},
            map=dict(width=WIDTH, height=HEIGHT, food=FOODS, home=HOMES, walls=sorted(WALLS)),
            people={name: dict(pos=person.pos, phase=person.phase, target=person.target,
                               firsthand=person.latest, heard=person.brain.inbox)
                    for name, person in self.world.residents.items()},
            events=self.events(), hint=self.hint, ended=self.departure is not None,
        )


def frame(opening, elapsed, hint):
    if opening not in OPENINGS or type(elapsed) is not int or not 0 <= elapsed <= MAX_STEPS:
        raise ValueError('开场或步数无效。')
    if hint is not None and (not isinstance(hint, dict) or set(hint) != {'offset', 'kind'}
            or type(hint['offset']) is not int or not 0 <= hint['offset'] <= elapsed
            or hint['kind'] != 'q'):
        raise ValueError('地点提醒无效。')

    scene = Scene(opening)
    scene.advance(elapsed, hint)
    result = scene.public_view()
    if scene.departure:
        waiting = Scene(opening)
        for _ in range(MAX_STEPS):
            waiting.step()
            if waiting.departure:
                break
        if waiting.departure is None:
            raise RuntimeError('这个开场的等待对照没有走到出发。')
        result['result'] = dict(actual=scene.departure, waiting=waiting.departure,
                                first=scene.speech(), waiting_first=waiting.speech())
    return result
