# Vascular Maze Generator - Quick Reference

## File Location
`features/map/vascular_maze_generator.gd`

## Class Information
- **Class Name**: `VascularMazeGenerator`
- **Extends**: `Node2D`
- **Purpose**: Generate blood vessel-themed maze levels using layered graph approach

## Core Requirements Met

### ✅ Layered Graph Generation Method
- **Artery Segment (20%)**: Few nodes, direct connections, minimal branching
- **Capillary Segment (60%)**: Many nodes, complex many-to-many connections
- **Vein Segment (20%)**: Multiple paths converging to single endpoint

### ✅ Wall Generation (Epithelial Cells)
- **No TileMap used** - walls are instantiated Sprite scenes
- **Tangent-based rotation** using `Curve2D.sample_baked_with_rotation()`
- **Gap mechanism** in capillary segment only (random wall skipping)

### ✅ Game Mechanics
- **One-way valves** at key branch points
- **Flow fields** (Area2D) pushing player downstream
- **Loop mechanism** teleports player from vein end to start

### ✅ Vessel Type Differences
| Type | Width | Speed | Gaps |
|------|-------|-------|------|
| Artery | Wide (1.5x) | Fast (500) | No |
| Capillary | Narrow (0.6x) | Slow (150) | Yes (15%) |
| Vein | Widest (2.0x) | Medium (300) | No |

## Export Variables (Configuration)

### Scene References
```gdscript
@export var wall_scene: PackedScene  # Epithelial cell sprite
@export var valve_scene: PackedScene  # One-way valve
@export var player_spawn_marker: Marker2D  # Start position marker
```

### Generation Parameters
```gdscript
@export var layer_count: int = 8  # Vertical layers (4-12 recommended)
@export var total_length: float = 5000.0  # Horizontal length in pixels
@export var vessel_width_base: float = 100.0  # Base vessel width
```

### Segment Ratios
```gdscript
@export var artery_ratio: float = 0.2  # 20% of total
@export var capillary_ratio: float = 0.6  # 60% of total
@export var vein_ratio: float = 0.2  # 20% of total
```

### Vessel Properties
```gdscript
# Width multipliers
@export var artery_width_multiplier: float = 1.5
@export var capillary_width_multiplier: float = 0.6
@export var vein_width_multiplier: float = 2.0

# Flow speeds (push force)
@export var artery_flow_speed: float = 500.0
@export var capillary_flow_speed: float = 150.0
@export var vein_flow_speed: float = 300.0
```

### Wall Properties
```gdscript
@export var wall_spacing: float = 20.0  # Distance between walls
@export var wall_offset: float = 50.0  # Distance from path center
@export var capillary_gap_chance: float = 0.15  # Gap probability (0-1)
```

### Loop Mechanism
```gdscript
@export var enable_loop: bool = true  # Enable end-to-start teleport
```

## Main Functions

### `generate_maze()`
Main generation function called automatically in `_ready()` if not in editor mode.

**Process**:
1. Clear previous content
2. Calculate segment lengths
3. Generate artery segment (first 20%)
4. Generate capillary segment (middle 60%)
5. Generate vein segment (last 20%)
6. Create loop trigger at end

### `_build_vessel_segment(segment_type, start_x, length, start_layer_range, end_layer_range)`
Build a specific vessel segment with appropriate properties.

**Parameters**:
- `segment_type`: ARTERY, CAPILLARY, or VEIN
- `start_x`: Starting X position
- `length`: Segment length
- `start_layer_range`: Starting layer distribution
- `end_layer_range`: Ending layer distribution

**Process**:
1. Get segment properties (paths, width, speed, gaps)
2. Determine layer distribution based on type
3. Generate paths using Curve2D
4. Generate walls along each path
5. Generate flow fields along each path
6. Add valves at branch points (arteries)

### `_generate_walls_along_path(curve, width_multiplier, has_gaps)`
Generate wall sprites along a vessel path.

**Process**:
1. Iterate along path using `curve.get_baked_length()`
2. Sample position and rotation at each point
3. Calculate perpendicular offset for left/right walls
4. Instantiate wall sprites with proper rotation
5. Skip walls randomly if has_gaps is true

### `_generate_flow_field_along_path(curve, flow_speed)`
Generate Area2D flow fields that push the player.

**Process**:
1. Place Area2D nodes every 100 pixels along path
2. Add CircleShape2D collision (radius 80)
3. Store flow direction and speed as metadata
4. Connect body_entered signal to apply force

### `_create_loop_trigger()`
Create teleport trigger at vein endpoint.

**Process**:
1. Create Area2D at end_position
2. Add CircleShape2D collision (radius 50)
3. Connect body_entered signal to teleport player

## Usage Steps

### 1. Create Scene
1. New scene with Node2D root
2. Attach `vascular_maze_generator.gd` script
3. Add Marker2D child named "PlayerSpawn"

### 2. Create Supporting Scenes
- **Wall Scene**: Sprite2D root with optional StaticBody2D collision
- **Valve Scene**: Area2D root with visual sprite

### 3. Configure in Inspector
- Assign wall_scene and valve_scene
- Select PlayerSpawn marker
- Adjust layer_count and total_length
- Fine-tune vessel properties if needed

### 4. Run Scene
Generator automatically creates maze structure at runtime.

## Example Scene Files

All located in `features/map/`:
- `tests/vascular_maze_test.tscn` - Complete example setup
- `example_epithelial_cell.tscn` - Basic wall scene
- `tests/vascular_valve.tscn` - Basic valve scene

## Player Requirements

Player must:
1. Be in `"player"` group
2. Have either:
   - `apply_force(force: Vector2)` method, OR
   - Be `CharacterBody2D` with `velocity` property

## Debugging

### Enable Path Visualization
Add to script:
```gdscript
func _draw() -> void:
    for curve in vessel_paths:
        draw_polyline(curve.get_baked_points(), Color.RED, 2.0)
    queue_redraw()
```

### Console Output
Generator prints:
- Generation start/complete messages
- Segment generation progress
- Total paths created
- Start/end positions

## Performance Tips

- Keep layer_count between 4-12
- Higher layer_count = more walls = lower performance
- Use VisibleOnScreenEnabler2D on wall sprites
- Consider implementing wall pooling for very large mazes

## Customization Ideas

### Difficulty Settings
```gdscript
# Easy
layer_count = 4
capillary_gap_chance = 0.25
total_length = 3000

# Hard
layer_count = 12
capillary_gap_chance = 0.1
total_length = 10000
```

### Visual Enhancements
- Add particle systems to flow fields
- Pulse vessels with AnimationPlayer
- Color-code vessel types
- Add glow effects

### Gameplay Extensions
- Spawn enemies along paths
- Add item pickups in capillaries
- Create puzzle valves requiring keys
- Implement dynamic flow speed changes
- Add "blood clot" obstacles

## Technical Notes

### Curve2D Methods Used
- `add_point(position)` - Add waypoint to curve
- `get_baked_length()` - Get total path length
- `sample_baked(offset)` - Get position at distance
- `sample_baked_with_rotation(offset)` - Get Transform2D at distance
- `get_baked_points()` - Get all points for visualization

### Transform2D for Rotation
```gdscript
var transform := curve.sample_baked_with_rotation(distance)
var rotation_angle := transform.get_rotation()
```

### Perpendicular Vector Calculation
```gdscript
var perpendicular := Vector2(-sin(angle), cos(angle))
```

## Documentation Files

- `VASCULAR_MAZE_USAGE.md` - Full English guide
- `VASCULAR_MAZE_USAGE_CN.md` - Full Chinese guide (完整中文指南)
- `features/map/vascular_maze_generator.gd` - Fully commented source

## License
Part of Legends of Uncharted Life project.
