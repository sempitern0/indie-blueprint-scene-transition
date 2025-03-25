extends Node2D


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		IndieBlueprintSceneTransitioner.transition_to_with_loading_screen(
			"res://test_scenes/test_scene_2.tscn",
			"res://test_scenes/example_loading_screen.tscn",
			IndieBlueprintPremadeTransitions.Dissolve,
			IndieBlueprintPremadeTransitions.Dissolve,
			{ 	"in": {"texture": IndieBlueprintPremadeTransitions.VerticalPaintBrush, "duration": 1.0, "color": Color.BLACK},
				"out": {"texture": IndieBlueprintPremadeTransitions.VerticalPaintBrush, "duration": 1.5, "color": Color.BLACK,}
			}
		)
