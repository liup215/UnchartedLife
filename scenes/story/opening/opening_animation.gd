extends Control

## Opening Animation Scene
## Plays the opening cutscene/animation when starting a new game
## Automatically transitions to prologue after completion

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skip_button: Button = $SkipButton
@onready var background: ColorRect = $Background
@onready var center_image: TextureRect = $CenterContainer/VBoxContainer/CenterImage
@onready var description_label: Label = $CenterContainer/VBoxContainer/DescriptionLabel
@onready var prompt_label: Label = $CenterContainer/VBoxContainer/PromptLabel

var can_skip: bool = true
var animation_finished: bool = false

func _ready() -> void:
	# Ensure full screen visibility
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Setup skip button
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	
	# Connect animation finished signal
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
	
	# Start the opening animation
	_start_opening_animation()

func _start_opening_animation() -> void:
	"""Start playing the opening animation sequence"""
	if animation_player and animation_player.has_animation("opening"):
		animation_player.play("opening")
	else:
		# If no animation exists, wait a few seconds then transition
		print("Warning: No 'opening' animation found, using default timing")
		await get_tree().create_timer(5.0).timeout
		_transition_to_prologue()

func _on_animation_finished(anim_name: String) -> void:
	"""Called when animation completes"""
	if anim_name == "opening":
		animation_finished = true
		_transition_to_prologue()

func _on_skip_pressed() -> void:
	"""Handle skip button press"""
	if can_skip:
		if animation_player:
			animation_player.stop()
		_transition_to_prologue()

func _input(event: InputEvent) -> void:
	"""Allow skipping with keyboard/controller input"""
	if can_skip and event.is_action_pressed("ui_cancel"):
		_on_skip_pressed()
		accept_event()

func _transition_to_prologue() -> void:
	"""Transition from opening to first prologue scene"""
	# Prevent multiple calls
	if not can_skip:
		return
	can_skip = false
	
	# Transition to prologue using loading screen with microscope introduction
	print("Opening animation complete, transitioning to prologue with loading screen...")
	
	# Load the game icon for loading screen
	var microscope_image: Texture2D = load("res://icon.svg")
	var microscope_intro_text: String = "显微镜使用教学\n\n学习如何使用显微镜观察细胞\n调节焦距、亮度和位置\n\nMicroscope Tutorial\n\nLearn how to use the microscope\nAdjust focus, brightness and position"
	
	# Use LoadingManager to load prologue scene with custom content
	LoadingManager.load_scene_with_progress(
		"res://scenes/story/prologue/prologue_scene_01.tscn",
		microscope_image,
		microscope_intro_text
	)
