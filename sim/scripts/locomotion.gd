extends Node
## Imported authored clips; animation playback follows measured, collision-resolved speed.
var player: AnimationPlayer
var tree: AnimationTree
var nominal_speed := 1.0
var blend := 0.0
var current_speed := 0.0

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
    graph.connect_node("output",0,"Blend")
    tree.tree_root = graph
    tree.active = true

func update_motion(speed: float, delta: float) -> void:
    current_speed = speed
    blend = move_toward(blend, smoothstep(0.02,0.32,speed),delta*6.0)
    tree.set("parameters/Blend/blend_amount",blend)
    tree.set("parameters/Rate/scale",clampf(speed/nominal_speed,0.0,1.7))
