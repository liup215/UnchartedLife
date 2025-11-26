class_name QuestionData
extends Resource

enum QuestionType {
	DEFINITION, # Red - Definitions, Facts
	PROCESS,    # Blue - Mechanisms, Processes
	APPLICATION # Green - Examples, Applications
}

@export_multiline var question_text: String = ""
@export var options: Array[String] = ["", "", "", ""]
@export var correct_option_index: int = 0
@export var type: QuestionType = QuestionType.DEFINITION
