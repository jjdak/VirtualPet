"""E5: local outcome-based scheduling over frozen E4 budgeted reinspection."""
from copy import deepcopy
import importlib.util
from pathlib import Path

E4_PATH = Path(__file__).resolve().parents[2] / 'budgeted_agents/src/core.py'
spec = importlib.util.spec_from_file_location('e4_frozen', E4_PATH)
e4 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e4)
E2_PATH, E3_PATH = e4.E2_PATH, e4.E3_PATH


class Agent(e4.Agent):
    def __init__(self, name, frequency_policy, config):
        super().__init__(name, 'hybrid', config)
        self.frequency_policy = frequency_policy
        for key in ('frequency_initial','frequency_min','frequency_max','frequency_step','proxy_threshold'):
            self.config[key] = config[key]
        self.interval = config['frequency_initial'] if frequency_policy == 'adaptive' else int(frequency_policy.split('_')[1])
        self.config['periodic_age'] = self.interval
        self.pending_feedback = None
        self.last_frequency = None

    def choose(self, seed, tick):
        self.config['periodic_age'] = self.interval
        choice = super().choose(seed, tick)
        choice['interval_before'] = self.interval
        self.pending_feedback = ({'tick':tick,'target':choice['target'],
                                  'baseline_target':choice['base_target'],
                                  'baseline_estimate':choice['scores'][choice['base_target']]}
                                 if choice['probe'] is not None else None)
        return choice

    def experience(self, kind, reward, tick):
        checked = super().experience(kind, reward, tick)
        before = self.interval
        feedback, self.pending_feedback = self.pending_feedback, None
        gain, useful = None, None
        if feedback is not None:
            assert feedback['tick'] == tick and feedback['target'] == kind
            gain = reward-feedback['baseline_estimate']
            useful = gain >= self.config['proxy_threshold']
            if self.frequency_policy == 'adaptive':
                self.interval = (max(self.config['frequency_min'], before//2) if useful else
                                 min(self.config['frequency_max'], before+self.config['frequency_step']))
        self.config['periodic_age'] = self.interval
        self.last_frequency = dict(before=before,after=self.interval,proxy_gain=gain,useful=useful,
                                   evidence=deepcopy(feedback),observed=reward if feedback else None)
        return checked

    @classmethod
    def restore(cls, data):
        a = cls(data['name'],data['frequency_policy'],data['config'])
        a.__dict__.update(deepcopy(data))
        a.seen,a.validated = set(data['seen']),set(data['validated'])
        return a


class Episode(e4.Episode):
    def __init__(self, config, seed, scenario, policy):
        super().__init__(config,seed,scenario,policy)
        self.agents = {k:Agent(k,policy,config) for k in ('A','B')}

    def step(self):
        row = super().step()
        for k,a in self.agents.items():
            row['after'][k]['frequency'] = deepcopy(a.last_frequency)
        return row

    @classmethod
    def restore(cls,data):
        e = cls(data['config'],data['seed'],data['scenario'],data['policy'])
        e.tick,e.cached = data['tick'],deepcopy(data['cached'])
        e.world.positions = {k:tuple(v) for k,v in data['positions'].items()}
        e.world.health = dict(data['health'])
        e.agents = {k:Agent.restore(v) for k,v in data['agents'].items()}
        return e


def summarize(rows, config, seed, scenario, policy):
    result = e4.summarize(rows,config,seed,scenario,policy)
    for actor,metrics in result['agents'].items():
        fs = [r['after'][actor]['frequency'] for r in rows]
        metrics.update(mean_interval=sum(f['after'] for f in fs)/len(fs),final_interval=fs[-1]['after'],
                       shortenings=sum(f['after']<f['before'] for f in fs),
                       lengthenings=sum(f['after']>f['before'] for f in fs),
                       useful_probes=sum(f['useful'] is True for f in fs))
        for event in metrics['events']:
            start,end = event['change_at'],event['segment_end']
            changed = [k for k in ('p','q') if rows[start]['evaluation_only']['expected_rewards'][k] != rows[start-1]['evaluation_only']['expected_rewards'][k]]
            event['discovery_delay'] = next((i-start+1 for i in range(start,end) if rows[i]['choices'][actor]['target'] in changed),None)
    return result
