"""Recompute all episodes; separately audit sampled physical/event traces."""
import argparse
import hashlib
import json
from pathlib import Path

from core import Episode, summarize


def canonical(value):
    return json.dumps(value, sort_keys=True)


def audit_trace(rows, config, scenario, seed):
    health = {k: 0 for k in ("A", "B")}
    positions = {k: (3, 3) for k in ("A", "B")}
    foods = {"p": (1, 1), "q": (5, 1)}
    seen_validation = {k: set() for k in ("A", "B")}
    incoming = {k: {} for k in ("A", "B")}
    actions = 0
    for tick, row in enumerate(rows):
        assert tick == row["tick"]
        good = ("p", "q")[seed % 2]
        if scenario in ("reversal", "stale_source") and tick >= config["flip_round"]:
            good = "q" if good == "p" else "p"
        for actor in ("A", "B"):
            choice = row["choices"][actor]
            expected_reward = 1 if choice["target"] == good else -1
            assert choice["reward"] == expected_reward
            eats = 0
            for event in choice["actions"]:
                actions += 1
                if event["action"] == "move":
                    start, end = tuple(event["from"]), tuple(event["to"])
                    assert start == positions[actor]
                    assert sum(abs(a-b) for a, b in zip(start, end)) == 1
                    assert 0 <= end[0] < 7 and 0 <= end[1] < 5 and end != (3, 2)
                    positions[actor] = end
                else:
                    assert event["action"] == "eat"
                    assert event["kind"] == choice["target"]
                    assert positions[actor] == foods[event["kind"]]
                    assert event["reward"] == expected_reward
                    health[actor] += expected_reward
                    eats += 1
            assert eats == 1 and positions[actor] == (3, 3)
            for check in choice["validated_messages"]:
                identity = check["id"]
                assert identity not in seen_validation[actor]
                assert identity in incoming[actor]
                message = incoming[actor][identity]
                assert message["kind"] == choice["target"]
                assert check["age"] == tick-message["tick"]
                assert 0 <= check["age"] <= config["message_ttl"]
                assert check["match"] == (message["claim"] == expected_reward)
                seen_validation[actor].add(identity)
        assert row["health"] == health
        for delivery in row["delivery"]:
            sender, receiver, msg = delivery["sender"], delivery["receiver"], delivery["message"]
            assert set(msg) == {"id", "source", "tick", "kind", "claim"}
            assert msg["source"] == sender
            expected_tick = (config["flip_round"]-1 if sender == "A" and scenario == "stale_source"
                             and tick >= config["flip_round"] else tick)
            assert msg["tick"] == expected_tick and msg["id"] == f"{sender}-{expected_tick}"
            choice = rows[expected_tick]["choices"][sender]
            expected = choice["reward"]
            if (sender == "A" and scenario == "faulty_source"
                    and config["fault_start"] <= tick < config["fault_end"]):
                expected *= -1
            assert msg["claim"] == expected and msg["kind"] == choice["target"]
            if delivery["status"] == "accepted":
                assert msg["id"] not in incoming[receiver]
                incoming[receiver][msg["id"]] = msg
    return actions


def main(directory):
    cfg = json.loads((directory / "protocol.json").read_text())
    manifest = json.loads((directory / "manifest.json").read_text())
    assert hashlib.sha256((directory / "protocol.json").read_bytes()).hexdigest() == manifest["protocol_sha256"]
    for name, digest in manifest["source_sha256"].items():
        assert hashlib.sha256(Path(__file__).with_name(name).read_bytes()).hexdigest() == digest
    results = [json.loads(line) for line in (directory / "raw/episodes.jsonl").read_text().splitlines()]
    assert len(results) == cfg["seeds"]*len(cfg["scenarios"])*len(cfg["policies"])
    keys = set()
    physical_actions, traces = 0, 0
    for result in results:
        seed, scenario, policy = result["seed"], result["scenario"], result["policy"]
        key = seed, scenario, policy
        assert key not in keys
        keys.add(key)
        e = Episode(cfg, seed, scenario, policy)
        rows = [e.step() for _ in range(cfg["rounds"])]
        assert summarize(rows, cfg, seed, scenario, policy) == result
        if seed in cfg["trace_seeds"]:
            name = f"{scenario}--{policy}--{seed}"
            recorded = [json.loads(line) for line in (directory / f"raw/{name}.jsonl").read_text().splitlines()]
            assert canonical(rows) == canonical(recorded)
            state = json.loads((directory / f"raw/{name}.final-state.json").read_text())
            assert canonical(e.snapshot()) == canonical(state)
            physical_actions += audit_trace(recorded, cfg, scenario, seed)
            traces += 1
    receipt = {"passed": True, "episodes_recomputed": len(results),
               "choices_recomputed": len(results)*cfg["rounds"]*2,
               "sampled_traces_independently_audited": traces,
               "physical_actions_independently_audited": physical_actions,
               "checks": ["world_reward_schedule", "adjacent_moves_and_walls", "food_reach",
                          "personal_evidence_before_trust_update", "no_duplicate_validation",
                          "message_age_and_channel_faults", "source_and_protocol_hashes"]}
    (directory / "verification.json").write_text(json.dumps(receipt, indent=2)+"\n")
    print(json.dumps(receipt))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    main(parser.parse_args().directory)
