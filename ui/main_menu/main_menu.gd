extends Control

@onready var new_game_button = $CenterContainer/VBoxContainer/MenuButtons/NewGameButton
@onready var continue_button = $CenterContainer/VBoxContainer/MenuButtons/ContinueButton
@onready var load_game_button = $CenterContainer/VBoxContainer/MenuButtons/LoadGameButton
@onready var options_button = $CenterContainer/VBoxContainer/MenuButtons/OptionsButton
@onready var credits_button = $CenterContainer/VBoxContainer/MenuButtons/CreditsButton
@onready var quit_button = $CenterContainer/VBoxContainer/MenuButtons/QuitButton

func _ready():
    new_game_button.pressed.connect(_on_new_game_pressed)
    continue_button.pressed.connect(_on_continue_pressed)
    load_game_button.pressed.connect(_on_load_game_pressed)
    options_button.pressed.connect(_on_options_pressed)
    credits_button.pressed.connect(_on_credits_pressed)
    quit_button.pressed.connect(_on_quit_pressed)

    # Disable buttons if no save files exist
    var has_saves = SaveManager.has_any_save_file()
    continue_button.disabled = not has_saves
    load_game_button.disabled = not has_saves

func _on_new_game_pressed():
    # Go to the character creation screen
    get_tree().change_scene_to_file("res://ui/character_creation/character_creation.tscn")

func _on_continue_pressed():
    # Load the most recent save file
    var latest_slot = SaveManager.get_latest_slot_id()
    if not latest_slot.is_empty():
        PlayerData.current_save_slot_id = latest_slot
        if SaveManager.load_game(latest_slot):
            get_tree().change_scene_to_file("res://main.tscn")
        else:
            print("Error loading latest save file.")
    else:
        # Should not happen if button is disabled
        print("No save file found to continue.")

func _on_load_game_pressed():
    get_tree().change_scene_to_file("res://ui/load_game/load_game_menu.tscn")

func _on_options_pressed():
    print("Options button pressed")
    # This will eventually open an options menu

func _on_credits_pressed():
    print("Credits button pressed")
    # This will eventually show a credits screen

func _on_quit_pressed():
    get_tree().quit()
