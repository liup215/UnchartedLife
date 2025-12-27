# TTS 使用示例 / TTS Usage Examples

## 示例 1: 基础对话 / Example 1: Basic Dialogue

```gdscript
# 在对话资源文件中 / In dialogue resource file (.tres)

[sub_resource type="Resource" id="line1"]
script = ExtResource("DialogueLineData")
speaker_name = "博士 / Dr. Cell"
text = "欢迎来到生物世界！/ Welcome to the world of biology!"
enable_tts = true          # 启用TTS / Enable TTS
tts_voice_id = ""          # 使用默认语音 / Use default voice
tts_rate = 1.0             # 正常语速 / Normal speed
tts_pitch = 1.0            # 正常音调 / Normal pitch
tts_volume = 0.8           # 80%音量 / 80% volume
```

## 示例 2: 不同角色不同语音设置 / Example 2: Different Settings for Different Characters

```gdscript
# 年轻角色 - 快速、高音调 / Young character - Fast, high pitch
[sub_resource type="Resource" id="young_character"]
script = ExtResource("DialogueLineData")
speaker_name = "小明 / Xiao Ming"
text = "我对细胞生物学非常感兴趣！/ I'm very interested in cell biology!"
enable_tts = true
tts_rate = 1.3             # 快速 / Fast
tts_pitch = 1.2            # 高音调 / High pitch
tts_volume = 0.9           # 响亮 / Loud

# 老年角色 - 慢速、低音调 / Elderly character - Slow, low pitch
[sub_resource type="Resource" id="elderly_character"]
script = ExtResource("DialogueLineData")
speaker_name = "李教授 / Professor Li"
text = "让我慢慢给你解释这个概念。/ Let me explain this concept slowly."
enable_tts = true
tts_rate = 0.8             # 慢速 / Slow
tts_pitch = 0.9            # 低音调 / Low pitch
tts_volume = 0.7           # 较轻 / Softer
```

## 示例 3: 程序化控制 / Example 3: Programmatic Control

```gdscript
# 在脚本中使用TTSManager / Using TTSManager in scripts

extends Node

func _ready():
    # 检查TTS是否可用 / Check if TTS is available
    if TTSManager.is_available():
        print("TTS is supported!")
    
    # 播放简单文本 / Speak simple text
    TTSManager.speak("你好，世界！/ Hello, world!")
    
    # 使用自定义设置 / Speak with custom settings
    TTSManager.speak(
        "这是一个测试。/ This is a test.",
        "",      # voice_id (空=默认 / empty=default)
        1.5,     # rate (1.5倍速 / 1.5x speed)
        1.1,     # pitch (稍高 / slightly higher)
        70.0,    # volume (70% / 70%)
        true     # interrupt (打断之前的语音 / interrupt previous)
    )
    
    # 停止当前语音 / Stop current speech
    TTSManager.stop()
    
    # 暂停和恢复 / Pause and resume
    TTSManager.pause()
    await get_tree().create_timer(2.0).timeout
    TTSManager.resume()

func _on_dialogue_started():
    # 对话开始时的自定义逻辑 / Custom logic on dialogue start
    if TTSManager.is_speaking():
        TTSManager.stop()
```

## 示例 4: 获取可用语音 / Example 4: Get Available Voices

```gdscript
extends Control

@onready var voice_list: OptionButton = $VoiceList

func _ready():
    # 填充语音列表 / Populate voice list
    var voices = TTSManager.get_available_voices()
    for voice in voices:
        voice_list.add_item(voice)
    
    # 连接选择信号 / Connect selection signal
    voice_list.item_selected.connect(_on_voice_selected)

func _on_voice_selected(index: int):
    var voice_id = voice_list.get_item_text(index)
    # 使用选定的语音测试 / Test with selected voice
    TTSManager.speak("测试语音 / Testing voice", voice_id)
```

## 示例 5: 对话面板TTS控制 / Example 5: DialoguePanel TTS Control

```gdscript
# 在DialoguePanel场景中 / In DialoguePanel scene

extends CanvasLayer

@export var enable_tts: bool = true  # 全局TTS开关 / Global TTS toggle

func _ready():
    # 连接信号 / Connect signals
    EventBus.dialogue_line.connect(_on_dialogue_line)
    
    # 从设置中加载TTS偏好 / Load TTS preference from settings
    if SaveManager.has_setting("enable_tts"):
        enable_tts = SaveManager.get_setting("enable_tts")

func _on_dialogue_line(line: DialogueLineData, _index: int, _total: int, _npc_id: String):
    # 显示对话文本 / Display dialogue text
    display_text(line)
    
    # 如果启用，播放TTS / Play TTS if enabled
    if enable_tts and line.enable_tts:
        var text = line.resolve_text()
        TTSManager.speak(
            text,
            line.tts_voice_id,
            line.tts_rate,
            line.tts_pitch,
            line.tts_volume * 100.0,  # 转换为0-100范围 / Convert to 0-100 range
            true
        )

func toggle_tts(enabled: bool):
    # 切换TTS / Toggle TTS
    enable_tts = enabled
    SaveManager.set_setting("enable_tts", enabled)
    if not enabled:
        TTSManager.stop()
```

## 示例 6: 完整的TTS设置面板 / Example 6: Complete TTS Settings Panel

```gdscript
extends Control

@onready var tts_enabled_check: CheckBox = $VBoxContainer/EnabledCheck
@onready var rate_slider: HSlider = $VBoxContainer/RateSlider
@onready var pitch_slider: HSlider = $VBoxContainer/PitchSlider
@onready var volume_slider: HSlider = $VBoxContainer/VolumeSlider
@onready var test_button: Button = $VBoxContainer/TestButton

func _ready():
    # 加载设置 / Load settings
    tts_enabled_check.button_pressed = TTSManager.is_tts_enabled()
    rate_slider.value = TTSManager.global_tts_rate
    pitch_slider.value = TTSManager.global_tts_pitch
    volume_slider.value = TTSManager.global_tts_volume
    
    # 连接信号 / Connect signals
    tts_enabled_check.toggled.connect(_on_tts_toggled)
    rate_slider.value_changed.connect(_on_rate_changed)
    pitch_slider.value_changed.connect(_on_pitch_changed)
    volume_slider.value_changed.connect(_on_volume_changed)
    test_button.pressed.connect(_on_test_pressed)

func _on_tts_toggled(enabled: bool):
    TTSManager.set_tts_enabled(enabled)

func _on_rate_changed(value: float):
    TTSManager.global_tts_rate = value

func _on_pitch_changed(value: float):
    TTSManager.global_tts_pitch = value

func _on_volume_changed(value: float):
    TTSManager.global_tts_volume = value

func _on_test_pressed():
    TTSManager.speak(
        "这是TTS测试。语速、音调和音量已调整。/ This is a TTS test. Rate, pitch and volume adjusted.",
        "",
        TTSManager.global_tts_rate,
        TTSManager.global_tts_pitch,
        TTSManager.global_tts_volume,
        true
    )
```

## 常见问题 / Common Issues

### Q1: TTS 在我的平台上不工作 / TTS not working on my platform
```gdscript
# 检查平台支持 / Check platform support
if not TTSManager.is_available():
    print("TTS不支持此平台 / TTS not supported on this platform")
    # 使用替代方案（如字幕） / Use alternative (like subtitles)
```

### Q2: 如何等待TTS完成？ / How to wait for TTS to finish?
```gdscript
# 连接完成信号 / Connect to finished signal
TTSManager.tts_finished.connect(_on_tts_finished)

func speak_and_wait(text: String):
    TTSManager.speak(text)
    await TTSManager.tts_finished

func _on_tts_finished():
    print("TTS已完成 / TTS finished")
```

### Q3: 如何为每个NPC使用不同的语音？ / How to use different voices for each NPC?
```gdscript
# 在ActorData或NPCData中添加语音ID / Add voice_id to ActorData or NPCData
class_name NPCData extends Resource

@export var npc_id: String
@export var npc_name: String
@export var tts_voice_id: String = ""  # 语音ID / Voice ID
@export var tts_rate: float = 1.0
@export var tts_pitch: float = 1.0

# 在创建对话行时使用NPC设置 / Use NPC settings when creating dialogue lines
func create_dialogue_line(npc: NPCData, text: String) -> DialogueLineData:
    var line = DialogueLineData.new()
    line.speaker_name = npc.npc_name
    line.text = text
    line.enable_tts = true
    line.tts_voice_id = npc.tts_voice_id
    line.tts_rate = npc.tts_rate
    line.tts_pitch = npc.tts_pitch
    return line
```

## 性能提示 / Performance Tips

1. **不要在每帧调用 / Don't call every frame**
   ```gdscript
   # 错误 / Wrong
   func _process(_delta):
       TTSManager.speak("每帧都说 / Speaking every frame")  # ❌
   
   # 正确 / Correct
   func _ready():
       TTSManager.speak("只说一次 / Speak once")  # ✅
   ```

2. **使用打断模式避免重叠 / Use interrupt to avoid overlap**
   ```gdscript
   # 打断之前的语音 / Interrupt previous speech
   TTSManager.speak("新文本 / New text", "", -1, -1, -1, true)  # ✅
   ```

3. **检查是否正在播放 / Check if speaking**
   ```gdscript
   if not TTSManager.is_speaking():
       TTSManager.speak("新消息 / New message")
   ```

## 调试技巧 / Debugging Tips

```gdscript
# 启用TTS调试日志 / Enable TTS debug logging
func _ready():
    TTSManager.tts_started.connect(func(): print("TTS开始 / TTS started"))
    TTSManager.tts_finished.connect(func(): print("TTS完成 / TTS finished"))
    TTSManager.tts_cancelled.connect(func(): print("TTS取消 / TTS cancelled"))
    
    # 打印可用语音 / Print available voices
    print("可用语音 / Available voices:", TTSManager.get_available_voices())
    
    # 检查平台支持 / Check platform support
    print("TTS支持 / TTS supported:", TTSManager.is_available())
```
