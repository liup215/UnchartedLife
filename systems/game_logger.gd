# GameLogger.gd
# Global logging system replacing print() calls
# Supports log levels, categories, and runtime filtering
extends Node

## Enabled log categories. Empty = all enabled.
@export var enabled_categories: Array[StringName] = []

## Minimum log level. 0=DEBUG, 1=INFO, 2=WARNING, 3=ERROR
@export var minimum_level: int = 0

## Whether logging is active
@export var active: bool = true

## Show timestamp prefix
@export var show_timestamp: bool = true

enum Level {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3
}

const LEVEL_NAMES: Array[String] = ["DEBUG", "INFO", "WARN", "ERROR"]

func debug(category: StringName, message: String):
	_log(Level.DEBUG, category, message)

func info(category: StringName, message: String):
	_log(Level.INFO, category, message)

func warn(category: StringName, message: String):
	_log(Level.WARNING, category, message)

func error(category: StringName, message: String):
	_log(Level.ERROR, category, message)

func _log(level: int, category: StringName, message: String) -> void:
	if not active:
		return
	if level < minimum_level:
		return
	if not enabled_categories.is_empty() and category not in enabled_categories:
		return

	var prefix := "[%s]" % LEVEL_NAMES[level]
	if show_timestamp:
		prefix = "[%s]%s[%s]" % [Time.get_time_string_from_system(), prefix, category]
	else:
		prefix = "%s[%s]" % [prefix, category]

	# Format with level-specific prefix
	var formatted := "%s %s" % [prefix, message]

	if level >= Level.ERROR:
		push_error(formatted)
	elif level >= Level.WARNING:
		push_warning(formatted)
	else:
		print(formatted)
