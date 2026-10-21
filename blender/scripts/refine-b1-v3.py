"""Fix reversed leaf winding found in the v2 visual render."""
import bpy, bmesh, json, hashlib
from pathlib import Path
from mathutils import Vector

source=Path(bpy.data.filepath)
assert source.name=='courtyard-b1-v2.blend'
dest=source.with_name('courtyard-b1-v3.blend')
assert not dest.exists()
centers=[(-4.75,2.70,3.55),(-4.06,2.46,3.78),(-3.2,2.60,3.85),(-2.31,2.69,3.92),(-1.42,2.54,3.94),(-.68,2.43,3.82),(-2.28,1.03,3.44),(-1.64,.55,3.63),(-4.11,.98,2.88),(-2.,1.93,2.34)]
radii=[(.66,.52,.48),(.66,.53,.60),(.68,.58,.58),(.67,.62,.47),(.70,.54,.49),(.50,.48,.40),(.76,.57,.49),(.47,.5,.41),(.66,.46,.41),(.50,.46,.37)]
for j,(c,rad) in enumerate(zip(centers,radii)):
    mesh=bpy.data.objects['Canopy cluster %02d'%j].data
    bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.reverse_faces(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
    normals=[]
    for v in mesh.vertices:
        direction=Vector(tuple((v.co[k]-c[k])/rad[k] for k in range(3))).normalized()
        normals.append(Vector((direction.x*.42,direction.y*.42,.85+direction.z*.4)).normalized())
    mesh.normals_split_custom_set_from_vertices(normals);mesh.update()
bpy.context.scene.render.filepath=str(source.with_name('b1-v3-preview.png'))
bpy.data.texts['B1 ART PASS - decisions and sources'].write('\nV3 fixes canopy face winding reversed by the v2 leaf tangent basis; keeps the crown volumes and other v2 art changes.\n')
bpy.ops.wm.save_as_mainfile(filepath=str(dest))
source.with_name('b1-v3-change-report.json').write_text(json.dumps({'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'output':str(dest),'fix':'Reverse canopy face winding; rebuild matching custom normals','owner_visual_acceptance':'pending'},indent=2))
bpy.ops.render.render(write_still=True)
