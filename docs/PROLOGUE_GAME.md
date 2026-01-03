# Prologue: Glucose Identification Game

## Overview
The prologue is an educational mini-game that teaches players to identify glucose molecules among other sugars. It serves as a tutorial for the core game mechanics while introducing basic biochemistry concepts.

## Objective
Restore a dying cell to health by:
1. Collecting glucose molecules to refill ammunition
2. Shooting the cell to heal it
3. Avoiding non-glucose sugar molecules

## Game Mechanics

### The Dying Cell
- **Starting Health**: 100 HP (10% of max)
- **Max Health**: 1000 HP
- **Victory Threshold**: 500 HP (50% of max)
- **Health Drain**: 1 HP per second (continuous)
- **Visual Feedback**: 
  - Pulses faster when low on health
  - Changes color from red → orange → yellow → green as health increases
  - Flashes green when healed

### Molecules
The game spawns 30 molecules randomly across the map:
- **Glucose (40%)**: Green circles - Correct answer
  - Refills 5 ammo when collected
  - Positive visual/audio feedback
- **Other Sugars (60%)**: Various colored circles - Wrong answers
  - Fructose (Orange)
  - Galactose (Yellow)
  - Sucrose (Red)
  - Lactose (Purple)
  - Maltose (Blue)
  - Deals 10 HP damage to player
  - Negative visual/audio feedback

### Player Mechanics
- **Movement**: WASD or Arrow Keys
- **Shooting**: Mouse click to aim and shoot
- **Ammo Management**: Must collect glucose to refill ammo
- **Health**: Loses HP from wrong molecules, dies at 0 HP

### Healing the Cell
- Shoot the cell with projectiles
- Each hit heals the cell for the weapon's damage amount
- Cell must reach 500 HP to win
- If cell reaches 0 HP (from continuous drain), game over

## Win/Lose Conditions

### Victory
- Cell health reaches 500 HP or more
- Player successfully identified enough glucose molecules
- Victory screen displays with educational summary

### Defeat
There are two ways to lose:
1. **Cell Dies**: Cell health reaches 0 HP from continuous drain
2. **Player Dies**: Player health reaches 0 HP from collecting wrong molecules

## Educational Goals
The prologue teaches:
1. **Visual Recognition**: Glucose structure identification (simplified to colors in prototype)
2. **Resource Management**: Balancing ammo collection vs. avoiding damage
3. **Biological Concepts**: Glucose as an energy source for cells
4. **Decision Making**: Risk vs. reward when approaching molecules

## Technical Implementation

### Files
- `features/prologue/prologue_game.gd` - Main game loop and spawning
- `features/prologue/target_cell.gd` - Dying cell mechanics
- `features/interactive/molecule/molecule.gd` - Molecule interaction
- `ui/prologue/prologue_ui.gd` - UI overlay
- `scenes/story/prologue/prologue_game.tscn` - Main scene

### Assets
- `assets/sprites/cell_sprite.png` - Cell visual (red circle)
- `assets/sprites/molecules/molecule_circle.png` - Molecule base sprite

### EventBus Signals
- `molecule_collected(molecule_type: int, is_glucose: bool)` - Fired when molecule is picked up

## Future Enhancements
1. **Molecular Structures**: Replace colored circles with actual chemical structure diagrams
2. **Difficulty Levels**: Adjust molecule ratios and spawn patterns
3. **Tutorial Overlay**: Step-by-step instructions for first-time players
4. **Sound Effects**: Collection sounds, healing sounds, victory music
5. **Particle Effects**: More polished visual feedback
6. **Educational Facts**: Pop-up facts about glucose and cellular respiration
7. **Leaderboard**: Track completion time and accuracy
8. **Multiple Rounds**: Progressive difficulty with different molecules to identify
