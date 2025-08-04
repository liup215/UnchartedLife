# animation_data.gd
# A resource that holds all the defining data for a single animation.
extends Resource
class_name AnimationData

## The name of the animation (e.g., "walk_down", "idle_up").
@export var animation_name: String = "default"

## The spritesheet texture for this animation.
@export var spritesheet: Texture2D

## The number of horizontal frames in the spritesheet.
@export var h_frames: int = 1

## The number of vertical frames in the spritesheet.
@export var v_frames: int = 1

## The sequence of frame indices to play for this animation.
## If empty, it will play all frames in order.
@export var frame_indices: Array[int]

## The playback speed of the animation in frames per second.
@export var speed: float = 5.0
