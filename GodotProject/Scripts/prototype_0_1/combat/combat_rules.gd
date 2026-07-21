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
