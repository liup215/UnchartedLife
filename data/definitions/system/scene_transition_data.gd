# scene_transition_data.gd
# Resource defining a single scene transition with loading screen configuration
extends Resource
class_name SceneTransitionData

## Scene to load (path to .tscn file)
@export var scene_path: String = ""

## Unique identifier for this scene
@export var scene_id: String = ""

## Display name for the scene
@export var scene_name: String = ""

## Loading screen image
@export var loading_image: Texture2D = null

## Loading screen text
@export_multiline var loading_text: String = "Loading..."

## Signal name to listen for completion (e.g., "tutorial_completed", "level_completed")
## If empty, scene is considered non-transitional (doesn't auto-advance)
@export var completion_signal: String = ""

## Condition to check before loading this scene (optional)
## Uses PlayerData properties, e.g., "completed_microscope_tutorial"
@export var required_condition: String = ""

## Should this scene hide the game scene (true for overlays like prologues)
@export var is_overlay: bool = true

## Should system menu be disabled during this scene
@export var disable_system_menu: bool = true

## Delay before hiding loading screen (seconds)
@export var loading_screen_delay: float = 1.0

## PlayerData property to set when this scene completes
@export var completion_flag: String = ""

func can_load() -> bool:
	"""Check if conditions are met to load this scene"""
	if required_condition.is_empty():
		return true
	
	# Check PlayerData for the condition
	if PlayerData and required_condition in PlayerData:
		return PlayerData.get(required_condition) == true
	
	return false

func to_dict() -> Dictionary:
	"""Convert to dictionary for saving"""
	return {
		"scene_path": scene_path,
		"scene_id": scene_id,
		"scene_name": scene_name,
		"loading_text": loading_text,
		"completion_signal": completion_signal,
		"required_condition": required_condition,
		"is_overlay": is_overlay,
		"disable_system_menu": disable_system_menu,
		"loading_screen_delay": loading_screen_delay,
		"completion_flag": completion_flag
	}
