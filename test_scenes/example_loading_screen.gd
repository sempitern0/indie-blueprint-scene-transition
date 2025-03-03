class_name IndieBlueprintExampleLoadingScreen extends IndieBlueprintLoadingScreen


@onready var color_rect: ColorRect = $ColorRect
@onready var progress_bar: ProgressBar = $ProgressBar


func _process(delta: float) -> void:
	super._process(delta)
	
	progress_bar.value = current_progress_value
