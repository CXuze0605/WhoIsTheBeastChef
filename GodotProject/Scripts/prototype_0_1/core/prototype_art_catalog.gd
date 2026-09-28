class_name PrototypeArtCatalog
extends RefCounted


const TEXTURES := {
	&"ingredient_cabinet": preload("res://Assets/Prototype/Static/ingredient_cabinet.png"),
	&"prep_counter": preload("res://Assets/Prototype/Static/prep_counter.png"),
	&"marinating_bowl": preload("res://Assets/Prototype/Static/marinating_bowl.png"),
	&"stove_station_double": preload("res://Assets/Prototype/Static/stove_station_double.png"),
	&"washing_station": preload("res://Assets/Prototype/Static/washing_station.png"),
	&"clean_plate_stack": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/containers/container_clean_plate.png"),
	&"trash_bin": preload("res://Assets/VisualLock/Workstations/workstation_trash_bin_static_v1.png"),
	&"dirty_plate": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/containers/container_dirty_plate.png"),
	&"basic_taste_enemy": preload("res://Assets/Prototype/Static/basic_taste_enemy.png"),
	&"heavy_taste_enemy": preload("res://Assets/Prototype/Static/heavy_taste_enemy.png"),
	&"normal_bull": preload("res://Assets/Prototype/Static/normal_bull.png"),
	&"raging_bull": preload("res://Assets/Prototype/Static/raging_bull.png"),
	&"enemy_dummy": preload("res://Assets/Prototype/Static/enemy_dummy.png"),
	&"friendly_dummy": preload("res://Assets/Prototype/Static/friendly_dummy.png"),
	&"raw_beef_chunk": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_raw_beef_chunk_3x3.png"),
	&"raw_steak": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_raw_steak_3x1.png"),
	&"tomahawk_steak": preload("res://Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready/weapon_tomahawk_steak_normal.png"),
	&"tomahawk_steak_perfect": preload("res://Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready/weapon_tomahawk_steak_perfect.png"),
	&"big_bone": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/weapons/weapon_big_bone.png"),
	&"raw_beef_slice_single": preload("res://Assets/Prototype/Static/raw_beef_slice_single.png"),
	&"raw_beef_slices": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_raw_beef_slices_1x1.png"),
	&"marinated_beef_slices": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_marinated_beef_slices_1x1.png"),
	&"shabu_beef_single": preload("res://Assets/Prototype/Static/shabu_beef_single.png"),
	&"shabu_beef_slices": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_shabu_beef_slices.png"),
	&"marinade": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_marinade_seasoning.png"),
	&"mustard": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_mustard_sauce.png"),
	&"chili_segment": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_chili_segments.png"),
	&"charcoal": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_charcoal.png"),
	&"cooking_oil_bottle": preload("res://Assets/Prototype/Static/cooking_oil_bottle.png"),
	&"salt_bottle": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_salt_shaker.png"),
	&"stir_fry_beef_unplated": preload("res://Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready/dish_stir_fry_beef_unplated.png"),
	&"stir_fry_beef_plated": preload("res://Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready/dish_stir_fry_beef_plated.png"),
	&"frying_pan": preload("res://Assets/Prototype/Static/frying_pan.png"),
	&"wok": preload("res://Assets/Prototype/Static/wok.png"),
	&"soup_pot": preload("res://Assets/Prototype/Static/soup_pot.png"),
	&"mushy_boiled_beef": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/failed_mushy_boiled_beef.png"),
	# Prototype-only rotten fallback. The freshness UI adds the grey-green
	# overlay and source-shape mask; dedicated rotten art remains future work.
	&"rotten_waste": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/failed_mushy_boiled_beef.png"),
	&"raw_rice": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_uncooked_rice.png"),
	&"whole_greens": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_whole_greens.png"),
	&"greens_leaf": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_greens_leaf.png"),
	&"raw_beef_dice": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_raw_beef_cubes.png"),
	&"marinated_beef_dice": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/ingredient_marinated_beef_cubes.png"),
	&"rice_bag_large": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/resource_rice_bag_large_starting.png"),
	&"rice_bag_small": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/ingredients/resource_rice_bag_small_enemy_drop.png"),
	&"white_rice_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_plain_white_rice_unplated.png"),
	&"white_rice_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_plain_white_rice_plated.png"),
	&"crispy_rice_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_rice_crust_unplated.png"),
	&"crispy_rice_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_rice_crust_plated.png"),
	&"boiled_greens_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_salt_water_greens_unplated.png"),
	&"boiled_greens_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_salt_water_greens_plated.png"),
	&"stir_fry_greens_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_clear_stir_fried_greens_unplated.png"),
	&"stir_fry_greens_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_clear_stir_fried_greens_plated.png"),
	&"spicy_stir_fry_greens_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_spicy_stir_fried_greens_unplated.png"),
	&"spicy_stir_fry_greens_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_spicy_stir_fried_greens_plated.png"),
	&"flash_stir_fry_greens_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_flash_stir_fried_greens_unplated.png"),
	&"flash_stir_fry_greens_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_flash_stir_fried_greens_plated.png"),
	&"rice_porridge_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_plain_congee_unplated.png"),
	&"rice_porridge_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_plain_congee_plated.png"),
	&"greens_porridge_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_greens_congee_unplated.png"),
	&"greens_porridge_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_greens_congee_plated.png"),
	&"beef_porridge_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_beef_congee_unplated.png"),
	&"beef_porridge_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_beef_congee_plated.png"),
	&"plain_beef_porridge_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_unseasoned_beef_congee_unplated.png"),
	&"plain_beef_porridge_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_unseasoned_beef_congee_plated.png"),
	&"beef_greens_unplated": preload("res://Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready/dish_greens_beef_stir_fry_unplated.png"),
	&"beef_greens_plated": preload("res://Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready/dish_greens_beef_stir_fry_plated.png"),
	&"greens_fried_rice_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_greens_fried_rice_unplated.png"),
	&"greens_fried_rice_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_greens_fried_rice_plated.png"),
	&"beef_fried_rice_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_beef_fried_rice_unplated.png"),
	&"beef_fried_rice_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_beef_fried_rice_plated.png"),
	&"mixed_fried_rice_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_greens_beef_fried_rice_unplated.png"),
	&"mixed_fried_rice_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_greens_beef_fried_rice_plated.png"),
	&"vegetable_rice_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_vegetable_rice_unplated.png"),
	&"vegetable_rice_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_vegetable_rice_plated.png"),
	&"soaked_rice_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_plain_soaked_rice_unplated.png"),
	&"soaked_rice_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_plain_soaked_rice_plated.png"),
	&"greens_soaked_rice_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_greens_soaked_rice_unplated.png"),
	&"greens_soaked_rice_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_greens_soaked_rice_plated.png"),
	&"beef_greens_rice_bowl_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_beef_greens_rice_bowl_plated.png"),
	&"beef_greens_soup_unplated": preload("res://Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready/dish_greens_beef_soup_unplated.png"),
	&"beef_greens_soup_plated": preload("res://Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready/dish_greens_beef_soup_plated.png"),
	&"mustard_greens_unplated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_mustard_greens_unplated_selected_candidate42.png"),
	&"mustard_greens_plated": preload("res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready/dishes/dish_mustard_greens_plated_selected_candidate64.png"),
	# 2026-08-01 cookbook completion batch. Only plated variants are final in
	# this pass; existing unplated fallbacks remain until their own art pass.
	&"greens_beef_porridge_plated": preload("res://Assets/Items/ItemArtBatch2026_08_01/assets/ready/dish_greens_beef_porridge_plated.png"),
	&"fried_white_rice_plated": preload("res://Assets/Items/ItemArtBatch2026_08_01/assets/ready/dish_fried_white_rice_plated.png"),
	&"clear_stir_fry_beef_plated": preload("res://Assets/Items/ItemArtBatch2026_08_01/assets/ready/dish_clear_stir_fry_beef_plated.png"),
	&"greens_soup_plated": preload("res://Assets/Items/ItemArtBatch2026_08_01/assets/ready/dish_greens_soup_plated.png"),
	&"beef_soup_plated": preload("res://Assets/Items/ItemArtBatch2026_08_01/assets/ready/dish_beef_soup_plated.png"),
	# 2026-07-30 missing-recipe art batch. These are deliberately keyed by
	# ItemType mappings in ItemCatalog rather than translated display names.
	&"greens_rice_bowl_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_rice_bowl_unplated.png"),
	&"greens_rice_bowl_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_rice_bowl_plated.png"),
	&"beef_rice_bowl_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_beef_rice_bowl_unplated.png"),
	&"beef_rice_bowl_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_beef_rice_bowl_plated.png"),
	&"beef_braised_rice_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_beef_braised_rice_unplated.png"),
	&"beef_braised_rice_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_beef_braised_rice_plated.png"),
	&"greens_beef_braised_rice_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_beef_braised_rice_unplated.png"),
	&"greens_beef_braised_rice_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_beef_braised_rice_plated.png"),
	&"greens_beef_congee_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_beef_congee_unplated.png"),
	&"greens_beef_congee_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_beef_congee_plated.png"),
	&"beef_soaked_rice_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_beef_soaked_rice_unplated.png"),
	&"beef_soaked_rice_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_beef_soaked_rice_plated.png"),
	&"greens_beef_soaked_rice_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_beef_soaked_rice_unplated.png"),
	&"greens_beef_soaked_rice_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_beef_soaked_rice_plated.png"),
	&"crispy_rice_beef_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_crispy_rice_beef_unplated.png"),
	&"crispy_rice_beef_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_crispy_rice_beef_plated.png"),
	&"spicy_fried_rice_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_fried_rice_unplated.png"),
	&"spicy_fried_rice_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_fried_rice_plated.png"),
	&"spicy_greens_beef_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_greens_beef_stir_fry_unplated.png"),
	&"spicy_greens_beef_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_greens_beef_stir_fry_plated.png"),
	&"spicy_beef_fried_rice_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_beef_fried_rice_unplated.png"),
	&"spicy_beef_fried_rice_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_beef_fried_rice_plated.png"),
	&"spicy_mixed_fried_rice_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_mixed_fried_rice_unplated.png"),
	&"spicy_mixed_fried_rice_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_mixed_fried_rice_plated.png"),
	&"spicy_beef_soup_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_beef_soup_unplated.png"),
	&"spicy_beef_soup_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_beef_soup_plated.png"),
	&"spicy_greens_beef_soup_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_greens_beef_soup_unplated.png"),
	&"spicy_greens_beef_soup_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_spicy_greens_beef_soup_plated.png"),
	&"plain_rice_cake_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_plain_rice_cake_unplated.png"),
	&"plain_rice_cake_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_plain_rice_cake_plated.png"),
	&"greens_rice_cake_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_rice_cake_unplated.png"),
	&"greens_rice_cake_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_rice_cake_plated.png"),
	&"beef_rice_cake_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_beef_rice_cake_unplated.png"),
	&"beef_rice_cake_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_beef_rice_cake_plated.png"),
	&"greens_beef_rice_cake_unplated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_beef_rice_cake_unplated.png"),
	&"greens_beef_rice_cake_plated": preload("res://Assets/Items/ItemArtBatch2026_07_30/assets/ready/dish_greens_beef_rice_cake_plated.png"),
	&"player_walk_sheet": preload("res://Assets/Prototype/Animation/Characters/player_walk_sheet.png"),
	&"basic_taste_enemy_walk_sheet": preload("res://Assets/Prototype/Animation/Characters/basic_taste_enemy_walk_sheet.png"),
	&"heavy_taste_enemy_walk_sheet": preload("res://Assets/Prototype/Animation/Characters/heavy_taste_enemy_walk_sheet.png"),
	&"fast_taste_enemy_walk_sheet": preload("res://Assets/Prototype/Animation/Characters/fast_taste_enemy_walk_sheet.png"),
}

# V3 item art is already exported to its intended transparent game canvas.
# Source-region cropping remains available for future assets, but the accepted
# 64×96 tomahawks must use their complete textures.
const UI_SOURCE_REGIONS := {}


static func apply_to(visual: PlaceholderVisual, art_key: StringName) -> void:
	if visual == null:
		return
	var texture := TEXTURES.get(art_key) as Texture2D
	visual.set_art(texture)


static func get_ui_source_rect(art_key: StringName, texture: Texture2D) -> Rect2:
	if texture == null:
		return Rect2()
	if UI_SOURCE_REGIONS.has(art_key):
		return UI_SOURCE_REGIONS[art_key] as Rect2
	return Rect2(Vector2.ZERO, texture.get_size())
