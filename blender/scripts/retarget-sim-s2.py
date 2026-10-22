"""Bake CC0 Quaternius motion onto the existing GirlA rig; never edit B2 or meshes."""
import bpy, math, json, hashlib, statistics
from pathlib import Path
from mathutils import Matrix, Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'sim/assets/private'
SOURCE=next((ROOT/'PrivateAssets/Courtyard/Animations/Quaternius').rglob('UAL1_Standard.glb'))
TARGET=OUT/'girl-a-standing.glb'
hashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [SOURCE,TARGET,ROOT/'PrivateAssets/Courtyard/Blender/B2/courtyard-b2-reference-v6-focused.blend']}
bpy.ops.wm.read_factory_settings(use_empty=True)
s=bpy.context.scene;s.render.fps=30
bpy.ops.import_scene.gltf(filepath=str(TARGET))
target=next(o for o in s.objects if o.type=='ARMATURE')
# glTF importer creates a hidden Icosphere bone-display helper: never include it in ground bounds.
chars=[target]+[o for o in s.objects if o.type=='MESH' and any(m.type=='ARMATURE' and m.object==target for m in o.modifiers)]
assert len(chars)==3
target.animation_data_clear()
for b in target.pose.bones:b.matrix_basis.identity();b.rotation_mode='QUATERNION'
bpy.context.view_layer.update()
trest={b.name:(target.matrix_world@b.matrix_local).to_quaternion() for b in target.data.bones}
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
source=next(o for o in s.objects if o.type=='ARMATURE' and o!=target)
for track in source.animation_data.nla_tracks:track.mute=True
def set_action(a):
 source.animation_data.action=a;source.animation_data.action_slot=a.slots[0]
set_action(bpy.data.actions['A_TPose']);s.frame_set(0)
srest={b.name:(source.matrix_world@b.matrix).to_quaternion() for b in source.pose.bones}
mapping={'Hips':'pelvis','Spine':'spine_01','Chest':'spine_03','Neck':'neck_01','Head':'Head'}
for side,suffix in [('Left','l'),('Right','r')]:
 for t,u in [('Shoulder','clavicle'),('Arm','upperarm'),('ForeArm','lowerarm'),('Hand','hand'),('UpLeg','thigh'),('Leg','calf'),('Foot','foot'),('ToeBase','ball')]:mapping[side+t]=u+'_'+suffix
 for t,u in [('Index','index'),('Middle','middle'),('Ring' if side=='Left' else 'Ling','ring'),('Pinky','pinky'),('Thumb','thumb')]:
  for i in range(1,4):
   name=side+'Hand'+t+str(i)
   if name in target.pose.bones:mapping[name]=u+'_'+str(i).zfill(2)+'_'+suffix
ratio=(target.matrix_world@target.data.bones['Hips'].head_local).z/(source.matrix_world@source.pose.bones['pelvis'].head).z
source_hips=(source.matrix_world@source.pose.bones['pelvis'].head).copy()
rig_inv=target.matrix_world.inverted();rig_rot_inv=target.matrix_world.to_quaternion().inverted()
report={'source':'Quaternius Universal Animation Library Standard v3 (CC0)','source_hashes':hashes,'mapped_bones':len(mapping),'height_ratio':ratio,'clips':{}}
for srcname,name in [('Idle_Loop','Idle'),('Walk_Loop','Walk')]:
 action=bpy.data.actions[srcname];end=round(action.frame_range[1]);set_action(action)
 target.animation_data_clear()
 for b in target.pose.bones:b.matrix_basis.identity()
 samples=[]
 for frame in range(end+1):
  s.frame_set(frame)
  # Parent-to-child world rotations avoid copying incompatible local bone axes.
  for pb in target.pose.bones:
   if pb.name not in mapping:continue
   sb=source.pose.bones[mapping[pb.name]]
   q=(source.matrix_world@sb.matrix).to_quaternion()@srest[sb.name].inverted()@trest[pb.name]
   m=(rig_rot_inv@q).to_matrix().to_4x4();m.translation=pb.head.copy()
   if pb.name=='Hips':
    delta=(source.matrix_world@sb.head)-source_hips
    m.translation=target.data.bones['Hips'].head_local+rig_inv.to_3x3()@(delta*ratio)
   pb.matrix=m;bpy.context.view_layer.update()
  # Preserve proportions; ground the supporting foot using the evaluated mesh.
  deps=bpy.context.evaluated_depsgraph_get();low=1e9
  for obj in chars:
   if obj.type!='MESH':continue
   ev=obj.evaluated_get(deps);mesh=ev.to_mesh()
   low=min(low,min((ev.matrix_world@v.co).z for v in mesh.vertices));ev.to_mesh_clear()
  hip=target.pose.bones['Hips'];m=hip.matrix.copy();m.translation+=rig_inv.to_3x3()@Vector((0,0,-low+.008));hip.matrix=m
  bpy.context.view_layer.update()
  samples.append({side: list(target.matrix_world@target.pose.bones[side+'ToeBase'].head) for side in ['Left','Right']})
  for b in target.pose.bones:
   b.keyframe_insert('rotation_quaternion',frame=frame,group=b.name)
   b.keyframe_insert('location',frame=frame,group=b.name)
 target.animation_data.action.name='S2_'+name
 speeds=[]
 for side in ['Left','Right']:
  floor=min(x[side][2] for x in samples)
  for a,b in zip(samples,samples[1:]):
   speed=(b[side][1]-a[side][1])*30
   if a[side][2]<floor+.045 and speed>.15:speeds.append(speed)
 report['clips'][name]={'source_clip':srcname,'duration':end/30,'frames':end+1,'measured_stance_speed':statistics.median(speeds) if speeds else 0,'foot_samples':samples}
 s.frame_start=0;s.frame_end=end;s.frame_set(0)
 bpy.ops.object.select_all(action='DESELECT')
 for o in chars:o.select_set(True)
 bpy.context.view_layer.objects.active=target
 bpy.ops.export_scene.gltf(filepath=str(OUT/('girl-a-'+name.lower()+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='SCENE',export_frame_range=True,export_force_sampling=True,export_skins=True,export_yup=True)
report['unchanged_sources']=all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
assert report['unchanged_sources']
(OUT/'locomotion.json').write_text(json.dumps(report,indent=2))
print('S2_RETARGET',json.dumps({k:{a:b for a,b in v.items() if a!='foot_samples'} for k,v in report['clips'].items()}))
