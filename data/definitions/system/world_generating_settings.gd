extends Node
class_name WorldGeneratingSettings

var Difficulty: String = "Normal"
var Seed: String = ""

func to_dict() -> Dictionary:
	return {
		"Difficulty": Difficulty,
		"Seed": Seed,
	}

func from_dict(data: Dictionary) -> void:
	if data.has("Difficulty"):
		Difficulty = data["Difficulty"]
	if data.has("Seed"):
		Seed = data["Seed"]