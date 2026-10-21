import * as THREE from 'three';

// Small deterministic painted surfaces, generated locally without image services.
export function createSurfaces(random) {
  function canvasTexture(paint, size=512) {
    const canvas=document.createElement('canvas');canvas.width=canvas.height=size;
    paint(canvas.getContext('2d'),size);
    const texture=new THREE.CanvasTexture(canvas);
    texture.colorSpace=THREE.SRGBColorSpace;
    texture.wrapS=texture.wrapT=THREE.RepeatWrapping;
    texture.anisotropy=4;
    return texture;
  }
  const plaster=canvasTexture((ctx,s)=>{
    ctx.fillStyle='#c8c6bb';ctx.fillRect(0,0,s,s);
    for(let i=0;i<360;i++) {
      const x=random()*s,y=random()*s,r=12+random()*90;
      const g=ctx.createRadialGradient(x,y,0,x,y,r);
      g.addColorStop(0,i%3?'rgba(233,217,186,.09)':'rgba(79,94,83,.11)');g.addColorStop(1,'transparent');
      ctx.fillStyle=g;ctx.fillRect(x-r,y-r,r*2,r*2);
    }
    for(let i=0;i<24000;i++) {
      ctx.fillStyle=i%2?'rgba(249,238,217,.10)':'rgba(77,80,66,.07)';
      ctx.fillRect(random()*s,random()*s,1+random()*2,1);
    }
  });
  const stone=canvasTexture((ctx,s)=>{
    ctx.fillStyle='#bebeb0';ctx.fillRect(0,0,s,s);
    for(let i=0;i<1000;i++) {
      const x=random()*s,y=random()*s,r=2+random()*36;
      const g=ctx.createRadialGradient(x,y,0,x,y,r);
      g.addColorStop(0,i%3?'rgba(232,218,190,.065)':'rgba(64,81,74,.055)');g.addColorStop(1,'transparent');
      ctx.fillStyle=g;ctx.fillRect(x-r,y-r,r*2,r*2);
    }
    for(let i=0;i<80;i++) {
      let x=random()*s,y=random()*s;ctx.beginPath();ctx.moveTo(x,y);
      for(let j=0;j<4;j++){x+=random()*13-4;y+=random()*8;ctx.lineTo(x,y);}
      ctx.strokeStyle='rgba(66,76,67,.15)';ctx.lineWidth=.5+random();ctx.stroke();
    }
  });
  const leaf=canvasTexture((ctx,s)=>{
    const g=ctx.createLinearGradient(0,0,s,s);g.addColorStop(0,'#89936b');g.addColorStop(1,'#435e46');
    ctx.fillStyle=g;ctx.beginPath();ctx.moveTo(s*.5,0);
    ctx.bezierCurveTo(s*.04,s*.28,s*.15,s*.72,s*.5,s);
    ctx.bezierCurveTo(s*.87,s*.7,s*.96,s*.25,s*.5,0);ctx.fill();
    ctx.strokeStyle='rgba(222,216,152,.32)';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(s*.5,s*.06);ctx.lineTo(s*.5,s*.96);ctx.stroke();
  },128);
  const shade=canvasTexture((ctx,s)=>{
    const g=ctx.createRadialGradient(s/2,s/2,0,s/2,s/2,s/2);
    g.addColorStop(0,'rgba(33,48,39,.40)');g.addColorStop(.35,'rgba(33,48,39,.23)');g.addColorStop(1,'rgba(33,48,39,0)');
    ctx.fillStyle=g;ctx.fillRect(0,0,s,s);
  },128);
  return {plaster,stone,leaf,shade};
}
