from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import unittest

LAB = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(LAB/'src'))
from core import Agent, Episode, changes, summarize, e3
from verify import audit
from report import interval
CFG = json.loads((LAB/'protocols/e4-v1.json').read_text())


def trained(strategy):
    a=Agent('B',strategy,CFG)
    a.experience('q',-1,0)
    for tick in range(1,20): a.experience('p',1,tick)
    return a


class BudgetTests(unittest.TestCase):
    def test_release_schedule_and_limit(self):
        a=Agent('A','hybrid',CFG)
        for tick,released in ((0,1),(14,1),(15,2),(164,11),(165,12),(999,12)):
            self.assertEqual(a.ledger(tick)['released'],released)

    def test_unknown_items_do_not_spend(self):
        e=Episode(CFG,100,'stable','hybrid')
        for _ in range(2):
            r=e.step()
            for c in r['choices'].values():
                self.assertEqual(c['reason'],'try_unknown')
                self.assertEqual(c['budget_after']['used'],0)

    def test_periodic_age_and_reserve(self):
        a=trained('hybrid')
        # At 20, two tokens released. Spend one on the 20-round-old item.
        c=a.choose(100,20)
        self.assertEqual((c['reason'],c['target']),('periodic_probe','q'))
        self.assertEqual(c['budget_after']['available'],1)
        a.experience('q',-1,20)
        # Isolate reservation with old q, a recent p, and cooldown satisfied.
        a.last_seen={'p':28,'q':0}
        c=a.choose(100,29)
        self.assertEqual(c['requests'][0]['blocked'],'reserve')
        self.assertIsNone(c['probe'])
        self.assertEqual(a.choose(100,30)['reason'],'periodic_probe')

    def test_trigger_priority_can_use_reserved_token(self):
        a=trained('hybrid')
        a.budget_used=1
        a.experience('p',-1,20)
        a.experience('p',-1,21)
        self.assertTrue(a.last_monitor['request_proposed'])
        c=a.choose(100,22)
        self.assertEqual((c['reason'],c['target']),('trigger_probe','q'))
        self.assertEqual(len(c['requests']),1)
        self.assertEqual(c['budget_after']['available'],0)

    def test_cooldown_budget_and_request_expiry(self):
        for used,last,block in ((2,-1000,'budget'),(1,20,'cooldown')):
            a=trained('trigger_only');a.budget_used=used;a.last_budget_tick=last
            a.experience('p',-1,20);a.experience('p',-1,21)
            c=a.choose(100,22)
            self.assertEqual(c['requests'][0]['blocked'],block)
            self.assertIsNone(a.request)
            self.assertEqual(a.choose(100,30)['requests'],[])

    def test_random_attempt_same_target_is_charged(self):
        found=False
        for seed in range(100,500):
            a=trained('budget_random');c=a.choose(seed,20)
            if c['probe'] and c['target']==c['base_target']:
                self.assertEqual(c['budget_after']['used'],1);found=True;break
        self.assertTrue(found)

    def test_no_hidden_background_random_or_world_schedule(self):
        for strategy in CFG['policies'][:-1]:
            a=trained(strategy)
            self.assertEqual(a.config['epsilon'],0)
            for k in ('cases','change_at','stagger_delay','noise_probability','rounds','seed_start'):
                self.assertNotIn(k,a.config)
        a=trained('trigger_only')
        a.receive({'id':'bad','source':'A','kind':'p','claim':-1,'tick':20},20)
        self.assertIsNone(a.request)

    def test_reference_rules_equal_e3(self):
        for scenario in ('stable','noisy_stable'):
            a=Episode(CFG,100,scenario,'e3_reference')
            b=e3.Episode(CFG,100,scenario,'surprise_stale')
            for _ in range(180):
                r,s=a.step(),b.step()
                for actor in ('A','B'):
                    for k,v in s['choices'][actor].items():self.assertEqual(r['choices'][actor][k],v)
                self.assertEqual(r['health'],s['health'])

    def test_asynchronous_and_hidden_rewards(self):
        e=Episode(CFG,100,'staggered@53','hybrid')
        self.assertEqual([e.potential(k,52)[0] for k in ('p','q')],[1,-.25])
        self.assertEqual([e.potential(k,53)[0] for k in ('p','q')],[-.75,-.25])
        self.assertEqual([e.potential(k,76)[0] for k in ('p','q')],[-.75,-1])
        e=Episode(CFG,101,'hidden_gain@91','hybrid')
        self.assertEqual([e.potential(k,90)[0] for k in ('p','q')],[-1,.5])
        self.assertEqual([e.potential(k,91)[0] for k in ('p','q')],[1,.5])
        self.assertEqual(changes(CFG,'staggered@91'),[91,114])

    def test_event_recovery_censored_at_next_change(self):
        e=Episode(CFG,100,'staggered@53','trigger_only')
        rows=[e.step() for _ in range(180)]
        # Synthetic evaluator fixture: always select p, so first segment never recovers.
        for row in rows: row['choices']['B']['target']='p'
        events=summarize(rows,CFG,100,'staggered@53','trigger_only')['agents']['B']['events']
        self.assertIsNone(events[0]['recovery'])
        self.assertEqual(events[0]['segment_end'],76)
        self.assertEqual(events[1]['recovery'],5)

    def test_new_process_pending_request_restore(self):
        e=Episode(CFG,100,'swap@27','hybrid');e.tick=22
        a=trained('hybrid');a.experience('p',-1,20);a.experience('p',-1,21);e.agents['B']=a
        data=json.dumps(e.snapshot())
        script='import sys,json;sys.path.insert(0,sys.argv[1]);from core import Episode;e=Episode.restore(json.load(sys.stdin));print(json.dumps([e.step() for _ in range(10)]))'
        out=subprocess.run([sys.executable,'-c',script,str(LAB/'src')],input=data,text=True,capture_output=True,check=True)
        self.assertEqual(json.loads(out.stdout),json.loads(json.dumps([e.step() for _ in range(10)])))

    def test_budget_bound_restore_and_independent_memory(self):
        for policy in CFG['policies']:
            e=Episode(CFG,101,'noisy_staggered@91',policy)
            for _ in range(92): e.step()
            restored=Episode.restore(json.loads(json.dumps(e.snapshot())))
            for _ in range(88):self.assertEqual(e.step(),restored.step())
            if policy!='e3_reference':
                for a in e.agents.values():self.assertLessEqual(a.budget_used,12)
            with self.assertRaises(RuntimeError):e.step()
        e=Episode(CFG,100,'stable','hybrid')
        e.agents['A'].values['q']=.7
        self.assertEqual(e.agents['B'].values['q'],0)

    def test_auditor_rejects_budget_and_reward_corruption(self):
        e=Episode(CFG,100,'staggered@91','hybrid')
        rows=json.loads(json.dumps([e.step() for _ in range(180)]))
        self.assertEqual(audit(rows,CFG,'staggered@91',100,'hybrid'),3240)
        bad=deepcopy(rows);bad[30]['choices']['B']['budget_after']['used']+=1
        with self.assertRaises(AssertionError):audit(bad,CFG,'staggered@91',100,'hybrid')
        bad=deepcopy(rows);bad[115]['choices']['B']['reward']+=.25
        with self.assertRaises(AssertionError):audit(bad,CFG,'staggered@91',100,'hybrid')

    def test_cost_account_and_interval(self):
        e=Episode(CFG,100,'stable','budget_random');rows=[e.step() for _ in range(180)]
        s=summarize(rows,CFG,100,'stable','budget_random')['agents']['B']
        self.assertEqual(s['explorations'],s['budget_used'])
        self.assertEqual(s['budget_used']+s['budget_unspent'],12)
        self.assertEqual(s['initial_unknown'],2)
        self.assertLessEqual(s['exploration_regret'],2*s['explorations'])
        self.assertEqual(interval([1.25]*50,CFG)['bootstrap_95'],[1.25,1.25])


if __name__=='__main__':unittest.main()
