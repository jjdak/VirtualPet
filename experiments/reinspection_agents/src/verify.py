"""Recompute all runs and independently check sampled actions/evidence/probes."""
import argparse
import hashlib
import json
from pathlib import Path
import random

from core import Episode, summarize

PROJECT = Path(__file__).resolve().parents[3]


def expected(config, scenario, seed, tick, actor, kind):
    good = ("p", "q")[seed % 2]
    if scenario == "hidden_improvement":
        value = .5 if kind == good else (1 if tick >= config["flip_round"] else -1)
    else:
        if scenario in ("reversal", "stale_source", "noisy_reversal") and tick >= config["flip_round"]:
            good = "q" if good == "p" else "p"
        value = 1 if kind == good else -1
    mean = value
    if scenario in ("noisy_stable", "noisy_reversal"):
        mean *= 1-2*config["noise_probability"]
        code = seed*1000003 + tick*1009 + (101 if actor == "B" else 0) + (503 if kind == "q" else 0) + 90000001
        if random.Random(code).random() < config["noise_probability"]:
            value *= -1
    return value, mean


def audit(rows, cfg, scenario, seed, policy):
    physical = 0
    for actor in ("A", "B"):
        position = (3, 3)
        health, used, last_probe = 0, 0, -1000
        counts, values = dict(p=0, q=0), dict(p=0., q=0.)
        last_seen = dict(p=None, q=None)
        streak, previous_kind, scheduled = 0, None, None
        for tick, row in enumerate(rows):
            assert row["tick"] == tick
            c = row["choices"][actor]
            kind, monitor = c["target"], c["monitor"]
            assert c["values_before"] == values
            if scheduled:
                assert c["probe"] == scheduled
                assert tick-scheduled["tick"] == 1
                used += 1
                assert used <= cfg["probe_budget"] and tick-last_probe >= cfg["probe_cooldown"]
                last_probe = tick
                if policy == "surprise_stale":
                    assert kind == scheduled["candidate"] and c["reason"] == "recheck_stale"
                else:
                    assert policy == "surprise_random" and c["reason"] == "recheck_random"
            else:
                assert c["probe"] is None
                assert c["target"] == c["base_target"] and c["reason"] == c["base_reason"]
            scheduled = None
            reward, mean = expected(cfg, scenario, seed, tick, actor, kind)
            assert c["reward"] == reward
            for food in ("p", "q"):
                assert row["evaluation_only"]["expected_rewards"][food] == expected(cfg, scenario, seed, tick, actor, food)[1]
            prediction = values[kind]
            surprise = counts[kind] >= cfg["min_experiences"] and abs(reward-prediction) >= cfg["residual_threshold"]
            streak = (streak+1 if previous_kind == kind else 1) if surprise else 0
            previous_kind = kind
            other = "q" if kind == "p" else "p"
            age = None if last_seen[other] is None else tick-last_seen[other]
            eligible = streak >= cfg["consecutive_errors"] and age is not None and age >= cfg["stale_after"]
            blocked = None
            if eligible and policy.startswith("surprise_"):
                if used >= cfg["probe_budget"]: blocked = "budget"
                elif tick+1-last_probe < cfg["probe_cooldown"]: blocked = "cooldown"
                else:
                    scheduled = {"tick":tick, "kind":kind, "prediction":prediction,
                                 "observed":reward, "residual":abs(reward-prediction),
                                 "streak":streak, "candidate":other, "candidate_age":age}
            assert monitor == {"prediction":prediction, "residual":abs(reward-prediction),
                               "prior_count":counts[kind], "unexpected":surprise, "streak":streak,
                               "candidate":other, "candidate_age":age, "eligible":eligible,
                               "scheduled":scheduled is not None, "blocked":blocked}
            counts[kind] += 1
            values[kind] = float(reward) if counts[kind] == 1 else values[kind]+cfg["alpha"]*(reward-values[kind])
            last_seen[kind] = tick
            eats = 0
            for action in c["actions"]:
                physical += 1
                if action["action"] == "move":
                    start, end = tuple(action["from"]), tuple(action["to"])
                    assert start == position and sum(abs(x-y) for x, y in zip(start, end)) == 1
                    assert 0 <= end[0] < 7 and 0 <= end[1] < 5 and end != (3, 2)
                    position = end
                else:
                    assert action["action"] == "eat" and action["kind"] == kind
                    assert position == ({"p":(1,1), "q":(5,1)}[kind]) and action["reward"] == reward
                    eats += 1
                    health += reward
            assert position == (3, 3) and eats == 1 and row["health"][actor] == health
            assert row["after"][actor]["values"] == values
            assert row["after"][actor]["counts"] == counts
            assert row["after"][actor]["last_seen"] == last_seen
            assert row["after"][actor]["probes_used"] == used
            assert row["terminated"] is False and row["truncated"] == (tick+1 == cfg["rounds"])
        assert len(rows) == cfg["rounds"]
    for tick, row in enumerate(rows):
        for d in row["delivery"]:
            msg = d["message"]
            t = cfg["flip_round"]-1 if scenario == "stale_source" and d["sender"] == "A" and tick >= cfg["flip_round"] else tick
            assert msg == {"id":f'{d["sender"]}-{t}', "source":d["sender"], "tick":t,
                           "kind":rows[t]["choices"][d["sender"]]["target"],
                           "claim":rows[t]["choices"][d["sender"]]["reward"]}
    return physical


def main(directory):
    cfg = json.loads((directory / "protocol.json").read_text())
    manifest = json.loads((directory / "manifest.json").read_text())
    for path, digest in manifest["source_sha256"].items():
        assert hashlib.sha256((PROJECT/path).read_bytes()).hexdigest() == digest, path
    assert hashlib.sha256((directory/"protocol.json").read_bytes()).hexdigest() == manifest["protocol_sha256"]
    episodes = [json.loads(s) for s in (directory/"raw/episodes.jsonl").read_text().splitlines()]
    keys, physical, traces = set(), 0, 0
    for result in episodes:
        seed, scenario, policy = result["seed"], result["scenario"], result["policy"]
        assert (seed, scenario, policy) not in keys
        keys.add((seed, scenario, policy))
        e = Episode(cfg, seed, scenario, policy)
        rows = [e.step() for _ in range(cfg["rounds"])]
        assert result == summarize(rows, cfg, seed, scenario, policy)
        if seed in cfg["trace_seeds"]:
            name = f"{scenario}--{policy}--{seed}"
            saved = [json.loads(s) for s in (directory/f"raw/{name}.jsonl").read_text().splitlines()]
            assert saved == json.loads(json.dumps(rows))
            assert json.loads((directory/f"raw/{name}.final-state.json").read_text()) == json.loads(json.dumps(e.snapshot()))
            physical += audit(saved, cfg, scenario, seed, policy)
            traces += 1
    expected_keys = {(s, c, p) for s in range(cfg["seeds"]) for c in cfg["scenarios"] for p in cfg["policies"]}
    assert keys == expected_keys
    receipt = {"passed":True, "episodes_recomputed":len(keys), "choices_recomputed":len(keys)*cfg["rounds"]*2,
               "traces_independently_audited":traces, "physical_actions_audited":physical,
               "checks":["source/config fingerprints", "world schedule and noise", "actions and rewards",
                         "personal-only prediction and delayed probe", "staleness/cooldown/budget", "messages", "final snapshots", "truncation"]}
    (directory/"verification.json").write_text(json.dumps(receipt,indent=2)+'\n')
    print(json.dumps(receipt))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("directory", type=Path)
    main(p.parse_args().directory)
