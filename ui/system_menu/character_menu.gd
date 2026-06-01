extends Control

@onready var name_label: Label = $HBoxContainer/RightPanel/BasicInfo/NameLabel
@onready var level_label: Label = $HBoxContainer/RightPanel/BasicInfo/LevelLabel

@onready var health_bar: ProgressBar = $HBoxContainer/RightPanel/StatsContainer/HealthContainer/HealthBar
@onready var health_value: Label = $HBoxContainer/RightPanel/StatsContainer/HealthContainer/HealthValue

@onready var atp_bar: ProgressBar = $HBoxContainer/RightPanel/StatsContainer/ATPContainer/ATPBar
@onready var atp_value: Label = $HBoxContainer/RightPanel/StatsContainer/ATPContainer/ATPValue

@onready var glucose_bar: ProgressBar = $HBoxContainer/RightPanel/StatsContainer/GlucoseContainer/GlucoseBar
@onready var glucose_value: Label = $HBoxContainer/RightPanel/StatsContainer/GlucoseContainer/GlucoseValue

@onready var neural_response_value: Label = $HBoxContainer/RightPanel/AttributesContainer/AttributesGrid/NeuralResponseValue
@onready var muscle_coordination_value: Label = $HBoxContainer/RightPanel/AttributesContainer/AttributesGrid/MuscleCoordinationValue
@onready var base_speed_value: Label = $HBoxContainer/RightPanel/AttributesContainer/AttributesGrid/BaseSpeedValue

func _ready():
	update_character_info()

func _get_player_runtime_state() -> ActorRuntimeState:
	var player = get_tree().get_first_node_in_group("player") as Actor
	if player and player.runtime_state:
		return player.runtime_state
	return null

func update_character_info():
	if PlayerData:
		# Update basic info
		name_label.text = "Name: " + PlayerData.player_name

		# Update static attributes from template
		if PlayerData.actor_data:
			var actor_data = PlayerData.actor_data
			neural_response_value.text = str(actor_data.neural_response_speed)
			muscle_coordination_value.text = str(actor_data.muscle_coordination)
			base_speed_value.text = str(actor_data.base_speed)
		
		# Update live stats from runtime state
		var rs := _get_player_runtime_state()
		if rs:
			health_bar.max_value = rs.max_health
			health_bar.value = rs.current_health
			health_value.text = str(rs.current_health) + " / " + str(rs.max_health)
			
			atp_bar.max_value = rs.max_atp
			atp_bar.value = rs.current_atp
			atp_value.text = str(rs.current_atp) + " / " + str(rs.max_atp)
			
			glucose_bar.max_value = rs.max_glucose
			glucose_bar.value = rs.current_glucose
			glucose_value.text = str(rs.current_glucose) + " / " + str(rs.max_glucose)
