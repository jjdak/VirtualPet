"""Standalone excursion ledger. Render the recorded departures and physical returns."""
from html import escape
import json

from w3_long import END
from w3_endpoint import OUT

PLACE = {'p':'青禾', 'q':'紫穗'}
NAME = {'A':'阿禾','B':'小岚'}
PHASE = {'rest':'营地休息','homebound':'返回营地','outbound':'前往食物地'}
LABEL = {'fixed_lag':'固定时差可对齐', 'matched_sequence':'邻近游程同地，时差有变化',
         'place_difference':'邻近游程有实际改选', 'insufficient':'样本不足'}


def timeline(person):
    lo,hi = END-80,END+80
    def x(t):
        return 90+(t-lo)*4.6
    svg = ['<svg viewBox="0 0 860 106" role="img" aria-label="两边出发到回营的游程。竖线为第2640步。">']
    for side, text, y in [('control','无干预',27),('hinted','有线索',61)]:
        svg.append(f'<text x="4" y="{y+5}">{text}</text><line x1="90" y1="{y}" x2="826" y2="{y}" stroke="#b7c1b3"/>')
        for trip in person['nearby'][side]:
            depart,home = trip['depart'],trip['home']
            if home is None or home<lo or depart>hi:
                continue
            a,b = x(max(lo,depart)),x(min(hi,home))
            color = '#477156' if trip['place']=='p' else '#846184'
            svg.append(f'<g><title>{PLACE[trip["place"]]}：+{depart} 出发，+{trip["eat"]} 取食，+{home} 回营</title>'
                       f'<rect x="{a:.1f}" y="{y-9}" width="{max(1,b-a):.1f}" height="18" rx="3" fill="{color}"/>')
            if b-a>23:
                svg.append(f'<text x="{(a+b)/2:.1f}" y="{y+4}" text-anchor="middle" style="fill:white">{PLACE[trip["place"]]}</text>')
            svg.append('</g>')
    svg.append(f'<line x1="{x(END)}" x2="{x(END)}" y1="2" y2="78" stroke="#934f38" stroke-dasharray="4 2"/>')
    for t in (lo,END-40,END,END+40,hi):
        svg.append(f'<text x="{x(t)}" y="97" text-anchor="middle">+{t}</text>')
    return ''.join(svg)+'</svg>'


def card(case, name, person, opened):
    lines = []
    for s,label in [('control','无干预'),('hinted','有线索')]:
        endpoint = person[s]['endpoint']
        t = person[s]['latest_trip']
        lines.append(f'<tr><th>{label}</th><td>{PHASE[endpoint["phase"]]} {tuple(endpoint["pos"])}</td>'
                     f'<td>{PLACE[t["place"]]}</td><td>+{t["depart"]}</td><td>+{t["eat"]}</td><td>+{t["home"]}</td></tr>')
    exact = '、'.join(f'{d:+d}' for d in person['exact_lags'])
    info = f'固定偏移（右减左）为 {exact} 步。' if exact else '固定平移检查覆盖分支后 +2560 至 +2720，两侧均核对。'
    rows = []
    alignment = person['best_alignment']
    for pair in alignment['trips'] if alignment else []:
        a,b = pair['control'],pair['hinted']
        rows.append(f'<tr><td>{PLACE[a["place"]]} ／ {PLACE[b["place"]]}</td><td>+{a["depart"]} ／ +{b["depart"]}</td>'
                    f'<td>+{a["home"]} ／ +{b["home"]}</td><td>{pair["delta"]["depart"]:+d} ／ {pair["delta"]["home"]:+d}</td></tr>')
    family = '效果互换' if case['family']=='reversal' else '天气交替'
    identity = f'{family} · 种子 {case["seed"]} · 原步 {case["age"]} · 提示{NAME[case["actor"]]}去{PLACE[case["kind"]]}'
    return f'''<details {'open' if opened else ''}><summary>{escape(identity)} ｜ 观察{NAME[name]} · {LABEL[person['classification']]}</summary>
<p>第 +2640 步及最近一趟。回营时刻取实际抵达营地格的那一步。</p><div class="scroll"><table><thead><tr>
<th>分支</th><th>截点状态／格子</th><th>去向</th><th>出发</th><th>取食</th><th>回营</th></tr></thead><tbody>{''.join(lines)}</tbody></table></div>
<div class="scroll">{timeline(person)}</div><p>{info} 下表按相邻游程配对，时间均相对原始分支。</p>
<div class="scroll"><table><thead><tr><th>地点 左／右</th><th>出发 左／右</th><th>回营 左／右</th><th>出发差／回营差</th></tr></thead><tbody>{''.join(rows)}</tbody></table></div></details>'''


def main():
    report = json.loads((OUT/'diagnosis.json').read_text())
    cards = []
    for c in report['cases']:
        for name,p in c['people'].items():
            if p['affected']:
                cards.append(card(c,name,p,(c['family'],c['seed'],c['actor'])==('reversal',4,'A')))
    page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>第 2640 步 · 游程对照</title><style>*{box-sizing:border-box}body{background:#f2f5ee;color:#293d36;font:15px/1.65 system-ui,sans-serif;margin:0}main{max-width:1040px;margin:auto;padding:28px 16px}h1{font-size:26px}
details{background:#fffef8;border:1px solid #ccd8c9;border-radius:10px;padding:14px 18px;margin:10px 0}summary{cursor:pointer;font-weight:600}.scroll{overflow-x:auto}table{border-collapse:collapse;width:100%}td,th{text-align:left;padding:5px 10px;border-bottom:1px solid #e2e6dc;white-space:nowrap}svg{width:100%;min-width:580px;display:block;margin-top:12px}svg text{font:12px system-ui;fill:#405347}</style>
<main><h1>第 2640 步，选的是哪一处？</h1>
<p>展开条目核对有差异角色的真实游程。色块从出发延伸到回营，竖线标出第 +2640 步。下方的游程表同时给出同地点或不同地点的配对证据。</p>'''
    (OUT/'index.html').write_text(page+''.join(cards)+'</main></html>\n')


if __name__=='__main__':
    main()
