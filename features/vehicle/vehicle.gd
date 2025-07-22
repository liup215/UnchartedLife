# vehicle.gd
# The base vehicle class for RigidBody2D tank-style control.
extends RigidBody2D

class_name Vehicle

@export var vehicle_data: Resource  # Will be VehicleData once the type is available
@onready var visuals: ColorRect = $Visuals
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var interaction_ui: Control = $InteractionUI
@onready var interaction_label: Label = $InteractionUI/InteractionLabel
@onready var vehicle_camera: Camera2D = $Camera2D

# Vehicle state
var occupied: bool = false
var driver: Node2D = null  # Will be Player once the type is available
var current_fuel: float = 100.0  # Represents available glucose for this vehicle
var engine_running: bool = false
var player_camera: Camera2D = null  # Reference to player's camera

# Movement parameters
var acceleration: float = 1200.0
var max_speed: float = 400.0
var turn_speed: float = 2.5

# 下车点检测参数
var exit_offsets := [
	Vector2(48, 0),   # 右
	Vector2(-48, 0),  # 左
	Vector2(0, 48),   # 下
	Vector2(0, -48),  # 上
	Vector2(34, 34),  # 右下
	Vector2(34, -34), # 右上
	Vector2(-34, 34), # 左下
	Vector2(-34, -34) # 左上
]

func _ready():
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	if visuals:
		visuals.color = Color.DARK_GRAY
		visuals.size = Vector2(64, 48)
	current_fuel = 100.0

func _physics_process(delta: float):
	if occupied and driver:
		_handle_vehicle_movement(delta)
		_consume_fuel(delta)
	else:
		# 空闲时自动阻尼
		linear_damp = 8
		angular_damp = 8

func _handle_vehicle_movement(delta: float):
	# 只允许前进/后退和左右转向
	var move_input = 0
	var turn_input = 0

	if Input.is_action_pressed("move_forward"):
		move_input += 1
	if Input.is_action_pressed("move_backward"):
		move_input -= 1
	if Input.is_action_pressed("turn_left"):
		turn_input -= 1
	if Input.is_action_pressed("turn_right"):
		turn_input += 1

	# 前进/后退
	if move_input != 0:
		var forward = Vector2.RIGHT.rotated(rotation)
		var force = forward * acceleration * move_input
		apply_central_force(force)
		# 限速
		if linear_velocity.length() > max_speed:
			linear_velocity = linear_velocity.normalized() * max_speed

	# 左右转向
	if turn_input != 0:
		angular_velocity = turn_speed * turn_input
	else:
		angular_velocity = 0

	# 低速时自动阻尼
	if move_input == 0:
		linear_damp = 8
	else:
		linear_damp = 2

func _consume_fuel(delta: float):
	if not vehicle_data:
		return
	# 简化燃料消耗
	var consumption = 0.5 if engine_running else 0.1
	current_fuel = max(0, current_fuel - consumption * delta)

func _on_body_entered(body: Node2D):
	if body.has_method("show_vehicle_interaction") and not occupied:
		body.show_vehicle_interaction(self)
		_show_interaction_ui(true)

func _on_body_exited(body: Node2D):
	if body.has_method("hide_vehicle_interaction"):
		body.hide_vehicle_interaction()
		_show_interaction_ui(false)

func _show_interaction_ui(is_visible: bool):
	if interaction_ui:
		interaction_ui.visible = is_visible
		if is_visible and interaction_label and vehicle_data:
			interaction_label.text = get_interaction_text()

func can_be_entered() -> bool:
	return not occupied

func enter_vehicle(player: Node2D) -> bool:
	if not can_be_entered():
		return false
	occupied = true
	driver = player
	engine_running = false
	# 摄像头切换
	if player.has_node("Camera2D"):
		player_camera = player.get_node("Camera2D")
		player_camera.enabled = false
	if vehicle_camera:
		vehicle_camera.enabled = true
	player.set_in_vehicle_state(true)
	return true

func exit_vehicle() -> bool:
	if not occupied:
		return false
	var ejected_player = driver
	occupied = false
	driver = null
	engine_running = false
	# 停止运动，防止被甩飞
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	# 彻底冻结物理，禁用所有碰撞体
	if collision:
		collision.disabled = true
	sleeping = true
	# 摄像头切换
	if vehicle_camera:
		vehicle_camera.enabled = false
	if player_camera:
		player_camera.enabled = true
		player_camera = null
	# 智能选择安全下车点
	if ejected_player:
		var safe_pos = find_safe_exit_position(ejected_player)
		# 临时禁用player碰撞体
		if ejected_player.has_method("set_collision_enabled"):
			ejected_player.set_collision_enabled(false)
		ejected_player.set_in_vehicle_state(false)
		ejected_player.global_position = safe_pos
		# 等待一帧，确保物理引擎稳定
		await get_tree().process_frame
		# 恢复player碰撞体
		if ejected_player.has_method("set_collision_enabled"):
			ejected_player.set_collision_enabled(true)
		# 恢复物理
		sleeping = false
		if collision:
			collision.disabled = false
		# 如果player和vehicle发生碰撞，主动将player弹开
		var space = get_world_2d().direct_space_state
		if ejected_player.has_node("CollisionShape2D"):
			var player_shape = ejected_player.get_node("CollisionShape2D").shape
			var params = PhysicsShapeQueryParameters2D.new()
			params.shape = player_shape
			params.transform = Transform2D(0, ejected_player.global_position)
			params.margin = 0.1
			params.collision_mask = 0xFFFFFFFF
			params.exclude = [self.get_rid()]
			var result = space.intersect_shape(params, 1)
			if result.size() > 0:
				# 计算弹开方向（远离vehicle）
				var away = (ejected_player.global_position - global_position).normalized()
				if away.length() < 0.1:
					away = Vector2.RIGHT.rotated(rotation)
				ejected_player.global_position += away * 32
	return true

func find_safe_exit_position(player: Node2D) -> Vector2:
	var space = get_world_2d().direct_space_state
	var base_pos = global_position
	var player_shape = null
	if player.has_node("CollisionShape2D"):
		player_shape = player.get_node("CollisionShape2D").shape
	for offset in exit_offsets:
		var test_pos = base_pos + offset.rotated(rotation)
		if player_shape:
			var params = PhysicsShapeQueryParameters2D.new()
			params.shape = player_shape
			params.transform = Transform2D(0, test_pos)
			params.margin = 0.1
			params.collision_mask = 0xFFFFFFFF
			params.exclude = [self.get_rid()]
			var result = space.intersect_shape(params, 1)
			if result.size() == 0:
				return test_pos
		else:
			# fallback: no shape, just return first offset
			return test_pos
	# 如果所有方向都不安全，默认放在右侧
	return base_pos + exit_offsets[0].rotated(rotation)

func get_interaction_text() -> String:
	if can_be_entered():
		return "Press E to enter " + (vehicle_data.vehicle_name if vehicle_data else "Vehicle")
	else:
		return "Vehicle occupied"
