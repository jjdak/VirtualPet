import json
from collections import deque
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'living_world/studies'))
from w3_endpoint import END, Frame, LONG, MAX_LAG, OUT, RADIUS, exact_lags, trip_alignment
from world import FOODS, HOMES, WALLS, WIDTH, HEIGHT


def distance(start, end):
    queue = deque([(start,0)])
    seen = {start}
    while queue:
        (x,y),d = queue.popleft()
        if (x,y)==end:
            return d
        for u,v in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=u<WIDTH and 0<=v<HEIGHT and (u,v) not in WALLS and (u,v) not in seen:
                queue.append(((u,v),d+1))
                seen.add((u,v))
    raise AssertionError('unreachable')


class EndpointDiagnostics(unittest.TestCase):
    def test_symmetric_shift_and_edge_disagreement(self):
        def frame(t):
            return Frame((t%47,0),'outbound','q','q' if t%47==0 else None,t%47==11)
        span=range(END-RADIUS-MAX_LAG, END+RADIUS+MAX_LAG+1)
        left={t:frame(t) for t in span}
        right={t:frame(t-17) for t in span}
        self.assertEqual(set(exact_lags(left,right)),{17,-30})
        self.assertEqual(set(exact_lags(right,left)),{-17,30})
        # A deviation at the edge of the right-hand window must count too.
        right[END-RADIUS]=Frame((999,1),'rest',None,None,False)
        self.assertFalse(exact_lags(left,right))

    def test_adjacent_trip_alignment_can_cross_the_endpoint(self):
        def tr(t,k):
            return dict(depart=t,eat=t+5,home=t+10,rest=t+11,place=k)
        left=[tr(END-125+40*i,k) for i,k in enumerate('pqqpqpp')]
        right=[{**j,**{t:j[t]+12 for t in ('depart','eat','home','rest')}} for j in left]
        a,b,options=trip_alignment(left,right)
        self.assertNotEqual(a['place'],b['place'])
        self.assertEqual(options[0]['mismatches'],0)
        self.assertTrue(all(r['delta']['depart']==12 for r in options[0]['trips']))

    def test_all_cases_endpoint_targets_and_archived_departures(self):
        key=lambda c:(c['family'],c['seed'],c['age'],c['actor'],c['kind'])
        source=[json.loads(s) for s in (LONG/'cases.jsonl').read_text().splitlines()]
        original={key(c):c for c in source if any(p['behavior_different_at_end'] for p in c['people'].values())}
        report=json.loads((OUT/'diagnosis.json').read_text())
        for case in report['cases']:
            previous=original.pop(key(case))
            for name,p in case['people'].items():
                self.assertEqual(p['affected'],previous['people'][name]['behavior_different_at_end'])
                for side in ('control','hinted'):
                    j=p[side]['latest_trip']
                    last=previous['people'][name]['events'][side][-1]
                    self.assertEqual([j['depart'],j['weather'],j['place']],last)
                    endpoint=p[side]['endpoint']
                    self.assertEqual(endpoint['outbound_target'],j['place'] if endpoint['phase']=='outbound' else None)
                    # Physical trip lengths independently derived from the fixed obstacle map.
                    for trip in p['nearby'][side]:
                        d=distance(HOMES[name],FOODS[trip['place']])
                        self.assertEqual(trip['eat']-trip['depart'],d+1)
                        self.assertEqual(trip['home']-trip['eat'],d)
                        self.assertEqual(trip['rest'],trip['home']+1)
        self.assertFalse(original)
