# quest_bus.gd
# Signals related to quest lifecycle and objective tracking.
extends Node
class_name QuestBus

signal quest_started(quest_id: String)
signal objective_updated(quest_id: String, objective_path: Array[int], progress: float, complete: bool)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String, reason: String)
signal quest_triggered(quest_id: String, step: int)
