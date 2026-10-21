"""P8: compare thin-leaf shading and a narrower existing leaf silhouette."""
import ast,bpy,hashlib,json,sys
from pathlib import Path
from mathutils import Vector

p=Path(bpy.data.filepath);out=p.parent
assert p.name=='courtyard-b2-reference-v6-focused.blend'
mode=sys.argv[sys.argv.index('--')+1];assert mode in ('soft','slender','balanced')
dest=out/f'courtyard-b2-canopy-v7-{mode}.blend'
assert not dest.exists()
s=bpy.context.scene;s.frame_set(1)
tree=ast.parse(Path(__file__).with_name('refine-b2-reference-light.py').read_text())
fn=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='fingerprint')
exec(compile(ast.Module(body=[fn],type_ignores=[]),'<fingerprint>','exec'))
before=fingerprint()
protected={m.name:hashlib.sha256(str([tuple(v.co) for v in m.vertices]).encode()).hexdigest()
           for m in bpy.data.meshes if not m.name.startswith('Canopy cluster ')}
for i in range(4):
    m=bpy.data.materials[f'B1 Foliage {i}'];t=m.node_tree
    bs=next(n for n in t.nodes if n.type=='BSDF_PRINCIPLED')
    surface=next(n for n in t.nodes if n.type=='OUTPUT_MATERIAL')
    color_link=next(l for l in t.links if l.to_socket==bs.inputs['Base Color'])
    translucent=t.nodes.new('ShaderNodeBsdfTranslucent');translucent.name='V7 Thin leaf transmission'
    t.links.new(color_link.from_socket,translucent.inputs['Color'])
    mix=t.nodes.new('ShaderNodeMixShader');mix.name='V7 Leaf body and transmitted light'
    mix.inputs[0].default_value=.26
    t.links.new(bs.outputs[0],mix.inputs[1]);t.links.new(translucent.outputs[0],mix.inputs[2])
    t.links.new(mix.outputs[0],surface.inputs['Surface'])
    bs.inputs['Specular IOR Level'].default_value=.12

counts=[]
for o in (o for o in s.objects if o.name.startswith('Canopy cluster ')):
    m=o.data;assert len(m.vertices)%13==0
    if mode in ('slender','balanced'):
        for start in range(0,len(m.vertices),13):
            points=[m.vertices[start+i].co.copy() for i in range(13)]
            center=sum(points[1:],Vector())/12
            u=(points[1]-points[7]).normalized()
            v=(points[4]-points[10]).normalized();v=(v-u*v.dot(u)).normalized()
            for i,point in enumerate(points):
                delta=point-center
                m.vertices[start+i].co=point-u*(delta.dot(u)*.06)-v*(delta.dot(v)*(.18 if mode=='balanced' else .32))
        m.update()
    counts.append({'object':o.name,'leaves':len(m.vertices)//13,'vertices':len(m.vertices)})
if mode=='balanced':
    light=bpy.data.lights.new('V7 canopy sky bounce','AREA')
    light.energy=220;light.color=(.78,.87,1);light.shape='DISK';light.size=4
    obj=bpy.data.objects.new(light.name,light);s.collection.objects.link(obj)
    obj.location=(-4,-1,5)
    obj.rotation_euler=(Vector((-2.8,2,3.4))-obj.location).to_track_quat('-Z','Y').to_euler()
    receivers=bpy.data.collections.new('V7 canopy only bounce receivers')
    for leaf in (o for o in s.objects if o.name.startswith('Canopy cluster ')):receivers.objects.link(leaf)
    obj.light_linking.receiver_collection=receivers
after=fingerprint()
assert all(after[k]==before[k] for k in ('actions','camera','ortho_scale','transforms','packed_images'))
assert protected=={m.name:hashlib.sha256(str([tuple(v.co) for v in m.vertices]).encode()).hexdigest()
                   for m in bpy.data.meshes if not m.name.startswith('Canopy cluster ')}
if mode=='soft':assert before['meshes']==after['meshes']
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='METAL';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='METAL'
s.cycles.device='GPU';s.cycles.samples=128;s.cycles.adaptive_threshold=.015
s.render.resolution_percentage=100;s.render.filepath=str(out/f'b2-canopy-v7-{mode}.png')
bpy.ops.wm.save_as_mainfile(filepath=str(dest))
report={'source':str(p),'source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
        'project':str(dest),'project_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),
        'preserved_noncanopy_meshes':protected,'fingerprint':after,'leaf_clusters':counts,
        'variant':mode,'translucency_mix':.26,'leaf_width_multiplier':{'slender':.68,'balanced':.82,'soft':1}[mode],
        'leaf_length_multiplier':1 if mode=='soft' else .94,'canopy_fill_watts':220 if mode=='balanced' else 0,'owner_acceptance':'pending'}
(out/f'b2-canopy-v7-{mode}-authoring.json').write_text(json.dumps(report,indent=2)+'\n')
s.render.resolution_percentage=75;s.cycles.samples=32;s.cycles.adaptive_threshold=.025
s.render.filepath=str(out/f'b2-canopy-v7-{mode}-draft.png');bpy.ops.render.render(write_still=True)
