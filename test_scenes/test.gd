extends Node2D

@export var next_scene: PackedScene

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		IndieBlueprintSceneTransitioner.transition_to(
			next_scene,
			IndieBlueprintPremadeTransitions.Dissolve,
			IndieBlueprintPremadeTransitions.Dissolve,
			{ 	"in": {"texture": IndieBlueprintPremadeTransitions.HorizontalPaintBrush, "duration": 1.0, "color": Color.BLACK},
				"out": {"texture": IndieBlueprintPremadeTransitions.HorizontalPaintBrush, "duration": 1.5, "color": Color.BLACK,}
			}
		)
