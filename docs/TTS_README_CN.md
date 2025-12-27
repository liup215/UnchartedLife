# 对话系统语音支持 (Dialogue System TTS Support)

## 功能说明

已为对话系统添加了文字转语音(TTS)功能，使用Godot内置的语音系统。

## 主要特性

1. **TTSManager 管理器** - 全局单例，管理所有TTS操作
   - 自动检测平台支持
   - 全局启用/禁用开关
   - 可配置语速、音调和音量
   - 暂停/恢复功能
   - 语音选择支持

2. **对话行配置** - 每行对话都可以单独配置TTS
   - `enable_tts` - 启用/禁用此行的TTS
   - `tts_voice_id` - 语音标识符（空字符串使用默认语音）
   - `tts_rate` - 语速（0.1-10.0，默认1.0）
   - `tts_pitch` - 音调（0.0-2.0，默认1.0）
   - `tts_volume` - 音量（0.0-1.0，默认1.0）

3. **对话面板集成** - 自动播放TTS
   - 显示新对话时自动播放语音
   - 玩家跳过时停止语音
   - 对话结束时停止语音

## 使用方法

### 为对话添加语音

1. 打开或创建对话资源文件（.tres）
2. 在 DialogueLineData 中设置：
   - 勾选 `enable_tts` 启用语音
   - 调整 `tts_rate`（语速）、`tts_pitch`（音调）、`tts_volume`（音量）

### 测试语音功能

1. 在Godot编辑器中打开项目
2. 运行 `tests/dialogue_test.tscn` 场景
3. 点击 "Start TTS Demo" 按钮测试语音对话
4. 如果平台支持，您会听到对话文字被朗读出来

## 平台支持

- ✅ Windows（SAPI）
- ✅ macOS（AVSpeechSynthesizer）
- ⚠️ Linux（取决于系统配置）
- ✅ Web（Web Speech API）
- ✅ Android
- ✅ iOS

## 文件清单

- `systems/tts_manager.gd` - TTS管理器
- `data/definitions/dialogue/dialogue_line_data.gd` - 对话行数据（已添加TTS字段）
- `ui/dialogue/dialogue_panel.gd` - 对话面板（已集成TTS）
- `data/dialogue/tts_demo.tres` - 示例TTS对话
- `tests/dialogue_test.gd` - 测试场景脚本
- `docs/TTS_IMPLEMENTATION.md` - 详细技术文档（英文）

## 无障碍功能

此功能特别有益于：
- 视觉障碍玩家
- 阅读困难玩家
- 希望听到对话朗读的玩家

可以根据玩家喜好随时开启或关闭。
