class_name DebugCombatTarget
extends CharacterBody2D

@export var combat_faction: int = CombatRules.Faction.ENEMY
@export var max_health: float = 120.0
@export var debug_title: String = "敌方测试假人"

var current_health: float
var knockback_velocity := Vector2.ZERO
var hit_flash_time: float = 0.0
var placeholder: PlaceholderVisual
var status_effects: DamageOverTimeController
var external_aim_sway_angle: float = 0.0
var external_sneeze_offset: float = 0.0
var receives_aim_influence: bool = true


func _ready() -> void:
	current_health = max_health
	add_to_group("damageable")
	add_to_group("debug_combat_target")
	if combat_faction == CombatRules.Faction.FRIENDLY and receives_aim_influence:
		add_to_group("aim_influence_receiver")
	status_effects = DamageOverTimeController.new()
	status_effects.name = "DamageOverTimeController"
	add_child(status_effects)
	placeholder = PlaceholderVisual.new()
	add_child(placeholder)
	placeholder.configure(Vector2(74.0, 64.0), _get_color(), debug_title, _health_text())


func _physics_process(delta: float) -> void:
	velocity = knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	hit_flash_time = maxf(0.0, hit_flash_time - delta)
	if placeholder != null:
		placeholder.set_color(Color.WHITE if hit_flash_time > 0.0 else _get_color())
		placeholder.set_status(_health_text())


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
	if not CombatRules.can_damage(attacker_faction, combat_faction, friendly_fire):
		return false
	current_health = maxf(0.0, current_health - damage)
	knockback_velocity += knockback_direction.normalized() * knockback_force
	hit_flash_time = 0.12
	return true


func apply_status_effect(effect: StatusEffectData) -> bool:
	return status_effects.apply_effect(effect) if status_effects != null else false


func receive_status_damage(damage: float, attacker_faction: int, _effect_type: int) -> bool:
	if not CombatRules.can_damage(attacker_faction, combat_faction, false):
		return false
	current_health = maxf(0.0, current_health - damage)
	hit_flash_time = 0.18
	return true


func set_external_aim_influence(_source_id: int, sway_angle: float, sneeze_offset: float, active: bool) -> void:
	external_aim_sway_angle = sway_angle if active else 0.0
	external_sneeze_offset = sneeze_offset if active else 0.0


func reset_target() -> void:
	current_health = max_health
	knockback_velocity = Vector2.ZERO


func _health_text() -> String:
	var effect_text := ""
	if status_effects != null and not status_effects.active_effects.is_empty():
		effect_text += " · 状态：%s" % status_effects.get_effects_text()
	if combat_faction == CombatRules.Faction.FRIENDLY and (not is_zero_approx(external_aim_sway_angle) or not is_zero_approx(external_sneeze_offset)):
		effect_text += " · 芥末瞄准干扰"
	return "HP %.0f / %.0f%s" % [current_health, max_health, effect_text]


func _get_color() -> Color:
	return Color("bd4b4b") if combat_faction == CombatRules.Faction.ENEMY else Color("4fa36c")
