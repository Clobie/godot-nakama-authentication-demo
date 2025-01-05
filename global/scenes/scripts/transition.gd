extends ColorRect

@onready var animation_player = $AnimationPlayer

func fade_out(time: float):
	animation_player.speed_scale = 1 / time
	animation_player.play("fade_out")

func fade_in(time: float):
	animation_player.speed_scale = 1 / time
	animation_player.play("fade_in")

func busy():
	return animation_player.is_playing()
