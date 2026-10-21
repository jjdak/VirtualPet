"""B1 character wardrobe study, continuing v3. Native meshes, no new assets."""
import bpy, math, json, hashlib
from pathlib import Path
from mathutils import Vector, Matrix

source=Path(bpy.data.filepath)
assert source.name=='courtyard-b1-v3.blend'
dest=source.with_name('courtyard-b1-character-v1.blend')
assert not dest.exists(), 'Never overwrite authored versions'
s=bpy.context.scene
rig=next(o for o in s.objects if o.type=='ARMATURE')
collection=bpy.data.collections.new('06 B1 - character wardrobe study')
s.collection.children.link(collection)
camera=s.camera;camera_matrix=camera.matrix_world.copy();camera_scale=camera.data.ortho_scale

def color(h):
    rgb=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    return tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb)+(1,)

cloth=bpy.data.materials.new('B1 Character - slate blue linen');cloth.use_nodes=True
n=cloth.node_tree.nodes;l=cloth.node_tree.links;bs=n.get('Principled BSDF')
bs.inputs['Roughness'].default_value=.92;bs.inputs['Sheen Weight'].default_value=.18
bs.inputs['Specular IOR Level'].default_value=.22
tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=7;tex.inputs['Detail'].default_value=1
ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=color('#667d85');ramp.color_ramp.elements[1].color=color('#82949a')
l.new(tex.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],bs.inputs['Base Color'])
fine=n.new('ShaderNodeTexNoise');fine.inputs['Scale'].default_value=170
bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.13;bump.inputs['Distance'].default_value=.0007
l.new(fine.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs[0],bs.inputs['Normal'])
# Keep source top alpha, which defines the neck opening; replace only its color response.
for name in ('Tops_01_CLOTH','Tops_01_CLOTH (Outline)'):
    m=bpy.data.materials[name];nodes=m.node_tree.nodes;links=m.node_tree.links;p=nodes.get('Principled BSDF')
    for link in list(p.inputs['Base Color'].links):links.remove(link)
    p.inputs['Base Color'].default_value=color('#758b93');p.inputs['Roughness'].default_value=.92;p.inputs['Sheen Weight'].default_value=.18
# Shorten the existing back/side hair into a jaw-length silhouette, keeping skinning.
for name in ('Hair','Body_5'):
    mesh=bpy.data.objects[name].data
    for v in mesh.vertices:
        if v.co.z<1.46:
            t=min(1,(1.46-v.co.z)/.435)
            v.co.z=1.46-(1.46-v.co.z)*.23
            v.co.x*=1-.11*t
    mesh.update()
# Recolor footwear, retaining the original topology and alpha.
for name in ('Shoes_01_CLOTH','Shoes_01_CLOTH (Outline)'):
    m=bpy.data.materials[name];p=m.node_tree.nodes.get('Principled BSDF')
    for link in list(p.inputs['Base Color'].links):m.node_tree.links.remove(link)
    p.inputs['Base Color'].default_value=color('#625b4e');p.inputs['Roughness'].default_value=.86
    p.inputs['Specular IOR Level'].default_value=.19
bpy.data.objects['Body_2'].hide_render=True

def bone_world(name):return rig.matrix_world@rig.pose.bones[name].head
def transform(name):
    return rig.matrix_world@rig.pose.bones[name].matrix@rig.data.bones[name].matrix_local.inverted()@rig.matrix_world.inverted()

bind_errors=[]
def garment(name,world_vertices,faces,weights):
    transforms={key:transform(key) for w in weights for key in w}
    rest=[]
    for p,weight in zip(world_vertices,weights):
        matrix=Matrix(((0,0,0,0),)*4)
        for key,w in weight.items():
            for a in range(4):
                for b in range(4):matrix[a][b]+=transforms[key][a][b]*w
        rest.append(matrix.inverted()@p)
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(rest,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);collection.objects.link(obj);mesh.materials.append(cloth)
    groups={key:obj.vertex_groups.new(name=key) for key in transforms}
    for i,w in enumerate(weights):
        for key,value in w.items():groups[key].add([i],value,'REPLACE')
    for p in mesh.polygons:p.use_smooth=True
    mod=obj.modifiers.new('Bound to existing character rig','ARMATURE');mod.object=rig
    bpy.context.view_layer.update();ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());em=ev.to_mesh()
    error=max((obj.matrix_world@v.co-target).length for v,target in zip(em.vertices,world_vertices));ev.to_mesh_clear()
    assert error<.0001,(name,error);bind_errors.append({'object':name,'bind_error_m':error})
    mod=obj.modifiers.new('Cloth thickness','SOLIDIFY');mod.thickness=.002;mod.offset=0
    return obj

# A seated skirt: waist turns into lap, with the support-side fabric above the stone.
profiles=[(.04,1.29,.176,.119,0),(.02,1.18,.19,.133,25),(-.10,1.105,.201,.116,65),(-.24,1.073,.205,.128,85),(-.40,1.04,.20,.136,90),(-.565,.992,.21,.142,100)]
verts=[];weights=[];faces=[];count=48;nr=31
for j in range(nr):
    t=j/(nr-1);v=t*(len(profiles)-1);idx=min(int(v),len(profiles)-2);f=v-idx
    y,z,width,depth,angle=[profiles[idx][k]*(1-f)+profiles[idx+1][k]*f for k in range(5)]
    angle=math.radians(angle)
    for i in range(count):
        theta=i/count*math.tau;fold=.0035*math.sin(theta*9+t*2)*math.sin(t*math.pi/2)
        x=width*math.cos(theta)
        p=Vector((-1.45+x,y+math.sin(theta)*(depth+fold)*math.cos(angle),z+math.sin(theta)*(depth+fold)*math.sin(angle)))
        if p.y>-.115:p.z=max(1.012,p.z)
        verts.append(p)
        leg=.72*t;left=max(0,min(1,.5+x/(width*2)))
        weights.append({'J_Bip_C_Hips':1-leg,'J_Bip_L_UpperLeg':leg*left,'J_Bip_R_UpperLeg':leg*(1-left)})
        if j<nr-1:faces.append((j*count+i,j*count+(i+1)%count,(j+1)*count+(i+1)%count,(j+1)*count+i))
garment('Slate linen - seated skirt',verts,faces,weights)

# Sleeve extensions follow the actual posed arm; hands remain clear.
for side in ('L','R'):
    upper='J_Bip_'+side+'_UpperArm';lower='J_Bip_'+side+'_LowerArm';hand='J_Bip_'+side+'_Hand'
    shoulder=bone_world(upper);elbow=bone_world(lower);wrist=bone_world(hand)
    start=shoulder.lerp(elbow,.27);end=elbow.lerp(wrist,.87)
    verts=[];faces=[];weights=[];nr=23;count=32
    for j in range(nr):
        t=j/(nr-1)
        if t<.48:pos=start.lerp(elbow,t/.48);axis=(elbow-start).normalized()
        else:pos=elbow.lerp(end,(t-.48)/.52);axis=(end-elbow).normalized()
        u=axis.cross(Vector((0,1,0))).normalized();v=axis.cross(u).normalized()
        radius=(.109*(1-t)+.066*t)+.003*math.sin(t*math.pi)
        low=max(0,min(1,(t-.31)/.34))
        for i in range(count):
            theta=i/count*math.tau;rr=radius+.002*math.sin(theta*6+t*4)
            verts.append(pos+u*math.cos(theta)*rr+v*math.sin(theta)*rr)
            weights.append({upper:1-low,lower:low})
            if j<nr-1:faces.append((j*count+i,j*count+(i+1)%count,(j+1)*count+(i+1)%count,(j+1)*count+i))
    garment('Slate linen - '+side+' sleeve',verts,faces,weights)

s.render.resolution_x=1280;s.render.resolution_y=720;s.cycles.samples=96
s.render.filepath=str(source.with_name('b1-character-preview.png'))
assert camera.matrix_world==camera_matrix and camera.data.ortho_scale==camera_scale
text=bpy.data.texts.new('B1 CHARACTER STUDY - scope')
text.write('Shortened existing skinned hair; blue linen wardrobe study with new skirt and sleeve meshes bound to original rig. Preserves face/expressions, camera, seating support and environment. Cloth simulation, broad motion collision and final wardrobe design are not accepted. Shoes recolored, not rebuilt. See docs/courtyard/B1_CHARACTER_PASS.md.\n')
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(dest))
source.with_name('b1-character-change-report.json').write_text(json.dumps({'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'output':str(dest),'camera_preserved':True,'garments':bind_errors,'new_dependencies':[],'owner_acceptance':'pending','cloth_simulation':False},indent=2))
bpy.ops.render.render(write_still=True)
# Separate detail view for inspection; never save this camera into the production file.
detail=camera.copy();detail.data=camera.data.copy();s.collection.objects.link(detail);s.camera=detail
detail.location+=Vector((-1.35,.1,.23));detail.data.ortho_scale=3.2
s.render.resolution_x=900;s.render.resolution_y=900;s.cycles.samples=64
s.render.filepath=str(source.with_name('b1-character-detail.png'))
bpy.ops.render.render(write_still=True)
