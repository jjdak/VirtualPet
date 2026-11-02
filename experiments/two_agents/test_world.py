import unittest
from copy import deepcopy
from world import World, expose, probes, value_choice
from run import parse_choice


class WorldTests(unittest.TestCase):
    def test_format_wrapper_does_not_repair_choices(self):
        obs = World(0).observe("甲")
        self.assertEqual(parse_choice('```json\n{"target":"q"}\n```', obs), "q")
        self.assertIsNone(parse_choice('```json\n{"target":"q"}\n```', obs, False))
        for raw in ('{"target":"not-visible"}', '{"target": ["p"]}',
                    '{"target":"p", "reason":"yes"}', 'choose p',
                    'prefix ```json\n{"target":"p"}\n```'):
            self.assertIsNone(parse_choice(raw, obs))

    def test_action_preconditions(self):
        w = World(0)
        self.assertFalse(w.apply("甲", "eat", "p")["ok"])
        self.assertFalse(w.apply("甲", "move", (3, 1))["ok"])
        self.assertFalse(w.apply("甲", "move", (-1, 2))["ok"])
        self.assertFalse(w.apply("甲", "move", (6, 2))["ok"])
        self.assertEqual(w.people["甲"].health, 10)

    def test_isolation_and_message_range(self):
        w = World(0)
        expose(w)
        self.assertEqual(w.people["乙"].memories, [])
        w.people["乙"].pos = (6, 4)
        self.assertEqual(w.observe("乙")["可见食物"], [])
        self.assertFalse(w.apply("甲", "tell", ("乙", 0))["ok"])
        w.people["乙"].pos = (3, 2)
        self.assertTrue(w.apply("甲", "tell", ("乙", 0))["ok"])
        w.people["甲"].memories[0]["health_delta"] = 999
        self.assertEqual(w.people["乙"].memories[0]["health_delta"], 4)

    def test_hidden_effects_and_causal_controls(self):
        for case in range(12):
            cases = {name: (w, a) for name, w, a in probes(case)}
            before, _ = cases["A_before"]
            self.assertEqual(before.observe("甲"), World(case, inverse=True).observe("甲"))
            self.assertEqual(cases["B_before"][0].observe("乙"),
                             cases["B_isolated"][0].observe("乙"))
            self.assertEqual(before.observe("甲"), cases["A_cleared"][0].observe("甲"))
            for name in ("A_experienced", "B_told", "A_inverse_history", "A_relocated"):
                w, actor = cases[name]
                target = value_choice(w.observe(actor))
                self.assertEqual(w.execute_choice(actor, target)[-1]["health_delta"], 4)
            self.assertNotEqual(value_choice(cases["A_experienced"][0].observe("甲")),
                                value_choice(cases["A_inverse_history"][0].observe("甲")))

    def test_probe_execution_does_not_contaminate_other_probe(self):
        cases = probes(0)
        snapshot = deepcopy(cases[2][1].observe("甲"))
        cases[0][1].execute_choice("甲", "q")
        self.assertEqual(cases[2][1].observe("甲"), snapshot)


if __name__ == "__main__":
    unittest.main()
