import * as THREE from 'three';

// Two-bone positional solve with a fixed elbow side, scoped to this seated pose.
// Clamping unreachable targets keeps the chain finite without stretching bones.
export function solveArm(upper,lower,hand,target,pole) {
  upper.updateWorldMatrix(true,true);
  const a=upper.getWorldPosition(new THREE.Vector3());
  const b=lower.getWorldPosition(new THREE.Vector3());
  const c=hand.getWorldPosition(new THREE.Vector3());
  const lengthA=a.distanceTo(b),lengthB=b.distanceTo(c);
  const direction=target.clone().sub(a);
  const distance=THREE.MathUtils.clamp(direction.length(),Math.abs(lengthA-lengthB)+1e-5,lengthA+lengthB-1e-5);
  direction.normalize();
  const side=pole.clone().sub(a).addScaledVector(direction,-pole.clone().sub(a).dot(direction));
  if(side.lengthSq()<1e-8){side.set(0,Math.abs(direction.y)<.9?1:0,Math.abs(direction.y)<.9?0:1);side.addScaledVector(direction,-side.dot(direction));}
  side.normalize();
  const along=(lengthA*lengthA+distance*distance-lengthB*lengthB)/(2*distance);
  const height=Math.sqrt(Math.max(0,lengthA*lengthA-along*along));
  const elbow=a.clone().addScaledVector(direction,along).addScaledVector(side,height);
  const end=a.clone().addScaledVector(direction,distance);
  function aim(joint,child,point){
    joint.updateWorldMatrix(true,true);
    const origin=joint.getWorldPosition(new THREE.Vector3());
    const from=child.getWorldPosition(new THREE.Vector3()).sub(origin).normalize();
    const to=point.clone().sub(origin).normalize();
    const delta=new THREE.Quaternion().setFromUnitVectors(from,to);
    const parent=joint.parent.getWorldQuaternion(new THREE.Quaternion());
    const local=parent.clone().invert().multiply(delta).multiply(parent);
    joint.quaternion.premultiply(local).normalize();joint.updateWorldMatrix(false,true);
  }
  aim(upper,lower,elbow);aim(lower,hand,end);
}

export function orientPalm(hand,fingerDirection,side='left'){
  const x=fingerDirection.clone().normalize().multiplyScalar(side==='left'?1:-1);
  const z=new THREE.Vector3().crossVectors(x,new THREE.Vector3(0,1,0)).normalize();
  const y=new THREE.Vector3().crossVectors(z,x).normalize();
  const world=new THREE.Quaternion().setFromRotationMatrix(new THREE.Matrix4().makeBasis(x,y,z));
  hand.quaternion.copy(hand.parent.getWorldQuaternion(new THREE.Quaternion()).invert().multiply(world));
}
