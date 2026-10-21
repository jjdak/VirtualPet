"""Historical controlled reproduction; writes diagnostic outputs, does not replace source frames.
Pass -- 1 2 101 157. See b2-v5-sampling-repair.json for verified replacements.
"""
import bpy
from pathlib import Path
s=bpy.context.scene;s.frame_set(1)
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='METAL';prefs.get_devices()
for d in prefs.devices:d.use=d.type=='METAL'
s.cycles.device='GPU';s.cycles.samples=128;s.cycles.adaptive_threshold=.015
s.render.resolution_percentage=100;s.render.filepath='/tmp/vp-v5-warm.png'
bpy.ops.render.render(write_still=True)
script=Path('blender/scripts/render-b2-preview.py').read_text().replace("'frames-body-v5'","'frames-body-v5-warm-repair'")
exec(compile(script,'render-b2-preview.py','exec'))
