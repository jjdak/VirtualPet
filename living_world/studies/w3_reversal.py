"""Exploratory follow-up on W2's previously published swap at step 480."""
from w3_influence import OUT, case_row, summarize, write_file
from fork_study import ContextWorld


def main():
    rows = []
    example = None
    for seed in range(32):
        world = ContextWorld(seed)
        while world.tick < 480:
            world.step()
        world.set_mode('sun')
        world.intervene('p', -1, True)
        world.intervene('q', 1, True)
        for age in (480,700):
            while world.tick < age:
                world.step()
            snapshot = world.snapshot()
            for actor in ('A','B'):
                for kind in ('p','q'):
                    row = case_row(snapshot,actor,kind)
                    rows.append(row)
                    if example is None and row['relay']:
                        example = row
                        write_file(OUT/'reversal-example.json',snapshot)
    summary = dict(protocol='Exploratory matched pairs after W2 swap at 480; 32 seeds, 2 fork ages, 4 hints, 240 steps.',
                   all=summarize(rows),by_age={str(age):summarize([r for r in rows if r['age']==age]) for age in (480,700)},
                   first_relay=example, pairs=rows)
    write_file(OUT/'reversal.json',summary)
    print(summary['all'])
    print('First relay:',example)


if __name__ == '__main__':
    main()
