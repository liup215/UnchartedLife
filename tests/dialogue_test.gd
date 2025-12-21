extends Control

@onready var intro_btn: Button = $VBoxContainer/IntroButton
@onready var more_btn: Button = $VBoxContainer/MoreButton
@onready var reset_btn: Button = $VBoxContainer/ResetButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

@export var intro_data: DialogueData
@export var more_data: DialogueData

func _ready() -> void:
	
	# Register with manager
	if intro_data:
		DialogueManager.register_dialogue(intro_data)
	if more_data:
		DialogueManager.register_dialogue(more_data)
		
	# Connect signals
	intro_btn.pressed.connect(_on_intro_pressed)
	more_btn.pressed.connect(_on_more_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)
	
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.dialogue_choice_made.connect(_on_choice_made)

func _on_intro_pressed() -> void:
	if intro_data:
		DialogueManager.start_dialogue(intro_data, "test_npc")
		status_label.text = "Started Intro"

func _on_more_pressed() -> void:
	if more_data:
		DialogueManager.start_dialogue(more_data, "test_npc")
		status_label.text = "Started More"

func _on_reset_pressed() -> void:
	# Resetting internal manager state isn't directly exposed, 
	# but we can just restart dialogues.
	status_label.text = "Ready"

func _on_dialogue_started(dlg: DialogueData, npc_id: String) -> void:
	status_label.text = "Dialogue Started: %s (%s)" % [dlg.id, npc_id]

func _on_dialogue_ended(npc_id: String, reason: String) -> void:
	status_label.text = "Dialogue Ended: %s (%s)" % [npc_id, reason]

func _on_choice_made(choice: DialogueChoiceData, npc_id: String) -> void:
	status_label.text = "Choice Made: %s" % choice.text
