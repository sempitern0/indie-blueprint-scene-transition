extends Node

signal transition_requested(next_scene: String)
signal transition_finished(next_scene: String)


var next_scene_path: String
