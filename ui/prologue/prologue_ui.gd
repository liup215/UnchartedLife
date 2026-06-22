## prologue_ui.gd
## UI overlay for the prologue scene
extends Control

const MoleculeData = preload("res://data/definitions/molecule/molecule_data.gd")

@onready var objective_label: Label = $VBoxContainer/ObjectiveLabel
@onready var counter_label: Label = $VBoxContainer/CounterLabel
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
	if objective_label:
		objective_label.text = "Objective: Collect all the GLUCOSE molecules!
Avoid other sugars - they hurt you!
Only glucose gives you energy!"
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func _process(delta: float):
	if feedback_timer > 0:
		feedback_timer -= delta
		if feedback_label:
			feedback_label.modulate.a = feedback_timer / 2.0

func update_glucose_counter(collected: int, total: int):
	if counter_label:
		counter_label.text = "Glucose: %d / %d" % [collected, total]
		
		# Color code based on progress
		var percentage := float(collected) / float(total) if total > 0 else 0.0
		if percentage < 0.3:
			counter_label.add_theme_color_override("font_color", Color.RED)
		elif percentage < 0.7:
			counter_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			counter_label.add_theme_color_override("font_color", Color.GREEN)

func on_molecule_collected(mol_data: MoleculeData, is_correct: bool):
	if not feedback_label:
		return
	
	var molecule_name := mol_data.display_name if mol_data != null and not mol_data.display_name.is_empty() else "Unknown"
	
	if is_correct:
		feedback_label.text = "✓ %s collected!" % molecule_name
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		feedback_label.text = "✗ Wrong! %s is not glucose! (-10 HP)" % molecule_name
		feedback_label.add_theme_color_override("font_color", Color.RED)
	
	feedback_label.modulate.a = 1.0
	feedback_timer = 2.0

func show_victory():
	if game_over_panel and game_over_label:
		game_over_label.text = "VICTORY!\nYou found all the glucose molecules!"
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
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)
