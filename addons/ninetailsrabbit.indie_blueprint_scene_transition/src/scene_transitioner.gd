extends Node

signal transition_requested(next_scene: String)
signal transition_finished(next_scene: String)


@export var transitions: Array[IndieBlueprintSceneTransitionConfiguration] = []
@export var use_subthreads: bool = false

@onready var canvas_layer: CanvasLayer = $CanvasLayer

var next_scene_path: String = ""
var current_transition: IndieBlueprintSceneTransition


func _process(delta: float) -> void:
	if _filepath_is_valid(next_scene_path):
		var progress: Array = []
		print(ResourceLoader.load_threaded_get_status(next_scene_path, progress))
		print("progress ", progress.pop_back())


func transition_to(
	scene,
	in_transition_id: StringName = IndieBlueprintPremadeTransitions.ColorFade,
	out_transition_id: StringName = IndieBlueprintPremadeTransitions.ColorFade,
	## A dictionary with "in" and "out" keys to pass the arguments to the corresponding transitions
	args: Dictionary = {} 
) -> void:
	next_scene_path = scene.resource_path if scene is PackedScene else scene
	
	if not _filepath_is_valid(next_scene_path):
		push_error("IndieBlueprintSceneTransitioner: The scene path %s is not a valid resource to load, aborting scene transition..." % next_scene_path)
		next_scene_path = ""
		return
	
	transition_requested.emit(next_scene_path)

	var in_transition: IndieBlueprintSceneTransitionConfiguration = transition_by_id(in_transition_id)
	
	if in_transition:
		current_transition = in_transition.scene.instantiate()
		canvas_layer.add_child(current_transition)
		
		current_transition.in_transition_finished.connect(func():
			if get_load_status() == ResourceLoader.THREAD_LOAD_LOADED:
				change_to_loaded_scene(next_scene_path)
				transition_finished.emit(next_scene_path)
				
				next_scene_path = ""
				
				if in_transition.id == out_transition_id:
					current_transition.transition_out(args.get_or_add("out", {}))
				else:
					var out_transition: IndieBlueprintSceneTransitionConfiguration = transition_by_id(out_transition_id)
					
					if out_transition:
						current_transition = out_transition.scene.instantiate()
						canvas_layer.add_child(current_transition)
						
						current_transition.transition_out(args.get_or_add("out", {}))
				, CONNECT_ONE_SHOT)
				
		current_transition.transition_in(args.get_or_add("in", {}))
		
		var load_error: Error = ResourceLoader.load_threaded_request(next_scene_path, "", use_subthreads)
		
		if load_error != OK:
			push_error("An error %s happened when trying to load the scene %s " % [error_string(load_error), next_scene_path])
			current_transition.queue_free()


func change_to_loaded_scene(next_scene: String = next_scene_path) -> void:
	get_tree().call_deferred("change_scene_to_packed", ResourceLoader.load_threaded_get(next_scene))


func get_load_status(progress: Array = []) -> ResourceLoader.ThreadLoadStatus:
	return ResourceLoader.load_threaded_get_status(next_scene_path, progress)


func transition_by_id(id: StringName) -> IndieBlueprintSceneTransitionConfiguration:
	if id.is_empty():
		return null
		
	var found_transitions: Array[IndieBlueprintSceneTransitionConfiguration] = transitions.filter(
			func(transition: IndieBlueprintSceneTransitionConfiguration): return id == transition.id
		)
	
	if found_transitions.is_empty():
		return null
		
	return found_transitions.front()


func _filepath_is_valid(path: String) -> bool:
	return not path.is_empty() and path.is_absolute_path() and ResourceLoader.exists(path)
