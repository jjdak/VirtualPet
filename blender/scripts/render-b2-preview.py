"""Render native B2 actions; resumable frames, no writes to the authored .blend."""
import bpy, json, sys, time, hashlib
from pathlib import Path

p=Path(bpy.data.filepath)
profiles={'courtyard-b2-light-motion-v1.blend':'frames-v1',
          'courtyard-b2-presence-v4.blend':'frames-presence-v4',
          'courtyard-b2-body-v5.blend':'frames-body-v5'}
assert p.name in profiles
refined=p.name!='courtyard-b2-light-motion-v1.blend'
out=p.parent/profiles[p.name];out.mkdir(exist_ok=True)
s=bpy.context.scene
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='METAL';prefs.get_devices()
for device in prefs.devices:device.use=device.type=='METAL'
s.cycles.device='GPU';s.cycles.samples=48 if refined else 24;s.cycles.use_denoising=True
s.cycles.use_adaptive_sampling=True;s.cycles.adaptive_threshold=.02 if refined else .05
s.cycles.use_animated_seed=False
s.render.use_persistent_data=True
s.render.resolution_x=960;s.render.resolution_y=540;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.render.image_settings.color_mode='RGB'
config={'project_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'samples':s.cycles.samples,'resolution':[960,540],'adaptive_threshold':s.cycles.adaptive_threshold,'fps':24}
manifest=out/'render-config.json'
if manifest.exists():assert json.loads(manifest.read_text())==config,'Do not mix render versions/settings'
else:
    if refined:assert not list(out.glob('*.png')),'Missing resume manifest'
    manifest.write_text(json.dumps(config,indent=2))
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
frames=[int(x) for x in args] if args else range(1,193)
start=time.monotonic();rendered=[]
for frame in frames:
    target=out/f'{frame:04d}.png'
    if target.exists():continue
    s.frame_set(frame);s.render.filepath=str(target)
    begin=time.monotonic();bpy.ops.render.render(write_still=True)
    rendered.append(frame)
    print('B2_FRAME',frame,round(time.monotonic()-begin,3),'seconds',flush=True)
report={'project':str(p),'frames_rendered_this_run':rendered,'elapsed_seconds':time.monotonic()-start,'resolution':[960,540],'samples':s.cycles.samples,'engine':'Cycles Metal','fps':24}
(out/'last-render-run.json').write_text(json.dumps(report,indent=2))
