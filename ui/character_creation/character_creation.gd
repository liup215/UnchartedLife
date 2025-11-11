extends Control

@export var main_game_scene: PackedScene

@onready var name_edit: LineEdit = $CenterContainer/VBoxContainer/NameEdit
@onready var start_game_button: Button = $CenterContainer/VBoxContainer/StartGameButton

func _ready():
	start_game_button.pressed.connect(_on_start_game_pressed)
	name_edit.text_submitted.connect(_on_start_game_pressed)

func _on_start_game_pressed(text: String = ""):
	var player_name = name_edit.text
	if player_name.is_empty():
		player_name = name_edit.placeholder_text

	# This is a new game, so clear any previous session data
	PlayerData.player_name = player_name
	PlayerData.current_slot = ""
	
	if main_game_scene:
		get_tree().change_scene_to_packed(main_game_scene)
	else:
		print("Main game scene not set in the inspector!")
