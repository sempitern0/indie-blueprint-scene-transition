extends Node

signal transition_requested(next_scene: String)
signal transition_finished(next_scene: String)
signal load_finished(next_scene: String)

@export var transitions: Array[IndieBlueprintSceneTransitionConfiguration] = []
@export var use_subthreads: bool = false
@export var progress_smooth_factor: float = 5.0

@onready var canvas_layer: CanvasLayer = $CanvasLayer

var next_scene_path: String = "":
	set(new_path):
		if new_path != next_scene_path:
			next_scene_path = new_path
			
		set_process(not next_scene_path.is_empty())
			
var current_transition: IndieBlueprintSceneTransition
var current_progress: Array = []
var current_progress_value: float = 0.0:
	set(value):
		current_progress_value = clampf(value, 0.0, 100.0)


func _process(delta: float) -> void:
	if _filepath_is_valid(next_scene_path):
		var load_status := _get_load_status(current_progress)
		current_progress_value = lerp(current_progress_value, current_progress[0] * 100.0, delta * progress_smooth_factor)
		
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			current_progress_value = 100.0
			
			_change_to_loaded_scene(next_scene_path)
			load_finished.emit(next_scene_path)


func _ready() -> void:
	set_process(not next_scene_path.is_empty())
	
	transition_finished.connect(on_transition_finished)


func transition_to(
	scene,
	in_transition_id: StringName = IndieBlueprintPremadeTransitions.ColorFade,
	out_transition_id: StringName = IndieBlueprintPremadeTransitions.ColorFade,
	## A dictionary with "in" and "out" keys to pass the arguments to the corresponding transitions
	args: Dictionary = {} 
) -> void:
	## A current transition is happening
	if is_processing():
		return
		
	next_scene_path = scene.resource_path if scene is PackedScene else scene
	
	if not _filepath_is_valid(next_scene_path):
		push_error("IndieBlueprintSceneTransitioner: The scene path %s is not a valid resource to load, aborting scene transition..." % next_scene_path)
		load_finished.emit(next_scene_path)
		return
	
	transition_requested.emit(next_scene_path)

	var in_transition: IndieBlueprintSceneTransitionConfiguration = get_transition_by_id(in_transition_id)
	
	if in_transition == null:
		push_error("IndieBlueprintSceneTransitioner: The transition with id %s was not found, aborting the transition..." % in_transition_id)
		load_finished.emit(next_scene_path)
	else:
		## Prepare the in-transition
		current_transition = in_transition.scene.instantiate()
		canvas_layer.add_child(current_transition)
		
		current_transition.in_transition_finished.connect(
			on_in_transition_finished.bind(in_transition_id, out_transition_id, args), 
			CONNECT_ONE_SHOT)
			
		current_transition.out_transition_finished.connect(
			on_out_transition_finished.bind(current_transition), 
			CONNECT_ONE_SHOT)
		
		## Initialize the first transition
		current_transition.transition_in(args.get_or_add("in", {}))
		

func _change_to_loaded_scene(next_scene: String = next_scene_path) -> void:
	get_tree().call_deferred("change_scene_to_packed", ResourceLoader.load_threaded_get(next_scene))


func _get_load_status(progress: Array = []) -> ResourceLoader.ThreadLoadStatus:
	return ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	

func get_transition_by_id(id: StringName) -> IndieBlueprintSceneTransitionConfiguration:
	if id.is_empty():
		return null
		
	var found_transitions: Array[IndieBlueprintSceneTransitionConfiguration] = transitions.filter(
			func(transition: IndieBlueprintSceneTransitionConfiguration): return id == transition.id
		)
	
	if found_transitions.is_empty():
		return null
		
	return found_transitions.front()


func _remove_current_transition() -> void:
	if current_transition and not current_transition.is_queued_for_deletion():
		current_transition.queue_free()
	
	current_transition = null


func _filepath_is_valid(path: String) -> bool:
	return not path.is_empty() and path.is_absolute_path() and ResourceLoader.exists(path)


#region Signal callbacks
func on_in_transition_finished(in_transition_id: StringName, out_transition_id: StringName, args: Dictionary) -> void:
	var load_error: Error = ResourceLoader.load_threaded_request(next_scene_path, "", use_subthreads)
	
	if load_error != OK:
		push_error("An error %s happened when trying to load the scene %s " % [error_string(load_error), next_scene_path])
		load_finished.emit(next_scene_path)

	if _get_load_status(current_progress) == ResourceLoader.THREAD_LOAD_LOADED:
		_change_to_loaded_scene(next_scene_path)
		load_finished.emit(next_scene_path)
		
		
	if in_transition_id == out_transition_id:
		current_transition.transition_out(args.get_or_add("out", {}))
	else:
		if current_transition:
			current_transition.queue_free()
			current_transition = null
	
		var out_transition: IndieBlueprintSceneTransitionConfiguration = get_transition_by_id(out_transition_id)
		
		if out_transition:
			current_transition = out_transition.scene.instantiate()
			canvas_layer.add_child(current_transition)
			
			current_transition.transition_out(args.get_or_add("out", {}))


func on_out_transition_finished(out_transition: IndieBlueprintSceneTransition) -> void:
	out_transition.queue_free()
	transition_finished.emit(next_scene_path)


func on_transition_finished(_next_scene_path: String) -> void:
	next_scene_path = ""
	_remove_current_transition()


func on_load_finished(_next_scene_path: String) -> void:
	current_progress.clear()
	
	## A little delay in case the load bar is still visible when changing scenes 
	## to avoid show how the load bar goes from 100 to 0.
	await get_tree().create_timer(1.0)
	current_progress_value = 0.0
#endregion
