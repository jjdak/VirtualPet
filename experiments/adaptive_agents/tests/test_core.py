import json
from pathlib import Path
import sys
import subprocess
import unittest

LAB = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(LAB / "src"))
from core import Agent, Episode, World

CONFIG = json.loads((LAB / "protocols/e2-v1.json").read_text())


class MechanismTests(unittest.TestCase):
    def test_action_preconditions_and_path(self):
        w = World()
        for position in ((3, 2), (-1, 3), (5, 3)):
            with self.assertRaises(ValueError):
                w.move("A", position)
        with self.assertRaises(ValueError):
            w.eat("A", "p", 1)
        actions = w.route("A", w.FOOD["p"])
        self.assertEqual(len(actions), 4)
        w.eat("A", "p", 1)
        agents = {k: Agent(k, "recent_trust", CONFIG) for k in ("A", "B")}
        with self.assertRaises(ValueError):
            w.tell("A", "B", {}, agents, 0)

    def test_private_state_and_no_hidden_schedule(self):
        e = Episode(CONFIG, 0, "reversal", "recent_trust")
        e.agents["A"].experience("p", -1, 0)
        self.assertEqual(e.agents["B"].values["p"], 0)
        self.assertNotIn("flip_round", e.agents["A"].config)
        stable = Episode(CONFIG, 0, "stable", "recent_trust")
        reversed_e = Episode(CONFIG, 0, "reversal", "recent_trust")
        self.assertEqual(stable.agents["A"].snapshot(), reversed_e.agents["A"].snapshot())

    def test_trust_requires_personal_confirmation(self):
        a = Agent("B", "recent_trust", CONFIG)
        msg = {"id": "A-0", "source": "A", "kind": "p", "claim": 1, "tick": 0}
        a.receive(msg, 0)
        self.assertEqual(a.trust(), .75)
        a.experience("q", -1, 1)
        self.assertEqual(a.trust(), .75)
        a.experience("p", -1, 1)
        self.assertLess(a.trust(), .75)
        first = a.trust()
        self.assertEqual(a.receive(msg, 1), "duplicate")
        a.experience("p", -1, 2)
        self.assertEqual(a.trust(), first)
        self.assertEqual(a.validation_count, 1)

    def test_expiry_older_message_and_copy(self):
        a = Agent("B", "recent_trust", CONFIG)
        m = {"id": "new", "source": "A", "kind": "p", "claim": 1, "tick": 4}
        self.assertEqual(a.receive(m, 4), "accepted")
        m["claim"] = -1
        self.assertEqual(a.inbox["p"]["claim"], 1)
        self.assertEqual(a.receive({**m, "id": "old", "tick": 3}, 4), "older_than_known")
        a.begin_round(10)
        a.experience("p", -1, 10)
        self.assertEqual(a.validation_count, 0)
        self.assertEqual(a.receive({**m, "id": "ancient", "tick": 0}, 10), "expired")

    def test_online_value_update_and_ablation(self):
        recent = Agent("A", "recent_trust", CONFIG)
        mean = Agent("A", "mean_fixed", CONFIG)
        for tick in range(20):
            recent.experience("p", 1, tick)
            mean.experience("p", 1, tick)
        for tick in range(20, 23):
            recent.experience("p", -1, tick)
            mean.experience("p", -1, tick)
        self.assertLess(recent.values["p"], 0)
        self.assertGreater(mean.values["p"], 0)
        mute = Agent("B", "recent_no_messages", CONFIG)
        self.assertEqual(mute.receive({}, 0), "disabled")
        self.assertFalse(mute.inbox)

    def test_save_resume_preserves_next_actions(self):
        for scenario in CONFIG["scenarios"]:
            e = Episode(CONFIG, 3, scenario, "recent_trust")
            for _ in range(61):
                e.step()
            restored = Episode.restore(json.loads(json.dumps(e.snapshot())))
            for _ in range(59):
                self.assertEqual(e.step(), restored.step())
            self.assertEqual(e.snapshot(), restored.snapshot())

    def test_resume_in_fresh_python_process(self):
        e = Episode(CONFIG, 2, "faulty_source", "recent_trust")
        for _ in range(61):
            e.step()
        saved = json.dumps(e.snapshot())
        expected = [e.step() for _ in range(59)]
        script = "import sys,json; from core import Episode; e=Episode.restore(json.load(sys.stdin)); print(json.dumps([e.step() for _ in range(59)]))"
        result = subprocess.run([sys.executable, "-c", script], input=saved, text=True,
                                cwd=LAB / "src", capture_output=True, check=True)
        self.assertEqual(json.loads(result.stdout), json.loads(json.dumps(expected)))


if __name__ == "__main__":
    unittest.main()
