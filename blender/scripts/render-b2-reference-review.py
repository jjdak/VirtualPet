"""Reopen selected art study, check its fingerprint, render three native review poses."""
import ast,bpy,hashlib,json
from pathlib import Path
p=Path(bpy.data.filepath);out=p.parent
profiles={'courtyard-b2-reference-v6-focused.blend':('b2-reference-v6-focused','b2-reference-v6-review','preserved'),
          'courtyard-b2-canopy-v7-balanced.blend':('b2-canopy-v7-balanced','b2-canopy-v7-review','fingerprint')}
assert p.name in profiles
stem,review_name,fingerprint_key=profiles[p.name]
report=json.loads((out/(stem+'-authoring.json')).read_text())
s=bpy.context.scene;s.frame_set(1)
# Reuse only the pure fingerprint function, never execute the authoring module.
tree=ast.parse(Path(__file__).with_name('refine-b2-reference-light.py').read_text())
fn=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='fingerprint')
exec(compile(ast.Module(body=[fn],type_ignores=[]),'<fingerprint>','exec'))
assert fingerprint()==report[fingerprint_key]
assert hashlib.sha256(p.read_bytes()).hexdigest()==report['project_sha256']
assert hashlib.sha256(Path(report['source']).read_bytes()).hexdigest()==report['source_sha256']
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='METAL';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='METAL'
s.cycles.device='GPU';s.cycles.use_animated_seed=False
s.cycles.samples=128;s.cycles.adaptive_threshold=.015
s.render.resolution_percentage=100
files=[]
for frame in [1,101,193]:
    s.frame_set(frame)
    path=out/(stem+'.png' if frame==1 else f'{stem}-f{frame:03d}.png')
    assert not path.exists()
    s.render.filepath=str(path);bpy.ops.render.render(write_still=True)
    files.append({'frame':frame,'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
(out/(review_name+'.json')).write_text(json.dumps({'project':str(p),'project_sha256':report['project_sha256'],'reopened':True,'source_unchanged':True,'authored_fingerprint_matches':True,'preservation_scope':'all meshes in v6; noncanopy meshes in v7; camera/layout/actions in both','renders':files,'resolution':[1280,720],'samples':128,'owner_acceptance':'pending','full_movie':'not rendered; v5 retained as motion baseline'},indent=2)+'\n')
