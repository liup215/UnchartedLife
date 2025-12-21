extends Node

signal dialogue_started(dialogue: DialogueData, npc_id: String)
signal dialogue_line_requested(line: DialogueLineData, index: int, total: int, npc_id: String)
signal dialogue_choices_requested(choices: Array[DialogueChoiceData], npc_id: String)
signal dialogue_ended(npc_id: String, reason: String)

var _library: Dictionary = {} # id -> DialogueData
var _current_dialogue: DialogueData
var _current_npc_id: String = ""
var _current_line_index: int = 0
var _available_choices: Array[DialogueChoiceData] = []
var _context: Dictionary = {}
var _flags: Dictionary = {}
var _active: bool = false
var _waiting_for_choice: bool = false

func register_dialogue(dialogue: DialogueData) -> void:
	if dialogue == null or dialogue.id.is_empty():
		push_warning("DialogueManager: attempted to register dialogue with empty id")
		return
	_library[dialogue.id] = dialogue

func register_dialogues(dialogues: Array[DialogueData]) -> void:
	for dlg in dialogues:
		register_dialogue(dlg)

func start_dialogue(dialogue: DialogueData, npc_id: String = "", context: Dictionary = {}) -> void:
	if dialogue == null:
		push_warning("DialogueManager.start_dialogue: dialogue is null")
		return
	_current_dialogue = dialogue
	_current_npc_id = npc_id
	_current_line_index = 0
	_available_choices.clear()
	_context = context.duplicate()
	_active = true
	_waiting_for_choice = false
	dialogue_started.emit(dialogue, npc_id)
	EventBus.dialogue_started.emit(dialogue, npc_id)
	_emit_next_line()

func is_active() -> bool:
	return _active

func request_advance() -> void:
	if not _active:
		return
	if _waiting_for_choice:
		return
	_emit_next_line()

func choose(index: int) -> void:
	if not _active:
		return
	if index < 0 or index >= _available_choices.size():
		push_warning("DialogueManager.choose: index out of range")
		return
	var choice: DialogueChoiceData = _available_choices[index]
	_apply_effects(choice.effects)
	EventBus.dialogue_choice_made.emit(choice, _current_npc_id)
	_waiting_for_choice = false
	if not choice.next_dialogue_id.is_empty():
		var next = _library.get(choice.next_dialogue_id, null)
		if next:
			start_dialogue(next, _current_npc_id, _context)
			return
		else:
			push_warning("DialogueManager: next dialogue '%s' not registered" % choice.next_dialogue_id)
	_end_dialogue("no_next_dialogue")

func interrupt(reason: String = "interrupted") -> void:
	if not _active:
		return
	_end_dialogue(reason)

func set_flag(key: String, value: bool) -> void:
	_flags[key] = value

func get_flag(key: String) -> bool:
	return bool(_flags.get(key, false))

# --- Internal ---

func _emit_next_line() -> void:
	if _current_dialogue == null:
		return
	if _current_line_index >= _current_dialogue.lines.size():
		_emit_choices_or_end()
		return
	var line: DialogueLineData = _current_dialogue.lines[_current_line_index]
	_current_line_index += 1
	dialogue_line_requested.emit(line, _current_line_index, _current_dialogue.lines.size(), _current_npc_id)
	EventBus.dialogue_line.emit(line, _current_line_index, _current_dialogue.lines.size(), _current_npc_id)
	# Auto advance if line demands it
	if line.auto_advance and not _waiting_for_choice:
		_emit_next_line()

func _emit_choices_or_end() -> void:
	_available_choices.clear()
	if _current_dialogue.choices.is_empty():
		_end_dialogue("no_choices")
		return
	for choice in _current_dialogue.choices:
		if _conditions_pass(choice.conditions):
			_available_choices.append(choice)
	_waiting_for_choice = true
	if _available_choices.is_empty():
		_end_dialogue("no_available_choices")
		return
	dialogue_choices_requested.emit(_available_choices, _current_npc_id)
	EventBus.dialogue_choices.emit(_available_choices, _current_npc_id)

func _conditions_pass(conditions: Array[DialogueConditionData]) -> bool:
	for cond in conditions:
		if not _condition_pass(cond):
			return false
	return true

func _condition_pass(cond: DialogueConditionData) -> bool:
	if cond == null:
		return true
	var result := true
	match cond.condition_type:
		DialogueConditionData.ConditionType.ALWAYS:
			result = true
		DialogueConditionData.ConditionType.QUEST_ACTIVE:
			result = _is_quest_status(cond.quest_id, QuestRuntimeState.STATUS_ACTIVE)
		DialogueConditionData.ConditionType.QUEST_COMPLETED:
			result = _is_quest_status(cond.quest_id, QuestRuntimeState.STATUS_COMPLETED)
		DialogueConditionData.ConditionType.QUEST_NOT_STARTED:
			result = not _is_quest_status(cond.quest_id, QuestRuntimeState.STATUS_ACTIVE) and not _is_quest_status(cond.quest_id, QuestRuntimeState.STATUS_COMPLETED)
		DialogueConditionData.ConditionType.FLAG_SET:
			result = get_flag(cond.flag)
		_:
			result = true
	return not result if cond.negate else result

func _apply_effects(effects: Array[DialogueEffectData]) -> void:
	for effect in effects:
		_apply_effect(effect)

func _apply_effect(effect: DialogueEffectData) -> void:
	if effect == null:
		return
	match effect.effect_type:
		DialogueEffectData.EffectType.START_QUEST:
			if QuestManager:
				QuestManager.start_quest(effect.quest_id)
		DialogueEffectData.EffectType.COMPLETE_QUEST:
			if QuestManager and QuestManager.has_method("complete_quest"):
				QuestManager.complete_quest(effect.quest_id)
		DialogueEffectData.EffectType.SET_FLAG:
			set_flag(effect.flag, effect.flag_value)
		DialogueEffectData.EffectType.EMIT_EVENT:
			EventBus.dialogue_event.emit(effect.event_name, effect.payload)

func _is_quest_status(quest_id: String, status: int) -> bool:
	if QuestManager == null:
		return false
	if not QuestManager.has_method("get_quest_status"):
		return false
	return QuestManager.get_quest_status(quest_id) == status

func _end_dialogue(reason: String) -> void:
	_active = false
	_waiting_for_choice = false
	dialogue_ended.emit(_current_npc_id, reason)
	EventBus.dialogue_ended.emit(_current_npc_id, reason)
	_current_dialogue = null
	_current_npc_id = ""
	_current_line_index = 0
	_available_choices.clear()
	_context.clear()
