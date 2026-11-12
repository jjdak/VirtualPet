import argparse
import json
from pathlib import Path
import random
import statistics as st


def interval(values,cfg):
    rng=random.Random(cfg['bootstrap_seed']);samples=sorted(st.mean(rng.choices(values,k=len(values))) for _ in range(cfg['bootstrap_samples']))
    return dict(mean_difference=st.mean(values),bootstrap_95=[samples[int(len(samples)*.025)-1],samples[int(len(samples)*.975)-1]],
                positive=sum(v>1e-12 for v in values),tied=sum(abs(v)<=1e-12 for v in values),negative=sum(v< -1e-12 for v in values))


def build(directory):
    cfg=json.loads((directory/'protocol.json').read_text())
    results=[json.loads(s) for s in (directory/'raw/episodes.jsonl').read_text().splitlines()]
    aggregate,paired,traces={},{},{}
    seeds=range(cfg['seed_start'],cfg['seed_start']+cfg['seeds'])
    for case in cfg['scenarios']:
        subset={(r['seed'],r['policy']):r['agents'] for r in results if r['scenario']==case}
        aggregate[case]={};paired[case]={}
        for p in cfg['policies']:
            aggregate[case][p]={}
            for a in ('A','B'):
                ms=[subset[s,p][a] for s in seeds]
                stats={k:(st.mean(m[k] for m in ms) if ms[0][k] is not None else None) for k in ms[0] if k!='events'}
                stats['events']=[]
                for i,ev in enumerate(ms[0]['events']):
                    es=[m['events'][i] for m in ms];rec=[e['recovery'] for e in es if e['recovery'] is not None];dis=[e['discovery_delay'] for e in es if e['discovery_delay'] is not None]
                    stats['events'].append(dict(change_at=ev['change_at'],segment_end=ev['segment_end'],optimal_next20=st.mean(e['optimal_next20'] for e in es),regret_next20=st.mean(e['regret_next20'] for e in es),median_recovery=st.median(rec) if rec else None,not_recovered=len(es)-len(rec),median_discovery=st.median(dis) if dis else None,not_discovered=len(es)-len(dis)))
                aggregate[case][p][a]=stats
            if case in cfg['trace_cases']:
                name=f'{case}--{p}--{cfg["trace_seeds"][0]}'
                traces[f'{case}/{p}']=[json.loads(s) for s in (directory/f'raw/{name}.jsonl').read_text().splitlines()]
        for p in cfg['policies']:
            if p=='adaptive':continue
            paired[case][p]=interval([subset[s,'adaptive']['B']['regret']-subset[s,p]['B']['regret'] for s in seeds],cfg)
    overall={p:{k:st.mean(aggregate[c][p]['B'][k] for c in cfg['scenarios']) for k in ('regret','explorations','exploration_regret','periodic_actions','trigger_actions','mean_interval','final_interval','shortenings','lengthenings','useful_probes')} for p in cfg['policies']}
    groups={g:{p:{k:st.mean(aggregate[c][p]['B'][k] for c in cfg[g+'_cases']) for k in overall[p]} for p in cfg['policies']} for g in ('regression','heldout')}
    summary=dict(group_means_B=groups,aggregate=aggregate,paired_adaptive_minus_comparator_B_regret=paired,overall_equal_case_weight_B=overall,
                 note='Lower regret is better. Marginal paired bootstrap by seed, no multiplicity correction. All four policies share E4 hybrid budget; regression and heldout timing groups reported separately.')
    (directory/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    payload=json.dumps(dict(config=cfg,summary=summary,traces=traces),ensure_ascii=False).replace('<','\\u003c')
    (directory/'replay.html').write_text(Path(__file__).with_name('replay.html').read_text().replace('__PAYLOAD__',payload))
    for case in cfg['scenarios']:
        print(case,{p:[round(aggregate[case][p]['B']['regret'],3),round(aggregate[case][p]['B']['explorations'],2)] for p in cfg['policies']})
    print('EQUAL-CASE MEANS',json.dumps(overall))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('directory',type=Path);build(p.parse_args().directory)
