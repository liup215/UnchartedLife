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
	_find_player()

func _find_player():
	# Try to find the player in the scene
	var player_nodes = get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		_connect_to_player(player_nodes[0])
	else:
		# Wait for player to be added if not found yet
		get_tree().node_added.connect(_on_node_added)

func _on_node_added(node):
	# If the player is added to the scene later, connect to them
	if node.is_in_group("player"):
		_connect_to_player(node)
		# Disconnect signal to prevent memory leak
		get_tree().node_added.disconnect(_on_node_added)

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
		_update_display(charge_component.get_current_charge(), charge_component.get_max_charge())
		print("[CHARGE UI] Connected to charge component")
	else:
		print("[CHARGE UI] Could not find charge component")

func _on_charge_changed(current: int, max: int):
	_update_display(current, max)

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

func _update_display(current: int, max: int):
	if charge_bar:
		charge_bar.max_value = max
		charge_bar.value = current
	
	if charge_label:
		charge_label.text = "Charge"
	
	if charge_level_label:
		charge_level_label.text = "Level %d / %d" % [current, max]
	
	# Change bar color based on charge level
	if charge_bar and max > 0:
		var ratio = float(current) / float(max)
		if ratio >= 1.0:
			charge_bar.modulate = Color.RED  # Max charge
		elif ratio >= 0.6:
			charge_bar.modulate = Color.ORANGE  # High charge
		elif ratio >= 0.3:
			charge_bar.modulate = Color.YELLOW  # Medium charge
		else:
			charge_bar.modulate = Color.WHITE  # Low charge
