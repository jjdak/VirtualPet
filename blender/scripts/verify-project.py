"""Read-only acceptance of the saved migration; never writes the .blend."""
import bpy
import json
from pathlib import Path
from mathutils import Quaternion

scene = bpy.context.scene
output = Path(bpy.data.filepath).parent
assert scene.camera and scene.camera.data.type == 'ORTHO'
assert abs(scene.camera.data.ortho_scale - 8.5/.95*16/9) < 1e-4
rigs = [o for o in scene.objects if o.type == 'ARMATURE']
assert len(rigs) == 1
rig = rigs[0]
faces = [o for o in scene.objects if o.type == 'MESH' and o.data.shape_keys]
assert faces
def vertices():
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    result = []
    for o in faces:
        ev = o.evaluated_get(depsgraph)
        mesh = ev.to_mesh()
        result.extend(ev.matrix_world @ v.co for v in mesh.vertices)
        ev.to_mesh_clear()
    return result
def distance(a,b): return max((x-y).length for x,y in zip(a,b))

baseline = vertices()
changed = []
for o in faces:
    key = o.data.shape_keys.key_blocks.get('Face_Blendshape.Fcl_EYE_Close')
    if key:
        changed.append((key,key.value));key.value = 1
blink_delta = distance(baseline, vertices())
for key,value in changed: key.value = value
assert blink_delta > .001, f'Blink not deforming vertices: {blink_delta}'
baseline = vertices()
head = rig.pose.bones.get('J_Bip_C_Head')
assert head, 'Original skinned head bone missing'
old_matrix = head.matrix_basis.copy()
head.rotation_mode = 'QUATERNION'
head.rotation_quaternion = head.rotation_quaternion @ Quaternion((0,1,0), .20)
head_delta = distance(baseline, vertices())
head.matrix_basis = old_matrix
assert head_delta > .005, f'Head not deforming vertices: {head_delta}'
images = [i for i in bpy.data.images if i.type == 'IMAGE']
assert images and all(i.packed_file and min(i.size)>0 for i in images)
assert len([o for o in scene.objects if o.name.startswith('Tree_Leaf_Cards')]) == 1
assert bpy.data.objects.get('Water')
report = {'file':bpy.data.filepath,'reopened':True,'camera_ortho_scale':scene.camera.data.ortho_scale,
          'rig_bones':len(rig.data.bones),'shape_key_meshes':len(faces),'packed_images':len(images),
          'blink_vertex_displacement_m':blink_delta,'head_vertex_displacement_m':head_delta,
          'result':'pass','scope':'saved geometry, skinning and morph editability; no animation or aesthetic acceptance'}
report_name = 'reopen-verification.json' if Path(bpy.data.filepath).name == 'courtyard.blend' else Path(bpy.data.filepath).stem + '-verification.json'
(output/report_name).write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(report))
