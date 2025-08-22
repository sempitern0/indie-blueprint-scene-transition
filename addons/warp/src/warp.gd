class_name WarpTransitioner extends Node

signal transition_requested(next_scene: String)
signal transition_finished(next_scene: String)
signal load_finished(transition: CurrentTransition)

class CurrentTransition extends RefCounted:
	var next_scene_path: String
	var loading_screen_path: String
	var use_subthreads: bool = false
	var loaded: bool = false
	var locked: bool = false
	var transition_in: Dictionary = {"transition": null, "args": {}}
	var transition_out: Dictionary = {"transition": null, "args": {}}
	
@export var transitions: Array[WarpTransitionConfiguration] = []

@onready var canvas_layer: CanvasLayer = $CanvasLayer

## After using the ResourceLoader into a PackedScene the resource_path can be returned empty
## so to avoid this error we keep the reference on the first load and use it in the transition
## https://stackoverflow.com/questions/77729092/is-resourceloader-meant-to-cache-loaded-resources
var scenes_references_paths: Dictionary[PackedScene, String] = {}

#var next_scene_path: String = ""
## This variable is used as flag to know if the scene is already loaded when the in-transition finished
## or instead follow the _process and change when the loading is finished there.

var current_progress: Array = []
var current_transition: CurrentTransition:
	set(value):
		current_transition = value
		
		if current_transition == null:
			set_process(false)


func _ready() -> void:
	set_process(false)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if is_instance_valid(current_transition):
		var load_status: ResourceLoader.ThreadLoadStatus = _get_load_status(current_progress)
		
		match load_status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				pass
			ResourceLoader.THREAD_LOAD_LOADED:
				if current_transition:
					load_finished.emit(current_transition)
					get_tree().call_deferred("change_scene_to_packed", ResourceLoader.load_threaded_get(current_transition.next_scene_path))
					current_transition = null
					
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Warp: An error %s happened in the process of loading the scene %s, aborting the transition..." %[error_string(load_status), current_transition.next_scene_path] )
				load_finished.emit(current_transition)
				current_transition = null
				
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Warp: An error %s happened, the scene %s is invalid, aborting the transition..." %[error_string(load_status), current_transition.next_scene_path] )
				load_finished.emit(current_transition)
				current_transition = null


func transition_to(scene: Variant) -> WarpTransitioner:
	if current_transition == null:
		current_transition = CurrentTransition.new()
		
	if scene is PackedScene:
		current_transition.next_scene_path = scene.resource_path
	elif typeof(scene) == TYPE_STRING_NAME or typeof(scene) == TYPE_STRING:
		current_transition.next_scene_path = scene
	else:
		current_transition = null
		push_error("Warp: The scene %s to transition is not a valid PackedScene or path" % scene)
	
	return self


func use_subthreads(enable: bool = false) -> WarpTransitioner:
	if current_transition == null:
		current_transition = CurrentTransition.new()
		
	current_transition.use_subthreads = enable

	return self
	

func in_transition(transition_id: StringName, args: Dictionary = {}) -> WarpTransitioner:
	var transition: WarpTransitionConfiguration = get_transition_by_id(transition_id)
	
	if transition:
		if current_transition == null:
			current_transition = CurrentTransition.new()
		
		current_transition.transition_in["transition"] = transition.scene.instantiate() as WarpTransition
		current_transition.transition_in["args"] = args
	

	return self


func out_transition(transition_id: StringName, args: Dictionary = {}) -> WarpTransitioner:
	var transition: WarpTransitionConfiguration = get_transition_by_id(transition_id)
	
	if transition:
		if current_transition == null:
			current_transition = CurrentTransition.new()
			
		current_transition.transition_out["transition"] = transition.scene.instantiate() as WarpTransition
		current_transition.transition_out["args"] = args
		
	return self


func with_loading_screen(loading_screen_path: String) -> WarpTransitioner:
	if current_transition == null:
		current_transition = CurrentTransition.new()
		
	current_transition.loading_screen_path = loading_screen_path

	return self
	
	
func apply() -> void:
	if is_instance_valid(current_transition) \
		and not current_transition.locked \
		and ResourceLoader.exists(current_transition.next_scene_path):
			
		current_transition.locked = true
		load_finished.connect(on_scene_load_finished, CONNECT_ONE_SHOT)
			
		if current_transition.transition_in.transition:
			canvas_layer.add_child(current_transition.transition_in.transition)
			current_transition.transition_in.transition.transition_in(current_transition.transition_in.args)
			await current_transition.transition_in.transition.in_transition_finished
		
		if ResourceLoader.exists(current_transition.loading_screen_path):
			var loading_screen: WarpLoadingScreen = load(current_transition.loading_screen_path).instantiate() as WarpLoadingScreen
			loading_screen.next_scene_path = current_transition.next_scene_path
			loading_screen.use_subthreads = current_transition.use_subthreads
	
			canvas_layer.add_child(loading_screen)
			loading_screen.finished.connect(on_loading_screen_finished.bind(loading_screen), CONNECT_ONE_SHOT)
			loading_screen.failed.connect(on_loading_screen_failed, CONNECT_ONE_SHOT)
			
			if current_transition.transition_in.transition:
				current_transition.transition_in.transition.queue_free()
		else:
			var load_request_error: Error = ResourceLoader.load_threaded_request(
				 current_transition.next_scene_path, 
				"PackedScene", 
				current_transition.use_subthreads
				)
				
			if load_request_error == OK:
				call_deferred("set_process", true)
			else:	
				push_error("Warp: An error %s happened when trying to load the scene %s " % [error_string(load_request_error), current_transition.next_scene_path])
				current_transition = null
	else:
		push_warning("Warp: There is no current transition to apply, aborting...")
		current_transition = null


func get_transition_by_id(id: StringName) -> WarpTransitionConfiguration:
	if id.is_empty():
		return null
		
	var found_transitions: Array[WarpTransitionConfiguration] = transitions.filter(
			func(transition: WarpTransitionConfiguration): return transition and id == transition.id
		)
	
	if found_transitions.is_empty():
		return null
		
	return found_transitions.front()
	
	
func add_transition_configuration(conf: WarpTransitionConfiguration) -> void:
	if not transitions.has(conf):
		transitions.append(conf)


func remove_transition_configuration(conf: WarpTransitionConfiguration) -> void:
	transitions.erase(conf)


func _get_load_status(progress: Array = []) -> ResourceLoader.ThreadLoadStatus:
	return ResourceLoader.load_threaded_get_status(current_transition.next_scene_path, progress)
	

func on_scene_load_finished(transition: CurrentTransition) -> void:
	if transition.transition_in.transition:
		transition.transition_in.transition.queue_free()
	
	if not ResourceLoader.exists(transition.loading_screen_path) and transition.transition_out.transition:
		canvas_layer.add_child(transition.transition_out.transition)
		transition.transition_out.transition.transition_out(current_transition.transition_out.args)
		await transition.transition_out.transition.out_transition_finished
		transition.transition_out.transition.queue_free()


func on_loading_screen_finished(next_scene: PackedScene, loading_screen: WarpLoadingScreen) -> void:
	loading_screen.queue_free()
	get_tree().call_deferred("change_scene_to_packed", next_scene)
	
	if current_transition.transition_out.transition:
		
		canvas_layer.add_child(current_transition.transition_out.transition)
		current_transition.transition_out.transition.transition_out(current_transition.transition_out.args)
		await current_transition.transition_out.transition.out_transition_finished
		current_transition.transition_out.transition.queue_free()
		
	current_transition = null
	

func on_loading_screen_failed(error: ResourceLoader.ThreadLoadStatus) -> void:
	if current_transition.transition_out.transition:
		canvas_layer.add_child(current_transition.transition_out.transition)
		current_transition.transition_out.transition.transition_out(current_transition.transition_out.args)
		await current_transition.transition_out.transition.out_transition_finished
		current_transition.transition_out.transition.queue_free()
		
	current_transition = null
