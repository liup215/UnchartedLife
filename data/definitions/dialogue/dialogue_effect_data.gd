extends Resource
class_name DialogueEffectData

enum EffectType { EMIT_EVENT, START_QUEST, COMPLETE_QUEST, SET_FLAG }

@export var effect_type: EffectType = EffectType.EMIT_EVENT
@export var quest_id: String = ""
@export var event_name: String = ""
@export var payload: Dictionary = {}
@export var flag: String = ""
@export var flag_value: bool = true
