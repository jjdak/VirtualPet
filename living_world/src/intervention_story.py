"""Observe real fork events and explain a single report's route without changing policy.

Every observer belongs to one restored world. No global monkeypatch or save schema change.
"""
from copy import deepcopy
import random

from context_world import ContextWorld
from fork_study import body, compare
from world import CONFIG


class ObservedWorld(ContextWorld):
    def __init__(self, seed=42):
        self.observations=[]
        super().__init__(seed)

    def emit(self, event_type, text, **extra):
        super().emit(event_type,text,**extra)
        event=deepcopy(self.events[-1])
        if event_type=='experience':
            event['report_id']=self.residents[extra['actor']].latest[extra['kind']]['id']
        elif event_type=='empty':
            event['kind']=self.residents[extra['actor']].target
        elif event_type=='message':
            receiver=self.residents[extra['receiver']]
            report=next(m for m in receiver.brain.inbox.values()
                        if m['source']==extra['sender'] and m['tick']==extra['evidence_tick'])
            event['report']=deepcopy(report)
        elif event_type=='decision':
            person=self.residents[extra['actor']]
            event.update(deepcopy(person.last_choice))
            previous=[e for e in person.history if e['type']=='decision' and e['tick']<self.tick]
            event['previous_target']=previous[-1]['target'] if previous else None
            eligible=list(person.last_choice['scores'])
            draw=random.Random(self.seed*100003+self.tick*97+(17 if person.name=='B' else 0)).random()
            event['route']=('unknown' if any(person.brain.counts[k]==0 for k in eligible)
                            else 'explore' if draw<CONFIG['epsilon'] else 'estimated_value')
            event['own_values']=dict(person.brain.values)
            event['reports']=[]
            for kind,message in person.brain.inbox.items():
                age=self.tick-message['tick']
                if not 0<=age<=CONFIG['message_ttl']:
                    continue
                # Same real tick, random inputs and trust; remove only this exact report.
                probe=deepcopy(person)
                del probe.brain.inbox[kind]
                without=probe.choose(self.seed,self.tick)
                event['reports'].append(dict(message=deepcopy(message),age=age,
                    without_report_target=without,changes_target=without!=person.last_choice['target']))
        self.observations.append(event)


def story_from_events(observations, result):
    actor,kind=result['actor'],result['kind']
    peer='B' if actor=='A' else 'A'
    start=result['start']
    hinted,control=(observations[s] for s in ('hinted','control'))
    hint=next(e for e in hinted if e['type']=='hint' and e['actor']==actor and e['tick']==start)
    cutoff=start+(result['hint_end'] if result['hint_end'] is not None else result['horizon'])
    experience=next((e for e in hinted if e['type']=='experience' and e['actor']==actor
                     and e['kind']==kind and start<e['tick']<=cutoff),None)
    empty_visit=next((e for e in hinted if e['type']=='empty' and e['actor']==actor
                      and e['kind']==kind and start<e['tick']<=cutoff),None)
    delivery=next((e for e in hinted if experience and e['type']=='message'
                   and e['sender']==actor and e['receiver']==peer
                   and e['report']['id']==experience['report_id']
                   and e['weather']==experience['weather']),None)
    candidates=[]
    if delivery:
        for event in hinted:
            if event['type']!='decision' or event['actor']!=peer or event['tick']<=delivery['tick']:
                continue
            report=next((r for r in event['reports'] if r['message']['id']==delivery['report']['id']),None)
            if report is None or event['weather']!=delivery['weather']:
                continue
            baseline=next((e for e in control if e['type']=='decision' and e['actor']==peer
                           and e['tick']==event['tick']),None)
            supported=(event['route']=='estimated_value' and report['changes_target'] and baseline is not None
                       and baseline['target']!=event['target'] and result['silent']['people'][peer]['steps']==0
                       and event['previous_target'] is not None and event['previous_target']!=event['target'])
            candidates.append(dict(event=event,report_test=report,control_choice=baseline,supported=supported))
    choice=next((c for c in candidates if c['supported']),candidates[0] if candidates else None)
    same_experience=bool(experience and any(e['type']=='experience' and e['actor']==actor
        and e['tick']==experience['tick'] and e['kind']==kind and e['reward']==experience['reward'] for e in control))
    nodes=[dict(key='hint',offset=0,event=hint),
           dict(key='experience',offset=experience['tick']-start if experience else None,event=experience,
                same_in_control=same_experience,empty_visit=empty_visit),
           dict(key='delivery',offset=delivery['tick']-start if delivery else None,event=delivery),
           dict(key='choice',offset=choice['event']['tick']-start if choice else None,event=choice)]
    return dict(version=1,actor=actor,peer=peer,kind=kind,nodes=nodes,
                supported=bool(choice and choice['supported']),hint_status=result['hint_status'],
                hint_end=result['hint_end'],horizon=result['horizon'])


def explain(snapshot, actor, kind, horizon=240):
    result=compare(snapshot,actor,kind,horizon=horizon,frames=True)
    observations={}
    for side in ('control','hinted'):
        world=ObservedWorld.restore(snapshot)
        world.observations=[]  # Drop initialization events, never revive pre-fork history as a new event.
        if side=='hinted':
            world.hint(actor,kind)
        for offset in range(horizon+1):
            if offset:
                world.step()
            expected=result['frames'][offset]
            assert world.weather==expected['weather']
            for name,person in world.residents.items():
                assert body(person,world.tick if offset else -1)==expected[side][name]
        observations[side]=world.observations
    result['story']=story_from_events(observations,result)
    return result
