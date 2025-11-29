class_name BioBlitzManager
extends Control

# Config
const QuestionDataScript = preload("res://data/definitions/bio_blitz/question_data.gd")

@export var question_pool: Array[Resource] = [] # Type hint: Array[QuestionData]
@export var question_bank_path: String = "res://data/question_bank/"
@export var battle_music: AudioStream

var question_deck: Array[Resource] = [] # Type hint: Array[QuestionData]

# State
var current_question: Resource # Type hint: QuestionData
var input_locked: bool = false

# UI References
@onready var quiz_panel: PanelContainer = $QuizHUD/QuizPanel
@onready var question_label: Label = $QuizHUD/QuizPanel/VBox/QuestionLabel
@onready var options_container: GridContainer = $QuizHUD/QuizPanel/VBox/OptionsGrid
@onready var exit_button: Button = $QuizHUD/ExitButton
@onready var game_hud: CanvasLayer = $GameHUD
@onready var boss: Actor = $GameWorld/Boss
@onready var player: Actor = $GameWorld/Player
@onready var cell_background: TextureRect = $BackgroundLayer/CellBackground

# Victory UI References
@onready var victory_panel: PanelContainer = $QuizHUD/VictoryPanel
@onready var victory_label: Label = $QuizHUD/VictoryPanel/VBox/Label
@onready var restart_button: Button = $QuizHUD/VictoryPanel/VBox/RestartButton
@onready var victory_exit_button: Button = $QuizHUD/VictoryPanel/VBox/ExitButton

func _process(_delta: float) -> void:
	if player and cell_background and cell_background.material:
		cell_background.material.set_shader_parameter("camera_offset", player.global_position)

func _ready() -> void:
	randomize()
	exit_button.pressed.connect(_on_exit_pressed)
	quiz_panel.visible = false
	victory_panel.visible = false

	# Connect Victory UI
	restart_button.pressed.connect(_on_restart_pressed)
	victory_exit_button.pressed.connect(_on_exit_pressed)

	# Connect to EventBus
	EventBus.request_quiz_reload.connect(_on_request_quiz_reload)

	# Setup Boss HUD
	if boss and game_hud:
		var boss_name = "Boss"
		if boss.actor_data and "actor_name" in boss.actor_data:
			boss_name = boss.actor_data.actor_name
		game_hud.show_boss_health(boss_name, boss.attribute_component.health_component.get_current_health(), boss.attribute_component.health_component.get_max_health())
		boss.actor_health_changed.connect(func(current, max_hp): game_hud.update_boss_health(current, max_hp))
		boss.actor_died.connect(_on_boss_died)

	if player:
		player.actor_died.connect(_on_player_died)

	# Play Music
	if battle_music:
		print("BioBlitzManager: Playing battle music")
		AudioManager.play_music(battle_music)
	else:
		print("BioBlitzManager: No battle music assigned")

	# Load questions
	if question_bank_path.ends_with(".json"):
		load_questions_from_json(question_bank_path)
	else:
		load_questions_from_dir(question_bank_path)

func _on_request_quiz_reload(_weapon_data: Resource) -> void:
	if quiz_panel.visible:
		return
	start_quiz()

func start_quiz() -> void:
	quiz_panel.visible = true
	input_locked = false
	display_random_question()

func display_random_question() -> void:
	if question_pool.size() > 0:
		if question_deck.is_empty():
			question_deck = question_pool.duplicate()
			question_deck.shuffle()
		current_question = question_deck.pop_back()
		display_question(current_question)
	else:
		print("No questions in pool!")
		question_label.text = "No questions loaded!"
		# Auto-complete if no questions (for testing)
		EventBus.quiz_completed.emit(true)
		quiz_panel.visible = false

func display_question(q: Resource) -> void:
	question_label.text = q.question_text

	# Clear old options
	for child in options_container.get_children():
		child.queue_free()

	# Create shuffled indices
	var indices = range(q.options.size())
	indices.shuffle()

	# Create new options in random order
	for i in indices:
		var btn = Button.new()
		btn.text = q.options[i]
		btn.add_theme_font_size_override("font_size", 32)
		btn.custom_minimum_size = Vector2(0, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Bind the original index 'i' so answer checking remains correct
		btn.pressed.connect(_on_option_selected.bind(i))
		options_container.add_child(btn)

func _on_option_selected(index: int) -> void:
	if input_locked:
		return

	input_locked = true

	if index == current_question.correct_option_index:
		handle_correct_answer()
	else:
		handle_wrong_answer()

func handle_correct_answer() -> void:
	# Visual Feedback
	question_label.text = "Correct! Ammo Refilled!"
	question_label.modulate = Color.GREEN

	await get_tree().create_timer(1.0).timeout
	quiz_panel.visible = false
	question_label.modulate = Color.WHITE
	EventBus.quiz_completed.emit(true)

func handle_wrong_answer() -> void:
	# Visual Feedback
	question_label.text = "Incorrect! Try again..."
	question_label.modulate = Color.RED

	await get_tree().create_timer(1.0).timeout
	question_label.modulate = Color.WHITE
	# Generate a new question instead of failing immediately?
	# Or just emit failure?
	# For "Reload", usually you have to keep trying until you get it right or cancel.
	# Let's give another question.
	input_locked = false
	display_random_question()

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://features/bio_blitz/bio_blitz_selection.tscn")

func _on_boss_died() -> void:
	victory_label.text = "Victory!"
	victory_panel.visible = true

func _on_player_died() -> void:
	victory_label.text = "Game Over"
	victory_panel.visible = true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

# --- JSON Loading Logic ---

func load_questions_from_dir(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					load_questions_from_dir(path + "/" + file_name)
			else:
				if file_name.ends_with(".json"):
					load_questions_from_json(path + "/" + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path: " + path)

func load_questions_from_json(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open file: " + file_path)
		return

	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)

	if error == OK:
		var data = json.data
		if data is Array:
			for item in data:
				var q_data = QuestionDataScript.new()
				q_data.question_text = item.get("text", "Unknown Question")

				# Ensure options are strings
				q_data.options.clear()
				var opts = item.get("options", [])
				for opt in opts:
					q_data.options.append(str(opt))

				q_data.correct_option_index = int(item.get("correct_index", 0))

				# Parse type
				var type_str = item.get("type", "DEFINITION")
				match type_str:
					"PROCESS":
						q_data.type = 1 # QuestionType.PROCESS
					"APPLICATION":
						q_data.type = 2 # QuestionType.APPLICATION
					_:
						q_data.type = 0 # QuestionType.DEFINITION

				question_pool.append(q_data)
