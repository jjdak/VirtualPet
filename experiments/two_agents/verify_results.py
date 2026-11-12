"""Replay all logged actions and validate the information boundary, offline."""
import argparse
import hashlib
import json
from pathlib import Path

from run import parse_choice
from run_text import text_observation
from world import probes


def canonical(obj):
    return json.dumps(obj, ensure_ascii=False, sort_keys=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    observed = {}
    for backend in ("value", "0.6B", "1.7B"):
        rows = [json.loads(x) for x in (args.directory / f"{backend}.jsonl").read_text().splitlines()]
        meta = json.loads((args.directory / f"{backend}.meta.json").read_text())
        assert len(rows) == 96
        index = {(r["case"], r["stage"]): r for r in rows}
        assert len(index) == 96
        for file, digest in meta["source_sha256"].items():
            assert hashlib.sha256(Path(__file__).with_name(file).read_bytes()).hexdigest() == digest
        for case in range(12):
            for stage, world, actor in probes(case):
                row = index[case, stage]
                obs = world.observe(actor)
                assert canonical(obs) == canonical(row["observation"])
                assert canonical(world.events) == canonical(row["setup_events"])
                target = parse_choice(row["raw"], obs)
                assert target == row["target"]
                assert row["valid"] == (target is not None)
                assert row["strict_json"] == (parse_choice(row["raw"], obs, False) is not None)
                actions = world.execute_choice(actor, target) if target is not None else []
                assert canonical(actions) == canonical(row["actions"])
                delta = actions[-1].get("health_delta") if actions else None
                assert row["health_delta"] == delta
                assert row["beneficial"] == (delta == 4)
                if backend != "value":
                    prompt = row["timing"]["prompt"]
                    expected = (text_observation(obs) if meta.get("input_encoding") == "natural_language"
                                else json.dumps(obs, ensure_ascii=False))
                    assert expected in prompt
                    assert "hidden_effects" not in prompt
                observed.setdefault((case, stage), canonical(row["observation"]))
                assert observed[case, stage] == canonical(row["observation"])
        print(f"{backend}: 96 observations and action traces verified")
    receipt = {"passed": True, "decisions_verified": 288, "unique_probes": len(observed),
               "checks": ["same_observations_across_backends", "source_fingerprints",
                          "strict_and_fenced_json_separate", "setup_and_action_replay",
                          "actual_world_outcomes", "no_hidden_effect_field_in_prompt"]}
    (args.directory / "verification.json").write_text(json.dumps(receipt, indent=2)+"\n")


if __name__ == "__main__":
    main()
