extends Resource
class_name DialogueChoiceData

@export var id: String = ""
@export var text: String = ""
@export var text_key: String = ""
@export var next_dialogue_id: String = ""
@export var conditions: Array[DialogueConditionData] = []
@export var effects: Array[DialogueEffectData] = []

func resolve_text() -> String:
	if not text_key.is_empty():
		var translated := tr(text_key)
		if translated != text_key:
			return translated
	return text
