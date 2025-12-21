extends Resource
class_name DialogueConditionData

enum ConditionType { ALWAYS, QUEST_ACTIVE, QUEST_COMPLETED, QUEST_NOT_STARTED, FLAG_SET }

@export var condition_type: ConditionType = ConditionType.ALWAYS
@export var quest_id: String = ""
@export var flag: String = ""
@export var negate: bool = false
