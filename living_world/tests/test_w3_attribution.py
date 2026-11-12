"""Check one-decision counterfactuals and reproduce the fixed archived sample."""
from contextlib import redirect_stdout
from copy import deepcopy
import io
import json
import math
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'living_world/studies'))
from w3_attribution import ContextWorld, OUT, probe, run, runtime


class ChoiceAttribution(unittest.TestCase):
    def person(self):
        person = ContextWorld(1).residents['A']
        person.brain.values = {'p': .2, 'q': 0.0}
        person.brain.counts = {'p': 4, 'q': 3}
        person.brain.inbox = {'q': dict(id='B:90',source='B',tick=90,kind='q',claim=1)}
        return person

    def test_messages_can_really_flip_the_fixed_decision(self):
        person = self.person()
        before = deepcopy(person.snapshot())
        config = deepcopy(runtime.CONFIG)
        full = probe(person,1,100,draws=[.8,.1])
        no_message = probe(person,1,100,messages=False,draws=[.8,.1])
        self.assertEqual(full['target'],'q')
        self.assertEqual(no_message['target'],'p')
        self.assertAlmostEqual(full['scores']['q'],.6*math.exp(-.1))
        self.assertEqual(person.snapshot(),before)
        self.assertEqual(runtime.CONFIG,config)

    def test_swapping_draws_keeps_message_age_and_can_disable_exploration(self):
        person = self.person()
        explore = probe(person,1,100,draws=[.01,.1])
        exploit = probe(person,1,100,draws=[.9,.1])
        disabled = probe(person,1,100,exploration=False,draws=[.01,.1])
        self.assertEqual(explore['target'],'p')
        self.assertEqual(exploit['target'],'q')
        self.assertEqual(disabled['target'],'q')
        self.assertEqual(explore['scores'],exploit['scores'])
        self.assertEqual(explore['scores'],disabled['scores'])
        # The real TTL boundary still applies; changing the clock is NOT an RNG swap.
        self.assertEqual(probe(person,1,250,draws=[.9,.1])['scores']['q'],.6*math.exp(-1.6))
        self.assertEqual(probe(person,1,251,draws=[.9,.1])['scores']['q'],0.0)

    def test_value_ablation_preserves_known_places_and_unknown_has_priority(self):
        person = self.person()
        result = probe(person,1,100,own=False,messages=False,draws=[.01,.1])
        self.assertEqual(result['route'],'explore')
        self.assertEqual(result['target'],'p')
        person.brain.counts['q'] = 0
        result = probe(person,1,100,own=False,messages=False,draws=[.01,.1])
        self.assertEqual(result['route'],'unknown')
        self.assertEqual(result['target'],'q')

    def test_registered_sample_replays_exactly_and_probes_explain_the_choices(self):
        archived = json.loads((OUT/'attribution.json').read_text())
        with tempfile.TemporaryDirectory() as folder, redirect_stdout(io.StringIO()):
            result = run(Path(folder))
        self.assertEqual(result,archived)
        self.assertEqual(result['summary'], dict(pairs=3,decisions=6,exploration_decisions=3,
            unique_rng_keys=4,unique_input_states=5,ablation_probes=48,swapped_draw_probes=6))
        for case in result['cases']:
            for pair in case['comparisons']:
                for side,d in pair['decisions'].items():
                    self.assertTrue(all(m['source_verified'] and m['received_tick']<d['tick']
                                        for m in d['messages']))
                    self.assertTrue(all(n>0 for n in d['own_counts'].values()))
                    self.assertFalse(any(h['status']=='pending' for h in d['hints']))
                    self.assertEqual(d['previous_choice']['target'],'q')
                    b = d['baseline']
                    self.assertGreater(b['scores']['q'],b['scores']['p'])
                    self.assertEqual(d['other_branch_draws']['scores'], b['scores'])
                    self.assertNotEqual(d['other_branch_draws']['target'], b['target'])
                    # Independent first-hand and social support both prefer q without exploration.
                    for p in d['ablations']:
                        if not p['exploration'] and (p['own'] or p['messages']):
                            self.assertEqual(p['target'],'q')
                        if side=='hinted' and p['exploration']:
                            self.assertEqual(p['target'],'p')


if __name__ == '__main__':
    unittest.main()
