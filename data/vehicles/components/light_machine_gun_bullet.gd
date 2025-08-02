extends Area2D

var speed: float = 800.0
var damage: float = 10.0
var direction: Vector2 = Vector2.UP
var lifetime: float = 2.0

@export var hit_effect_texture: Texture2D = preload("res://assets/effects/explosion_scaled_down.png")

func _ready():
	# 旋转子弹朝向移动方向
	rotation = direction.angle() + PI/2

	# 确保精灵可见并设置合适的视觉效果
	if has_node("Sprite2D"):
		var sprite = $Sprite2D
		sprite.visible = true
		# 使用第一帧作为子弹图像
		sprite.frame = 0
		# 调整精灵大小使其看起来更像子弹
		sprite.scale = Vector2(3, 3) # 恢复默认尺寸，使其可见
		# 添加发光效果
		sprite.modulate = Color(1.2, 1.2, 0.8, 1)  # 略微发光的黄色

	# 设置子弹的生命周期
	_setup_lifetime()

func _setup_lifetime():
	await get_tree().create_timer(lifetime).timeout
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

	# 创建命中效果
	_create_hit_effect()

	# 击中任何物体后消失
	queue_free()

func _create_hit_effect():
	if not hit_effect_texture:
		return

	var effect_sprite = Sprite2D.new()
	effect_sprite.texture = hit_effect_texture
	effect_sprite.hframes = 4
	effect_sprite.vframes = 4
	effect_sprite.global_position = self.global_position
	effect_sprite.scale = Vector2(3, 3)
	get_tree().current_scene.add_child(effect_sprite)

	# 从场景树创建Tween，确保它在子弹消失后依然存在
	var tween = get_tree().create_tween()
	
	# 使用回调和 .bind() 方法逐帧播放动画
	var frame_duration = 0.05
	for i in range(1, 16):
		tween.tween_callback(effect_sprite.set_frame.bind(i))
		tween.tween_interval(frame_duration)

	# 动画完成后，释放 effect_sprite
	tween.tween_callback(effect_sprite.queue_free)
