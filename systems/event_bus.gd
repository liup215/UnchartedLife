# event_bus.gd
# Facade event bus that delegates signals to domain-specific sub-buses.
# Existing code can continue using EventBus.signal_name.connect(...) without changes.
# New code should prefer CombatBus, QuestBus, or UIEventBus directly for clarity.
extends Node

# Sub-buses (created in _ready so they are available for relaying)
var combat: CombatBus
var quest: QuestBus
var ui: UIEventBus

# --- Combat / Item signals (delegated to CombatBus) ---
signal actor_health_changed(actor: Node, current_health: int, max_health: int)
signal actor_died(actor: Node)
signal inventory_item_added(item_data: ItemData, quantity: int)
signal item_used(actor: Actor, item: ItemData, success: bool)
signal equipment_changed(actor: Actor)
signal item_use_failed(actor: Actor, item: ItemData, reason: String)
signal buff_applied(actor: Actor, buff_id: String, duration: float)
signal request_quiz_reload(weapon_data: Resource)
signal weapon_out_of_ammo(item_data: ItemData)
signal quiz_completed(success: bool)

# --- Quest signals (delegated to QuestBus) ---
signal quest_triggered(quest_id: String, step: int)
signal quest_started(quest_id: String)
signal objective_updated(quest_id: String, objective_path: Array[int], progress: float, complete: bool)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String, reason: String)

# --- UI / Dialogue signals (delegated to UIEventBus) ---
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

# --- Map & Misc signals (kept on EventBus itself) ---
signal map_changed(map_id: String, spawn_position: Vector2)
signal area_unlocked(area_id: String)
signal molecule_collected(molecule_type: int, is_glucose: bool)

func _ready():
	combat = CombatBus.new()
	combat.name = "CombatBus"
	add_child(combat)
	_relay_combat_signals()

	quest = QuestBus.new()
	quest.name = "QuestBus"
	add_child(quest)
	_relay_quest_signals()

	ui = UIEventBus.new()
	ui.name = "UIEventBus"
	add_child(ui)
	_relay_ui_signals()

func _relay_combat_signals() -> void:
	combat.actor_health_changed.connect(func(a, c, m): actor_health_changed.emit(a, c, m))
	combat.actor_died.connect(func(a): actor_died.emit(a))
	combat.inventory_item_added.connect(func(i, q): inventory_item_added.emit(i, q))
	combat.item_used.connect(func(a, i, s): item_used.emit(a, i, s))
	combat.equipment_changed.connect(func(a): equipment_changed.emit(a))
	combat.item_use_failed.connect(func(a, i, r): item_use_failed.emit(a, i, r))
	combat.buff_applied.connect(func(a, b, d): buff_applied.emit(a, b, d))
	combat.request_quiz_reload.connect(func(w): request_quiz_reload.emit(w))
	combat.weapon_out_of_ammo.connect(func(i): weapon_out_of_ammo.emit(i))
	combat.quiz_completed.connect(func(s): quiz_completed.emit(s))

	# Reverse relay: EventBus emits forwarded to combat bus
	actor_health_changed.connect(func(a, c, m): combat.actor_health_changed.emit(a, c, m))
	actor_died.connect(func(a): combat.actor_died.emit(a))
	inventory_item_added.connect(func(i, q): combat.inventory_item_added.emit(i, q))
	item_used.connect(func(a, i, s): combat.item_used.emit(a, i, s))
	equipment_changed.connect(func(a): combat.equipment_changed.emit(a))
	item_use_failed.connect(func(a, i, r): combat.item_use_failed.emit(a, i, r))
	buff_applied.connect(func(a, b, d): combat.buff_applied.emit(a, b, d))
	request_quiz_reload.connect(func(w): combat.request_quiz_reload.emit(w))
	weapon_out_of_ammo.connect(func(i): combat.weapon_out_of_ammo.emit(i))
	quiz_completed.connect(func(s): combat.quiz_completed.emit(s))

func _relay_quest_signals() -> void:
	quest.quest_triggered.connect(func(id, s): quest_triggered.emit(id, s))
	quest.quest_started.connect(func(id): quest_started.emit(id))
	quest.objective_updated.connect(func(id, p, pr, c): objective_updated.emit(id, p, pr, c))
	quest.quest_completed.connect(func(id): quest_completed.emit(id))
	quest.quest_failed.connect(func(id, r): quest_failed.emit(id, r))

	quest_triggered.connect(func(id, s): quest.quest_triggered.emit(id, s))
	quest_started.connect(func(id): quest.quest_started.emit(id))
	objective_updated.connect(func(id, p, pr, c): quest.objective_updated.emit(id, p, pr, c))
	quest_completed.connect(func(id): quest.quest_completed.emit(id))
	quest_failed.connect(func(id, r): quest.quest_failed.emit(id, r))

func _relay_ui_signals() -> void:
	ui.dialogue_started.connect(func(d, n): dialogue_started.emit(d, n))
	ui.dialogue_line.connect(func(l, i, t, n): dialogue_line.emit(l, i, t, n))
	ui.dialogue_choices.connect(func(c, n): dialogue_choices.emit(c, n))
	ui.dialogue_choice_made.connect(func(c, n): dialogue_choice_made.emit(c, n))
	ui.dialogue_ended.connect(func(n, r): dialogue_ended.emit(n, r))
	ui.dialogue_event.connect(func(e, p): dialogue_event.emit(e, p))
	ui.player_dodge_started.connect(func(p): player_dodge_started.emit(p))
	ui.player_dodge_ended.connect(func(p): player_dodge_ended.emit(p))
	ui.player_dodge_failed.connect(func(p, r): player_dodge_failed.emit(p, r))
	ui.story_scene_entered.connect(func(s): story_scene_entered.emit(s))
	ui.story_milestone_reached.connect(func(m, d): story_milestone_reached.emit(m, d))
	ui.request_scene_transition.connect(func(s, sp): request_scene_transition.emit(s, sp))

	dialogue_started.connect(func(d, n): ui.dialogue_started.emit(d, n))
	dialogue_line.connect(func(l, i, t, n): ui.dialogue_line.emit(l, i, t, n))
	dialogue_choices.connect(func(c, n): ui.dialogue_choices.emit(c, n))
	dialogue_choice_made.connect(func(c, n): ui.dialogue_choice_made.emit(c, n))
	dialogue_ended.connect(func(n, r): ui.dialogue_ended.emit(n, r))
	dialogue_event.connect(func(e, p): ui.dialogue_event.emit(e, p))
	player_dodge_started.connect(func(p): ui.player_dodge_started.emit(p))
	player_dodge_ended.connect(func(p): ui.player_dodge_ended.emit(p))
	player_dodge_failed.connect(func(p, r): ui.player_dodge_failed.emit(p, r))
	story_scene_entered.connect(func(s): ui.story_scene_entered.emit(s))
	story_milestone_reached.connect(func(m, d): ui.story_milestone_reached.emit(m, d))
	request_scene_transition.connect(func(s, sp): ui.request_scene_transition.emit(s, sp))
