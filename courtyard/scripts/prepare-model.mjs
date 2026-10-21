import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const source = 'https://raw.githubusercontent.com/pixiv/three-vrm/v3.5.3/packages/three-vrm/examples/models/VRM1_Constraint_Twist_Sample.vrm';
const sha = '12c2b97e95e700783a6a550dc0eee2d7880aeedccef9ae67bc4c5a2f0f2631a2';
const privateFile = new URL('../../PrivateAssets/Courtyard/sample.vrm', import.meta.url);
let bytes;
try { bytes = await readFile(privateFile); }
catch (error) {
  if (error.code !== 'ENOENT') throw error;
  const response = await fetch(source);
  if (!response.ok) throw new Error(`Model download failed: ${response.status}`);
  bytes = Buffer.from(await response.arrayBuffer());
}
if (createHash('sha256').update(bytes).digest('hex') !== sha) throw new Error('Model checksum mismatch');
const gltf = JSON.parse(bytes.subarray(20, 20 + bytes.readUInt32LE(12)));
const vrm = gltf.extensions.VRMC_vrm;
for (const name of ['hips','head','neck','leftEye','rightEye','leftUpperLeg','rightUpperLeg']) {
  if (!vrm.humanoid.humanBones[name]) throw new Error(`Missing bone: ${name}`);
}
if (!vrm.expressions.preset.blink.morphTargetBinds?.length) throw new Error('Blink has no morph binding');
const dir = new URL('../public/models/', import.meta.url);
await mkdir(dir, {recursive: true});
await writeFile(new URL('character.vrm', dir), bytes);
await writeFile(new URL('metadata.json', dir), JSON.stringify({source, sha256: sha, meta: vrm.meta}, null, 2));
console.log('Verified and staged sample VRM, eye bones and blink binding. Runtime motion still requires browser verification.');
