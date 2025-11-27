extends CanvasLayer

@onready var player_name_label: Label = $PlayerInfoContainer/VBoxContainer/PlayerNameLabel
@onready var health_bar: ProgressBar = $PlayerInfoContainer/VBoxContainer/HealthContainer/HealthBar
@onready var health_value: Label = $PlayerInfoContainer/VBoxContainer/HealthContainer/HealthBar/HealthValue
@onready var atp_bar: ProgressBar = $PlayerInfoContainer/VBoxContainer/ATPContainer/ATPBar
@onready var atp_value: Label = $PlayerInfoContainer/VBoxContainer/ATPContainer/ATPBar/ATPValue
@onready var glucose_label: Label = $PlayerInfoContainer/VBoxContainer/GlucoseLabel

@onready var tank_name_label: Label = $PlayerInfoContainer/VBoxContainer/TankStatusContainer/TankNameLabel
@onready var tank_speed_label: Label = $PlayerInfoContainer/VBoxContainer/TankStatusContainer/TankSpeedLabel
@onready var tank_defense_label: Label = $PlayerInfoContainer/VBoxContainer/TankStatusContainer/TankDefenseLabel
@onready var tank_load_label: Label = $PlayerInfoContainer/VBoxContainer/TankStatusContainer/TankLoadLabel

# Boss HUD elements
@onready var boss_info_container: MarginContainer = $BossInfoContainer
@onready var boss_name_label: Label = $BossInfoContainer/VBoxContainer/BossNameLabel
@onready var boss_health_bar: ProgressBar = $BossInfoContainer/VBoxContainer/BossHealthBar
@onready var boss_health_value: Label = $BossInfoContainer/VBoxContainer/BossHealthBar/BossHealthValue

var player: Actor = null
var vehicle: Node = null

func _update_tank_status():
	# Try to find a vehicle the player is in
	var found_vehicle = null
	if player and player.has_method("get_current_state") and player.get_current_state() == 1:  # IN_VEHICLE = 1
		# Find vehicle by checking all vehicles in group
		var vehicles = get_tree().get_nodes_in_group("vehicle")
		for v in vehicles:
			if v.occupied and v.driver == player:
				found_vehicle = v
				break
	
	vehicle = found_vehicle
	
	if vehicle and vehicle.has_node("VehicleStatsComponent"):
		var stats = vehicle.get_node("VehicleStatsComponent")
		tank_name_label.text = "Tank: %s" % (vehicle.vehicle_data.vehicle_name if vehicle.vehicle_data else "Unknown")
		# Display current speed instead of max speed
		var current_speed = vehicle.linear_velocity.length() if vehicle.has_method("get") else 0
		tank_speed_label.text = "Speed: %.1f" % current_speed
		tank_defense_label.text = "Defense: %d" % stats.final_defense
		tank_load_label.text = "Load: %.1f / %.1f" % [stats.total_weight, stats.total_max_load]
		
		# Make tank status visible
		tank_name_label.show()
		tank_speed_label.show()
		tank_defense_label.show()
		tank_load_label.show()
	else:
		# Hide tank status when not in vehicle
		tank_name_label.text = "Tank: -"
		tank_speed_label.text = "Speed: -"
		tank_defense_label.text = "Defense: -"
		tank_load_label.text = "Load: -"
		
		# Hide labels when not in vehicle
		tank_name_label.hide()
		tank_speed_label.hide()
		tank_defense_label.hide()
		tank_load_label.hide()

func _ready():
	# Wait until the scene tree is ready to find the player
	get_tree().node_added.connect(_on_node_added)
	_find_player()
	
	# Initial glucose update
	if PlayerData:
		_update_glucose_label()
	
	# Hide boss info by default
	hide_boss_health()

func _find_player():
	# Try to find the player in the scene
	var player_nodes = get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		player = player_nodes[0]
		_on_player_ready(player)

func _on_node_added(node):
	# If the player is added to the scene later, we can find them here.
	if node.is_in_group("player"):
		player = node
		_on_player_ready(player)

func _on_player_ready(player_node: Actor):
	# Connect to the player's signals to update the HUD
	player_node.actor_health_changed.connect(_on_player_health_changed)
	
	# Check if the player has an ATP component before connecting
	if player_node.has_node("ATPComponent"):
		var atp_component = player_node.get_node("ATPComponent")
		atp_component.atp_changed.connect(_on_player_atp_changed)
		# Set initial ATP value
		_on_player_atp_changed(atp_component.get_current_atp(), atp_component.get_max_atp())
	
	# Set initial health value
	_on_player_health_changed(
		player_node.health_component.get_current_health(),
		player_node.health_component.get_max_health()
	)
	
	# Update player name
	if PlayerData:
		player_name_label.text = PlayerData.player_name

func _on_player_health_changed(current_health: int, max_health: int):
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_value.text = "%d/%d" % [current_health, max_health]

func _on_player_atp_changed(current_atp: int, max_atp: int):
	atp_bar.max_value = max_atp
	atp_bar.value = current_atp
	atp_value.text = "%d/%d" % [current_atp, max_atp]

func _physics_process(_delta):
	# Continuously update glucose, as it can change frequently
	if PlayerData:
		_update_glucose_label()
	_update_tank_status()

func _update_glucose_label():
	glucose_label.text = "Glucose: %.1f" % PlayerData.glucose

# --- Boss Health API ---

func show_boss_health(boss_name: String, current_health: int, max_health: int):
	boss_info_container.show()
	boss_name_label.text = boss_name
	update_boss_health(current_health, max_health)

func update_boss_health(current_health: int, max_health: int):
	boss_health_bar.max_value = max_health
	boss_health_bar.value = current_health
	boss_health_value.text = "%d/%d" % [current_health, max_health]

func hide_boss_health():
	boss_info_container.hide()