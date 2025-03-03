extends Node2D


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		IndieBlueprintSceneTransitioner.transition_to(
			"res://test_scene_2.tscn",
			IndieBlueprintPremadeTransitions.Dissolve,
			IndieBlueprintPremadeTransitions.Dissolve,
			{ 	"in": {"texture": IndieBlueprintPremadeTransitions.HorizontalPaintBrush, "duration": 1.0, "color": Color.LIGHT_SKY_BLUE},
				"out": {"texture": IndieBlueprintPremadeTransitions.VerticalPaintBrush, "duration": 1.5, "color": Color.LIGHT_SEA_GREEN,}
			}
		)
