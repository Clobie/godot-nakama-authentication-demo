extends Node

var transition_instance = null
var changing_scene = false
var next_scene = ''

var scene_fade_time = 0.25

func _ready():
	transition_instance = load("res://global/scenes/transition.tscn").instantiate()
	add_child(transition_instance)

func _physics_process(_delta):
	if changing_scene:
		if !transition_instance.busy():
			changing_scene = false
			get_tree().change_scene_to_file(next_scene)
			next_scene = ''
			fade_in(scene_fade_time)

func fade_out(time: float):
	transition_instance.fade_out(time)

func fade_in(time: float):
	transition_instance.fade_in(time)

func busy():
	return transition_instance.busy()

func change_to_scene(scene: String):
	fade_out(scene_fade_time)
	next_scene = scene
	changing_scene = true
