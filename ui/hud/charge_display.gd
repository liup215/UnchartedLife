# charge_display.gd
# UI component to display combat charge level
extends Control

@onready var charge_label: Label = $VBoxContainer/ChargeLabel
@onready var charge_bar: ProgressBar = $VBoxContainer/ChargeBar
@onready var charge_level_label: Label = $VBoxContainer/ChargeLevelLabel

var charge_component: ChargeComponent = null

func _ready():
	# Position in bottom-right corner with margin
	anchor_left = 1.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -250
	offset_top = -150
	offset_right = -20
	offset_bottom = -20
	
	# Try to find player immediately
	call_deferred("_find_player_deferred")

func _find_player_deferred():
	# Deferred call to ensure scene is ready
	_find_player()

func _find_player():
	# Try to find the player in the scene
	var player_nodes = get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		_connect_to_player(player_nodes[0])
	else:
		# Use a timer to check periodically instead of node_added signal
		var timer = Timer.new()
		timer.wait_time = 0.5
		timer.one_shot = false
		timer.timeout.connect(_check_for_player)
		add_child(timer)
		timer.start()

func _check_for_player():
	var player_nodes = get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		_connect_to_player(player_nodes[0])
		# Stop checking once player is found
		for child in get_children():
			if child is Timer:
				child.stop()
				child.queue_free()
				break

func _on_node_added(node):
	# No longer used - kept for backwards compatibility
	pass

func _connect_to_player(player: Node):
	# Find charge component in player or their combat component
	if player.has_node("ChargeComponent"):
		charge_component = player.get_node("ChargeComponent")
	elif player.has_node("ActorCombatComponent"):
		var combat_comp = player.get_node("ActorCombatComponent")
		if combat_comp.charge_component:
			charge_component = combat_comp.charge_component
	
	if charge_component:
		# Connect to signals
		charge_component.charge_changed.connect(_on_charge_changed)
		charge_component.charge_level_up.connect(_on_charge_level_up)
		charge_component.charge_max_reached.connect(_on_charge_max_reached)
		
		# Initialize display
		_update_display(charge_component.get_current_charge_level(), charge_component.get_current_charge_progress(), charge_component.get_max_charge_level())
		print("[CHARGE UI] Connected to charge component")
	else:
		print("[CHARGE UI] Could not find charge component")

func _on_charge_changed(level: int, progress: float, max_level: int):
	_update_display(level, progress, max_level)

func _on_charge_level_up(level: int):
	# Visual feedback for level up
	var tween = create_tween()
	tween.tween_property(charge_level_label, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(charge_level_label, "scale", Vector2(1.0, 1.0), 0.1)

func _on_charge_max_reached():
	# Flash effect when max charge reached
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(charge_bar, "modulate", Color.YELLOW, 0.2)
	tween.tween_property(charge_bar, "modulate", Color.WHITE, 0.2)

func _update_display(level: int, progress: float, max_level: int):
	# Progress bar shows progress within current level (0-100)
	if charge_bar:
		charge_bar.max_value = 100.0  # Always 100 units per level
		charge_bar.value = progress
	
	if charge_label:
		charge_label.text = "Charge"
	
	if charge_level_label:
		# Show current level and progress percentage
		var progress_percent = int(progress)
		charge_level_label.text = "Lv %d/%d (%d%%)" % [level, max_level, progress_percent]
	
	# Change bar color based on charge level (not progress)
	if charge_bar and max_level > 0:
		var level_ratio = float(level) / float(max_level)
		if level >= max_level:
			charge_bar.modulate = Color.RED  # Max level
		elif level_ratio >= 0.6:
			charge_bar.modulate = Color.ORANGE  # High level
		elif level_ratio >= 0.3:
			charge_bar.modulate = Color.YELLOW  # Medium level
		elif level > 0:
			charge_bar.modulate = Color.LIGHT_BLUE  # Low level, charging
		else:
			charge_bar.modulate = Color.WHITE  # No charge
