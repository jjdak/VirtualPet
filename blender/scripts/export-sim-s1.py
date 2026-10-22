"""Read B2 source; export separate runtime assets. Never save the .blend source."""
import bpy, json, math, hashlib
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[2]
SOURCE=Path(bpy.data.filepath)
assert SOURCE.name=='courtyard-b2-reference-v6-focused.blend'
source_hash=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
OUT=ROOT/'sim/assets/private'; OUT.mkdir(parents=True,exist_ok=True)
s=bpy.context.scene; s.frame_set(1)
rig=bpy.data.objects['GirlA - courtyard rig']
chars=[rig,bpy.data.objects['face'],bpy.data.objects['other']]
def convert(v):return [v.x,v.z,-v.y]
cam=s.camera; pos=cam.matrix_world.translation
metadata={'source':str(SOURCE.relative_to(ROOT)),'source_sha256':source_hash,'camera_position':convert(pos),'camera_target':convert(pos+cam.matrix_world.to_quaternion()@Vector((0,0,-20))),'camera_vertical_size':cam.data.ortho_scale/(s.render.resolution_x/s.render.resolution_y),'bone_count':len(rig.data.bones),'material_policy':'Procedural environment color ramps flattened; original character textures retained. Runtime lighting/water replace Cycles effects.'}
# Replace procedural environment shading only in memory; carry the actual B2 palette.
material_changes={}
for m in list(bpy.data.materials):
 if not m.name.startswith('B1 '):continue
 ramps=[n for n in m.node_tree.nodes if n.type=='VALTORGB'] if m.use_nodes else []
 color=tuple(ramps[0].color_ramp.evaluate(.5)) if ramps else tuple(m.diffuse_color)
 replacement=bpy.data.materials.new('S1 '+m.name);replacement.use_nodes=True
 bs=replacement.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=color;bs.inputs['Roughness'].default_value=.88
 replacement.diffuse_color=color
 replacement.use_backface_culling=False
 for o in s.objects:
  if o.type=='MESH' and o not in chars:
   for slot in o.material_slots:
    if slot.material==m:slot.material=replacement
 material_changes[m.name]=list(color)
def export(name,objects,animation=False):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.gltf(filepath=str(OUT/name),export_format='GLB',use_selection=True,export_animations=animation,export_animation_mode='SCENE',export_frame_range=True,export_force_sampling=True,export_skins=True,export_yup=True,export_cameras=False,export_lights=False)
env=[o for o in s.objects if o.type=='MESH' and o.visible_get() and not o.hide_render and o not in chars and o.name not in ['Water','Backdrop - studio ground']]
export('courtyard-v6.glb',env)
# Complete existing seated animation, with the original placement, for explicit preview mode.
export('girl-a-seated.glb',chars,True)
# Independent standing pose for the movement/camera test. Mesh geometry stays untouched.
rig.animation_data_clear()
for b in rig.pose.bones:b.matrix_basis.identity()
rig.location=(0,0,0);rig.rotation_euler=(0,0,math.pi);rig.scale=(1.8,)*3
bpy.context.view_layer.update()
def aim(name,child,target):
 pb=rig.pose.bones[name];a=pb.head.copy();direction=rig.pose.bones[child].head-a
 delta=direction.rotation_difference(Vector(target)-a)
 pb.matrix=Matrix.Translation(a)@delta.to_matrix().to_4x4()@Matrix.Translation(-a)@pb.matrix
 bpy.context.view_layer.update()
for side,sign in [('Left',1),('Right',-1)]:
 arm=rig.pose.bones[side+'Arm'].head.copy()
 aim(side+'Arm',side+'ForeArm',arm+Vector((sign*.08,0,-.35)))
# Ground the evaluated skinned feet; don't change the original mesh vertices.
deps=bpy.context.evaluated_depsgraph_get();points=[]
for o in chars[1:]:
 ev=o.evaluated_get(deps);mesh=ev.to_mesh();points.extend(ev.matrix_world@v.co for v in mesh.vertices);ev.to_mesh_clear()
zmin=min(v.z for v in points);zmax=max(v.z for v in points)
rig.location.z-=zmin;bpy.context.view_layer.update()
metadata['standing_height']=zmax-zmin
metadata['standing_eye_height']=(rig.matrix_world@rig.pose.bones['Head'].head).z+.12
metadata['standing_forward']='+Z in Godot'
for bone in rig.pose.bones:
 for frame in (1,193):
  for channel in ('location','rotation_quaternion','rotation_euler','scale'):
   bone.keyframe_insert(data_path=channel,frame=frame)
rig.animation_data.action.name='S1_Standing'
export('girl-a-standing.glb',chars,True)
metadata['environment_meshes']=len(env);metadata['material_colors']=material_changes
metadata['source_unchanged']=hashlib.sha256(SOURCE.read_bytes()).hexdigest()==source_hash
metadata['exports']={p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in OUT.glob('*.glb')}
assert metadata['source_unchanged']
(OUT/'migration.json').write_text(json.dumps(metadata,indent=2))
print('S1_EXPORT_OK',json.dumps({k:metadata[k] for k in ['environment_meshes','bone_count','standing_height','standing_eye_height','source_unchanged']}))
