class_name StatusEffectData
extends Resource

enum EffectType {
	POISON,
	MOVE_SLOW,
	ATTACK_SPEED_SLOW,
	WEAKNESS,
	VULNERABILITY,
	AIM_DISRUPTION,
	DIRECT_ATTACK_BONUS,
	DAMAGE_REDUCTION,
	HEAL_OVER_TIME,
}

var effect_type: int = EffectType.POISON
var damage_per_tick: float = 0.0
var tick_interval: float = 1.0
var duration: float = 0.0
var source_faction: int = CombatRules.Faction.PLAYER
var refresh_duration: bool = true
var attack_form: int = ItemData.AttackForm.DAMAGE_OVER_TIME
var cooking_method: int = ItemData.CookingMethod.NONE
var source_id: Variant
var magnitude: float = 0.0


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
	copy.source_id = source_id
	copy.magnitude = magnitude
	return copy


func get_display_name() -> String:
	match effect_type:
		EffectType.POISON:
			return "毒"
		EffectType.MOVE_SLOW:
			return "减速"
		EffectType.ATTACK_SPEED_SLOW:
			return "攻击变慢"
		EffectType.WEAKNESS:
			return "虚弱"
		EffectType.VULNERABILITY:
			return "易伤"
		EffectType.AIM_DISRUPTION:
			return "失瞄"
		EffectType.DIRECT_ATTACK_BONUS:
			return "直接攻击增强"
		EffectType.DAMAGE_REDUCTION:
			return "免伤"
		EffectType.HEAL_OVER_TIME:
			return "持续恢复"
	return "持续效果"
