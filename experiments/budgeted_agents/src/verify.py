"""Recompute all trials; audit sampled world, physical steps and budget independently."""
import argparse
import hashlib
import json
from pathlib import Path
import random
from core import Episode, summarize

PROJECT=Path(__file__).resolve().parents[3]


def outcome(cfg,case,seed,t,actor,food):
    original=('p','q')[seed%2];kind=case['kind'];at=case['change_at']
    if kind=='hidden_gain':v=.5 if food==original else (1 if t>=at else -1)
    elif kind in ('staggered','noisy_staggered'):
        v=(1 if t<at else -.75) if food==original else (-.25 if t<at+cfg['stagger_delay'] else -1)
    else:
        best=original if kind!='swap' or t<at else ('q' if original=='p' else 'p')
        v=1 if food==best else -1
    mean=v
    if kind in ('noisy_stable','noisy_staggered'):
        mean=v*(1-2*cfg['noise_probability'])
        code=seed*1000003+t*1009+(101 if actor=='B' else 0)+(503 if food=='q' else 0)+90000001
        if random.Random(code).random()<cfg['noise_probability']:v=-v
    return v,mean


def audit(rows,cfg,scenario,seed,policy):
    case=next(c for c in cfg['cases'] if c['id']==scenario)
    actions=0
    for actor in ('A','B'):
        used,last=0,-1000;values=dict(p=0.,q=0.);counts=dict(p=0,q=0)
        seen=dict(p=None,q=None);streak=0;prior_kind=None;pending=None
        health=0;position=(3,3)
        for t,row in enumerate(rows):
            assert row['tick']==t
            c=row['choices'][actor];target=c['target'];m=c['monitor']
            assert c['values_before']==values
            if policy!='e3_reference':
                released=min(cfg['total_budget'],1+t//cfg['budget_release_every'])
                def ledger():return dict(released=released,used=used,available=released-used,last_spend=last,limit=cfg['total_budget'])
                assert c['budget_before']==ledger()
                candidates=[]
                if c['base_reason']!='try_unknown':
                    if pending and policy in ('trigger_only','hybrid'):
                        assert pending['tick']==t-1
                        candidates.append(('trigger',pending['candidate'],pending))
                    old=[k for k in ('p','q') if seen[k] is not None and t-seen[k]>=cfg['periodic_age']]
                    if old and policy in ('periodic_only','hybrid'):
                        k=min(old,key=lambda k:seen[k]);candidates.append(('periodic',k,dict(last_seen=seen[k],age=t-seen[k])))
                    if policy=='budget_random':
                        rng=random.Random(seed*100003+t*97+(17 if actor=='B' else 0));roll,tie=rng.random(),rng.random()
                        if roll<cfg['epsilon']:candidates.append(('random',('p','q')[int(tie*2)],dict(roll=roll)))
                requests=[];granted=None
                for source,k,evidence in candidates:
                    block=None
                    if released-used<1:block='budget'
                    elif t-last<cfg['budget_cooldown']:block='cooldown'
                    elif source=='periodic' and policy=='hybrid' and released-used<=cfg['hybrid_reserve']:block='reserve'
                    req=dict(source=source,target=k,evidence=evidence,blocked=block);requests.append(req)
                    if block is None:
                        granted=req;used+=1;last=t;break
                assert c['requests']==requests and c['probe']==granted
                assert c['budget_after']==ledger() and row['after'][actor]['budget']==ledger()
                assert used<=released<=cfg['total_budget']
                if granted:
                    assert target==granted['target'] and c['reason']==granted['source']+'_probe'
                else:assert target==c['base_target'] and c['reason']==c['base_reason']
            else:assert c['budget_before'] is None and c['budget_after'] is None
            value,mean=outcome(cfg,case,seed,t,actor,target)
            assert c['reward']==value
            for food in ('p','q'):
                assert row['evaluation_only']['expected_rewards'][food]==outcome(cfg,case,seed,t,actor,food)[1]
            residual=abs(value-values[target]);unexpected=counts[target]>=cfg['min_experiences'] and residual>=cfg['residual_threshold']
            streak=(streak+1 if prior_kind==target else 1) if unexpected else 0
            prior_kind=target;other='q' if target=='p' else 'p';age=None if seen[other] is None else t-seen[other]
            eligible=streak>=cfg['consecutive_errors'] and age is not None and age>=cfg['stale_after']
            for key,expected in dict(prediction=values[target],residual=residual,prior_count=counts[target],unexpected=unexpected,streak=streak,candidate=other,candidate_age=age,eligible=eligible).items():assert m[key]==expected
            pending=None
            if policy!='e3_reference':
                proposed=eligible and policy in ('trigger_only','hybrid')
                assert m['request_proposed']==proposed
                if proposed:pending=dict(tick=t,candidate=other,candidate_age=age,kind=target,prediction=values[target],observed=value,residual=residual,streak=streak)
            counts[target]+=1
            values[target]=float(value) if counts[target]==1 else values[target]+cfg['alpha']*(value-values[target])
            seen[target]=t;eats=0
            for a in c['actions']:
                actions+=1
                if a['action']=='move':
                    start,end=tuple(a['from']),tuple(a['to'])
                    assert start==position and sum(abs(x-y) for x,y in zip(start,end))==1
                    assert 0<=end[0]<7 and 0<=end[1]<5 and end!=(3,2)
                    position=end
                else:
                    assert a==dict(action='eat',kind=target,reward=value)
                    assert position==({'p':(1,1),'q':(5,1)}[target]);eats+=1;health+=value
            assert eats==1 and position==(3,3) and row['health'][actor]==health
            assert row['after'][actor]['values']==values and row['after'][actor]['counts']==counts
            assert row['after'][actor]['last_seen']==seen
            assert not row['terminated'] and row['truncated']==(t==cfg['rounds']-1)
        assert len(rows)==cfg['rounds']
    for t,row in enumerate(rows):
        for d in row['delivery']:
            c=row['choices'][d['sender']]
            assert d['message']==dict(id=f'{d["sender"]}-{t}',source=d['sender'],tick=t,kind=c['target'],claim=c['reward'])
    return actions


def main(directory):
    cfg=json.loads((directory/'protocol.json').read_text());m=json.loads((directory/'manifest.json').read_text())
    for path,digest in m['source_sha256'].items():assert hashlib.sha256((PROJECT/path).read_bytes()).hexdigest()==digest,path
    assert hashlib.sha256((directory/'protocol.json').read_bytes()).hexdigest()==m['protocol_sha256']
    results=[json.loads(s) for s in (directory/'raw/episodes.jsonl').read_text().splitlines()]
    keys=set();n=0;physical=0
    for r in results:
        seed,scenario,policy=r['seed'],r['scenario'],r['policy'];key=(seed,scenario,policy)
        assert key not in keys;keys.add(key)
        e=Episode(cfg,seed,scenario,policy);rows=[e.step() for _ in range(cfg['rounds'])]
        assert r==summarize(rows,cfg,seed,scenario,policy)
        if seed in cfg['trace_seeds'] and scenario in cfg['trace_cases']:
            name=f'{scenario}--{policy}--{seed}'
            saved=[json.loads(s) for s in (directory/f'raw/{name}.jsonl').read_text().splitlines()]
            assert saved==json.loads(json.dumps(rows))
            assert json.loads((directory/f'raw/{name}.final-state.json').read_text())==json.loads(json.dumps(e.snapshot()))
            physical+=audit(saved,cfg,scenario,seed,policy);n+=1
        for metrics in r['agents'].values():
            assert metrics['initial_unknown']==2
            if policy!='e3_reference':assert metrics['budget_used']==metrics['explorations']<=cfg['total_budget']
    assert keys=={(s,c,p) for s in range(cfg['seed_start'],cfg['seed_start']+cfg['seeds']) for c in cfg['scenarios'] for p in cfg['policies']}
    result=dict(passed=True,episodes_recomputed=len(keys),choices_recomputed=len(keys)*cfg['rounds']*2,traces_independently_audited=n,physical_actions_audited=physical,
                checks=['source/config fingerprints','independent budgets and priority/reservation','personal evidence and delayed request','asynchronous reward schedule/noise','movement and eating','messages','final snapshots','initial unknown count and horizon'])
    (directory/'verification.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('directory',type=Path);main(p.parse_args().directory)
