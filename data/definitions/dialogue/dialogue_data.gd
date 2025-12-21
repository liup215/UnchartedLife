extends Resource
class_name DialogueData

@export var id: String = ""
@export var lines: Array[DialogueLineData] = []
@export var choices: Array[DialogueChoiceData] = []
@export var typing_speed: float = 0.03
@export var can_skip: bool = true
@export var metadata: Dictionary = {}
