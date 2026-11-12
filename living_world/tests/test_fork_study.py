"""W3 contracts checked against observations, not the study's implementation."""
from copy import deepcopy
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))
from context_world import ContextWorld
from world import HINT_TTL
from fork_study import compare, run_pair


def state(person):
    return person['pos'], person['phase'], person['target']


def saved(seed=0, age=0):
    world = ContextWorld(seed)
    for _ in range(age):
        world.step()
    return world.snapshot()


class ForkStudyTests(unittest.TestCase):
    def test_snapshot_isolated_and_repeatable(self):
        snapshot = saved(7, 60)
        before = deepcopy(snapshot)
        first = compare(snapshot, 'B', 'q', 120)
        self.assertEqual(snapshot, before)
        self.assertEqual(first, compare(snapshot, 'B', 'q', 120))
        self.assertEqual(snapshot, before)
        self.assertEqual(first['start'], 60)
        self.assertEqual(first['horizon'], 120)
        self.assertTrue(first['origin_hash'])

    def test_one_hint_only_and_no_hint_control(self):
        calls = []
        original = ContextWorld.hint
        def record(world, actor, kind):
            calls.append((world.tick, actor, kind))
            return original(world, actor, kind)
        with patch.object(ContextWorld, 'hint', record):
            run_pair(saved(3, 60), 'A', 'p', 180)
        self.assertEqual(calls, [(60, 'A', 'p')])
        calls.clear()
        with patch.object(ContextWorld, 'hint', record):
            pair = run_pair(saved(3, 60), 'A', None, 180, frames=True)
        self.assertEqual(calls, [])
        for frame in pair['frames']:
            for actor in ('A', 'B'):
                self.assertEqual(state(frame['control'][actor]), state(frame['hinted'][actor]))
            self.assertEqual(frame['deliveries']['control'], frame['deliveries']['hinted'])

    def test_start_and_weather_follow_saved_schedule(self):
        snapshot = saved(9, 60)
        result = compare(snapshot, 'A', 'q', 120)
        frames = result['frames']
        self.assertEqual([f['offset'] for f in frames], list(range(121)))
        reference = ContextWorld.restore(snapshot)
        for frame in frames:
            self.assertEqual(frame['weather'], reference.weather)
            for actor in ('A', 'B'):
                expected = reference.residents[actor]
                self.assertEqual(state(frame['control'][actor]), (expected.pos, expected.phase, expected.target if expected.phase == 'outbound' else None))
                if frame['offset'] == 0:
                    self.assertEqual(state(frame['control'][actor]), state(frame['hinted'][actor]))
            if frame['offset'] < 120:
                reference.step()

    def test_metrics_match_observed_behavior_and_relative_time(self):
        result = compare(saved(0, 60), 'A', 'q', 240)
        for actor, metrics in result['people'].items():
            differences = [f['offset'] for f in result['frames']
                           if state(f['control'][actor]) != state(f['hinted'][actor])]
            self.assertEqual(metrics['first'], differences[0] if differences else None)
            self.assertEqual(metrics['last'], differences[-1] if differences else None)
            self.assertEqual(metrics['steps'], len(differences))
            self.assertEqual(metrics['at_end'], 240 in differences)
            end = result['hint_end']
            if end is not None:
                self.assertEqual(metrics['after_hint'], sum(t > end for t in differences))
        deliveries = [f['offset'] for f in result['frames']
                      if f['deliveries']['control'] != f['deliveries']['hinted']]
        self.assertEqual(result['message_first'], deliveries[0] if deliveries else None)

    def test_no_behavior_case_and_expiry_boundary(self):
        snapshot = saved()
        for person in snapshot['active']['residents'].values():
            person['next_departure'] = 100
            person['hunger'] = 0
        short = compare(snapshot, 'A', 'q', 20)
        for metrics in short['people'].values():
            self.assertEqual((metrics['first'], metrics['last'], metrics['steps'], metrics['at_end']),
                             (None, None, 0, False))
        self.assertIsNone(short['message_first'])
        self.assertIsNone(short['hint_end'])
        # Both locations unavailable prevents fulfillment: the hint expires only after TTL.
        snapshot = saved()
        for resource in snapshot['active']['resources'].values():
            resource['available'] = False
        for person in snapshot['active']['residents'].values():
            person['observed'] = {k: {'available': False, 'tick': 0} for k in ('p', 'q')}
            person['next_departure'] = 100
            person['hunger'] = 0
        self.assertIsNone(compare(snapshot, 'A', 'q', HINT_TTL)['hint_end'])
        self.assertEqual(compare(snapshot, 'A', 'q', HINT_TTL + 1)['hint_end'], HINT_TTL + 1)

    def test_communication_can_be_disabled_without_rewriting_input(self):
        snapshot = saved(4, 60)
        before = deepcopy(snapshot)
        pair = run_pair(snapshot, 'A', 'q', 120, frames=True, social=False)
        self.assertEqual(snapshot, before)
        self.assertTrue(all(not f['deliveries'][side] for f in pair['frames']
                            for side in ('control', 'hinted')))

    def test_report_precedes_peer_change_and_silence_removes_that_change(self):
        # A bounded mechanism fixture, not a selected natural-grid success case:
        # both foods have been tried; B initially favors q and waits at home.
        world = ContextWorld(2)
        a, b = world.residents.values()
        for person in (a, b):
            person.brain.counts.update(p=1, q=1)
        b.brain.values.update(p=0, q=.9)
        b.hunger, b.next_departure = 0, 50
        result = compare(world.snapshot(), 'A', 'q', 120)
        self.assertTrue(result['relay'])
        self.assertLess(result['people']['A']['first'], result['message_first'])
        self.assertLess(result['message_first'], result['people']['B']['first'])
        self.assertEqual(result['people']['B']['first_choice_split'],
                         result['people']['B']['first'])
        self.assertGreater(result['people']['B']['choice_splits'], 0)
        self.assertEqual(result['silent']['people']['B']['steps'], 0)
        self.assertIsNone(result['silent']['message_first'])
        self.assertTrue(result['people']['B']['at_end'])
        self.assertGreater(result['people']['B']['after_hint'], 0)
        # Confirm the observed branch choices, independently of summary flags.
        frame = result['frames'][result['people']['B']['first']]
        self.assertEqual({frame[side]['B']['choice'] for side in ('control', 'hinted')},
                         {'p', 'q'})
        delivery = result['frames'][result['message_first']]['deliveries']
        self.assertNotEqual(delivery['control'], delivery['hinted'])
        self.assertTrue(any(delivery.values()))

    def test_invalid_requests_rejected(self):
        snapshot = saved()
        for actor, kind, horizon in [('C', 'p', 10), ('A', 'x', 10),
                                     ('A', 'p', -1), ('A', 'p', 0), ('A', 'p', 961), ('A', 'p', True),
                                     ('A', 'p', 1.5)]:
            with self.subTest(actor=actor, kind=kind, horizon=horizon):
                with self.assertRaises(ValueError):
                    compare(snapshot, actor, kind, horizon)


if __name__ == '__main__':
    unittest.main()
