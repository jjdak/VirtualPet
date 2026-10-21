import test from 'node:test';
import assert from 'node:assert/strict';
import * as THREE from 'three';
import {solveArm} from './seated-support.js';
function chain(){
  const root=new THREE.Group();root.position.set(-1.45,.7,-.05);root.rotation.set(.07,.15,-.045);root.scale.setScalar(1.5);
  const upper=new THREE.Bone(),lower=new THREE.Bone(),hand=new THREE.Bone();root.add(upper);upper.add(lower);lower.add(hand);
  upper.position.set(0,.6,0);lower.position.x=.22;hand.position.x=.21;root.updateMatrixWorld(true);
  return {root,upper,lower,hand};
}
test('support solver reaches a contact under rotated/scaled parents and preserves bone lengths',()=>{
  const {upper,lower,hand}=chain();const a=upper.getWorldPosition(new THREE.Vector3());
  const target=a.clone().add(new THREE.Vector3(.12,-.52,.05)),pole=a.clone().add(new THREE.Vector3(.3,-.2,-.2));
  for(let i=0;i<30;i++){
    solveArm(upper,lower,hand,target,pole);
    assert(hand.getWorldPosition(new THREE.Vector3()).distanceTo(target)<1e-6);
    assert(Math.abs(upper.getWorldPosition(new THREE.Vector3()).distanceTo(lower.getWorldPosition(new THREE.Vector3()))-.33)<1e-6);
    assert(Math.abs(lower.getWorldPosition(new THREE.Vector3()).distanceTo(hand.getWorldPosition(new THREE.Vector3()))-.315)<1e-6);
  }
});
test('unreachable and collinear targets stay finite and within reach',()=>{
  const {upper,hand}=chain();const lower=hand.parent,a=upper.getWorldPosition(new THREE.Vector3());
  const target=a.clone().add(new THREE.Vector3(0,0,10));solveArm(upper,lower,hand,target,target);
  const end=hand.getWorldPosition(new THREE.Vector3());assert(end.toArray().every(Number.isFinite));
  assert(end.distanceTo(a)<=.645+1e-6);assert(end.z>a.z);
});
