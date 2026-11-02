"""E3: bounded probes after personal prediction errors. Python stdlib only.

Imports the frozen E2 mechanisms without modifying their source or results.
The evaluator's potential rewards and schedules never enter Agent state.
"""
from copy import deepcopy
import importlib.util
from pathlib import Path
import random

E2_PATH = Path(__file__).resolve().parents[2] / "adaptive_agents/src/core.py"
spec = importlib.util.spec_from_file_location("e2_core", E2_PATH)
e2 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e2)
World = e2.World


class Agent(e2.Agent):
    def __init__(self, name, mode, config):
        super().__init__(name, "recent_trust", config)
        self.mode = mode
        for key in ("residual_threshold", "consecutive_errors", "min_experiences",
                    "stale_after", "probe_cooldown", "probe_budget", "high_epsilon"):
            self.config[key] = deepcopy(config[key])
        if mode == "random_24":
            self.config["epsilon"] = config["high_epsilon"]
        self.last_seen = {k: None for k in ("p", "q")}
        self.error_streak = 0
        self.error_kind = None
        self.error_tick = -2
        self.queued_probe = None
        self.probes_used = 0
        self.last_probe_tick = -1000
        self.last_monitor = None

    def choose(self, seed, tick):
        choice = super().choose(seed, tick)
        choice["base_target"] = choice["target"]
        choice["base_reason"] = choice["reason"]
        choice["probe"] = None
        if self.queued_probe is not None:
            trigger = self.queued_probe
            assert trigger["tick"] == tick-1
            if self.mode == "surprise_stale":
                target = trigger["candidate"]
            else:
                rng = random.Random(seed*100003 + tick*97 + (17 if self.name == "B" else 0) + 700001)
                target = rng.choice(["p", "q"])
            self.probes_used += 1
            self.last_probe_tick = tick
            self.queued_probe = None
            choice.update(target=target, reason="recheck_stale" if self.mode == "surprise_stale"
                          else "recheck_random", probe=deepcopy(trigger))
        return choice

    def experience(self, kind, reward, tick):
        prediction, count = self.values[kind], self.counts[kind]
        residual = abs(reward-prediction)
        unexpected = count >= self.config["min_experiences"] and residual >= self.config["residual_threshold"]
        if unexpected:
            self.error_streak = (self.error_streak+1 if self.error_kind == kind
                                 and self.error_tick == tick-1 else 1)
        else:
            self.error_streak = 0
        self.error_kind, self.error_tick = kind, tick
        alternative = "q" if kind == "p" else "p"
        age = None if self.last_seen[alternative] is None else tick-self.last_seen[alternative]
        eligible = self.error_streak >= self.config["consecutive_errors"] and age is not None and age >= self.config["stale_after"]
        blocked = None
        scheduled = False
        if eligible and self.mode.startswith("surprise_"):
            if self.probes_used >= self.config["probe_budget"]:
                blocked = "budget"
            elif tick+1-self.last_probe_tick < self.config["probe_cooldown"]:
                blocked = "cooldown"
            else:
                self.queued_probe = {"tick": tick, "kind": kind, "prediction": prediction,
                                     "observed": reward, "residual": residual,
                                     "streak": self.error_streak, "candidate": alternative,
                                     "candidate_age": age}
                scheduled = True
        self.last_monitor = {"prediction": prediction, "residual": residual,
                             "prior_count": count, "unexpected": unexpected,
                             "streak": self.error_streak, "candidate": alternative,
                             "candidate_age": age, "eligible": eligible,
                             "scheduled": scheduled, "blocked": blocked}
        self.last_seen[kind] = tick
        return super().experience(kind, reward, tick)

    @classmethod
    def restore(cls, data):
        agent = cls(data["name"], data["mode"], data["config"])
        agent.__dict__.update(deepcopy(data))
        agent.seen, agent.validated = set(data["seen"]), set(data["validated"])
        return agent


class Episode:
    def __init__(self, config, seed, scenario, policy):
        self.config, self.seed, self.scenario, self.policy = deepcopy(config), seed, scenario, policy
        self.agents = {k: Agent(k, policy, config) for k in ("A", "B")}
        self.world, self.tick, self.cached = World(), 0, None

    def potential(self, kind, tick):
        """Environment only: uncorrupted outcome and expected reward."""
        good = ("p", "q")[self.seed % 2]
        changed = tick >= self.config["flip_round"]
        if self.scenario == "hidden_improvement":
            reward = .5 if kind == good else (1 if changed else -1)
        else:
            if self.scenario in ("reversal", "stale_source", "noisy_reversal") and changed:
                good = "q" if good == "p" else "p"
            reward = 1 if kind == good else -1
        noisy = self.scenario in ("noisy_stable", "noisy_reversal")
        return reward, reward*(1-2*self.config["noise_probability"] if noisy else 1)

    def reward(self, actor, kind, tick):
        reward, _ = self.potential(kind, tick)
        if self.scenario in ("noisy_stable", "noisy_reversal"):
            rng = random.Random(self.seed*1000003 + tick*1009 + (101 if actor == "B" else 0)
                                + (503 if kind == "q" else 0) + 90000001)
            if rng.random() < self.config["noise_probability"]:
                reward *= -1
        return reward

    def step(self):
        if self.tick >= self.config["rounds"]:
            raise RuntimeError("episode truncated by experiment horizon")
        t, messages, choices = self.tick, {}, {}
        for agent in self.agents.values():
            agent.begin_round(t)
        # All decisions precede this round's outcomes and communications.
        decisions = {k: a.choose(self.seed, t) for k, a in self.agents.items()}
        for actor, agent in self.agents.items():
            choice = decisions[actor]
            kind = choice["target"]
            actions = self.world.route(actor, self.world.FOOD[kind])
            reward = self.reward(actor, kind, t)
            actions.append(self.world.eat(actor, kind, reward))
            checked = agent.experience(kind, reward, t)
            actions.extend(self.world.route(actor, self.world.CAMP))
            messages[actor] = {"id": f"{actor}-{t}", "source": actor, "tick": t,
                               "kind": kind, "claim": reward}
            choices[actor] = {**choice, "reward": reward, "actions": actions,
                              "validated_messages": checked, "monitor": deepcopy(agent.last_monitor)}
        if t == self.config["flip_round"]-1:
            self.cached = deepcopy(messages["A"])
        if self.scenario == "stale_source" and t >= self.config["flip_round"]:
            messages["A"] = deepcopy(self.cached)
        delivery = []
        for sender, receiver in (("A", "B"), ("B", "A")):
            status = self.world.tell(sender, receiver, messages[sender], self.agents, t)
            delivery.append({"sender": sender, "receiver": receiver,
                             "message": deepcopy(messages[sender]), "status": status})
        result = {"tick": t, "choices": choices, "delivery": delivery,
                  "health": dict(self.world.health),
                  "after": {k: {"values": dict(a.values), "counts": dict(a.counts),
                                 "trust": a.trust(), "probes_used": a.probes_used,
                                 "last_seen": dict(a.last_seen)} for k, a in self.agents.items()},
                  "evaluation_only": {"expected_rewards": {k: self.potential(k, t)[1] for k in ("p", "q")}},
                  "terminated": False, "truncated": t+1 == self.config["rounds"]}
        self.tick += 1
        return result

    def snapshot(self):
        return {"config": deepcopy(self.config), "seed": self.seed, "scenario": self.scenario,
                "policy": self.policy, "tick": self.tick, "cached": deepcopy(self.cached),
                "positions": deepcopy(self.world.positions), "health": dict(self.world.health),
                "agents": {k: a.snapshot() for k, a in self.agents.items()}}

    @classmethod
    def restore(cls, data):
        e = cls(data["config"], data["seed"], data["scenario"], data["policy"])
        e.tick, e.cached = data["tick"], deepcopy(data["cached"])
        e.world.positions = {k: tuple(v) for k, v in data["positions"].items()}
        e.world.health = dict(data["health"])
        e.agents = {k: Agent.restore(v) for k, v in data["agents"].items()}
        return e


def summarize(rows, config, seed, scenario, policy):
    start = config["flip_round"]
    result = {"seed": seed, "scenario": scenario, "policy": policy, "agents": {}}
    for actor in ("A", "B"):
        choices = [r["choices"][actor] for r in rows]
        regrets = [max(r["evaluation_only"]["expected_rewards"].values())-
                   r["evaluation_only"]["expected_rewards"][c["target"]] for r, c in zip(rows, choices)]
        optimal = [abs(x) < 1e-12 for x in regrets]
        streak, recovery = 0, None
        for i, good in enumerate(optimal[start:], start):
            streak = streak+1 if good else 0
            if streak == 5:
                recovery = i-start+1
                break
        probes = [i for i, c in enumerate(choices) if c["probe"] is not None]
        result["agents"][actor] = {
            "optimal_all": sum(optimal)/len(rows),
            "optimal_40_59": sum(optimal[start:start+20])/20,
            "regret": sum(regrets), "reward": sum(c["reward"] for c in choices),
            "recovery_rounds": recovery,
            "probes": len(probes), "probe_regret": sum(regrets[i] for i in probes),
            "suboptimal_probes": sum(not optimal[i] for i in probes),
            "probe_overrides": sum(choices[i]["target"] != choices[i]["base_target"] for i in probes),
            "random_actions": sum(c["reason"] == "explore" for c in choices),
            "scheduled": sum(c["monitor"]["scheduled"] for c in choices),
            "blocked_budget": sum(c["monitor"]["blocked"] == "budget" for c in choices),
            "blocked_cooldown": sum(c["monitor"]["blocked"] == "cooldown" for c in choices),
            "trust_end": rows[-1]["after"][actor]["trust"]}
    return result
