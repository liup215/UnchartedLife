# Active Context: Godot ARPG - Data-Driven Architecture & Directory Update

## Current Focus
- 目录结构已完成梳理与规范化，所有资源、组件、功能模块分层清晰，便于扩展和维护。
- WorldData资源类型已引入，地图区块场景引用已实现数据驱动，消除硬编码路径。
- 组件、数据、功能、原始资源分离，强化高内聚、低耦合。
- 继续推动所有场景、数据、资源引用走数据驱动和Inspector导出变量方式。

## Key Decisions Made
1.  **Embrace "Resource-as-Soul"**: The core design philosophy is now to treat `Resource` files (`.tres`) as the "soul" of an entity, defining what it *is* and how it *behaves*. Scenes (`.tscn`) are now just generic "containers".
2.  **AI as Composable Data**: Instead of hard-coding AI behaviors in scripts, AI behaviors are now `Resource` files (`AIBehaviorData`). An enemy's AI is defined by an array of these resources, which the `Actor` script interprets.
3.  **Centralized Resource Management**: All scene references (especially map chunks via `WorldData`) are managed through Inspector-exported variables or custom Resource types, avoiding hardcoded paths.
4.  **Feature-First Directory Structure**: The project structure prioritizes features (e.g., `features/actor`, `features/vehicle`) over type-based organization, keeping related code together.

## Recent Achievements

### May 2026 Updates
- **UI Theme System (Current Changes)**:
  - Created `ui/themes/biocell_theme.tres` - Custom Godot Theme resource for consistent visual style
  - Added shader-based background effects (`background_pulse.gdshader`) for animated UI backgrounds
  - Applied theme to all major UI scenes: main menu, HUD, system menu, inventory, equipment, character menu, dialogue panel, loading screen, prologue UI, load game menu
  - Theme configured in `project.godot` under `[gui] theme/custom`
  - UI scenes updated with theme-consistent styling: custom button sizes, font colors, spacing, shadows
  - `main_game_manager.gd`: Removed `_unhandled_input()` for ESC key (system menu toggle moved to input handling system)

- **Prologue Scene Improvements**:
  - Microscope focus difficulty tuning: reduced `FOCUS_TOLERANCE` from 0.2 to 0.15, `FINE_ADJUSTMENT` from 0.1 to 0.05
  - Added `snappedf()` for precise fine adjustments aligned to step size
  - Specimen offset now scales inversely with magnification (higher mag = smaller offset range, keeping specimen in view)
  - Visual feedback on distance label: green when focused, yellow when close, white when far
  - Improved target distance randomization ensuring fine adjustment is always required

### December 2025 Updates
- **Text-to-Speech (TTS) for Dialogue System**:
  - TTSManager autoload singleton using Godot's built-in DisplayServer TTS API
  - Per-line TTS configuration (enable_tts, voice_id, rate, pitch, volume)
  - DialoguePanel integration with automatic TTS playback and lifecycle management
  - TTS stops on dialogue skip, end, or interruption
  - Platform detection and graceful degradation
  - Demo dialogue and test infrastructure
  - Comprehensive documentation in English and Chinese (TTS_IMPLEMENTATION.md, TTS_README_CN.md)
  - Accessibility feature for visually impaired and reading-challenged players

- **Complete Save/Load System (PR #2)**:
  - Binary serialization (var_to_bytes/bytes_to_var) supporting all custom data types
  - Full ActorData serialization with Resource path conversion
  - Multi-slot save system with metadata tracking
  - Complete game state persistence (player, vehicle, map chunks, global singletons)
  - MapManager integration with chunk restoration
  - Vehicle state restoration with proper re-entry
  - Corrupted save file error handling
  - Deferred loading pattern for scene-dependent data

- **UI & Menu System Improvements (PR #3)**:
  - Fixed NewGameSettings visibility issue (proper menu container hiding)
  - Enhanced save file error handling with warning messages
  - New game flow: Menu → Settings → Initialize State → Load Scene
  - Continue/Load game flow with proper state restoration
  - Save game from in-game system menu (ESC key)

- **Animation System Fix (PR #4)**:
  - Fixed player walk animation displaying idle frame on first step
  - Root cause: Animation frame_indices started with idle frame (frame 0)
  - Solution: Reordered frame indices to move idle frame to end
  - Added defensive `is_playing()` check in actor animation logic
  - Created animation testing documentation and debug guides

- **Advanced Combat System Implementation**:
  - **Combo Attack System**: Light attacks with 3-stage combo progression (damage, armor break, stagger scaling)
  - **Heavy Charge System**: Hold-to-charge mechanic with 5 charge levels (2.0x to 5.0x damage multipliers)
  - **ChargeComponent**: Universal charge management supporting both hit accumulation and hold-to-charge
  - **ChargeDisplay UI**: Real-time charge level display in bottom-right corner with color-coded feedback
  - **ComboAttackData & HeavyAttackData**: Resource-based attack configuration per weapon
  - **DamageCalculator**: Comprehensive damage calculation considering all combat factors
  - **ToughnessComponent**: Complete toughness/stagger system (韧性/僵直)
  - **Stagger Mechanics**: 2-second duration with input lockout, movement lock, and visual feedback
  - **Weapon-Specific Configs**: Each weapon can have unique combo sequences and charge properties
  - Complete integration with existing combat systems (projectiles, hit detection, visual effects)

- **Map/Level Switching System**:
  - **MapData Resource**: Define maps with chunk scenes, spawn positions, and metadata
  - **Multi-Map Support**: Switch between different maps with automatic chunk loading/unloading
  - **Default Initial Map**: "main_world" configured as default map for new games
  - **Map-Specific Saves**: Current map ID and player position saved/loaded correctly
  - **Vehicle-Map Binding**: Vehicles assigned to specific maps with `assigned_map_id` property
  - **Portal System**: Example portal implementation for map transitions
  - **EventBus Integration**: `map_changed` signal for system notifications
  - Complete documentation in MAP_SYSTEM.md and MAP_SYSTEM_CN.md

### Previous Achievements (Earlier 2025)
- **Map System Refactor**: `MapManager` now loads chunks dynamically using `WorldData` resource. No more hardcoded `res://world/chunk_*.tscn` paths.
- **Inventory System**: Implemented comprehensive inventory management with `InventoryComponent`, `InventoryData` resources, and tabbed UI with item details panel.
- **Equipment System**: Added equipment slots (Weapon/Armor/Gloves/Helmet/Boots) with visual display of equipped items and stats.
- **Dialogue System**: Complete NPC dialogue system with branching choices, conditions, quest integration, and typewriter effect.
- **Quest System**: Hierarchical quest/objective system with runtime state management and event-based tracking.

### June 1, 2026 Session — Runtime Bug Fixes & UX Polish

A focused bug-fixing session resolved multiple startup and runtime errors discovered during playtesting:

1. **Stale Resource UID Fixes**:
   - `ui/loading_screen/loading_screen.tscn` and `scenes/story/opening/opening_animation.tscn` both referenced outdated `uid://b0a3wuusv8qjh` for `icon.svg`
   - Corrected to `uid://df6ywaepewvs1` (matching the current `.import` file)

2. **Save System Stabilization**:
   - Root cause: old `.dat` files (56–1808 bytes) created with a previous Godot version's binary format were incompatible, causing engine-level `ERR_INVALID_DATA` in `bytes_to_var()`
   - `save_manager.gd`: introduced **versioned binary format** `[version: u32][payload_len: u32][payload_bytes]` with `SAVE_VERSION = 1`
   - Added `MIN_SAVE_SIZE` guard and shared `_read_save_payload()` helper that auto-detects legacy format
   - Deleted all corrupted old save files from `%APPDATA%\Godot\app_userdata\UnchartedLife\saves\`

3. **Scene Export / Assignment Fixes**:
   - `inventory_ui.tscn`: added missing `@export` assign for `item_slot_scene` (`ui/system_menu/item_slot.tscn`)
   - `prologue_scene_02.tscn`: added missing `@export` assign for `molecule_scene` (`features/interactive/molecule/molecule.tscn`)
   - `game_scene.tscn`: removed static `game_scene_data = ExtResource("2_default_data")` assignment (empty resource caused false-positive warning)

4. **MapManager Cleanup**:
   - `game_scene.gd`: downgraded `push_warning` to `GameLogger.debug` when `game_scene_data` is null (normal during placeholder instantiation)
   - `map_manager.gd`: silenced `printerr("map_parent not set")` in `update_chunks` — it's expected during scene transitions
   - `main_game_manager.gd`: added `is_instance_valid(game_scene)` guard in `_physics_process` to avoid calling `update_chunks` while transitioning

5. **Combat System Repair**:
   - `attribute_component.gd`: added `get_current_atp()` and `consume_atp()` delegates to `MetabolismComponent`
   - This fixed `Invalid call. Nonexistent function 'get_current_atp'` in `actor_combat_component.gd` during light/heavy attacks

6. **Out-of-Ammo UX Improvement**:
   - `weapon_component.gd`: replaced backend `GameLogger.warn` with `EventBus.weapon_out_of_ammo.emit(item_data)`
   - `event_bus.gd`: added new `weapon_out_of_ammo(item_data: ItemData)` signal
   - `hud.gd`: added `_show_notification()` overlay label for on-screen feedback (bottom-center, 2s duration)

### June 1, 2026 Session — Input System Fix & Combat Feedback UI

1. **Player Attack/Dodge Input Fix (Root Cause: consume_transient_intents)**:
   - `player.gd`: `consume_transient_intents()` was being called at the top of `_physics_process()`, immediately clearing all one-shot input flags (`should_dodge`, `should_light_attack`, `should_heavy_attack`, `heavy_attack_released`)
   - This caused attack and dodge to never register when keys were pressed, while movement worked fine (because `desired_direction` is a continuous state, not a one-shot flag)
   - **Fix**: Moved `consume_transient_intents()` to the END of `_handle_on_foot_logic()`, after `_handle_combat_input()` and all input processing

2. **Combat Action Failure UI Feedback System**:
   - **EventBus Signals**: Added `combat_action_failed(action: String, reason: String)` signal to `EventBus`, `CombatBus`, and `UIEventBus` for generic combat failure notifications
   - **HUD Notification Queue**: Upgraded `_show_notification()` from a single direct-display to a queue-based system with fade in/out tween animations, preventing message overwriting when multiple events occur simultaneously
   - **Dodge Failures**: Connected `EventBus.player_dodge_failed` → HUD, showing user-friendly messages ("Dodge failed: Not enough ATP!", "Dodge on cooldown!", "Dodge in progress!")
   - **Light/Heavy Attack Failures**: Modified `actor_combat_component.gd` to emit `EventBus.combat_action_failed.emit("light_attack", "Not enough ATP")` and `EventBus.combat_action_failed.emit("heavy_attack", "Not enough ATP")`
   - **HUD Handler**: Added `_on_combat_action_failed()` in `hud.gd` mapping action names to localized display names ("Light Attack", "Heavy Attack")

3. **Cleaned `.godot` cache**: Deleted and regenerated the entire `.godot` uid_cache folder to fix invalid UID references (base_actor.tscn not in cache).

## Next Steps
- **BioBlitz Enhancement:**
  - Expand question bank with diverse biology topics
  - Add different question types (multiple choice, fill-in-blank, matching)
  - Implement difficulty progression
  - Add hints system tied to ATP cost

- **Biology Content Integration:**
  - Create educational tooltips for all biological systems
  - Design biology-themed enemies (viruses, bacteria, mutated cells)
  - Build ecology restoration mini-game
  - Implement genetic modification lab interface

- **Vehicle Bionic Modifications:**
  - Create bionic modification system based on animal adaptations
  - Each modification teaches evolutionary biology concepts
  - Visual representation of modifications on vehicle

- **Combat System Polish:**
  - Balance combo progression and charge levels
  - Tune toughness/stagger mechanics
  - Add more visual effects for combat feedback
  - Create weapon-specific combo animations
  - Implement elemental damage type effectiveness

- **Map & Level Design:**
  - Create additional maps with distinct biomes
  - Design portal/transition systems between maps
  - Add map-specific enemies and challenges
  - Implement minimap and map discovery system

- **Performance & Polish:**
  - Profile combat system performance
  - Optimize damage calculation for large battles
  - Add audio feedback for combat actions
  - Improve visual effects and screen shake
