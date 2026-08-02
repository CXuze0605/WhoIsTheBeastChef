extends SceneTree

const ITEM_ROOT := "res://Assets/Items/ItemArtBatch2026_07_30/assets/ready"
const CHARACTER_ROOT := "res://Assets/Characters/Enemies/RangedTasteEnemy01"

const EXPECTED_ITEM_KEYS := {
	ItemData.ItemType.UNPLATED_GREENS_RICE_BOWL: &"greens_rice_bowl_unplated",
	ItemData.ItemType.PLATED_GREENS_RICE_BOWL: &"greens_rice_bowl_plated",
	ItemData.ItemType.UNPLATED_BEEF_RICE_BOWL: &"beef_rice_bowl_unplated",
	ItemData.ItemType.PLATED_BEEF_RICE_BOWL: &"beef_rice_bowl_plated",
	ItemData.ItemType.UNPLATED_BEEF_BRAISED_RICE: &"beef_braised_rice_unplated",
	ItemData.ItemType.PLATED_BEEF_BRAISED_RICE: &"beef_braised_rice_plated",
	ItemData.ItemType.UNPLATED_GREENS_BEEF_BRAISED_RICE: &"greens_beef_braised_rice_unplated",
	ItemData.ItemType.PLATED_GREENS_BEEF_BRAISED_RICE: &"greens_beef_braised_rice_plated",
	ItemData.ItemType.UNPLATED_GREENS_BEEF_PORRIDGE: &"greens_beef_congee_unplated",
	ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE: &"greens_beef_porridge_plated",
	ItemData.ItemType.UNPLATED_BEEF_SOAKED_RICE: &"beef_soaked_rice_unplated",
	ItemData.ItemType.PLATED_BEEF_SOAKED_RICE: &"beef_soaked_rice_plated",
	ItemData.ItemType.UNPLATED_GREENS_BEEF_SOAKED_RICE: &"greens_beef_soaked_rice_unplated",
	ItemData.ItemType.PLATED_GREENS_BEEF_SOAKED_RICE: &"greens_beef_soaked_rice_plated",
	ItemData.ItemType.UNPLATED_CRISPY_RICE_BEEF: &"crispy_rice_beef_unplated",
	ItemData.ItemType.PLATED_CRISPY_RICE_BEEF: &"crispy_rice_beef_plated",
	ItemData.ItemType.UNPLATED_SPICY_FRIED_RICE: &"spicy_fried_rice_unplated",
	ItemData.ItemType.PLATED_SPICY_FRIED_RICE: &"spicy_fried_rice_plated",
	ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS: &"spicy_greens_beef_unplated",
	ItemData.ItemType.PLATED_SPICY_BEEF_GREENS: &"spicy_greens_beef_plated",
	ItemData.ItemType.UNPLATED_SPICY_BEEF_FRIED_RICE: &"spicy_beef_fried_rice_unplated",
	ItemData.ItemType.PLATED_SPICY_BEEF_FRIED_RICE: &"spicy_beef_fried_rice_plated",
	ItemData.ItemType.UNPLATED_SPICY_MIXED_FRIED_RICE: &"spicy_mixed_fried_rice_unplated",
	ItemData.ItemType.PLATED_SPICY_MIXED_FRIED_RICE: &"spicy_mixed_fried_rice_plated",
	ItemData.ItemType.UNPLATED_SPICY_BEEF_SOUP: &"spicy_beef_soup_unplated",
	ItemData.ItemType.PLATED_SPICY_BEEF_SOUP: &"spicy_beef_soup_plated",
	ItemData.ItemType.UNPLATED_SPICY_BEEF_GREENS_SOUP: &"spicy_greens_beef_soup_unplated",
	ItemData.ItemType.PLATED_SPICY_BEEF_GREENS_SOUP: &"spicy_greens_beef_soup_plated",
	ItemData.ItemType.UNPLATED_PAN_FRIED_RICE_CAKE: &"plain_rice_cake_unplated",
	ItemData.ItemType.PLATED_PAN_FRIED_RICE_CAKE: &"plain_rice_cake_plated",
	ItemData.ItemType.UNPLATED_GREENS_RICE_CAKE: &"greens_rice_cake_unplated",
	ItemData.ItemType.PLATED_GREENS_RICE_CAKE: &"greens_rice_cake_plated",
	ItemData.ItemType.UNPLATED_BEEF_RICE_CAKE: &"beef_rice_cake_unplated",
	ItemData.ItemType.PLATED_BEEF_RICE_CAKE: &"beef_rice_cake_plated",
	ItemData.ItemType.UNPLATED_GREENS_BEEF_RICE_CAKE: &"greens_beef_rice_cake_unplated",
	ItemData.ItemType.PLATED_GREENS_BEEF_RICE_CAKE: &"greens_beef_rice_cake_plated",
}

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_item_mappings()
	_test_combat_art()
	_test_ranged_character_frames()
	if failures.is_empty():
		print("PROTOTYPE_ART_BATCH_2026_07_30_TEST: PASS (3/3 groups)")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROTOTYPE_ART_BATCH_2026_07_30_TEST: FAIL (%d)" % failures.size())
	quit(1)


func _test_item_mappings() -> void:
	_expect(EXPECTED_ITEM_KEYS.size() == 36, "item batch must cover 18 unplated/plated pairs")
	for item_type in EXPECTED_ITEM_KEYS:
		var key: StringName = EXPECTED_ITEM_KEYS[item_type]
		_expect(ItemCatalog.get_art_key(item_type) == key, "incorrect item-art key: %s" % key)
		_expect(PrototypeArtCatalog.TEXTURES.has(key), "art key not registered: %s" % key)
		_expect(PrototypeArtCatalog.TEXTURES.get(key) is Texture2D, "art texture failed to load: %s" % key)
	var png_count := 0
	for file_name in DirAccess.get_files_at(ITEM_ROOT):
		if file_name.ends_with(".png"):
			png_count += 1
	_expect(png_count == 36, "item batch must contain exactly 36 runtime PNGs")


func _test_combat_art() -> void:
	_expect(CombatArtCatalog.TEXTURES.size() == 15, "combat catalog must register 15 static sprites")
	for key in CombatArtCatalog.TEXTURES:
		_expect(CombatArtCatalog.get_texture(key) != null, "combat texture failed to load: %s" % key)
	_expect(CombatArtCatalog.CRISPY_BEEF_EXPLOSION_FRAMES.size() == 9, "crispy beef explosion needs 9 frames")
	for texture in CombatArtCatalog.CRISPY_BEEF_EXPLOSION_FRAMES:
		_expect(texture != null, "crispy beef explosion contains a missing frame")


func _test_ranged_character_frames() -> void:
	var animator := RangedEnemyCharacterAnimator.new()
	var frames := animator.build_sprite_frames()
	for direction in RangedEnemyCharacterAnimator.DIRECTIONS:
		_expect(frames.get_frame_count(StringName("idle_%s" % direction)) == 1, "missing ranged idle: %s" % direction)
		_expect(frames.get_frame_count(StringName("walk_%s" % direction)) == 8, "missing ranged walk loop: %s" % direction)
		_expect(frames.get_frame_count(StringName("attack_%s" % direction)) == 11, "missing ranged attack: %s" % direction)
	_expect(frames.get_frame_count(&"defeat_south") == 7, "ranged defeat must use the seven-frame south animation")
	_expect(not frames.has_animation(&"defeat_east"), "ordinary defeat must not require directional variants")
	_expect(ResourceLoader.exists(CHARACTER_ROOT + "/rotations/south.png"), "ranged south identity anchor is missing")
	animator.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
