extends Node2D
class_name BaseWeaponEffect

@export var effect_name = "BaseEffect"

func fire(origin: Vector2, target: Vector2, weapon_data: WeaponData):
	print("[WEAPON EFFECT] Firing weapon from", origin, "to", target, "weapon:", weapon_data.weapon_name)
	# 创建枪口闪光效果
	if weapon_data.muzzle_flash_effect:
		var flash = weapon_data.muzzle_flash_effect.instantiate()
		flash.global_position = origin
		get_tree().current_scene.add_child(flash)

	# 创建实际的子弹
	if weapon_data.bullet_scene:
		var direction = (target - origin).normalized()
		var bullet = weapon_data.bullet_scene.instantiate()
		
		# Inject data from WeaponData into the bullet
		bullet.global_position = origin + direction * 50 # Spawn 50px away from origin
		bullet.direction = direction
		bullet.speed = weapon_data.bullet_speed
		bullet.damage = weapon_data.damage
		bullet.lifetime = weapon_data.bullet_lifetime
		bullet.bullet_texture = weapon_data.bullet_texture
		bullet.bullet_scale = weapon_data.bullet_scale
		bullet.hit_effect_texture = weapon_data.hit_effect_texture
		bullet.hit_effect_scale = weapon_data.hit_effect_scale
		bullet.hit_effect_h_frames = weapon_data.hit_effect_h_frames
		bullet.hit_effect_v_frames = weapon_data.hit_effect_v_frames
		bullet.hit_effect_frame_count = weapon_data.hit_effect_frame_count
		bullet.hit_effect_duration = weapon_data.hit_effect_duration
		
		get_tree().current_scene.add_child(bullet)

	# 播放音效
	if weapon_data.fire_sound:
		var sound_player = AudioStreamPlayer2D.new()
		sound_player.stream = weapon_data.fire_sound
		sound_player.global_position = origin
		get_tree().current_scene.add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)
