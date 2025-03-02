extends Node2D

@export var test_transition_scene: PackedScene
@export_file("*.tscn") var test_transition_path: String


func _ready() -> void:
	IndieBlueprintSceneTransitioner.transition_to(
		test_transition_scene,
		IndieBlueprintPremadeTransitions.ColorFade,
		IndieBlueprintPremadeTransitions.ColorFade,
		{
			"in": {"duration": 2.5, "color": Color.DEEP_PINK}, 
			"out": {"duration": 1.0, "color": Color.GREEN}
		}
	)
