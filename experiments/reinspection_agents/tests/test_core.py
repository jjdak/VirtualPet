import json
from pathlib import Path
import subprocess
import sys
import unittest

LAB = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(LAB / "src"))
from core import Agent, Episode, e2
from verify import audit
from report import paired_interval

CFG = json.loads((LAB / "protocols/e3-v1.json").read_text())


def experienced_agent(mode="surprise_stale"):
    a = Agent("B", mode, CFG)
    a.experience("q", -1, 0)
    for tick in range(1, 20):
        a.experience("p", 1, tick)
    return a


class E3Tests(unittest.TestCase):
    def test_single_surprise_does_not_trigger(self):
        a = experienced_agent()
        a.experience("p", -1, 20)
        self.assertIsNone(a.queued_probe)
        a.experience("p", 1, 21)
        self.assertEqual(a.error_streak, 0)
        a.experience("p", -1, 22)
        self.assertIsNone(a.queued_probe)

    def test_double_surprise_delayed_probe_and_no_free_reset(self):
        a = experienced_agent()
        a.experience("p", -1, 20)
        a.experience("p", -1, 21)
        self.assertEqual(a.queued_probe["tick"], 21)
        self.assertEqual(a.probes_used, 0)
        self.assertEqual(a.values["q"], -1)
        c = a.choose(0, 22)
        self.assertEqual((c["target"], c["reason"]), ("q", "recheck_stale"))
        self.assertEqual(a.values["q"], -1)
        a.experience("q", 1, 22)
        self.assertAlmostEqual(a.values["q"], -.2)

    def test_recent_alternative_and_messages_do_not_trigger(self):
        a = experienced_agent()
        a.experience("q", -1, 19)
        a.experience("p", -1, 20)
        a.experience("p", -1, 21)
        self.assertIsNone(a.queued_probe)
        a = experienced_agent()
        for tick in (20, 21):
            a.receive({"source":"A", "id":str(tick), "tick":tick, "kind":"p", "claim":-1}, tick)
        self.assertIsNone(a.queued_probe)
        self.assertEqual(a.error_streak, 0)

    def test_probe_budget_and_cooldown(self):
        for used, last, expected in ((6, 0, "budget"), (1, 20, "cooldown")):
            a = experienced_agent()
            a.probes_used, a.last_probe_tick = used, last
            a.experience("p", -1, 20)
            a.experience("p", -1, 21)
            self.assertIsNone(a.queued_probe)
            self.assertEqual(a.last_monitor["blocked"], expected)

    def test_same_trigger_random_control_can_retry_same_food(self):
        targets = set()
        for seed in range(20):
            a = experienced_agent("surprise_random")
            a.experience("p", -1, 20)
            a.experience("p", -1, 21)
            targets.add(a.choose(seed, 22)["target"])
        self.assertEqual(targets, {"p", "q"})

    def test_observation_boundary_and_independent_state(self):
        e = Episode(CFG, 0, "noisy_reversal", "surprise_stale")
        a, b = e.agents.values()
        for key in ("flip_round", "noise_probability", "scenario", "seed", "rounds"):
            self.assertNotIn(key, a.config)
        a.experience("p", -1, 0)
        self.assertEqual(b.counts["p"], 0)
        unchanged = Episode(CFG, 0, "stable", "surprise_stale")
        self.assertEqual(b.snapshot(), unchanged.agents["B"].snapshot())

    def test_e2_baseline_exact_behavior(self):
        for scenario in ("stable", "reversal", "stale_source"):
            for seed in (0, 1, 17):
                old = e2.Episode(CFG, seed, scenario, "recent_trust")
                new = Episode(CFG, seed, scenario, "random_12")
                for _ in range(CFG["rounds"]):
                    r, s = old.step(), new.step()
                    self.assertEqual(r["delivery"], s["delivery"])
                    for actor in ("A", "B"):
                        for key, value in r["choices"][actor].items():
                            self.assertEqual(value, s["choices"][actor][key])
                        self.assertEqual(r["after"][actor]["values"], s["after"][actor]["values"])

    def test_noise_and_unobserved_improvement(self):
        e = Episode(CFG, 0, "hidden_improvement", "surprise_stale")
        self.assertEqual(e.potential("p", 39), (.5, .5))
        self.assertEqual(e.potential("p", 40), (.5, .5))
        self.assertEqual(e.potential("q", 39), (-1, -1))
        self.assertEqual(e.potential("q", 40), (1, 1))
        noisy = Episode(CFG, 0, "noisy_stable", "surprise_stale")
        other = Episode(CFG, 0, "noisy_stable", "random_12")
        vals = [noisy.reward("B", "p", t) for t in range(120)]
        self.assertEqual(set(vals), {-1, 1})
        self.assertEqual(vals, [other.reward("B", "p", t) for t in range(120)])
        self.assertEqual(noisy.potential("p", 0)[1], .8)

    def test_resume_pending_probe_in_new_process(self):
        e = Episode(CFG, 0, "stale_source", "surprise_stale")
        # Explicitly checkpoint a pending probe, not just a quiet round.
        e.tick = 22
        a = experienced_agent()
        a.experience("p", -1, 20)
        a.experience("p", -1, 21)
        e.agents["B"] = a
        snapshot = json.loads(json.dumps(e.snapshot()))
        script = ('import sys,json;sys.path.insert(0,sys.argv[1]);from core import Episode;'
                  'e=Episode.restore(json.load(sys.stdin));print(json.dumps([e.step() for _ in range(10)]))')
        result = subprocess.run([sys.executable, "-c", script, str(LAB / "src")],
                                input=json.dumps(snapshot), text=True, capture_output=True, check=True)
        actual = [e.step() for _ in range(10)]
        self.assertEqual(json.loads(result.stdout), json.loads(json.dumps(actual)))

    def test_full_restore_all_scenarios_and_horizon(self):
        for scenario in CFG["scenarios"]:
            e = Episode(CFG, 0, scenario, "surprise_stale")
            for _ in range(60): e.step()
            restored = Episode.restore(json.loads(json.dumps(e.snapshot())))
            for _ in range(60):
                self.assertEqual(e.step(), restored.step())
            with self.assertRaises(RuntimeError): e.step()
            self.assertEqual(restored.snapshot()["tick"], CFG["rounds"])

    def test_independent_auditor_rejects_corrupt_evidence(self):
        e = Episode(CFG, 0, "noisy_reversal", "surprise_stale")
        rows = json.loads(json.dumps([e.step() for _ in range(120)]))
        self.assertEqual(audit(rows, CFG, "noisy_reversal", 0, "surprise_stale"), 2160)
        for field in ("reward", "monitor"):
            bad = json.loads(json.dumps(rows))
            if field == "reward": bad[0]["choices"]["B"]["reward"] *= -1
            else: bad[45]["choices"]["B"]["monitor"]["prediction"] += .1
            with self.assertRaises(AssertionError): audit(bad, CFG, "noisy_reversal", 0, "surprise_stale")

    def test_paired_interval_and_truncation(self):
        interval = paired_interval([.2]*10)
        self.assertEqual(interval["bootstrap_95_interval"], [.2, .2])
        e = Episode(CFG, 0, "stable", "random_12")
        rows = [e.step() for _ in range(120)]
        self.assertTrue(rows[-1]["truncated"])
        self.assertFalse(any(r["truncated"] or r["terminated"] for r in rows[:-1]))


if __name__ == "__main__":
    unittest.main()
