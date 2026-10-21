import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Attention} from './attention.js';

test('water responds before attention; attention eventually returns to idle', () => {
  const a = new Attention();
  a.touch({x:1,z:2}, 0);
  assert.equal(a.update(.2),'notice');
  assert.equal(a.update(.33),'observe');
  assert.equal(a.update(3.2),'return');
  assert.equal(a.update(5),'idle');
});
test('rapid inputs cannot indefinitely postpone noticing and use the latest location', () => {
  const a = new Attention();
  for (let i=0;i<20;i++) { a.touch({x:i,z:2},i*.02); a.update(i*.02); }
  assert.equal(a.phase,'observe');
  assert.equal(a.target.x,19);
  assert.equal(a.update(6),'idle');
});
test('a new touch interrupts recovery with a fresh notice interval', () => {
  const a = new Attention();
  a.touch({x:-1,z:1},0); a.update(1); a.update(3.2);
  a.touch({x:1,z:2},3.3);
  assert.equal(a.update(3.4),'notice');
  assert.equal(a.update(3.7),'observe');
});
