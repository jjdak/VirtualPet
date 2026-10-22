extends RefCounted
## Exercise actual input/physics over time, including cancellation of active root motion.
static func key(scene: Node, code: Key) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = code
    event.pressed = true
    scene._unhandled_input(event)

static func run(s: Node) -> void:
    await s.get_tree().create_timer(0.5).timeout
    var report := {"graphical":DisplayServer.get_name()!="headless"}
    s._close_camera()
    Input.action_press("right")
    await s.get_tree().create_timer(0.3).timeout
    report.turn_started = s.locomotion.special.begins_with("Turn")
    var old_angle: float = s.avatar.rotation.y
    Input.action_release("right")
    await s.get_tree().create_timer(0.22).timeout
    report.release_cancels_turn = s.locomotion.special == ""
    report.release_heading_drift = absf(wrapf(s.avatar.rotation.y-old_angle,-PI,PI))
    await s._capture("s2-control-release")
    s.reset_actor()
    await s.get_tree().create_timer(0.3).timeout
    var right: Vector3 = s.follow_camera.global_basis.x
    s.avatar.rotation.y = atan2(right.x,right.z)
    Input.action_press("right")
    await s.get_tree().create_timer(0.65).timeout
    Input.action_release("right")
    await s.get_tree().create_timer(0.2).timeout
    report.stop_started = s.locomotion.special == "Stop"
    Input.action_press("right")
    await s.get_tree().create_timer(0.25).timeout
    report.stop_interrupted = s.locomotion.special != "Stop" and s.locomotion.current_speed > 0.1
    # Space cancels the body command but leaves the world running, even with a key held.
    key(s,KEY_SPACE)
    var stopped_at: Vector3 = s.actor.position
    var boat_x: float = s.boat_world.boat.position.x
    await s.get_tree().create_timer(0.4).timeout
    report.stop_button_drift = Vector2(s.actor.position.x-stopped_at.x,s.actor.position.z-stopped_at.z).length()
    report.world_keeps_running = s.boat_world.boat.position.x > boat_x+0.08
    Input.action_release("right")
    await s.get_tree().create_timer(0.1).timeout
    Input.action_press("left")
    await s.get_tree().create_timer(0.25).timeout
    report.new_input_resumes = s.locomotion.special.begins_with("Turn") or s.locomotion.current_speed > 0.1
    report.resumed_status = s.action_result == "你正在控制"
    # Redirect an active turn without waiting for its original end frame.
    old_angle = s.avatar.rotation.y
    Input.action_release("left")
    Input.action_press("right")
    await s.get_tree().create_timer(0.12).timeout
    report.redirect_cancels_old_turn = s.locomotion.special == ""
    report.redirect_heading_delta = absf(wrapf(s.avatar.rotation.y-old_angle,-PI,PI))
    await s._capture("s2-control-redirect")
    Input.action_release("right")
    s.reset_actor()
    await s.get_tree().create_timer(0.3).timeout
    s._go_to_bank()
    # Exercise takeover while a root-motion turn is active, not merely during a walk.
    s._begin_motion("TurnLeft",Vector3.RIGHT)
    await s.get_tree().create_timer(0.2).timeout
    Input.action_press("back")
    await s.get_tree().create_timer(0.1).timeout
    report.takeover_cancels_action = not s.auto_walk and s.locomotion.special == "" and s.action_result == "已由你接管"
    Input.action_release("back")
    s._go_to_bank()
    await s.get_tree().create_timer(0.4).timeout
    s._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    stopped_at = s.actor.position
    await s.get_tree().create_timer(0.35).timeout
    report.focus_loss_stops = not s.auto_walk and s.locomotion.special == "" and Vector2(s.actor.position.x-stopped_at.x,s.actor.position.z-stopped_at.z).length()<0.01
    # Returning from the seated reference must not resume a suspended root-motion clip.
    s._begin_motion("TurnLeft",Vector3.RIGHT)
    await s.get_tree().create_timer(0.2).timeout
    s.set_seated(true)
    await s.get_tree().create_timer(0.2).timeout
    s.set_seated(false)
    stopped_at = s.actor.position
    await s.get_tree().create_timer(0.25).timeout
    report.seated_return_stable = s.locomotion.special == "" and Vector2(s.actor.position.x-stopped_at.x,s.actor.position.z-stopped_at.z).length()<0.01
    s.set_first_person(true)
    s._begin_motion("Stop",Vector3.ZERO)
    await s.get_tree().create_timer(0.15).timeout
    key(s,KEY_ESCAPE)
    report.escape_stops = s.locomotion.special == "" and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
    s.reset_actor()
    s.set_first_person(false)
    await s.get_tree().create_timer(0.3).timeout
    await s._capture("s2-control-overview")
    report.passed = report.turn_started and report.release_cancels_turn and report.release_heading_drift<0.08 and report.stop_started and report.stop_interrupted and report.stop_button_drift<0.01 and report.world_keeps_running and report.new_input_resumes and report.resumed_status and report.redirect_cancels_old_turn and report.redirect_heading_delta<0.4 and report.takeover_cancels_action and report.focus_loss_stops and report.seated_return_stable and report.escape_stops
    var path := "res://evidence/s2-control-"+("graphical" if report.graphical else "headless")+".json"
    FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("CONTROL_CHECK ",JSON.stringify(report))
    s.get_tree().quit(0 if report.passed else 1)

static func film(s: Node) -> void:
    await s.get_tree().create_timer(1.0).timeout
    s._close_camera()
    Input.action_press("right")
    await s.get_tree().create_timer(0.45).timeout
    Input.action_release("right")
    await s.get_tree().create_timer(0.8).timeout
    Input.action_press("right")
    await s.get_tree().create_timer(2.0).timeout
    Input.action_release("right")
    await s.get_tree().create_timer(0.25).timeout
    Input.action_press("right")
    await s.get_tree().create_timer(0.55).timeout
    key(s,KEY_SPACE)
    await s.get_tree().create_timer(0.65).timeout
    Input.action_release("right")
    await s.get_tree().create_timer(0.2).timeout
    Input.action_press("left")
    await s.get_tree().create_timer(0.5).timeout
    Input.action_release("left")
    Input.action_press("right")
    await s.get_tree().create_timer(0.7).timeout
    Input.action_release("right")
    await s.get_tree().create_timer(1.3).timeout
    s._go_to_bank()
    await s.get_tree().create_timer(6.5).timeout
    s.get_tree().quit()
