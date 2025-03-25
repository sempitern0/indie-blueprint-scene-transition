extends Node2D


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		IndieBlueprintSceneTransitioner.transition_to(
			"res://test_scenes/test_scene.tscn",
			IndieBlueprintPremadeTransitions.Dissolve,
			IndieBlueprintPremadeTransitions.Dissolve,
			{ 	"in": {"texture": IndieBlueprintPremadeTransitions.HorizontalPaintBrush, "duration": 1.0, "color": Color.BLACK},
				"out": {"texture": IndieBlueprintPremadeTransitions.HorizontalPaintBrush, "duration": 1.5, "color": Color.BLACK,}
			}
		)
