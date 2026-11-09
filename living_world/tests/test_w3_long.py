"""Checks for censored-cohort selection, evidence thresholds and actual follow-up choices."""
import json
from pathlib import Path
import sys
import unittest
from collections import Counter

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'living_world/studies'))
from w3_long import ARCHIVE, OUTPUT, END, START, rebuild, window_result, person_result, first_realign
from context_world import ContextWorld


class ExtendedObservationTests(unittest.TestCase):
    def test_complete_union_including_peer_only_cases(self):
        inputs = {'primary':[json.loads(s) for s in (ARCHIVE/'pairs.jsonl').read_text().splitlines()],
                  'reversal':json.loads((ARCHIVE/'reversal.json').read_text())['pairs']}
        expected = {(f,r['seed'],r['age'],r['actor'],r['kind']): (r['recipient']['at_end'],r['peer']['at_end'])
                    for f,rows in inputs.items() for r in rows if r['recipient']['at_end'] or r['peer']['at_end']}
        actual = [json.loads(s) for s in (OUTPUT/'cases.jsonl').read_text().splitlines()]
        self.assertEqual(len(actual),len(expected))
        for r in actual:
            key = (r['family'],r['seed'],r['age'],r['actor'],r['kind'])
            self.assertEqual(expected.pop(key), (r['people'][r['actor']]['at_240'],r['people'][r['peer']]['at_240']))
        self.assertFalse(expected)

    def test_scoring_sparse_mixed_opposite_and_unmatched(self):
        def classify(a,b):
            events = {side:[[241+i,'sun',v] for i,v in enumerate(trips)] for side,trips in [('control',a),('hinted',b)]}
            return window_result(events,{'sun'},241,720)['weather']['sun']
        self.assertEqual(classify('pp','ppp')['verdict'],'sparse')
        self.assertEqual(classify('ppqq','pppp')['verdict'],'mixed')
        self.assertEqual(classify('ppq','qqp')['verdict'],'opposite')
        r = classify('pqp','pppp')
        self.assertEqual((r['verdict'],r['matched'],r['equal'],r['unpaired']),('agree',3,2,1))
        e = {s:[[241,'sun','q']] for s in ('control','hinted')}
        self.assertFalse(person_result(e,[{'sun'}]*5,[],{'control':'q','hinted':'q'},True,[])['final_preference_agreement'])

    def test_target_alignment_does_not_leak_between_weather_spells(self):
        events = {'control':[[241,'sun','q'],[243,'rain','p']], 'hinted':[[246,'rain','q']]}
        result = first_realign(events,{'control':'p','hinted':'q'},[[241,242,'sun'],[243,246,'rain']])
        self.assertEqual(result,{'first':241,'reopen':246})

    def test_restored_plus_240_checkpoints_reproduce_all_departures_and_physical_intervals(self):
        cases = [json.loads(s) for s in (OUTPUT/'cases.jsonl').read_text().splitlines()]
        chosen = [next(c for c in cases if c['family']=='primary'),
                  next(c for c in cases if (c['family'],c['seed'],c['age'],c['actor'],c['kind'])==('reversal',4,480,'A','q'))]
        for case in chosen:
            original = rebuild(case['family'],case)
            paths = {}
            for side in ('control','hinted'):
                w = ContextWorld.restore(original)
                if side=='hinted':
                    w.hint(case['actor'],case['kind'])
                for _ in range(START):
                    w.step()
                w = ContextWorld.restore(json.loads(json.dumps(w.snapshot())))
                paths[side] = {}
                observed = {'A':[], 'B':[]}
                for t in range(START+1,END+1):
                    w.step()
                    paths[side][t] = {}
                    for n,r in w.residents.items():
                        if r.last_choice and r.last_choice['tick']==w.tick:
                            observed[n].append([t,w.weather,r.last_choice['target']])
                        paths[side][t][n] = (tuple(r.pos),r.phase,r.target if r.phase=='outbound' else None)
                for n in observed:
                    self.assertEqual(observed[n],case['people'][n]['events'][side])
            for n,p in case['people'].items():
                ticks = {t for t in paths['control'] if paths['control'][t][n]!=paths['hinted'][t][n]}
                self.assertEqual(ticks,{t for a,b in p['behavior_intervals'] for t in range(a,b+1)})
                for window in p['windows']:
                    for weather,cell in window['weather'].items():
                        for side,trips in p['events'].items():
                            raw = Counter(target for t,w,target in trips if window['begin']<=t<=window['end'] and w==weather)
                            self.assertEqual(dict(raw),cell['counts'][side])


if __name__ == '__main__':
    unittest.main()
