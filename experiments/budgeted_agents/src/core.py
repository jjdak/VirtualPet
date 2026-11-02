"""E4: one capped exploration budget for routine and triggered reinspection."""
from copy import deepcopy
import importlib.util
from pathlib import Path
import random

E3_PATH = Path(__file__).resolve().parents[2] / "reinspection_agents/src/core.py"
spec = importlib.util.spec_from_file_location("e3_frozen", E3_PATH)
e3 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e3)
E2_PATH = e3.E2_PATH


class Agent(e3.Agent):
    def __init__(self, name, strategy, config):
        super().__init__(name, "surprise_stale" if strategy == "e3_reference" else strategy, config)
        self.strategy = strategy
        for key in ("total_budget", "budget_release_every", "budget_cooldown", "periodic_age", "hybrid_reserve"):
            self.config[key] = config[key]
        # Primary policies have no uncharged background exploration.
        self.exploration_probability = config["epsilon"]
        if strategy != "e3_reference":
            self.config["epsilon"] = 0.
        self.budget_used = 0
        self.last_budget_tick = -1000
        self.request = None

    def ledger(self, tick):
        released = min(self.config["total_budget"], 1+tick//self.config["budget_release_every"])
        return {"released":released, "used":self.budget_used, "available":released-self.budget_used,
                "last_spend":self.last_budget_tick, "limit":self.config["total_budget"]}

    def choose(self, seed, tick):
        if self.strategy == "e3_reference":
            c = super().choose(seed, tick)
            return {**c, "budget_before":None, "budget_after":None, "requests":[]}
        # Read-only E2 selector handles unknown items and social/personal scores.
        c = e3.e2.Agent.choose(self, seed, tick)
        c.update(base_target=c["target"], base_reason=c["reason"], probe=None,
                 budget_before=self.ledger(tick), requests=[])
        pending, self.request = self.request, None
        if c["reason"] != "try_unknown":
            candidates = []
            if self.strategy in ("trigger_only", "hybrid") and pending is not None:
                if pending["tick"] == tick-1:
                    candidates.append(("trigger", pending["candidate"], pending))
            if self.strategy in ("periodic_only", "hybrid"):
                stale = [k for k in ("p", "q") if self.last_seen[k] is not None
                         and tick-self.last_seen[k] >= self.config["periodic_age"]]
                if stale:
                    target = min(stale, key=lambda k:self.last_seen[k])
                    candidates.append(("periodic", target, {"last_seen":self.last_seen[target],
                                                            "age":tick-self.last_seen[target]}))
            if self.strategy == "budget_random":
                rng = random.Random(seed*100003 + tick*97 + (17 if self.name == "B" else 0))
                roll, tie = rng.random(), rng.random()
                if roll < self.exploration_probability:
                    candidates.append(("random", ("p", "q")[int(tie*2)], {"roll":roll}))
            for source, target, evidence in candidates:
                account = self.ledger(tick)
                blocked = None
                if account["available"] < 1: blocked = "budget"
                elif tick-self.last_budget_tick < self.config["budget_cooldown"]: blocked = "cooldown"
                elif source == "periodic" and self.strategy == "hybrid" and account["available"] <= self.config["hybrid_reserve"]:
                    blocked = "reserve"
                receipt = {"source":source, "target":target, "evidence":deepcopy(evidence), "blocked":blocked}
                c["requests"].append(receipt)
                if blocked is None:
                    self.budget_used += 1
                    self.last_budget_tick = tick
                    self.probes_used += 1
                    c.update(target=target, reason=source+"_probe", probe=deepcopy(receipt))
                    break
        c["budget_after"] = self.ledger(tick)
        return c

    def experience(self, kind, reward, tick):
        checked = super().experience(kind, reward, tick)
        if self.strategy != "e3_reference":
            m = self.last_monitor
            propose = self.strategy in ("trigger_only", "hybrid") and m["eligible"]
            if propose:
                self.request = {"tick":tick, "candidate":m["candidate"], "candidate_age":m["candidate_age"],
                                "kind":kind, "prediction":m["prediction"], "observed":reward,
                                "residual":m["residual"], "streak":m["streak"]}
            m["request_proposed"] = propose
        return checked

    @classmethod
    def restore(cls, data):
        a = cls(data["name"], data["strategy"], data["config"])
        a.__dict__.update(deepcopy(data))
        a.seen, a.validated = set(data["seen"]), set(data["validated"])
        return a


class Episode(e3.Episode):
    def __init__(self, config, seed, scenario, policy):
        super().__init__(config, seed, scenario, policy)
        self.case = deepcopy(next(c for c in config["cases"] if c["id"] == scenario))
        self.agents = {k:Agent(k, policy, config) for k in ("A", "B")}

    def potential(self, kind, tick):
        original = ("p", "q")[self.seed % 2]
        category, change = self.case["kind"], self.case["change_at"]
        first = change is not None and tick >= change
        if category == "hidden_gain":
            value = .5 if kind == original else (1 if first else -1)
        elif category in ("staggered", "noisy_staggered"):
            if kind == original: value = -.75 if first else 1
            else: value = -1 if tick >= change+self.config["stagger_delay"] else -.25
        else:
            good = original
            if category == "swap" and first: good = "q" if original == "p" else "p"
            value = 1 if kind == good else -1
        noisy = category in ("noisy_stable", "noisy_staggered")
        return value, value*(1-2*self.config["noise_probability"] if noisy else 1)

    def reward(self, actor, kind, tick):
        value, _ = self.potential(kind, tick)
        if self.case["kind"] in ("noisy_stable", "noisy_staggered"):
            rng = random.Random(self.seed*1000003 + tick*1009 + (101 if actor == "B" else 0)
                                + (503 if kind == "q" else 0) + 90000001)
            if rng.random() < self.config["noise_probability"]: value *= -1
        return value

    def step(self):
        row = super().step()
        for name, a in self.agents.items():
            row["after"][name]["budget"] = None if self.policy == "e3_reference" else a.ledger(row["tick"])
        return row

    @classmethod
    def restore(cls, data):
        e = cls(data["config"], data["seed"], data["scenario"], data["policy"])
        e.tick, e.cached = data["tick"], deepcopy(data["cached"])
        e.world.positions = {k:tuple(v) for k,v in data["positions"].items()}
        e.world.health = dict(data["health"])
        e.agents = {k:Agent.restore(v) for k,v in data["agents"].items()}
        return e


def changes(config, scenario):
    case = next(c for c in config["cases"] if c["id"] == scenario)
    if case["change_at"] is None: return []
    events = [case["change_at"]]
    if case["kind"] in ("staggered", "noisy_staggered"):
        events.append(case["change_at"]+config["stagger_delay"])
    return events


def summarize(rows, config, seed, scenario, policy):
    result = {"seed":seed, "scenario":scenario, "policy":policy, "agents":{}}
    events = changes(config, scenario)
    for actor in ("A", "B"):
        cs = [r["choices"][actor] for r in rows]
        regrets = [max(r["evaluation_only"]["expected_rewards"].values())-
                   r["evaluation_only"]["expected_rewards"][c["target"]] for r,c in zip(rows,cs)]
        explorations = [i for i,c in enumerate(cs) if c["probe"] is not None or c["reason"] == "explore"]
        phases = []
        for n,start in enumerate(events):
            end = events[n+1] if n+1 < len(events) else len(rows)
            recovery, streak = None, 0
            for i in range(start,end):
                streak = streak+1 if regrets[i] < 1e-12 else 0
                if streak == 5:
                    recovery = i-start+1
                    break
            phases.append({"change_at":start, "segment_end":end,
                           "optimal_next20":sum(x < 1e-12 for x in regrets[start:start+20])/20,
                           "regret_next20":sum(regrets[start:start+20]), "recovery":recovery})
        result["agents"][actor] = {
            "regret":sum(regrets), "reward":sum(c["reward"] for c in cs),
            "optimal_all":sum(x < 1e-12 for x in regrets)/len(rows),
            "explorations":len(explorations), "exploration_regret":sum(regrets[i] for i in explorations),
            "overrides":sum(cs[i]["target"] != cs[i]["base_target"] for i in explorations),
            "initial_unknown":sum(c["reason"] == "try_unknown" for c in cs),
            "random_actions":sum(c["reason"] in ("random_probe", "explore") for c in cs),
            "periodic_actions":sum(c["reason"] == "periodic_probe" for c in cs),
            "trigger_actions":sum(c["reason"] in ("trigger_probe", "recheck_stale") for c in cs),
            "budget_used":rows[-1]["after"][actor]["budget"]["used"] if policy != "e3_reference" else None,
            "budget_unspent":config["total_budget"]-rows[-1]["after"][actor]["budget"]["used"] if policy != "e3_reference" else None,
            **{"blocked_"+reason:sum(q["blocked"] == reason for c in cs for q in c["requests"])
               for reason in ("budget","cooldown","reserve")},
            "events":phases}
    return result
