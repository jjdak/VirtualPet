"""V4: modest character light, wall grain, and clearer existing motion."""
import bpy, hashlib, json
from pathlib import Path
from mathutils import Vector, Quaternion

source=Path(bpy.data.filepath)
assert source.name=='courtyard-b2-shapes-v3.blend'
out=source.parent;dest=out/'courtyard-b2-presence-v4.blend'
assert not dest.exists()
s=bpy.context.scene;s.frame_set(1)
rig=bpy.data.objects['GirlA - courtyard rig']
camera={'matrix':[list(x) for x in s.camera.matrix_world],'scale':s.camera.data.ortho_scale}
def mesh_digest():
    h=hashlib.sha256()
    for m in sorted(bpy.data.meshes,key=lambda m:m.name):
        h.update(m.name.encode())
        for v in m.vertices:h.update(str(tuple(v.co)).encode())
    return h.hexdigest()
before=mesh_digest()

light=bpy.data.lights.new('B2 V4 - soft character rim','AREA')
light.energy=140;light.color=(1,.88,.74);light.shape='DISK';light.size=1.8
obj=bpy.data.objects.new(light.name,light);s.collection.objects.link(obj)
obj.location=(-3.5,1,4.2)
obj.rotation_euler=(Vector((-1.45,.05,1.85))-obj.location).to_track_quat('-Z','Y').to_euler()
receivers=bpy.data.collections.new('B2 V4 - character light receivers')
for mesh in (o for o in s.objects if o.type=='MESH' and o.parent==rig):
    receivers.objects.link(mesh)
obj.light_linking.receiver_collection=receivers
hair=bpy.data.materials['girlA_hair'].node_tree.nodes
bs=next(n for n in hair if n.type=='BSDF_PRINCIPLED')
bs.inputs['Roughness'].default_value=.64
bs.inputs['Specular IOR Level'].default_value=.32
wall=bpy.data.materials['B1 Limewash - broad quiet variation'].node_tree
for n in wall.nodes:
    if n.type=='BUMP':n.inputs['Distance'].default_value=.014;n.inputs['Strength'].default_value=.26

def curves(action):
    for layer in action.layers:
        for strip in layer.strips:
            for slot in action.slots:
                bag=strip.channelbag(slot)
                if bag:
                    yield from bag.fcurves

# Scale quaternion differences from the existing rest pose; keep event timing.
action=rig.animation_data.action
for name in ('Head','Neck'):
    path='pose.bones["'+name+'"].rotation_quaternion'
    fs=sorted((f for f in curves(action) if f.data_path==path),key=lambda f:f.array_index)
    assert len(fs)==4
    original=[Quaternion([f.evaluate(frame) for f in fs]).normalized() for frame in range(1,194)]
    base=original[0]
    for idx,q in enumerate(original):
        delta=base.inverted()@q
        if delta.w<0:delta.negate()
        axis,angle=delta.to_axis_angle()
        revised=base@Quaternion(axis,angle*1.22)
        for component,f in enumerate(fs):
            assert int(f.keyframe_points[idx].co.x)==idx+1
            f.keyframe_points[idx].co.y=revised[component]
    for f in fs:f.update()
for action in bpy.data.actions:
    if action.name.startswith('B2 Wind pivot '):
        for f in curves(action):
            base=f.evaluate(1)
            for k in f.keyframe_points:k.co.y=base+(k.co.y-base)*1.18
            f.update()
s.frame_set(1)
assert mesh_digest()==before
assert camera=={'matrix':[list(x) for x in s.camera.matrix_world],'scale':s.camera.data.ortho_scale}
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='METAL';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='METAL'
s.cycles.device='GPU';s.cycles.samples=128;s.cycles.adaptive_threshold=.015
s.cycles.use_animated_seed=False
s.render.resolution_percentage=100;s.render.filepath=str(out/'b2-presence-v4.png')
bpy.ops.wm.save_as_mainfile(filepath=str(dest))
report={'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'project':str(dest),'camera':camera,'mesh_digest':before,'all_meshes_unchanged':True,
        'head_neck_amplitude_multiplier':1.22,'wind_amplitude_multiplier':1.18,
        'event_timing_unchanged':True,'water_arm_body_actions_unchanged':True,'owner_acceptance':'pending'}
(out/'b2-presence-v4-verification.json').write_text(json.dumps(report,indent=2)+'\n')
s.cycles.samples=32;s.render.resolution_percentage=75
s.render.filepath=str(out/'b2-presence-v4-draft.png')
bpy.ops.render.render(write_still=True)
