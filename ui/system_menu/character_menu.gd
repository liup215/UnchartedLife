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

func update_character_info():
	if PlayerData:
		# Update basic info
		name_label.text = "Name: " + PlayerData.player_name

		# Update stats if actor_data exists
		if PlayerData.actor_data:
			var actor_data = PlayerData.actor_data

			# Health
			health_bar.max_value = actor_data.max_health
			health_bar.value = actor_data.current_health
			health_value.text = str(actor_data.current_health) + " / " + str(actor_data.max_health)

			# ATP
			atp_bar.max_value = actor_data.max_atp
			atp_bar.value = actor_data.current_atp
			atp_value.text = str(actor_data.current_atp) + " / " + str(actor_data.max_atp)

			# Glucose
			glucose_bar.max_value = actor_data.max_glucose
			glucose_bar.value = actor_data.current_glucose
			glucose_value.text = str(actor_data.current_glucose) + " / " + str(actor_data.max_glucose)

			# Attributes
			neural_response_value.text = str(actor_data.neural_response_speed)
			muscle_coordination_value.text = str(actor_data.muscle_coordination)
			base_speed_value.text = str(actor_data.base_speed)

func _process(_delta):
	# Update in real-time if needed
	if visible:
		update_character_info()
