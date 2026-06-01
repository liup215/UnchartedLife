# ui_event_bus.gd
# Signals related to UI feedback, input, menus, and dialogue.
extends Node
class_name UIEventBus

signal dialogue_started(dialogue: DialogueData, npc_id: String)
signal dialogue_line(line: DialogueLineData, line_index: int, total_lines: int, npc_id: String)
signal dialogue_choices(choices: Array[DialogueChoiceData], npc_id: String)
signal dialogue_choice_made(choice: DialogueChoiceData, npc_id: String)
signal dialogue_ended(npc_id: String, reason: String)
signal dialogue_event(event_name: String, payload: Dictionary)

signal player_dodge_started(player: Node)
signal player_dodge_ended(player: Node)
signal player_dodge_failed(player: Node, reason: String)

signal story_scene_entered(scene_id: String)
signal story_milestone_reached(milestone_id: String, data: Dictionary)

signal request_scene_transition(scene_id: String, spawn_point_id: String)

# Generic combat action failure feedback for HUD popups
signal combat_action_failed(action: String, reason: String)
