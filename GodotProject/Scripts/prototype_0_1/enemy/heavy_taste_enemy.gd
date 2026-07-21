class_name HeavyTasteEnemy
extends BasicTasteEnemy


func setup(enemy_config: PrototypeWaveConfig, player_target: PrototypePlayer, nav: KitchenNavigationGrid) -> void:
	super.setup(enemy_config, player_target, nav)
	enemy_title = "重型味真族"
	enemy_color = Color("7b2f4b")
	enemy_visual_size = Vector2(82.0, 92.0)
	enemy_collision_radius = 23.0
	max_health_value = config.heavy_max_health
	move_speed_value = config.heavy_move_speed
	attack_distance_value = config.heavy_attack_distance
	attack_range_value = config.heavy_attack_range
	attack_width_value = config.heavy_attack_width
	windup_time_value = config.heavy_windup_time
	attack_active_time_value = config.heavy_attack_active_time
	recovery_time_value = config.heavy_recovery_time
	attack_damage_value = config.heavy_attack_damage
	player_knockback_value = config.heavy_player_knockback
	attack_cooldown_value = config.heavy_attack_cooldown
	hit_stun_time_value = config.heavy_hit_stun_time
	stagger_threshold = config.heavy_stagger_threshold
	knockback_multiplier = config.heavy_knockback_multiplier
	current_health = max_health_value


func _ready() -> void:
	super._ready()
	add_to_group("heavy_taste_enemy")


func get_trap_taste_time_multiplier() -> float:
	return config.heavy_taste_time_multiplier
