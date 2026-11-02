"""Build inspectable summaries and an offline replay from actual event logs."""
import argparse
import json
import math
import statistics
from pathlib import Path

STAGES = {
    "A_before": "甲 · 无经验", "B_before": "乙 · 无经验",
    "A_experienced": "甲 · 亲历后", "B_isolated": "乙 · 隔离未获知",
    "B_told": "乙 · 接收甲的记录后", "A_cleared": "甲 · 清空记忆",
    "A_inverse_history": "甲 · 相反经历", "A_relocated": "甲 · 食物换位置",
}


def summarize(rows):
    grouped = {stage: [r for r in rows if r["stage"] == stage] for stage in STAGES}
    pairs = {c: {r["stage"]: r for r in rows if r["case"] == c}
             for c in sorted({r["case"] for r in rows})}
    pair = lambda a, b, equal: sum(
        p[a]["valid"] and p[b]["valid"] and ((p[a]["target"] == p[b]["target"]) == equal)
        for p in pairs.values())
    seconds = sorted(r["timing"]["seconds"] for r in rows)
    result = {
        "decisions": len(rows), "valid": sum(r["valid"] for r in rows),
        "strict_json": sum(r.get("strict_json", r["valid"]) for r in rows),
        "beneficial_by_stage": {k: sum(r["beneficial"] for r in v) for k, v in grouped.items()},
        "case_count": len(pairs),
        "experience_choice_changes": pair("A_before", "A_experienced", False),
        "communication_choice_changes": pair("B_isolated", "B_told", False),
        "isolated_consistent": pair("B_before", "B_isolated", True),
        "cleared_consistent": pair("A_before", "A_cleared", True),
        "inverse_choice_changes": pair("A_experienced", "A_inverse_history", False),
        "relocated_identity_consistent": pair("A_experienced", "A_relocated", True),
        "median_seconds": statistics.median(seconds),
        "p95_seconds": seconds[math.ceil(len(seconds)*.95)-1],
        "total_decision_seconds": sum(seconds),
    }
    if "generation_tokens" in rows[0]["timing"]:
        result.update(
            median_generation_tps=statistics.median(r["timing"]["generation_tps"] for r in rows),
            median_ttft_seconds=statistics.median(r["timing"]["ttft_seconds"] for r in rows),
            prompt_token_range=[min(r["timing"]["prompt_tokens"] for r in rows),
                                max(r["timing"]["prompt_tokens"] for r in rows)],
            peak_mlx_gb=max(r["timing"]["mlx_peak_gb"] for r in rows))
    return result


HTML = r'''<!doctype html><html lang="zh-CN"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>两个人，一段经历 · E1 实验回放</title><style>
*{box-sizing:border-box}body{margin:0;background:#eef1eb;color:#233b36;font:16px/1.65 system-ui,sans-serif}
main{max-width:1380px;margin:auto;padding:36px}h1{font-size:32px;font-weight:600;margin:5px 0}
.eyebrow{letter-spacing:3px;font-size:12px;color:#536f64}.note{color:#52655e;max-width:950px}
table{width:100%;border-collapse:collapse;background:#fffdf7;border-radius:12px;margin:24px 0}
td,th{text-align:left;padding:12px;border-bottom:1px solid #e0e7dc;font-size:14px}
.controls{display:flex;align-items:center;gap:16px;flex-wrap:wrap;margin:26px 0}
select,button{font:inherit;padding:8px 12px;background:#fffdf7;border:1px solid #bbc9bf;border-radius:8px;color:inherit}
button{background:#274c40;color:white;cursor:pointer}.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}
article{padding:22px;background:#fffdf7;border:1px solid #dce3d8;border-radius:14px;min-width:0}
h2{font-size:20px;margin:0 0 12px}.badge{background:#e3efdf;padding:5px 10px;border-radius:6px;font-size:14px}
.bad{background:#f7d7c6}.grid{display:grid;grid-template-columns:repeat(7,1fr);gap:4px;margin:20px 0}
.cell{aspect-ratio:1;background:#edf0e6;border-radius:5px;position:relative;display:flex;align-items:center;justify-content:center;font-size:11px}
.wall{background:#bbc4b5}.food{background:#f1dfb8}.person{position:absolute;right:1px;bottom:1px;width:22px;height:22px;border-radius:50%;background:#375f54;color:white;text-align:center;font-size:12px}
.event{min-height:55px;font-size:14px;overflow-wrap:anywhere}.memory{min-height:100px;font-size:14px;border-top:1px solid #dce3d8;padding-top:12px;white-space:pre-line}
pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px;max-height:300px;overflow:auto}
.small{font-size:12px;color:#5f7068}details{margin-top:12px}footer{margin-top:26px;font-size:13px;color:#5f7068}
@media(max-width:900px){.cards{grid-template-columns:1fr}main{padding:18px}table{display:block;overflow:auto}}
</style><main><div class="eyebrow">LOCAL AGENT LAB / E1</div><h1>两个人，一段经历</h1>
<p class="note">甲亲自尝试，乙先保持未知，再接收甲的经历。这里回放的是本机实际决策和动作记录；模型只选目标，世界负责移动与取食。</p>
<p class="small">受控实验 · 12 个世界 × 8 个探针 · 不代表自主分享或模型权重训练 · 食物标签、效果与位置已做对照</p>
<p id="encoding" class="small"></p>
<table><thead><tr><th>后端</th><th>亲历后有益选择</th><th>传播后有益选择</th><th>相反经历后</th><th>决策中位 / P95</th><th>MLX 峰值</th></tr></thead><tbody id="summary"></tbody></table>
<div class="controls"><label>世界 <select id="case"></select></label><label>对照 <select id="stage"></select></label><button id="play">播放实际行动</button></div>
<div id="cards" class="cards"></div><footer>“相反经历”是另一份环境效果相反的历史，不是同一个角色适应环境突变。告知动作由实验员安排，消息传递真实结果；尚未测试误导信息、主动分享、长期生存或 3D 渲染竞争。</footer></main>
<script>const DATA=__DATA__;const STAGES=__STAGES__;
document.getElementById('encoding').textContent='本页输入编码：'+(DATA['0.6B'].meta.input_encoding==='natural_language'?'中文句子（探索性对照）':'结构化 JSON（预定协议）')+'。两种模型均为 4-bit，关闭长思考，顺序推理。';
const el=(tag,text,cls)=>{const e=document.createElement(tag);if(text!==undefined)e.textContent=text;if(cls)e.className=cls;return e};
const secs=x=>x<.001?'< 0.001':x.toFixed(3);
for(const [key,d] of Object.entries(DATA)){const s=d.summary,tr=el('tr');for(const v of [key==='value'?'经验价值表（无 LLM）':'Qwen3 '+key,s.beneficial_by_stage.A_experienced+'/12',s.beneficial_by_stage.B_told+'/12',s.beneficial_by_stage.A_inverse_history+'/12',secs(s.median_seconds)+' / '+secs(s.p95_seconds)+' s',s.peak_mlx_gb?s.peak_mlx_gb.toFixed(2)+' GB':'—'])tr.append(el('td',v));document.querySelector('#summary').append(tr)}
for(let c=0;c<12;c++){let o=el('option','世界 '+(c+1));o.value=c;document.querySelector('#case').append(o)}
for(const [key,name] of Object.entries(STAGES)){let o=el('option',name);o.value=key;document.querySelector('#stage').append(o)}
document.querySelector('#stage').value='B_told';let timer;
function render(step=-1){const c=Number(document.querySelector('#case').value),stage=document.querySelector('#stage').value;document.querySelector('#cards').replaceChildren();
for(const [key,d] of Object.entries(DATA)){const r=d.rows.find(r=>r.case===c&&r.stage===stage);const a=el('article');a.append(el('h2',key==='value'?'经验价值表':'Qwen3 '+key));a.append(el('span',r.valid?(r.beneficial?'结果：健康 +4':'结果：健康 −4'):'无效输出',r.beneficial?'badge':'badge bad'));
let pos=r.observation['位置'],health=r.observation['健康'];for(let i=0;i<=step&&i<r.actions.length;i++){const e=r.actions[i];if(e.ok&&e.pos)pos=e.pos;if(e.ok&&e.health_delta)health+=e.health_delta}
const grid=el('div',undefined,'grid');for(let y=0;y<5;y++)for(let x=0;x<7;x++){const f=r.observation['可见食物'].find(f=>f.pos[0]===x&&f.pos[1]===y);const cell=el('div',f?f.id+' · '+f.kind:'','cell'+(x===3&&y===1?' wall':'')+(f?' food':''));if(pos[0]===x&&pos[1]===y)cell.append(el('span',r.actor,'person'));grid.append(cell)}a.append(grid);
const e=r.actions[Math.min(step,r.actions.length-1)];let event=step<0?'行动尚未播放':!e?'没有可执行行动':e.action==='move'?'移动到 ('+e.pos.join(', ')+')':e.action==='eat'?'吃了'+e.kind+'，健康'+(e.health_delta>0?'增加':'减少')+Math.abs(e.health_delta):e.action;a.append(el('div','健康 '+health+' · '+event,'event'));
const memories=r.observation['个人记录'];a.append(el('div',memories.length?memories.map(m=>m.via+' / 来源 '+m.source+'：'+m.kind+' → 健康 '+(m.health_delta>0?'+':'')+m.health_delta).join('\n'):'个人记录为空：不知道食物效果。','memory'));
a.append(el('p','决策 '+secs(r.timing.seconds)+' s · 目标 '+(r.target||'无'),'small'));const details=el('details');details.append(el('summary','原始输出与可见信息'));details.append(el('pre',r.raw+'\n\n'+JSON.stringify(r.observation,null,2)));a.append(details);document.querySelector('#cards').append(a)}}
for(const id of ['case','stage'])document.getElementById(id).onchange=()=>{clearInterval(timer);render()};document.querySelector('#play').onclick=()=>{clearInterval(timer);let step=-1;render();timer=setInterval(()=>{render(++step);if(step>=3)clearInterval(timer)},550)};render();
</script></html>'''


def main():
    p = argparse.ArgumentParser()
    p.add_argument("directory", type=Path)
    args = p.parse_args()
    all_data = {}
    for backend in ("value", "0.6B", "1.7B"):
        rows = [json.loads(line) for line in (args.directory / f"{backend}.jsonl").read_text().splitlines()]
        assert len(rows) == 96, (backend, len(rows))
        meta = json.loads((args.directory / f"{backend}.meta.json").read_text())
        all_data[backend] = {"summary": summarize(rows), "meta": meta, "rows": rows}
    summary = {k: {"summary": v["summary"], "meta": v["meta"]} for k, v in all_data.items()}
    (args.directory / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2)+"\n")
    # Embed only synthetic data; escape '<' so model output cannot close the script.
    data = json.dumps(all_data, ensure_ascii=False).replace('<', '\\u003c')
    page = HTML.replace('__DATA__', data).replace('__STAGES__', json.dumps(STAGES, ensure_ascii=False))
    (args.directory / "replay.html").write_text(page)
    print(json.dumps({k: v["summary"] for k, v in all_data.items()}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
