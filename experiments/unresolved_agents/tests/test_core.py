import copy
import json
from pathlib import Path
import subprocess
import sys
import unittest
LAB=Path(__file__).resolve().parents[1];sys.path.insert(0,str(LAB/'src'))
from core import Agent,Episode,e5,summarize
from verify import audit
C=json.loads((LAB/'protocols/e6-v1.json').read_text())


def ready(policy='persistent_adaptive'):
    a=Agent('B',policy,C)
    for t in range(4):a.experience('p',1,t)
    a.experience('q',-1,4)
    return a


def anomaly(a):
    # q last seen at4, two personal errors at6/7: signal before q is old enough.
    a.experience('p',-1,6);a.experience('p',-1,7)
    return a


class TicketTests(unittest.TestCase):
    def test_remembers_through_freshness_gate(self):
        a=anomaly(ready());self.assertEqual(a.ticket['created'],7)
        c=a.choose(300,8);self.assertEqual(c['requests'][0]['blocked'],'fresh')
        a.experience(c['target'],-1,8)
        self.assertEqual(a.ticket['created'],7)
        c=a.choose(300,15);self.assertEqual(c['reason'],'trigger_probe')
        a.experience('q',1,15);self.assertIsNone(a.ticket)
        self.assertEqual(a.last_ticket['events'][0]['event'],'resolved')

    def test_oneshot_expires_without_resolution(self):
        a=anomaly(ready('oneshot_adaptive'));c=a.choose(300,8);a.experience(c['target'],-1,8)
        c=a.choose(300,9);self.assertIsNone(a.ticket)
        self.assertEqual(a.ticket_events[0]['event'],'expired')

    def test_budget_block_retained_then_release(self):
        a=anomaly(ready());a.budget_used=1
        c=a.choose(300,12);self.assertEqual(c['requests'][0]['blocked'],'budget')
        a.experience(c['target'],-1,12);self.assertIsNotNone(a.ticket)
        self.assertEqual(a.choose(300,15)['reason'],'trigger_probe')

    def test_cooldown_retained(self):
        a=anomaly(ready());a.last_budget_tick=10
        c=a.choose(300,12);self.assertEqual(c['requests'][0]['blocked'],'cooldown')
        a.experience(c['target'],-1,12);self.assertEqual(a.choose(300,16)['reason'],'trigger_probe')

    def test_deadline_inclusive_and_expiry(self):
        a=anomaly(ready());self.assertEqual(a.ticket['expires'],19)
        self.assertEqual(a.choose(300,19)['reason'],'trigger_probe')
        b=anomaly(ready());c=b.choose(300,20)
        self.assertIsNone(b.ticket);self.assertEqual(b.ticket_events[0]['event'],'expired')

    def test_duplicate_does_not_extend_lifetime(self):
        a=anomaly(ready());before=copy.deepcopy(a.ticket)
        # Same signal observed at the same logical feedback tick; no scheduler renewal.
        a.values['p']=1;a.error_streak=2;a.error_kind='p';a.error_tick=7
        a.experience('p',-1,8)
        self.assertEqual(a.ticket,before)
        self.assertEqual(a.last_ticket['events'][-1]['event'],'signal_ignored')

    def test_message_cannot_resolve_but_personal_sample_can(self):
        a=anomaly(ready());a.receive(dict(id='A-8',source='A',tick=8,kind='q',claim=1),8)
        self.assertIsNotNone(a.ticket)
        a.choose(300,8);a.experience('q',1,8);self.assertIsNone(a.ticket)
        self.assertEqual(a.last_ticket['events'][-1]['event'],'resolved')

    def test_resolve_then_new_signal(self):
        a=anomaly(ready());a.counts['q']=4;a.values['q']=-1
        a.error_kind='q';a.error_tick=7;a.error_streak=1
        a.choose(300,8);a.experience('q',1,8)
        self.assertEqual([x['event'] for x in a.last_ticket['events']],['resolved','created'])
        self.assertEqual(a.ticket['candidate'],'p')

    def test_isolation_and_hidden_state(self):
        a=anomaly(ready());b=ready();self.assertIsNone(b.ticket)
        for key in ('scenarios','cases','change_at','seed_start'):self.assertNotIn(key,a.config)

    def test_legacy_and_fixed_identical_to_e5(self):
        for policy,old in [('legacy_adaptive','adaptive'),('fixed30','fixed_30')]:
            e=Episode(C,300,'noisy_stable',policy);f=e5.Episode(C,300,'noisy_stable',old)
            for _ in range(180):
                r=e.step();q=f.step()
                for a in ('A','B'):
                    r['choices'][a].pop('ticket_before');r['choices'][a].pop('ticket_at_decision');r['after'][a].pop('investigation')
                self.assertEqual(r,q)

    def test_all_policies_independent_audit(self):
        for policy in C['policies']:
            e=Episode(C,300,'swap@77',policy);r=[e.step() for _ in range(180)]
            self.assertEqual(audit(r,C,'swap@77',300,policy),3240)
            m=summarize(r,C,300,'swap@77',policy)['agents']['B']
            self.assertEqual(m['ticket_created'],m['ticket_resolved']+m['ticket_expired']+m['ticket_unresolved_end'])
            self.assertLessEqual(m['explorations'],12)

    def test_reject_corrupt_ticket(self):
        e=Episode(C,300,'swap@77','persistent_adaptive');r=[e.step() for _ in range(180)]
        t=next(i for i,x in enumerate(r) if x['after']['B']['investigation']['pending'])
        r[t]['after']['B']['investigation']['pending']['expires']+=1
        with self.assertRaises(AssertionError):audit(r,C,'swap@77',300,'persistent_adaptive')

    def test_fresh_process_ticket_restore(self):
        a=anomaly(ready());a.choose(300,8);snapshot=a.snapshot()
        code="import json,sys;from core import Agent;a=Agent.restore(json.load(sys.stdin));a.experience('p',-1,8);print(json.dumps(a.choose(300,15),sort_keys=True))"
        actual=subprocess.check_output([sys.executable,'-c',code],input=json.dumps(snapshot).encode(),cwd=LAB/'src')
        a.experience('p',-1,8);self.assertEqual(json.loads(actual),a.choose(300,15))

    def test_episode_restoration_and_noise_audit(self):
        e=Episode(C,301,'noisy_stable','persistent_adaptive');r=[e.step() for _ in range(80)]
        f=Episode.restore(json.loads(json.dumps(e.snapshot())))
        for _ in range(100):
            x=e.step();self.assertEqual(x,f.step());r.append(x)
        self.assertEqual(audit(r,C,'noisy_stable',301,'persistent_adaptive'),3240)
        with self.assertRaises(RuntimeError):e.step()

if __name__=='__main__':unittest.main()
