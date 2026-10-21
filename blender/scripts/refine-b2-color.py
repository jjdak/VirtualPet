"""Continue saved B2: color/value hierarchy only; preserve geometry and actions."""
import bpy, hashlib, json, math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'PrivateAssets/Courtyard/Blender/B2'
source = Path(bpy.data.filepath)
assert source.name == 'courtyard-b2-light-motion-v1.blend'
dest = OUT / 'courtyard-b2-color-v2.blend'
assert not dest.exists(), 'Keep authored versions'
s = bpy.context.scene
s.frame_set(1)

def geometry_digest():
    h = hashlib.sha256()
    for m in sorted(bpy.data.meshes, key=lambda x: x.name):
        h.update(m.name.encode())
        for v in m.vertices:
            h.update(str(tuple(v.co)).encode())
    return h.hexdigest()

def action_digest():
    h = hashlib.sha256()
    for a in sorted(bpy.data.actions, key=lambda x: x.name):
        h.update(a.name.encode())
        for layer in a.layers:
            for strip in layer.strips:
                for slot in a.slots:
                    bag = strip.channelbag(slot)
                    if bag:
                        for fc in bag.fcurves:
                            h.update(str((fc.data_path, fc.array_index)).encode())
                            for k in fc.keyframe_points:
                                h.update(str((tuple(k.co), k.interpolation)).encode())
    return h.hexdigest()

def camera_state():
    return {'matrix': [list(r) for r in s.camera.matrix_world], 'ortho_scale': s.camera.data.ortho_scale}

def color(value):
    v = [int(value[i:i+2], 16)/255 for i in (1, 3, 5)]
    return tuple(x/12.92 if x <= .04045 else ((x+.055)/1.055)**2.4 for x in v)+(1,)

def palette(name, colors):
    for n in bpy.data.materials[name].node_tree.nodes:
        if n.type == 'VALTORGB':
            elements = sorted(n.color_ramp.elements, key=lambda e: e.position)
            assert len(elements) == len(colors), name
            for e, c in zip(elements, colors):
                e.color = color(c)

before = {'geometry': geometry_digest(), 'actions': action_digest(), 'camera': camera_state()}
sun = bpy.data.objects['B1 Afternoon sun']
sun.data.energy = 3.8
sun.data.color = (1, .84, .65)
sun.data.angle = math.radians(2.2)
sun.rotation_euler = Vector((.8, -2.6, -4)).to_track_quat('-Z', 'Y').to_euler()
bg = s.world.node_tree.nodes['Background']
bg.inputs['Color'].default_value = (.36, .55, .76, 1)
bg.inputs['Strength'].default_value = .32
fill = bpy.data.objects['B1 Soft sky fill']
fill.data.energy = 95
fill.data.color = (.62, .78, 1)
bounce = bpy.data.objects['B2 - warm poolside bounce']
bounce.data.energy = 160
bounce.data.color = (1, .86, .72)
bounce.data.size = 2.4
s.view_settings.exposure = .10

for i in range(4):
    palette('B1 Limestone '+str(i), ['#a7a493', '#c6bea7', '#e2d5b8'])
palette('B1 Limewash - broad quiet variation', ['#a3a497', '#c5bfaa', '#e3d7bc'])
palette('B1 Pool bed - jade silt', ['#477f7c', '#74a299', '#b0c3a5'])
palette('B1 Bark - muted warm grey', ['#39483e', '#656d56', '#939174'])
for i, colors in enumerate([
    ['#304e3b', '#708c4f'], ['#425b3d', '#879957'],
    ['#5b6938', '#a3ac60'], ['#2d5146', '#668c64'],
]):
    palette('B1 Foliage '+str(i), colors)
bpy.data.materials['Backdrop - warm neutral'].node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = color('#c6c7bf')

after = {'geometry': geometry_digest(), 'actions': action_digest(), 'camera': camera_state()}
assert before == after
assert s.frame_end == 192 and s.render.fps == 24
s.render.resolution_x = 1280
s.render.resolution_y = 720
s.render.resolution_percentage = 100
s.cycles.samples = 96
s.cycles.adaptive_threshold = .02
s.render.filepath = str(OUT / 'b2-color-v2.png')
prefs = bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type = 'METAL'
prefs.get_devices()
for device in prefs.devices:
    device.use = device.type == 'METAL'
s.cycles.device = 'GPU'
bpy.ops.wm.save_as_mainfile(filepath=str(dest))
report = {'source': str(source), 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
          'project': str(dest), 'preserved': after, 'native_actions': len(bpy.data.actions),
          'packed_images': sum(bool(i.packed_file) for i in bpy.data.images),
          'scope': 'Native lights and environment material palettes only; original character untouched',
          'visual_acceptance': 'pending', 'movie': 'v1 remains previous look; v2 not rendered as movie'}
(OUT / 'b2-color-v2-verification.json').write_text(json.dumps(report, indent=2)+'\n')
s.cycles.samples = 32
s.render.resolution_percentage = 75
s.render.filepath = str(OUT / 'b2-color-v2-draft.png')
bpy.ops.render.render(write_still=True)
print('B2_COLOR_DRAFT_COMPLETE', flush=True)
