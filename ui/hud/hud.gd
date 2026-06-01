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
var vehicle: Vehicle = null

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

var _notification_label: Label = null

func _ready():
	# Wait until the scene tree is ready to find the player
	get_tree().node_added.connect(_on_node_added)
	_find_player()
	
	# Hide boss info by default
	hide_boss_health()
	
	# Setup on-screen notification for ammo etc.
	_setup_notification_label()
	
	# Listen for out-of-ammo events
	EventBus.weapon_out_of_ammo.connect(_on_weapon_out_of_ammo)
	
	# Listen for dodge failure events (show UI hint instead of just console warning)
	EventBus.player_dodge_failed.connect(_on_player_dodge_failed)
	
	# Listen for generic combat action failures
	EventBus.combat_action_failed.connect(_on_combat_action_failed)

var _notification_queue: Array[String] = []
var _notification_active: bool = false

func _setup_notification_label():
	_notification_label = Label.new()
	_notification_label.add_theme_font_size_override("font_size", 24)
	_notification_label.add_theme_color_override("font_color", Color(0.94, 0.27, 0.27))
	_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
	_notification_label.anchor_left = 0.5
	_notification_label.anchor_top = 1.0
	_notification_label.anchor_right = 0.5
	_notification_label.anchor_bottom = 1.0
	_notification_label.offset_left = -200.0
	_notification_label.offset_top = -120.0
	_notification_label.offset_right = 200.0
	_notification_label.offset_bottom = -80.0
	_notification_label.visible = false
	add_child(_notification_label)

func _show_notification(text: String, duration: float = 2.0):
	_notification_queue.append(text)
	if not _notification_active:
		_process_notification_queue(duration)

func _process_notification_queue(duration: float):
	if _notification_queue.is_empty():
		_notification_active = false
		if _notification_label:
			_notification_label.visible = false
		return
	
	_notification_active = true
	var text = _notification_queue.pop_front()
	if _notification_label:
		_notification_label.text = text
		_notification_label.visible = true
		# Fade in/out animation
		_notification_label.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(_notification_label, "modulate:a", 1.0, 0.1)
		tween.tween_interval(duration)
		tween.tween_property(_notification_label, "modulate:a", 0.0, 0.3)
		tween.finished.connect(func():
			_process_notification_queue(duration)
		)
	else:
		_process_notification_queue(duration)

func _on_weapon_out_of_ammo(item_data: ItemData):
	var weapon_name = item_data.item_name if item_data else "Weapon"
	_show_notification(weapon_name + ": Out of ammo! (Press reload key)")

func _on_player_dodge_failed(_player: Node, reason: String):
	# Show user-friendly localized hint on screen instead of just console warning
	var hint_text: String = ""
	if reason == "Not enough ATP":
		hint_text = "Dodge failed: Not enough ATP!"
	elif reason == "Dodge on cooldown":
		hint_text = "Dodge on cooldown!"
	elif reason == "Already dodging":
		hint_text = "Dodge in progress!"
	else:
		hint_text = "Dodge failed: %s" % reason
	_show_notification(hint_text, 1.5)

func _on_combat_action_failed(action: String, reason: String):
	var action_name := ""
	match action:
		"light_attack": action_name = "Light Attack"
		"heavy_attack": action_name = "Heavy Attack"
		_:
			action_name = action.capitalize()
	_show_notification("%s failed: %s" % [action_name, reason], 1.5)

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
	# Connect to the player's new ECS-lite signals for stat changes.
	player_node.actor_health_changed.connect(_on_player_health_changed)
	player_node.actor_atp_changed.connect(_on_player_atp_changed)
	player_node.actor_glucose_changed.connect(_on_player_glucose_changed)
	
	# Trigger initial update via StatSystem (authoritative) if entity already registered.
	if player_node.entity_id >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		var eid := player_node.entity_id
		if stat_system:
			_on_player_health_changed(
				int(stat_system.get_stat_current(eid, "health")),
				int(stat_system.get_stat_value(eid, "health"))
			)
			_on_player_atp_changed(
				stat_system.get_stat_current(eid, "atp"),
				stat_system.get_stat_value(eid, "atp")
			)
			_on_player_glucose_changed(
				stat_system.get_stat_current(eid, "glucose"),
				stat_system.get_stat_value(eid, "glucose")
			)
	
	# Update player name
	if PlayerData:
		player_name_label.text = PlayerData.player_name

func _on_player_health_changed(current_health: int, max_health: int):
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_value.text = "%d/%d" % [current_health, max_health]

func _on_player_atp_changed(current_atp: float, max_atp: float):
	atp_bar.max_value = max_atp
	atp_bar.value = current_atp
	atp_value.text = "%d/%d" % [current_atp, max_atp]

func _on_player_glucose_changed(current_glucose: float, max_glucose: float):
	glucose_label.text = "Glucose: %.1f/%.1f" % [current_glucose, max_glucose]

func _physics_process(_delta):
	# Glucose is now updated via signal, no need to poll
	_update_tank_status()

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
