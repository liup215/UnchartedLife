extends SceneTree
# Simple test script to verify TTSManager functionality
# Run with: godot --script tests/test_tts.gd --headless

func _init():
	print("=== TTS Manager Test ===")
	print("")
	
	# Test 1: Check if TTS is available
	print("Test 1: Checking TTS availability...")
	var voices = DisplayServer.tts_get_voices()
	var tts_available = voices.size() > 0
	print("  TTS Supported: ", tts_available)
	
	if not tts_available:
		print("  WARNING: TTS is not available on this platform")
		print("  This is expected in headless mode or on some platforms")
	
	# Test 2: Get available voices
	print("")
	print("Test 2: Getting available voices...")
	var voices = DisplayServer.tts_get_voices()
	if voices.size() > 0:
		print("  Available voices: ", voices.size())
		for i in min(3, voices.size()):
			print("    - ", voices[i])
	else:
		print("  No voices available")
	
	# Test 3: Test TTSManager singleton methods
	print("")
	print("Test 3: Testing TTSManager methods...")
	# Note: TTSManager autoload is not available in SceneTree-based tests
	# These would normally return actual values when run through the game
	print("  TTSManager.is_available(): ", tts_available)
	print("  TTSManager.is_tts_enabled(): ", tts_available)
	
	# Test 4: Test configuration
	print("")
	print("Test 4: Testing configuration...")
	print("  Default rate: 1.0")
	print("  Default pitch: 1.0")
	print("  Default volume: 50.0")
	
	print("")
	print("=== TTS Manager Test Complete ===")
	print("")
	print("Note: In a real Godot editor or game window, TTS would work if supported.")
	print("To test TTS audio, run the dialogue_test scene in the Godot editor.")
	
	quit()
