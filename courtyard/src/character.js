import * as THREE from 'three';
import {GLTFLoader} from 'three/addons/loaders/GLTFLoader.js';
import {VRMLoaderPlugin} from '@pixiv/three-vrm';
import {solveArm,orientPalm} from './seated-support.js';

export async function createCharacter(scene) {
  const loader = new GLTFLoader();
  loader.register(parser => new VRMLoaderPlugin(parser));
  const gltf = await loader.loadAsync('/models/character.vrm');
  const vrm = gltf.userData.vrm;
  if (!vrm) throw new Error('人物没有可读取的 VRM 骨骼。');
  const root = vrm.scene;
  scene.add(root);
  root.scale.setScalar(1.5);
  root.position.set(-1.45, 0, -.055);
  const bone = name => vrm.humanoid.getNormalizedBoneNode(name);
  for (const name of ['head','neck','leftEye','rightEye','hips','leftUpperLeg','rightUpperLeg','leftUpperArm','leftLowerArm','leftHand','rightUpperArm','rightLowerArm','rightHand']) {
    if (!bone(name)) throw new Error(`人物缺少可动骨骼：${name}`);
  }
  if (!vrm.expressionManager.getExpression('blink')) throw new Error('人物缺少眨眼表情。');
  const set = (name,x=0,y=0,z=0) => { const b=bone(name); if(b) b.rotation.set(x,y,z); };
  // Bend hips and knees into a seated pose; arms fall alongside the lap.
  set('leftUpperLeg',-1.47,-.035,-.085); set('rightUpperLeg',-1.40,.035,.035);
  set('leftLowerLeg',1.58); set('rightLowerLeg',1.40);
  set('leftFoot',-.03,0,-.03); set('rightFoot',-.08,0,.04);
  set('spine',.02,0,-.045);set('chest',.055,0,-.025);set('leftShoulder',0,0,-.25);
  set('leftUpperArm',-.10,0,-1.33); set('rightUpperArm',-.10,0,1.33);
  set('leftLowerArm',0,-.75,-.06); set('rightLowerArm',0,.75,.06);
  set('leftHand',.12,0,.05); set('rightHand',.12,0,-.05);
  for (const side of ['left','right']) {
    for (const finger of ['Index','Middle','Ring','Little']) {
      for (const joint of ['Proximal','Intermediate','Distal']) set(`${side}${finger}${joint}`,0,0,side==='left'?-.025:.12);
    }
  }
  vrm.update(0); root.updateMatrixWorld(true);
  const hip = bone('hips').getWorldPosition(new THREE.Vector3());
  root.position.y += 1.13 - hip.y;
  const supportTarget=new THREE.Vector3(-1.16,1.012,-.11);
  const lapTarget=new THREE.Vector3(-1.50,1.22,.33);
  function supportArms(){
    solveArm(bone('leftUpperArm'),bone('leftLowerArm'),bone('leftHand'),supportTarget,new THREE.Vector3(-.90,1.40,-.24));
    orientPalm(bone('leftHand'),new THREE.Vector3(.30,0,1),'left');
    solveArm(bone('rightUpperArm'),bone('rightLowerArm'),bone('rightHand'),lapTarget,new THREE.Vector3(-1.95,1.42,.05));
    orientPalm(bone('rightHand'),new THREE.Vector3(.10,-.15,1),'right');
  }
  supportArms();vrm.update(0);
  // The loaded spring tails still refer to the standing model's world position.
  // Reset after placement so the first visible frame does not whip the hair.
  root.updateMatrixWorld(true);
  vrm.springBoneManager?.reset();
  const adjustedMaterials=new Set();
  root.traverse(obj => {
    if(!obj.isMesh) return;
    obj.castShadow = true; obj.receiveShadow = true; obj.frustumCulled = false;
    const materials = Array.isArray(obj.material)?obj.material:[obj.material];
    for(const m of materials) {
      if(adjustedMaterials.has(m))continue;adjustedMaterials.add(m);
      if(m.isMToonMaterial){m.giEqualizationFactor=.2;m.shadingToonyFactor=.2;m.shadingShiftFactor=-.08;m.matcapFactor?.setRGB(0,0,0);}
      if(m.name.includes('SKIN')) {m.color?.set('#c2afa0');m.shadeColorFactor?.set('#8e9690');}

      if(m.name.includes('Tops') || m.name.includes('Bottoms')) {
        m.color?.set('#657f8d');
        m.shadeColorFactor?.set('#536975');
      }
      if(m.name.includes('Hair')) { m.color?.set('#70695f'); m.shadeColorFactor?.set('#56635b'); }
    }
  });
  const eyeTarget = new THREE.Object3D(); scene.add(eyeTarget);
  vrm.lookAt.target = eyeTarget;
  const restTarget = new THREE.Vector3(-.2,.4,3.8);
  eyeTarget.position.copy(restTarget);
  const desired = new THREE.Vector3(), headPosition = new THREE.Vector3();
  let nextBlink=2.6, blinkStart=-10, yaw=.1, pitch=.18;
  const head=bone('head'), neck=bone('neck'), chest=bone('chest');
  let override = null;
  function update(time,dt,attention,reduced=false) {
    const looking = attention.phase === 'observe';
    desired.copy(looking ? attention.target : restTarget);
    const speed=looking?5:1.8;
    eyeTarget.position.lerp(desired,1-Math.exp(-speed*dt));
    root.updateMatrixWorld(true);
    head.getWorldPosition(headPosition);
    const diff=eyeTarget.position.clone().sub(headPosition);
    const targetYaw=THREE.MathUtils.clamp(Math.atan2(diff.x,diff.z),-.72,.72);
    const targetPitch=THREE.MathUtils.clamp(Math.atan2(-diff.y,Math.hypot(diff.x,diff.z)),.04,.5);
    yaw=THREE.MathUtils.damp(yaw,targetYaw,looking?2.3:1.5,dt);
    pitch=THREE.MathUtils.damp(pitch,targetPitch,looking?2.0:1.4,dt);
    head.rotation.set(pitch*.72,yaw*.76,reduced?0:Math.sin(time*.29)*.012);
    neck.rotation.set(pitch*.28,yaw*.24,0);
    if(chest) chest.rotation.x = .055 + (reduced?0:Math.sin(time*1.25)*.006);
    supportArms();
    if(time>=nextBlink){blinkStart=time;nextBlink=time+3.2+Math.random()*3.5;}
    const phase=(time-blinkStart)/.22;
    const blink=phase>=0&&phase<=1?Math.sin(Math.PI*phase):0;
    vrm.expressionManager.setValue('blink',override?.blink ?? (reduced?0:blink));
    vrm.expressionManager.setValue('relaxed',.045);
    if(override?.yaw!==undefined){head.rotation.y=override.yaw;neck.rotation.y=0;}
    if(override?.pitch!==undefined){head.rotation.x=override.pitch;neck.rotation.x=0;}
    vrm.update(dt);
  }
  function snapshot(){
    const positions={};
    for(const n of ['leftIndexProximal','leftIndexDistal','leftMiddleProximal','leftMiddleDistal','hips','head','leftUpperArm','leftLowerArm','rightUpperArm','rightLowerArm','leftHand','rightHand','leftUpperLeg','leftLowerLeg','rightUpperLeg','rightLowerLeg','leftFoot','rightFoot']) positions[n]=bone(n).getWorldPosition(new THREE.Vector3()).toArray();
    const morphs=[];
    root.traverse(o=>{if(o.isMesh&&o.morphTargetInfluences) morphs.push({name:o.name,active:o.morphTargetInfluences.map((v,i)=>[i,v]).filter(a=>a[1]>.001)});});
    return {support:{target:supportTarget.toArray(),error:bone('leftHand').getWorldPosition(new THREE.Vector3()).distanceTo(supportTarget)},yaw:head.rotation.y,pitch:head.rotation.x,blink:vrm.expressionManager.getValue('blink'),eyeTarget:eyeTarget.position.toArray(),eyeRotation:vrm.humanoid.getRawBoneNode('leftEye').quaternion.toArray(),positions,morphs};
  }
  return {root,vrm,update,snapshot,setOverride(value){override=value;}};
}
