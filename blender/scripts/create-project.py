"""One-time migration to editable Blender. Never rerun over an artist's edited file."""
import bpy
import json
import math
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'PrivateAssets/Courtyard/Blender'
args = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
OUTPUT = Path(args[0]) if args else ASSETS / 'courtyard.blend'
if OUTPUT.exists():
    raise RuntimeError(f'Refusing to overwrite editable project: {OUTPUT}')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ASSETS / 'source.glb'))
scene = bpy.context.scene
scene.name = 'Quiet Courtyard'
scene.unit_settings.system = 'METRIC'
scene.render.engine = 'CYCLES'
scene.cycles.samples = 32
scene.cycles.use_denoising = True
scene.cycles.max_bounces = 8
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.fps = 24
scene.frame_start = 1
scene.frame_end = 240
scene.view_settings.view_transform = 'AgX'
scene.view_settings.exposure = 0
scene.render.film_transparent = False

def collection(name):
    c = bpy.data.collections.new(name)
    scene.collection.children.link(c)
    return c

env_collection = collection('01 Courtyard - editable meshes')
char_collection = collection('02 Character - rig and expressions')
light_collection = collection('03 Lighting and camera')
helper_collection = collection('04 Rig helpers - not rendered')
helper_collection.hide_render = True
helper_collection.hide_viewport = True
custom_shapes = {b.custom_shape for o in scene.objects if o.type == 'ARMATURE' for b in o.pose.bones if b.custom_shape}
def move(obj, target):
    for c in list(obj.users_collection): c.objects.unlink(obj)
    target.objects.link(obj)

for obj in list(scene.objects):
    if obj in custom_shapes:
        move(obj, helper_collection)
        obj.hide_render = True
        continue
    ancestor = obj
    is_character = False
    while ancestor:
        if ancestor.name == 'Character': is_character = True
        ancestor = ancestor.parent
    move(obj, char_collection if is_character or obj.type == 'ARMATURE' else env_collection)
    if obj.type == 'CAMERA':
        scene.camera = obj
        move(obj, light_collection)
if scene.camera is None: raise RuntimeError('Approved camera missing')
scene.camera.data.lens = 50
# Transfer exporter does not preserve the Three camera zoom/frustum convention.
# Use the separately recorded visible vertical span, with Blender's horizontal fit.
metadata = json.loads((ASSETS / 'source.json').read_text())
scene.camera.data.sensor_fit = 'HORIZONTAL'
scene.camera.data.ortho_scale = metadata['camera']['verticalSpan'] * metadata['camera']['aspect']

world = bpy.data.worlds.new('Warm paper / cool ambient')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (.72, .80, .85, 1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value = .45
scene.world = world

def area(name, pos, energy, color, size, target=(0,0,0)):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy, data.color, data.shape, data.size = energy, color, 'DISK', size
    obj = bpy.data.objects.new(name, data)
    light_collection.objects.link(obj)
    obj.location = pos
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
    return obj

area('Key - soft afternoon', (-3,-4,8), 1400, (1,.86,.68), 4.0, (-1,0,0))
area('Fill - courtyard sky', (3,2,6), 450, (.73,.84,1), 5.0, (-1,0,1))

def principled(name, color, roughness):
    m = bpy.data.materials.new(name);m.use_nodes = True
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*color,1)
    bs.inputs['Roughness'].default_value = roughness
    return m, bs

water = bpy.data.objects.get('Water')
if water is None: raise RuntimeError('Water mesh missing')
water_mat, bs = principled('Water - native Blender / migration baseline', (.19,.34,.29), .20)
bs.inputs['Transmission Weight'].default_value = .55
bs.inputs['IOR'].default_value = 1.333
nodes = water_mat.node_tree.nodes;links = water_mat.node_tree.links
noise = nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value = 4
noise.inputs['Detail'].default_value = 2
bump = nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value = .12;bump.inputs['Distance'].default_value = .035
links.new(noise.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs['Normal'],bs.inputs['Normal'])
water.data.materials.clear();water.data.materials.append(water_mat)

# A render backdrop under the original finite plinth; does not change its layout.
bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,-.365))
ground = bpy.context.object;ground.name = 'Backdrop - studio ground';move(ground,light_collection)
ground_mat, _ = principled('Backdrop - warm neutral', (.76,.74,.66), 1)
ground.data.materials.append(ground_mat)

readme = bpy.data.texts.new('START HERE - project status')
readme.write('Blender is now the production source.\n'
 'This is a migration baseline, not final art acceptance.\n'
 'Approved complete layout and camera preserved.\n'
 'Character mesh, armature, skinning and expression shape keys imported.\n'
 'MToon converted to Principled-compatible materials; water and lighting rebuilt.\n'
 'JavaScript interactions, procedural breathing, hand IK solver and spring physics\n'
 'are NOT native Blender animation. The seated pose is the migration checkpoint.\n'
 'Continue editing this .blend and Save As a new version.\n'
 'Do not rerun the migration script over artist edits.\n'
 'Private model embedded: keep this file under PrivateAssets.\n')
provenance = bpy.data.texts.new('Source transfer metadata.json')
provenance.write((ASSETS / 'source.json').read_text())

for screen in bpy.data.screens:
    for area_view in screen.areas:
        if area_view.type == 'VIEW_3D':
            space = area_view.spaces.active
            space.region_3d.view_perspective = 'CAMERA'
            space.overlay.show_overlays = False
            space.shading.type = 'MATERIAL'
            space.clip_end = 500

bpy.ops.object.select_all(action='DESELECT')
scene.camera.select_set(True);bpy.context.view_layer.objects.active = scene.camera
bpy.ops.file.pack_all()
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT))

report = {
 'blender': bpy.app.version_string, 'file': str(OUTPUT),
 'objects': len(scene.objects), 'meshes': sum(o.type=='MESH' for o in scene.objects),
 'armatures': {o.name:len(o.data.bones) for o in scene.objects if o.type=='ARMATURE'},
 'shape_keys': {o.name:list(o.data.shape_keys.key_blocks.keys()) for o in scene.objects if o.type=='MESH' and o.data.shape_keys},
 'images': [{'name':i.name,'packed':bool(i.packed_file),'size':list(i.size)} for i in bpy.data.images if i.type=='IMAGE'],
 'camera': {'name':scene.camera.name,'type':scene.camera.data.type,'ortho_scale':scene.camera.data.ortho_scale},
 'animation_status': 'seated pose only; runtime actions not migrated',
 'subjective_acceptance': 'pending',
}
(ASSETS / 'migration-report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
scene.render.filepath = str(ASSETS / 'migration-preview.png')
bpy.ops.render.render(write_still=True)
