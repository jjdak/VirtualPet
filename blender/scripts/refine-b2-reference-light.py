"""Bounded v6 lighting variants, inspired by reference/preview community workflows.

Run on saved v5, passing -- soft or -- focused. No model generation or migration.
"""
import bpy, hashlib, json, math, sys
from pathlib import Path
from mathutils import Vector

source=Path(bpy.data.filepath)
assert source.name=='courtyard-b2-body-v5.blend'
variant=sys.argv[sys.argv.index('--')+1]
assert variant in ('soft','focused')
out=source.parent
dest=out/f'courtyard-b2-reference-v6-{variant}.blend'
assert not dest.exists(), 'Preserve authored variants'
s=bpy.context.scene;s.frame_set(1)

def fingerprint():
    meshes=hashlib.sha256();actions=hashlib.sha256()
    for m in sorted(bpy.data.meshes,key=lambda m:m.name):
        meshes.update(m.name.encode())
        for v in m.vertices:meshes.update(str(tuple(v.co)).encode())
    for a in sorted(bpy.data.actions,key=lambda a:a.name):
        actions.update(a.name.encode())
        for layer in a.layers:
            for strip in layer.strips:
                for slot in a.slots:
                    bag=strip.channelbag(slot)
                    if bag:
                        for fc in bag.fcurves:
                            actions.update(str((fc.data_path,fc.array_index)).encode())
                            for k in fc.keyframe_points:
                                actions.update(str((tuple(k.co),tuple(k.handle_left),tuple(k.handle_right),k.interpolation)).encode())
    return {'meshes':meshes.hexdigest(),'actions':actions.hexdigest(),
            'camera': [list(r) for r in s.camera.matrix_world],
            'ortho_scale':s.camera.data.ortho_scale,
            'transforms':{o.name:[list(r) for r in o.matrix_world] for o in s.objects if o.type not in ('LIGHT',)},
            'packed_images':sum(bool(i.packed_file) for i in bpy.data.images)}

before=fingerprint()
def color(h):
    rgb=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    return tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb)+(1,)
def palette(name,colors):
    for n in bpy.data.materials[name].node_tree.nodes:
        if n.type=='VALTORGB':
            elements=sorted(n.color_ramp.elements,key=lambda e:e.position)
            assert len(elements)==len(colors)
            for e,c in zip(elements,colors):e.color=color(c)

# Compress small foliage highlights; keep existing animated leaf geometry.
for i,colors in enumerate([
    ['#435747','#77805a'],['#4c624b','#89936a'],
    ['#596547','#969b6b'],['#405e53','#71896d']]):
    m=bpy.data.materials[f'B1 Foliage {i}'];palette(m.name,colors)
    for n in m.node_tree.nodes:
        if n.type=='BSDF_PRINCIPLED':
            n.inputs['Roughness'].default_value=.93
            n.inputs['Specular IOR Level'].default_value=.18
        elif n.type=='BUMP':n.inputs['Strength'].default_value=.10

palette('B1 Limewash - broad quiet variation',['#9b9e92','#c4bda5','#e0d1b4'])
for i in range(4):palette('B1 Limestone '+str(i),['#a5a18f','#c8bea3','#e6d7b7'])
palette('B1 Pool bed - jade silt',['#397470','#729d90','#acbba0'])
bpy.data.materials['Backdrop - warm neutral'].node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=color('#d2cec2')

focused=variant=='focused'
sun=bpy.data.objects['B1 Afternoon sun']
sun.data.energy=4.7 if focused else 4.1
sun.data.color=(1,.88,.72)
sun.data.angle=math.radians(1.6 if focused else 3.5)
sun.rotation_euler=Vector((1.25,-2.8,-3.4)).to_track_quat('-Z','Y').to_euler()
s.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.18 if focused else .30
bpy.data.objects['B1 Soft sky fill'].data.energy=55 if focused else 90
bpy.data.objects['B2 - warm poolside bounce'].data.energy=190
bpy.data.objects['B2 V4 - soft character rim'].data.energy=180
s.view_settings.exposure=.20 if focused else .10
# No additional post-process grading: changes remain native editable lighting/materials.
assert fingerprint()==before,'Layout, camera, character and all actions must stay identical'
s['B2_v6_reference_pass']=variant
s.render.resolution_x=1280;s.render.resolution_y=720;s.render.resolution_percentage=100
s.cycles.samples=128;s.cycles.adaptive_threshold=.015;s.cycles.use_animated_seed=False
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='METAL';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='METAL'
s.cycles.device='GPU';s.cycles.use_denoising=True
s.render.filepath=str(out/f'b2-reference-v6-{variant}.png')
bpy.ops.wm.save_as_mainfile(filepath=str(dest))
report={'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'project':str(dest),'project_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),
        'variant':variant,'preserved':before,'geometry_actions_camera_preserved':True,
        'lights':[{ 'name':o.name,'energy':o.data.energy,'hidden_render':o.hide_render} for o in s.objects if o.type=='LIGHT'],
        'owner_acceptance':'pending','movie':'v5 is the motion baseline; v6 full movie not rendered'}
(out/f'b2-reference-v6-{variant}-authoring.json').write_text(json.dumps(report,indent=2)+'\n')
s.render.resolution_percentage=75;s.cycles.samples=32;s.cycles.adaptive_threshold=.025
s.render.filepath=str(out/f'b2-reference-v6-{variant}-draft.png')
bpy.ops.render.render(write_still=True)
print('V6_DRAFT_COMPLETE',variant,flush=True)
