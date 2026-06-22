extends Control

## Opening Animation Scene
## Displays the glucose molecule and mission introduction
## Automatically transitions to prologue after completion

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var background: ColorRect = $Background
@onready var molecule_visual: Node2D = $CenterContainer/VBoxContainer/MoleculeVisualContainer/MoleculeVisual
@onready var description_label: Label = $CenterContainer/VBoxContainer/DescriptionLabel
@onready var prompt_label: Label = $CenterContainer/VBoxContainer/PromptLabel

const GLUCOSE_DATA = preload("res://data/molecules/alpha_glucose.tres")

var can_skip: bool = true
var animation_finished: bool = false

func _ready() -> void:
	# Ensure full screen visibility
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Setup molecule visual with glucose data
	if molecule_visual and molecule_visual.has_method("set_molecule_data"):
		molecule_visual.set_molecule_data(GLUCOSE_DATA)
		molecule_visual.queue_redraw()
	
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
		GameLogger.warn("story", "No 'opening' animation found, using default timing")
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
	"""Transition from opening to main scene which will load prologue"""
	# Prevent multiple calls
	if not can_skip:
		return
	can_skip = false
	
	# Transition directly to main.tscn instead of prologue
	# main.tscn will handle loading prologue scenes
	GameLogger.info("story", "Opening animation complete, transitioning to main scene...")
	
	# Mark that we should start with prologue
	PlayerData.should_start_prologue = true
	
	get_tree().change_scene_to_file(ScenePaths.MAIN_SCENE)
