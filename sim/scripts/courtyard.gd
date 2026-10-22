extends Node3D

const ASSET_ROOT := "res://assets/private/"
const SPEED := 1.08
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
var s2_test := false
var foot_contact: Node
var locomotion: Node
var boat_world: Node3D
var follow_camera: Camera3D
var close_view := false
var move_speed := 0.0
var auto_walk := false
var auto_braking := false
var auto_target := Vector3(2.65, 0.0, -0.20)
var auto_elapsed := 0.0
var stuck_time := 0.0
var action_result := ""
var boat_button: Button

func _ready() -> void:
    s2_test = "--s2-test" in OS.get_cmdline_user_args()
    test_mode = s2_test
    _input_map()
    _ui()
    for required in ["migration.json","locomotion.json","courtyard-v6.glb","girl-a-idle.glb","girl-a-walk.glb","girl-a-seated.glb","transitions.json","girl-a-turnleft.glb","girl-a-turnright.glb","girl-a-stop.glb"]:
        if not FileAccess.file_exists(ASSET_ROOT + required):
            status.text = "缺少本地资产：" + required + "，请先运行准备脚本。"
            if test_mode:
                get_tree().quit(1)
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
    boat_world = load("res://scripts/paper_boat.gd").new()
    add_child(boat_world)
    boat_world.state_changed.connect(func(_value): _update_ui())
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
        call_deferred("_run_s2_checks")
    elif "--motion-check" in OS.get_cmdline_user_args():
        call_deferred("_motion_check")
    elif "--light-check" in OS.get_cmdline_user_args():
        call_deferred("_light_check")
    elif "--s2-film" in OS.get_cmdline_user_args():
        call_deferred("_run_s2_film")

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
    env.ambient_light_color = Color("cbd9d5")
    env.ambient_light_energy = 0.24
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 0.85
    env.tonemap_white = 6.0
    world.environment = env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-53, -32, 0)
    sun.light_color = Color("fff9f2")
    sun.light_energy = 0.55
    sun.shadow_enabled = true
    sun.shadow_opacity = 0.86
    sun.directional_shadow_max_distance = 26.0
    add_child(sun)
    var floor_mesh := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(200, 200)
    floor_mesh.mesh = plane
    floor_mesh.position.y = -0.37
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("b6b5a9")
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
    avatar = load(ASSET_ROOT + "girl-a-idle.glb").instantiate() as Node3D
    avatar.name = "GirlAVisual"
    actor.add_child(avatar)
    locomotion = load("res://scripts/locomotion.gd").new()
    avatar.add_child(locomotion)
    var motion_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ASSET_ROOT + "locomotion.json"))
    locomotion.setup(avatar,load(ASSET_ROOT + "girl-a-walk.glb"),motion_data.clips.Walk.measured_stance_speed)
    var skeleton: Skeleton3D = avatar.find_children("*","Skeleton3D",true,false)[0]
    foot_contact = load("res://scripts/foot_contact.gd").new()
    skeleton.add_child(foot_contact)
    foot_contact.setup(actor,locomotion)

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
    follow_camera = Camera3D.new()
    follow_camera.name = "MotionReviewCamera"
    follow_camera.fov = 44
    add_child(follow_camera)
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
    close_view = false
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
    auto_walk = false
    move_speed = 0.0
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
    move_speed = 0.0
    locomotion.reset_motion()
    foot_contact.reset_contacts()
    auto_walk = false
    auto_braking = false
    action_result = ""
    boat_world.reset()
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
            KEY_B:
                _toggle_branch()
            KEY_G:
                _go_to_bank()
            KEY_C:
                _close_camera()
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
    var basis := camera_pivot.global_basis if first_person else (follow_camera.global_basis if close_view else overview.global_basis)
    var forward := -basis.z
    forward.y = 0.0
    forward = forward.normalized()
    var right := basis.x
    right.y = 0.0
    right = right.normalized()
    var direction := (right * axes.x - forward * axes.y).normalized()
    if axes.length() > 0.01 and auto_walk:
        auto_walk = false
        action_result = "已由你接管"
    if auto_walk:
        auto_elapsed += delta
        var offset := auto_target - actor.position
        offset.y = 0.0
        if auto_braking and locomotion.special != "":
            direction = Vector3.ZERO
        elif offset.length() < 0.15 or (auto_braking and offset.length() < 0.25):
            auto_walk = false
            action_result = "已到池边"
            direction = Vector3.ZERO
        elif auto_elapsed > 12.0 or stuck_time > 1.3:
            auto_walk = false
            action_result = "前方不可达，请手动绕行"
            direction = Vector3.ZERO
        else:
            auto_braking = false
            direction = offset.normalized()
            var stop_samples: Array = locomotion.transitions.Stop.root_samples
            var stop_distance: float = stop_samples[-1].position[2]
            if move_speed > 0.35 and offset.length() < stop_distance+0.035 and locomotion.special == "":
                auto_braking = true
                direction = Vector3.ZERO
    var target_speed := 0.0
    var angle_error := 0.0
    var has_direction := direction.length_squared()>0.01
    if has_direction:
        angle_error = wrapf(atan2(direction.x,direction.z)-avatar.rotation.y,-PI,PI)
    if locomotion.special == "":
        if move_speed > 0.35 and (not has_direction or absf(angle_error)>2.0):
            locomotion.begin_action("Stop",avatar.rotation.y)
        elif has_direction and absf(angle_error)>1.15 and move_speed < 0.12:
            locomotion.begin_action("TurnLeft" if angle_error>0 else "TurnRight",avatar.rotation.y)
    if locomotion.special != "":
        var action: Dictionary = locomotion.advance_action(delta)
        avatar.rotation.y = action.angle
        actor.velocity.x = action.velocity.x
        actor.velocity.z = action.velocity.z
        move_speed = 0.0
    else:
        if has_direction:
            avatar.rotation.y = rotate_toward(avatar.rotation.y,atan2(direction.x,direction.z),delta*1.8)
            target_speed = SPEED*clampf(cos(angle_error),0.35,1.0)
        move_speed = move_toward(move_speed,target_speed,delta*(2.8 if target_speed>move_speed else 4.5))
        var facing := Vector3(sin(avatar.rotation.y),0,cos(avatar.rotation.y))
        actor.velocity.x = facing.x*move_speed
        actor.velocity.z = facing.z*move_speed
    if not actor.is_on_floor():
        actor.velocity.y -= GRAVITY * delta
    else:
        actor.velocity.y = 0.0
    var before := actor.position
    actor.move_and_slide()
    var actual := actor.position-before
    actual.y = 0
    var actual_speed := actual.length()/delta
    locomotion.update_motion(0.0 if locomotion.special != "" else actual_speed,delta)
    if auto_walk:
        stuck_time = stuck_time+delta if actual_speed < 0.04 and locomotion.special == "" else 0.0
    follow_camera.position = follow_camera.position.lerp(actor.position+Vector3(3.4,2.5,4.5),1-exp(-delta*4))
    follow_camera.look_at(actor.position+Vector3(0,0.95,0))
    _update_ui()
    if actor.position.y < -2.0:
        reset_actor()

func _toggle_branch() -> void:
    if scene_ready:
        boat_world.toggle_obstacle()
        _update_ui()

func _go_to_bank() -> void:
    if not scene_ready:
        return
    set_seated(false)
    auto_walk = true
    auto_elapsed = 0.0
    auto_braking = false
    stuck_time = 0.0
    action_result = "正走向池边 · WASD 随时接管"

func _close_camera() -> void:
    if not scene_ready:
        return
    var enable := not close_view
    set_first_person(false)
    close_view = enable
    follow_camera.position = actor.position+Vector3(3.4,2.5,4.5)
    follow_camera.look_at(actor.position+Vector3(0,0.95,0))
    follow_camera.current = enable
    overview.current = not enable

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
    title.add_theme_constant_override("outline_size",5)
    title.add_theme_color_override("font_outline_color",Color("e8eadd"))
    ui.add_child(title)
    status = Label.new()
    status.position = Vector2(33, 62)
    status.add_theme_color_override("font_color", Color("486053"))
    status.add_theme_constant_override("outline_size",4)
    status.add_theme_color_override("font_outline_color",Color("e8eadd"))
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
    for label in ["全景", "近看  C", "第一视角  F", "去池边  G", "移开树枝  B", "重置  R"]:
        var button := Button.new()
        button.text = label
        button.focus_mode = Control.FOCUS_NONE
        var button_style := StyleBoxFlat.new()
        button_style.bg_color = Color("dbe2d1")
        button_style.set_corner_radius_all(5)
        button_style.content_margin_left = 10
        button_style.content_margin_right = 10
        button_style.content_margin_top = 6
        button_style.content_margin_bottom = 6
        button.add_theme_stylebox_override("normal",button_style)
        button.add_theme_color_override("font_color",Color("344d40"))
        row.add_child(button)
        match label:
            "全景": button.pressed.connect(func(): set_first_person(false))
            "近看  C": button.pressed.connect(_close_camera)
            "去池边  G": button.pressed.connect(_go_to_bank)
            "移开树枝  B":
                boat_button = button
                button.pressed.connect(_toggle_branch)
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
    var boat_text: String = {"drifting":"纸船顺水漂着", "blocked":"纸船被树枝挡住了", "arrived":"纸船到了另一边"}.get(boat_world.state,"")
    status.text = boat_text + ("  ·  " + action_result if action_result != "" else "")
    if boat_button:
        boat_button.text = "移开树枝  B" if boat_world.obstacle_present else "放回树枝  B"
    hint.text = "WASD 走动 · C 近看 · F 第一视角 · Esc 释放鼠标 · B 导演移动树枝 · R 重置"
    if seated_preview:
        hint.text = "原坐姿动画参考 · P 返回控制小样"

func _capture(name: String) -> void:
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("res://evidence/"+name+".png")

func _run_s2_checks() -> void:
    DirAccess.make_dir_recursive_absolute("res://evidence")
    await get_tree().create_timer(1.0).timeout
    var report := {"engine":Engine.get_version_info().string,"graphical":DisplayServer.get_name()!="headless"}
    var sk := avatar.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
    var leg := sk.find_bone("LeftLeg")
    report["bone_count"] = sk.get_bone_count()
    report["grounded"] = actor.is_on_floor()
    var left_foot := sk.find_bone("LeftToeBase")
    var right_foot := sk.find_bone("RightToeBase")
    var left_y: float = (sk.global_transform * sk.get_bone_global_pose(left_foot).origin).y-actor.position.y
    var right_y: float = (sk.global_transform * sk.get_bone_global_pose(right_foot).origin).y-actor.position.y
    report["support_foot_height"] = minf(left_y,right_y)
    report["clips"] = Array(locomotion.player.get_animation_list())
    _close_camera()
    await _capture("s2-idle")
    # Both authored turns must finish with their measured yaw, without instant spinning.
    var turn_results := {}
    for turn_name in ["TurnLeft","TurnRight"]:
        var old_heading := avatar.rotation.y
        locomotion.begin_action(turn_name,old_heading)
        await get_tree().create_timer(0.3).timeout
        turn_results[turn_name+"_300ms"] = absf(wrapf(avatar.rotation.y-old_heading,-PI,PI))
        await get_tree().create_timer(1.45).timeout
        turn_results[turn_name+"_error"] = absf(wrapf(avatar.rotation.y-old_heading-float(locomotion.transitions[turn_name].yaw),-PI,PI))
    report["turns"] = turn_results
    reset_actor()
    await get_tree().create_timer(0.5).timeout
    # Start aligned so this measures walking rather than the new pre-walk turn.
    var right := follow_camera.global_basis.x
    avatar.rotation.y = atan2(right.x,right.z)
    var initial_pose := sk.get_bone_pose_rotation(leg)
    var start := actor.position
    Input.action_press("right")
    await get_tree().create_timer(1.15).timeout
    report["walking_distance"] = actor.position.distance_to(start)
    report["leg_angle_change"] = initial_pose.angle_to(sk.get_bone_pose_rotation(leg))
    report["walk_blend"] = locomotion.blend
    await _capture("s2-walk")
    Input.action_release("right")
    await get_tree().create_timer(0.35).timeout
    report["stop_clip_entered"] = locomotion.special == "Stop"
    await _capture("s2-stop-contact")
    await get_tree().create_timer(1.0).timeout
    report["stop_clip_completed"] = "Stop" in locomotion.completed_specials
    report["stopped_speed"] = locomotion.current_speed
    report["idle_blend"] = locomotion.blend
    # Opposite input must select a turn clip, then allow walking after it finishes.
    Input.action_press("left")
    await get_tree().create_timer(0.3).timeout
    report["input_turn_entered"] = locomotion.special.begins_with("Turn")
    await _capture("s2-turn")
    Input.action_release("left")
    await get_tree().create_timer(1.5).timeout
    report["contacts"] = foot_contact.metrics.duplicate(true)
    reset_actor()
    set_first_person(false)
    _go_to_bank()
    await get_tree().create_timer(4.5).timeout
    report["bank_result"] = action_result
    report["bank_distance"] = Vector2(actor.position.x-auto_target.x,actor.position.z-auto_target.z).length()
    await _capture("s2-bank")
    # The normal boat journey must meet the actual branch collider and stay blocked.
    await get_tree().create_timer(8.5).timeout
    report["boat_blocked"] = boat_world.state == "blocked"
    var blocked_x: float = boat_world.boat.position.x
    await get_tree().create_timer(0.6).timeout
    report["blocked_drift"] = absf(boat_world.boat.position.x-blocked_x)
    await _capture("s2-boat-blocked")
    _toggle_branch()
    await get_tree().create_timer(2.5).timeout
    report["boat_released"] = boat_world.boat.position.x > blocked_x+0.4
    await _capture("s2-boat-released")
    report["events"] = boat_world.events.duplicate(true)
    # Putting the branch back after the hull has passed cannot rewind or block the boat.
    await get_tree().create_timer(1.3).timeout
    var after_pass: float = boat_world.boat.position.x
    _toggle_branch()
    await get_tree().create_timer(0.9).timeout
    report["replaced_after_pass"] = boat_world.boat.position.x > after_pass and boat_world.state != "blocked"
    # Clearing the obstruction before arrival must bypass blocking entirely.
    boat_world.reset()
    boat_world.toggle_obstacle()
    await get_tree().create_timer(0.8).timeout
    boat_world.boat.position.x = 1.65
    await get_tree().create_timer(2.5).timeout
    report["removed_before_arrival"] = boat_world.state == "drifting" and boat_world.boat.position.x > 2.5
    # Collision cannot be escaped by the goal follower; report failure and yield to manual input.
    actor.position = Vector3(3.7,0.96,-2.1)
    auto_target = Vector3(5.5,0,-2.1)
    _go_to_bank()
    await get_tree().create_timer(4.0).timeout
    report["unreachable_result"] = action_result
    report["wall_blocked"] = actor.position.x < 4.3
    _go_to_bank()
    Input.action_press("back")
    await get_tree().create_timer(0.2).timeout
    Input.action_release("back")
    report["manual_interrupt"] = not auto_walk and action_result == "已由你接管"
    auto_target = Vector3(2.65,0,-0.20)
    reset_actor()
    await get_tree().create_timer(0.6).timeout
    report["reset_ok"] = boat_world.obstacle_present and boat_world.state == "drifting" and actor.position.distance_to(SPAWN) < 0.15
    set_first_person(true)
    report["first_person"] = eyes.current and not overview.current
    var last_yaw := yaw
    Input.action_press("look_right")
    await get_tree().create_timer(0.25).timeout
    Input.action_release("look_right")
    report["camera_look"] = absf(yaw-last_yaw)>0.2
    set_first_person(false)
    await _capture("s2-overview")
    report["passed"] = report.grounded and absf(report.support_foot_height) < 0.12 and report.bone_count == 58 and report.walking_distance > 0.35 and report.leg_angle_change > 0.1 and report.stopped_speed < 0.05 and report.turns.TurnLeft_300ms < 1.0 and report.turns.TurnRight_300ms < 1.0 and report.turns.TurnLeft_error < 0.05 and report.turns.TurnRight_error < 0.05 and report.stop_clip_entered and report.stop_clip_completed and report.input_turn_entered and report.bank_distance < 0.25 and report.boat_blocked and report.blocked_drift < 0.01 and report.boat_released and report.removed_before_arrival and report.wall_blocked and report.unreachable_result.contains("不可达") and report.manual_interrupt and report.reset_ok and report.first_person and report.camera_look and report.replaced_after_pass
    var contact_checks := true
    for phase in ["Walk","TurnLeft","TurnRight","Stop"]:
        var m: Dictionary = report.contacts.phases.get(phase,{})
        contact_checks = contact_checks and m.get("samples",0)>5 and m.get("corrected_slide_sum",1.0)<m.get("raw_slide_sum",0.0)*0.65
    report["contact_checks"] = contact_checks and report.contacts.max_segment_error < 0.001
    report.passed = report.passed and report.contact_checks
    FileAccess.open("res://evidence/s2-check-"+("graphical" if report.graphical else "headless")+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("S2_CHECK ",JSON.stringify(report))
    get_tree().quit(0 if report.passed else 1)

func _run_s2_film() -> void:
    await get_tree().create_timer(1.0).timeout
    _close_camera()
    await get_tree().create_timer(1.0).timeout
    Input.action_press("right")
    await get_tree().create_timer(3.2).timeout
    Input.action_release("right")
    await get_tree().create_timer(1.35).timeout
    Input.action_press("left")
    await get_tree().create_timer(4.2).timeout
    Input.action_release("left")
    await get_tree().create_timer(1.35).timeout
    _go_to_bank()
    await get_tree().create_timer(5.5).timeout
    set_first_person(false)
    await get_tree().create_timer(2.0).timeout
    _toggle_branch()
    await get_tree().create_timer(4.0).timeout
    get_tree().quit()

func _light_check() -> void:
    await get_tree().create_timer(1.0).timeout
    await _capture("s2-light-corrected")
    get_tree().quit()

func _motion_check() -> void:
    await get_tree().create_timer(0.5).timeout
    _close_camera()
    locomotion.begin_action("TurnLeft",avatar.rotation.y)
    await get_tree().create_timer(0.75).timeout
    await _capture("s2-turn-contact")
    await get_tree().create_timer(1.0).timeout
    locomotion.begin_action("Stop",avatar.rotation.y)
    await get_tree().create_timer(0.55).timeout
    await _capture("s2-stop-contact")
    await get_tree().create_timer(0.7).timeout
    print("CONTACT ",JSON.stringify(foot_contact.metrics))
    get_tree().quit()
