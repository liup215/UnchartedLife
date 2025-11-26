class_name BossData
extends ActorData

@export var boss_name: String = "Unknown Entity"
@export var texture: Texture2D
# max_hp is inherited from ActorData

enum WeaknessType {
DEFINITION, # Red
	PROCESS,    # Blue
	APPLICATION # Green
}

@export var weakness_type: WeaknessType = WeaknessType.DEFINITION
