// Verify support using the full browser run's actual left/right/idle samples.
// Run browser-check.cjs first with COURTYARD_QA_DIR pointing to pose-light/full.
const assert=require('node:assert/strict');const fs=require('node:fs/promises');const path=require('node:path');
const output=path.resolve(process.env.COURTYARD_QA_DIR || '../.runtime/courtyard/pose-light');
(async()=>{
  const input=path.join(output,'full/verification.json');const source=JSON.parse(await fs.readFile(input,'utf8'));
  const samples=[source.left,source.right,source.recovered];
  assert.equal(samples[0].phase,'observe');assert.equal(samples[1].phase,'observe');assert.equal(samples[2].phase,'idle');
  assert(samples[1].character.yaw-samples[0].character.yaw>.25);
  assert(samples.every(s=>s.character.support.error<.002),'Support wrist must stay within 2mm of the authored contact');
  assert(samples.every(s=>s.character.positions.leftIndexDistal[1]>=.99),'Support finger bone must not sink below the stone surface');
  assert.equal(samples[2].ripples,0);assert.deepEqual(source.errors,[]);
  const report={verifiedAt:new Date().toISOString(),browserVerifiedAt:source.verifiedAt,source:input,checks:['support contact during left/right gaze and idle breathing','support finger bone above stone','actual left/right head response','return to idle and ripple cleanup','no runtime or shader errors'],maxSupportError:Math.max(...samples.map(s=>s.character.support.error)),samples};
  await fs.writeFile(path.join(output,'support-verification.json'),JSON.stringify(report,null,2));console.log(JSON.stringify({checks:report.checks,maxSupportError:report.maxSupportError}));
})().catch(e=>{console.error(e);process.exitCode=1});
