"""Continue environment v3 with the existing GirlA rig; no character mesh edits."""
import bpy, math, json
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT/'PrivateAssets/Courtyard/Blender/courtyard-b1-girl-a-v2.blend'
assert Path(bpy.data.filepath).name == 'courtyard-b1-girl-a-v1.blend'
assert not DEST.exists(), 'Do not overwrite authored scenes'
scene = bpy.context.scene
camera_matrix = scene.camera.matrix_world.copy()
camera_scale = scene.camera.data.ortho_scale
old = bpy.data.objects['Root']
old_positions = {b.name: old.matrix_world@b.head for b in old.pose.bones}
rig = bpy.data.objects['GirlA - courtyard rig']
for b in rig.pose.bones:
    b.matrix_basis = Matrix.Identity(4); b.custom_shape = None
rig.location = (-1.45,.05,1.13-2.25*.627820909)
rig.rotation_mode = 'XYZ'
rig.rotation_euler = (0,0,math.pi);rig.scale = (2.25,)*3
bpy.context.view_layer.update()
def point(name): return rig.matrix_world@rig.pose.bones[name].head
def aim(name, child, target):
    bpy.context.view_layer.update()
    pb = rig.pose.bones[name]
    a = pb.head.copy(); b = rig.pose.bones[child].head.copy()
    target_local = rig.matrix_world.inverted()@Vector(target)
    q = (b-a).rotation_difference(target_local-a)
    pb.matrix = Matrix.Translation(a)@q.to_matrix().to_4x4()@Matrix.Translation(-a)@pb.matrix
    bpy.context.view_layer.update()
def match_direction(name, child, oldname, oldchild):
    aim(name,child,point(name)+(old_positions[oldchild]-old_positions[oldname]))
for side, letter in [('Left','L'),('Right','R')]:
    match_direction(side+'UpLeg',side+'Leg',f'J_Bip_{letter}_UpperLeg',f'J_Bip_{letter}_LowerLeg')
    match_direction(side+'Leg',side+'Foot',f'J_Bip_{letter}_LowerLeg',f'J_Bip_{letter}_Foot')
    aim(side+'Foot',side+'ToeBase',point(side+'Foot')+Vector((0,-1,-.04)))
# Mild asymmetry, using only original body bones.
pb = rig.pose.bones['Spine'];pb.rotation_mode='QUATERNION'
axis = pb.bone.matrix_local.to_quaternion().inverted()@Vector((1,0,0))
pb.rotation_quaternion = Quaternion(axis,math.radians(-3))
bpy.context.view_layer.update()
def arm(side,target,pole):
    upper,lower,hand = side+'Arm',side+'ForeArm',side+'Hand'
    a = point(upper);c = Vector(target);axis = (c-a).normalized()
    l1 = (point(lower)-a).length;l2=(point(hand)-point(lower)).length
    dist = min((c-a).length,l1+l2-.001)
    x = (dist*dist+l1*l1-l2*l2)/(2*dist)
    h = math.sqrt(max(0,l1*l1-x*x))
    tangent = Vector(pole)-a;tangent -= axis*tangent.dot(axis);tangent.normalize()
    elbow = a+axis*x+tangent*h
    aim(upper,lower,elbow);aim(lower,hand,c)
    return (point(hand)-c).length
errors = {'left':arm('Left',(-1.16,.11,1.025),(-.85,.25,1.45)),
          'right':arm('Right',(-1.54,-.30,1.18),(-1.95,-.10,1.40))}
# Original palm orientation in world space: finger axis lies on stone/lap.
for side in ('Left','Right'):
    pb=rig.pose.bones[side+'Hand'];m=pb.matrix.copy()
    # Rest fingers extend left/right along X; rotate them toward front (-Y world).
    q=Quaternion((0,0,1),math.pi/2 if side=='Left' else -math.pi/2)
    orientation=q.to_matrix().to_4x4()@pb.bone.matrix_local.to_quaternion().to_matrix().to_4x4()
    orientation.translation=m.translation;pb.matrix=orientation
bpy.context.view_layer.update()
head = rig.pose.bones['Head'];head.rotation_mode='QUATERNION'
axis=head.bone.matrix_local.to_quaternion().inverted()@Vector((0,0,1))
head.rotation_quaternion=Quaternion(axis,math.radians(-8))
assert scene.camera.matrix_world == camera_matrix and scene.camera.data.ortho_scale == camera_scale
scene['girl_a_scope']='Owner accepts missing face data for scene-first progress. Static placement; no character mesh edits, no blink, no learned intelligence.'
scene.render.resolution_x=1280;scene.render.resolution_y=720
scene.render.resolution_percentage=100;scene.cycles.samples=48
scene.render.filepath=str(DEST.with_name('b1-girl-a-v2-preview.png'))
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(DEST))
report={'file':str(DEST),'camera_ortho_scale':camera_scale,'camera_unchanged':True,'original_meshes_modified':False,'rig_bones':len(rig.data.bones),'hand_joint_target_errors_m':errors,'face_controls':'absent; owner accepted for current stage','static_visual_acceptance':'pending'}
DEST.with_suffix('.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
bpy.ops.render.render(write_still=True)
print(json.dumps(report))
