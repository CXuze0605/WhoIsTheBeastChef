class_name DamageContext
extends RefCounted

enum SourceType {
	PLAYER_DIRECT_MELEE,
	PLAYER_DIRECT_RANGED,
	TURRET,
	SUMMON,
	TRAP,
	DAMAGE_OVER_TIME,
	STATUS_TRIGGER,
	AUTO_DISH_EQUIPMENT,
	ENVIRONMENT,
	FRIENDLY_FIRE,
	ENEMY_ATTACK,
}

var source_entity: Node
var source_dish: ItemData
var source_type: int = SourceType.ENVIRONMENT
var attacker_faction: int = CombatRules.Faction.ENEMY
var target_faction: int = CombatRules.Faction.PLAYER
var base_damage: float = 0.0
var quality_multiplier: float = 1.0
var friendly_fire: bool = false
var allow_direct_attack_bonus: bool = false
var affected_by_weakness: bool = true
var affected_by_vulnerability: bool = true
var affected_by_damage_reduction: bool = true
var actual_shield_damage: float = 0.0
var actual_health_damage: float = 0.0
var final_damage_before_defense: float = 0.0


static func from_legacy(
	damage: float,
	attacker: int,
	target: int,
	allow_friendly_fire: bool,
	entity: Node = null
) -> DamageContext:
	var context := DamageContext.new()
	context.source_entity = entity
	context.attacker_faction = attacker
	context.target_faction = target
	context.base_damage = maxf(0.0, damage)
	context.friendly_fire = allow_friendly_fire
	context.source_type = SourceType.ENEMY_ATTACK if attacker == CombatRules.Faction.ENEMY else SourceType.PLAYER_DIRECT_RANGED
	# Legacy attacks keep their existing numbers. New attacks opt into direct bonuses
	# explicitly so old projectiles do not change behavior without a source entity.
	context.allow_direct_attack_bonus = entity != null and attacker == CombatRules.Faction.PLAYER
	return context


func is_player_direct_damage() -> bool:
	return source_type in [SourceType.PLAYER_DIRECT_MELEE, SourceType.PLAYER_DIRECT_RANGED]


func get_actual_damage() -> float:
	return actual_shield_damage + actual_health_damage

