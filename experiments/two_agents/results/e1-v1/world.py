"""Small deterministic world. Hidden food effects never enter observations."""
from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass, field


@dataclass
class Person:
    name: str
    pos: tuple[int, int] = (3, 2)
    health: int = 10
    memories: list[dict] = field(default_factory=list)


class World:
    def __init__(self, case: int, inverse: bool = False):
        names = [("青禾", "紫穗"), ("甲果", "乙果"), ("圆果", "方果")]
        kinds = names[(case // 4) % len(names)]
        if case % 2:
            kinds = kinds[::-1]
        self.food = {
            "p": {"kind": kinds[0], "pos": (2, 2)},
            "q": {"kind": kinds[1], "pos": (4, 2)},
        }
        good_kind = names[(case // 4) % len(names)][(case // 2) % 2]
        if inverse:
            good_kind = next(k for k in kinds if k != good_kind)
        self.effects = {k: 4 if k == good_kind else -4 for k in kinds}
        self.people = {k: Person(k) for k in ("甲", "乙")}
        self.walls = {(3, 1)}
        self.events: list[dict] = []

    def apply(self, actor: str, action: str, target) -> dict:
        p = self.people[actor]
        event = {"actor": actor, "action": action, "target": target, "ok": False}
        if action == "move":
            x, y = target
            if (0 <= x < 7 and 0 <= y < 5 and (x, y) not in self.walls
                    and abs(x-p.pos[0]) + abs(y-p.pos[1]) == 1):
                p.pos = (x, y)
                event.update(ok=True, pos=p.pos)
        elif action == "eat" and target in self.food:
            f = self.food[target]
            if p.pos == f["pos"]:
                delta = self.effects[f["kind"]]
                p.health += delta
                memory = {"kind": f["kind"], "health_delta": delta,
                          "source": actor, "via": "亲历"}
                p.memories.append(memory)
                event.update(ok=True, kind=f["kind"], health_delta=delta)
        elif action == "tell":
            receiver, index = target
            other = self.people.get(receiver)
            if (other and receiver != actor and 0 <= index < len(p.memories)
                    and sum(abs(a-b) for a, b in zip(p.pos, other.pos)) <= 1):
                memory = deepcopy(p.memories[index])
                memory.update(via="转述", source=actor)
                other.memories.append(memory)
                event.update(ok=True, memory=memory)
        self.events.append(event)
        return event

    def observe(self, actor: str) -> dict:
        p = self.people[actor]
        foods = [{"id": key, **deepcopy(f)} for key, f in self.food.items()
                 if sum(abs(a-b) for a, b in zip(p.pos, f["pos"])) <= 2]
        return {"角色": actor, "位置": p.pos, "健康": p.health,
                "可见食物": foods, "个人记录": deepcopy(p.memories)}

    def execute_choice(self, actor: str, target: str) -> list[dict]:
        """This task's skill controller traverses a clear horizontal corridor."""
        start = len(self.events)
        visible = {f["id"] for f in self.observe(actor)["可见食物"]}
        if target not in visible:
            return [{"actor": actor, "action": "choose", "ok": False,
                     "reason": "invalid_or_invisible_target", "target": target}]
        dest = self.food[target]["pos"]
        p = self.people[actor]
        for _ in range(12):
            if p.pos == dest:
                self.apply(actor, "eat", target)
                return deepcopy(self.events[start:])
            x, y = p.pos
            nxt = ((x + (1 if dest[0] > x else -1), y) if x != dest[0]
                   else (x, y + (1 if dest[1] > y else -1)))
            if not self.apply(actor, "move", nxt)["ok"]:
                break
        return deepcopy(self.events[start:])


def reset_body(w: World, actor: str):
    w.people[actor].pos = (3, 2)
    w.people[actor].health = 10


def expose(w: World):
    """Controlled exposure, NOT autonomous exploration."""
    w.people["乙"].pos = (6, 4)
    for target in ("p", "q"):
        reset_body(w, "甲")
        events = w.execute_choice("甲", target)
        assert events[-1]["ok"] and events[-1]["action"] == "eat"
    reset_body(w, "甲")
    reset_body(w, "乙")


def probes(case: int) -> list[tuple[str, World, str]]:
    w = World(case)
    result = [("A_before", deepcopy(w), "甲"), ("B_before", deepcopy(w), "乙")]
    expose(w)
    result.extend([("A_experienced", deepcopy(w), "甲"),
                   ("B_isolated", deepcopy(w), "乙")])
    for index in range(len(w.people["甲"].memories)):
        assert w.apply("甲", "tell", ("乙", index))["ok"]
    result.append(("B_told", deepcopy(w), "乙"))
    cleared = deepcopy(w)
    cleared.people["甲"].memories.clear()
    result.append(("A_cleared", cleared, "甲"))
    inverse = World(case, inverse=True)
    expose(inverse)
    result.append(("A_inverse_history", inverse, "甲"))
    relocated = deepcopy(w)
    relocated.food["p"]["pos"], relocated.food["q"]["pos"] = (
        relocated.food["q"]["pos"], relocated.food["p"]["pos"])
    result.append(("A_relocated", relocated, "甲"))
    return result


def value_choice(observation: dict) -> str:
    """Empirical mean reward from available evidence, zero prior, stable tie."""
    def score(food):
        evidence = [m["health_delta"] for m in observation["个人记录"]
                    if m["kind"] == food["kind"]]
        return sum(evidence)/len(evidence) if evidence else 0
    return max(observation["可见食物"], key=score)["id"]
