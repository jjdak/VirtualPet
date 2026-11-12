"""A W2 resident uses the W1 decision rule with the evidence for today's weather."""
from copy import deepcopy

from world import CONFIG, FOODS, NAMES, Resident, World, e2, validate_snapshot

WEATHER = {'sun': '晴天', 'rain': '雨天'}
PERIOD = 80


class WeatherResident(Resident):
    # Weather is a public cue supplied by the world, not part of a W1 body save.
    __slots__ = ('weather',)

    def remember(self, tick, event_type, text, **data):
        super().remember(tick, event_type, f'{WEATHER[self.weather]} · {text}',
                         weather=self.weather, **data)

    def choose(self, seed, tick):
        target = super().choose(seed, tick)
        if target:
            self.reason = f'{WEATHER[self.weather]}出发。{self.reason}'
            self.last_choice['reason'] = self.reason
        return target


class ContextWorld(World):
    def __init__(self, seed=42):
        self.weather = 'sun'
        super().__init__(seed)
        self.auto = True
        self.change_at = PERIOD
        self.other_effects = {'p': -1, 'q': 1}
        self.residents = {name: WeatherResident(name) for name in NAMES}
        # Each pair holds one person's E2 estimates, inbox and own shareable reports.
        self.reserve = {}
        for name, person in self.residents.items():
            person.weather = self.weather
            self.reserve[name] = (e2.Agent(name, 'recent_trust', CONFIG), {})

    def emit(self, event_type, text, **extra):
        super().emit(event_type, f'{WEATHER[self.weather]} · {text}', weather=self.weather, **extra)

    def swap_evidence(self, name, person):
        active = (person.brain, person.latest)
        person.brain, person.latest = self.reserve[name]
        self.reserve[name] = active

    def change_weather(self, weather):
        if weather not in WEATHER:
            raise ValueError('天气需为晴天或雨天')
        if weather == self.weather:
            return
        for kind, resource in self.resources.items():
            resource['effect'], self.other_effects[kind] = self.other_effects[kind], resource['effect']
        self.weather = weather
        for name, person in self.residents.items():
            self.swap_evidence(name, person)
            person.weather = weather
        self.emit('weather', f'天气转为{WEATHER[weather]}。')

    def set_mode(self, mode):
        if mode == 'auto':
            self.auto = True
            self.change_at = self.tick + PERIOD
            self.emit('weather_control', '你开启了天气交替。')
        elif mode in WEATHER:
            self.change_weather(mode)
            self.auto = False
            self.change_at = None
            self.emit('weather_control', f'你固定了{WEATHER[mode]}。')
        else:
            raise ValueError('未知天气模式')

    def before_actions(self):
        if self.auto and self.tick == self.change_at:
            self.change_weather('rain' if self.weather == 'sun' else 'sun')
            self.change_at += PERIOD

    def snapshot(self):
        return dict(version=2, active=super().snapshot(), weather=self.weather,
                    auto=self.auto, change_at=self.change_at, other_effects=dict(self.other_effects),
                    reserve={name: dict(brain=brain.snapshot(), latest=deepcopy(latest))
                             for name, (brain, latest) in self.reserve.items()})

    @classmethod
    def restore(cls, data):
        if isinstance(data, dict) and data.get('version') == 1:
            raise ValueError('这是 W1 存档。请用 W1 入口打开，旧经历没有天气记录。')
        expected = {'version','active','weather','auto','change_at','other_effects','reserve'}
        try:
            if (not isinstance(data, dict) or set(data) != expected or type(data['version']) is not int
                    or data['version'] != 2 or data['weather'] not in WEATHER or type(data['auto']) is not bool):
                raise ValueError('无效的 W2 天气存档')
            active = World.restore(data['active'])
            at = data['change_at']
            if (data['auto'] and not (type(at) is int and active.tick < at <= active.tick + PERIOD)
                    or not data['auto'] and at is not None):
                raise ValueError('天气时钟无效')
            effects = data['other_effects']
            if set(effects) != set(FOODS) or any(type(v) is not int or v not in (-1, 1) for v in effects.values()):
                raise ValueError('另一种天气的食物效果无效')
            reserve = data['reserve']
            if set(reserve) != set(NAMES):
                raise ValueError('缺少个人天气记忆')
            # Apply the same W1 checks to both banks (including message source and time).
            opposite = deepcopy(data['active'])
            for name, bank in reserve.items():
                if set(bank) != {'brain', 'latest'}:
                    raise ValueError('个人天气记忆格式错误')
                opposite['residents'][name].update(bank)
            validate_snapshot(opposite)
            w = cls(active.seed)
            w.tick, w.events, w.sequence, w.resources = active.tick, active.events, active.sequence, active.resources
            w.weather, w.auto, w.change_at = data['weather'], data['auto'], at
            w.other_effects = dict(effects)
            for name, person in w.residents.items():
                person.__dict__.update(active.residents[name].__dict__)
                person.weather = w.weather
                bank = reserve[name]
                w.reserve[name] = (e2.Agent.restore(bank['brain']), deepcopy(bank['latest']))
            return w
        except (KeyError, TypeError, AttributeError) as exc:
            raise ValueError('天气存档字段错误') from exc

    def view(self):
        result = super().view()
        other = 'rain' if self.weather == 'sun' else 'sun'
        result['weather'] = self.weather
        result['auto_weather'] = self.auto
        result['change_at'] = self.change_at
        for name, person in self.residents.items():
            banks = {self.weather: person.brain, other: self.reserve[name][0]}
            result['residents'][name]['context_memory'] = {
                weather: {'values': dict(brain.values), 'counts': dict(brain.counts)}
                for weather, brain in banks.items()}
        return result
