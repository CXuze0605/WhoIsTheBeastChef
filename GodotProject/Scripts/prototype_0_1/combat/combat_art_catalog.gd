class_name CombatArtCatalog
extends RefCounted


const ROOT := "res://Assets/Combat/DishEffects2026_07_30"

const TEXTURES := {
	&"rice_grain": preload(ROOT + "/fx_rice_grain_projectile.png"),
	&"greens_leaf": preload(ROOT + "/fx_greens_leaf_projectile.png"),
	&"beef_projectile": preload(ROOT + "/fx_beef_projectile.png"),
	&"spicy_rice": preload(ROOT + "/fx_spicy_rice_projectile.png"),
	&"ranged_leftovers": preload(ROOT + "/fx_ranged_leftovers_projectile.png"),
	&"ranged_leftovers_impact": preload(ROOT + "/fx_ranged_leftovers_impact.png"),
	&"crispy_beef_bomb_large": preload(ROOT + "/fx_crispy_rice_beef_bomb_large.png"),
	&"crispy_beef_bomb_small": preload(ROOT + "/fx_crispy_rice_beef_bomb_small.png"),
	&"rice_cake_plain": preload(ROOT + "/fx_rice_cake_plain.png"),
	&"rice_cake_greens": preload(ROOT + "/fx_rice_cake_greens.png"),
	&"rice_cake_beef": preload(ROOT + "/fx_rice_cake_beef.png"),
	&"rice_cake_greens_beef": preload(ROOT + "/fx_rice_cake_greens_beef.png"),
	&"soup_stream_beef": preload(ROOT + "/fx_soup_stream_beef.png"),
	&"soup_stream_greens_beef": preload(ROOT + "/fx_soup_stream_greens_beef.png"),
	&"soup_stream_spicy": preload(ROOT + "/fx_soup_stream_spicy.png"),
}

const CRISPY_BEEF_EXPLOSION_FRAMES: Array[Texture2D] = [
	preload(ROOT + "/fx_crispy_rice_beef_explosion/frame_000.png"),
	preload(ROOT + "/fx_crispy_rice_beef_explosion/frame_001.png"),
	preload(ROOT + "/fx_crispy_rice_beef_explosion/frame_002.png"),
	preload(ROOT + "/fx_crispy_rice_beef_explosion/frame_003.png"),
	preload(ROOT + "/fx_crispy_rice_beef_explosion/frame_004.png"),
	preload(ROOT + "/fx_crispy_rice_beef_explosion/frame_005.png"),
	preload(ROOT + "/fx_crispy_rice_beef_explosion/frame_006.png"),
	preload(ROOT + "/fx_crispy_rice_beef_explosion/frame_007.png"),
	preload(ROOT + "/fx_crispy_rice_beef_explosion/frame_008.png"),
]


static func get_texture(key: StringName) -> Texture2D:
	return TEXTURES.get(key) as Texture2D

