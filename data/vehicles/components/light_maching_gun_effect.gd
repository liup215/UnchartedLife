extends Node2D

@export var bullet_scene: PackedScene = preload("res://data/vehicles/components/light_machine_gun_bullet.tscn")
@export var fire_sound: AudioStream
@export var muzzle_flash_texture: Texture2D

func _ready():
	pass

func fire(origin: Vector2, target: Vector2, damage: float, weapon_data: WeaponData):
	# 创建枪口闪光效果
	if muzzle_flash_texture:
		var flash = Sprite2D.new()
		flash.texture = muzzle_flash_texture
		flash.global_position = origin
		flash.modulate = Color(1, 1, 0.8, 1)  # 略微偏黄的闪光
		flash.scale = Vector2(0.5, 0.5)
		get_tree().current_scene.add_child(flash)
		
		# 创建闪烁动画
		var tween = flash.create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, 0.1)
		tween.tween_callback(flash.queue_free)

	# 创建实际的子弹
	if bullet_scene and weapon_data.weapon_type == WeaponData.WeaponType.SUB_WEAPON:
		var direction = (target - origin).normalized()
		var bullet = bullet_scene.instantiate()
		bullet.global_position = origin + direction * 50 # 在朝向鼠标方向50像素处生成
		bullet.direction = direction
		# bullet.speed = damage * 100.0 if damage > 0 else 800.0
		bullet.damage = damage
		get_tree().current_scene.add_child(bullet)

	# 播放音效
	var sound = weapon_data.fire_sound if weapon_data else fire_sound
	if sound:
		var sound_player = AudioStreamPlayer2D.new()
		sound_player.stream = sound
		sound_player.global_position = origin
		get_tree().current_scene.add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)
