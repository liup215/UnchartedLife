extends Resource
class_name QuestData

# Data-only resource for quest definition

enum QuestStatus { INACTIVE, ACTIVE, COMPLETED, FAILED }

@export var id: String = ""            # Unique quest id
@export var title_key: String = ""      # i18n key
@export var desc_key: String = ""       # i18n key

@export var objectives: Array[ObjectiveData] = []
@export var dependencies: Array[String] = []
@export var auto_start: bool = false

# Rewards (data only; delivery handled by managers)
@export var reward_items: Array[Dictionary] = []  # [{id: String, count: int}]
@export var reward_exp: int = 0
@export var reward_unlock_flags: Array[String] = []

func has_objectives() -> bool:
	return not objectives.is_empty()
