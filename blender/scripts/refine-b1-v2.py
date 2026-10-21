"""Correct the inspected B1 still; continue the existing v1 without re-import."""
import bpy, math, random, json, hashlib
from pathlib import Path
from mathutils import Vector, Quaternion

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'PrivateAssets/Courtyard/Blender'
source=Path(bpy.data.filepath)
assert source.name=='courtyard-b1-v1.blend'
dest=OUT/'courtyard-b1-v2.blend'
assert not dest.exists(), 'Preserve existing art versions'
scene=bpy.context.scene
camera=[list(row) for row in scene.camera.matrix_world]
scale=scene.camera.data.ortho_scale
art=bpy.data.collections['05 B1 - authored stone, foliage and water']
r=random.Random(91202)

def color(h):
    a=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    return tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in a)+(1,)

# Retain the ten authored crown groups, but distribute leaves through volumes.
# Leaves have individual tilt; their normal field follows each small crown.
centers=[(-4.75,2.70,3.55),(-4.06,2.46,3.78),(-3.2,2.60,3.85),(-2.31,2.69,3.92),(-1.42,2.54,3.94),(-.68,2.43,3.82),(-2.28,1.03,3.44),(-1.64,.55,3.63),(-4.11,.98,2.88),(-2.,1.93,2.34)]
radii=[(.66,.52,.48),(.66,.53,.60),(.68,.58,.58),(.67,.62,.47),(.70,.54,.49),(.50,.48,.40),(.76,.57,.49),(.47,.5,.41),(.66,.46,.41),(.50,.46,.37)]
for j,(c,rad) in enumerate(zip(centers,radii)):
    obj=bpy.data.objects['Canopy cluster %02d'%j]
    mesh=obj.data;center=Vector(c); normals=[]
    for start in range(0,len(mesh.vertices),7):
        z=r.uniform(-1,1);theta=r.uniform(0,math.tau);radius=r.random()**.32
        direction=Vector((math.sqrt(1-z*z)*math.cos(theta),math.sqrt(1-z*z)*math.sin(theta),z))
        off=Vector(tuple(direction[k]*rad[k]*radius for k in range(3)))
        pos=center+off
        length=r.uniform(.16,.28);width=length*r.uniform(.27,.37)
        yaw=r.random()*math.tau
        u=Vector((math.cos(yaw),math.sin(yaw),r.uniform(-.95,.95))).normalized()
        v=u.cross(Vector((0,0,1))).normalized()
        normal=u.cross(v).normalized()
        if normal.z<0:normal=-normal
        fold=Quaternion(u,r.uniform(-.7,.7));v=fold@v;normal=fold@normal
        smooth=(Vector((direction.x*.42,direction.y*.42,.85+direction.z*.4))).normalized()
        for k,(x,y,h) in enumerate([(0,-.5,0),(-.8,-.1,0),(-1,.16,0),(0,.58,-.009),(1,.16,0),(.8,-.1,0),(0,0,.012)]):
            mesh.vertices[start+k].co=pos+v*x*width+u*y*length+normal*h
            normals.append(smooth)
    mesh.update();mesh.normals_split_custom_set_from_vertices(normals)

# Blend wall dampness by height with a noisy transition, replacing solid bands.
for name in ('Wall foot back','Wall foot left'):bpy.data.objects[name].hide_render=True
m=bpy.data.materials['B1 Limewash - broad quiet variation'];n=m.node_tree.nodes;l=m.node_tree.links
bs=n.get('Principled BSDF');original=bs.inputs['Base Color'].links[0].from_socket
geo=n.new('ShaderNodeNewGeometry');sep=n.new('ShaderNodeSeparateXYZ');l.new(geo.outputs['Position'],sep.inputs[0])
noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=3.5;l.new(geo.outputs['Position'],noise.inputs['Vector'])
mul=n.new('ShaderNodeMath');mul.operation='MULTIPLY';mul.inputs[1].default_value=.23;l.new(noise.outputs['Fac'],mul.inputs[0])
add=n.new('ShaderNodeMath');add.operation='ADD';l.new(sep.outputs['Z'],add.inputs[0]);l.new(mul.outputs[0],add.inputs[1])
ran=n.new('ShaderNodeMapRange');ran.inputs['From Min'].default_value=.93;ran.inputs['From Max'].default_value=1.43;ran.inputs['To Min'].default_value=.65;ran.inputs['To Max'].default_value=0;l.new(add.outputs[0],ran.inputs['Value'])
mix=n.new('ShaderNodeMixRGB');l.new(ran.outputs[0],mix.inputs[0]);l.new(original,mix.inputs[1]);mix.inputs[2].default_value=color('#829581');l.new(mix.outputs[0],bs.inputs['Base Color'])

# Replace thin square pool tiles by submerged, irregular rounded pebbles.
for obj in list(scene.objects):
    if obj.name.startswith('Submerged stone '):obj.hide_render=True
for i in range(65):
    x=r.uniform(-3.85,3.85);y=r.uniform(-3.83,-.39)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(x,y,.084))
    o=bpy.context.object;o.name='B1v2 River pebble %02d'%i
    for col in list(o.users_collection):col.objects.unlink(o)
    art.objects.link(o)
    size=r.uniform(.055,.19);o.scale=(size,size*r.uniform(.6,1),r.uniform(.014,.026))
    o.rotation_euler.z=r.random()*math.tau
    for v in o.data.vertices:v.co*=r.uniform(.88,1.08)
    for p in o.data.polygons:p.use_smooth=True
    o.data.materials.append(bpy.data.materials['B1 Submerged pebble '+str(i%3)])

# A closed shallow water body gives refracted rays an exit boundary.
water=bpy.data.objects['Water']
corners=[water.matrix_world@Vector(v) for v in water.bound_box]
x0,x1=min(v.x for v in corners),max(v.x for v in corners)
y0,y1=min(v.y for v in corners),max(v.y for v in corners)
vertices=[(x,y,z) for z in (.077,.17) for x,y in ((x0,y0),(x1,y0),(x1,y1),(x0,y1))]
mesh=bpy.data.meshes.new('B1v2 Closed shallow water')
mesh.from_pydata(vertices,[],[(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]);mesh.update()
wm=water.data.materials[0];water.data=mesh;water.matrix_world.identity();mesh.materials.append(wm)
n=wm.node_tree.nodes;bs=n.get('Principled BSDF');bs.inputs['Base Color'].default_value=color('#e5eee4');bs.inputs['Roughness'].default_value=.045
for node in n:
    if node.type=='BUMP':node.inputs['Strength'].default_value=.11;node.inputs['Distance'].default_value=.009
bed=bpy.data.materials['B1 Pool bed - jade silt']
for node in bed.node_tree.nodes:
    if node.type=='VALTORGB':
        for el,h in zip(sorted(node.color_ramp.elements,key=lambda e:e.position),['#8ba195','#9bad9c','#aab7a3']):el.color=color(h)
    if node.type=='TEX_NOISE' and node.inputs['Scale'].default_value<10:node.inputs['Scale'].default_value=1.4
    if node.type=='BUMP':node.inputs['Distance'].default_value=.005

# Compress alternating paving colors so silhouettes do not become a checkerboard.
for j in range(4):
    m=bpy.data.materials['B1 Limestone '+str(j)]
    for node in m.node_tree.nodes:
        if node.type=='VALTORGB':
            for e,h in zip(sorted(node.color_ramp.elements,key=lambda e:e.position),['#b4b7a5','#c8c9b4','#dcd8bf']):
                target=color(h);e.color=tuple(e.color[k]*.25+target[k]*.75 for k in range(4))
scene.cycles.samples=96
scene.render.filepath=str(OUT/'b1-v2-preview.png')
assert camera==[list(row) for row in scene.camera.matrix_world] and scale==scene.camera.data.ortho_scale
bpy.data.texts['B1 ART PASS - decisions and sources'].write('\nV2 visual correction: volumetric crown groups, individual leaf tilt; soft noisy wall dampness; rounded river pebbles; closed shallow water volume; unified paving palette. Source v1 retained.\n')
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(dest))
(OUT/'b1-v2-change-report.json').write_text(json.dumps({'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'output':str(dest),'camera_preserved':True,'canopy_groups':10,'river_pebbles':65,'water_closed_volume':True,'subjective_acceptance':'pending'},indent=2))
bpy.ops.render.render(write_still=True)
