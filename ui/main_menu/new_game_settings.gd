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
	if main_menu_ref:
		main_menu_ref.visible = false

func Exit():
	visible = false
	if main_menu_ref:
		main_menu_ref.visible = true

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
	
	var world_scene = load("res://world/game_world.tscn")
	var world_instance = world_scene.instance()

	var game_properties = load("res://systems/game_properties.gd")

	world_instance.current_game = game_properties.StartNewGame(settings)

	SceneManager.SwitchToSceneInstance(world_instance)

func GetGameSettings() -> WorldGeneratingSettings:
	var settings = WorldGeneratingSettings.new()
	settings.Difficulty = difficulty_dropdown.get_item_text(difficulty_dropdown.selected)
	settings.Seed = seed_line_edit.text
	return settings
