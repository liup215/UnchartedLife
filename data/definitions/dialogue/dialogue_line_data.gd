extends Resource
class_name DialogueLineData

@export var speaker_id: String = ""
@export var speaker_name: String = ""
@export var speaker_name_key: String = ""
@export var text: String = ""
@export var text_key: String = ""
@export var portrait: Texture2D
@export var mood: String = ""
@export var voice_sfx: AudioStream
@export var auto_advance: bool = false
@export var typing_speed: float = 0.03

func resolve_text() -> String:
	if not text_key.is_empty():
		var translated := tr(text_key)
		if translated != text_key:
			return translated
	return text

func resolve_speaker_name() -> String:
	if not speaker_name_key.is_empty():
		var translated := tr(speaker_name_key)
		if translated != speaker_name_key:
			return translated
	if not speaker_name.is_empty():
		return speaker_name
	return speaker_id
