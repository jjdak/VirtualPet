"""E2: independent online value estimates and evidence-based source reliability.

No language model; neither Agent nor choose receives hidden world rewards.
"""
from collections import deque
from copy import deepcopy
import math
import random


class Agent:
    def __init__(self, name, policy, config):
        self.name, self.policy = name, policy
        self.config = {k: deepcopy(config[k]) for k in (
            "epsilon", "alpha", "fixed_trust", "trust_prior", "trust_retention",
            "message_ttl", "message_decay")}
        self.values = {k: 0.0 for k in ("p", "q")}
        self.counts = {k: 0 for k in ("p", "q")}
        self.trust_counts = list(self.config["trust_prior"])
        self.inbox, self.pending = {}, {}
        self.seen, self.validated = set(), set()
        self.validation_count = 0
        self.matches = 0

    def trust(self):
        if self.policy != "recent_trust":
            return self.config["fixed_trust"]
        a, b = self.trust_counts
        return a / (a+b)

    def begin_round(self, tick):
        if self.policy == "recent_trust":
            self.trust_counts = [prior + (value-prior)*self.config["trust_retention"]
                                 for prior, value in zip(self.config["trust_prior"], self.trust_counts)]
        self.pending = {k: m for k, m in self.pending.items()
                        if 0 <= tick-m["tick"] <= self.config["message_ttl"]}

    def choose(self, seed, tick):
        rng = random.Random(seed*100003 + tick*97 + (17 if self.name == "B" else 0))
        explore, tie = rng.random(), rng.random()
        scores = {}
        for kind in ("p", "q"):
            score = self.values[kind]
            message = self.inbox.get(kind)
            if message and 0 <= tick-message["tick"] <= self.config["message_ttl"]:
                weight = self.trust()*math.exp(-(tick-message["tick"])/self.config["message_decay"])
                score = (1-weight)*score + weight*message["claim"]
            scores[kind] = score
        unknown = [k for k in ("p", "q") if self.counts[k] == 0]
        if unknown:
            candidates, reason = unknown, "try_unknown"
        elif explore < self.config["epsilon"]:
            candidates, reason = ["p", "q"], "explore"
        else:
            best = max(scores.values())
            candidates = [k for k, v in scores.items() if abs(v-best) < 1e-12]
            reason = "estimated_value"
        target = candidates[min(int(tie*len(candidates)), len(candidates)-1)]
        return {"target": target, "reason": reason, "scores": scores,
                "values_before": dict(self.values), "trust_before": self.trust()}

    def experience(self, kind, reward, tick):
        self.counts[kind] += 1
        step = 1/self.counts[kind] if self.policy == "mean_fixed" else self.config["alpha"]
        if self.counts[kind] == 1:
            self.values[kind] = float(reward)
        else:
            self.values[kind] += step*(reward-self.values[kind])
        checked = []
        for identity, message in list(self.pending.items()):
            if message["kind"] != kind:
                continue
            age = tick-message["tick"]
            if 0 <= age <= self.config["message_ttl"] and identity not in self.validated:
                match = message["claim"] == reward
                self.validated.add(identity)
                self.validation_count += 1
                self.matches += int(match)
                if self.policy == "recent_trust":
                    self.trust_counts[0 if match else 1] += 1
                checked.append({"id": identity, "match": match, "age": age})
            del self.pending[identity]
        return checked

    def receive(self, message, tick):
        if self.policy == "recent_no_messages":
            return "disabled"
        if message["source"] == self.name:
            return "self"
        if message["id"] in self.seen:
            return "duplicate"
        if not 0 <= tick-message["tick"] <= self.config["message_ttl"]:
            return "expired"
        prior = self.inbox.get(message["kind"])
        if prior and prior["tick"] > message["tick"]:
            return "older_than_known"
        self.seen.add(message["id"])
        self.inbox[message["kind"]] = deepcopy(message)
        self.pending[message["id"]] = deepcopy(message)
        return "accepted"

    def snapshot(self):
        data = deepcopy(self.__dict__)
        data["seen"], data["validated"] = sorted(self.seen), sorted(self.validated)
        return data

    @classmethod
    def restore(cls, data):
        agent = cls(data["name"], data["policy"], data["config"])
        agent.__dict__.update(deepcopy(data))
        agent.seen, agent.validated = set(data["seen"]), set(data["validated"])
        return agent


class World:
    CAMP = (3, 3)
    FOOD = {"p": (1, 1), "q": (5, 1)}
    WALLS = {(3, 2)}

    def __init__(self):
        self.positions = {k: self.CAMP for k in ("A", "B")}
        self.health = {k: 0 for k in ("A", "B")}

    def move(self, actor, destination):
        old = self.positions[actor]
        x, y = destination
        if (not (0 <= x < 7 and 0 <= y < 5) or destination in self.WALLS
                or abs(x-old[0])+abs(y-old[1]) != 1):
            raise ValueError("blocked or non-adjacent move")
        self.positions[actor] = destination
        return {"action": "move", "from": old, "to": destination}

    def route(self, actor, destination):
        start = self.positions[actor]
        queue, parent = deque([start]), {start: None}
        while queue:
            x, y = queue.popleft()
            if (x, y) == destination:
                break
            for cell in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
                if (0 <= cell[0] < 7 and 0 <= cell[1] < 5
                        and cell not in self.WALLS and cell not in parent):
                    parent[cell] = (x, y)
                    queue.append(cell)
        if destination not in parent:
            raise ValueError("no path")
        path, cell = [], destination
        while parent[cell] is not None:
            path.append(cell)
            cell = parent[cell]
        return [self.move(actor, cell) for cell in reversed(path)]

    def eat(self, actor, kind, reward):
        if self.positions[actor] != self.FOOD[kind]:
            raise ValueError("food out of reach")
        self.health[actor] += reward
        return {"action": "eat", "kind": kind, "reward": reward}

    def tell(self, sender, receiver, message, agents, tick):
        a, b = self.positions[sender], self.positions[receiver]
        if abs(a[0]-b[0])+abs(a[1]-b[1]) > 1:
            raise ValueError("recipient out of range")
        return agents[receiver].receive(message, tick)


class Episode:
    def __init__(self, config, seed, scenario, policy):
        self.config, self.seed, self.scenario, self.policy = deepcopy(config), seed, scenario, policy
        self.agents = {k: Agent(k, policy, config) for k in ("A", "B")}
        self.world, self.tick, self.cached = World(), 0, None

    def reward(self, kind):
        good = "p" if self.seed % 2 == 0 else "q"
        if self.scenario in ("reversal", "stale_source") and self.tick >= self.config["flip_round"]:
            good = "q" if good == "p" else "p"
        return 1 if kind == good else -1

    def step(self):
        t, choices, messages = self.tick, {}, {}
        for agent in self.agents.values():
            agent.begin_round(t)
        for actor, agent in self.agents.items():
            choice = agent.choose(self.seed, t)
            kind = choice["target"]
            actions = self.world.route(actor, self.world.FOOD[kind])
            reward = self.reward(kind)
            actions.append(self.world.eat(actor, kind, reward))
            checked = agent.experience(kind, reward, t)
            actions.extend(self.world.route(actor, self.world.CAMP))
            messages[actor] = {"id": f"{actor}-{t}", "source": actor, "tick": t,
                               "kind": kind, "claim": reward}
            choices[actor] = {**choice, "reward": reward, "actions": actions,
                              "validated_messages": checked}
        if t == self.config["flip_round"]-1:
            self.cached = deepcopy(messages["A"])
        if (self.scenario == "faulty_source"
                and self.config["fault_start"] <= t < self.config["fault_end"]):
            messages["A"]["claim"] *= -1
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
                                 "trust": a.trust(), "validations": a.validation_count}
                            for k, a in self.agents.items()}}
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
        rewards = [r["choices"][actor]["reward"] for r in rows]
        streak, recovery = 0, None
        for index, reward in enumerate(rewards[start:], start):
            streak = streak+1 if reward > 0 else 0
            if streak == 5:
                recovery = index-start+1
                break
        result["agents"][actor] = {
            "beneficial_all": sum(v > 0 for v in rewards)/len(rewards),
            "beneficial_40_59": sum(v > 0 for v in rewards[start:start+20])/20,
            "beneficial_fault_phase": sum(v > 0 for v in rewards[config["fault_start"]:config["fault_end"]])/(config["fault_end"]-config["fault_start"]),
            "total_reward": sum(rewards), "recovery_rounds": recovery,
            "trust_before_fault": rows[config["fault_start"]-1]["after"][actor]["trust"],
            "trust_end_fault": rows[config["fault_end"]-1]["after"][actor]["trust"],
            "trust_end": rows[-1]["after"][actor]["trust"],
            "trust_min_post_flip": min(r["after"][actor]["trust"] for r in rows[start:start+20]),
            "validations": rows[-1]["after"][actor]["validations"],
        }
    return result
