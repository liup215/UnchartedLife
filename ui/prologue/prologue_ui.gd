## prologue_ui.gd
## UI overlay for the prologue scene
extends Control

@onready var objective_label: Label = $VBoxContainer/ObjectiveLabel
@onready var cell_health_label: Label = $VBoxContainer/CellHealthLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/VBoxContainer/MessageLabel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton
@onready var menu_button: Button = $GameOverPanel/VBoxContainer/MenuButton

var feedback_timer: float = 0.0

func _ready():
	_setup_ui()
	_hide_game_over()

func _setup_ui():
	# Set up objective text
	if objective_label:
		objective_label.text = "Objective: Collect GLUCOSE to refill ammo\nShoot the dying cell to heal it!\nAvoid other sugars - they hurt you!"
	
	# Set up buttons
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func _process(delta: float):
	# Fade out feedback label over time
	if feedback_timer > 0:
		feedback_timer -= delta
		if feedback_label:
			feedback_label.modulate.a = feedback_timer / 2.0

func update_cell_health(current: int, max_hp: int, percentage: float):
	if cell_health_label:
		cell_health_label.text = "Cell Health: %d / %d (%.1f%%)" % [current, max_hp, percentage * 100]
		
		# Color code based on health
		if percentage < 0.3:
			cell_health_label.add_theme_color_override("font_color", Color.RED)
		elif percentage < 0.5:
			cell_health_label.add_theme_color_override("font_color", Color.ORANGE)
		elif percentage < 0.7:
			cell_health_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			cell_health_label.add_theme_color_override("font_color", Color.GREEN)

func on_molecule_collected(type: int, is_glucose: bool):
	if not feedback_label:
		return
	
	if is_glucose:
		feedback_label.text = "✓ GLUCOSE collected! Ammo refilled!"
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		var molecule_name = _get_molecule_name(type)
		feedback_label.text = "✗ Wrong! %s is not glucose! (-10 HP)" % molecule_name
		feedback_label.add_theme_color_override("font_color", Color.RED)
	
	feedback_label.modulate.a = 1.0
	feedback_timer = 2.0

func _get_molecule_name(type: int) -> String:
	match type:
		0: return "Glucose"
		1: return "Fructose"
		2: return "Galactose"
		3: return "Sucrose"
		4: return "Lactose"
		5: return "Maltose"
		_: return "Unknown"

func show_victory():
	if game_over_panel and game_over_label:
		game_over_label.text = "VICTORY!\nYou've healed the cell!"
		game_over_label.add_theme_color_override("font_color", Color.GREEN)
		game_over_panel.visible = true

func show_game_over(reason: String):
	if game_over_panel and game_over_label:
		game_over_label.text = "GAME OVER\n" + reason
		game_over_label.add_theme_color_override("font_color", Color.RED)
		game_over_panel.visible = true

func _hide_game_over():
	if game_over_panel:
		game_over_panel.visible = false

func _on_restart_pressed():
	# Restart the scene
	get_tree().reload_current_scene()

func _on_menu_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
