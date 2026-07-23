class_name PrototypeArtCatalog
extends RefCounted


const TEXTURES := {
	&"ingredient_cabinet": preload("res://Assets/Prototype/Static/ingredient_cabinet.png"),
	&"prep_counter": preload("res://Assets/Prototype/Static/prep_counter.png"),
	&"marinating_bowl": preload("res://Assets/Prototype/Static/marinating_bowl.png"),
	&"stove_station_double": preload("res://Assets/Prototype/Static/stove_station_double.png"),
	&"washing_station": preload("res://Assets/Prototype/Static/washing_station.png"),
	&"clean_plate_stack": preload("res://Assets/Prototype/Static/clean_plate_stack.png"),
	&"dirty_plate": preload("res://Assets/Prototype/Static/dirty_plate.png"),
	&"basic_taste_enemy": preload("res://Assets/Prototype/Static/basic_taste_enemy.png"),
	&"heavy_taste_enemy": preload("res://Assets/Prototype/Static/heavy_taste_enemy.png"),
	&"normal_bull": preload("res://Assets/Prototype/Static/normal_bull.png"),
	&"raging_bull": preload("res://Assets/Prototype/Static/raging_bull.png"),
	&"enemy_dummy": preload("res://Assets/Prototype/Static/enemy_dummy.png"),
	&"friendly_dummy": preload("res://Assets/Prototype/Static/friendly_dummy.png"),
	&"raw_beef_chunk": preload("res://Assets/Prototype/Static/raw_beef_chunk.png"),
	&"raw_steak": preload("res://Assets/Prototype/Static/raw_steak.png"),
	&"tomahawk_steak": preload("res://Assets/Prototype/Static/tomahawk_steak.png"),
	&"raw_beef_slice_single": preload("res://Assets/Prototype/Static/raw_beef_slice_single.png"),
	&"raw_beef_slices": preload("res://Assets/Prototype/Static/raw_beef_slices.png"),
	&"shabu_beef_single": preload("res://Assets/Prototype/Static/shabu_beef_single.png"),
	&"shabu_beef_slices": preload("res://Assets/Prototype/Static/shabu_beef_slices.png"),
	&"marinade": preload("res://Assets/Prototype/Static/marinade.png"),
	&"mustard": preload("res://Assets/Prototype/Static/mustard.png"),
	&"chili_segment": preload("res://Assets/Prototype/Static/chili_segment.png"),
	&"cooking_oil_bottle": preload("res://Assets/Prototype/Static/cooking_oil_bottle.png"),
	&"salt_bottle": preload("res://Assets/Prototype/Static/salt_bottle.png"),
	&"plated_stir_fry_beef": preload("res://Assets/Prototype/Static/plated_stir_fry_beef.png"),
	&"frying_pan": preload("res://Assets/Prototype/Static/frying_pan.png"),
	&"wok": preload("res://Assets/Prototype/Static/wok.png"),
	&"soup_pot": preload("res://Assets/Prototype/Static/soup_pot.png"),
	&"player_walk_sheet": preload("res://Assets/Prototype/Animation/Characters/player_walk_sheet.png"),
	&"basic_taste_enemy_walk_sheet": preload("res://Assets/Prototype/Animation/Characters/basic_taste_enemy_walk_sheet.png"),
	&"heavy_taste_enemy_walk_sheet": preload("res://Assets/Prototype/Animation/Characters/heavy_taste_enemy_walk_sheet.png"),
	&"fast_taste_enemy_walk_sheet": preload("res://Assets/Prototype/Animation/Characters/fast_taste_enemy_walk_sheet.png"),
}


static func apply_to(visual: PlaceholderVisual, art_key: StringName) -> void:
	if visual == null:
		return
	var texture := TEXTURES.get(art_key) as Texture2D
	visual.set_art(texture)
