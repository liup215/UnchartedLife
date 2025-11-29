extends Control

@onready var syllabus_option: OptionButton = $VBoxContainer/SyllabusOption
@onready var chapter_option: OptionButton = $VBoxContainer/ChapterOption
@onready var mode_option: OptionButton = $VBoxContainer/ModeOption
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

const QUESTION_BANK_PATH = "res://data/question_bank/"
const BATTLE_SCENE_PATH = "res://features/bio_blitz/bio_blitz_battle.tscn"

var syllabi: Array[String] = []
var current_syllabus_path: String = ""

# Boss Data Mapping
# Map "Syllabus/Chapter.json" to BossData resources
var chapter_boss_map: Dictionary = {
	"A2Biology/cell_structure.json": preload("res://data/questions/bio_blitz_demo/boss_demo.tres"),
	"A2Biology/12_respiration.json": preload("res://data/questions/bio_blitz_demo/boss_respiration.tres"),
	# Add more mappings here:
	# "Math/fractions.json": preload("res://path/to/math_boss.tres"),
}

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	syllabus_option.item_selected.connect(_on_syllabus_selected)

	load_syllabi()

func load_syllabi() -> void:
	syllabus_option.clear()
	syllabi.clear()

	var dir = DirAccess.open(QUESTION_BANK_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				syllabi.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

		for syllabus in syllabi:
			syllabus_option.add_item(syllabus)

		if syllabi.size() > 0:
			_on_syllabus_selected(0)
		else:
			start_button.disabled = true
	else:
		print("Failed to open question bank path: " + QUESTION_BANK_PATH)

func _on_syllabus_selected(index: int) -> void:
	if index < 0 or index >= syllabi.size():
		return

	var syllabus_name = syllabi[index]
	current_syllabus_path = QUESTION_BANK_PATH + syllabus_name + "/"
	load_chapters(current_syllabus_path)

func load_chapters(path: String) -> void:
	chapter_option.clear()

	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				chapter_option.add_item(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	# Disable start button if no chapters
	start_button.disabled = (chapter_option.item_count == 0)

func _on_start_pressed() -> void:
	if chapter_option.item_count == 0:
		return

	var selected_chapter_index = chapter_option.selected
	if selected_chapter_index == -1:
		return

	var chapter_filename = chapter_option.get_item_text(selected_chapter_index)
	var full_path = current_syllabus_path + chapter_filename

	# Construct key for boss map: Syllabus/Chapter.json
	var selected_syllabus_index = syllabus_option.selected
	var syllabus_name = syllabus_option.get_item_text(selected_syllabus_index)
	var boss_map_key = syllabus_name + "/" + chapter_filename

	print("Starting game with chapter: " + full_path)

	# Load the battle scene
	var battle_scene_res = load(BATTLE_SCENE_PATH)
	if battle_scene_res:
		var battle_scene_instance = battle_scene_res.instantiate()

		# Assuming the root node of the battle scene is BioBlitzManager or has a script with 'question_bank_path'
		if "question_bank_path" in battle_scene_instance:
			battle_scene_instance.question_bank_path = full_path
		
		# Set Boss Data if defined for this chapter
		if boss_map_key in chapter_boss_map and "boss_data" in battle_scene_instance:
			battle_scene_instance.boss_data = chapter_boss_map[boss_map_key]
			print("Loaded specific boss for chapter: " + boss_map_key)

		# Switch scene manually since we instantiated it
		var root = get_tree().root
		root.add_child(battle_scene_instance)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = battle_scene_instance
	else:
		print("Error: Could not load battle scene at " + BATTLE_SCENE_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()
