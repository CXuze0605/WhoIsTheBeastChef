class_name DebugCombatTarget
extends CharacterBody2D

signal auto_attack_changed(enabled: bool)

@export var combat_faction: int = CombatRules.Faction.ENEMY
@export var max_health: float = 120.0
@export var debug_title: String = "敌方测试假人"
@export_group("Development Auto Attack")
@export var auto_attack_available: bool = false
@export var auto_attack_enabled: bool = false
@export var auto_attack_range: float = 220.0
@export var auto_attack_damage: float = 8.0
@export var auto_attack_interval: float = 1.0
@export var auto_attack_knockback: float = 34.0
@export_group("")

var current_health: float
var knockback_velocity := Vector2.ZERO
var hit_flash_time: float = 0.0
var auto_attack_cooldown: float = 0.0
var auto_attack_pulse_time: float = 0.0
var last_auto_attack_hit_count: int = 0
var total_auto_attack_pulses: int = 0
var placeholder: PlaceholderVisual
var status_effects: DamageOverTimeController
var external_aim_sway_angle: float = 0.0
var external_sneeze_offset: float = 0.0
var receives_aim_influence: bool = true
var lobby_active: bool = true
var original_collision_layer: int
var original_collision_mask: int
var combat_statuses: CombatStatusController


func _ready() -> void:
	current_health = max_health
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	add_to_group("damageable")
	add_to_group("debug_combat_target")
	if combat_faction == CombatRules.Faction.FRIENDLY and receives_aim_influence:
		add_to_group("aim_influence_receiver")
	status_effects = DamageOverTimeController.new()
	status_effects.name = "DamageOverTimeController"
	add_child(status_effects)
	combat_statuses = CombatStatusController.ensure_on(self)
	placeholder = PlaceholderVisual.new()
	add_child(placeholder)
	var art_key: StringName = &"friendly_dummy" if combat_faction == CombatRules.Faction.FRIENDLY else &"enemy_dummy"
	PrototypeArtCatalog.apply_to(placeholder, art_key)
	placeholder.configure(Vector2(74.0, 64.0), _get_color(), debug_title, _health_text())


func _physics_process(delta: float) -> void:
	velocity = knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	hit_flash_time = maxf(0.0, hit_flash_time - delta)
	auto_attack_pulse_time = maxf(0.0, auto_attack_pulse_time - delta)
	if auto_attack_enabled and auto_attack_available and lobby_active:
		auto_attack_cooldown -= delta
		if auto_attack_cooldown <= 0.0:
			perform_auto_attack_pulse()
			auto_attack_cooldown = maxf(0.05, auto_attack_interval)
	queue_redraw()
	if placeholder != null:
		placeholder.set_color(Color.WHITE if hit_flash_time > 0.0 else _get_color())
		placeholder.set_status(_health_text())


func _draw() -> void:
	if not auto_attack_available or not auto_attack_enabled or not lobby_active:
		return
	var range_color := Color(1.0, 0.35, 0.25, 0.72)
	draw_arc(Vector2.ZERO, auto_attack_range, 0.0, TAU, 72, range_color, 3.0, true)
	if auto_attack_pulse_time > 0.0:
		var pulse_ratio := auto_attack_pulse_time / 0.18
		draw_circle(Vector2.ZERO, auto_attack_range * (1.0 - pulse_ratio * 0.12), Color(1.0, 0.2, 0.12, 0.13))


func set_auto_attack_enabled(enabled: bool) -> void:
	var next_enabled := enabled and auto_attack_available and lobby_active
	if auto_attack_enabled == next_enabled:
		return
	auto_attack_enabled = next_enabled
	auto_attack_cooldown = 0.0
	last_auto_attack_hit_count = 0
	queue_redraw()
	auto_attack_changed.emit(auto_attack_enabled)


func perform_auto_attack_pulse() -> int:
	if not auto_attack_available or not auto_attack_enabled or not lobby_active:
		return 0
	var hit_count := 0
	for node in get_tree().get_nodes_in_group("damageable"):
		if node == self or not is_instance_valid(node):
			continue
		if not node is Node2D or not node.has_method("get_combat_faction") or not node.has_method("receive_combat_hit"):
			continue
		var target_faction := int(node.get_combat_faction())
		if target_faction not in [CombatRules.Faction.PLAYER, CombatRules.Faction.FRIENDLY]:
			continue
		var target := node as Node2D
		if global_position.distance_to(target.global_position) > auto_attack_range:
			continue
		var direction := global_position.direction_to(target.global_position)
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		if bool(target.receive_combat_hit(auto_attack_damage, CombatRules.Faction.ENEMY, direction, auto_attack_knockback, false)):
			hit_count += 1
	last_auto_attack_hit_count = hit_count
	total_auto_attack_pulses += 1
	auto_attack_pulse_time = 0.18
	queue_redraw()
	return hit_count


func get_auto_attack_status_text() -> String:
	if not auto_attack_available:
		return "不可用"
	if not auto_attack_enabled:
		return "关闭"
	return "开启 · 范围 %.0f · 伤害 %.0f · 上次命中 %d" % [auto_attack_range, auto_attack_damage, last_auto_attack_hit_count]


func get_combat_faction() -> int:
	return combat_faction


func receive_combat_hit(
	damage: float,
	attacker_faction: int,
	knockback_direction: Vector2,
	knockback_force: float,
	friendly_fire: bool,
	_stagger_power: float = 0.0
) -> bool:
	var context := DamageContext.from_legacy(damage, attacker_faction, combat_faction, friendly_fire)
	return receive_damage_context(context, knockback_direction, knockback_force)


func receive_damage_context(context: DamageContext, knockback_direction: Vector2 = Vector2.ZERO, knockback_force: float = 0.0, _stagger_power: float = 0.0) -> bool:
	if context == null or not lobby_active or not CombatRules.can_damage(context.attacker_faction, combat_faction, context.friendly_fire):
		return false
	context.target_faction = combat_faction
	var resolved_damage := CombatRules.resolve_damage(context, self)
	var health_before := current_health
	current_health = maxf(0.0, current_health - resolved_damage)
	var actual_damage := health_before - current_health
	context.actual_health_damage = actual_damage
	var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
	if stats != null:
		stats.record_damage_context(context)
		if health_before > 0.0 and current_health <= 0.0 and combat_faction == CombatRules.Faction.FRIENDLY:
			stats.record_teammate_knocked_down()
	knockback_velocity += knockback_direction.normalized() * knockback_force
	hit_flash_time = 0.12
	return true


func get_combat_status_controller() -> CombatStatusController:
	return combat_statuses


func apply_status_effect(effect: StatusEffectData) -> bool:
	return status_effects.apply_effect(effect) if status_effects != null else false


func receive_status_damage(damage: float, attacker_faction: int, _effect_type: int) -> bool:
	if not lobby_active or not CombatRules.can_damage(attacker_faction, combat_faction, false):
		return false
	var health_before := current_health
	current_health = maxf(0.0, current_health - damage)
	var stats := get_tree().get_first_node_in_group("run_stats") as RunStats
	if stats != null:
		stats.record_damage(health_before - current_health, attacker_faction, combat_faction)
	hit_flash_time = 0.18
	return true


func set_external_aim_influence(_source_id: int, sway_angle: float, sneeze_offset: float, active: bool) -> void:
	external_aim_sway_angle = sway_angle if active else 0.0
	external_sneeze_offset = sneeze_offset if active else 0.0


func reset_target() -> void:
	current_health = max_health
	knockback_velocity = Vector2.ZERO
	external_aim_sway_angle = 0.0
	external_sneeze_offset = 0.0
	auto_attack_cooldown = 0.0
	last_auto_attack_hit_count = 0
	if status_effects != null:
		status_effects.active_effects.clear()
	if combat_statuses != null:
		combat_statuses.clear_all()


func set_lobby_active(active: bool) -> void:
	lobby_active = active
	visible = active
	set_physics_process(active)
	collision_layer = original_collision_layer if active else 0
	collision_mask = original_collision_mask if active else 0
	if status_effects != null:
		status_effects.set_process(active)
	if active:
		if not is_in_group("damageable"):
			add_to_group("damageable")
		if combat_faction == CombatRules.Faction.FRIENDLY and receives_aim_influence and not is_in_group("aim_influence_receiver"):
			add_to_group("aim_influence_receiver")
		reset_target()
	else:
		set_auto_attack_enabled(false)
		if is_in_group("damageable"):
			remove_from_group("damageable")
		if is_in_group("aim_influence_receiver"):
			remove_from_group("aim_influence_receiver")
		knockback_velocity = Vector2.ZERO


func _health_text() -> String:
	var effect_text := ""
	if status_effects != null and not status_effects.active_effects.is_empty():
		effect_text += " · 状态：%s" % status_effects.get_effects_text()
	if combat_faction == CombatRules.Faction.FRIENDLY and (not is_zero_approx(external_aim_sway_angle) or not is_zero_approx(external_sneeze_offset)):
		effect_text += " · 芥末瞄准干扰"
	if auto_attack_available:
		effect_text += " · 自动攻击：%s" % ("开" if auto_attack_enabled else "关")
	return "HP %.0f / %.0f%s" % [current_health, max_health, effect_text]


func _get_color() -> Color:
	return Color("bd4b4b") if combat_faction == CombatRules.Faction.ENEMY else Color("4fa36c")
