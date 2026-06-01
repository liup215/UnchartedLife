# data/definitions/stat/stat_definition.gd
# Resource that defines a single numeric stat for an entity.
# Used by StatSystem to initialize entity stat instances.
extends Resource
class_name StatDefinition

@export var stat_id: String = ""
@export var base_value: float = 0.0
@export var min_value: float = -999999.0
@export var max_value: float = 999999.0
## If true, this stat is treated as a resource pool (has a current / max pair).
@export var is_resource_pool: bool = false
@export var description: String = ""
