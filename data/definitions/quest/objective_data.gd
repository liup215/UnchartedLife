extends Resource
class_name ObjectiveData

# Supports leaf and composite objectives for hierarchical quests

enum ObjectiveType { COLLECT, REACH, DEFEAT, INTERACT, QUIZ, TIME_LIMIT, CUSTOM }
enum CompletionPolicy { ALL, ANY, COUNT }

@export var type: ObjectiveType = ObjectiveType.CUSTOM
@export var optional: bool = false

# Parameters for leaf objectives (e.g., {"item_id": "glucose", "count": 10})
@export var params: Dictionary = {}

# Event name to track progress via EventBus (e.g., "inventory_item_added")
@export var track_via_event: String = ""

# Composite support
@export var sub_objectives: Array[ObjectiveData] = []
@export var policy: CompletionPolicy = CompletionPolicy.ALL
@export var target_count: int = 0  # Used when policy == COUNT

func is_leaf() -> bool:
	return sub_objectives.is_empty()
