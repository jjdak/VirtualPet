import argparse
import json
from pathlib import Path
import statistics


def build(directory):
    cfg = json.loads((directory / "protocol.json").read_text())
    episodes = [json.loads(line) for line in (directory / "raw/episodes.jsonl").read_text().splitlines()]
    aggregate, traces = {}, {}
    for scenario in cfg["scenarios"]:
        aggregate[scenario] = {}
        for policy in cfg["policies"]:
            selected = [e for e in episodes if e["scenario"] == scenario and e["policy"] == policy]
            assert len(selected) == cfg["seeds"]
            roles = {}
            for actor in ("A", "B"):
                records = [e["agents"][actor] for e in selected]
                stats = {key: statistics.mean(r[key] for r in records)
                         for key in records[0] if key != "recovery_rounds"}
                recovered = [r["recovery_rounds"] for r in records if r["recovery_rounds"] is not None]
                stats.update(recovered=len(recovered), not_recovered=len(records)-len(recovered),
                             median_recovery=statistics.median(recovered) if recovered else None)
                roles[actor] = stats
            aggregate[scenario][policy] = roles
            name = f"{scenario}--{policy}--0"
            traces[f"{scenario}/{policy}"] = [json.loads(line) for line in
                                              (directory / f"raw/{name}.jsonl").read_text().splitlines()]
    paired = {}
    for scenario in cfg["scenarios"]:
        by_seed = {(e["seed"], e["policy"]): e["agents"]["B"] for e in episodes if e["scenario"] == scenario}
        differences = [by_seed[s, "recent_trust"]["beneficial_fault_phase"] -
                       by_seed[s, "recent_fixed"]["beneficial_fault_phase"] for s in range(cfg["seeds"])]
        paired[scenario] = {"metric": "B beneficial rate rounds 20..79",
                            "mean_difference": statistics.mean(differences),
                            "better_seeds": sum(d > 0 for d in differences),
                            "equal_seeds": sum(d == 0 for d in differences),
                            "worse_seeds": sum(d < 0 for d in differences)}
    summary = {"seeds_per_group": cfg["seeds"], "aggregate": aggregate, "paired_trust_vs_fixed": paired}
    (directory / "summary.json").write_text(json.dumps(summary, indent=2)+"\n")
    data = {"config": cfg, "summary": summary, "traces": traces}
    payload = json.dumps(data, ensure_ascii=False).replace('<', '\\u003c')
    template = Path(__file__).with_name("replay.html").read_text()
    (directory / "replay.html").write_text(template.replace("__PAYLOAD__", payload))
    print(json.dumps(paired, indent=2))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("directory", type=Path)
    build(p.parse_args().directory)
