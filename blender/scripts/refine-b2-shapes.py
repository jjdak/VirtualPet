"""Refine existing environmental silhouettes; keep character, camera and actions."""
import bpy, math, random, hashlib, json
from pathlib import Path
from mathutils import Vector

source = Path(bpy.data.filepath)
assert source.name == 'courtyard-b2-color-v2.blend'
out = source.parent
dest = out/'courtyard-b2-shapes-v3.blend'
assert not dest.exists(), 'Preserve authored versions'
s = bpy.context.scene
s.frame_set(1)

def protected():
    h = hashlib.sha256()
    rig = bpy.data.objects['GirlA - courtyard rig']
    for o in sorted((o for o in s.objects if o.type == 'MESH' and o.parent == rig), key=lambda o:o.name):
        h.update(o.name.encode())
        for v in o.data.vertices: h.update(str(tuple(v.co)).encode())
    actions = hashlib.sha256()
    for a in sorted(bpy.data.actions, key=lambda a:a.name):
        actions.update(a.name.encode())
        for layer in a.layers:
            for strip in layer.strips:
                for slot in a.slots:
                    bag = strip.channelbag(slot)
                    if bag:
                        for fc in bag.fcurves:
                            actions.update(str((fc.data_path,fc.array_index)).encode())
                            for k in fc.keyframe_points: actions.update(str((tuple(k.co),k.interpolation)).encode())
    seats = {o.name:[tuple(v.co) for v in o.data.vertices] for o in s.objects if o.name.startswith('Seat limestone ')}
    return {'character':h.hexdigest(),'actions':actions.hexdigest(),'seats':seats,
            'camera':[list(r) for r in s.camera.matrix_world], 'scale':s.camera.data.ortho_scale}

before = protected()
leaf_count = 0
for j, o in enumerate(sorted((o for o in s.objects if o.name.startswith('Canopy cluster ')), key=lambda o:o.name)):
    old = o.data
    assert len(old.vertices)%7 == 0
    center = sum((v.co for v in old.vertices), Vector())/len(old.vertices)
    verts=[]; faces=[]; normals=[]; indices=[]
    rng=random.Random(10200+j)
    for start in range(0,len(old.vertices),7):
        p=[old.vertices[start+k].co.copy() for k in range(7)]
        pos=(p[0]+p[3])*.5
        u=(p[3]-p[0]).normalized()
        v=(p[4]-p[2]).normalized()
        v=(v-u*v.dot(u)).normalized()
        normal=u.cross(v).normalized()
        if normal.z < 0: v=-v; normal=-normal
        length=(p[3]-p[0]).length*.58
        width=(p[4]-p[2]).length*.57
        base=len(verts)
        # A gently curved oval replaces the six-corner folded diamond.
        verts.append(pos+normal*.007)
        for k in range(12):
            a=math.tau*k/12
            verts.append(pos+u*(math.cos(a)*length)+v*(math.sin(a)*width)-normal*(.006*abs(math.cos(a))))
        smooth=Vector(((pos.x-center.x)*.25,(pos.y-center.y)*.25,1)).normalized()
        normals.extend([smooth]*13)
        # Coherent crown color instead of a per-leaf checkerboard.
        mat=1 if pos.z>center.z+.15 else 0
        if rng.random()<.06: mat=2
        for k in range(12):
            faces.append((base,base+1+k,base+1+(k+1)%12));indices.append(mat)
        leaf_count+=1
    mesh=bpy.data.meshes.new(o.name+' - curved oval v3')
    mesh.from_pydata(verts,[],faces)
    for m in old.materials: mesh.materials.append(m)
    for p,idx in zip(mesh.polygons,indices): p.material_index=idx;p.use_smooth=True
    mesh.update();mesh.normals_split_custom_set_from_vertices(normals)
    o.data=mesh

stone_count=0
for o in sorted(s.objects,key=lambda o:o.name):
    if not o.name.startswith(('Limestone block ','Riser stone ','Corner cap ')): continue
    old=o.data
    assert len(old.vertices)==16, o.name
    rng=random.Random(o.name+' shapes-v3')
    bottom=[v.co.copy() for v in old.vertices[:8]]
    top=[v.co.copy() for v in old.vertices[8:16]]
    z0=min(v.z for v in bottom);z1=max(v.z for v in top)
    height=z1-z0
    # Keep overall stone positions; recess small shoulders, not seat surfaces.
    ring=[]
    for i in range(8):
        a=top[i];b=top[(i+1)%8]
        edge=b-a; inward=Vector((-edge.y,edge.x,0)).normalized()
        for k in range(4):
            t=k/4
            p=a.lerp(b,t)
            p+=inward*rng.uniform(.001,.018)
            ring.append(p)
    verts=[];n=len(ring)
    for level in range(3):
        for p in ring:
            q=p.copy()
            if level==0: q.z=z0
            elif level==1: q.z=z1-min(.026,height*.16)
            else:
                toward=Vector((-q.x,-q.y,0)).normalized()
                q+=toward*rng.uniform(.003,.021)
                q.z=z1
            verts.append(q)
    faces=[tuple(reversed(range(n))),tuple(range(2*n,3*n))]
    for level in range(2):
        for k in range(n):
            a=level*n+k;b=level*n+(k+1)%n
            faces.append((a,b,b+n,a+n))
    mesh=bpy.data.meshes.new(o.name+' - worn shoulders v3')
    mesh.from_pydata(verts,[],faces)
    for m in old.materials: mesh.materials.append(m)
    mesh.update();o.data=mesh
    for mod in o.modifiers:
        if mod.type=='BEVEL': mod.width=.006;mod.segments=2
    stone_count+=1

assert protected()==before
prefs=bpy.context.preferences.addons['cycles'].preferences
prefs.compute_device_type='METAL';prefs.get_devices()
for device in prefs.devices: device.use=device.type=='METAL'
s.cycles.device='GPU';s.cycles.samples=96;s.cycles.adaptive_threshold=.02
s.render.resolution_percentage=100
s.render.filepath=str(out/'b2-shapes-v3.png')
bpy.ops.wm.save_as_mainfile(filepath=str(dest))
report={'source':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
        'project':str(dest),'protected':before,'canopy_leaves':leaf_count,'stone_objects':stone_count,
        'camera_character_actions_seats_unchanged':True,'owner_acceptance':'pending',
        'video':'Existing v1 movie is historical; v3 movie not rendered'}
(out/'b2-shapes-v3-verification.json').write_text(json.dumps(report,indent=2)+'\n')
s.render.resolution_percentage=75;s.cycles.samples=32
s.render.filepath=str(out/'b2-shapes-v3-draft.png')
bpy.ops.render.render(write_still=True)
