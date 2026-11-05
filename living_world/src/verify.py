"""Reproduce W1 checks and a small causal example; no GUI claims generated here."""
from copy import deepcopy
from datetime import datetime
import hashlib
import io
import json
from pathlib import Path
import platform
import unittest

from world import World

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / 'docs/sim/living-world/review'


def main():
    REVIEW.mkdir(parents=True, exist_ok=True)
    output=io.StringIO()
    suite=unittest.defaultTestLoader.discover(str(ROOT/'living_world/tests'))
    result=unittest.TextTestRunner(stream=output,verbosity=2).run(suite)
    (REVIEW/'tests.txt').write_text(output.getvalue())
    if not result.wasSuccessful():
        print(output.getvalue());raise SystemExit(1)
    w=World(42);w.hint('A','q');frames=[]
    for _ in range(51):
        if w.tick==10:
            before={k:r.snapshot() for k,r in w.residents.items()}
            w.intervene('q',1,True)
            assert before=={k:r.snapshot() for k,r in w.residents.items()}
        if w.tick in (0,9,10,14,19,50):
            frames.append(dict(tick=w.tick,resources=deepcopy(w.resources),residents={
                k:dict(pos=r.pos,values=dict(r.brain.values),counts=dict(r.brain.counts),
                       hints=deepcopy(r.hints),inbox=deepcopy(r.brain.inbox),trust=r.brain.trust())
                for k,r in w.residents.items()}))
        w.step()
    assert frames[1]['residents']['A']['values']['q']==-1
    assert frames[3]['residents']['B']['values']['q']==1
    assert frames[3]['residents']['B']['hints']==[]
    assert frames[4]['residents']['A']['inbox']['q']['source']=='B'
    example=dict(seed=42,interventions=[dict(tick=0,action='hint',actor='A',kind='q'),
                 dict(tick=10,action='environment',kind='q',effect=1,available=True)],
                 note='Fixed illustrative trajectory, not a general learning-performance claim.',frames=frames,events=w.events)
    (REVIEW/'causal-example.json').write_text(json.dumps(example,ensure_ascii=False,indent=2)+'\n')
    paths=sorted((ROOT/'living_world').rglob('*.py'))+sorted((ROOT/'living_world/web').glob('*'))+[ROOT/'living_world/run.command',ROOT/'experiments/adaptive_agents/src/core.py']
    receipt=dict(verified_at=datetime.now().astimezone().isoformat(),python=platform.python_version(),
        tests_run=result.testsRun,failures=len(result.failures),errors=len(result.errors),
        checks=['3000-step movement/need/memory bounds with closures and reopen',
                '400-step exact continuation after save and identical subsequent interventions',
                'fresh Python process restores and reproduces 80 additional steps',
                'loopback HTTP commands, export/import, bad saves, origin/host restrictions',
                'real server clock advances, pause stops, restart restores paused',
                'fixed causal example: separate experiences and proximity-limited transfer'],
        source_sha256={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
        browser_verification='Separate manual receipt; this runner does not inspect UI.',owner_experience_accepted=False)
    (REVIEW/'verification.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(dict(tests=result.testsRun,passed=result.wasSuccessful(),example_frames=len(frames),receipt=str(REVIEW/'verification.json')),ensure_ascii=False))


if __name__=='__main__':main()
