"""Frozen E6 batch. Refuses overwriting any result directory."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import time

from core import Episode, summarize, E2_PATH, E3_PATH, E4_PATH, E5_PATH

LAB = Path(__file__).resolve().parents[1]


def run(config, output):
    output.mkdir(parents=True, exist_ok=False)
    raw = output / "raw"
    raw.mkdir()
    start = time.perf_counter()
    project = LAB.parents[1]
    tracked = list((LAB / "src").glob("*")) + list((LAB / "tests").glob("*")) + [E2_PATH, E3_PATH, E4_PATH, E5_PATH, project / "docs/sim/experiments/e6/PLAN.md"]
    sources = {str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest()
               for p in sorted(tracked) if p.is_file()}
    (output / "protocol.json").write_text(json.dumps(config, indent=2)+"\n")
    count = 0
    with (raw / "episodes.jsonl").open("w") as summaries:
        for scenario in config["scenarios"]:
            for policy in config["policies"]:
                for seed in range(config["seed_start"], config["seed_start"]+config["seeds"]):
                    e = Episode(config, seed, scenario, policy)
                    rows = [e.step() for _ in range(config["rounds"])]
                    summaries.write(json.dumps(summarize(rows, config, seed, scenario, policy))+"\n")
                    if seed in config["trace_seeds"] and scenario in config["trace_cases"]:
                        name = f"{scenario}--{policy}--{seed}"
                        (raw / f"{name}.jsonl").write_text("".join(json.dumps(r)+"\n" for r in rows))
                        (raw / f"{name}.final-state.json").write_text(json.dumps(e.snapshot(), indent=2)+"\n")
                    count += 1
                print(f"finished {scenario} / {policy}", flush=True)
    meta = {"protocol": config["protocol"], "client_date": config["client_date"],
            "finished_utc": datetime.now(timezone.utc).isoformat(), "python": platform.python_version(),
            "episodes": count, "choices": count*config["rounds"]*2,
            "elapsed_seconds": time.perf_counter()-start, "source_sha256": sources,
            "protocol_sha256": hashlib.sha256((output / "protocol.json").read_bytes()).hexdigest(),
            "dependencies": "Python standard library only", "llm_calls": 0}
    (output / "manifest.json").write_text(json.dumps(meta, indent=2)+"\n")
    print(json.dumps(meta), flush=True)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--protocol", type=Path, default=LAB / "protocols/e6-v1.json")
    p.add_argument("--output", type=Path, required=True)
    a = p.parse_args()
    run(json.loads(a.protocol.read_text()), a.output)
