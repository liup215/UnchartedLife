# data/definitions/stat/stat_sheet.gd
# A collection of StatDefinitions for a specific entity type (e.g. Player, Slime).
# Provides a clean way to define all stats in one Resource file.
extends Resource
class_name StatSheet

@export var entity_type: String = ""
@export var stats: Array[StatDefinition] = []
@export var description: String = ""

## Convenience to find a stat definition by ID.
func get_stat_def(stat_id: String) -> StatDefinition:
	for def in stats:
		if def.stat_id == stat_id:
			return def
	return null

## Returns all resource-pool stat IDs.
func get_resource_pool_stats() -> Array[String]:
	var result: Array[String] = []
	for def in stats:
		if def.is_resource_pool:
			result.append(def.stat_id)
	return result
