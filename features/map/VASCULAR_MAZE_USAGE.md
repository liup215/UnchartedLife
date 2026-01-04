# Vascular Maze Generator Usage Guide

## Overview
The `VascularMazeGenerator` is a standalone script that generates blood vessel-themed maze levels using a layered graph approach. It simulates the progression from arteries through capillaries to veins with realistic biological properties.

## Quick Start

### 1. Create a New Scene
1. Create a new scene in Godot with a `Node2D` as the root
2. Attach the `vascular_maze_generator.gd` script to the root node
3. Save the scene (e.g., `vascular_level_01.tscn`)

### 2. Configure Required Scenes

#### Wall Scene (Epithelial Cell)
Create a simple sprite scene for vessel walls:
1. Create a new scene with `Sprite2D` as root
2. Add a texture (e.g., a cell or wall sprite)
3. Optionally add a `StaticBody2D` with `CollisionShape2D` for collision
4. Save as `epithelial_cell.tscn`

Example structure:
```
Sprite2D (root)
├── Texture: cell_sprite.png
└── StaticBody2D
    └── CollisionShape2D (RectangleShape2D or CircleShape2D)
```

#### Valve Scene (One-Way Valve)
Create a valve that allows one-way passage:
1. Create a new scene with `Area2D` as root
2. Add a visual sprite
3. Add collision detection
4. Attach a script to check player direction and only allow passage in one direction
5. Save as `valve.tscn`

Example structure:
```
Area2D (root)
├── Sprite2D (valve visual)
└── CollisionShape2D
```

#### Player Spawn Marker (Optional)
1. Add a `Marker2D` node as a child of the generator
2. Name it something like "PlayerSpawn"
3. Position it where the player should start

### 3. Assign Export Variables

In the Godot Inspector, set the following:

**Scene References:**
- `Wall Scene`: Drag your epithelial cell scene here
- `Valve Scene`: Drag your valve scene here
- `Player Spawn Marker`: Select the Marker2D child node

**Generation Parameters:**
- `Layer Count`: Number of vertical layers (default: 8)
  - More layers = more complex maze
  - Recommended range: 4-12
- `Total Length`: Total horizontal length in pixels (default: 5000.0)
  - Larger values = longer level
  - Recommended range: 3000-10000

**Vessel Properties:**
You can adjust the width and flow speed for each vessel type:
- Artery: Wide, fast flow, no gaps
- Capillary: Narrow, slow flow, has gaps
- Vein: Widest, medium flow, no gaps

### 4. Run the Scene

When you run the scene, the generator will automatically create the maze structure:
1. Artery segment (first 20%)
2. Capillary network (middle 60%)
3. Vein segment (last 20%)
4. Loop trigger at the end

## Advanced Configuration

### Segment Ratios
Adjust how much of the total length each segment takes:
```gdscript
artery_ratio = 0.2    # 20% of total length
capillary_ratio = 0.6  # 60% of total length
vein_ratio = 0.2       # 20% of total length
```

### Width Multipliers
Control the width of each vessel type:
```gdscript
artery_width_multiplier = 1.5    # 1.5x base width
capillary_width_multiplier = 0.6  # 0.6x base width (narrower)
vein_width_multiplier = 2.0       # 2.0x base width (widest)
```

### Flow Speed
Adjust the push force applied to the player:
```gdscript
artery_flow_speed = 500.0      # Strong push
capillary_flow_speed = 150.0   # Gentle push
vein_flow_speed = 300.0        # Medium push
```

### Wall Gap Mechanism
Control the capillary wall gaps (entry/exit points):
```gdscript
capillary_gap_chance = 0.15  # 15% chance to skip a wall
```
Higher values = more gaps = easier navigation

### Wall Spacing and Offset
Fine-tune wall placement:
```gdscript
wall_spacing = 20.0  # Distance between wall sprites
wall_offset = 50.0   # Distance from path center to walls
```

## How It Works

### Layered Graph Approach
The generator creates a layered structure:
1. **Layers**: Vertical divisions across the maze height
2. **Nodes**: Points within each layer
3. **Connections**: Paths between nodes in adjacent layers

### Three Vessel Segments

#### 1. Artery (First 20%)
- **Characteristics**: Few parallel paths, mostly straight
- **Nodes**: Sparse (layer_count / 4 paths)
- **Connections**: Direct, minimal branching
- **Width**: Wide (1.5x base)
- **Flow**: Fast (500 units)
- **Gaps**: None (solid walls)
- **Valves**: Generated at branch points

#### 2. Capillary (Middle 60%)
- **Characteristics**: Dense network, complex interconnections
- **Nodes**: Many (layer_count * 3 paths)
- **Connections**: Many-to-many, creating maze structure
- **Width**: Narrow (0.6x base)
- **Flow**: Slow (150 units)
- **Gaps**: Random (15% chance to skip walls)
- **Purpose**: Main exploration/puzzle area

#### 3. Vein (Last 20%)
- **Characteristics**: Converging paths back to single endpoint
- **Nodes**: Moderate (layer_count / 3 paths)
- **Connections**: All paths merge to center
- **Width**: Widest (2.0x base)
- **Flow**: Medium (300 units)
- **Gaps**: None (solid walls)
- **Teleport**: Loop trigger at end returns to start

### Wall Generation
Walls are placed along vessel paths using:
1. **Curve2D**: Smooth path representation
2. **Tangent Calculation**: `sample_baked_with_rotation()` gets path direction
3. **Perpendicular Offset**: Walls placed on both sides of path
4. **Rotation**: Sprites rotated to align with vessel direction

### Flow Fields
Area2D nodes create push forces:
1. Placed every 100 pixels along paths
2. Store flow direction and speed as metadata
3. Apply force when player enters (via `body_entered` signal)

### Loop Mechanism
A trigger at the vein endpoint teleports the player back to the start, creating an endless circulation effect.

## Integration with Player

The generator expects the player to:
1. Be in the `"player"` group
2. Have either:
   - `apply_force(force: Vector2)` method for physics-based movement
   - Be a `CharacterBody2D` with `velocity` property for kinematic movement

## Tips for Best Results

### Visual Design
- Use elongated cell sprites for walls (oriented vertically)
- Make valves visually distinct (different color/shape)
- Add particle effects to flow fields for visual feedback

### Balancing Difficulty
- **Easy Level**: 
  - layer_count = 4
  - capillary_gap_chance = 0.25
  - shorter total_length (3000)
- **Hard Level**:
  - layer_count = 12
  - capillary_gap_chance = 0.1
  - longer total_length (10000)

### Performance
- Keep layer_count reasonable (4-12)
- Each layer creates multiple paths with walls
- Large layer counts = many sprite instances
- Consider using VisibleOnScreenEnabler2D for walls

### Educational Integration
Add biology facts:
1. Place info markers along the path
2. Quiz triggers at key points
3. Labels explaining vessel types
4. Visual indicators for flow direction

## Debugging

### Enable Debug Drawing
Add to the script:
```gdscript
func _draw() -> void:
    # Draw paths for debugging
    for curve in vessel_paths:
        draw_polyline(curve.get_baked_points(), Color.RED, 2.0)
```

### Console Output
The generator prints:
- "Starting maze generation..."
- Segment generation progress
- "Maze generation complete!"
- Total paths created
- Start/end positions

### Common Issues

**Walls not appearing:**
- Check that `wall_scene` is assigned
- Verify wall scene has a Sprite2D root
- Check wall_spacing isn't too large

**No collision:**
- Ensure wall scene has StaticBody2D + CollisionShape2D
- Check collision layers/masks in project settings

**Flow not working:**
- Verify player is in "player" group
- Check player movement implementation
- Ensure flow fields are being created (check node tree)

**Valves not spawning:**
- Assign valve_scene in inspector
- Check that valve_scene is not null

## Example Scene Setup

```
VascularLevel (Node2D) [vascular_maze_generator.gd attached]
├── PlayerSpawn (Marker2D)
└── [Generated content appears here at runtime]
    ├── WallSprite1 (Sprite2D)
    ├── WallSprite2 (Sprite2D)
    ├── ...
    ├── FlowField1 (Area2D)
    ├── FlowField2 (Area2D)
    ├── ...
    ├── Valve1 (Area2D)
    └── LoopTrigger (Area2D)
```

## Extending the Generator

### Custom Segment Types
Add new vessel types by:
1. Adding to `SegmentType` enum
2. Adding case to `_get_segment_properties()`
3. Calling `_build_vessel_segment()` with new type

### Additional Features
Consider adding:
- Enemy spawn points along paths
- Item pickups in capillaries
- Branching puzzles at valves
- Dynamic width based on flow
- Visual effects (pulsing, flowing particles)
- Audio cues for different segments

### Save/Load Support
To make generated mazes persistent:
1. Add to "saveable" group
2. Implement `save_data() -> Dictionary`
3. Implement `load_data(data: Dictionary)`
4. Save vessel_paths and regenerate walls

## License
Part of Legends of Uncharted Life project.
