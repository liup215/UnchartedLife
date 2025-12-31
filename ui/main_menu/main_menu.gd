extends Control

@onready var menu_container = $CenterContainer
@onready var new_game_button = $CenterContainer/VBoxContainer/MenuButtons/NewGameButton
@onready var prologue_button = $CenterContainer/VBoxContainer/MenuButtons/PrologueButton
@onready var continue_button = $CenterContainer/VBoxContainer/MenuButtons/ContinueButton
@onready var load_game_button = $CenterContainer/VBoxContainer/MenuButtons/LoadGameButton
@onready var options_button = $CenterContainer/VBoxContainer/MenuButtons/OptionsButton
@onready var credits_button = $CenterContainer/VBoxContainer/MenuButtons/CreditsButton
@onready var quit_button = $CenterContainer/VBoxContainer/MenuButtons/QuitButton
@onready var new_game_settings = $NewGameSettings

# Timer for checking startup success
var timerForStartupSuccess: float = 0.0
var startupSuccessChecked: bool = false
const STARTUP_SUCCESS_DELAY: float = 2.0 # Seconds to wait before checking success

func _ready():
	# 1. Exit Check
	if SceneManager.QuitOrQuitting:
		return

	# Force unpause and input mode
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# 2. Menu Initialization
	RunMenuSetup()

	# 3. Intro Logic (Skipped for now, directly to menu)
	OnIntroEnded()
	
	# 4. Fetch News
	FetchNews()

func RunMenuSetup():
	# Initialize buttons
	new_game_button.pressed.connect(_on_new_game_pressed)
	prologue_button.pressed.connect(_on_prologue_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect new game settings signal
	if new_game_settings:
		new_game_settings.game_started.connect(_on_new_game_confirmed)

	# Disable buttons if no save files exist
	var has_saves = SaveManager.has_any_save_file()
	continue_button.disabled = not has_saves
	load_game_button.disabled = not has_saves
	
	# Check Graphics/System info (Stub)
	CheckSystemInfo()
	
	# Check Store/Patch notes status (Stub)
	CheckStoreStatus()

func OnIntroEnded():
	# Play fade-in animation (Stub)
	# Show main menu container (Already visible)
	
	# Notify disk cache / Trigger GC
	# In Godot, we can't explicitly trigger GC in the same way as Unity, 
	# but we can ensure resources are managed.
	pass

func _process(delta):
	if not startupSuccessChecked:
		timerForStartupSuccess += delta
		if timerForStartupSuccess >= STARTUP_SUCCESS_DELAY:
			CheckStartupSuccess()
			startupSuccessChecked = true

func CheckStartupSuccess():
	# Check Safe Mode (Stub)
	# Report Startup Success (Stub)
	print("Startup checks completed successfully.")
	
	# Check Performance (Stub)
	WarnAboutLowPerformance()

func FetchNews():
	# Placeholder for fetching news
	print("Fetching news...")
	# In a real implementation, this would make an HTTP request
	# await get_tree().create_timer(1.0).timeout
	# print("News fetched.")

# --- Helper Stubs ---

func CheckSystemInfo():
	var rendering_device = RenderingServer.get_video_adapter_name()
	print("Graphics Adapter: ", rendering_device)
	# Logic to warn about specific drivers could go here

func CheckStoreStatus():
	# Logic to check Steam/Itch status
	pass

func WarnAboutLowPerformance():
	var fps = Engine.get_frames_per_second()
	if fps < 30 and fps > 0:
		print("Warning: Low performance detected in menu.")

# --- Button Callbacks ---

func _on_new_game_pressed():
	# Play button sound (stub)
	# Hide main menu and open new game settings
	if new_game_settings:
		new_game_settings.OpenFromMainMenu(self)
	else:
		print("NewGameSettings node not found.")


func _on_prologue_pressed():
	# Launch the prologue scene directly
	print("Launching prologue...")
	get_tree().change_scene_to_file("res://scenes/story/prologue/prologue_game.tscn")


func _on_new_game_confirmed(settings):
	# Called when NewGameSettings emits game_started
	OnEnteringGame(true)
	# Load the opening animation scene for new games
	get_tree().change_scene_to_file("res://scenes/story/opening/opening_animation.tscn")

func _on_continue_pressed():
	var latest_slot = SaveManager.get_latest_slot_id()
	if not latest_slot.is_empty():
		PlayerData.current_slot = latest_slot
		if SaveManager.load_game(latest_slot):
			OnEnteringGame(false)
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		else:
			print("Error loading latest save file.")
	else:
		print("No save file found to continue.")

func _on_load_game_pressed():
	get_tree().change_scene_to_file("res://ui/load_game/load_game_menu.tscn")

func _on_options_pressed():
	print("Options button pressed")

func _on_credits_pressed():
	print("Credits button pressed")

func _on_quit_pressed():
	SceneManager.quit_game()

func OnEnteringGame(is_new_game: bool):
	# Disable cheats (Stub)
	# Clear last save time (Stub)
	# Report achievements (Stub)
	print("Entering game. New game: ", is_new_game)
