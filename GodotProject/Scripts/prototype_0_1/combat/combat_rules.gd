class_name CombatRules
extends RefCounted

enum Faction {
	PLAYER,
	ENEMY,
	FRIENDLY,
}


static func can_damage(attacker_faction: int, target_faction: int, friendly_fire: bool) -> bool:
	if friendly_fire:
		return target_faction in [Faction.PLAYER, Faction.ENEMY, Faction.FRIENDLY]
	match attacker_faction:
		Faction.PLAYER, Faction.FRIENDLY:
			return target_faction == Faction.ENEMY
		Faction.ENEMY:
			return target_faction in [Faction.PLAYER, Faction.FRIENDLY]
	return false


static func resolve_damage(context: DamageContext, target: Node) -> float:
	if context == null or target == null:
		return 0.0
	var damage := maxf(0.0, context.base_damage) * maxf(0.0, context.quality_multiplier)
	if context.source_entity != null and is_instance_valid(context.source_entity):
		var source_status := context.source_entity.get_node_or_null("CombatStatusController") as CombatStatusController
		if source_status != null:
			damage *= source_status.get_outgoing_damage_multiplier(
				context.source_type,
				context.allow_direct_attack_bonus and context.is_player_direct_damage()
			)
	var target_status := target.get_node_or_null("CombatStatusController") as CombatStatusController
	if target_status != null:
		damage *= target_status.get_incoming_damage_multiplier(
			context.affected_by_vulnerability,
			context.affected_by_damage_reduction
		)
	context.final_damage_before_defense = maxf(0.0, damage)
	return context.final_damage_before_defense
