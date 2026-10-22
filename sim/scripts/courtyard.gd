extends Node3D

const ASSET_ROOT := "res://assets/private/"
const SPEED := 1.65
const GRAVITY := 18.0
const SPAWN := Vector3(1.35, 0.96, -2.1)
var actor: CharacterBody3D
var avatar: Node3D
var seated: Node3D
var overview: Camera3D
var eyes: Camera3D
var camera_pivot: Node3D
var status: Label
var hint: Label
var first_person := false
var seated_preview := false
var yaw := PI
var pitch := -0.28
var scene_ready := false
var colliders := 0
var metadata: Dictionary
var test_mode := false

func _ready() -> void:
    test_mode = "--s1-test" in OS.get_cmdline_user_args()
    _input_map()
    _ui()
    if not FileAccess.file_exists(ASSET_ROOT + "migration.json"):
        status.text = "缺少本地资产，请先运行 sim 的准备脚本。"
        return
    metadata = JSON.parse_string(FileAccess.get_file_as_string(ASSET_ROOT + "migration.json"))
    _lighting()
    var courtyard := load(ASSET_ROOT + "courtyard-v6.glb").instantiate() as Node3D
    courtyard.name = "ImportedCourtyardV6"
    add_child(courtyard)
    for node in courtyard.find_children("*", "MeshInstance3D", true, false):
        var mesh_node := node as MeshInstance3D
        var n := String(mesh_node.name)
        if n in ["Source_161", "Source_162"]:
            mesh_node.visible = false # Legacy painted contact shadows belong to the old seated shot.
        # Reuse actual architectural geometry. Small decorative stones are visual only.
        if n.begins_with("Limestone") or n.begins_with("Seat") or n in ["Source_000", "Source_001", "Source_002", "Source_003", "Source_066", "Source_067", "Source_068", "Source_069", "Source_070", "Source_072"]:
            mesh_node.create_trimesh_collision()
            colliders += 1
    _water()
    # Explicit S1 walking boundary: the shallow pool is not a swimming area.
    _barrier("PoolLimit", Vector3(0, 0.65, 0.43), Vector3(8.8, 2.0, 0.16))
    _barrier("RightLimit", Vector3(4.5, 1.1, -1.35), Vector3(0.18, 3.2, 4.6))
    _barrier("LeftLimit", Vector3(-4.5, 1.1, -0.35), Vector3(0.18, 3.2, 2.8))
    _actor()
    _cameras()
    seated = load(ASSET_ROOT + "girl-a-seated.glb").instantiate() as Node3D
    seated.name = "OriginalSeatedStudy"
    add_child(seated)
    seated.visible = false
    _play_imported(seated)
    scene_ready = true
    _update_ui()
    if test_mode:
        call_deferred("_run_checks")

func _input_map() -> void:
    var bindings := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "look_left": KEY_LEFT, "look_right": KEY_RIGHT, "look_up": KEY_UP, "look_down": KEY_DOWN}
    for action in bindings:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var key := InputEventKey.new()
        key.physical_keycode = bindings[action]
        InputMap.action_add_event(action, key)

func _lighting() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("c8d5ca")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("d5e2d9")
    env.ambient_light_energy = 0.25
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-53, -32, 0)
    sun.light_color = Color("fff5e7")
    sun.light_energy = 0.70
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 45.0
    add_child(sun)
    var floor_mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(200, 200)
    floor_mesh.mesh = plane
    floor_mesh.position.y = -0.37
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("d8d7c7")
    mat.roughness = 1.0
    floor_mesh.material_override = mat
    add_child(floor_mesh)

func _water() -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = "RealtimeWater"
    var plane := PlaneMesh.new()
    plane.size = Vector2(8.2, 3.75)
    mesh.mesh = plane
    mesh.position = Vector3(0, 0.21, 2.15)
    var mat := ShaderMaterial.new()
    mat.shader = load("res://scripts/water.gdshader")
    mesh.material_override = mat
    add_child(mesh)

func _barrier(label: String, center: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = label
    body.position = center
    var collision := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    collision.shape = box
    body.add_child(collision)
    add_child(body)

func _actor() -> void:
    actor = CharacterBody3D.new()
    actor.name = "ControlledGirlA"
    actor.position = SPAWN
    actor.floor_snap_length = 0.28
    actor.floor_max_angle = deg_to_rad(48)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.23
    capsule.height = 1.85
    collision.shape = capsule
    collision.position.y = 0.925
    actor.add_child(collision)
    add_child(actor)
    avatar = load(ASSET_ROOT + "girl-a-standing.glb").instantiate() as Node3D
    avatar.name = "GirlAVisual"
    actor.add_child(avatar)
    _play_imported(avatar)

func _play_imported(root: Node) -> void:
    for node in root.find_children("*", "AnimationPlayer", true, false):
        var player := node as AnimationPlayer
        for animation in player.get_animation_list():
            if animation != "RESET":
                player.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
                player.play(animation)
                break

func _cameras() -> void:
    overview = Camera3D.new()
    overview.name = "ApprovedOverview"
    overview.projection = Camera3D.PROJECTION_ORTHOGONAL
    overview.size = float(metadata.camera_vertical_size)
    overview.position = _vec(metadata.camera_position)
    overview.far = 250.0
    add_child(overview)
    overview.look_at(_vec(metadata.camera_target))
    overview.current = true
    camera_pivot = Node3D.new()
    camera_pivot.name = "EyePivot"
    actor.add_child(camera_pivot)
    camera_pivot.position.y = float(metadata.standing_eye_height)
    eyes = Camera3D.new()
    eyes.name = "FirstPerson"
    eyes.near = 0.04
    eyes.far = 100.0
    eyes.fov = 72.0
    camera_pivot.add_child(eyes)
    _look()

func _vec(a: Array) -> Vector3:
    return Vector3(float(a[0]), float(a[1]), float(a[2]))

func _look() -> void:
    camera_pivot.rotation.y = yaw
    eyes.rotation.x = pitch

func set_first_person(enabled: bool) -> void:
    if not scene_ready:
        return
    if seated_preview:
        set_seated(false)
    first_person = enabled
    eyes.current = enabled
    overview.current = not enabled
    # S1 hides the whole local visual from the eye camera to avoid clipping through hair/clothes.
    # Keep its shadow; per-surface body visibility is deferred.
    for node in avatar.find_children("*", "GeometryInstance3D", true, false):
        node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    if not test_mode:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE
    _update_ui()

func set_seated(enabled: bool) -> void:
    if not scene_ready:
        return
    if first_person:
        set_first_person(false)
    seated_preview = enabled
    avatar.visible = not enabled
    seated.visible = enabled
    actor.velocity = Vector3.ZERO
    _update_ui()

func reset_actor() -> void:
    if not scene_ready:
        return
    set_seated(false)
    actor.position = SPAWN
    actor.velocity = Vector3.ZERO
    avatar.rotation.y = 0.0
    yaw = PI
    pitch = -0.28
    _look()

func _unhandled_input(event: InputEvent) -> void:
    if not scene_ready:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_F, KEY_TAB:
                set_first_person(not first_person)
            KEY_P:
                set_seated(not seated_preview)
            KEY_R:
                reset_actor()
            KEY_ESCAPE:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
                _update_ui()
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and first_person:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        _update_ui()

func _input(event: InputEvent) -> void:
    if not scene_ready:
        return
    if event is InputEventMouseMotion and first_person and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * 0.0025
        pitch = clampf(pitch - event.relative.y * 0.0025, -1.15, 1.15)
        _look()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    if not scene_ready or seated_preview:
        return
    if first_person:
        yaw -= Input.get_axis("look_left", "look_right") * delta * 1.4
        pitch = clampf(pitch - Input.get_axis("look_up", "look_down") * delta * 1.1, -1.15, 1.15)
        _look()
    var axes := Input.get_vector("left", "right", "forward", "back")
    if first_person and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not test_mode:
        axes = Vector2.ZERO
    var basis := camera_pivot.global_basis if first_person else overview.global_basis
    var forward := -basis.z
    forward.y = 0.0
    forward = forward.normalized()
    var right := basis.x
    right.y = 0.0
    right = right.normalized()
    var direction := (right * axes.x - forward * axes.y).normalized()
    actor.velocity.x = direction.x * SPEED
    actor.velocity.z = direction.z * SPEED
    if not actor.is_on_floor():
        actor.velocity.y -= GRAVITY * delta
    else:
        actor.velocity.y = 0.0
    actor.move_and_slide()
    if direction.length_squared() > 0.01:
        avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(direction.x, direction.z), minf(delta * 12.0, 1.0))
    if actor.position.y < -2.0:
        reset_actor()

func _ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var theme := Theme.new()
    var font := SystemFont.new()
    font.font_names = PackedStringArray(["PingFang SC", "Helvetica Neue"])
    theme.default_font = font
    theme.default_font_size = 16
    ui.theme = theme
    layer.add_child(ui)
    var title := Label.new()
    title.text = "庭院  /  COURTYARD"
    title.position = Vector2(32, 24)
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("2b4138"))
    ui.add_child(title)
    status = Label.new()
    status.position = Vector2(33, 62)
    status.add_theme_color_override("font_color", Color("486053"))
    ui.add_child(status)
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_left = 24
    panel.offset_right = -24
    panel.offset_top = -112
    panel.offset_bottom = -20
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.96, 0.97, 0.92, 0.94)
    style.set_corner_radius_all(12)
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    panel.add_theme_stylebox_override("panel", style)
    ui.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    column.add_child(row)
    for label in ["观察视角", "第一视角  F", "原坐姿小样  P", "回到起点  R"]:
        var button := Button.new()
        button.text = label
        button.focus_mode = Control.FOCUS_NONE
        row.add_child(button)
        match label:
            "观察视角": button.pressed.connect(func(): set_first_person(false))
            "第一视角  F": button.pressed.connect(func(): set_first_person(true))
            "原坐姿小样  P": button.pressed.connect(func(): set_seated(not seated_preview))
            _: button.pressed.connect(reset_actor)
    hint = Label.new()
    hint.add_theme_color_override("font_color", Color("4e6256"))
    hint.add_theme_font_size_override("font_size", 14)
    column.add_child(hint)

func _update_ui() -> void:
    if not scene_ready:
        return
    status.text = "S1 · 原坐姿动画预览" if seated_preview else ("S1 · 第一视角" if first_person else "S1 · 观察视角")
    hint.text = "WASD 移动 · F 切换视角 · 鼠标/方向键环顾 · Esc 释放鼠标 · R 重置  |  移动为控制验证，自然步态将在 S2 接入"
    if seated_preview:
        hint.text = "正在播放 B2 既有身体动作，人物位置沿用原工程。按 P 返回控制小样。"

func _run_checks() -> void:
    # Real physics/input smoke checks; outputs are private and do not replace visual review.
    await get_tree().create_timer(1.0).timeout
    var graphical := DisplayServer.get_name() != "headless"
    var report := {"graphical": graphical, "engine": Engine.get_version_info(), "colliders": colliders, "source": metadata.source_sha256}
    report["spawn_grounded"] = actor.is_on_floor()
    var start := actor.position
    Input.action_press("right")
    await get_tree().create_timer(0.7).timeout
    Input.action_release("right")
    report["moved_distance"] = actor.position.distance_to(start)
    set_first_person(true)
    report["first_person_current"] = eyes.current and not overview.current
    report["eye_height"] = camera_pivot.position.y
    var old_yaw := yaw
    Input.action_press("look_right")
    await get_tree().create_timer(0.3).timeout
    Input.action_release("look_right")
    report["look_angle_changed"] = absf(yaw - old_yaw) > 0.2
    var old_pitch := pitch
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    var motion := InputEventMouseMotion.new()
    motion.relative = Vector2(40, 20)
    Input.parse_input_event(motion)
    await get_tree().process_frame
    report["mouse_capture_mode"] = Input.mouse_mode
    report["mouse_look_changed"] = absf(pitch - old_pitch) > 0.02 if graphical else null
    report["mouse_check_note"] = "Captured pointer + InputEventMouseMotion" if graphical else "Headless display cannot capture pointer; checked in graphical run"
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    set_first_person(false)
    report["overview_current"] = overview.current and not eyes.current
    set_seated(true)
    report["seated_mode"] = seated.visible and not avatar.visible
    var clips: Array = []
    for player in seated.find_children("*", "AnimationPlayer", true, false):
        clips.append({"playing": player.is_playing(), "animation": player.current_animation, "time": player.current_animation_position})
    report["seated_clips"] = clips
    var skeletons := seated.find_children("*", "Skeleton3D", true, false)
    report["imported_bones"] = (skeletons[0] as Skeleton3D).get_bone_count() if not skeletons.is_empty() else 0
    var bone_motion := 0.0
    if not skeletons.is_empty():
        var sk := skeletons[0] as Skeleton3D
        var head := sk.find_bone("Head")
        var initial := sk.get_bone_pose_rotation(head)
        await get_tree().create_timer(1.4).timeout
        bone_motion = initial.angle_to(sk.get_bone_pose_rotation(head))
    report["seated_head_change_radians"] = bone_motion
    set_seated(false)
    # Drive into right boundary for enough time to verify physics, not just clamp coordinates.
    actor.position = Vector3(3.6, 1.0, -2.1)
    yaw = -PI / 2.0
    _look()
    set_first_person(true)
    Input.action_press("forward")
    await get_tree().create_timer(1.8).timeout
    Input.action_release("forward")
    report["wall_stop_x"] = actor.position.x
    report["wall_blocked"] = actor.position.x < 4.3 and actor.position.x > 3.9
    actor.position = Vector3(2.6, 0.8, -0.15)
    yaw = PI
    _look()
    Input.action_press("forward")
    await get_tree().create_timer(0.8).timeout
    Input.action_release("forward")
    report["pool_blocked"] = actor.position.z < 0.15
    reset_actor()
    set_first_person(false)
    await get_tree().create_timer(0.3).timeout
    report["reset_position"] = [actor.position.x, actor.position.y, actor.position.z]
    report["passed"] = report.spawn_grounded and report.moved_distance > 0.4 and report.first_person_current and report.overview_current and report.seated_mode and report.wall_blocked and not clips.is_empty() and report.look_angle_changed and (not graphical or report.mouse_look_changed) and report.pool_blocked and bone_motion > 0.001
    DirAccess.make_dir_recursive_absolute("res://evidence")
    FileAccess.open("res://evidence/s1-runtime-check-" + ("graphical" if graphical else "headless") + ".json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
    print("S1_CHECK ", JSON.stringify(report))
    get_tree().quit(0 if report.passed else 1)
