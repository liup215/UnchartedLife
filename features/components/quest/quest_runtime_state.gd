extends RefCounted
class_name QuestRuntimeState

# Runtime-only state separate from data resources

const STATUS_INACTIVE := 0
const STATUS_ACTIVE := 1
const STATUS_COMPLETED := 2
const STATUS_FAILED := 3

var quest_id: String
var status: int = STATUS_INACTIVE
var objective_states: Array[ObjectiveRuntimeState] = []

func _init(id: String) -> void:
	quest_id = id

class ObjectiveRuntimeState:
	var type: int
	var progress: float = 0.0
	var is_complete: bool = false
	var optional: bool = false
	var params: Dictionary = {}
	var track_via_event: String = ""
	var sub_states: Array[ObjectiveRuntimeState] = []
	var policy: int = 0
	var target_count: int = 0
