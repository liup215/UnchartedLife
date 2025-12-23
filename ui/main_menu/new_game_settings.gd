extends Control

signal game_started(settings)

@onready var difficulty_dropdown = $Panel/VBoxContainer/DifficultyDropdown
@onready var seed_line_edit = $Panel/VBoxContainer/SeedLineEdit
@onready var start_button = $Panel/VBoxContainer/StartButton
@onready var back_button = $Panel/VBoxContainer/BackButton

var main_menu_ref = null

func OpenFromMainMenu(main_menu=null):
	main_menu_ref = main_menu
	visible = true
	if main_menu_ref and "menu_container" in main_menu_ref:
		main_menu_ref.menu_container.visible = false
	elif main_menu_ref:
		# Fallback: hide CenterContainer by path if menu_container property doesn't exist
		var center_container = main_menu_ref.get_node_or_null("CenterContainer")
		if center_container:
			center_container.visible = false

func Exit():
	visible = false
	if main_menu_ref and "menu_container" in main_menu_ref:
		main_menu_ref.menu_container.visible = true
	elif main_menu_ref:
		# Fallback: show CenterContainer by path if menu_container property doesn't exist
		var center_container = main_menu_ref.get_node_or_null("CenterContainer")
		if center_container:
			center_container.visible = true

func _ready():
	start_button.pressed.connect(OnConfirmPressed)
	back_button.pressed.connect(Exit)
	# Populate difficulty dropdown
	difficulty_dropdown.clear()
	difficulty_dropdown.add_item("Easy")
	difficulty_dropdown.add_item("Normal")
	difficulty_dropdown.add_item("Hard")
	difficulty_dropdown.selected = 1

func OnConfirmPressed():
	StartGame()

func StartGame():
	var settings = GetGameSettings()
	
	# Create a new save slot for this game
	PlayerData.current_slot = SaveManager.create_new_slot_id()
	
	# Initialize game properties
	GameProperties.start_new_game(settings)
	
	# Emit the game_started signal with settings
	game_started.emit(settings)

func GetGameSettings() -> WorldGeneratingSettings:
	var settings = WorldGeneratingSettings.new()
	settings.Difficulty = difficulty_dropdown.get_item_text(difficulty_dropdown.selected)
	settings.Seed = seed_line_edit.text
	return settings
