"""Presentation-only footer correction; leaves frozen batch sources/data intact."""
import hashlib
import json
from pathlib import Path
import sys
p=Path(sys.argv[1]);f=p/'replay.html';s=f.read_text()
old='判断超过 18 回合未亲历时可日常复查，自适应策略为意外保留 1 次可用额度。'
new='固定策略使用 12 / 18 / 30 回合阈值；自适应初始 18 回合，收益代理 ≥0.25 时减半（最低 6），否则加 6（最高 42）。各策略均保留 1 次应急额度。收益代理是亲历结果减原优选估计，并非真实反事实收益。'
if new in s:
    print('Presentation correction already applied.');sys.exit(0)
assert s.count(old)==1
before=hashlib.sha256(f.read_bytes()).hexdigest()
f.write_text(s.replace(old,new))
(p/'review').mkdir(exist_ok=True)
(p/'review/presentation-fix.json').write_text(json.dumps(dict(date='2026-11-02',scope='Footer text only, no data/code/experiment changes; frozen template retained for batch provenance',before_sha256=before,after_sha256=hashlib.sha256(f.read_bytes()).hexdigest(),replacement=new),ensure_ascii=False,indent=2)+'\n')
