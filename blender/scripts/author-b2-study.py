"""Native 8-second study from the saved GirlA scene. No character mesh edits."""
import bpy, math, json, hashlib
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'PrivateAssets/Courtyard/Blender/B2'
OUT.mkdir(exist_ok=True)
SOURCE = Path(bpy.data.filepath)
assert SOURCE.name == 'courtyard-b1-girl-a-v3.blend'
DEST = OUT/'courtyard-b2-light-motion-v1.blend'
assert not DEST.exists(), 'Do not overwrite authored art'
s = bpy.context.scene
cam = [list(x) for x in s.camera.matrix_world]
cam_scale = s.camera.data.ortho_scale
rig = bpy.data.objects['GirlA - courtyard rig']
meshes = [o for o in s.objects if o.type=='MESH' and o.parent==rig]
mesh_before = {o.name: [(v.co.x,v.co.y,v.co.z) for v in o.data.vertices] for o in meshes}
base = {b.name:b.matrix_basis.copy() for b in rig.pose.bones}
base_hand = {side:rig.pose.bones[side+'Hand'].matrix.copy() for side in ('Left','Right')}
base_feet = {side:rig.pose.bones[side+'Foot'].matrix.copy() for side in ('Left','Right')}
stage = bpy.data.collections.new('07 B2 - animation controls')
s.collection.children.link(stage)

# Warm directional key and cool restrained ambient preserve the approved camera.
sun = bpy.data.objects['B1 Afternoon sun']
sun.data.energy = 3.0;sun.data.color = (1,.88,.70);sun.data.angle = math.radians(4)
sun.rotation_euler = Vector((2.2,3.5,-7)).to_track_quat('-Z','Y').to_euler()
fill = bpy.data.objects['B1 Soft sky fill']
fill.data.energy = 160;fill.data.color=(.62,.78,1)
bg = s.world.node_tree.nodes['Background']
bg.inputs['Color'].default_value=(.53,.69,.90,1)
bg.inputs['Strength'].default_value=.24
ld = bpy.data.lights.new('B2 - warm poolside bounce','AREA')
ld.energy=105;ld.color=(1,.80,.59);ld.shape='DISK';ld.size=2.8
light = bpy.data.objects.new(ld.name,ld);stage.objects.link(light)
light.location=(-2,-2.5,3.4)
light.rotation_euler=(Vector((-1.45,.05,1.4))-light.location).to_track_quat('-Z','Y').to_euler()
s.view_settings.exposure=.10
look_items = s.view_settings.bl_rna.properties['look'].enum_items
looks=[i.identifier for i in look_items]
for look in ('AgX - Medium High Contrast','Medium High Contrast'):
    if look in looks:s.view_settings.look=look;break

# Lighting-compatible original textures; avoid whitening the hair or red bow.
for m in {m for o in meshes for m in o.data.materials}:
    if not m or not m.use_nodes:continue
    bs = next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
    if bs:
        bs.inputs['Roughness'].default_value=.78 if 'face' in m.name else .88
        bs.inputs['Specular IOR Level'].default_value=.2

# Animated native shader, periodic at frame 193; water remains a closed volume.
water = bpy.data.objects['Water'];tree=water.data.materials[0].node_tree
noise=next(n for n in tree.nodes if n.type=='TEX_NOISE')
noise.noise_dimensions='4D';noise.inputs['Scale'].default_value=2.4
noise.inputs['Detail'].default_value=2
bump=next(n for n in tree.nodes if n.type=='BUMP')
bump.inputs['Strength'].default_value=.17;bump.inputs['Distance'].default_value=.022
bs=next(n for n in tree.nodes if n.type=='BSDF_PRINCIPLED')
bs.inputs['Roughness'].default_value=.035
geo=tree.nodes.new('ShaderNodeTexCoord');geo.name='B2 Water coordinates'
mapping=tree.nodes.new('ShaderNodeVectorMath');mapping.operation='ADD';mapping.name='B2 Water drift'
tree.links.new(geo.outputs['Generated'],mapping.inputs[0]);tree.links.new(mapping.outputs[0],noise.inputs['Vector'])

# Pivots preserve world-space leaf geometry at the first frame.
pivots=[]
for i,o in enumerate(sorted((o for o in s.objects if o.name.startswith('Canopy cluster ')),key=lambda o:o.name)):
    mw=o.matrix_world.copy()
    center=sum((mw@Vector(c) for c in o.bound_box),Vector())/8
    p=bpy.data.objects.new('B2 Wind pivot %02d'%i,None);stage.objects.link(p)
    p.empty_display_type='PLAIN_AXES';p.empty_display_size=.1;p.location=center
    bpy.context.view_layer.update()
    o.parent=p;o.matrix_world=mw
    pivots.append(p)

def smooth(a,b,t):
    q=max(0,min(1,(t-a)/(b-a)))
    return q*q*q*(q*(q*6-15)+10)
def event(t):return smooth(2.3,3.8,t)*(1-smooth(5.0,7.3,t))
def bone_turn(name,axis,amount):
    pb=rig.pose.bones[name]
    q=pb.bone.matrix_local.to_quaternion().inverted()@Vector(axis)
    pb.matrix_basis=base[name]@Quaternion(q,amount).to_matrix().to_4x4()
def point(name):return rig.matrix_world@rig.pose.bones[name].head
def aim(name,child,target):
    bpy.context.view_layer.update();pb=rig.pose.bones[name]
    a=pb.head.copy();v=rig.pose.bones[child].head-a
    goal=rig.matrix_world.inverted()@Vector(target)-a
    q=v.rotation_difference(goal)
    pb.matrix=Matrix.Translation(a)@q.to_matrix().to_4x4()@Matrix.Translation(-a)@pb.matrix
    bpy.context.view_layer.update()
def hold_hand(side):
    up,lo,hand=side+'Arm',side+'ForeArm',side+'Hand'
    a=point(up);c=rig.matrix_world@base_hand[side].translation
    axis=(c-a).normalized();l1=(point(lo)-a).length;l2=(point(hand)-point(lo)).length
    distance=min((c-a).length,l1+l2-.0001)
    along=(distance*distance+l1*l1-l2*l2)/(2*distance)
    height=math.sqrt(max(0,l1*l1-along*along))
    pole=Vector((-.85,.25,1.45) if side=='Left' else (-1.95,-.10,1.40))-a
    pole-=axis*pole.dot(axis);pole.normalize()
    aim(up,lo,a+axis*along+pole*height);aim(lo,hand,c)
    # Copy pose-space orientation after solving the arm, preserving the wrist location.
    pb=rig.pose.bones[hand];m=base_hand[side].copy();m.translation=pb.head;pb.matrix=m
    bpy.context.view_layer.update()
    return (point(hand)-c).length

s.render.fps=24;s.frame_start=1;s.frame_end=192
animated_bones=['Spine','Chest','Neck','Head','LeftArm','LeftForeArm','LeftHand','RightArm','RightForeArm','RightHand']
for name in animated_bones:rig.pose.bones[name].rotation_mode='QUATERNION'
max_hand_error=0
for frame in range(1,194):
    s.frame_set(frame);t=(frame-1)/24;phase=math.tau*t/8
    for name in animated_bones:rig.pose.bones[name].matrix_basis=base[name]
    breathing=math.sin(phase*2)
    response=event(t)
    # Keep lower body grounded; head and neck act after the gust, not in unison.
    bone_turn('Spine',(1,0,0),.0015*breathing)
    bone_turn('Chest',(1,0,0),.0035*breathing)
    bone_turn('Neck',(0,0,1),math.radians(-4)*event(t-.12))
    bone_turn('Head',(0,0,1),math.radians(-19)*response)
    head=rig.pose.bones['Head']
    ax=head.bone.matrix_local.to_quaternion().inverted()@Vector((1,0,0))
    head.matrix_basis=head.matrix_basis@Quaternion(ax,math.radians(-3.5)*response).to_matrix().to_4x4()
    bpy.context.view_layer.update()
    max_hand_error=max(max_hand_error,hold_hand('Left'),hold_hand('Right'))
    for name in animated_bones:
        b=rig.pose.bones[name]
        for path in ('rotation_quaternion','location','scale'):b.keyframe_insert(data_path=path,frame=frame,group=name)
    gust=smooth(1.3,2.7,t)*(1-smooth(3.4,5.0,t))
    for i,p in enumerate(pivots):
        offset=i*.47
        wave=math.sin(phase+offset)-math.sin(offset)
        fast=math.sin(phase*3+offset)-math.sin(offset)
        p.rotation_euler=(.015*wave+.020*gust*math.sin(phase*3+offset),.012*wave+.011*gust, .008*fast)
        p.keyframe_insert(data_path='rotation_euler',frame=frame,group='Wind')
    noise.inputs['W'].default_value=.28*math.sin(phase)
    noise.inputs['W'].keyframe_insert('default_value',frame=frame)
    mapping.inputs[1].default_value=(.18*(math.cos(phase)-1),.10*math.sin(phase),0)
    mapping.inputs[1].keyframe_insert('default_value',frame=frame)
assert max_hand_error<.006, max_hand_error

# Each frame is baked into ordinary native actions; no runtime handler required.
for action in bpy.data.actions:
    for layer in action.layers:
        for strip in layer.strips:
            for slot in action.slots:
                bag=strip.channelbag(slot)
                if bag:
                    for fc in bag.fcurves:
                        for key in fc.keyframe_points:key.interpolation='LINEAR'

s.frame_set(1)
assert cam==[list(x) for x in s.camera.matrix_world] and cam_scale==s.camera.data.ortho_scale
assert all(mesh_before[o.name]==[(v.co.x,v.co.y,v.co.z) for v in o.data.vertices] for o in meshes)
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='METAL';prefs.get_devices()
for device in prefs.devices:device.use=device.type=='METAL'
s.render.engine='CYCLES';s.cycles.device='GPU';s.cycles.samples=64
s.cycles.use_denoising=True;s.cycles.use_adaptive_sampling=True;s.cycles.adaptive_threshold=.03
s.cycles.max_bounces=8;s.render.use_persistent_data=True
s.render.resolution_x=1280;s.render.resolution_y=720;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.render.filepath=str(OUT/'b2-light-still-v1.png')
readme=bpy.data.texts.new('B2 - play this scene')
readme.write('Native study: frames 1-192 at 24 fps = 8 seconds. Frame 193 is a matching endpoint.\nWater material, canopy pivots and GirlA body bones have native keyframes.\nNo facial movement, no audio, no interactive input or learned intelligence.\nCamera, original character meshes and source version preserved.\nRender still in Cycles; reduced samples/resolution allowed for motion preview.\n')
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(DEST))
report={'source':str(SOURCE),'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'project':str(DEST),'camera_unchanged':True,'character_meshes_unchanged':True,'fps':24,'render_frames':[1,192],'loop_endpoint':193,'canopy_pivots':len(pivots),'max_wrist_target_error_m':max_hand_error,'native_actions':len(bpy.data.actions),'face_animation':False,'audio':False,'learning':False,'subjective_acceptance':'pending'}
(OUT/'b2-authoring-report.json').write_text(json.dumps(report,indent=2))
print('B2_AUTHORING',json.dumps(report),flush=True)
bpy.ops.render.render(write_still=True)
