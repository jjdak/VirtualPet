"""Visual correction of the existing wardrobe study, preserving previous versions."""
import bpy, bmesh, math, json, hashlib
from pathlib import Path
from mathutils import Matrix, Vector

source=Path(bpy.data.filepath);assert source.name=='courtyard-b1-character-v1.blend'
dest=source.with_name('courtyard-b1-character-v2.blend');assert not dest.exists()
s=bpy.context.scene;rig=next(o for o in s.objects if o.type=='ARMATURE')
def transform(name):return rig.matrix_world@rig.pose.bones[name].matrix@rig.data.bones[name].matrix_local.inverted()@rig.matrix_world.inverted()
def weighted(obj,vertex):
    m=Matrix(((0,0,0,0),)*4);total=0
    for g in vertex.groups:
        name=obj.vertex_groups[g.group].name
        if name not in rig.pose.bones:continue
        t=transform(name);total+=g.weight
        for a in range(4):
            for b in range(4):m[a][b]+=t[a][b]*g.weight
    assert total>.99
    return m

# Restore v3 hair coordinates, then reshape in evaluated pose space and inverse-bind.
for name in ('Hair','Body_5'):
    obj=bpy.data.objects[name]
    for v in obj.data.vertices:
        if v.co.z<1.46:
            original_z=1.46+(v.co.z-1.46)/.23
            t=min(1,(1.46-original_z)/.435);v.co.z=original_z;v.co.x/=1-.11*t
    bpy.context.view_layer.update();ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=ev.to_mesh()
    targets=[obj.matrix_world@v.co for v in mesh.vertices];ev.to_mesh_clear()
    inv=obj.matrix_world.inverted()
    for v,p in zip(obj.data.vertices,targets):
        if p.z<1.925:
            f=min(1,(1.925-p.z)/.7)
            p.z=1.925-(1.925-p.z)*.25
            p.x=-1.409+(p.x+1.409)*(1-.18*f)
            p.y=.065+(p.y-.065)*(1-.18*f)
        v.co=inv@weighted(obj,v).inverted()@p
    obj.data.update()

# Extend the source shirt continuously; the separate tubular sleeves are archived.
for name in ('Slate linen - L sleeve','Slate linen - R sleeve'):
    bpy.data.objects[name].hide_render=True;bpy.data.objects[name].hide_set(True)
obj=bpy.data.objects['Body_4']
for v in obj.data.vertices:
    x=abs(v.co.x)
    if x<=.19:continue
    side='L' if v.co.x>0 else 'R';sign=1 if v.co.x>0 else -1
    u=min(1,(x-.19)/(.321-.19));nx=.19+u*(.507-.19)
    v.co.x=sign*nx;v.co.y=.025+(v.co.y-.025)*(1-.15*u);v.co.z=1.274+(v.co.z-1.274)*(1-.15*u)
    for group in obj.vertex_groups:group.remove([v.index])
    blend=max(0,min(1,(nx-.275)/.105))
    for bone,w in [('J_Bip_'+side+'_UpperArm',1-blend),('J_Bip_'+side+'_LowerArm',blend)]:obj.vertex_groups[bone].add([v.index],w,'REPLACE')
sub=obj.modifiers.new('Soft continuous sleeve surface','SUBSURF');sub.levels=1;sub.render_levels=1

# The hem turns down beyond the knees, instead of opening toward the camera.
obj=bpy.data.objects['Slate linen - seated skirt']
profiles=[(.04,1.29,.176,.119,0),(.02,1.18,.19,.133,25),(-.10,1.105,.201,.116,65),(-.24,1.073,.205,.128,85),(-.40,1.04,.20,.136,75),(-.51,.97,.205,.132,38),(-.52,.865,.202,.119,0)]
for vertex in obj.data.vertices:
    j,i=divmod(vertex.index,48);t=j/30;u=t*(len(profiles)-1);idx=min(int(u),len(profiles)-2);f=u-idx
    y,z,width,depth,angle=[profiles[idx][k]*(1-f)+profiles[idx+1][k]*f for k in range(5)];angle=math.radians(angle)
    theta=i/48*math.tau;fold=.0035*math.sin(theta*9+t*2)*math.sin(t*math.pi/2)
    p=Vector((-1.45+width*math.cos(theta),y+math.sin(theta)*(depth+fold)*math.cos(angle),z+math.sin(theta)*(depth+fold)*math.sin(angle)))
    if p.y>-.115:p.z=max(1.012,p.z)
    vertex.co=weighted(obj,vertex).inverted()@p
bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.reverse_faces(bm,faces=list(bm.faces));bm.to_mesh(obj.data);bm.free()
sub=obj.modifiers.new('Soft cloth profile','SUBSURF');sub.levels=1;sub.render_levels=1
# Match existing torso color so the waist reads as one garment.
m=bpy.data.materials['B1 Character - slate blue linen'];p=m.node_tree.nodes.get('Principled BSDF')
for link in list(p.inputs['Base Color'].links):m.node_tree.links.remove(link)
p.inputs['Base Color'].default_value=bpy.data.materials['Tops_01_CLOTH'].node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value

s.render.filepath=str(source.with_name('b1-character-v2-preview.png'));s.cycles.samples=96
bpy.data.texts['B1 CHARACTER STUDY - scope'].write('\nV2: original shirt sleeves extended continuously and reweighted, earlier sleeve tubes hidden. Hem turns downward over knees. Hair shortened in evaluated pose space and inverse-bound to retained bones. Not cloth simulation.\n')
bpy.ops.wm.save_as_mainfile(filepath=str(dest))
source.with_name('b1-character-v2-change-report.json').write_text(json.dumps({'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'output':str(dest),'corrections':['Continuous source shirt sleeves','Downward hem profile','Pose-space hair shortening'],'owner_acceptance':'pending'},indent=2))
bpy.ops.render.render(write_still=True)
camera=s.camera;detail=camera.copy();detail.data=camera.data.copy();s.collection.objects.link(detail);s.camera=detail
detail.location+=Vector((-1.35,.1,.23));detail.data.ortho_scale=3.2
s.render.resolution_x=900;s.render.resolution_y=900;s.cycles.samples=64;s.render.filepath=str(source.with_name('b1-character-v2-detail.png'))
bpy.ops.render.render(write_still=True)
