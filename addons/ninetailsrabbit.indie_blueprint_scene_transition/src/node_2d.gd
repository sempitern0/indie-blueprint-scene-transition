extends Node2D


func _ready() -> void:
	IndieBlueprintSceneTransitioner.transition_to("res://").use_subthreads(true)
