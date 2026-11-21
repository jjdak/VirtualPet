"""W4 provenance, conservative attribution, and observer isolation contracts."""
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'src'))
from context_world import ContextWorld
from fork_server import example
from fork_study import compare
from intervention_story import ObservedWorld, explain, story_from_events


def events(snapshot,actor='A',kind='q',horizon=240):
    output={}
    for side in ('hinted','control'):
        world=ObservedWorld.restore(snapshot)
        world.observations=[]
        if side=='hinted':
            world.hint(actor,kind)
        for _ in range(horizon):
            world.step()
        output[side]=world.observations
    return output


class StoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.snapshot=example('reversal')['snapshot']
        cls.result=explain(cls.snapshot,'A','q')
        cls.events=events(cls.snapshot)

    def test_exact_experience_delivery_and_decision(self):
        story=self.result['story']
        self.assertEqual([n['offset'] for n in story['nodes']],[0,56,59,66])
        _,experience,delivery,choice=story['nodes']
        report=experience['event']['report_id']
        self.assertEqual(report,'A:536')
        self.assertEqual(delivery['event']['report']['id'],report)
        decision=choice['event']
        self.assertEqual(decision['report_test']['message']['id'],report)
        self.assertEqual(decision['event']['target'],'q')
        self.assertEqual(decision['event']['previous_target'],'p')
        self.assertEqual(decision['control_choice']['target'],'p')
        self.assertEqual(decision['report_test']['without_report_target'],'p')
        self.assertTrue(story['supported'])
        self.assertEqual(self.result['message_first'],54)  # A different report, not our +59 delivery.

    def test_original_comparison_and_input_unchanged(self):
        before=deepcopy(self.snapshot)
        annotated=explain(self.snapshot,'A','q')
        annotated.pop('story')
        self.assertEqual(annotated,compare(self.snapshot,'A','q',frames=True))
        self.assertEqual(self.snapshot,before)

    def test_full_save_state_unchanged_by_observer_across_weather(self):
        snapshot=example('step700')['snapshot']
        observed,reference=ObservedWorld.restore(snapshot),ContextWorld.restore(snapshot)
        observed.set_mode('auto');reference.set_mode('auto')
        observed.hint('B','p');reference.hint('B','p')
        for _ in range(240):
            observed.step();reference.step()
            self.assertEqual(observed.snapshot(),reference.snapshot())
        self.assertTrue(any(e['type']=='weather' for e in observed.observations))

    def test_parallel_requests_are_independent(self):
        jobs=[('A','q'),('B','p'),('A','p'),('B','q')]
        expected=[explain(self.snapshot,a,k) for a,k in jobs]
        with ThreadPoolExecutor(max_workers=2) as pool:
            actual=list(pool.map(lambda job:explain(self.snapshot,*job),jobs))
        self.assertEqual(actual,expected)

    def test_unrelated_report_cannot_complete_chain(self):
        altered=deepcopy(self.events)
        for event in altered['hinted']:
            if event['type']=='message' and event['report']['id']=='A:536':
                event['report']['id']='A:other-experience'
        story=story_from_events(altered,self.result)
        self.assertIsNone(story['nodes'][2]['event'])
        self.assertIsNone(story['nodes'][3]['event'])
        self.assertFalse(story['supported'])

    def test_exploration_and_asynchronous_baseline_cannot_claim_causality(self):
        for case in ('explore','unknown','no_simultaneous_control','unchanged_target','silent_difference'):
            altered=deepcopy(self.events);result=deepcopy(self.result)
            for e in altered['hinted']:
                if e['type']=='decision' and e['actor']=='B':
                    if case in ('explore','unknown'):e['route']=case
                    if case=='unchanged_target':e['previous_target']=e['target']
            if case=='no_simultaneous_control':
                altered['control']=[e for e in altered['control'] if not(e['type']=='decision' and e['actor']=='B')]
            if case=='silent_difference':result['silent']['people']['B']['steps']=1
            with self.subTest(case=case):
                self.assertFalse(story_from_events(altered,result)['supported'])

    def test_same_tick_message_arrives_after_decision(self):
        altered=deepcopy(self.events)
        for e in altered['hinted']:
            if e['type']=='message' and e['report']['id']=='A:536':e['tick']=546
        story=story_from_events(altered,self.result)
        choice=story['nodes'][3]
        self.assertTrue(choice['offset'] is None or choice['offset']>66)

    def test_short_window_does_not_reuse_prior_experience(self):
        result=explain(self.snapshot,'A','q',20)
        self.assertEqual([n['offset'] for n in result['story']['nodes']],[0,None,None,None])
        self.assertIsNone(result['hint_end'])
        self.assertFalse(result['story']['supported'])

    def test_expired_hint_has_no_fabricated_experience(self):
        snapshot=ContextWorld(1).snapshot()
        for p in snapshot['active']['residents'].values():
            p['next_departure']=100;p['hunger']=0
            p['observed']={k:{'available':False,'tick':0} for k in ('p','q')}
        for resource in snapshot['active']['resources'].values():resource['available']=False
        result=explain(snapshot,'A','q',110)
        self.assertEqual(result['hint_status'],'expired')
        self.assertIsNone(result['story']['nodes'][1]['event'])
        self.assertFalse(result['story']['supported'])

    def test_empty_visit_is_not_food_experience(self):
        world=ContextWorld(1);world.set_mode('sun')
        world.resources['q']['available']=False
        a=world.residents['A'];a.pos=[8,3];a.target='q';a.phase='outbound'
        result=explain(world.snapshot(),'A','q',10)
        self.assertEqual(result['hint_status'],'visited')
        self.assertIsNone(result['story']['nodes'][1]['event'])
        self.assertEqual(result['story']['nodes'][1]['empty_visit']['kind'],'q')
        self.assertIsNone(result['story']['nodes'][2]['event'])

    def test_same_experience_in_zero_effect_worlds_is_disclosed(self):
        snapshot=example('study')['snapshot']
        result=explain(snapshot,'A','q')
        self.assertEqual(result['people']['A']['steps'],0)
        self.assertEqual(result['people']['B']['steps'],0)
        self.assertTrue(result['story']['nodes'][1]['same_in_control'])
        self.assertFalse(result['story']['supported'])


if __name__=='__main__':unittest.main()
