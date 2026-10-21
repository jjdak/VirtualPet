// Fixed attention timing, not learning. The first notice deadline is preserved
// during rapid input; repeated clicks replace the target without starving a response.
export class Attention {
  constructor() { this.phase = 'idle'; this.target = null; this.readyAt = 0; this.releaseAt = 0; }
  touch(point, now) {
    this.target = {...point};
    if (this.phase === 'idle' || this.phase === 'return') {
      this.phase = 'notice';
      this.readyAt = now + 0.32;
    }
    this.releaseAt = now + 3.1;
  }
  update(now) {
    if (this.phase === 'notice' && now >= this.readyAt) this.phase = 'observe';
    if (this.phase === 'observe' && now >= this.releaseAt) this.phase = 'return';
    if (this.phase === 'return' && now >= this.releaseAt + 1.8) this.phase = 'idle';
    return this.phase;
  }
}
