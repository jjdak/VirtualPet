"""V5: delayed body follow, retaining original meshes and held hand contacts."""
import bpy, math, json, hashlib
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion

source=Path(bpy.data.filepath)
assert source.name=='courtyard-b2-presence-v4.blend'
out=source.parent;dest=out/'courtyard-b2-body-v5.blend'
assert not dest.exists()
s=bpy.context.scene;rig=bpy.data.objects['GirlA - courtyard rig']
names=['Spine','Chest','LeftShoulder','RightShoulder','LeftArm','LeftForeArm','LeftHand','RightArm','RightForeArm','RightHand']
for name in names:rig.pose.bones[name].rotation_mode='QUATERNION'
def mesh_hash():
    h=hashlib.sha256()
    for m in sorted(bpy.data.meshes,key=lambda m:m.name):
        h.update(m.name.encode())
        for v in m.vertices:h.update(str(tuple(v.co)).encode())
    return h.hexdigest()
before=mesh_hash();cam=[list(x) for x in s.camera.matrix_world]
poses={}
for f in range(1,194):
    s.frame_set(f)
    poses[f]={n:rig.pose.bones[n].matrix_basis.copy() for n in names}
s.frame_set(1)
hands={side:rig.pose.bones[side+'Hand'].matrix.copy() for side in ('Left','Right')}
feet={side:rig.matrix_world@rig.pose.bones[side+'Foot'].head for side in ('Left','Right')}
def smooth(a,b,t):
    q=max(0,min(1,(t-a)/(b-a)))
    return q*q*q*(q*(q*6-15)+10)
def event(t):return smooth(2.65,4.15,t)*(1-smooth(5.15,7.6,t))
def turn(name,axis,amount):
    pb=rig.pose.bones[name]
    axis=pb.bone.matrix_local.to_quaternion().inverted()@Vector(axis)
    pb.matrix_basis=pb.matrix_basis@Quaternion(axis,amount).to_matrix().to_4x4()
def point(n):return rig.matrix_world@rig.pose.bones[n].head
def aim(name,child,target):
    bpy.context.view_layer.update();pb=rig.pose.bones[name];a=pb.head.copy()
    direction=rig.pose.bones[child].head-a
    goal=rig.matrix_world.inverted()@Vector(target)-a
    q=direction.rotation_difference(goal)
    pb.matrix=Matrix.Translation(a)@q.to_matrix().to_4x4()@Matrix.Translation(-a)@pb.matrix
    bpy.context.view_layer.update()
def hold(side):
    up,lo,hand=side+'Arm',side+'ForeArm',side+'Hand'
    # Move the shoulder joint along its actual clavicle arc if the wrist lies
    # beyond arm reach. Preserve bone lengths instead of stretching the arm.
    c=rig.matrix_world@hands[side].translation
    for _ in range(4):
        a=point(up);l1=(point(lo)-a).length;l2=(point(hand)-point(lo)).length
        excess=(c-a).length-(l1+l2-.0001)
        if excess<=0:break
        target=a+(c-a).normalized()*min(.02,excess*3)
        aim(side+'Shoulder',up,target)
    a=point(up);c=rig.matrix_world@hands[side].translation
    axis=(c-a).normalized();l1=(point(lo)-a).length;l2=(point(hand)-point(lo)).length
    distance=min((c-a).length,l1+l2-.0001)
    along=(distance*distance+l1*l1-l2*l2)/(2*distance)
    height=math.sqrt(max(0,l1*l1-along*along))
    pole=Vector((-.85,.25,1.45) if side=='Left' else (-1.95,-.10,1.40))-a
    pole-=axis*pole.dot(axis);pole.normalize()
    aim(up,lo,a+axis*along+pole*height);aim(lo,hand,c)
    pb=rig.pose.bones[hand];m=hands[side].copy();m.translation=pb.head;pb.matrix=m
    bpy.context.view_layer.update()
    return (point(hand)-c).length
max_hand=0;max_foot=0
for frame in range(1,194):
    s.frame_set(frame)
    for n in names:rig.pose.bones[n].matrix_basis=poses[frame][n]
    t=(frame-1)/24;e=event(t)
    turn('Spine',(1,0,0),math.radians(-3)*e)
    turn('Chest',(0,0,1),math.radians(-6)*e)
    turn('Chest',(1,0,0),math.radians(.35)*math.sin(math.tau*t/4))
    bpy.context.view_layer.update()
    max_hand=max(max_hand,hold('Left'),hold('Right'))
    for side in ('Left','Right'):
        max_foot=max(max_foot,(point(side+'Foot')-feet[side]).length)
    for n in names:
        b=rig.pose.bones[n]
        for path in ('rotation_quaternion','location','scale'):
            b.keyframe_insert(data_path=path,frame=frame,group=n)
assert max_hand<.002,max_hand
assert max_foot<1e-5,max_foot
for a in bpy.data.actions:
    if a!=rig.animation_data.action:continue
    for layer in a.layers:
        for strip in layer.strips:
            for slot in a.slots:
                bag=strip.channelbag(slot)
                if bag:
                    for fc in bag.fcurves:
                        for key in fc.keyframe_points:key.interpolation='LINEAR'
s.frame_set(1)
assert before==mesh_hash() and cam==[list(x) for x in s.camera.matrix_world]
s.render.filepath=str(out/'b2-body-v5.png')
bpy.ops.wm.save_as_mainfile(filepath=str(dest))
report={'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'project':str(dest),'all_meshes_unchanged':True,'camera_unchanged':True,
        'max_hand_target_error_m':max_hand,'max_foot_drift_m':max_foot,
        'body_follow_seconds':[2.65,4.15,5.15,7.6],'face_animation':False,
        'owner_acceptance':'pending'}
(out/'b2-body-v5-authoring.json').write_text(json.dumps(report,indent=2)+'\n')
print('V5_AUTHOR',json.dumps(report),flush=True)
