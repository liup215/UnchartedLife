# systems/core/tick_system.gd
# Unified game tick pipeline.
# All gameplay systems that need per-frame updates register here instead of
# using their own _process. This guarantees deterministic execution order.
extends Node
class_name TickSystem

class TickEntry:
	var system: Object
	var method_name: StringName
	var priority: int

var _entries: Array[TickEntry] = []
var _is_sorted: bool = false

## Register a system that has an `on_tick(delta: float) -> void` method.
func register_system(system: Object, method_name: StringName = &"on_tick", priority: int = 0) -> void:
	var entry := TickEntry.new()
	entry.system = system
	entry.method_name = method_name
	entry.priority = priority
	_entries.append(entry)
	_is_sorted = false

func unregister_system(system: Object) -> void:
	_entries = _entries.filter(func(e: TickEntry) -> bool:
		return e.system != system
	)

func tick(delta: float) -> void:
	if not _is_sorted:
		_entries.sort_custom(func(a: TickEntry, b: TickEntry) -> int:
			return a.priority - b.priority
		)
		_is_sorted = true

	for entry in _entries:
		if entry.system and is_instance_valid(entry.system):
			if entry.system.has_method(entry.method_name):
				entry.system.call(entry.method_name, delta)

## Hook this into a root node _process or _physics_process.
func _process(delta: float) -> void:
	tick(delta)
