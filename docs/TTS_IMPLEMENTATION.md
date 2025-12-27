# Text-to-Speech (TTS) Implementation for Dialogue System

## Overview
This document describes the text-to-speech feature implementation for the dialogue system in Uncharted Life.

## Components

### 1. TTSManager (systems/tts_manager.gd)
A global autoload singleton that manages all TTS operations using Godot's built-in DisplayServer TTS functionality.

**Key Features:**
- Platform compatibility checking
- Global TTS enable/disable toggle
- Configurable speech rate, pitch, and volume
- Pause/resume support
- Voice selection support
- Signals for TTS lifecycle events (started, finished, cancelled)

**Main Methods:**
- `speak(text, voice_id, rate, pitch, volume, interrupt)` - Speaks the given text
- `stop()` - Stops current TTS playback
- `pause()` / `resume()` - Pause and resume playback
- `is_speaking()` - Check if TTS is currently active
- `get_available_voices()` - Get list of available system voices
- `is_available()` - Check if TTS is supported on current platform

### 2. DialogueLineData Extensions (data/definitions/dialogue/dialogue_line_data.gd)
Added TTS configuration fields to DialogueLineData resource:

- `enable_tts: bool` - Enable/disable TTS for this line
- `tts_voice_id: String` - Voice identifier (empty uses default)
- `tts_rate: float` - Speech speed (0.1-10.0, default 1.0)
- `tts_pitch: float` - Voice pitch (0.0-2.0, default 1.0)
- `tts_volume: float` - Volume (0.0-1.0, default 1.0)

### 3. DialoguePanel Integration (ui/dialogue/dialogue_panel.gd)
Integrated TTS into the dialogue UI system:

**Features:**
- Global TTS toggle (`enable_tts` export variable)
- Automatic TTS playback when dialogue lines are displayed
- TTS stops when:
  - Player skips typing animation
  - Dialogue choices are presented
  - Dialogue ends or is interrupted
  - New dialogue line starts

**New Methods:**
- `_play_tts_for_line(line)` - Plays TTS for a dialogue line
- `_stop_tts()` - Stops any active TTS

## Usage

### For Content Creators

#### Creating TTS-Enabled Dialogue
1. Open or create a DialogueData resource (.tres file)
2. For each DialogueLineData in the dialogue:
   - Set `enable_tts` to `true`
   - (Optional) Configure `tts_voice_id` for specific voice
   - (Optional) Adjust `tts_rate` (1.0 = normal speed, 2.0 = 2x speed)
   - (Optional) Adjust `tts_pitch` (1.0 = normal pitch)
   - (Optional) Adjust `tts_volume` (1.0 = full volume)

Example dialogue resource configuration:
```gdscript
[sub_resource type="Resource" id="Resource_line1"]
script = ExtResource("2")
speaker_name = "Dr. Cell"
text = "Welcome to the world of biology!"
enable_tts = true
tts_voice_id = ""  # Empty = default voice
tts_rate = 1.0
tts_pitch = 1.0
tts_volume = 0.8
```

#### Global TTS Control
In the DialoguePanel scene, you can:
- Enable/disable TTS globally via the `enable_tts` export variable
- This allows you to turn off TTS for testing or accessibility purposes

### For Programmers

#### Accessing TTSManager
```gdscript
# Check if TTS is available
if TTSManager.is_available():
    # Speak some text
    TTSManager.speak("Hello, world!")

# Speak with custom settings
TTSManager.speak(
    "Hello, world!",
    "",        # voice_id (empty = default)
    1.5,       # rate (1.5x speed)
    1.2,       # pitch (higher pitch)
    80.0,      # volume (0-100)
    true       # interrupt previous speech
)

# Stop speaking
TTSManager.stop()

# Check if currently speaking
if TTSManager.is_speaking():
    print("TTS is active")

# Get available voices
var voices = TTSManager.get_available_voices()
for voice in voices:
    print("Available voice: ", voice)
```

#### Connecting to TTS Signals
```gdscript
func _ready():
    TTSManager.tts_started.connect(_on_tts_started)
    TTSManager.tts_finished.connect(_on_tts_finished)
    TTSManager.tts_cancelled.connect(_on_tts_cancelled)

func _on_tts_started():
    print("TTS started speaking")

func _on_tts_finished():
    print("TTS finished speaking")

func _on_tts_cancelled():
    print("TTS was cancelled")
```

## Testing

### Manual Testing in Godot Editor
1. Open the project in Godot Editor
2. Run the `tests/dialogue_test.tscn` scene
3. Click "Start TTS Demo" button to test TTS-enabled dialogue
4. You should hear the dialogue text spoken aloud (if TTS is supported on your platform)

### Test Files
- `tests/dialogue_test.gd` - Updated with TTS demo button
- `tests/test_tts.gd` - Standalone TTS verification script
- `data/dialogue/tts_demo.tres` - Sample dialogue with TTS enabled

### Platform Support
TTS support varies by platform:
- **Windows**: ✅ Supported (SAPI)
- **macOS**: ✅ Supported (AVSpeechSynthesizer)
- **Linux**: ⚠️ Varies (espeak, speech-dispatcher)
- **Web**: ✅ Supported (Web Speech API)
- **Android**: ✅ Supported (Android TTS)
- **iOS**: ✅ Supported (AVSpeechSynthesizer)

## Accessibility Benefits
- Players with visual impairments can hear dialogue read aloud
- Helpful for players with reading difficulties (dyslexia, etc.)
- Provides an alternative way to experience the game's narrative
- Can be toggled on/off based on player preference

## Future Enhancements
Possible improvements for future iterations:
1. Voice presets for different character types (deep voice, high voice, etc.)
2. Per-character voice mapping (each NPC has their own voice)
3. Subtitle highlighting synchronized with TTS
4. TTS speed control in game settings menu
5. Save TTS preferences in player settings
6. Support for SSML (Speech Synthesis Markup Language) for advanced control
7. TTS for UI elements (buttons, menus, etc.)

## Technical Notes
- TTS uses Godot's DisplayServer API, which is platform-native
- Volume is converted from 0.0-1.0 range to 0-100 for DisplayServer
- TTS is automatically stopped when dialogue advances to prevent overlap
- The system gracefully degrades on platforms without TTS support
- No external dependencies required - uses built-in Godot functionality
