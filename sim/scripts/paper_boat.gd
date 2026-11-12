extends Node3D
## A deterministic water lane, not a fluid simulation. A swept shape query detects the branch.
signal state_changed(value: String)
const START := Vector3(-2.5, 0.25, 0.88)
const END_X := 3.55
const DRIFT_SPEED := 0.38
const OBSTACLE_HOME := Vector3(2.3, 0.25, 0.88)
var boat: Node3D
var branch: StaticBody3D
var shape: BoxShape3D
var branch_shape: CollisionShape3D
var state := "drifting"
var obstacle_present := true
var elapsed := 0.0
var events: Array[Dictionary] = []
var branch_tween: Tween
var ripples: Array[MeshInstance3D] = []

func _ready() -> void:
    boat = Node3D.new()
    boat.name = "PaperBoat"
    add_child(boat)
    boat.position = START
    # Folded paper hull: separate triangular planes retain a readable crease at this distance.
    var points := [Vector3(-0.32, 0.08, 0), Vector3(0.32, 0.08, 0), Vector3(0, -0.015, -0.13), Vector3(0, -0.015, 0.13), Vector3(-0.11, 0.08, -0.17), Vector3(0.11, 0.08, -0.17), Vector3(-0.11, 0.08, 0.17), Vector3(0.11, 0.08, 0.17), Vector3(0, 0.26, 0)]
    for face in [[0,2,4],[4,2,5],[5,2,1],[0,6,3],[6,7,3],[7,1,3],[0,8,1],[0,1,2],[0,3,1]]:
        var st := SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        for index in face:
            st.add_vertex(points[index])
        st.generate_normals()
        var mesh := MeshInstance3D.new()
        mesh.mesh = st.commit()
        mesh.material_override = _material(Color("e8d8ad") if face.has(8) else Color("f1ebda"))
        boat.add_child(mesh)
    shape = BoxShape3D.new()
    shape.size = Vector3(0.60, 0.16, 0.31)
    branch = StaticBody3D.new()
    branch.name = "MovableBranch"
    branch.collision_layer = 2
    branch.collision_mask = 0
    add_child(branch)
    branch.position = OBSTACLE_HOME
    branch_shape = CollisionShape3D.new()
    var capsule := BoxShape3D.new()
    capsule.size = Vector3(0.14, 0.20, 0.86)
    branch_shape.shape = capsule
    branch.add_child(branch_shape)
    _twig(Vector3(0,0,-0.45),Vector3(0,0.02,0.48),0.045)
    _twig(Vector3(0,0,0.1),Vector3(-0.21,0.04,0.29),0.022)
    _twig(Vector3(0,0,-0.2),Vector3(0.18,0.045,-0.36),0.018)
    for i in 3:
        var ripple := MeshInstance3D.new()
        var ring := TorusMesh.new()
        ring.inner_radius = 0.23 + i * 0.08
        ring.outer_radius = ring.inner_radius + 0.007
        ring.rings = 40
        ring.ring_segments = 6
        ripple.mesh = ring
        ripple.material_override = _material(Color(0.57,0.68,0.57,0.35))
        ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(ripple)
        ripples.append(ripple)

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.86
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    if color.a < 1:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return mat

func _twig(a: Vector3, b: Vector3, radius: float) -> void:
    var mesh := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = radius * 0.5
    cylinder.bottom_radius = radius
    cylinder.height = a.distance_to(b)
    cylinder.radial_segments = 8
    mesh.mesh = cylinder
    mesh.material_override = _material(Color("796849"))
    branch.add_child(mesh)
    mesh.position = (a+b)*0.5
    mesh.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func _physics_process(delta: float) -> void:
    elapsed += delta
    if state != "arrived":
        var query := PhysicsShapeQueryParameters3D.new()
        query.shape = shape
        query.transform = Transform3D(Basis.IDENTITY,boat.position)
        query.motion = Vector3(DRIFT_SPEED*delta,0,0)
        query.collision_mask = 2
        query.margin = 0.008
        var space := get_world_3d().direct_space_state
        var overlaps := space.intersect_shape(query,1)
        var travel := space.cast_motion(query)
        if not overlaps.is_empty():
            travel[0] = 0.0
        if travel[0] < 0.999:
            _set_state("blocked")
        else:
            _set_state("drifting")
        boat.position.x += query.motion.x * travel[0]
        if boat.position.x >= END_X:
            boat.position.x = END_X
            _set_state("arrived")
    boat.position.y = START.y + sin(elapsed*1.9)*0.009
    boat.rotation.z = sin(elapsed*1.5)*0.018
    boat.rotation.x = cos(elapsed*1.1)*0.025
    for i in ripples.size():
        ripples[i].position = Vector3(boat.position.x - 0.08,0.224,boat.position.z)
        ripples[i].scale = Vector3(1.3,1,0.6)*(1.0+fmod(elapsed*.22+i*.24,0.7))

func _set_state(value: String) -> void:
    if value == state:
        return
    state = value
    events.append({"time":elapsed,"event":value,"boat_x":boat.position.x})
    state_changed.emit(value)

func toggle_obstacle() -> void:
    obstacle_present = not obstacle_present
    # Collision follows the visible obstacle. No direct writes to boat state or position.
    if branch_tween:
        branch_tween.kill()
    branch_tween = create_tween()
    branch_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    branch_tween.tween_property(branch,"position",OBSTACLE_HOME if obstacle_present else OBSTACLE_HOME+Vector3(0,0,0.85),0.65)
    events.append({"time":elapsed,"event":"branch_replaced" if obstacle_present else "branch_removed"})

func reset() -> void:
    if branch_tween:
        branch_tween.kill()
    branch.position = OBSTACLE_HOME
    obstacle_present = true
    boat.position = START
    elapsed = 0
    events.clear()
    _set_state("drifting")
