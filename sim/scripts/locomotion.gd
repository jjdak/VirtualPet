extends Node
## Imported authored clips; animation playback follows measured, collision-resolved speed.
var player: AnimationPlayer
var tree: AnimationTree
var nominal_speed := 1.0
var blend := 0.0
var current_speed := 0.0
var transitions: Dictionary
var special := ""
var special_time := 0.0
var special_start_angle := 0.0
var last_root := Vector3.ZERO
var action_node: AnimationNodeAnimation
var action_weight := 0.0
var completed_specials: Array[String] = []

func setup(avatar: Node3D, walk_scene: PackedScene, measured_speed: float) -> void:
    player = avatar.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
    var donor := walk_scene.instantiate()
    var donor_player := donor.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
    var library := AnimationLibrary.new()
    for pair in [[player,"Idle"],[donor_player,"Walk"]]:
        for clip in pair[0].get_animation_list():
            if clip == "RESET":
                continue
            var animation: Animation = pair[0].get_animation(clip).duplicate(true)
            animation.loop_mode = Animation.LOOP_LINEAR
            library.add_animation(pair[1],animation)
            break
    transitions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/private/transitions.json")).clips
    for name in ["TurnLeft","TurnRight","Stop"]:
        var scene: Node = load("res://assets/private/girl-a-"+name.to_lower()+".glb").instantiate()
        var source_player: AnimationPlayer = scene.find_children("*","AnimationPlayer",true,false)[0]
        for clip in source_player.get_animation_list():
            if clip != "RESET":
                var animation: Animation = source_player.get_animation(clip).duplicate(true)
                animation.loop_mode = Animation.LOOP_NONE
                library.add_animation(name,animation)
                break
        scene.free()
    player.stop()
    player.add_animation_library("Motion",library)
    donor.free()
    nominal_speed = measured_speed
    tree = AnimationTree.new()
    avatar.add_child(tree)
    tree.anim_player = tree.get_path_to(player)
    var graph := AnimationNodeBlendTree.new()
    var idle := AnimationNodeAnimation.new()
    idle.animation = "Motion/Idle"
    var walk := AnimationNodeAnimation.new()
    walk.animation = "Motion/Walk"
    graph.add_node("Idle",idle)
    graph.add_node("Walk",walk)
    graph.add_node("Rate",AnimationNodeTimeScale.new())
    graph.add_node("Blend",AnimationNodeBlend2.new())
    graph.connect_node("Rate",0,"Walk")
    graph.connect_node("Blend",0,"Idle")
    graph.connect_node("Blend",1,"Rate")
    action_node = AnimationNodeAnimation.new()
    action_node.animation = "Motion/Stop"
    graph.add_node("Action",action_node)
    graph.add_node("Seek",AnimationNodeTimeSeek.new())
    graph.add_node("Final",AnimationNodeBlend2.new())
    graph.connect_node("Seek",0,"Action")
    graph.connect_node("Final",0,"Blend")
    graph.connect_node("Final",1,"Seek")
    graph.connect_node("output",0,"Final")
    tree.tree_root = graph
    tree.active = true

func update_motion(speed: float, delta: float) -> void:
    current_speed = speed
    blend = move_toward(blend, smoothstep(0.02,0.32,speed),delta*6.0)
    tree.set("parameters/Blend/blend_amount",blend)
    tree.set("parameters/Rate/scale",clampf(speed/nominal_speed,0.0,1.7))
    tree.set("parameters/Final/blend_amount",action_weight)

func begin_action(name: String, angle: float) -> void:
    special = name
    special_time = 0.0
    special_start_angle = angle
    last_root = Vector3.ZERO
    action_node.animation = "Motion/"+name
    tree.set("parameters/Seek/seek_request",0.0)

func advance_action(delta: float) -> Dictionary:
    var data: Dictionary = transitions[special]
    special_time = minf(special_time+delta,float(data.duration))
    var samples: Array = data.root_samples
    var at := special_time*30.0
    var i := mini(int(at),samples.size()-1)
    var j := mini(i+1,samples.size()-1)
    var fraction := at-float(i)
    var a: Array = samples[i].position
    var b: Array = samples[j].position
    var position := Vector3(a[0],a[1],a[2]).lerp(Vector3(b[0],b[1],b[2]),fraction)
    var root_delta := position-last_root
    last_root = position
    var angle := lerpf(samples[i].yaw,samples[j].yaw,fraction)
    action_weight = minf(special_time/0.13,(float(data.duration)-special_time)/0.17)
    action_weight = clampf(action_weight,0.0,1.0)
    var result := {"velocity":root_delta.rotated(Vector3.UP,special_start_angle)/delta,"angle":special_start_angle+angle}
    if special_time >= float(data.duration):
        completed_specials.append(special)
        special = ""
    return result

func reset_motion() -> void:
    special = ""
    action_weight = 0.0
    blend = 0.0
    current_speed = 0.0
    completed_specials.clear()
    tree.set("parameters/Final/blend_amount",0.0)
