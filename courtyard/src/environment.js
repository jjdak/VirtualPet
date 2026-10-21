import * as THREE from 'three';
import {RoundedBoxGeometry} from 'three/addons/geometries/RoundedBoxGeometry.js';
import {createSurfaces} from './surfaces.js';

export const WATER_BOUNDS={left:-4.1,right:4.1,bottom:.275,top:4.025};

export async function createEnvironment(scene) {
  let seed=481;
  const random=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296;};
  const surfaces=createSurfaces(random),occluders=[];
  const masonry=await new THREE.TextureLoader().loadAsync('/textures/stone_wall_05_diff_1k.jpg');
  masonry.colorSpace=THREE.SRGBColorSpace;masonry.wrapS=masonry.wrapT=THREE.RepeatWrapping;masonry.repeat.set(3,.35);masonry.anisotropy=4;
  const stone=new THREE.MeshStandardMaterial({color:'#e6e2d1',map:surfaces.stone,bumpMap:surfaces.stone,bumpScale:.015,roughness:.97});
  const wall=new THREE.MeshStandardMaterial({color:'#fff8e6',map:surfaces.plaster,bumpMap:surfaces.plaster,bumpScale:.012,roughness:1});
  const foundation=new THREE.MeshStandardMaterial({color:new THREE.Color().setRGB(2.1,2.2,1.9),map:masonry,roughness:1});
  const bark=new THREE.MeshStandardMaterial({color:'#716f5d',map:surfaces.stone,bumpMap:surfaces.stone,bumpScale:.06,roughness:1});
  const leaves=new THREE.MeshStandardMaterial({map:surfaces.leaf,alphaTest:.4,side:THREE.DoubleSide,roughness:1});
  function mesh(geometry,material,x,y,z,parent=scene){
    const o=new THREE.Mesh(geometry,material);o.position.set(x,y,z);o.castShadow=true;o.receiveShadow=true;parent.add(o);return o;
  }
  function block(w,h,d,x,y,z,material=stone,round=0){
    const g=round?new RoundedBoxGeometry(w,h,d,2,round):new THREE.BoxGeometry(w,h,d);
    const o=mesh(g,material,x,y,z);occluders.push(o);return o;
  }
  // Restore the original compact courtyard footprint, using the refined surfaces.
  block(9.5,.32,8.2,0,-.2,.5,stone,.045);
  block(8.8,.16,5.45,0,-.005,1.47,foundation);
  block(9,.84,2.75,0,.42,-2.15,foundation);
  block(9,.59,.72,0,.295,-.43,foundation);
  block(3.35,.35,1.18,-1.6,.825,-.47,stone,.035);
  for(let row=0;row<3;row++) {
    let x=-4.4;
    while(x<4.39) {
      const w=Math.min(.75+random()*.65,4.4-x);
      if(w<.04)break;
      const m=stone.clone();m.color.offsetHSL(0,0,(random()-.5)*.065);
      block(w-.025,.065,.74,x+w/2,.865,-3.18+row*.77,m,.025);
      x+=w;
    }
  }
  for(let x=-4.4;x<4.39;){
    const w=Math.min(.75+random()*.45,4.4-x);
    if(w<.04)break;
    block(w-.025,.08,.7,x+w/2,.63,0,stone,.025);x+=w;
  }
  for(let z=.7;z<4.3;z+=.7){
    block(.42,.28,.68,-4.32,.22,z,stone,.025);
    block(.42,.28,.68,4.32,.22,z,stone,.025);
  }
  for(let x=-4.1;x<4.4;x+=.7)block(.68,.28,.4,x,.22,4.24,stone,.025);
  block(9.25,2.25,.24,0,1.94,-3.55,wall);
  block(.25,2.1,4.4,-4.55,1.77,-1.45,wall);
  block(9.4,.12,.38,0,3.1,-3.55,stone,.018);
  const damp=new THREE.MeshStandardMaterial({color:'#626f61',map:surfaces.plaster,roughness:1});
  block(.60,.70,.035,2.5,1.99,-3.417,damp,.01);
  block(.72,.04,.34,2.5,1.6,-3.37,stone,.01);
  let branchParent=scene;

  function branch(a,b,r1,r2){
    const v=new THREE.Vector3().subVectors(b,a);
    const geometry=new THREE.CylinderGeometry(r2,r1,v.length(),9,5);
    const positions=geometry.attributes.position;
    for(let i=0;i<positions.count;i++) {
      const t=positions.getY(i)/v.length()+.5,bend=Math.sin(t*Math.PI);
      positions.setX(i,positions.getX(i)+bend*v.length()*.045);
      positions.setZ(i,positions.getZ(i)+bend*v.length()*.025);
    }
    geometry.computeVertexNormals();
    const o=mesh(geometry,bark,...a.clone().add(b).multiplyScalar(.5).toArray(),branchParent);
    o.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),v.normalize());return o;
  }
  const V=(x,y,z)=>new THREE.Vector3(x,y,z);
  const foliageMatrices=[];
  const dummy=new THREE.Object3D();
  function leafAt(p,size=.16){
    dummy.position.copy(p);dummy.rotation.set(-.6+random()*1.8,random()*Math.PI,random()*Math.PI);
    dummy.scale.set(size*.86,size,1);dummy.updateMatrix();foliageMatrices.push(dummy.matrix.clone());
  }
  // Branches remain visible between thin leaves instead of a solid polygon crown.
  function twig(a,b,r,depth){
    branch(a,b,r,r*.5);
    if(depth>0){
      const direction=b.clone().sub(a);
      for(let i=0;i<3;i++){
        const c=b.clone().add(direction.clone().multiplyScalar(.35+random()*.35)).add(V((random()-.5)*1.2,.1+random()*.35,(random()-.5)*1.1));
        twig(b,c,r*.46,depth-1);
      }
    }else{
      for(let i=0;i<16;i++){
        const p=a.clone().lerp(b,random()).add(V((random()-.5)*.45,(random()-.5)*.3,(random()-.5)*.45));
        leafAt(p,.16+random()*.18);
      }
    }
  }
  const tree=new THREE.Group();scene.add(tree);branchParent=tree;
  tree.scale.setScalar(.8);tree.position.set(.06,.18,-.58);
  branch(V(-4.2,.9,-1.9),V(-4.05,2.6,-2),.22,.14);
  twig(V(-4.05,2.1,-2),V(-5.1,3.6,-2.2),.13,2);
  twig(V(-4.05,2.6,-2),V(-2.6,3.9,-2.2),.12,3);
  twig(V(-4.05,2.6,-2),V(-3.3,4.25,-.65),.09,2);
  twig(V(-4.05,2.6,-2),V(-2.75,2.9,-1.8),.065,1);
  twig(V(-4.05,2.45,-2),V(-4.9,2.9,-.7),.055,1);
  const foliage=new THREE.InstancedMesh(new THREE.PlaneGeometry(1,1),leaves,foliageMatrices.length);
  foliageMatrices.forEach((m,i)=>{foliage.setMatrixAt(i,m);foliage.setColorAt(i,new THREE.Color().setHSL(.20+random()*.07,.16,.65+random()*.28));});
  foliage.castShadow=true;foliage.receiveShadow=true;tree.add(foliage);branchParent=scene;
  // Keep the refined crown within the original overview silhouette.
  tree.updateMatrixWorld(true);
  const crownTop=new THREE.Box3().setFromObject(tree).max.y;
  if(crownTop>4.25){
    tree.scale.y*=(4.25-.9)/(crownTop-.9);
    tree.position.y=.9-.9*tree.scale.y;
  }
  // Fine undergrowth, creeping wall leaves, and sparse plants in stone seams.
  const groundMatrices=[];
  for(let i=0;i<420;i++){
    let x,z,y;
    if(i<180){x=-3.3+(random()-.5)*1.7;z=-2.1+(random()-.5)*1.7;y=.96;}
    else if(i<320){x=-4+random()*8;z=-3.3+random()*.3;y=.95;}
    else{x=-4+random()*8;z=-.80+random()*.09;y=.98;}
    dummy.position.set(x,y+random()*.07,z);dummy.rotation.set(-Math.PI/2+random()*.9,random()*6.28,random()*6.28);
    const size=.07+random()*.13;dummy.scale.set(size*.6,size,1);dummy.updateMatrix();groundMatrices.push(dummy.matrix.clone());
  }
  const undergrowth=new THREE.InstancedMesh(new THREE.PlaneGeometry(1,1),leaves,groundMatrices.length);
  groundMatrices.forEach((m,i)=>undergrowth.setMatrixAt(i,m));undergrowth.castShadow=true;scene.add(undergrowth);
  for(let i=0;i<12;i++){
    const o=mesh(new THREE.IcosahedronGeometry(.13+random()*.15,1),stone,-3.3+(random()-.5)*1.4,.95,-2.1+(random()-.5)*1.1);
    o.scale.set(1,.55,.8);
  }
  // Soft contact shading is authored for this seated position.
  const contact=mesh(new THREE.PlaneGeometry(.95,.6),new THREE.MeshBasicMaterial({map:surfaces.shade,transparent:true,depthWrite:false}),-1.45,1.002,-.30);
  contact.rotation.x=-Math.PI/2;contact.castShadow=false;
  const palmContact=mesh(new THREE.PlaneGeometry(.21,.25),new THREE.MeshBasicMaterial({map:surfaces.shade,transparent:true,depthWrite:false,opacity:.8}),-1.13,1.002,-.04);
  palmContact.rotation.x=-Math.PI/2;palmContact.castShadow=false;
  branch(V(.6,.9,-2.65),V(.6,2.9,-2.65),.04,.03);
  branch(V(.6,2.9,-2.65),V(1.25,2.9,-2.65),.036,.036);
  branch(V(1.15,2.9,-2.65),V(1.15,2.61,-2.65),.003,.003);
  const bellMaterial=new THREE.MeshStandardMaterial({color:'#6c8073',roughness:.7,metalness:.4});
  mesh(new THREE.SphereGeometry(.12,20,12,0,Math.PI*2,0,Math.PI/2),bellMaterial,1.15,2.5,-2.65);
  const tag=mesh(new THREE.PlaneGeometry(.055,.35),stone,1.15,2.31,-2.65);tag.rotation.y=.3;

  // Shallow-water depth, broken caustics and a static environment reflection.
  // Reflection is captured once; this fixed-light slice has no dynamic reflected actor.
  const waterUniforms={time:{value:0},reflection:{value:null},reflectionMatrix:{value:new THREE.Matrix4()},hasReflection:{value:0}};
  const waterMaterial=new THREE.ShaderMaterial({uniforms:waterUniforms,side:THREE.DoubleSide,
    vertexShader:`varying vec3 world;varying vec4 reflected;uniform mat4 reflectionMatrix;
      void main(){vec4 p=modelMatrix*vec4(position,1.);world=p.xyz;reflected=reflectionMatrix*p;gl_Position=projectionMatrix*viewMatrix*p;}`,
    fragmentShader:`varying vec3 world;varying vec4 reflected;uniform float time;uniform sampler2D reflection;uniform float hasReflection;
      float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
      float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
      void main(){
        vec2 q=world.xz;float t=time*.13;
        float n=noise(q*1.8)+noise(q*5.)*.25;
        float depth=smoothstep(.3,5.2,q.y);
        vec3 col=mix(vec3(.21,.31,.25),vec3(.075,.18,.17),depth);
        col+=(n-.5)*.055;
        vec2 p=q*5.+vec2(sin(q.y*3.+t),cos(q.x*2.-t))*.4;
        float c=abs(sin(p.x+sin(p.y*1.1+t))*sin(p.y+sin(p.x*.9-t)));
        float caustic=pow(1.-c,20.);
        float sunPatch=1.-smoothstep(.6,4.8,length((q-vec2(.15,2.0))*vec2(.65,.85)));
        col+=vec3(.32,.32,.18)*caustic*.12*sunPatch;
        col+=vec3(.085,.075,.035)*sunPatch;
        vec2 uv=reflected.xy/reflected.w;
        uv+=vec2(sin(q.y*12.+t*2.),sin(q.x*11.-t))* .0018;
        vec3 reflectedColor=texture2D(reflection,clamp(uv,0.,1.)).rgb;
        col=mix(col,reflectedColor,hasReflection*(.13+depth*.16));
        float bank=1.-smoothstep(.275,.48,q.y);col*=1.-bank*.3;
        gl_FragColor=vec4(col,1.);
        #include <tonemapping_fragment>
        #include <colorspace_fragment>
      }`
  });
  const water=mesh(new THREE.PlaneGeometry(WATER_BOUNDS.right-WATER_BOUNDS.left,WATER_BOUNDS.top-WATER_BOUNDS.bottom),waterMaterial,(WATER_BOUNDS.left+WATER_BOUNDS.right)/2,.17,(WATER_BOUNDS.bottom+WATER_BOUNDS.top)/2);
  water.rotation.x=-Math.PI/2;water.castShadow=false;
  // Submerged stones stop before the walking ledge and remain understated.
  for(let i=0;i<65;i++){
    const m=new THREE.MeshStandardMaterial({color:new THREE.Color().setHSL(.16,.12,.32+random()*.12),roughness:1});
    const o=mesh(new THREE.IcosahedronGeometry(.04+random()*.1,1),m,-3.8+random()*7.6,.145,.42+random()*.22);o.scale.set(1.8,.25,1);o.castShadow=false;
  }
  const dustGeometry=new THREE.BufferGeometry();
  const dustPositions=new Float32Array(24*3);
  for(let i=0;i<24;i++)dustPositions.set([-5+random()*9,1+random()*3,-2+random()*5],i*3);
  dustGeometry.setAttribute('position',new THREE.BufferAttribute(dustPositions,3));
  const dust=new THREE.Points(dustGeometry,new THREE.PointsMaterial({color:'#ead7ac',size:.014,transparent:true,opacity:.35,depthWrite:false}));scene.add(dust);
  const reflectionTarget=new THREE.WebGLRenderTarget(768,512,{type:THREE.HalfFloatType});
  function captureReflection(renderer,camera,character){
    const mirror=camera.clone();mirror.position.y=.34-camera.position.y;
    const target=camera.getWorldDirection(new THREE.Vector3()).add(camera.position);target.y=.34-target.y;
    mirror.up.set(0,-1,0);mirror.lookAt(target);mirror.updateMatrixWorld();
    waterUniforms.reflectionMatrix.value.set(.5,0,0,.5,0,.5,0,.5,0,0,.5,.5,0,0,0,1).multiply(mirror.projectionMatrix).multiply(mirror.matrixWorldInverse);
    const previous=renderer.getRenderTarget();
    water.visible=false;character.visible=false;
    try{renderer.setRenderTarget(reflectionTarget);renderer.render(scene,mirror);}
    finally{renderer.setRenderTarget(previous);water.visible=true;character.visible=true;}
    waterUniforms.reflection.value=reflectionTarget.texture;waterUniforms.hasReflection.value=1;
  }
  return {water,occluders,captureReflection,update(t,reduced){waterUniforms.time.value=reduced?0:t;dust.position.y=reduced?0:Math.sin(t*.12)*.10;}};
}
