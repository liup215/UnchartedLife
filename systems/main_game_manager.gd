extends Node2D

@onready var system_menu = $SystemMenu
@onready var game_scene: Node2D = $GameScene

# Prologue scenes
const PROLOGUE_SCENE_01 = preload("res://scenes/story/prologue/prologue_scene_01.tscn")
const PROLOGUE_SCENE_02 = preload("res://scenes/story/prologue/prologue_scene_02.tscn")

var current_prologue_scene: Control = null
var loading_screen_instance: Control = null

func _ready():
	# Check if we should start with prologue
	if PlayerData.should_start_prologue:
		# Clear the flag
		PlayerData.should_start_prologue = false
		# Start prologue sequence
		_start_prologue_sequence()
	else:
		# GameScene handles normal game/level loading
		pass

func _start_prologue_sequence():
	"""Start the prologue tutorial sequence"""
	print("MainGameManager: Starting prologue sequence")
	_load_prologue_scene_01()

func _load_prologue_scene_01():
	"""Load prologue scene 01 (microscope tutorial) with loading screen"""
	# Show loading screen
	_show_loading_screen_for_prologue_01()
	
	# Wait a frame for loading screen to show
	await get_tree().process_frame
	
	# Instantiate prologue scene
	current_prologue_scene = PROLOGUE_SCENE_01.instantiate()
	
	# Connect completion signal
	if current_prologue_scene.has_signal("tutorial_completed"):
		current_prologue_scene.tutorial_completed.connect(_on_prologue_01_completed)
	
	# Add to scene tree
	add_child(current_prologue_scene)
	
	# Hide loading screen after a brief moment
	await get_tree().create_timer(1.0).timeout
	_hide_loading_screen()

func _on_prologue_01_completed():
	"""Called when microscope tutorial (prologue 01) is completed"""
	print("MainGameManager: Prologue 01 completed, loading prologue 02")
	current_prologue_scene = null  # Will be freed by queue_free() in prologue_scene_01
	
	# Load prologue scene 02 (glucose game)
	_load_prologue_scene_02()

func _load_prologue_scene_02():
	"""Load prologue scene 02 (glucose identification game) with loading screen"""
	# Show loading screen
	_show_loading_screen_for_prologue_02()
	
	# Wait a frame for loading screen to show
	await get_tree().process_frame
	
	# Instantiate prologue scene
	current_prologue_scene = PROLOGUE_SCENE_02.instantiate()
	
	# Connect completion signal if available
	if current_prologue_scene.has_signal("prologue_completed"):
		current_prologue_scene.prologue_completed.connect(_on_prologue_02_completed)
	
	# Add to scene tree
	add_child(current_prologue_scene)
	
	# Hide loading screen after a brief moment
	await get_tree().create_timer(1.0).timeout
	_hide_loading_screen()

func _on_prologue_02_completed():
	"""Called when glucose tutorial (prologue 02) is completed"""
	print("MainGameManager: Prologue 02 completed, starting main game")
	
	# Clean up prologue scene
	if current_prologue_scene:
		current_prologue_scene.queue_free()
		current_prologue_scene = null
	
	# Mark as completed
	PlayerData.completed_glucose_tutorial = true
	
	# Now the game_scene will take over with normal gameplay

func _show_loading_screen_for_prologue_01():
	"""Show loading screen with microscope tutorial info"""
	var microscope_image: Texture2D = load("res://assets/items/tools/microscope.webp")
	var microscope_text: String = "Microscope Tutorial\n\nLearn how to use the microscope\nAdjust focus, brightness and position"
	_show_loading_screen(microscope_image, microscope_text)

func _show_loading_screen_for_prologue_02():
	"""Show loading screen with glucose tutorial info"""
	var glucose_image: Texture2D = load("res://icon.svg")  # Use default icon for now
	var glucose_text: String = "Glucose Tutorial\n\nLearn to identify glucose molecules\nEssential for survival"
	_show_loading_screen(glucose_image, glucose_text)

func _show_loading_screen(image: Texture2D = null, text: String = "Loading..."):
	"""Show the loading screen managed by main scene"""
	if not loading_screen_instance:
		# Load and instantiate loading screen
		var loading_screen_scene = load("res://ui/loading_screen/loading_screen.tscn")
		if loading_screen_scene:
			loading_screen_instance = loading_screen_scene.instantiate()
			add_child(loading_screen_instance)
	
	# Configure and show
	if loading_screen_instance:
		if image and loading_screen_instance.has_method("set_image"):
			loading_screen_instance.set_image(image)
		if text and loading_screen_instance.has_method("set_text"):
			loading_screen_instance.set_text(text)
		if loading_screen_instance.has_method("show_loading_screen"):
			loading_screen_instance.show_loading_screen()

func _hide_loading_screen():
	"""Hide the loading screen"""
	if loading_screen_instance and loading_screen_instance.has_method("hide_loading_screen"):
		loading_screen_instance.hide_loading_screen()

func _unhandled_input(event):
	# Using the built-in "ui_cancel" action, which is mapped to Escape by default.
	if event.is_action_pressed("ui_cancel"):
		# Don't allow system menu during prologue
		if current_prologue_scene:
			return
		
		if system_menu.visible:
			system_menu.close_menu()
		else:
			system_menu.open_menu()
