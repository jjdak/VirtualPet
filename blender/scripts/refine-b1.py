"""B1 art pass, applied to the saved B0 project; writes a new version only."""
import bpy, math, random, json, hashlib
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'PrivateAssets/Courtyard/Blender'
DEST=OUT/'courtyard-b1-v1.blend'
assert bpy.data.filepath, 'Open the existing project first'
assert not DEST.exists(), 'Do not overwrite a previous art pass'
source=Path(bpy.data.filepath)
source_hash=hashlib.sha256(source.read_bytes()).hexdigest()
scene=bpy.context.scene
camera_before={'matrix':[list(v) for v in scene.camera.matrix_world],'scale':scene.camera.data.ortho_scale}
rng=random.Random(20260912)
art=bpy.data.collections.new('05 B1 - authored stone, foliage and water');scene.collection.children.link(art)
archive=bpy.data.collections.new('90 B0 - replaced meshes, retained');scene.collection.children.link(archive)
archive.hide_render=True;archive.hide_viewport=True
def move(obj,col):
    for c in list(obj.users_collection):c.objects.unlink(obj)
    col.objects.link(obj)
def keep_old(obj):
    obj.hide_render=True;move(obj,archive)
def color(h):
    x=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    return tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in x)+(1,)
def material(name,colors,scale=2,rough=.87,bump=.02):
    m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links
    bs=n.get('Principled BSDF');bs.inputs['Roughness'].default_value=rough
    bs.inputs['Specular IOR Level'].default_value=.25
    tex=n.new('ShaderNodeTexCoord');noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=scale;noise.inputs['Detail'].default_value=1.5;noise.inputs['Roughness'].default_value=.6
    l.new(tex.outputs['Object'],noise.inputs['Vector'])
    ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.22;ramp.color_ramp.elements[0].color=color(colors[0]);ramp.color_ramp.elements[1].position=.78;ramp.color_ramp.elements[1].color=color(colors[-1])
    if len(colors)>2:ramp.color_ramp.elements.new(.5).color=color(colors[1])
    l.new(noise.outputs['Fac'],ramp.inputs['Fac']);l.new(ramp.outputs['Color'],bs.inputs['Base Color'])
    fine=n.new('ShaderNodeTexNoise');fine.inputs['Scale'].default_value=scale*8;fine.inputs['Detail'].default_value=2;l.new(tex.outputs['Object'],fine.inputs['Vector'])
    bm=n.new('ShaderNodeBump');bm.inputs['Strength'].default_value=.22;bm.inputs['Distance'].default_value=bump;l.new(fine.outputs['Fac'],bm.inputs['Height']);l.new(bm.outputs['Normal'],bs.inputs['Normal'])
    return m
stones=[material('B1 Limestone '+str(i),p,3,.92,.012) for i,p in enumerate([
 ['#a7aa99','#c4c4ad','#dbd5b9'],['#a2a799','#bcbeac','#d3cdb5'],['#aaa68f','#c9c3a7','#ded7be'],['#9da89e','#b8c1b3','#d2d3bd']])]
mortar=material('B1 Lime mortar',['#6c796b','#949d88'],3,1,.008)
plaster=material('B1 Limewash - broad quiet variation',['#c4c1a6','#d9d4b7','#e6dfc3'],1.25,.95,.006)
bark=material('B1 Bark - muted warm grey',['#585e50','#81806a','#a3a087'],3,.9,.025)
moss=material('B1 Moss',['#475e43','#718257','#939764'],7,1,.009)

def chipped_stone(name,loc,dims,mat,seed,edge=.02):
    """A cut-corner extrusion; preserve flat support height and editability."""
    r=random.Random(seed);w,d,h=dims;w/=2;d/=2
    cuts=[min(w,d)*r.uniform(.10,.29) for _ in range(4)]
    a,b,c,e=cuts
    outline=[(-w+a,-d),(w-b,-d),(w,-d+b),(w,d-c),(w-c,d),(-w+e,d),(-w,d-e),(-w,-d+a)]
    # Uneven side shoulders; upper surface stays flat for stable seat contact.
    verts=[(x*r.uniform(.98,1.015),y*r.uniform(.98,1.015),-h/2) for x,y in outline]+[(x,y,h/2) for x,y in outline]
    faces=[tuple(reversed(range(8))),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);art.objects.link(o);o.location=loc;o.data.materials.append(mat)
    bevel=o.modifiers.new('Worn edge - editable','BEVEL');bevel.width=min(edge,h*.18);bevel.segments=2
    return o

replaced=[]
for o in list(scene.objects):
    if not o.name.startswith('Source_') or o.type!='MESH':continue
    idx=int(o.name.split('_')[1])
    if idx in (0,1,2,3):
        o.data.materials.clear();o.data.materials.append(mortar if idx else stones[1])
    elif idx==4:
        keep_old(o);replaced.append(o.name)
        # Three carefully split seating blocks; central and palm support remain at z=1.
        for j,(left,right) in enumerate([(-3.275,-2.23),(-2.21,-.76),(-.74,.075)]):
            chipped_stone('Seat limestone '+str(j),((left+right)/2,.47,.825),(right-left,1.18,.35),stones[j%4],400+j,.035)
    elif 5<=idx<=65:
        pos=o.matrix_world.translation.copy();dims=o.dimensions.copy()
        keep_old(o);replaced.append(o.name)
        if idx<31:pos.z+=rng.uniform(-.009,.009)
        chipped_stone('Limestone block '+str(idx),pos,dims,stones[idx%4],idx,.023)
    elif idx in (66,67):
        o.data.materials.clear();o.data.materials.append(plaster)
        mod=o.modifiers.new('Soft plaster edge','BEVEL');mod.width=.018;mod.segments=3
    elif idx in (68,70):
        o.data.materials.clear();o.data.materials.append(stones[0])
    elif 72<=idx<=146:
        o.data.materials.clear();o.data.materials.append(bark)
        for p in o.data.polygons:p.use_smooth=True
    elif abs(o.matrix_world.translation.z-.145)<.005:
        keep_old(o);replaced.append(o.name)

# Native masonry relief in front of the old photographic foundation planes.
for row,(z,h,y) in enumerate([(.36,.37,.035),(.73,.23,.835)]):
    x=-4.45;i=0
    while x<4.4:
        width=min(rng.uniform(.65,1.12),4.5-x)
        if width<.08:break
        chipped_stone('Riser stone %d-%d'%(row,i),(x+width/2,y,z),(width-.025,.11,h),stones[(i+row)%4],2000+i+row*100,.023)
        x+=width;i+=1

# Cover the two inherited tiny rim corner gaps using matching, editable stones.
for i,x in enumerate((-4.32,4.30)):
    chipped_stone('Corner cap '+str(i),(x,-4.18,.222),(.39,.36,.279),stones[1],2400+i,.019)

# Quiet damp band follows wall bases, with a broken world-height boundary.
damp=material('B1 Damp limestone foot',['#7b8873','#a2aa8e','#bcc0a1'],2.3,.94,.01)
chipped_stone('Wall foot back',(0,3.414,1.04),(9.1,.025,.42),damp,2450,.002)
chipped_stone('Wall foot left',(-4.412,1.42,1.03),(.026,4.34,.41),damp,2451,.002)

# Remove confetti-like plants; retain the actual branch scaffold and tree position.
for name in ('Tree_Leaf_Cards','Ground_Leaf_Cards'):
    if bpy.data.objects.get(name):keep_old(bpy.data.objects[name])
leaf_mats=[material('B1 Foliage '+str(i),p,3,.86,.002) for i,p in enumerate([
 ['#526b4a','#839359'],['#63754c','#9da76d'],['#788349','#b3b570'],['#4e6957','#7e956a']])]
for m in leaf_mats:
    n=m.node_tree.nodes;l=m.node_tree.links;bs=n.get('Principled BSDF');out=n.get('Material Output')
    trans=n.new('ShaderNodeBsdfTranslucent');ramp=next(n for n in n if n.type=='VALTORGB');l.new(ramp.outputs['Color'],trans.inputs['Color'])
    mix=n.new('ShaderNodeMixShader');mix.inputs[0].default_value=.22;l.new(bs.outputs[0],mix.inputs[1]);l.new(trans.outputs[0],mix.inputs[2]);l.new(mix.outputs[0],out.inputs['Surface'])

def leaf_cluster(name,center,radii,count,seed,small=False):
    r=random.Random(seed);center=Vector(center);verts=[];faces=[];normals=[];mi=[]
    for i in range(count):
        theta=r.random()*math.tau;rad=math.sqrt(r.random());height=r.uniform(-1,1)
        off=Vector((math.cos(theta)*rad*radii[0],math.sin(theta)*rad*radii[1],height*radii[2]*(1-.3*rad)))
        pos=center+off
        length=r.uniform(.12,.23) if not small else r.uniform(.07,.14)
        width=length*r.uniform(.28,.43)
        yaw=r.uniform(0,math.tau);u=Vector((math.cos(yaw),math.sin(yaw),r.uniform(-.35,.35))).normalized();v=Vector((-u.y,u.x,r.uniform(-.3,.3))).normalized()
        start=len(verts)
        for x,y,z in [(0,-.5,0),(-.8,-.1,0),(-1,.16,0),(0,.58,-.01),(1,.16,0),(.8,-.1,0),(0,0,.025)]:
            verts.append(pos+v*(x*width)+u*(y*length)+Vector((0,0,z)))
            normal=Vector((off.x/(radii[0]+.1)*.3,off.y/(radii[1]+.1)*.3,.9+height*.15)).normalized();normals.append(normal)
        for k in range(6):faces.append((start+6,start+k,start+(k+1)%6));mi.append((i//9+int(pos.z*3))%len(leaf_mats))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    for mat in leaf_mats:mesh.materials.append(mat)
    for p,i in zip(mesh.polygons,mi):p.material_index=i;p.use_smooth=True
    if hasattr(mesh,'normals_split_custom_set_from_vertices'):mesh.normals_split_custom_set_from_vertices(normals)
    else:raise RuntimeError('Leaf normal transfer API unavailable')
    obj=bpy.data.objects.new(name,mesh);art.objects.link(obj);return obj

clusters=[((-4.75,2.70,3.55),(.64,.50,.30),165),((-4.06,2.46,3.78),(.60,.48,.28),185),((-3.2,2.60,3.85),(.64,.57,.25),190),((-2.31,2.69,3.92),(.63,.60,.23),195),((-1.42,2.54,3.94),(.68,.52,.22),185),((-.68,2.43,3.82),(.48,.46,.25),135),((-2.28,1.03,3.44),(.74,.55,.35),210),((-1.64,.55,3.63),(.45,.48,.28),120),((-4.11,.98,2.88),(.64,.42,.27),170),((-2.0,1.93,2.34),(.48,.43,.25),125)]
for i,(c,r,n) in enumerate(clusters):leaf_cluster('Canopy cluster %02d'%i,c,r,n,3100+i)

# Small grouped plants at cracks and wall/tree contacts; keep the seat clear.
for i,(x,y,z) in enumerate([(-3.50,2.08,.99),(-3.84,1.69,.98),(-3.85,2.64,.98),(-4.19,2.99,.98),(-2.98,3.25,.99),(-2.53,3.24,.97),(3.42,3.25,.98),(3.81,3.20,.98),(2.10,.76,.65),(3.48,.78,.65),(-3.87,.32,.69)]):
    leaf_cluster('Ground growth %02d'%i,(x,y,z),(.23,.20,.09),50,4000+i,True)
    patch=chipped_stone('Moss contact %02d'%i,(x,y,z-.027),(.40,.28,.023),moss,4200+i,.003)

# Pool bed is visible through real transmission, using subdued submerged stones.
bed=material('B1 Pool bed - jade silt',['#627969','#91a18b','#b0b5a0'],4,.93,.018)
bpy.data.objects['Source_001'].data.materials.clear();bpy.data.objects['Source_001'].data.materials.append(bed)
pebbles=[material('B1 Submerged pebble '+str(i),p,4,.83,.014) for i,p in enumerate([['#748776','#a7b49a'],['#8f967c','#bec1a0'],['#617c73','#96ada0']])]
for i in range(85):
    x=rng.uniform(-3.97,3.97);y=rng.uniform(-3.97,-.38);w=rng.uniform(.15,.51);d=rng.uniform(.11,.4)
    chipped_stone('Submerged stone %02d'%i,(x,y,.093),(w,d,.045),pebbles[i%3],4500+i,.018)
water=bpy.data.objects['Water'];wm=bpy.data.materials.new('B1 Clear jade water');wm.use_nodes=True;n=wm.node_tree.nodes;l=wm.node_tree.links;bs=n.get('Principled BSDF')
bs.inputs['Base Color'].default_value=color('#c9e0ca');bs.inputs['Transmission Weight'].default_value=1;bs.inputs['Roughness'].default_value=.075;bs.inputs['IOR'].default_value=1.333
tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=3.2;tex.inputs['Detail'].default_value=2
bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.15;bump.inputs['Distance'].default_value=.045;l.new(tex.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs['Normal'],bs.inputs['Normal']);water.data.materials.clear();water.data.materials.append(wm)

# Unified afternoon light; soft cast shadows now come from the grouped canopy.
for o in list(scene.objects):
    if o.type=='LIGHT':o.hide_render=True
ld=bpy.data.lights.new('B1 Afternoon sun','SUN');ld.energy=2.2;ld.color=(1,.86,.69);ld.angle=math.radians(5)
sun=bpy.data.objects.new(ld.name,ld);art.objects.link(sun);sun.rotation_euler=Vector((3,4,-8)).to_track_quat('-Z','Y').to_euler()
ld=bpy.data.lights.new('B1 Soft sky fill','AREA');ld.energy=300;ld.color=(.76,.87,1);ld.shape='DISK';ld.size=6
fill=bpy.data.objects.new(ld.name,ld);art.objects.link(fill);fill.location=(1,-4,6);fill.rotation_euler=(Vector((-1,0,1))-fill.location).to_track_quat('-Z','Y').to_euler()
bg=scene.world.node_tree.nodes.get('Background');bg.inputs['Color'].default_value=(.69,.80,.90,1);bg.inputs['Strength'].default_value=.55
back=bpy.data.materials.get('Backdrop - warm neutral');back.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=color('#dedccc')

# Preserve the skinned character: adjust fabric response and skin scattering only.
for m in bpy.data.materials:
    if not m.use_nodes:continue
    bs=m.node_tree.nodes.get('Principled BSDF')
    if not bs:continue
    if 'SKIN' in m.name:
        bs.inputs['Subsurface Weight'].default_value=.07
        bs.inputs['Subsurface Radius'].default_value=(.10,.045,.02)
        bs.inputs['Roughness'].default_value=.68
    elif 'Tops' in m.name or 'Bottoms' in m.name:
        bs.inputs['Roughness'].default_value=.91;bs.inputs['Sheen Weight'].default_value=.15

scene.cycles.samples=64;scene.cycles.use_denoising=True
scene.render.resolution_x=1280;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.render.filepath=str(OUT/'b1-preview.png')
assert camera_before=={'matrix':[list(v) for v in scene.camera.matrix_world],'scale':scene.camera.data.ortho_scale}
text=bpy.data.texts.new('B1 ART PASS - decisions and sources')
text.write('B1 environment art pass. Applied to saved B0, not regenerated from browser.\nOriginal camera preserved. Original replaced meshes retained in disabled collection.\nStone edge silhouettes, grouped canopy normals, broad palette and directed light.\nSources and scope: docs/courtyard/B1_ART_PASS.md. No downloaded artwork or new paid tools.\nStatic visual review pending; native character animation is still not authored.\n')
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(DEST))
(OUT/'b1-change-report.json').write_text(json.dumps({'source':str(source),'source_sha256':source_hash,'output':str(DEST),'camera_before':camera_before,'camera_preserved':True,'replaced_objects':replaced,'canopy_clusters':len(clusters),'canopy_leaves':sum(c[2] for c in clusters),'generated_with_seed':20260912,'new_dependencies':[],'subjective_acceptance':'pending'},indent=2))
bpy.ops.render.render(write_still=True)
