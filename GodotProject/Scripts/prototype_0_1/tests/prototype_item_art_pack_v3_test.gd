extends SceneTree

const PACK_ROOT := "res://Assets/Items/ItemArtPack2026_07_29_v3/assets/ready"

const EXPECTED_V3_MAPPINGS := {
	ItemData.ItemType.RAW_BEEF_CHUNK: &"raw_beef_chunk",
	ItemData.ItemType.RAW_STEAK: &"raw_steak",
	ItemData.ItemType.RAW_BEEF_SLICES: &"raw_beef_slices",
	ItemData.ItemType.MARINATED_BEEF_SLICES: &"marinated_beef_slices",
	ItemData.ItemType.MARINADE: &"marinade",
	ItemData.ItemType.CHILI_SEGMENTS: &"chili_segment",
	ItemData.ItemType.CHARCOAL: &"charcoal",
	ItemData.ItemType.CLEAN_PLATE: &"clean_plate_stack",
	ItemData.ItemType.DIRTY_PLATE: &"dirty_plate",
	ItemData.ItemType.SALT: &"salt_bottle",
	ItemData.ItemType.MUSTARD: &"mustard",
	ItemData.ItemType.BIG_BONE: &"big_bone",
	ItemData.ItemType.SHABU_BEEF: &"shabu_beef_slices",
	ItemData.ItemType.MUSHY_BOILED_BEEF: &"mushy_boiled_beef",
	ItemData.ItemType.RICE_BAG: &"rice_bag_large",
	ItemData.ItemType.SMALL_RICE_BAG: &"rice_bag_small",
	ItemData.ItemType.RAW_RICE: &"raw_rice",
	ItemData.ItemType.UNPLATED_WHITE_RICE: &"white_rice_unplated",
	ItemData.ItemType.PLATED_WHITE_RICE: &"white_rice_plated",
	ItemData.ItemType.UNPLATED_RICE_PORRIDGE: &"rice_porridge_unplated",
	ItemData.ItemType.PLATED_RICE_PORRIDGE: &"rice_porridge_plated",
	ItemData.ItemType.UNPLATED_CRISPY_RICE: &"crispy_rice_unplated",
	ItemData.ItemType.PLATED_CRISPY_RICE: &"crispy_rice_plated",
	ItemData.ItemType.WHOLE_GREENS: &"whole_greens",
	ItemData.ItemType.GREENS_LEAF: &"greens_leaf",
	ItemData.ItemType.RAW_BEEF_DICE: &"raw_beef_dice",
	ItemData.ItemType.MARINATED_BEEF_DICE: &"marinated_beef_dice",
	ItemData.ItemType.UNPLATED_BOILED_GREENS: &"boiled_greens_unplated",
	ItemData.ItemType.PLATED_BOILED_GREENS: &"boiled_greens_plated",
	ItemData.ItemType.UNPLATED_STIR_FRY_GREENS: &"stir_fry_greens_unplated",
	ItemData.ItemType.PLATED_STIR_FRY_GREENS: &"stir_fry_greens_plated",
	ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS: &"spicy_stir_fry_greens_unplated",
	ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS: &"spicy_stir_fry_greens_plated",
	ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS: &"flash_stir_fry_greens_unplated",
	ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS: &"flash_stir_fry_greens_plated",
	ItemData.ItemType.UNPLATED_GREENS_PORRIDGE: &"greens_porridge_unplated",
	ItemData.ItemType.PLATED_GREENS_PORRIDGE: &"greens_porridge_plated",
	ItemData.ItemType.UNPLATED_BEEF_PORRIDGE: &"beef_porridge_unplated",
	ItemData.ItemType.PLATED_BEEF_PORRIDGE: &"beef_porridge_plated",
	ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE: &"plain_beef_porridge_unplated",
	ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE: &"plain_beef_porridge_plated",
	ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE: &"greens_fried_rice_unplated",
	ItemData.ItemType.PLATED_GREENS_FRIED_RICE: &"greens_fried_rice_plated",
	ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE: &"beef_fried_rice_unplated",
	ItemData.ItemType.PLATED_BEEF_FRIED_RICE: &"beef_fried_rice_plated",
	ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE: &"mixed_fried_rice_unplated",
	ItemData.ItemType.PLATED_MIXED_FRIED_RICE: &"mixed_fried_rice_plated",
	ItemData.ItemType.UNPLATED_VEGETABLE_RICE: &"vegetable_rice_unplated",
	ItemData.ItemType.PLATED_VEGETABLE_RICE: &"vegetable_rice_plated",
	ItemData.ItemType.UNPLATED_SOAKED_RICE: &"soaked_rice_unplated",
	ItemData.ItemType.PLATED_SOAKED_RICE: &"soaked_rice_plated",
	ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE: &"greens_soaked_rice_unplated",
	ItemData.ItemType.PLATED_GREENS_SOAKED_RICE: &"greens_soaked_rice_plated",
	ItemData.ItemType.PLATED_BEEF_GREENS_RICE_BOWL: &"beef_greens_rice_bowl_plated",
	ItemData.ItemType.UNPLATED_MUSTARD_GREENS: &"mustard_greens_unplated",
	ItemData.ItemType.PLATED_MUSTARD_GREENS: &"mustard_greens_plated",
}

const TRUE_MISSING_ART := []

const RETAINED_READY_FILES := [
	"ingredients/resource_rice_bag_small_enemy_drop.png",
	"containers/container_metal_prep_bowl.png",
	"containers/container_porcelain_deep_bowl.png",
	"containers/container_porcelain_shallow_bowl.png",
]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_all_current_item_types()
	await _test_v3_ready_asset_mappings()
	await _test_visual_state_separation()
	await _test_dynamic_variants()
	await _test_tomahawk_canvas_and_shape()
	await _test_shared_display_consumers()
	_test_import_and_source_policy()
	if failures.is_empty():
		print("PROTOTYPE_ITEM_ART_PACK_V3_TEST: PASS (7/7 groups)")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_ITEM_ART_PACK_V3_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_all_current_item_types() -> void:
	for item_type: int in ItemData.ItemType.values():
		var art_key := ItemCatalog.get_art_key(item_type)
		if TRUE_MISSING_ART.has(item_type):
			_expect(art_key == &"", "Coverage: true missing ItemType %d must remain an explicit placeholder" % item_type)
			continue
		_expect(art_key != &"", "Coverage: ItemType %d must have a centralized art key" % item_type)
		_expect(PrototypeArtCatalog.TEXTURES.get(art_key) is Texture2D, "Coverage: ItemType %d art key %s must load a texture" % [item_type, art_key])
	await process_frame


func _test_v3_ready_asset_mappings() -> void:
	_expect(EXPECTED_V3_MAPPINGS.size() == 56, "Mapping: exactly 56 current ItemTypes should keep their V3 art after the V4 correction")
	for item_type: int in EXPECTED_V3_MAPPINGS:
		var art_key: StringName = EXPECTED_V3_MAPPINGS[item_type]
		var texture := PrototypeArtCatalog.TEXTURES.get(art_key) as Texture2D
		_expect(ItemCatalog.get_art_key(item_type) == art_key, "Mapping: ItemType %d must use %s" % [item_type, art_key])
		_expect(texture != null and texture.resource_path.begins_with(PACK_ROOT), "Mapping: %s must resolve to V3 ready" % art_key)
	for relative_path: String in RETAINED_READY_FILES:
		_expect(FileAccess.file_exists("%s/%s" % [PACK_ROOT, relative_path]), "Retention: V3 ready file must be preserved: %s" % relative_path)
	await process_frame


func _test_visual_state_separation() -> void:
	var distinct_pairs := [
		[ItemData.ItemType.UNPLATED_WHITE_RICE, ItemData.ItemType.PLATED_WHITE_RICE],
		[ItemData.ItemType.UNPLATED_RICE_PORRIDGE, ItemData.ItemType.PLATED_RICE_PORRIDGE],
		[ItemData.ItemType.UNPLATED_CRISPY_RICE, ItemData.ItemType.PLATED_CRISPY_RICE],
		[ItemData.ItemType.UNPLATED_BOILED_GREENS, ItemData.ItemType.PLATED_BOILED_GREENS],
		[ItemData.ItemType.UNPLATED_STIR_FRY_GREENS, ItemData.ItemType.PLATED_STIR_FRY_GREENS],
		[ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS, ItemData.ItemType.PLATED_SPICY_STIR_FRY_GREENS],
		[ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS, ItemData.ItemType.PLATED_FLASH_STIR_FRY_GREENS],
		[ItemData.ItemType.UNPLATED_GREENS_PORRIDGE, ItemData.ItemType.PLATED_GREENS_PORRIDGE],
		[ItemData.ItemType.UNPLATED_BEEF_PORRIDGE, ItemData.ItemType.PLATED_BEEF_PORRIDGE],
		[ItemData.ItemType.UNPLATED_PLAIN_BEEF_PORRIDGE, ItemData.ItemType.PLATED_PLAIN_BEEF_PORRIDGE],
		[ItemData.ItemType.UNPLATED_GREENS_FRIED_RICE, ItemData.ItemType.PLATED_GREENS_FRIED_RICE],
		[ItemData.ItemType.UNPLATED_BEEF_FRIED_RICE, ItemData.ItemType.PLATED_BEEF_FRIED_RICE],
		[ItemData.ItemType.UNPLATED_MIXED_FRIED_RICE, ItemData.ItemType.PLATED_MIXED_FRIED_RICE],
		[ItemData.ItemType.UNPLATED_VEGETABLE_RICE, ItemData.ItemType.PLATED_VEGETABLE_RICE],
		[ItemData.ItemType.UNPLATED_SOAKED_RICE, ItemData.ItemType.PLATED_SOAKED_RICE],
		[ItemData.ItemType.UNPLATED_GREENS_SOAKED_RICE, ItemData.ItemType.PLATED_GREENS_SOAKED_RICE],
		[ItemData.ItemType.UNPLATED_MUSTARD_GREENS, ItemData.ItemType.PLATED_MUSTARD_GREENS],
	]
	for pair: Array in distinct_pairs:
		_expect(ItemCatalog.get_art_key(pair[0]) != ItemCatalog.get_art_key(pair[1]), "State art: unplated/plated pair %s must be distinct" % str(pair))
	var normal_key := ItemCatalog.get_art_key(ItemData.ItemType.UNPLATED_STIR_FRY_GREENS)
	var spicy_key := ItemCatalog.get_art_key(ItemData.ItemType.UNPLATED_SPICY_STIR_FRY_GREENS)
	var flash_key := ItemCatalog.get_art_key(ItemData.ItemType.UNPLATED_FLASH_STIR_FRY_GREENS)
	_expect(normal_key != spicy_key and normal_key != flash_key and spicy_key != flash_key, "State art: clear, spicy and flash stir-fried greens must not share art")
	await process_frame


func _test_dynamic_variants() -> void:
	var raw_slices := ItemCatalog.create(ItemData.ItemType.RAW_BEEF_SLICES)
	raw_slices.remaining_portions = 5
	_expect(ItemCatalog.get_art_key_for_data(raw_slices) == &"raw_beef_slices", "Dynamic art: grouped raw slices must use the V3 grouped image")
	raw_slices.remaining_portions = 1
	_expect(ItemCatalog.get_art_key_for_data(raw_slices) == &"raw_beef_slice_single", "Dynamic art: the last raw slice must keep the existing single image")
	var shabu := ItemCatalog.create(ItemData.ItemType.SHABU_BEEF)
	shabu.stack_count = 5
	_expect(ItemCatalog.get_art_key_for_data(shabu) == &"shabu_beef_slices", "Dynamic art: grouped shabu beef must use the V3 grouped image")
	shabu.stack_count = 1
	_expect(ItemCatalog.get_art_key_for_data(shabu) == &"shabu_beef_single", "Dynamic art: the last shabu serving must keep the existing single image")
	var unplated := ItemCatalog.create(ItemData.ItemType.TOMAHAWK_STEAK)
	unplated.quality = ItemData.Quality.PERFECT
	_expect(ItemCatalog.get_art_key_for_data(unplated) == &"tomahawk_steak", "Dynamic art: unplated tomahawk must never select perfect plated art")
	var plated := ItemCatalog.create(ItemData.ItemType.PLATED_TOMAHAWK_STEAK)
	plated.quality = ItemData.Quality.NORMAL
	_expect(ItemCatalog.get_art_key_for_data(plated) == &"tomahawk_steak", "Dynamic art: non-perfect plated tomahawk must use normal art")
	plated.quality = ItemData.Quality.PERFECT
	_expect(ItemCatalog.get_art_key_for_data(plated) == &"tomahawk_steak_perfect", "Dynamic art: only perfect plated tomahawk may use processed perfect art")
	await process_frame


func _test_tomahawk_canvas_and_shape() -> void:
	var normal := PrototypeArtCatalog.TEXTURES.get(&"tomahawk_steak") as Texture2D
	var perfect := PrototypeArtCatalog.TEXTURES.get(&"tomahawk_steak_perfect") as Texture2D
	var bone := PrototypeArtCatalog.TEXTURES.get(&"big_bone") as Texture2D
	_expect(normal != null and perfect != null and bone != null, "Tomahawk art: normal, perfect and big-bone textures must all load")
	_expect(normal != perfect and perfect != bone and normal != bone, "Tomahawk art: normal, perfect and big bone must not share textures")
	_expect(normal.get_size() == Vector2(64.0, 96.0), "Tomahawk art: normal texture must remain 64x96")
	_expect(perfect.get_size() == Vector2(64.0, 96.0), "Tomahawk art: corrected perfect texture must be 64x96")
	var perfect_image := perfect.get_image()
	_expect(
		perfect_image.get_pixel(0, 0).a == 0.0
		and perfect_image.get_pixel(63, 0).a == 0.0
		and perfect_image.get_pixel(0, 95).a == 0.0
		and perfect_image.get_pixel(63, 95).a == 0.0,
		"Tomahawk art: corrected perfect texture must retain a transparent background"
	)
	var expected_cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1),
		Vector2i(0, 2),
	]
	_expect(ItemStorageCatalog.get_shape_cells(ItemData.ItemType.TOMAHAWK_STEAK) == expected_cells, "Storage: normal tomahawk must use the 2/2/1 irregular mask")
	_expect(ItemStorageCatalog.get_shape_cells(ItemData.ItemType.PLATED_TOMAHAWK_STEAK) == expected_cells, "Storage: plated tomahawk must use the 2/2/1 irregular mask")
	_expect(ItemStorageCatalog.get_default_size(ItemData.ItemType.RAW_STEAK) == Vector2i(3, 1), "Storage: raw steak default direction must be horizontal 3x1")
	_expect(ItemStorageCatalog.get_shape_bounds(ItemStorageCatalog.get_shape_cells(ItemData.ItemType.RAW_STEAK, true)) == Vector2i(1, 3), "Storage: rotating raw steak must produce 1x3")
	await process_frame


func _test_shared_display_consumers() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var data := ItemCatalog.create(ItemData.ItemType.PLATED_BEEF_FRIED_RICE)
	var item := ItemFactory.create_carryable(data)
	holder.add_child(item)
	await process_frame
	var expected := PrototypeArtCatalog.TEXTURES.get(&"beef_fried_rice_plated") as Texture2D
	_expect(item.placeholder != null and item.placeholder.art_sprite.texture == expected, "Display: world/held CarryableItem must use the centralized V3 mapping")
	var quickbar := QuickInventoryUI.new()
	quickbar._build_ui()
	quickbar._refresh_slot_content(0, item)
	_expect(quickbar.slot_icons[0].texture == expected, "Display: quickbar icon must use the same centralized texture")
	var grid := GridInventory.new(4, 4, holder)
	_expect(grid.add_item_at(item, Vector2i.ZERO), "Display: mapped item must fit the inventory grid")
	var grid_view := InventoryGridView.new()
	grid_view.setup(grid, 32.0, "test")
	_expect(grid_view.get_item_art_source_rect(item) == Rect2(Vector2.ZERO, expected.get_size()), "Display: backpack/cabinet grid must use the complete centralized texture")
	_expect(grid_view.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Display: backpack/cabinet grid must force nearest-neighbor filtering")
	grid_view.queue_free()
	quickbar.queue_free()
	holder.queue_free()
	await process_frame


func _test_import_and_source_policy() -> void:
	for art_key: StringName in PrototypeArtCatalog.TEXTURES:
		var texture := PrototypeArtCatalog.TEXTURES[art_key] as Texture2D
		if texture == null:
			continue
		_expect(not texture.resource_path.contains("ItemArtPack2026_07_29_v1"), "Policy: V1 texture must not remain registered: %s" % art_key)
		_expect(not texture.resource_path.contains("ItemArtPack2026_07_29_v2"), "Policy: V2 texture must not remain registered: %s" % art_key)
		_expect(not texture.resource_path.contains("review_required"), "Policy: review_required texture must never be registered: %s" % art_key)
		_expect(not texture.resource_path.contains("needs_processing"), "Policy: gray source texture must never be registered: %s" % art_key)
		_expect(not texture.resource_path.contains("sources_48px"), "Policy: 48px source texture must never be registered: %s" % art_key)
		if not texture.resource_path.begins_with(PACK_ROOT):
			continue
		var import_path := "%s.import" % texture.resource_path
		_expect(FileAccess.file_exists(import_path), "Import: V3 texture must have a Godot import sidecar: %s" % texture.resource_path)
		if FileAccess.file_exists(import_path):
			var import_text := FileAccess.get_file_as_string(import_path)
			_expect(import_text.contains("compress/mode=0"), "Import: V3 pixel art must use lossless compression: %s" % texture.resource_path)
			_expect(import_text.contains("mipmaps/generate=false"), "Import: V3 pixel art must disable mipmaps: %s" % texture.resource_path)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
