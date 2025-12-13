# quest_log_component.gd
# Attachable component to expose quest data to UI and react to quest events.
extends Node
class_name QuestLogComponent

signal quest_list_updated()

var _tracked_quest_id: String = ""

func _ready() -> void:
	EventBus.quest_started.connect(_on_quest_started)
	EventBus.objective_updated.connect(_on_objective_updated)
	EventBus.quest_completed.connect(_on_quest_completed)
	EventBus.quest_failed.connect(_on_quest_failed)

func set_tracked_quest(id: String) -> void:
	_tracked_quest_id = id
	quest_list_updated.emit()

func get_active_quests() -> Array[QuestRuntimeState]:
	if QuestManager:
		return QuestManager.get_active_quests()
	return []

func _on_quest_started(id: String) -> void:
	quest_list_updated.emit()

func _on_objective_updated(quest_id: String, _path: Array[int], _progress: float, _complete: bool) -> void:
	if quest_id == _tracked_quest_id:
		quest_list_updated.emit()

func _on_quest_completed(id: String) -> void:
	quest_list_updated.emit()

func _on_quest_failed(id: String, _reason: String) -> void:
	quest_list_updated.emit()
