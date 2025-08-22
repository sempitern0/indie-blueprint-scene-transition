extends Node2D


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		Warp\
			.transition_to("res://test_scenes/test_scene.tscn")\
			.use_subthreads(true)\
			.in_transition(&"color_fade", {"color": Color.WEB_GRAY})\
			.out_transition(&"color_fade", {"color": Color.WEB_GRAY})\
			.apply()
