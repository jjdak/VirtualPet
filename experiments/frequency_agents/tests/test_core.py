import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import unittest

LAB=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(LAB/'src'))
from core import Agent,Episode,e4
from verify import audit
C=json.loads((LAB/'protocols/e5-v1.json').read_text())


def familiar():
    a=Agent('B','adaptive',C)
    for k,r in [('p',.5),('q',-1)]:a.experience(k,r,0)
    return a


class FrequencyTests(unittest.TestCase):
    def test_unhelpful_probe_backs_off(self):
        a=familiar();c=a.choose(200,18)
        self.assertIsNotNone(c['probe']);a.experience(c['target'],-1,18)
        self.assertEqual(a.interval,24)
        self.assertEqual(a.last_frequency['proxy_gain'],-1.5)

    def test_useful_probe_shrinks_next_interval(self):
        a=familiar();c=a.choose(200,18);self.assertEqual(c['interval_before'],18)
        a.experience(c['target'],1,18)
        self.assertEqual(a.interval,9);self.assertEqual(a.last_frequency['proxy_gain'],.5)
        self.assertEqual(a.choose(200,19)['interval_before'],9)

    def test_threshold_and_bounds(self):
        for interval,gain,expected in [(18,.25,9),(18,.249,24),(6,.5,6),(42,-.5,42),(9,.5,6)]:
            a=familiar();a.interval=interval
            a.pending_feedback={'tick':10,'target':'q','baseline_target':'p','baseline_estimate':.5}
            a.experience('q',.5+gain,10);self.assertEqual(a.interval,expected)

    def test_rejected_and_ordinary_actions_do_not_update(self):
        a=familiar();a.interval=6;c=a.choose(200,6)
        self.assertEqual(c['requests'][0]['blocked'],'reserve')
        a.experience(c['target'],-1,6);self.assertEqual(a.interval,6)
        self.assertIsNone(a.last_frequency['proxy_gain'])
        c=a.choose(200,7);a.experience(c['target'],1,7);self.assertEqual(a.interval,6)

    def test_messages_and_other_actor_do_not_change_interval(self):
        a,b=familiar(),familiar()
        a.receive(dict(id='A-2',source='A',tick=2,kind='q',claim=1),2)
        self.assertEqual(a.interval,18)
        c=a.choose(200,18);a.experience(c['target'],-1,18)
        self.assertEqual(b.interval,18)
        for k in ('cases','scenarios','change_at','seed_start','trace_cases'):self.assertNotIn(k,a.config)

    def test_trigger_feedback_same_rule(self):
        a=familiar();a.interval=42
        a.request=dict(tick=29,candidate='q')
        c=a.choose(200,30);self.assertEqual(c['probe']['source'],'trigger')
        a.experience('q',1,30);self.assertEqual(a.interval,21)

    def test_fixed18_exact_e4_hybrid(self):
        for case in ('stable','noisy_stable','hidden_gain@77','staggered@119'):
            e=Episode(C,201,case,'fixed_18');old=e4.Episode(C,201,case,'hybrid')
            for _ in range(C['rounds']):
                r=e.step();previous=old.step()
                for a in ('A','B'):
                    r['choices'][a].pop('interval_before');r['after'][a].pop('frequency')
                self.assertEqual(r,previous)

    def test_all_strategies_budget_and_independent_audit(self):
        for policy in C['policies']:
            e=Episode(C,200,'noisy_stable',policy);rows=[e.step() for _ in range(180)]
            self.assertEqual(audit(rows,C,'noisy_stable',200,policy),3240)
            for a in e.agents.values():self.assertLessEqual(a.budget_used,12)

    def test_audit_rejects_corrupt_gain_and_score(self):
        e=Episode(C,200,'stable','adaptive');rows=[e.step() for _ in range(180)]
        t=next(i for i,r in enumerate(rows) if r['choices']['B']['probe'])
        for location in ('gain','score','budget'):
            bad=copy.deepcopy(rows)
            if location=='gain':bad[t]['after']['B']['frequency']['proxy_gain']+=1
            elif location=='score':bad[t]['choices']['B']['scores']['p']+=.2
            else:bad[t]['choices']['B']['budget_after']['used']+=1
            with self.assertRaises(AssertionError):audit(bad,C,'stable',200,'adaptive')

    def test_pending_feedback_fresh_process_restore(self):
        a=familiar();c=a.choose(200,18);snapshot=a.snapshot()
        code="import sys,json;from core import Agent;a=Agent.restore(json.load(sys.stdin));a.experience(a.pending_feedback['target'],1,18);print(json.dumps(a.snapshot(),sort_keys=True))"
        actual=subprocess.check_output([sys.executable,'-c',code],input=json.dumps(snapshot).encode(),cwd=LAB/'src')
        a.experience(c['target'],1,18);self.assertEqual(json.loads(actual),json.loads(json.dumps(a.snapshot())))

    def test_episode_restore_across_change(self):
        e=Episode(C,201,'hidden_gain@77','adaptive')
        for _ in range(79):e.step()
        restored=Episode.restore(json.loads(json.dumps(e.snapshot())))
        for _ in range(101):self.assertEqual(e.step(),restored.step())
        with self.assertRaises(RuntimeError):e.step()

    def test_stable_interval_reaches_cap(self):
        e=Episode(C,200,'stable','adaptive');rows=[e.step() for _ in range(180)]
        a=e.agents['B'];self.assertEqual(a.interval,42)
        self.assertLess(a.budget_used,9)
        from core import summarize
        s=summarize(rows,C,200,'stable','adaptive')['agents']['B']
        self.assertEqual(s['shortenings'],0);self.assertEqual(s['initial_unknown'],2)

if __name__=='__main__':unittest.main()
