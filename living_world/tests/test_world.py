"""Causal and persistence tests, not snapshot-of-implementation checks."""
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SRC = Path(__file__).resolve().parents[1] / 'src'
sys.path.insert(0, str(SRC))
from world import World, FOODS, HOMES, WALLS, NAMES, distance
from server import Runtime


class WorldTests(unittest.TestCase):
    def test_environment_does_not_leak_to_remote_memory_or_choice(self):
        baseline = World()
        changed = World.restore(baseline.snapshot())
        before = {k:r.snapshot() for k,r in changed.residents.items()}
        changed.intervene('p', -1, False)
        self.assertEqual(before, {k:r.snapshot() for k,r in changed.residents.items()})
        for _ in range(3):
            baseline.step(); changed.step()
        self.assertEqual(baseline.residents['A'].last_choice, changed.residents['A'].last_choice)
        self.assertEqual(baseline.residents['B'].snapshot(), changed.residents['B'].snapshot())

    def test_only_recipient_gets_hint_not_experience(self):
        w=World(); b=deepcopy(w.residents['B'].snapshot()); counts=dict(w.residents['A'].brain.counts)
        w.hint('A','q')
        self.assertEqual(b,w.residents['B'].snapshot())
        self.assertEqual(counts,w.residents['A'].brain.counts)
        self.assertEqual('q',w.residents['A'].choose(42,0))
        self.assertEqual(0,w.residents['A'].brain.values['q'])

    def test_hint_not_forced_over_strong_experience_and_not_teleport(self):
        w=World(); r=w.residents['A']
        r.brain.experience('p',1,0);r.brain.experience('q',-1,0)
        w.hint('A','q')
        choices=[r.choose(42,t) for t in range(1,60)]
        self.assertGreater(choices.count('p'),45)
        r.target='p';r.phase='outbound'; pos=list(r.pos)
        w.hint('A','q')
        self.assertEqual('p',r.target);self.assertEqual(pos,r.pos)

    def test_consumption_requires_contact_and_uses_current_truth(self):
        w=World();r=w.residents['A'];r.target='p'
        with self.assertRaises(ValueError):w.consume(r)
        r.pos=list(FOODS['p']);w.intervene('p',-1,True);w.consume(r)
        self.assertEqual(-1,r.brain.values['p']);self.assertEqual(1,r.brain.counts['p'])
        self.assertEqual(0,w.residents['B'].brain.counts['p'])

    def test_closed_supply_observed_locally_and_not_treated_as_bad_food(self):
        w=World();r=w.residents['A'];w.intervene('q',-1,False)
        self.assertNotIn('q',r.observed)
        r.pos=list(FOODS['q']);r.phase='outbound';r.target='q';w.step()
        self.assertFalse(r.observed['q']['available']);self.assertEqual(0,r.brain.counts['q'])
        self.assertEqual('homebound',r.phase)

    def test_peer_sharing_requires_proximity_and_keeps_personal_counts(self):
        w=World();r=w.residents['A'];r.target='p';r.pos=list(FOODS['p']);w.consume(r)
        w.share();self.assertEqual({},w.residents['B'].brain.inbox)
        r.pos=list(HOMES['A']);w.share()
        b=w.residents['B'];self.assertEqual(1,b.brain.inbox['p']['claim']);self.assertEqual(0,b.brain.counts['p'])
        n=len(w.events);w.share();self.assertEqual(n,len(w.events))
        self.assertEqual(0,b.brain.validation_count)
        b.pos=list(FOODS['p']);b.target='p';w.consume(b)
        self.assertEqual(1,b.brain.validation_count)

    def test_player_hint_not_relayed_as_peer_fact(self):
        w=World();w.hint('A','p');w.share()
        self.assertEqual({},w.residents['B'].brain.inbox)
        self.assertEqual([],w.residents['B'].hints)

    def test_exact_save_continuation_mid_action(self):
        w=World();w.hint('B','q')
        for _ in range(42):w.step()
        w.intervene('p',-1,True)
        other=World.restore(json.loads(json.dumps(w.snapshot())))
        for t in range(400):
            if t==70:
                w.intervene('q',1,True);other.intervene('q',1,True)
            if t==90:
                w.hint('A','q');other.hint('A','q')
            w.step();other.step();self.assertEqual(w.snapshot(),other.snapshot())

    def test_new_process_restore(self):
        w=World();w.hint('A','q')
        for _ in range(73):w.step()
        with tempfile.TemporaryDirectory() as tmp:
            source=Path(tmp)/'in.json';source.write_text(json.dumps(w.snapshot()))
            code='import json,sys; from world import World; w=World.restore(json.load(open(sys.argv[1]))); [w.step() for _ in range(80)]; print(json.dumps(w.snapshot()))'
            result=subprocess.check_output([sys.executable,'-c',code,str(source)],cwd=SRC,text=True)
            for _ in range(80):w.step()
            self.assertEqual(json.loads(result),json.loads(json.dumps(w.snapshot())))

    def test_long_run_bounded_state_and_valid_movement(self):
        w=World()
        for t in range(3000):
            if t==200:w.intervene('p',-1,True);w.intervene('q',1,True)
            if t==500:w.intervene('p',1,False);w.intervene('q',1,False)
            if t==650:w.intervene('p',1,True)
            if t%200==0:w.hint('B','p' if t%400 else 'q')
            old={k:list(r.pos) for k,r in w.residents.items()};w.step()
            for k,r in w.residents.items():
                self.assertLessEqual(distance(r.pos,old[k]),1)
                self.assertNotIn(tuple(r.pos),WALLS)
                self.assertTrue(0<=r.hunger<=100 and 0<=r.energy<=100)
            if t%100==0:World.restore(w.snapshot())
        self.assertTrue(all(sum(r.brain.counts.values())>20 for r in w.residents.values()))
        self.assertLess(len(json.dumps(w.snapshot())),150000)

    def test_bad_snapshot_rejected_transactionally(self):
        with tempfile.TemporaryDirectory() as tmp:
            rt=Runtime(tmp);rt.command({'action':'step'});before=rt.world.snapshot()
            cases=[]
            for field,value in [('version',99),('tick',-1),('resources',{}),('residents',{})]:
                bad=deepcopy(before);bad[field]=value;cases.append(bad)
            bad=deepcopy(before);bad['residents']['A']['brain']['config']['alpha']=99;cases.append(bad)
            bad=deepcopy(before);bad['residents']['A']['hunger']=float('nan');cases.append(bad)
            bad=deepcopy(before);bad['residents']['A']['phase']='fly';cases.append(bad)
            bad=deepcopy(before);bad['residents']['A']['pos']=[5,2];cases.append(bad)
            for bad in cases:
                with self.assertRaises(ValueError):rt.command({'action':'import','world':bad})
                self.assertEqual(before,rt.world.snapshot())

    def test_manual_and_auto_save_restore_paused(self):
        with tempfile.TemporaryDirectory() as tmp:
            rt=Runtime(tmp);rt.command({'action':'hint','actor':'B','kind':'q'})
            for _ in range(17):rt.command({'action':'step'})
            rt.command({'action':'save','slot':'slot1'});saved=rt.world.snapshot()
            rt.command({'action':'step'});rt.command({'action':'load','slot':'slot1'})
            self.assertEqual(saved,rt.world.snapshot());self.assertFalse(rt.running)
            fresh=Runtime(tmp);self.assertEqual(saved,fresh.world.snapshot());self.assertFalse(fresh.running)
            with self.assertRaises(ValueError):rt.command({'action':'save','slot':'../escape'})
            rt.command({'action':'new'});self.assertTrue((Path(tmp)/'slot1.json').exists())
            self.assertTrue((Path(tmp)/'before-restore.json').exists())


if __name__=='__main__':unittest.main()
