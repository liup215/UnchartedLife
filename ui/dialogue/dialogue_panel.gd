extends CanvasLayer

@export var default_typing_interval: float = 0.03
@export var auto_hide_on_end: bool = true
@export var pause_on_dialogue: bool = true
@export var enable_tts: bool = true  # Global TTS toggle for dialogue panel

@onready var panel: PanelContainer = $Panel
@onready var portrait: TextureRect = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Portrait
@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/SpeakerName
@onready var body_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/Body
@onready var choices_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/Choices
@onready var typing_timer: Timer = $TypingTimer

var _current_line: DialogueLineData
var _typing: bool = false
var _full_text: String = ""
var _current_choices: Array[DialogueChoiceData] = []
var _was_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	panel.hide()
	typing_timer.timeout.connect(_on_typing_tick)
	typing_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_line.connect(_on_dialogue_line)
	EventBus.dialogue_choices.connect(_on_dialogue_choices)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)

func _on_dialogue_started(_dialogue: DialogueData, _npc_id: String) -> void:
	show()
	panel.show()
	_clear_choices()
	body_label.text = ""
	body_label.visible_characters = -1
	_typing = false
	if pause_on_dialogue:
		_was_paused = get_tree().paused
		get_tree().paused = true

func _on_dialogue_line(line: DialogueLineData, _index: int, _total: int, _npc_id: String) -> void:
	_current_line = line
	_clear_choices()
	portrait.texture = line.portrait
	speaker_label.text = line.resolve_speaker_name()
	_full_text = line.resolve_text()
	body_label.text = _full_text
	body_label.visible_characters = 0
	_typing = true
	var interval := line.typing_speed if line.typing_speed > 0.0 else default_typing_interval
	typing_timer.wait_time = interval
	typing_timer.start()
	
	# Play TTS if enabled
	_play_tts_for_line(line)

func _on_dialogue_choices(choices: Array[DialogueChoiceData], _npc_id: String) -> void:
	_typing = false
	typing_timer.stop()
	_stop_tts()  # Stop TTS when choices are presented
	_current_choices = choices
	choices_container.show()
	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i].resolve_text()
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(btn)

func _on_dialogue_ended(_npc_id: String, _reason: String) -> void:
	typing_timer.stop()
	_typing = false
	_clear_choices()
	_stop_tts()  # Stop TTS when dialogue ends
	if auto_hide_on_end:
		hide()
		panel.hide()
	if pause_on_dialogue:
		get_tree().paused = _was_paused

func _on_choice_pressed(index: int) -> void:
	DialogueManager.choose(index)

func _on_typing_tick() -> void:
	if not _typing:
		return
	var current := body_label.visible_characters
	if current < _full_text.length():
		body_label.visible_characters = current + 1
	else:
		_typing = false
		typing_timer.stop()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _typing:
			_finish_typing()
			_stop_tts()  # Stop TTS when player skips typing
		elif _current_choices.is_empty():
			DialogueManager.request_advance()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		DialogueManager.interrupt("player_cancel")

func _finish_typing() -> void:
	body_label.visible_characters = -1
	_typing = false
	typing_timer.stop()

func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()
	choices_container.hide()
	_current_choices.clear()

func _play_tts_for_line(line: DialogueLineData) -> void:
	"""Play TTS for the given dialogue line if enabled."""
	if not enable_tts:
		return
	
	if not line.enable_tts:
		return
	
	var text_to_speak := line.resolve_text()
	if text_to_speak.is_empty():
		return
	
	# Volume is already in 0-1 range, TTSManager will handle conversion to 0-100
	TTSManager.speak(
		text_to_speak,
		line.tts_voice_id,
		line.tts_rate,
		line.tts_pitch,
		line.tts_volume * 100.0,  # Convert to 0-100 range
		true  # Interrupt any previous speech
	)

func _stop_tts() -> void:
	"""Stop any currently playing TTS."""
	if TTSManager:
		TTSManager.stop()

