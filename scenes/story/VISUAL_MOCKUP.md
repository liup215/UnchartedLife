# Visual Mockup of Story Scenes

## Opening Animation Scene

### Initial State (0-1 seconds)
```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║                                                            ║
║                                                            ║
║                                                            ║
║                         [Black]                            ║
║                                                            ║
║                                                            ║
║                                                            ║
║                                                            ║
║                                                            ║
║                                                            ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

### Mid Animation (2-6 seconds)
```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║                          ┌─────┐                           ║
║                          │     │                           ║
║                          │ 🧫  │  ← Petri dish/cell icon  ║
║                          │     │     (300x300 px)          ║
║                          └─────┘                           ║
║                                                            ║
║          Help the cells in the petri dish survive          ║
║                                                            ║
║          Press any key to continue                         ║
║                                          [Skip >>]         ║
╚════════════════════════════════════════════════════════════╝
         [Dark blue/purple background with gradual fade]
```

### Animation Details
- **Duration**: 8 seconds total
- **0-1s**: Fade from black
- **1-2s**: Background fades to dark blue/purple
- **2s**: Center image fades in
- **2.5s**: Description text fades in
- **3s**: Prompt text fades in
- **6-8s**: All elements fade out to black
- **Skip Button**: Always visible in bottom-right corner
- **User Input**: ESC, any key, or Skip button → immediate transition

### Content
- **Image**: Game icon (icon.svg) displayed at 300x300px in center
- **Description**: "Help the cells in the petri dish survive"
- **Prompt**: "Press any key to continue"
- **Theme**: Petri dish and cellular biology survival game

---

## Prologue Scene 01

### Top View Layout
```
╔════════════════════════════════════════════════════════════╗
║  Welcome to Legends of Uncharted Life!                    ║
║                                                            ║
║  Use WASD to move                                          ║
║  Press E to interact                                       ║
║  Press Esc for menu                                        ║
║                                                            ║
║                                                            ║
║              [@]  ← Player (spawns here at 200,200)        ║
║                                                            ║
║                                                            ║
║             [Green Ground - 2000x2000 units]               ║
║                                                            ║
║                                                            ║
║                                                            ║
║                      Continue to Game → [█] Exit Area      ║
║                                        (at 800,400)        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

### Player View (What player sees with camera)
```
┌──────────────── HUD ────────────────┐
│ HP: ████████░░  ATP: ██████░░░░     │  ← Top HUD Bar
│ Glucose: ████████████████░░░         │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│    Welcome to Legends of              │
│       Uncharted Life!                 │
│                                       │
│    Use WASD to move                   │  ← Instruction Labels
│    Press E to interact                │
│    Press Esc for menu                 │
│                                       │
│                                       │
│           [@]  ← You are here         │  ← Player character
│                                       │
│    [Green ground continues...]        │
│                                       │
│                                       │
│                                       │
│              ↓ ↓ ↓                    │
│      [Continue to Game →]             │  ← Exit marker
│          [█████]                      │     (Green highlight)
└──────────────────────────────────────┘
        Camera follows player smoothly
```

### Scene Elements
1. **Player**: Spawns at center-left (200, 200)
2. **Ground**: Green rectangle covering 2000x2000 area
3. **Welcome Text**: Large label at top
4. **Instructions**: Medium label below welcome
5. **Exit Area**: Green semi-transparent area at (800, 400)
6. **Camera**: Follows player with zoom 1.5x, smooth motion
7. **HUD**: Shows player stats (HP, ATP, Glucose)

### Interaction Flow
```
Player Movement:
┌─────────────┐
│  [@] Start  │  Use WASD to move
│             │
│             │  Move right →
│      [@]    │
│             │
│             │  Continue right →
│         [@] │
│             │
│             │  Enter green area →
│      [███[@]│  ← Triggers transition
└─────────────┘

Transition:
[Exit Area Entered]
       ↓
[Load main.tscn]
       ↓
[Main Game Starts]
```

---

## Camera Behavior

### Opening Animation
```
Static Camera - Full Screen
┌────────────────────┐
│                    │
│   Fixed Position   │  No movement
│   Full UI Control  │  Mouse visible
│                    │
└────────────────────┘
```

### Prologue Scene
```
Following Camera - Zoomed 1.5x
┌────────────────────┐
│     [@] Player     │  Camera center follows
│                    │  Smooth interpolation
│  Visible radius:   │  Speed: 8.0
│   ~600x400 units   │  
└────────────────────┘
```

---

## Color Scheme

### Opening Animation
- Background: Dark (0.1, 0.1, 0.15) → (0.2, 0.2, 0.3) → Black
- Title Text: White (1, 1, 1) with alpha fade
- Subtitle Text: White (1, 1, 1) with alpha fade
- Skip Button: Default theme

### Prologue Scene
- Ground: Green (0.2, 0.3, 0.2) - represents grass/nature
- Welcome Text: White, size 24
- Instructions: White, size 16
- Exit Area: Green (0, 1, 0) with alpha 0.3 (semi-transparent)
- Exit Label: White, size 18

---

## User Experience Flow

```
New Game Button Pressed
        ↓
Game Settings Dialog
        ↓
Start Game Button Pressed
        ↓
╔═══════════════════════════════════╗
║  Opening Animation (8 seconds)    ║
║  - Can skip with button or ESC    ║
║  - Shows title with fade effects  ║
║  - Automatic transition           ║
╚═══════════════════════════════════╝
        ↓
╔═══════════════════════════════════╗
║  Prologue Scene 01                ║
║  - Player spawns at start point   ║
║  - Can move freely with WASD      ║
║  - See instructions on screen     ║
║  - Move to green exit area        ║
╚═══════════════════════════════════╝
        ↓
╔═══════════════════════════════════╗
║  Main Game Scene                  ║
║  - Full game experience begins    ║
║  - All systems active             ║
║  - Can save/load game             ║
╚═══════════════════════════════════╝
```

---

## Technical Notes

### Opening Animation Assets
- Background: ColorRect (dark blue gradient)
- Title: Label (48pt font)
- Subtitle: Label (24pt font)
- Skip Button: Button (100x30 pixels)
- Animation: AnimationPlayer with 3 animated tracks

### Prologue Assets
- Ground: ColorRect (2000x2000)
- Player: Instance of player.tscn
- Spawn Point: Marker2D
- Exit Area: Area2D with CollisionShape2D
- Labels: Multiple Label nodes
- HUD: Instance of hud.tscn
- Dialogue: Instance of dialogue_panel.tscn

### Performance Considerations
- Opening Animation: Very lightweight (UI only, no physics)
- Prologue Scene: Light (1 player, simple environment)
- Estimated Load Time: < 1 second on modern hardware
- Memory Usage: Minimal (< 50MB additional)
