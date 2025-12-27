# tts_manager.gd
# Global TTS (Text-to-Speech) manager for dialogue and UI text.
# This script should be configured as an Autoload singleton in Godot's project settings.
# Uses Godot's built-in DisplayServer TTS functionality.
extends Node

# Global TTS settings
var tts_enabled: bool = true
var global_tts_rate: float = 1.0
var global_tts_pitch: float = 1.0
var global_tts_volume: float = 50.0  # 0-100 range for DisplayServer

# Current speech state
var _current_utterance_id: int = -1
var _is_speaking: bool = false

signal tts_started()
signal tts_finished()
signal tts_cancelled()

func _ready() -> void:
	# Check if TTS is available on this platform
	if not DisplayServer.tts_is_speaking_supported():
		push_warning("TTSManager: Text-to-speech is not supported on this platform")
		tts_enabled = false

func is_available() -> bool:
	"""Check if TTS is available on the current platform."""
	return DisplayServer.tts_is_speaking_supported()

func speak(text: String, voice_id: String = "", rate: float = -1.0, pitch: float = -1.0, volume: float = -1.0, interrupt: bool = true) -> void:
	"""
	Speak the given text using TTS.
	
	Args:
		text: The text to speak
		voice_id: Voice identifier (empty string uses default)
		rate: Speech rate (uses global default if -1)
		pitch: Voice pitch (uses global default if -1)
		volume: Volume 0-100 (uses global default if -1)
		interrupt: Whether to stop current speech before starting new
	"""
	if not tts_enabled or not is_available():
		return
	
	if text.is_empty():
		return
	
	# Stop current speech if interrupting
	if interrupt and is_speaking():
		stop()
	
	# Use global defaults if parameters not specified
	var final_rate := rate if rate >= 0.0 else global_tts_rate
	var final_pitch := pitch if pitch >= 0.0 else global_tts_pitch
	var final_volume := volume if volume >= 0.0 else global_tts_volume
	
	# Clamp values to valid ranges
	final_rate = clamp(final_rate, 0.1, 10.0)
	final_pitch = clamp(final_pitch, 0.0, 2.0)
	final_volume = clamp(final_volume, 0.0, 100.0)
	
	# Start speaking
	_is_speaking = true
	DisplayServer.tts_speak(text, voice_id, final_volume, final_pitch, final_rate, 0, interrupt)
	tts_started.emit()

func stop() -> void:
	"""Stop any currently playing TTS."""
	if not is_available():
		return
	
	if _is_speaking:
		DisplayServer.tts_stop()
		_is_speaking = false
		tts_cancelled.emit()

func pause() -> void:
	"""Pause the current TTS playback."""
	if not is_available():
		return
	
	if _is_speaking:
		DisplayServer.tts_pause()

func resume() -> void:
	"""Resume paused TTS playback."""
	if not is_available():
		return
	
	if _is_speaking:
		DisplayServer.tts_resume()

func is_speaking() -> bool:
	"""Check if TTS is currently speaking."""
	if not is_available():
		return false
	
	# Update internal state from DisplayServer
	_is_speaking = DisplayServer.tts_is_speaking()
	return _is_speaking

func get_available_voices() -> PackedStringArray:
	"""Get list of available TTS voices on the system."""
	if not is_available():
		return PackedStringArray()
	
	return DisplayServer.tts_get_voices()

func set_tts_enabled(enabled: bool) -> void:
	"""Enable or disable TTS globally."""
	tts_enabled = enabled
	if not enabled:
		stop()

func is_tts_enabled() -> bool:
	"""Check if TTS is globally enabled."""
	return tts_enabled and is_available()

func _process(_delta: float) -> void:
	# Check if speech has finished
	if _is_speaking and not DisplayServer.tts_is_speaking():
		_is_speaking = false
		tts_finished.emit()
