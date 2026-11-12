import argparse
import json
from pathlib import Path
import random
import statistics


def paired_interval(values):
    rng = random.Random(20261101)
    samples = sorted(statistics.mean(rng.choices(values, k=len(values))) for _ in range(2000))
    return {"mean_difference":statistics.mean(values), "bootstrap_95_interval":[samples[49],samples[1949]],
            "positive":sum(v > 1e-12 for v in values), "tied":sum(abs(v) <= 1e-12 for v in values),
            "negative":sum(v < -1e-12 for v in values)}


def build(directory):
    cfg = json.loads((directory/"protocol.json").read_text())
    episodes = [json.loads(s) for s in (directory/"raw/episodes.jsonl").read_text().splitlines()]
    aggregate, paired, traces = {}, {}, {}
    for scenario in cfg["scenarios"]:
        aggregate[scenario], paired[scenario] = {}, {}
        selected = {(e["seed"], e["policy"]):e["agents"] for e in episodes if e["scenario"] == scenario}
        for policy in cfg["policies"]:
            aggregate[scenario][policy] = {}
            for actor in ("A", "B"):
                records = [selected[s,policy][actor] for s in range(cfg["seeds"])]
                stats = {k:statistics.mean(r[k] for r in records) for k in records[0] if k != "recovery_rounds"}
                recoveries = [r["recovery_rounds"] for r in records if r["recovery_rounds"] is not None]
                stats.update(median_recovery=statistics.median(recoveries) if recoveries else None,
                             not_recovered=cfg["seeds"]-len(recoveries))
                aggregate[scenario][policy][actor] = stats
            name = f"{scenario}--{policy}--0"
            traces[f"{scenario}/{policy}"] = [json.loads(s) for s in (directory/f"raw/{name}.jsonl").read_text().splitlines()]
        for comparator in ("random_12", "random_24", "surprise_random"):
            paired[scenario][comparator] = {}
            for metric in ("optimal_40_59", "regret"):
                values = [selected[s,"surprise_stale"]["B"][metric]-selected[s,comparator]["B"][metric]
                          for s in range(cfg["seeds"])]
                paired[scenario][comparator][metric] = paired_interval(values)
    summary = {"seeds":cfg["seeds"], "aggregate":aggregate, "paired_stale_minus_comparator_B":paired,
               "interval_method":"2000 paired seed bootstrap replicates; fixed RNG 20261101; marginal intervals, not multiplicity adjusted"}
    (directory/"summary.json").write_text(json.dumps(summary,indent=2)+'\n')
    payload = json.dumps({"config":cfg,"summary":summary,"traces":traces},ensure_ascii=False).replace('<','\\u003c')
    (directory/"replay.html").write_text(Path(__file__).with_name("replay.html").read_text().replace("__PAYLOAD__",payload))
    for scenario in cfg["scenarios"]:
        print(scenario, {p:{k:round(aggregate[scenario][p]["B"][k],3) for k in
                              ("optimal_40_59","regret","probes","probe_regret","median_recovery")}
                         for p in cfg["policies"]})


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("directory",type=Path)
    build(p.parse_args().directory)
