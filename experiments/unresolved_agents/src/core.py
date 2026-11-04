"""E6: bounded unresolved investigations over frozen E5 decisions and worlds."""
from copy import deepcopy
import importlib.util
from pathlib import Path

E5_PATH = Path(__file__).resolve().parents[2] / 'frequency_agents/src/core.py'
spec = importlib.util.spec_from_file_location('e5_frozen', E5_PATH)
e5 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e5)
E2_PATH, E3_PATH, E4_PATH = e5.E2_PATH, e5.E3_PATH, e5.E4_PATH
NEW_POLICIES = ('oneshot_adaptive', 'persistent_adaptive')


class Agent(e5.Agent):
    def __init__(self, name, experiment_policy, config):
        super().__init__(name, 'fixed_30' if experiment_policy == 'fixed30' else 'adaptive', config)
        self.experiment_policy = experiment_policy
        self.config['ticket_ttl'] = config['ticket_ttl']
        self.ticket = None
        self.ticket_events = []
        self.last_ticket = None

    def choose(self, seed, tick):
        self.ticket_events = []
        before = deepcopy(self.ticket)
        if self.experiment_policy not in NEW_POLICIES:
            choice = super().choose(seed, tick)
        else:
            if self.ticket is not None and tick > self.ticket['expires']:
                self.ticket_events.append(dict(event='expired',ticket=deepcopy(self.ticket)))
                self.ticket = None
            self.config['periodic_age'] = self.interval
            choice = e5.e4.e3.e2.Agent.choose(self, seed, tick)
            choice.update(base_target=choice['target'],base_reason=choice['reason'],probe=None,
                          interval_before=self.interval,budget_before=self.ledger(tick),requests=[])
            candidates = []
            if choice['reason'] != 'try_unknown':
                if self.ticket is not None:
                    candidates.append(('trigger',self.ticket['candidate'],deepcopy(self.ticket)))
                old = [k for k in ('p','q') if self.last_seen[k] is not None and tick-self.last_seen[k]>=self.interval]
                if old:
                    target = min(old,key=lambda k:self.last_seen[k])
                    candidates.append(('periodic',target,dict(last_seen=self.last_seen[target],age=tick-self.last_seen[target])))
                for source,target,evidence in candidates:
                    block = None;account = self.ledger(tick)
                    if source == 'trigger' and tick-self.last_seen[target] < self.config['stale_after']:
                        block = 'fresh'
                    elif account['available'] < 1: block = 'budget'
                    elif tick-self.last_budget_tick < self.config['budget_cooldown']: block = 'cooldown'
                    elif source == 'periodic' and account['available'] <= self.config['hybrid_reserve']: block = 'reserve'
                    receipt = dict(source=source,target=target,evidence=deepcopy(evidence),blocked=block)
                    choice['requests'].append(receipt)
                    if block is None:
                        self.budget_used+=1;self.probes_used+=1;self.last_budget_tick=tick
                        choice.update(target=target,reason=source+'_probe',probe=deepcopy(receipt));break
            choice['budget_after']=self.ledger(tick)
            self.pending_feedback = (dict(tick=tick,target=choice['target'],baseline_target=choice['base_target'],
                                          baseline_estimate=choice['scores'][choice['base_target']]) if choice['probe'] else None)
        choice['ticket_before'] = before
        choice['ticket_at_decision'] = deepcopy(self.ticket)
        return choice

    def experience(self, kind, reward, tick):
        checked = super().experience(kind,reward,tick)
        if self.experiment_policy in NEW_POLICIES:
            self.request = None  # This policy uses tickets, not E4's one-step request.
            if self.ticket is not None and kind == self.ticket['candidate'] and tick > self.ticket['created']:
                self.ticket_events.append(dict(event='resolved',ticket=deepcopy(self.ticket),observed=reward))
                self.ticket = None
            m = self.last_monitor
            signal = m['streak'] >= self.config['consecutive_errors'] and m['candidate_age'] is not None
            created = False
            if signal:
                if self.ticket is None:
                    ttl = self.config['ticket_ttl'] if self.experiment_policy == 'persistent_adaptive' else 1
                    self.ticket = dict(created=tick,expires=tick+ttl,candidate=m['candidate'],
                                       kind=kind,prediction=m['prediction'],observed=reward,
                                       residual=m['residual'],streak=m['streak'],candidate_age=m['candidate_age'])
                    self.ticket_events.append(dict(event='created',ticket=deepcopy(self.ticket)))
                    created = True
                else:
                    self.ticket_events.append(dict(event='signal_ignored',candidate=m['candidate'],reason='existing_ticket_first'))
            m['ticket_signal'] = signal
            m['request_proposed'] = created
        self.last_ticket = dict(pending=deepcopy(self.ticket),events=deepcopy(self.ticket_events))
        return checked

    @classmethod
    def restore(cls,data):
        a=cls(data['name'],data['experiment_policy'],data['config'])
        a.__dict__.update(deepcopy(data));a.seen,a.validated=set(data['seen']),set(data['validated'])
        return a


class Episode(e5.Episode):
    def __init__(self,config,seed,scenario,policy):
        # Avoid constructing E5 with an E6 policy label.
        super().__init__(config,seed,scenario,'fixed_30' if policy=='fixed30' else 'adaptive')
        self.policy=policy
        self.agents={k:Agent(k,policy,config) for k in ('A','B')}

    def step(self):
        row=super().step()
        for k,a in self.agents.items():row['after'][k]['investigation']=deepcopy(a.last_ticket)
        return row

    @classmethod
    def restore(cls,data):
        e=cls(data['config'],data['seed'],data['scenario'],data['policy'])
        e.tick,e.cached=data['tick'],deepcopy(data['cached'])
        e.world.positions={k:tuple(v) for k,v in data['positions'].items()};e.world.health=dict(data['health'])
        e.agents={k:Agent.restore(v) for k,v in data['agents'].items()}
        return e


def summarize(rows,config,seed,scenario,policy):
    result=e5.summarize(rows,config,seed,scenario,policy)
    for actor,m in result['agents'].items():
        inv=[r['after'][actor]['investigation'] for r in rows]
        for event in ('created','resolved','expired','signal_ignored'):
            m['ticket_'+event]=sum(x['event']==event for v in inv for x in v['events'])
        m['ticket_pending_rounds']=sum(v['pending'] is not None for v in inv)
        m['ticket_unresolved_end']=int(inv[-1]['pending'] is not None)
        m['blocked_fresh']=sum(q['blocked']=='fresh' for r in rows for q in r['choices'][actor]['requests'])
    return result
