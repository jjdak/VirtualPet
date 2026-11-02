// DOM logic check only: this does not claim browser rendering/screenshot coverage.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const html = fs.readFileSync(process.argv[2], 'utf8');
const script = html.split('<script>')[1].split('</script>')[0];
class Element {
  constructor(tag) { this.tag = tag; this.children = []; this.value = ''; }
  append(...nodes) { this.children.push(...nodes); }
  replaceChildren(...nodes) { this.children = [...nodes]; }
}
const ids = Object.fromEntries(['encoding', 'summary', 'case', 'stage', 'cards', 'play']
  .map(id => [id, new Element(id)]));
let tick;
const context = vm.createContext({
  document: {
    getElementById: id => ids[id],
    querySelector: selector => ids[selector.slice(1)],
    createElement: tag => new Element(tag),
  },
  setInterval: fn => { tick = fn; return 1; }, clearInterval: () => {},
});
vm.runInContext(script, context);
assert.equal(ids.summary.children.length, 3);
assert.equal(ids.case.children.length, 12);
assert.equal(ids.stage.children.length, 8);
const stages = ids.stage.children.map(e => e.value);
let checked = 0;
for (let c = 0; c < 12; c++) {
  for (const stage of stages) {
    ids.case.value = String(c);
    ids.stage.value = stage;
    ids.stage.onchange();
    assert.equal(ids.cards.children.length, 3);
    for (const card of ids.cards.children) {
      const grid = card.children.find(e => e.className === 'grid');
      assert.equal(grid.children.length, 35);
      assert.equal(grid.children.filter(e => e.children.length > 0).length, 1);
    }
    ids.play.onclick();
    for (let step = 0; step < 4; step++) tick();
    const rows = vm.runInContext('Object.values(DATA).map(d => d.rows)', context);
    ids.cards.children.forEach((card, index) => {
      const row = rows[index].find(r => r.case === c && r.stage === stage);
      const event = card.children.find(e => e.className === 'event');
      const health = row.observation['健康'] + (row.health_delta || 0);
      assert.ok(event.textContent.startsWith('健康 ' + health + ' · '));
      checked++;
    });
  }
}
console.log(JSON.stringify({passed:true, replay_cards_checked:checked,
  coverage:'DOM logic with test doubles; not actual browser layout or animation timing'}));
