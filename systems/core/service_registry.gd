# systems/core/service_registry.gd
# Central registry for all game systems.
# Systems register themselves here; consumers request services by name.
# This replaces all direct singleton references with a single lookup point.
extends Node
class_name ServiceRegistry

var _services: Dictionary[String, Object] = {}

func register(name: String, service: Object) -> void:
	if _services.has(name):
		push_warning("ServiceRegistry: service '%s' already registered, overwriting" % name)
	_services[name] = service

func get_service(name: String) -> Object:
	if not _services.has(name):
		push_error("ServiceRegistry: service '%s' not registered" % name)
		return null
	return _services[name]

func has_service(name: String) -> bool:
	return _services.has(name)

func remove_service(name: String) -> void:
	if _services.has(name):
		_services.erase(name)

func list_services() -> Array[String]:
	var keys: Array = _services.keys()
	var result: Array[String] = []
	for k in keys:
		result.append(k)
	return result
