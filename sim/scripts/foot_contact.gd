extends SkeletonModifier3D
## Runs after authored animation. Small two-bone correction plants low support feet in world space.
var actor: CharacterBody3D
var motion: Node
var feet: Array[Dictionary] = []
var metrics := {"samples":0,"raw_slide_sum":0.0,"corrected_slide_sum":0.0,"max_correction":0.0,"max_segment_error":0.0,"phases":{}}
var enabled := true

func setup(body: CharacterBody3D, locomotion: Node) -> void:
    actor = body
    motion = locomotion
    var sk := get_skeleton()
    for side in ["Left","Right"]:
        feet.append({"hip":sk.find_bone(side+"UpLeg"),"knee":sk.find_bone(side+"Leg"),"ankle":sk.find_bone(side+"Foot"),"toe":sk.find_bone(side+"ToeBase"),"locked":false,"anchor":Vector3.ZERO,"weight":0.0,"previous_raw":Vector3.ZERO,"previous_final":Vector3.ZERO,"last_contact":false})

func reset_contacts() -> void:
    for foot in feet:
        foot.locked = false
        foot.weight = 0.0
        foot.last_contact = false

func _process_modification_with_delta(delta: float) -> void:
    if not enabled or not is_instance_valid(actor) or feet.is_empty():
        return
    var sk := get_skeleton()
    for foot in feet:
        var ankle_pose := sk.get_bone_global_pose(foot.ankle)
        var raw := sk.global_transform * ankle_pose.origin
        var toe := sk.global_transform * sk.get_bone_global_pose(foot.toe).origin
        var ray := PhysicsRayQueryParameters3D.create(raw+Vector3.UP*0.38,raw-Vector3.UP*0.55,1,[actor.get_rid()])
        var hit := get_world_3d().direct_space_state.intersect_ray(ray)
        if hit.is_empty() or not actor.is_on_floor():
            foot.locked = false
            foot.weight = move_toward(foot.weight,0.0,delta*10)
            foot.last_contact = false
            continue
        var floor_y: float = hit.position.y
        # Toe low means support phase; use hysteresis so the lock doesn't chatter.
        var clearance := toe.y-floor_y
        var low := clearance < (0.09 if foot.locked else 0.055)
        if motion.current_speed < 0.025 and motion.special == "":
            low = clearance < 0.14
        if foot.locked and raw.distance_to(foot.anchor)>0.22:
            low = false # Never stretch a planted leg beyond the correction budget.
        if low and not foot.locked:
            foot.anchor = raw
            foot.anchor.y = floor_y+0.085
            foot.locked = true
        elif not low:
            foot.locked = false
        foot.weight = move_toward(foot.weight,1.0 if foot.locked else 0.0,delta*12.0)
        # Airborne foot remains authored. Support feet follow the actual hit surface.
        var desired: Vector3 = raw.lerp(foot.anchor,foot.weight)
        if clearance < 0.015:
            desired.y = maxf(desired.y,raw.y+0.015-clearance)
        var correction := desired-raw
        correction = correction.limit_length(0.22)
        desired = raw+correction
        _solve_leg(sk,foot,sk.global_transform.affine_inverse()*desired)
        var final := sk.global_transform*sk.get_bone_global_pose(foot.ankle).origin
        if foot.locked and foot.last_contact and foot.weight > 0.95:
            var r: Vector3 = raw-foot.previous_raw
            var c: Vector3 = final-foot.previous_final
            r.y=0;c.y=0
            var phase: String = motion.special if motion.special != "" else ("Walk" if motion.current_speed>0.1 else "Idle")
            if not metrics.phases.has(phase):
                metrics.phases[phase] = {"samples":0,"raw_slide_sum":0.0,"corrected_slide_sum":0.0}
            metrics.phases[phase].samples += 1
            metrics.phases[phase].raw_slide_sum += r.length()
            metrics.phases[phase].corrected_slide_sum += c.length()
            metrics.samples += 1
            metrics.raw_slide_sum += r.length()
            metrics.corrected_slide_sum += c.length()
        metrics.max_correction = maxf(metrics.max_correction,correction.length())
        foot.previous_raw = raw
        foot.previous_final = final
        foot.last_contact = foot.locked

func _rotate_global(sk: Skeleton3D, bone: int, rotation: Quaternion) -> void:
    var parent := sk.get_bone_parent(bone)
    var parent_rotation := sk.get_bone_global_pose(parent).basis.get_rotation_quaternion() if parent >= 0 else Quaternion.IDENTITY
    sk.set_bone_pose_rotation(bone,parent_rotation.inverse()*rotation)

func _solve_leg(sk: Skeleton3D, foot: Dictionary, target: Vector3) -> void:
    var hip_pose := sk.get_bone_global_pose(foot.hip)
    var knee_pose := sk.get_bone_global_pose(foot.knee)
    var ankle_pose := sk.get_bone_global_pose(foot.ankle)
    var saved_ankle_rotation := ankle_pose.basis.get_rotation_quaternion()
    var a := hip_pose.origin
    var b := knee_pose.origin
    var c := ankle_pose.origin
    var upper := a.distance_to(b)
    var lower := b.distance_to(c)
    var direction := (target-a).normalized()
    var distance := clampf(a.distance_to(target),absf(upper-lower)+0.001,upper+lower-0.001)
    var pole := (b-a)-direction*(b-a).dot(direction)
    if pole.length_squared()<0.00001:
        pole = sk.global_basis.inverse()*(actor.global_basis*Vector3.FORWARD)
        pole -= direction*pole.dot(direction)
    pole = pole.normalized()
    var along := (upper*upper-lower*lower+distance*distance)/(2.0*distance)
    var height := sqrt(maxf(upper*upper-along*along,0.0))
    var new_knee := a+direction*along+pole*height
    var rotation := Quaternion((b-a).normalized(),(new_knee-a).normalized())*hip_pose.basis.get_rotation_quaternion()
    _rotate_global(sk,foot.hip,rotation)
    knee_pose = sk.get_bone_global_pose(foot.knee)
    ankle_pose = sk.get_bone_global_pose(foot.ankle)
    rotation = Quaternion((ankle_pose.origin-knee_pose.origin).normalized(),(target-knee_pose.origin).normalized())*knee_pose.basis.get_rotation_quaternion()
    _rotate_global(sk,foot.knee,rotation)
    # Retain the authored foot orientation after solving the ankle position.
    _rotate_global(sk,foot.ankle,saved_ankle_rotation)
    var final_hip := sk.get_bone_global_pose(foot.hip).origin
    var final_knee := sk.get_bone_global_pose(foot.knee).origin
    var final_ankle := sk.get_bone_global_pose(foot.ankle).origin
    metrics.max_segment_error = maxf(metrics.max_segment_error,maxf(absf(final_hip.distance_to(final_knee)-upper),absf(final_knee.distance_to(final_ankle)-lower)))
