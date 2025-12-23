extends CanvasLayer

@onready var save_game_button: Button = $Panel/VBoxContainer/SaveGameButton
@onready var quit_to_menu_button: Button = $Panel/VBoxContainer/QuitToMenuButton
@onready var quit_to_desktop_button: Button = $Panel/VBoxContainer/QuitToDesktopButton

func _ready():
	save_game_button.pressed.connect(_on_save_game_pressed)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)
	quit_to_desktop_button.pressed.connect(_on_quit_to_desktop_pressed)

func _on_save_game_pressed():
	if PlayerData.current_slot.is_empty():
		PlayerData.current_slot = SaveManager.create_new_slot_id()
	SaveManager.save_game(PlayerData.current_slot)
	# Optionally, give feedback to the player
	# e.g., show a "Game Saved!" label for a second.
	print("Game saved to slot: %s" % PlayerData.current_slot)
	close_menu()

func _on_quit_to_menu_pressed():
	# IMPORTANT: Unpause the game before changing scenes
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")

func _on_quit_to_desktop_pressed():
	# IMPORTANT: Unpause the game before quitting
	get_tree().paused = false
	get_tree().quit()

func open_menu():
	visible = true
	get_tree().paused = true

func close_menu():
	visible = false
	get_tree().paused = false

func _unhandled_input(event):
	# Using the built-in "ui_cancel" action, which is mapped to Escape by default.
	if event.is_action_pressed("ui_cancel"):
		if visible:
			close_menu()
		else:
			open_menu()
