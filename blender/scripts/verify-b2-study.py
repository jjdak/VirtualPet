"""Check saved native motion, contact drift, loop endpoint and untouched source."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector

p=Path(bpy.data.filepath);s=bpy.context.scene
assert s.frame_start==1 and s.frame_end==192 and s.render.fps==24
assert s.camera.data.ortho_scale==15.90643310546875
rig=bpy.data.objects['GirlA - courtyard rig']
assert len(rig.data.bones)==58
meshes=[o for o in s.objects if o.type=='MESH' and o.parent==rig]
assert sorted(len(o.data.vertices) for o in meshes)==[1942,6420]
assert not any(o.data.shape_keys for o in meshes)
leaf=bpy.data.objects['Canopy cluster 06']
water=bpy.data.objects['Water'].data.materials[0].node_tree
noise=next(n for n in water.nodes if n.type=='TEX_NOISE')
def sample(frame):
    s.frame_set(frame);bpy.context.view_layer.update()
    dg=bpy.context.evaluated_depsgraph_get();verts=[]
    for o in meshes:
        ev=o.evaluated_get(dg);m=ev.to_mesh();verts.extend(ev.matrix_world@v.co for v in m.vertices);ev.to_mesh_clear()
    return {'vertices':verts,'wrists':{side:rig.matrix_world@rig.pose.bones[side+'Hand'].head for side in ('Left','Right')},'leaf':leaf.matrix_world@leaf.data.vertices[0].co,'water_w':noise.inputs['W'].default_value,'head':[list(x) for x in rig.pose.bones['Head'].matrix]}
a=sample(1);peak=sample(93);end=sample(193)
delta=lambda x,y:max((v-w).length for v,w in zip(x['vertices'],y['vertices']))
body_delta=delta(a,peak);loop_error=delta(a,end)
assert body_delta>.02,(body_delta,'No actual body deformation')
assert loop_error<1e-5,(loop_error,'Loop is not closed')
max_wrist_drift=0
max_leaf_delta=0
for frame in range(1,194):
    s.frame_set(frame);bpy.context.view_layer.update()
    for side in ('Left','Right'):
        wrist=rig.matrix_world@rig.pose.bones[side+'Hand'].head
        max_wrist_drift=max(max_wrist_drift,(wrist-a['wrists'][side]).length)
    max_leaf_delta=max(max_leaf_delta,(leaf.matrix_world@leaf.data.vertices[0].co-a['leaf']).length)
assert max_wrist_drift<.002,max_wrist_drift
assert max_leaf_delta>.003,max_leaf_delta
assert abs(a['water_w']-end['water_w'])<1e-5
assert abs(sample(49)['water_w']-a['water_w'])>.1
images=[i for i in bpy.data.images if i.type=='IMAGE']
assert images and all(i.packed_file and min(i.size)>0 for i in images)
source=p.parent.parent/'courtyard-b1-girl-a-v3.blend'
source_sha=hashlib.sha256(source.read_bytes()).hexdigest()
assert source_sha=='ddd32be6b41dc0198863ae6bf3c743beb4ee10dc34016734ecb9f961ba797f86'
s.frame_set(1)
report={'project':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'reopened':True,'source_unchanged':True,'fps':24,'render_frames':192,'duration_seconds':8,'head_body_max_displacement_m':body_delta,'max_wrist_drift_m':max_wrist_drift,'canopy_vertex_max_displacement_m':max_leaf_delta,'loop_endpoint_vertex_error_m':loop_error,'water_shader_animated':True,'packed_images':len(images),'result':'native_motion_and_saved_scene_pass','limitations':'No face animation, audio, interactive response, cloth simulation or subjective acceptance. Palm penetration not exhaustively tested.'}
report_name = 'b2-verification.json' if p.name == 'courtyard-b2-light-motion-v1.blend' else p.stem.removeprefix('courtyard-')+'-motion-verification.json'
(p.parent/report_name).write_text(json.dumps(report,indent=2))
print('B2_VERIFY',json.dumps(report),flush=True)
