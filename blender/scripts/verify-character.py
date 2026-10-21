"""Read-only wardrobe deformation check. Does not claim cloth simulation."""
import bpy, json
from pathlib import Path
from mathutils import Quaternion

s=bpy.context.scene
rig=next(o for o in s.objects if o.type=='ARMATURE')
continuous=bpy.data.objects['Slate linen - L sleeve'].hide_render
targets=['Slate linen - seated skirt','Body_4' if continuous else 'Slate linen - L sleeve','Body_4' if continuous else 'Slate linen - R sleeve','Hair']
def positions(obj):
    bpy.context.view_layer.update()
    ev=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=ev.to_mesh()
    result=[obj.matrix_world@v.co for v in mesh.vertices];ev.to_mesh_clear();return result
results=[]
for name,bone_name in zip(targets,['J_Bip_L_UpperLeg','J_Bip_L_LowerArm','J_Bip_R_LowerArm','J_Bip_C_Head']):
    obj=bpy.data.objects[name]
    assert any(m.type=='ARMATURE' and m.object==rig for m in obj.modifiers)
    before=positions(obj);bone=rig.pose.bones[bone_name];matrix=bone.matrix_basis.copy();mode=bone.rotation_mode
    bone.rotation_mode='QUATERNION';bone.rotation_quaternion=bone.rotation_quaternion@Quaternion((0,1,0),.15)
    after=positions(obj);displacement=max((a-b).length for a,b in zip(before,after))
    bone.matrix_basis=matrix;bone.rotation_mode=mode
    assert displacement>.003,(name,displacement)
    restored=positions(obj);error=max((a-b).length for a,b in zip(before,restored))
    assert error<1e-5,(name,error)
    results.append({'object':name,'bone':bone_name,'max_vertex_displacement_m':displacement,'restore_error_m':error})
report={'file':bpy.data.filepath,'result':'pass','garments':results,'scope':'Garment skinning responds to real bone edits; no broad-motion collision or cloth simulation acceptance'}
Path(bpy.data.filepath).with_suffix('.wardrobe-verification.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
