extends Area2D

# These properties will be set by the weapon that fires the bullet
var speed: float = 800.0
var damage: float = 10.0
var direction: Vector2 = Vector2.UP
var lifetime: float = 2.0
var bullet_texture: Texture2D
var bullet_scale: Vector2 = Vector2.ONE
var hit_effect_texture: Texture2D
var hit_effect_scale: Vector2 = Vector2.ONE
var hit_effect_h_frames: int = 1
var hit_effect_v_frames: int = 1
var hit_effect_frame_count: int = 1
var hit_effect_duration: float = 0.5

# Reference to shooter for charge accumulation
var shooter: Node = null

func _ready():
	# 旋转子弹朝向移动方向
	rotation = direction.angle() + PI/2

	# 确保精灵可见并设置合适的视觉效果
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		if bullet_texture:
			sprite.texture = bullet_texture
		sprite.scale = bullet_scale
		sprite.visible = true
		# 使用第一帧作为子弹图像
		sprite.frame = 0
		# 添加发光效果
		sprite.modulate = Color(1.2, 1.2, 0.8, 1)  # 略微发光的黄色

	# 设置子弹的生命周期
	_setup_lifetime()

func _setup_lifetime():
	await get_tree().create_timer(lifetime, false).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	# 移动子弹
	position += direction * speed * delta

func _on_body_entered(body):
	print("Bullet hit: ", body.name)
	# 处理命中逻辑
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# Notify shooter's combat component about the hit (for charge accumulation)
	if shooter and shooter.has_node("ActorCombatComponent"):
		var combat_comp = shooter.get_node("ActorCombatComponent")
		if combat_comp.has_method("on_enemy_hit"):
			combat_comp.on_enemy_hit(body, damage)

	# 创建命中效果
	_create_hit_effect()

	# 击中任何物体后消失
	queue_free()

func _create_hit_effect():
	if not hit_effect_texture:
		return

	var effect_sprite = Sprite2D.new()
	effect_sprite.texture = hit_effect_texture
	effect_sprite.hframes = hit_effect_h_frames
	effect_sprite.vframes = hit_effect_v_frames
	effect_sprite.global_position = self.global_position
	effect_sprite.scale = hit_effect_scale
	get_tree().current_scene.add_child(effect_sprite)

	# 从场景树创建Tween，确保它在子弹消失后依然存在
	var tween = get_tree().create_tween()

	# 使用 tween_property 直接对 frame 属性进行动画处理
	tween.tween_property(effect_sprite, "frame", hit_effect_frame_count - 1, hit_effect_duration).from(0)

	# 动画完成后，释放 effect_sprite
	tween.tween_callback(effect_sprite.queue_free)
