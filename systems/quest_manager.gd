# quest_manager.gd
# Global quest lifecycle manager with hierarchical objective support.
extends Node

const STATUS_INACTIVE := 0
const STATUS_ACTIVE := 1
const STATUS_COMPLETED := 2
const STATUS_FAILED := 3

var _quest_defs: Dictionary = {}            # id -> QuestData
var _quest_states: Dictionary = {}          # id -> QuestRuntimeState

func _ready() -> void:
	add_to_group("saveable")

# --- Public API ---

func register_quest(def: QuestData) -> bool:
	if def == null or def.id.is_empty():
		push_error("QuestManager.register_quest: invalid QuestData or empty id")
		return false
	if _quest_defs.has(def.id):
		push_warning("QuestManager: duplicate quest id '%s'" % def.id)
		return false
	_quest_defs[def.id] = def
	return true

func start_quest(id: String) -> bool:
	if not _quest_defs.has(id):
		push_error("QuestManager.start_quest: unknown quest id '%s'" % id)
		return false
	var def: QuestData = _quest_defs[id]
	var state = QuestRuntimeState.new(id)
	state.status = STATUS_ACTIVE
	state.objective_states = _build_objective_states(def.objectives)
	_quest_states[id] = state
	EventBus.quest_started.emit(id)
	return true

func get_active_quests() -> Array[QuestRuntimeState]:
	var arr: Array[QuestRuntimeState] = []
	for id in _quest_states.keys():
		var st: QuestRuntimeState = _quest_states[id]
		if st.status == STATUS_ACTIVE:
			arr.append(st)
	return arr

func get_quest_status(id: String) -> int:
	if _quest_states.has(id):
		var st: QuestRuntimeState = _quest_states[id]
		return st.status
	return STATUS_INACTIVE

func complete_quest(id: String) -> void:
	if not _quest_states.has(id):
		return
	var st: QuestRuntimeState = _quest_states[id]
	st.status = STATUS_COMPLETED
	EventBus.quest_completed.emit(id)

# Advance a leaf objective or mark composite child as complete.
# objective_path: indices through the hierarchy (e.g., [0, 2] means objectives[0].sub_objectives[2])
func advance_objective(quest_id: String, objective_path: Array[int], amount: float = 1.0) -> void:
	if not _quest_states.has(quest_id):
		return
	var st: QuestRuntimeState = _quest_states[quest_id]
	if st.status != STATUS_ACTIVE:
		return
	var obj_state := _get_objective_state_by_path(st, objective_path)
	if obj_state == null:
		push_warning("advance_objective: invalid path for quest '%s'" % quest_id)
		return
	if obj_state.sub_states.is_empty():
		# Leaf objective: increase progress; target_count used as threshold if set.
		obj_state.progress += amount
		var target = max(1, int(obj_state.target_count))
		if obj_state.progress >= float(target):
			obj_state.is_complete = true
	else:
		# Composite child: amount >= 1 means mark one sub as complete is handled externally.
		# Typically, composites are completed by their children being completed.
		pass
	# Re-evaluate hierarchy and quest completion
	_update_composites_and_emit(quest_id)
	var complete := obj_state.is_complete
	EventBus.objective_updated.emit(quest_id, objective_path, obj_state.progress, complete)

func fail_quest(quest_id: String, reason: String = "") -> void:
	if not _quest_states.has(quest_id): return
	var st: QuestRuntimeState = _quest_states[quest_id]
	st.status = STATUS_FAILED
	EventBus.quest_failed.emit(quest_id, reason)

# --- Internal helpers ---

func _build_objective_states(objs: Array[ObjectiveData]) -> Array[QuestRuntimeState.ObjectiveRuntimeState]:
	var states: Array[QuestRuntimeState.ObjectiveRuntimeState] = []
	for obj in objs:
		var s := QuestRuntimeState.ObjectiveRuntimeState.new()
		s.type = obj.type
		s.optional = obj.optional
		s.params = obj.params.duplicate()
		s.track_via_event = obj.track_via_event
		s.policy = obj.policy
		s.target_count = obj.target_count
		if not obj.sub_objectives.is_empty():
			s.sub_states = _build_objective_states(obj.sub_objectives)
		states.append(s)
	return states

func _get_objective_state_by_path(st: QuestRuntimeState, path: Array[int]) -> QuestRuntimeState.ObjectiveRuntimeState:
	var current_list := st.objective_states
	var current: QuestRuntimeState.ObjectiveRuntimeState = null
	for i in path:
		if i < 0 or i >= current_list.size():
			return null
		current = current_list[i]
		current_list = current.sub_states
	return current

func _update_composites_and_emit(quest_id: String) -> void:
	var st: QuestRuntimeState = _quest_states[quest_id]
	for i in st.objective_states.size():
		_update_objective_recursive(st.objective_states[i])
	# Quest completion: all non-optional objectives complete
	var all_complete := true
	for obj in st.objective_states:
		if obj.optional:
			continue
		if not obj.is_complete:
			all_complete = false
			break
	if all_complete and st.status == STATUS_ACTIVE:
		st.status = STATUS_COMPLETED
		EventBus.quest_completed.emit(quest_id)

func _update_objective_recursive(obj: QuestRuntimeState.ObjectiveRuntimeState) -> void:
	if obj.sub_states.is_empty():
		# Leaf: complete state already set by advance_objective
		return
	match obj.policy:
		0: # ALL
			var all_c := true
			for c in obj.sub_states:
				_update_objective_recursive(c)
				if not c.is_complete:
					all_c = false
					break
			obj.is_complete = all_c
		1: # ANY
			var any_c := false
			for c in obj.sub_states:
				_update_objective_recursive(c)
				if c.is_complete:
					any_c = true
					break
			obj.is_complete = any_c
		2: # COUNT
			var count := 0
			for c in obj.sub_states:
				_update_objective_recursive(c)
				if c.is_complete:
					count += 1
			obj.is_complete = count >= max(1, obj.target_count)
		_: # default to ALL
			var all_c2 := true
			for c in obj.sub_states:
				_update_objective_recursive(c)
				if not c.is_complete:
					all_c2 = false
					break
			obj.is_complete = all_c2

# --- Save/Load ---

func save_data() -> Dictionary:
	var data: Dictionary = {}
	for id in _quest_states.keys():
		var st: QuestRuntimeState = _quest_states[id]
		data[id] = {
			"status": st.status,
			"objectives": _serialize_objectives(st.objective_states)
		}
	return data

func load_data(data: Dictionary) -> void:
	for id in data.keys():
		if not _quest_defs.has(id):
			continue
		var def: QuestData = _quest_defs[id]
		var st := QuestRuntimeState.new(id)
		st.status = int(data[id].get("status", STATUS_INACTIVE))
		st.objective_states = _build_objective_states(def.objectives)
		_deserialize_objectives(st.objective_states, data[id].get("objectives", []))
		_quest_states[id] = st

func _serialize_objectives(list: Array[QuestRuntimeState.ObjectiveRuntimeState]) -> Array:
	var arr: Array = []
	for o in list:
		arr.append({
			"progress": o.progress,
			"complete": o.is_complete,
			"optional": o.optional,
			"policy": o.policy,
			"target_count": o.target_count,
			"sub": _serialize_objectives(o.sub_states)
		})
	return arr

func _deserialize_objectives(list: Array[QuestRuntimeState.ObjectiveRuntimeState], data_list: Array) -> void:
	var n = min(list.size(), data_list.size())
	for i in n:
		var o := list[i]
		var d: Dictionary = data_list[i]
		o.progress = float(d.get("progress", 0.0))
		o.is_complete = bool(d.get("complete", false))
		o.optional = bool(d.get("optional", o.optional))
		o.policy = int(d.get("policy", o.policy))
		o.target_count = int(d.get("target_count", o.target_count))
		_deserialize_objectives(o.sub_states, d.get("sub", []))
