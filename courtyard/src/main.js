import * as THREE from 'three';
import './style.css';
import {createEnvironment,WATER_BOUNDS} from './environment.js';
import {createCharacter} from './character.js';
import {Attention} from './attention.js';

const host=document.querySelector('#scene');
const loading=document.querySelector('#loading');
const errorPanel=document.querySelector('#error');
const inspect=new URLSearchParams(location.search).has('inspect');
const reducedQuery=matchMedia('(prefers-reduced-motion: reduce)');
const attention=new Attention();
const history=[];
let renderer,character,environment,paused=false,time=0,last=performance.now(),ripples=[];
let count=0;
const scene=new THREE.Scene();
scene.background=new THREE.Color('#ece8db');
scene.fog=new THREE.Fog('#ece8db',34,62);
const camera=new THREE.OrthographicCamera(-7,7,4.5,-4.5,.1,60);
function courtyardView(){camera.position.set(7.9,7.2,12);camera.lookAt(0,1.6,.3);camera.position.addScaledVector(camera.getWorldDirection(new THREE.Vector3()),-12);camera.zoom=.95;}
courtyardView();

function fail(error){
  console.error(error);loading.classList.add('ready');errorPanel.hidden=false;
  errorPanel.textContent='庭院还没准备好。\n'+(String(error.message).includes('404')?'人物资源缺失，请在 courtyard 目录运行 npm run assets 后刷新。':'请刷新重试；若仍失败，请查看项目运行说明。');
}
function resize(){
  const w=host.clientWidth,h=host.clientHeight,aspect=w/h;
  const vertical=Math.max(4.25,6.45/aspect);
  camera.left=-vertical*aspect;camera.right=vertical*aspect;camera.top=vertical;camera.bottom=-vertical;
  camera.updateProjectionMatrix();renderer?.setSize(w,h);
  if(environment&&character)environment.captureReflection(renderer,camera,character.root);
}
function touch(point){
  if(paused||!character) return false;
  attention.touch({x:point.x,y:.17,z:point.z},time);
  count++;
  document.querySelector('#hint').classList.add('quiet');
  const group=new THREE.Group();group.position.set(point.x,.19,point.z);
  for(let i=0;i<3;i++){
    const material=new THREE.ShaderMaterial({transparent:true,depthWrite:false,side:THREE.DoubleSide,
      uniforms:{strength:{value:.8}},
      vertexShader:'varying vec3 world;void main(){vec4 p=modelMatrix*vec4(position,1.);world=p.xyz;gl_Position=projectionMatrix*viewMatrix*p;}',
      fragmentShader:`varying vec3 world;uniform float strength;void main(){if(world.x<${WATER_BOUNDS.left.toFixed(3)}||world.x>${WATER_BOUNDS.right.toFixed(3)}||world.z<${WATER_BOUNDS.bottom.toFixed(3)}||world.z>${WATER_BOUNDS.top.toFixed(3)})discard;gl_FragColor=vec4(.83,.88,.72,strength);}`
    });
    const ring=new THREE.Mesh(new THREE.RingGeometry(.97,1,80),material);
    ring.rotation.x=-Math.PI/2;group.add(ring);
  }
  scene.add(group);ripples.push({group,born:time});
  if(ripples.length>8) disposeRipple(ripples.shift());
  return true;
}
function disposeRipple(r){scene.remove(r.group);r.group.children.forEach(o=>{o.geometry.dispose();o.material.dispose();});}
const raycaster=new THREE.Raycaster();
function waterPoint(event){
  if(!environment||!character) return null;
  const r=host.getBoundingClientRect();
  raycaster.setFromCamera(new THREE.Vector2((event.clientX-r.left)/r.width*2-1,-(event.clientY-r.top)/r.height*2+1),camera);
  const hits=raycaster.intersectObjects([environment.water,...environment.occluders,character.root],true);
  return hits[0]?.object===environment.water?hits[0].point:null;
}
host.addEventListener('pointerdown',event=>{if(event.button!==0)return;const p=waterPoint(event);if(p)touch(p);});
host.addEventListener('pointermove',event=>{host.style.cursor=waterPoint(event)?'pointer':'default';});
host.addEventListener('keydown',event=>{if(event.key==='Enter'||event.key===' '){event.preventDefault();touch(new THREE.Vector3(.35,.17,2.7));}});
const pauseButton=document.querySelector('#pause');
pauseButton.addEventListener('click',()=>{paused=!paused;pauseButton.textContent=paused?'继续相处':'暂停片刻';pauseButton.setAttribute('aria-pressed',String(paused));pauseButton.setAttribute('aria-label',paused?'继续庭院动画':'暂停庭院动画');});
document.addEventListener('visibilitychange',()=>{last=performance.now();});
window.addEventListener('resize',resize);

try {
  renderer=new THREE.WebGLRenderer({antialias:true,alpha:false,powerPreference:'high-performance',preserveDrawingBuffer:inspect});
  renderer.setPixelRatio(Math.min(devicePixelRatio,1.75));
  renderer.outputColorSpace=THREE.SRGBColorSpace;
  renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.0;
  renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFShadowMap;
  host.append(renderer.domElement);resize();
  scene.add(new THREE.HemisphereLight('#e7efec','#82928c',2.0));
  const sunlight=new THREE.DirectionalLight('#ffe7ba',2.5);
  sunlight.position.set(-3,8,4);sunlight.castShadow=true;sunlight.shadow.mapSize.set(2048,2048);
  Object.assign(sunlight.shadow.camera,{left:-7,right:7,top:7,bottom:-7,near:.5,far:25});
  sunlight.shadow.normalBias=.035;sunlight.shadow.bias=-.00025;sunlight.shadow.radius=3;
  scene.add(sunlight);
  environment=await createEnvironment(scene);
  character=await createCharacter(scene);
  character.update(0,1/60,attention,reducedQuery.matches);
  environment.captureReflection(renderer,camera,character.root);
  loading.classList.add('ready');
  setTimeout(()=>loading.hidden=true,1400);
  renderer.domElement.addEventListener('webglcontextlost',event=>{event.preventDefault();paused=true;fail(new Error('WebGL context lost'));});
  if(inspect){
    window.__courtyard={
      snapshot:()=>({time,phase:attention.phase,target:attention.target,touchCount:count,ripples:ripples.length,paused,history,character:character.snapshot(),drawCalls:renderer.info.render.calls,triangles:renderer.info.render.triangles}),
      project:(x,y,z)=>{const p=new THREE.Vector3(x,y,z).project(camera);return {x:(p.x+1)*host.clientWidth/2,y:(1-p.y)*host.clientHeight/2};},
      override:value=>character.setOverride(value),
      closeup:enabled=>{if(enabled){camera.position.set(.8,2.75,4.8);camera.lookAt(-1.45,1.55,.12);camera.zoom=2.6;}else{courtyardView();}camera.updateProjectionMatrix();environment.captureReflection(renderer,camera,character.root);},
      canvas:renderer.domElement,
    };
    const panel=document.createElement('details');panel.id='inspection';
    panel.innerHTML='<summary>制作检查</summary><button id="closeup">人物近看</button> <button id="wide">庭院全景</button> <button id="blinkOpen">睁眼</button> <button id="blinkClosed">闭眼</button> <button id="natural">自然动作</button> <button id="record">录制十二秒</button><a id="recording" hidden download="courtyard-c2.webm">保存录屏</a><pre id="inspection-state"></pre>';
    document.querySelector('#app').append(panel);
    document.querySelector('#closeup').onclick=()=>window.__courtyard.closeup(true);
    document.querySelector('#wide').onclick=()=>window.__courtyard.closeup(false);
    document.querySelector('#blinkOpen').onclick=()=>character.setOverride({blink:0});
    document.querySelector('#blinkClosed').onclick=()=>character.setOverride({blink:1});
    document.querySelector('#natural').onclick=()=>character.setOverride(null);
    document.querySelector('#record').onclick=()=>{
      const button=document.querySelector('#record');button.disabled=true;button.textContent='正在录制';
      const stream=renderer.domElement.captureStream(30);
      const recorder=new MediaRecorder(stream,{mimeType:'video/webm'}),chunks=[];
      recorder.ondataavailable=e=>chunks.push(e.data);
      recorder.onstop=()=>{
        stream.getTracks().forEach(t=>t.stop());
        const reader=new FileReader();reader.onload=()=>{const link=document.querySelector('#recording');link.href=reader.result;link.hidden=false;button.textContent='录制十二秒';button.disabled=false;};
        reader.readAsDataURL(new Blob(chunks,{type:'video/webm'}));
      };
      recorder.start();setTimeout(()=>recorder.stop(),12000);
    };
    setInterval(()=>{document.querySelector('#inspection-state').textContent=JSON.stringify(window.__courtyard.snapshot(),null,2);},250);
  }
  function frame(now){
    requestAnimationFrame(frame);
    const dt=Math.min((now-last)/1000,.05);last=now;
    if(!paused&&!document.hidden){
      time+=dt;
      const previous=attention.phase;attention.update(time);
      if(inspect&&attention.phase!==previous){history.push({time,from:previous,to:attention.phase});if(history.length>12)history.shift();}
      character.update(time,dt,attention,reducedQuery.matches);
      environment.update(time,reducedQuery.matches);
      ripples=ripples.filter(r=>{
        const age=time-r.born;
        if(age>3.5){disposeRipple(r);return false;}
        r.group.children.forEach((o,i)=>{
          const a=age-i*.22;
          o.visible=a>=0;
          o.scale.setScalar(Math.max(.005,a*.38+.05));
          o.material.uniforms.strength.value=Math.max(0,(1-a/3)*.8);
        });return true;
      });
    }
    renderer.render(scene,camera);
  }
  last=performance.now();requestAnimationFrame(frame);
}catch(error){fail(error);}
