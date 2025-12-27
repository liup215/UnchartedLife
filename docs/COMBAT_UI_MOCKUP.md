# Combat System UI Mockup

## Screen Layout (1920x1080)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Uncharted Life - Gameplay                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ╔═══════════════╗                                                          │
│  ║ Player Info   ║                                                          │
│  ║               ║                                                          │
│  ║ Liup215       ║                                                          │
│  ║ HP: ████░░ 80 ║                                                          │
│  ║ ATP: ███░░░ 60║                                                          │
│  ║ Glucose: 450  ║                                                          │
│  ╚═══════════════╝                                                          │
│                                                                             │
│                                                                             │
│                        [Player Character]                                   │
│                              @                                              │
│                                                                             │
│                                                                             │
│                   [Enemy]              [Enemy]                              │
│                     👾                   👾                                 │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                ┌──────────────────────────┐ │
│                                                │      ⚡ Charge ⚡        │ │
│                                                │                          │ │
│                                                │  ████████████████░░░░░   │ │
│                                                │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░   │ │
│                                                │                          │ │
│                                                │    Level 4 / 5           │ │
│                                                └──────────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Charge Display States

### Level 0 - No Charge
```
┌──────────────────────────┐
│      ⚡ Charge ⚡        │
│                          │
│  ░░░░░░░░░░░░░░░░░░░░░   │ (Gray/Empty)
│  ░░░░░░░░░░░░░░░░░░░░░   │
│                          │
│    Level 0 / 5           │
└──────────────────────────┘
```

### Level 1-2 - Low Charge (White)
```
┌──────────────────────────┐
│      ⚡ Charge ⚡        │
│                          │
│  ████░░░░░░░░░░░░░░░░░   │ (White)
│  ▓▓▓▓░░░░░░░░░░░░░░░░░   │
│                          │
│    Level 2 / 5           │
└──────────────────────────┘
```

### Level 3 - Medium Charge (Yellow)
```
┌──────────────────────────┐
│      ⚡ Charge ⚡        │
│                          │
│  ████████████░░░░░░░░░   │ (Yellow)
│  ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░   │
│                          │
│    Level 3 / 5           │
└──────────────────────────┘
```

### Level 4 - High Charge (Orange)
```
┌──────────────────────────┐
│      ⚡ Charge ⚡        │
│                          │
│  ████████████████░░░░░   │ (Orange)
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░   │
│                          │
│    Level 4 / 5           │
└──────────────────────────┘
```

### Level 5 - Max Charge (Red + Flash)
```
┌──────────────────────────┐
│      ⚡ Charge ⚡        │
│                          │
│  █████████████████████   │ (Red - Flashing)
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   │
│                          │
│    Level 5 / 5  ⚡⚡     │
└──────────────────────────┘
```

## Combat Flow Visualization

### Light Attack Combo

```
Attack 1 (Stage 0)         Attack 2 (Stage 1)         Attack 3 (Stage 2)
     ↓                            ↓                            ↓
┌─────────┐                ┌─────────┐                ┌─────────┐
│  SLASH  │                │ DOUBLE  │                │ FINISH  │
│    ⚔️   │    Hit Enemy   │ SLASH   │    Hit Enemy   │  SLASH  │
│         │  ─────────→    │   ⚔️⚔️  │  ─────────→    │  ⚔️💥   │
│ DMG: 1x │      +1        │ DMG: 1.3x│      +1        │ DMG: 1.8x│
│ Charge +│   Charge       │ Charge +│   Charge       │ Charge +│
└─────────┘                └─────────┘                └─────────┘
     │                           │                           │
     ▼                           ▼                           ▼
Charge: █░░░░             Charge: ██░░░             Charge: ████░
Level 1/5                 Level 2/5                 Level 4/5
```

### Heavy Attack Charge & Release

```
Press & Hold Right Mouse Button
          ↓
    ┌──────────┐
    │ CHARGING │
    │    ⚡    │
    └──────────┘
          │
    Time passes...
          │
    ┌──────────────────────────────────┐
    │ Charge Bar Filling                │
    │                                   │
    │ 0.0s: ░░░░░░░░░░ Level 0          │
    │ 0.5s: ████░░░░░░ Level 1          │
    │ 1.0s: ████████░░ Level 2          │
    │ 1.5s: ████████████ Level 3        │
    │ 2.0s: ████████████████ Level 4    │
    │ 2.5s: ██████████████████ Level 5  │
    └──────────────────────────────────┘
          │
    Release Button
          ↓
    ┌──────────┐
    │  HEAVY   │
    │  ATTACK  │
    │   💥⚡💥  │
    │ DMG: 5x  │
    │ Charge   │
    │ Released │
    └──────────┘
          │
          ▼
    Charge: ░░░░░
    Level 0/5
```

## Combat Stats Comparison

### Light Attack Progression
```
Stage 0:  ⚔️      Damage: 1.0x   Armor Break: 10   Stagger: 15
Stage 1:  ⚔️⚔️    Damage: 1.3x   Armor Break: 20   Stagger: 25
Stage 2:  ⚔️💥    Damage: 1.8x   Armor Break: 40   Stagger: 50
```

### Heavy Attack Scaling
```
Level 1:  💥      Damage: 2.0x   Armor Break: 50   Stagger: 75
Level 3:  💥💥    Damage: 3.5x   Armor Break: 75   Stagger: 90
Level 5:  💥💥💥  Damage: 5.0x   Armor Break: 100  Stagger: 100
```

## Control Layout

```
┌────────────────────────────────────┐
│        Combat Controls             │
├────────────────────────────────────┤
│                                    │
│  🖱️ Left Click                    │
│  → Light Attack / Combo           │
│                                    │
│  🖱️ Right Click (Hold)            │
│  → Charge Heavy Attack             │
│                                    │
│  🖱️ Right Click (Release)         │
│  → Execute Heavy Attack            │
│                                    │
│  WASD → Movement                   │
│  Shift → Sprint                    │
│                                    │
└────────────────────────────────────┘
```

## Charge Accumulation Visualization

### Scenario 1: Building Charge with Light Attacks
```
Time    Action              Charge Level
────────────────────────────────────────
00:00   Start               ░░░░░ (0)
00:01   Light Attack Hit    █░░░░ (1)
00:02   Light Attack Hit    ██░░░ (2)
00:03   Light Attack Hit    ███░░ (3)
00:04   Light Attack Hit    ████░ (4)
00:05   Heavy Attack        █████ (5) → RELEASE → ░░░░░ (0)
```

### Scenario 2: Charging Heavy Attack
```
Time    Action              Charge Level
────────────────────────────────────────
00:00   Start               ░░░░░ (0)
00:01   Hold RMB            ░░░░░ (0)
00:15   Still Holding       ░░░░░ (0)
00:50   Still Holding       █░░░░ (1)
01:00   Still Holding       ██░░░ (2)
01:50   Still Holding       ███░░ (3)
02:00   Release RMB         ███░░ (3) → ATTACK → ░░░░░ (0)
```

### Scenario 3: Mixed Strategy
```
Time    Action              Charge Level
────────────────────────────────────────
00:00   Start               ░░░░░ (0)
00:01   Light Hit           █░░░░ (1)
00:02   Light Hit           ██░░░ (2)
00:03   Hold RMB            ██░░░ (2)
00:53   Still Holding       ███░░ (3)
01:03   Still Holding       ████░ (4)
01:53   Still Holding       █████ (5)
02:03   Release RMB         █████ (5) → MASSIVE ATTACK → ░░░░░ (0)
```

## UI Feedback Examples

### Normal State
```
No input → Charge slowly decays (if decay enabled)
Display: Static, shows current level
```

### Light Attack Hit
```
Enemy Hit! → Flash green → +1 charge → Scale bounce
Display: Number increases, bar fills
```

### Charging Heavy
```
Holding RMB → Bar pulsing → Level increasing
Display: Animated filling, numbers counting up
```

### Max Charge Reached
```
Level 5! → Flash yellow → Screen shake (optional)
Display: Red color, flashing effect, lightning icon
```

### Heavy Attack Released
```
Release! → Explosion effect → Bar empties → Cooldown
Display: Rapid drain animation, reset to 0
```

## Position Details

```
Screen: 1920 x 1080
Charge Display Position:
  - X: 1670 (right edge - 250)
  - Y: 930 (bottom edge - 150)
  - Width: 230
  - Height: 130
  - Margin from edge: 20px

Relative to screen edges:
  - 250px from right
  - 150px from bottom
  - Always visible
  - Never obscures gameplay
```
