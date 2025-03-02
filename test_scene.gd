extends Node2D


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		IndieBlueprintSceneTransitioner.transition_to("res://test_scene_2.tscn")
