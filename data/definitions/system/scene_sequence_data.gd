# scene_sequence_data.gd
# Resource defining a sequence of scene transitions (e.g., prologue sequence, tutorial chain)
extends Resource
class_name SceneSequenceData

## Unique identifier for this sequence
@export var sequence_id: String = ""

## Display name
@export var sequence_name: String = ""

## Ordered array of scene transitions
@export var transitions: Array[SceneTransitionData] = []

## Should this sequence start automatically when conditions are met
@export var auto_start: bool = false

## Condition to check before starting sequence (uses PlayerData properties)
@export var start_condition: String = ""

## What happens after sequence completes
enum SequenceCompletion {
	CONTINUE_GAMEPLAY,  ## Let game_scene take over
	LOAD_NEXT_SEQUENCE, ## Load another sequence
	CUSTOM             ## Custom handling needed
}

@export var on_completion: SequenceCompletion = SequenceCompletion.CONTINUE_GAMEPLAY

## If on_completion is LOAD_NEXT_SEQUENCE, this is the next sequence ID
@export var next_sequence_id: String = ""

func can_start() -> bool:
	"""Check if conditions are met to start this sequence"""
	if start_condition.is_empty():
		return auto_start
	
	# Check PlayerData for the condition
	if PlayerData and start_condition in PlayerData:
		return PlayerData.get(start_condition) == true
	
	return false

func get_next_transition(current_index: int) -> SceneTransitionData:
	"""Get the next transition in the sequence"""
	if current_index + 1 < transitions.size():
		return transitions[current_index + 1]
	return null

func to_dict() -> Dictionary:
	"""Convert to dictionary for saving"""
	var transitions_data: Array = []
	for transition in transitions:
		transitions_data.append(transition.to_dict())
	
	return {
		"sequence_id": sequence_id,
		"sequence_name": sequence_name,
		"transitions": transitions_data,
		"auto_start": auto_start,
		"start_condition": start_condition,
		"on_completion": on_completion,
		"next_sequence_id": next_sequence_id
	}
