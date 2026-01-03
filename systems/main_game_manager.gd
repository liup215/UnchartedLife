extends Node2D

@onready var system_menu = $SystemMenu
@onready var game_scene: Node2D = $GameScene

## Scene sequence configuration (loaded from data)
@export var active_sequences: Array[SceneSequenceData] = []

# Runtime state
var current_sequence: SceneSequenceData = null
var current_sequence_index: int = -1
var current_transition_index: int = 0
var current_scene_instance: Node = null
var loading_screen_instance: Control = null

func _ready():
	# Check for sequences that should auto-start
	_check_and_start_sequences()

func _check_and_start_sequences():
	"""Check if any sequences should start based on conditions"""
	for sequence in active_sequences:
		if sequence.can_start():
			start_sequence(sequence)
			return
	
	# If no sequence started, game_scene handles normal gameplay
	print("MainGameManager: No sequence to start, game_scene taking over")

func start_sequence(sequence: SceneSequenceData):
	"""Start a scene sequence"""
	if not sequence or sequence.transitions.is_empty():
		push_error("MainGameManager: Invalid sequence or no transitions")
		return
	
	print("MainGameManager: Starting sequence '%s'" % sequence.sequence_name)
	current_sequence = sequence
	current_transition_index = 0
	
	# Clear the condition that triggered this sequence (if any)
	if sequence.start_condition and PlayerData and sequence.start_condition in PlayerData:
		PlayerData.set(sequence.start_condition, false)
	
	# Load first transition
	_load_transition(current_sequence.transitions[0])

func _load_transition(transition: SceneTransitionData):
	"""Load a scene transition with loading screen"""
	if not transition:
		push_error("MainGameManager: Invalid transition")
		return
	
	print("MainGameManager: Loading transition '%s'" % transition.scene_name)
	
	# Show loading screen
	_show_loading_screen(transition.loading_image, transition.loading_text)
	
	# Wait a frame for loading screen to show
	await get_tree().process_frame
	
	# Load scene
	var scene_resource = load(transition.scene_path)
	if not scene_resource:
		push_error("MainGameManager: Failed to load scene at %s" % transition.scene_path)
		_hide_loading_screen()
		return
	
	# Instantiate scene
	current_scene_instance = scene_resource.instantiate()
	
	# Connect completion signal if specified
	if not transition.completion_signal.is_empty():
		if current_scene_instance.has_signal(transition.completion_signal):
			current_scene_instance.connect(transition.completion_signal, _on_scene_completed.bind(transition))
		else:
			push_warning("MainGameManager: Scene doesn't have signal '%s'" % transition.completion_signal)
	
	# Add to scene tree
	add_child(current_scene_instance)
	
	# Hide loading screen after delay
	await get_tree().create_timer(transition.loading_screen_delay).timeout
	_hide_loading_screen()

func _on_scene_completed(transition: SceneTransitionData):
	"""Called when a scene in the sequence completes"""
	print("MainGameManager: Scene '%s' completed" % transition.scene_name)
	
	# Set completion flag if specified
	if not transition.completion_flag.is_empty() and PlayerData:
		if transition.completion_flag in PlayerData:
			PlayerData.set(transition.completion_flag, true)
	
	# Clean up current scene
	if current_scene_instance:
		current_scene_instance.queue_free()
		current_scene_instance = null
	
	# Move to next transition
	current_transition_index += 1
	
	if current_transition_index < current_sequence.transitions.size():
		# Load next transition in sequence
		_load_transition(current_sequence.transitions[current_transition_index])
	else:
		# Sequence complete
		_on_sequence_completed()

func _on_sequence_completed():
	"""Called when entire sequence completes"""
	print("MainGameManager: Sequence '%s' completed" % current_sequence.sequence_name)
	
	match current_sequence.on_completion:
		SceneSequenceData.SequenceCompletion.CONTINUE_GAMEPLAY:
			print("MainGameManager: Continuing with gameplay")
			current_sequence = null
			# GameScene takes over
		
		SceneSequenceData.SequenceCompletion.LOAD_NEXT_SEQUENCE:
			if not current_sequence.next_sequence_id.is_empty():
				# Find and load next sequence
				var next_seq = _find_sequence_by_id(current_sequence.next_sequence_id)
				if next_seq:
					start_sequence(next_seq)
				else:
					push_error("MainGameManager: Next sequence '%s' not found" % current_sequence.next_sequence_id)
					current_sequence = null
			else:
				push_warning("MainGameManager: LOAD_NEXT_SEQUENCE specified but no next_sequence_id")
				current_sequence = null
		
		SceneSequenceData.SequenceCompletion.CUSTOM:
			push_warning("MainGameManager: Custom completion handling not implemented")
			current_sequence = null

func _find_sequence_by_id(sequence_id: String) -> SceneSequenceData:
	"""Find a sequence by its ID"""
	for sequence in active_sequences:
		if sequence.sequence_id == sequence_id:
			return sequence
	return null

func load_sequence_by_id(sequence_id: String):
	"""Public API to load a sequence by ID"""
	var sequence = _find_sequence_by_id(sequence_id)
	if sequence:
		start_sequence(sequence)
	else:
		push_error("MainGameManager: Sequence '%s' not found" % sequence_id)

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

func is_in_sequence() -> bool:
	"""Check if currently running a sequence"""
	return current_sequence != null

func should_disable_system_menu() -> bool:
	"""Check if system menu should be disabled"""
	if not current_sequence or current_transition_index >= current_sequence.transitions.size():
		return false
	
	var current_transition = current_sequence.transitions[current_transition_index]
	return current_transition.disable_system_menu

func _unhandled_input(event):
	# Using the built-in "ui_cancel" action, which is mapped to Escape by default.
	if event.is_action_pressed("ui_cancel"):
		# Don't allow system menu during sequence if disabled
		if should_disable_system_menu():
			return
		
		if system_menu.visible:
			system_menu.close_menu()
		else:
			system_menu.open_menu()
