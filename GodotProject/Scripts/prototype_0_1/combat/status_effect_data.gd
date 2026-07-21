class_name StatusEffectData
extends Resource

enum EffectType {
	POISON,
}

var effect_type: int = EffectType.POISON
var damage_per_tick: float = 0.0
var tick_interval: float = 1.0
var duration: float = 0.0
var source_faction: int = CombatRules.Faction.PLAYER
var refresh_duration: bool = true
var attack_form: int = ItemData.AttackForm.DAMAGE_OVER_TIME
var cooking_method: int = ItemData.CookingMethod.NONE


func copy_effect() -> StatusEffectData:
	var copy := StatusEffectData.new()
	copy.effect_type = effect_type
	copy.damage_per_tick = damage_per_tick
	copy.tick_interval = tick_interval
	copy.duration = duration
	copy.source_faction = source_faction
	copy.refresh_duration = refresh_duration
	copy.attack_form = attack_form
	copy.cooking_method = cooking_method
	return copy


func get_display_name() -> String:
	match effect_type:
		EffectType.POISON:
			return "毒"
	return "持续效果"
