"""Test departure coupling independently of archived outcome counts."""
from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'living_world/studies'))
from w3_coupling import (CHOOSE, MODES, OUT, ContextWorld, aggregate, alignment,
                         draws, instrument, key, relay_history, run_pair, source_rows, study, runtime)


class DepartureCoupling(unittest.TestCase):
    def test_departure_number_survives_save_and_weather_and_ignores_clock(self):
        w=ContextWorld(19)
        for _ in range(180):
            w.step()
        snapshot=w.snapshot()
        a=ContextWorld.restore(snapshot)
        b=ContextWorld.restore(snapshot)
        b.set_mode('rain' if a.weather=='sun' else 'sun')
        expected=a.residents['A'].decisions+1
        self.assertEqual(b.residents['A'].decisions+1,expected)
        samples=[]
        for world,tick in ((a,300),(b,307)):
            events={n:[] for n in runtime.NAMES}
            with instrument('departure',events,0):
                world.residents['A'].choose(19,tick)
            samples.append(events['A'][0])
        self.assertEqual(samples[0]['draws'],samples[1]['draws'])
        self.assertEqual(samples[0]['draws'],draws(19,'A',expected))
        self.assertNotEqual(draws(19,'A',300),draws(19,'A',307))
        self.assertIs(type(a.residents['A']).choose,CHOOSE)
        self.assertEqual(w.snapshot(),snapshot)

    def test_same_random_inputs_do_not_force_same_choice(self):
        worlds=[ContextWorld(1),ContextWorld(1)]
        for i,w in enumerate(worlds):
            p=w.residents['A']
            p.brain.counts={'p':1,'q':1}
            p.brain.values={'p':1 if i==0 else -1,'q':-1 if i==0 else 1}
            # Select a known non-exploratory departure index.
            p.decisions=next(n-1 for n in range(1,100) if draws(1,'A',n)[0]>.1)
        records=[]
        for w in worlds:
            events={n:[] for n in runtime.NAMES}
            with instrument('departure',events,0):
                w.residents['A'].choose(1,500)
            records.append(events['A'][0])
        self.assertEqual(records[0]['draws'],records[1]['draws'])
        self.assertEqual([r['target'] for r in records],['p','q'])

    def test_no_hint_identical_replays_and_empty_supply_does_not_increment(self):
        snapshot=ContextWorld(7).snapshot()
        for mode in MODES:
            result,events=run_pair(snapshot,'A',None,mode,end=320)
            for p in result['people'].values():
                self.assertEqual(p['behavior']['steps'],0)
                self.assertEqual(p['aligned']['all']['different'],0)
                self.assertFalse(p['memory']['value_difference'])
            self.assertEqual(events['control'],events['hinted'])
        w=ContextWorld(7)
        p=w.residents['A']
        p.observed={k:dict(available=False,tick=500) for k in runtime.FOODS}
        original=p.decisions
        events={n:[] for n in runtime.NAMES}
        config=deepcopy(runtime.CONFIG)
        with instrument('departure',events,0):
            self.assertIsNone(p.choose(7,500))
        self.assertEqual(p.decisions,original)
        self.assertEqual(events['A'],[])
        self.assertEqual(runtime.CONFIG,config)

    def test_tail_alignment_excludes_cross_boundary_and_unmatched(self):
        def event(n,t,target,weather='sun'):
            return dict(n=n,t=t,target=target,weather=weather,draws=draws(1,'A',n))
        left=[event(10,2150,'p'),event(11,2200,'q'),event(12,2300,'q')]
        right=[event(10,2170,'q'),event(11,2210,'p','rain')]
        result=alignment(left,right,'departure')
        self.assertEqual(result['tail_cross_boundary'],1)
        self.assertEqual(result['tail']['matched'],1)
        self.assertEqual(result['tail']['destination_different_other_weather'],1)
        self.assertEqual(result['tail_unpaired'],1)
        self.assertEqual(result['all']['different'],2)

    def test_checkpoint_is_frozen_while_the_longer_rollout_continues(self):
        from w3_coupling import rebuild
        row=next(r for r in source_rows() if key(r)==('primary',19,0,'A','q'))
        snapshot=rebuild(row['family'],row)
        short,_=run_pair(snapshot,'A','q','clock',end=240)
        long,_=run_pair(snapshot,'A','q','clock',end=2640)
        self.assertEqual(short['at240'],long['at240'])
        self.assertEqual(long['at240']['A'],row['recipient'])
        self.assertEqual(long['at240']['B'],row['peer'])

    def test_archive_integrity_summary_and_selected_fresh_replays(self):
        summary=json.loads((OUT/'summary.json').read_text())
        source=OUT/'cases.jsonl'
        self.assertEqual(sha256(source.read_bytes()).hexdigest(),summary['cases_sha256'])
        rows=[json.loads(s) for s in source.read_text().splitlines()]
        original={key(r):r for r in source_rows()}
        self.assertEqual(len(rows),640)
        self.assertEqual({key(r) for r in rows},set(original))
        for family in ('primary','reversal'):
            for mode in MODES:
                self.assertEqual(aggregate([r for r in rows if r['family']==family],mode),summary['families'][family][mode])
        examples=json.loads((OUT/'examples.json').read_text())
        selected={key(e['key']) for e in examples}|{key(rows[0])}
        for row in rows:
            if key(row) in selected:
                actual,trips=study(original[key(row)])
                self.assertEqual(actual,row)
                prior=next((e for e in examples if key(e['key'])==key(row)),None)
                if prior:
                    self.assertEqual(prior['trips'],trips)
                    if prior['first_peer']:
                        self.assertEqual(relay_history(original[key(row)],actual),
                            json.loads((OUT/'relay-history.json').read_text()))
        for path,digest in summary['source_sha256'].items():
            self.assertEqual(sha256((ROOT/path).read_bytes()).hexdigest(),digest)


if __name__=='__main__':
    unittest.main()
