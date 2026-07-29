extends SceneTree

const PATCH_ROOT := "res://Assets/Items/ItemArtCorrection2026_07_29_v4/assets/ready"

const EXPECTED_KEYS := {
	ItemData.ItemType.TOMAHAWK_STEAK: &"tomahawk_steak",
	ItemData.ItemType.UNPLATED_STIR_FRY_BEEF: &"stir_fry_beef_unplated",
	ItemData.ItemType.PLATED_STIR_FRY_BEEF: &"stir_fry_beef_plated",
	ItemData.ItemType.UNPLATED_BEEF_GREENS: &"beef_greens_unplated",
	ItemData.ItemType.PLATED_BEEF_GREENS: &"beef_greens_plated",
	ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP: &"beef_greens_soup_unplated",
	ItemData.ItemType.PLATED_BEEF_GREENS_SOUP: &"beef_greens_soup_plated",
}

const EXPECTED_FILES := {
	&"tomahawk_steak": "weapon_tomahawk_steak_normal.png",
	&"tomahawk_steak_perfect": "weapon_tomahawk_steak_perfect.png",
	&"stir_fry_beef_unplated": "dish_stir_fry_beef_unplated.png",
	&"stir_fry_beef_plated": "dish_stir_fry_beef_plated.png",
	&"beef_greens_unplated": "dish_greens_beef_stir_fry_unplated.png",
	&"beef_greens_plated": "dish_greens_beef_stir_fry_plated.png",
	&"beef_greens_soup_unplated": "dish_greens_beef_soup_unplated.png",
	&"beef_greens_soup_plated": "dish_greens_beef_soup_plated.png",
}

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_exact_v4_mappings()
	await _test_tomahawk_quality_and_shape()
	await _test_shared_display_source()
	await _test_lobby_catalog_20_by_80()
	_test_import_policy()
	if failures.is_empty():
		print("PROTOTYPE_ITEM_ART_CORRECTION_V4_TEST: PASS (5/5 groups)")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("PROTOTYPE_ITEM_ART_CORRECTION_V4_TEST: FAIL (%d)" % failures.size())
	quit(1)


func _test_exact_v4_mappings() -> void:
	for item_type: int in EXPECTED_KEYS:
		var expected_key: StringName = EXPECTED_KEYS[item_type]
		_expect(ItemCatalog.get_art_key(item_type) == expected_key, "V4 mapping: ItemType %d must use %s" % [item_type, expected_key])
	for art_key: StringName in EXPECTED_FILES:
		var texture := PrototypeArtCatalog.TEXTURES.get(art_key) as Texture2D
		_expect(texture != null, "V4 mapping: %s must load" % art_key)
		if texture != null:
			_expect(texture.resource_path == "%s/%s" % [PATCH_ROOT, EXPECTED_FILES[art_key]], "V4 mapping: %s must resolve to the exact correction PNG" % art_key)
			var expected_size := Vector2(64.0, 96.0) if art_key in [&"tomahawk_steak", &"tomahawk_steak_perfect"] else Vector2(32.0, 32.0)
			_expect(texture.get_size() == expected_size, "V4 mapping: %s must keep its declared pixel canvas" % art_key)
			var image := texture.get_image()
			_expect(
				image.get_pixel(0, 0).a == 0.0
				or image.get_pixel(image.get_width() - 1, 0).a == 0.0
				or image.get_pixel(0, image.get_height() - 1).a == 0.0
				or image.get_pixel(image.get_width() - 1, image.get_height() - 1).a == 0.0,
				"V4 mapping: %s must retain transparent background pixels" % art_key
			)
	_expect(not PrototypeArtCatalog.TEXTURES.has(&"plated_stir_fry_beef"), "V4 mapping: the old shared stir-fry placeholder key must not remain registered")
	_expect(
		ItemCatalog.get_art_key(ItemData.ItemType.UNPLATED_STIR_FRY_BEEF) != ItemCatalog.get_art_key(ItemData.ItemType.PLATED_STIR_FRY_BEEF)
		and ItemCatalog.get_art_key(ItemData.ItemType.UNPLATED_BEEF_GREENS) != ItemCatalog.get_art_key(ItemData.ItemType.PLATED_BEEF_GREENS)
		and ItemCatalog.get_art_key(ItemData.ItemType.UNPLATED_BEEF_GREENS_SOUP) != ItemCatalog.get_art_key(ItemData.ItemType.PLATED_BEEF_GREENS_SOUP),
		"V4 mapping: every corrected unplated/plated pair must use distinct art"
	)
	await process_frame


func _test_tomahawk_quality_and_shape() -> void:
	var normal := ItemCatalog.create(ItemData.ItemType.PLATED_TOMAHAWK_STEAK)
	normal.quality = ItemData.Quality.NORMAL
	var perfect := ItemCatalog.create(ItemData.ItemType.PLATED_TOMAHAWK_STEAK)
	perfect.quality = ItemData.Quality.PERFECT
	var unplated := ItemCatalog.create(ItemData.ItemType.TOMAHAWK_STEAK)
	unplated.quality = ItemData.Quality.PERFECT
	_expect(ItemCatalog.get_art_key_for_data(normal) == &"tomahawk_steak", "V4 tomahawk: non-perfect plated steak must use normal art")
	_expect(ItemCatalog.get_art_key_for_data(perfect) == &"tomahawk_steak_perfect", "V4 tomahawk: perfect plated steak must use perfect art")
	_expect(ItemCatalog.get_art_key_for_data(unplated) == &"tomahawk_steak", "V4 tomahawk: unplated steak must not select perfect art")
	var normal_texture := PrototypeArtCatalog.TEXTURES.get(&"tomahawk_steak") as Texture2D
	var perfect_texture := PrototypeArtCatalog.TEXTURES.get(&"tomahawk_steak_perfect") as Texture2D
	_expect(normal_texture.get_size() == Vector2(64.0, 96.0) and perfect_texture.get_size() == Vector2(64.0, 96.0), "V4 tomahawk: both textures must remain 64x96")
	var expected_cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1),
		Vector2i(0, 2),
	]
	_expect(ItemStorageCatalog.get_shape_cells(ItemData.ItemType.TOMAHAWK_STEAK) == expected_cells, "V4 tomahawk: normal shape must remain 2/2/1")
	_expect(ItemStorageCatalog.get_shape_cells(ItemData.ItemType.PLATED_TOMAHAWK_STEAK) == expected_cells, "V4 tomahawk: plated shape must remain 2/2/1")
	await process_frame


func _test_shared_display_source() -> void:
	var holder := Node2D.new()
	root.add_child(holder)
	var item := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.PLATED_BEEF_GREENS_SOUP))
	holder.add_child(item)
	await process_frame
	var expected := PrototypeArtCatalog.TEXTURES.get(&"beef_greens_soup_plated") as Texture2D
	_expect(item.placeholder.art_sprite.texture == expected, "V4 display: world and held item must use the centralized correction texture")
	var quickbar := QuickInventoryUI.new()
	quickbar._build_ui()
	quickbar._refresh_slot_content(0, item)
	_expect(quickbar.slot_icons[0].texture == expected, "V4 display: quickbar must use the same correction texture")
	var grid := GridInventory.new(4, 4, holder)
	_expect(grid.add_item_at(item, Vector2i.ZERO), "V4 display: corrected soup must fit its unchanged grid shape")
	var grid_view := InventoryGridView.new()
	grid_view.setup(grid, 32.0, "test")
	_expect(grid_view.get_item_art_source_rect(item) == Rect2(Vector2.ZERO, expected.get_size()), "V4 display: cabinet and backpack grid must use the same correction texture")
	grid_view.queue_free()
	quickbar.queue_free()
	holder.queue_free()
	await process_frame


func _test_lobby_catalog_20_by_80() -> void:
	_expect(ItemStorageCatalog.FORMAL_CABINET_SIZE == Vector2i(10, 8), "V4 cabinet: formal storage must remain 10x8")
	_expect(ItemStorageCatalog.LOBBY_TEST_CABINET_SIZE == Vector2i(20, 80), "V4 cabinet: lobby-only storage must be 20x80")
	var cabinet := IngredientCabinet.new()
	root.add_child(cabinet)
	await process_frame
	cabinet.configure_lobby_unlimited_catalog()
	_expect(cabinet.storage.width == 20 and cabinet.storage.height == 80 and cabinet.storage.width * cabinet.storage.height == 1600, "V4 cabinet: actual lobby data grid must contain 1600 cells")
	_expect(cabinet.storage.get_items().size() == IngredientCabinet.get_all_item_types().size(), "V4 cabinet: one sample of every current ItemType must populate")

	cabinet.lobby_replenishing = true
	cabinet.storage.clear_all()
	for y in range(3, 20):
		for x in range(20):
			var blocker := ItemFactory.create_carryable(ItemCatalog.create(ItemData.ItemType.RAW_RICE))
			cabinet.add_child(blocker)
			_expect(cabinet.storage.add_item_at(blocker, Vector2i(x, y)), "V4 cabinet: upper-half blocker setup must fit")
	cabinet._populate_missing_lobby_items()
	cabinet.lobby_replenishing = false

	var lower_item: CarryableItem
	for item in cabinet.storage.get_items():
		var placement := cabinet.storage.get_placement(item)
		if item.data.item_type != ItemData.ItemType.RAW_RICE and placement != null and placement.origin.y >= 20:
			lower_item = item
			break
	_expect(lower_item != null, "V4 cabinet: auto placement must be able to use rows below the first 20")
	if lower_item != null:
		var removed_type := lower_item.data.item_type
		var removed_id := lower_item.get_instance_id()
		cabinet.storage.remove_item(lower_item)
		await process_frame
		await process_frame
		var replacement := cabinet._find_item(removed_type)
		var replacement_placement := cabinet.storage.get_placement(replacement) if replacement != null else null
		_expect(replacement != null and replacement.get_instance_id() != removed_id, "V4 cabinet: taking a lower-half item must create a fresh replacement")
		_expect(replacement_placement != null and replacement_placement.origin.y >= 20, "V4 cabinet: replenishment must continue below row 20")
	cabinet.queue_free()
	await process_frame


func _test_import_policy() -> void:
	for art_key: StringName in EXPECTED_FILES:
		var texture := PrototypeArtCatalog.TEXTURES.get(art_key) as Texture2D
		if texture == null:
			continue
		var import_path := "%s.import" % texture.resource_path
		_expect(FileAccess.file_exists(import_path), "V4 import: sidecar must exist for %s" % art_key)
		if not FileAccess.file_exists(import_path):
			continue
		var import_text := FileAccess.get_file_as_string(import_path)
		_expect(import_text.contains("compress/mode=0"), "V4 import: %s must use lossless compression" % art_key)
		_expect(import_text.contains("mipmaps/generate=false"), "V4 import: %s must disable mipmaps" % art_key)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
