extends Node2D


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		IndieBlueprintSceneTransitioner\
			.transition_to("res://test_scenes/test_scene_2.tscn")\
			.use_subthreads(true)\
			.in_transition(&"color_fade")\
			.out_transition(&"color_fade")\
			#.with_loading_screen("res://test_scenes/example_loading_screen.tscn")\
			.apply()
