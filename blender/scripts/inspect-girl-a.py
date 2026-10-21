"""Inspect owner-supplied GirlA without mesh edits; save a separate rig review scene."""
import bpy
import hashlib
import json
import math
from pathlib import Path
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'PrivateAssets/Courtyard/Characters/GirlA'
SOURCE = OUT / '6309260419351179234.vrm.glb'
PROJECT = OUT / 'girl-a-rig-review.blend'
if PROJECT.exists():
    raise RuntimeError('Review already exists; do not overwrite artist edits')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
scene = bpy.context.scene
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
meshes = [o for o in scene.objects if o.type == 'MESH' and o.parent == rig]
helpers = {b.custom_shape for b in rig.pose.bones if b.custom_shape}
for o in helpers:
    o.hide_render = True
    o.hide_set(True)

def coordinates():
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    result = {}
    for o in meshes:
        ev = o.evaluated_get(dg)
        m = ev.to_mesh()
        result[o.name] = [ev.matrix_world @ v.co for v in m.vertices]
        ev.to_mesh_clear()
    return result

def rotate(name, axis, degrees):
    bone = rig.pose.bones[name]
    bone.rotation_mode = 'QUATERNION'
    local_axis = bone.bone.matrix_local.to_quaternion().inverted() @ Vector(axis)
    bone.rotation_quaternion = Quaternion(local_axis, math.radians(degrees))

report = {'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
          'blender': bpy.app.version_string, 'bones': len(rig.data.bones),
          'mesh_vertices': {o.name: len(o.data.vertices) for o in meshes},
          'shape_keys': {o.name: list(o.data.shape_keys.key_blocks.keys()) if o.data.shape_keys else [] for o in meshes},
          'eye_bones': [b.name for b in rig.data.bones if 'eye' in b.name.lower()],
          'deformation_probes': {}}
for name, axis, degrees in [('Head', (0,0,1), 18), ('LeftArm', (0,1,0), -40),
                            ('LeftLeg', (1,0,0), -35), ('LeftHandIndex1', (0,1,0), -25)]:
    before = coordinates()
    bone = rig.pose.bones[name]
    old = bone.matrix_basis.copy()
    rotate(name, axis, degrees)
    after = coordinates()
    delta = {o.name: max((a-b).length for a,b in zip(before[o.name], after[o.name])) for o in meshes}
    assert max(delta.values()) > 0.0001, (name, delta)
    report['deformation_probes'][name] = {'degrees': degrees, 'max_displacement_m': delta}
    bone.matrix_basis = old

# Preserve original textures and mesh topology; adapt only shading to studio lights.
for m in {m for o in meshes for m in o.data.materials}:
    tree = m.node_tree
    texture = next(n.image for n in tree.nodes if n.type == 'TEX_IMAGE')
    tree.nodes.clear()
    output = tree.nodes.new('ShaderNodeOutputMaterial')
    bs = tree.nodes.new('ShaderNodeBsdfPrincipled')
    tex = tree.nodes.new('ShaderNodeTexImage'); tex.image = texture
    bs.inputs['Roughness'].default_value = .85
    bs.inputs['Specular IOR Level'].default_value = .18
    tree.links.new(tex.outputs['Color'], bs.inputs['Base Color'])
    tree.links.new(bs.outputs['BSDF'], output.inputs['Surface'])

# Make a comparison copy, preserving independent pose controls.
copy_rig = rig.copy(); copy_rig.data = rig.data.copy()
scene.collection.objects.link(copy_rig); copy_rig.name = 'GirlA - source T pose'
for o in meshes:
    duplicate = o.copy(); duplicate.data = o.data.copy()
    scene.collection.objects.link(duplicate); duplicate.parent = copy_rig
    for mod in duplicate.modifiers:
        if mod.type == 'ARMATURE': mod.object = copy_rig
copy_rig.location.x = -.57
rig.name = 'GirlA - pose check'
rig.location.x = .57
rotate('LeftArm', (0,1,0), -68)
rotate('RightArm', (0,1,0), 68)
rotate('Head', (0,0,1), 18)

def material(name, color):
    m = bpy.data.materials.new(name); m.diffuse_color = (*color,1); m.use_nodes = True
    m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (*color,1)
    m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 1
    return m

bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,-.015))
bpy.context.object.name = 'Review backdrop'
bpy.context.object.data.materials.append(material('Warm grey', (.52,.53,.49)))
world = bpy.data.worlds.new('Soft studio'); world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (.8,.85,1,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value = .6
scene.world = world
for name, pos, power, size in [('Key',(-2,3,4),350,3),('Fill',(2,1,2),100,3)]:
    data = bpy.data.lights.new(name,'AREA'); data.energy = power; data.shape = 'DISK'; data.size = size
    obj = bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location = pos
    obj.rotation_euler = (Vector((0,0,.65))-obj.location).to_track_quat('-Z','Y').to_euler()
data = bpy.data.cameras.new('Review camera'); camera = bpy.data.objects.new('Review camera',data)
scene.collection.objects.link(camera);scene.camera = camera
camera.location = (0,4,1.55)
camera.rotation_euler = (Vector((0,0,.60))-camera.location).to_track_quat('-Z','Y').to_euler()
data.type = 'ORTHO';data.ortho_scale = 2.45
scene.render.engine = 'CYCLES'; scene.cycles.samples = 32;scene.cycles.use_denoising = True
scene.render.resolution_x = 1200;scene.render.resolution_y = 760;scene.render.resolution_percentage = 100
scene.view_settings.view_transform = 'AgX'
scene.render.image_settings.file_format = 'PNG'
scene.render.filepath = str(OUT/'girl-a-rig-review.png')
scene['scope'] = 'Original T pose (image right), relaxed arms and head turn (image left). No authored mesh, no blink or gaze controls, no animation.'
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'VIEW_3D':
            area.spaces.active.region_3d.view_perspective = 'CAMERA'
            area.spaces.active.overlay.show_overlays = False
bpy.ops.file.pack_all()
report['images'] = [{'name':i.name,'packed':bool(i.packed_file),'size':list(i.size)} for i in bpy.data.images if i.type=='IMAGE']
report['result'] = 'body_skinning_pass; blink_and_independent_gaze_missing; not_ready_for_target_performance'
report['project'] = str(PROJECT)
report['animation_authored'] = False
report['source_meshes_modified'] = False
(OUT/'rig-verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(PROJECT))
bpy.ops.render.render(write_still=True)
print(json.dumps(report,ensure_ascii=False))
