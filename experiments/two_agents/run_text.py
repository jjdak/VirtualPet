"""Run one backend per process; save all decisions, including invalid outputs."""
from __future__ import annotations

import argparse
import hashlib
import json
import platform
import resource
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

from world import probes, value_choice

ROOT = Path(__file__).resolve().parents[2]
SYSTEM = '''你控制一个小世界中的角色。选择下一处要去取食的食物，目标是让自己健康增加。
只能依据当前可见食物和个人记录决策。health_delta 是该次取食导致的健康变化，正数增加、负数减少。
记录可能是自己的亲历，也可能是另一个角色的转述。没有记录时效果未知。
只输出一个 JSON 对象，格式为 {"target":"食物id"}，target 必须是当前可见食物的 id。
不要输出解释或额外字段。移动和取食由世界执行。'''


def text_observation(observation: dict) -> str:
    parts = [f"角色：{observation['角色']}。你的位置：{observation['位置']}。健康：{observation['健康']}。", "当前可见食物："]
    for food in observation["可见食物"]:
        parts.append(f"编号 {food['id']}：{food['kind']}，位置 {food['pos']}。")
    parts.append("你的个人记录：")
    if not observation["个人记录"]:
        parts.append("没有记录，食物效果未知。")
    for m in observation["个人记录"]:
        change = "增加" if m["health_delta"] > 0 else "减少"
        prefix = "你亲自尝试过" if m["via"] == "亲历" else f"{m['source']}向你转述了自己的经历"
        parts.append(f"{prefix}：吃了{m['kind']}之后，健康{change}{abs(m['health_delta'])}。")
    return "\n".join(parts)


def parse_choice(raw: str, observation: dict, allow_fence: bool = True):
    text = raw.strip()
    # Accept exactly one JSON code fence; never repair payloads or infer targets.
    if allow_fence and text.startswith("```json\n") and text.endswith("\n```"):
        text = text[len("```json\n"):-len("\n```")]
    try:
        obj = json.loads(text)
        ids = {f["id"] for f in observation["可见食物"]}
        if isinstance(obj, dict) and set(obj) == {"target"} and obj["target"] in ids:
            return obj["target"]
    except (ValueError, TypeError):
        pass
    return None


def fingerprint():
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
            for p in (Path(__file__), Path(__file__).with_name("world.py"))}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--backend", choices=["value", "0.6B", "1.7B"], required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    output = args.output / f"{args.backend}.jsonl"
    if output.exists():
        raise SystemExit(f"Refusing to overwrite evidence: {output}")
    meta = {"backend": args.backend, "started_utc": datetime.now(timezone.utc).isoformat(),
            "client_date": "2026-10-31", "platform": platform.platform(),
            "python": platform.python_version(), "source_sha256": fingerprint(),
            "protocol": "E1-v3-natural-language", "input_encoding": "natural_language", "cases": 12, "probes_per_case": 8,
            "temperature": 0, "max_tokens": 48, "thinking": False,
            "concurrency": 1, "shared_weights_separate_memories": True,
            "llm_weights_trained": False}
    try:
        meta["hardware"] = subprocess.check_output(
            ["/usr/sbin/sysctl", "-n", "machdep.cpu.brand_string", "hw.memsize"],
            text=True).strip().splitlines()
    except subprocess.CalledProcessError:
        meta["hardware"] = "unavailable"
    if args.backend != "value":
        import mlx.core as mx
        from mlx_lm import load, stream_generate
        from mlx_lm.sample_utils import make_sampler
        from importlib.metadata import version
        entries = json.loads((ROOT / "PrivateAssets/AgentLab/models/manifest.json").read_text())
        entry = next(e for e in entries if e["size"] == args.backend)
        meta["model"] = entry
        meta["packages"] = {k: version(k) for k in ("mlx", "mlx-lm", "transformers")}
        t0 = time.perf_counter()
        model, tokenizer = load(str(ROOT / entry["path"]))
        mx.eval(model.parameters())
        meta["load_seconds"] = time.perf_counter() - t0

        def decide(observation):
            prompt = tokenizer.apply_chat_template(
                [{"role": "system", "content": SYSTEM},
                 {"role": "user", "content": text_observation(observation)}],
                tokenize=False, add_generation_prompt=True, enable_thinking=False)
            t0 = time.perf_counter()
            ttft = None
            pieces = []
            response = None
            for response in stream_generate(model, tokenizer, prompt=prompt,
                                            max_tokens=48, sampler=make_sampler(temp=0)):
                if ttft is None:
                    ttft = time.perf_counter()-t0
                pieces.append(response.text)
            elapsed = time.perf_counter()-t0
            assert response is not None
            return "".join(pieces), {
                "seconds": elapsed, "ttft_seconds": ttft,
                "prompt_tokens": response.prompt_tokens,
                "generation_tokens": response.generation_tokens,
                "generation_tps": response.generation_tps,
                "prompt_tps": response.prompt_tps,
                "mlx_peak_gb": response.peak_memory,
                "finish_reason": response.finish_reason,
                "prompt": prompt}

        _, warmup = decide(probes(0)[0][1].observe("甲"))
        meta["warmup"] = {k: v for k, v in warmup.items() if k != "prompt"}
    else:
        def decide(observation):
            t0 = time.perf_counter()
            raw = json.dumps({"target": value_choice(observation)})
            return raw, {"seconds": time.perf_counter()-t0, "prompt": None}

    with output.open("w") as handle:
        for case in range(12):
            for stage, world, actor in probes(case):
                obs = world.observe(actor)
                raw, timing = decide(obs)
                target = parse_choice(raw, obs)
                exposure_events = list(world.events)
                actions = world.execute_choice(actor, target) if target is not None else []
                delta = actions[-1].get("health_delta") if actions else None
                row = {"case": case, "stage": stage, "actor": actor, "observation": obs,
                       "raw": raw, "target": target, "valid": target is not None,
                       "strict_json": parse_choice(raw, obs, allow_fence=False) is not None,
                       "health_delta": delta, "beneficial": delta == 4,
                       "timing": timing, "setup_events": exposure_events,
                       "actions": actions, "hidden_effects_for_audit_only": world.effects}
                handle.write(json.dumps(row, ensure_ascii=False)+"\n")
                handle.flush()
            print(json.dumps({"backend": args.backend, "case_done": case,
                              "last_seconds": round(timing["seconds"], 3)}), flush=True)
    meta["rss_highwater_gb"] = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1e9
    meta["completed_utc"] = datetime.now(timezone.utc).isoformat()
    (args.output / f"{args.backend}.meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2)+"\n")


if __name__ == "__main__":
    main()
