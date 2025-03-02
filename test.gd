extends Node2D

@export var test_transition_scene: PackedScene
@export_file("*.tscn") var test_transition_path: String


func _ready() -> void:
	IndieBlueprintSceneTransitioner.transition_to(
		test_transition_scene,
	)
