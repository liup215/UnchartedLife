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

# Text-to-Speech configuration
@export var enable_tts: bool = false
@export var tts_voice_id: String = ""  # Empty string uses default voice
@export_range(0.1, 10.0) var tts_rate: float = 1.0  # Speech speed
@export_range(0.0, 2.0) var tts_pitch: float = 1.0  # Voice pitch
@export_range(0.0, 1.0) var tts_volume: float = 1.0  # Volume (0-100 will be converted internally)

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
