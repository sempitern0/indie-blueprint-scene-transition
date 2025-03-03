extends Node2D


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		IndieBlueprintSceneTransitioner.transition_to(
			"res://test_scene_2.tscn",
			IndieBlueprintPremadeTransitions.ColorFade,
			IndieBlueprintPremadeTransitions.Voronoi,
			{ 	"in": {"duration": 2.5, "color": Color.LIGHT_SKY_BLUE, "flip": true},
				"out": {"duration": 1.5, "color": Color.LIGHT_SEA_GREEN,  "flip": true}
			}
		)
