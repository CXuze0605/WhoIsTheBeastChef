class_name PrototypeArtCatalog
extends RefCounted


const TEXTURES := {
	&"ingredient_cabinet": preload("res://Assets/Prototype/Static/ingredient_cabinet.png"),
	&"prep_counter": preload("res://Assets/Prototype/Static/prep_counter.png"),
	&"marinating_bowl": preload("res://Assets/Prototype/Static/marinating_bowl.png"),
	&"stove_station_double": preload("res://Assets/Prototype/Static/stove_station_double.png"),
	&"washing_station": preload("res://Assets/Prototype/Static/washing_station.png"),
	&"clean_plate_stack": preload("res://Assets/Prototype/Static/clean_plate_stack.png"),
	&"basic_taste_enemy": preload("res://Assets/Prototype/Static/basic_taste_enemy.png"),
	&"raw_steak": preload("res://Assets/Prototype/Static/raw_steak.png"),
	&"chili_segment": preload("res://Assets/Prototype/Static/chili_segment.png"),
	&"cooking_oil_bottle": preload("res://Assets/Prototype/Static/cooking_oil_bottle.png"),
	&"salt_bottle": preload("res://Assets/Prototype/Static/salt_bottle.png"),
	&"plated_stir_fry_beef": preload("res://Assets/Prototype/Static/plated_stir_fry_beef.png"),
	&"frying_pan": preload("res://Assets/Prototype/Static/frying_pan.png"),
	&"wok": preload("res://Assets/Prototype/Static/wok.png"),
	&"soup_pot": preload("res://Assets/Prototype/Static/soup_pot.png"),
}


static func apply_to(visual: PlaceholderVisual, art_key: StringName) -> void:
	if visual == null:
		return
	var texture := TEXTURES.get(art_key) as Texture2D
	visual.set_art(texture)
