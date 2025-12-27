# Text-to-Speech System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     TTS Implementation Flow                      │
└─────────────────────────────────────────────────────────────────┘

1. Dialogue Content Creation
   ┌──────────────────────────────┐
   │   DialogueLineData (.tres)   │
   │  ─────────────────────────   │
   │  text: "Welcome!"            │
   │  enable_tts: true            │
   │  tts_rate: 1.0               │
   │  tts_pitch: 1.0              │
   │  tts_volume: 0.8             │
   └──────────────┬───────────────┘
                  │
                  ↓
2. Dialogue Manager
   ┌──────────────────────────────┐
   │     DialogueManager.gd       │
   │  ──────────────────────────  │
   │  start_dialogue()            │
   │  _emit_next_line()           │
   └──────────────┬───────────────┘
                  │
                  │ EventBus.dialogue_line
                  ↓
3. Dialogue Panel (UI)
   ┌──────────────────────────────┐
   │     DialoguePanel.gd         │
   │  ──────────────────────────  │
   │  _on_dialogue_line()         │
   │  _play_tts_for_line()        │
   └──────────────┬───────────────┘
                  │
                  │ Check: enable_tts?
                  ↓
4. TTS Manager (Autoload)
   ┌──────────────────────────────┐
   │      TTSManager.gd           │
   │  ──────────────────────────  │
   │  speak(text, voice,          │
   │        rate, pitch, volume)  │
   └──────────────┬───────────────┘
                  │
                  ↓
5. Godot Engine
   ┌──────────────────────────────┐
   │    DisplayServer TTS API     │
   │  ──────────────────────────  │
   │  tts_speak()                 │
   │  tts_stop()                  │
   │  tts_is_speaking()           │
   └──────────────┬───────────────┘
                  │
                  ↓
6. System TTS Engine
   ┌──────────────────────────────┐
   │  Platform Native TTS         │
   │  ──────────────────────────  │
   │  Windows: SAPI               │
   │  macOS: AVSpeechSynthesizer  │
   │  Linux: espeak/speech-d      │
   │  Web: Web Speech API         │
   └──────────────┬───────────────┘
                  │
                  ↓
              🔊 Audio Output


┌─────────────────────────────────────────────────────────────────┐
│                  Component Relationships                         │
└─────────────────────────────────────────────────────────────────┘

DialogueLineData (Resource)
    ↓ loaded by
DialogueData (Resource)
    ↓ registered with
DialogueManager (Autoload)
    ↓ emits signals to
DialoguePanel (UI CanvasLayer)
    ↓ calls
TTSManager (Autoload)
    ↓ uses
DisplayServer TTS API (Godot Engine)
    ↓ calls
System TTS Engine (OS)


┌─────────────────────────────────────────────────────────────────┐
│                     TTS Control Flow                             │
└─────────────────────────────────────────────────────────────────┘

Start Dialogue
    ↓
Display Line → Play TTS (if enabled)
    ↓
Player Actions:
    ├─ Skip (ui_accept) → Stop TTS, show full text
    ├─ Cancel (ui_cancel) → Stop TTS, end dialogue
    └─ Wait → Continue TTS until finished
    ↓
Next Line → Stop previous TTS, play new TTS
    ↓
Show Choices → Stop TTS
    ↓
End Dialogue → Stop TTS, hide panel


┌─────────────────────────────────────────────────────────────────┐
│                    Configuration Options                         │
└─────────────────────────────────────────────────────────────────┘

Global Level (DialoguePanel):
  enable_tts: bool (default: true)
  └─ Affects all dialogues

Per-Line Level (DialogueLineData):
  enable_tts: bool (default: false)
  tts_voice_id: String (default: "" = system default)
  tts_rate: float (0.1-10.0, default: 1.0)
  tts_pitch: float (0.0-2.0, default: 1.0)
  tts_volume: float (0.0-1.0, default: 1.0)

Manager Level (TTSManager):
  tts_enabled: bool (default: true)
  global_tts_rate: float (default: 1.0)
  global_tts_pitch: float (default: 1.0)
  global_tts_volume: float (0-100, default: 50.0)


┌─────────────────────────────────────────────────────────────────┐
│                      File Structure                              │
└─────────────────────────────────────────────────────────────────┘

UnchartedLife/
├── systems/
│   └── tts_manager.gd              ← TTS autoload singleton
├── data/
│   ├── definitions/dialogue/
│   │   └── dialogue_line_data.gd   ← Extended with TTS fields
│   └── dialogue/
│       └── tts_demo.tres            ← Demo TTS dialogue
├── ui/dialogue/
│   └── dialogue_panel.gd            ← TTS integration
├── tests/
│   ├── dialogue_test.gd             ← Updated with TTS button
│   ├── dialogue_test.tscn           ← Test scene
│   └── test_tts.gd                  ← TTS verification script
└── docs/
    ├── TTS_IMPLEMENTATION.md        ← Technical documentation (EN)
    └── TTS_README_CN.md             ← User guide (中文)


┌─────────────────────────────────────────────────────────────────┐
│                   Platform Support Matrix                        │
└─────────────────────────────────────────────────────────────────┘

Platform    | Status | TTS Engine
─────────────────────────────────────────────────────────────
Windows     | ✅ Yes | SAPI (Speech API)
macOS       | ✅ Yes | AVSpeechSynthesizer
Linux       | ⚠️ Varies | espeak, speech-dispatcher
Web         | ✅ Yes | Web Speech API
Android     | ✅ Yes | Android TTS
iOS         | ✅ Yes | AVSpeechSynthesizer
```
