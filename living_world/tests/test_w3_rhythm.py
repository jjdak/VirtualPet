"""Ledger, trajectory and one-time synchronization checks for the rhythm diagnosis."""
from collections import deque
from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'living_world/studies'))
import w3_rhythm as rhythm
from w3_coupling import source_rows,key


def distance(start,end):
    todo=deque([(start,0)])
    seen={start}
    while todo:
        pos,d=todo.popleft()
        if pos==end:
            return d
        x,y=pos
        for p in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
            if 0<=p[0]<rhythm.runtime.WIDTH and 0<=p[1]<rhythm.runtime.HEIGHT and p not in rhythm.runtime.WALLS and p not in seen:
                seen.add(p); todo.append((p,d+1))
    raise AssertionError('unreachable')


class RhythmDiagnosis(unittest.TestCase):
    def test_ledger_clipping_and_restored_boundary(self):
        w=rhythm.ContextWorld(0)
        w.set_mode('sun')
        w.residents['A'].hunger=100
        b=w.residents['B']
        b.hunger=0; b.phase='outbound'; b.pos=list(rhythm.runtime.FOODS['p']); b.target='p'
        snapshot=w.snapshot()
        row=dict(family='primary',seed=0,age=0,actor='A',kind='q',origin_hash=rhythm.origin_hash(snapshot))
        with patch.object(rhythm,'rebuild',return_value=snapshot),patch.object(rhythm,'STOP',120),patch.object(rhythm,'END',60):
            histories,endpoints,snapshots,_=rhythm.replay(row)
        for side in rhythm.SIDES:
            self.assertGreater(histories[side]['trips']['A'][-1]['ledger']['upper_loss'],0)
            self.assertAlmostEqual(histories[side]['trips']['B'][-1]['ledger']['lower_gain'],37.2)
            self.assertEqual(snapshots[side]['active']['tick'],60)
            self.assertTrue(all(t['depart']<=60 for t in [endpoints[side][n]['latest_trip'] for n in ('A','B')]))
        self.assertEqual(w.snapshot(),snapshot)

    def test_body_sync_preserves_memory_and_distinguishes_ordinal(self):
        a=rhythm.ContextWorld(1); b=rhythm.ContextWorld(1)
        for _ in range(100):
            a.step(); b.step()
        b.residents['A'].brain.values['p']=-.2
        b.residents['A'].decisions+=3
        b.residents['A'].hunger=99
        before=deepcopy(b.residents['A'].brain.snapshot())
        n=b.residents['A'].decisions
        rhythm.synchronize(a,b,False)
        self.assertEqual(rhythm.physical(a.residents['A']),rhythm.physical(b.residents['A']))
        self.assertEqual(b.residents['A'].decisions,n)
        self.assertEqual(b.residents['A'].brain.snapshot(),before)
        rhythm.synchronize(a,b,True)
        self.assertEqual(b.residents['A'].decisions,a.residents['A'].decisions)
        self.assertEqual(b.residents['A'].brain.snapshot(),before)

    def test_all_saved_ledgers_trip_lengths_and_endpoint_count_accounting(self):
        source=rhythm.OUT/'cases.jsonl'
        meta=json.loads((rhythm.OUT/'summary.json').read_text())
        rows=[json.loads(line) for line in source.read_text().splitlines()]
        self.assertEqual(sha256(source.read_bytes()).hexdigest(),meta['cases_sha256'])
        self.assertEqual(rhythm.summary(rows),meta['summary'])
        self.assertEqual((len(rows),sum(len(r['people']) for r in rows)),(26,27))
        for row in rows:
            for name,p in row['people'].items():
                trips={s:{t['n']:t for t in p['trips'][s]} for s in rhythm.SIDES}
                for side in rhythm.SIDES:
                    for t in trips[side].values():
                        d=distance(rhythm.runtime.HOMES[name],rhythm.runtime.FOODS[t['target']])
                        if t['eat'] is not None:
                            self.assertEqual(t['arrive_food']-t['depart'],d)
                            self.assertEqual(t['eat']-t['depart'],d+1)
                        if t['home'] is not None:
                            self.assertEqual(t['home']-t['eat'],d)
                        if t['rest'] is not None:
                            self.assertEqual(t['rest'],t['home']+1)
                        if 'next_depart' in t:
                            self.assertGreaterEqual(t['wait_after_rest'],4)
                for pair in p['paired']:
                    a,b=(trips[s][pair['n']] for s in rhythm.SIDES)
                    self.assertAlmostEqual(pair['lag'],rhythm.predicted_lag(a,b),places=7)
                    if min(pair['control_depart'],pair['hinted_depart'])>2160:
                        self.assertEqual(pair['lag'],-30*pair['bad_delta'])
                counted=sum(1 if t['hinted_depart']<=2640 else -1 for t in p['endpoint_crossings'])
                self.assertEqual(counted,p['count_delta'])
                self.assertEqual(p['count_delta'],p['endpoint']['hinted']['departures']-p['endpoint']['control']['departures'])

    def test_fresh_replays_cover_count_equality_positive_negative_and_long_lags(self):
        rows=[json.loads(s) for s in (rhythm.OUT/'cases.jsonl').read_text().splitlines()]
        originals={key(r):r for r in source_rows()}
        prior={key(r):r for r in map(json.loads,(rhythm.COUPLING/'cases.jsonl').read_text().splitlines())}
        selected={('reversal',15,480,'B','q'),('reversal',19,480,'A','q'),('reversal',26,480,'A','p')}
        for row in rows:
            if key(row) in selected:
                self.assertEqual(rhythm.analyze(originals[key(row)],prior[key(row)]),row)


if __name__=='__main__':
    unittest.main()
