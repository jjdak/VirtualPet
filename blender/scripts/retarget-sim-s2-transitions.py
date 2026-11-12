"""Retarget selected CMU recordings to existing GirlA, extracting collision-safe root motion."""
import bpy,json,math,hashlib
from pathlib import Path
from mathutils import Vector,Quaternion
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'sim/assets/private'
TARGET=OUT/'girl-a-standing.glb';hash_before=hashlib.sha256(TARGET.read_bytes()).hexdigest()
clips={}
# Bounds chosen after inspecting pelvis heading and displacement, at 30 fps.
for source_name,name,start,end in [('69_16','TurnLeft',1,48),('69_18','TurnRight',31,78),('16_33','Stop',41,72)]:
 bpy.ops.wm.read_factory_settings(use_empty=True);s=bpy.context.scene;s.render.fps=30
 bpy.ops.import_scene.gltf(filepath=str(TARGET))
 target=next(o for o in s.objects if o.type=='ARMATURE')
 chars=[target]+[o for o in s.objects if o.type=='MESH' and any(m.type=='ARMATURE' and m.object==target for m in o.modifiers)]
 target.animation_data_clear()
 for b in target.pose.bones:b.matrix_basis.identity();b.rotation_mode='QUATERNION'
 bpy.context.view_layer.update()
 trest={b.name:(target.matrix_world@b.matrix_local).to_quaternion() for b in target.data.bones}
 source_path=ROOT/'PrivateAssets/Courtyard/Animations/CMU'/f'{source_name}.fbx'
 bpy.ops.import_scene.fbx(filepath=str(source_path))
 source=next(o for o in s.objects if o.type=='ARMATURE' and o!=target)
 srest={b.name:(source.matrix_world@b.matrix_local).to_quaternion() for b in source.data.bones}
 mapping={'Hips':'hip','Spine':'abdomen','Chest':'chest','Neck':'neck','Head':'head'}
 for side,pre in [('Left','l'),('Right','r')]:
  for t,u in [('Shoulder','Collar'),('Arm','Shldr'),('ForeArm','ForeArm'),('Hand','Hand'),('UpLeg','Thigh'),('Leg','Shin'),('Foot','Foot')]:mapping[side+t]=pre+u
 ratio=(target.matrix_world@target.data.bones['Hips'].head_local).z/(source.matrix_world@source.data.bones['hip'].head_local).z
 inv=target.matrix_world.inverted();invrot=target.matrix_world.to_quaternion().inverted()
 samples=[];previous=None;yaw=0.0
 s.frame_set(start);initial=(source.matrix_world@source.pose.bones['hip'].head).copy()
 for f in range(start,end+1):
  s.frame_set(f)
  line=source.pose.bones['lThigh'].head-source.pose.bones['rThigh'].head
  angle=math.atan2(line.y,line.x)
  if previous is None:previous=angle
  yaw+=(angle-previous+math.pi)%(2*math.pi)-math.pi;previous=angle
  hip=(source.matrix_world@source.pose.bones['hip'].head).copy()
  root=(hip-initial)*ratio
  # Root yaw/translation are applied to CharacterBody3D, not hidden inside its mesh.
  unturn=Quaternion((0,0,1),-yaw)
  for pb in target.pose.bones:
   if pb.name not in mapping:continue
   sb=source.pose.bones[mapping[pb.name]]
   q=unturn@(source.matrix_world@sb.matrix).to_quaternion()@srest[sb.name].inverted()@trest[pb.name]
   m=(invrot@q).to_matrix().to_4x4();m.translation=pb.head.copy()
   if pb.name=='Hips':m.translation=target.data.bones['Hips'].head_local+inv.to_3x3()@Vector((0,0,root.z))
   pb.matrix=m;bpy.context.view_layer.update()
  low=1e9;deps=bpy.context.evaluated_depsgraph_get()
  for o in chars[1:]:
   ev=o.evaluated_get(deps);mesh=ev.to_mesh();low=min(low,min((ev.matrix_world@v.co).z for v in mesh.vertices));ev.to_mesh_clear()
  hp=target.pose.bones['Hips'];m=hp.matrix.copy();m.translation+=inv.to_3x3()@Vector((0,0,-low+.008));hp.matrix=m;bpy.context.view_layer.update()
  samples.append({'time':(f-start)/30,'yaw':yaw,'position':[root.x,0,-root.y]})
  for pb in target.pose.bones:
   pb.keyframe_insert('rotation_quaternion',frame=f,group=pb.name);pb.keyframe_insert('location',frame=f,group=pb.name)
 target.animation_data.action.name='S2_'+name
 s.frame_start=start;s.frame_end=end;s.frame_set(start)
 bpy.ops.object.select_all(action='DESELECT')
 for o in chars:o.select_set(True)
 bpy.context.view_layer.objects.active=target
 dest=OUT/('girl-a-'+name.lower()+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='SCENE',export_frame_range=True,export_force_sampling=True,export_skins=True,export_yup=True)
 clips[name]={'source':source_name,'frames':[start,end],'duration':(end-start)/30,'yaw':yaw,'root_samples':samples,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()}
assert hashlib.sha256(TARGET.read_bytes()).hexdigest()==hash_before
(OUT/'transitions.json').write_text(json.dumps({'source':'CMU mocap via RancidMilk / gbionics mirror; not CC0','clips':clips,'license':{'name': 'CMU mocap terms (not CC0)', 'attribution': 'CMU Graphics Lab, NSF EIA-0196217; BVH by cgspeed; FBX conversion by RancidMilk; mirror gbionics/cmu-fbx', 'terms': 'May use, copy, modify and redistribute, including in commercial products; may not directly resell motion data, including conversions. Pass these terms along when redistributing. Character license is separate.', 'source': 'https://rancidmilk.itch.io/free-character-animations', 'mirror': 'https://huggingface.co/datasets/gbionics/cmu-fbx'}},indent=2))
print('TRANSITIONS',[(n,round(math.degrees(v['yaw']),1),v['duration']) for n,v in clips.items()])
