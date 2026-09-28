extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _wait_frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _run() -> void:
	await _test_catalog_integrity()
	await _test_ui_open_flip_and_lock()
	if failures.is_empty():
		print("PROTOTYPE_COOKBOOK_UI_SMOKE_TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("PROTOTYPE_COOKBOOK_UI_SMOKE_TEST: FAIL (%d)" % failures.size())
		quit(1)


func _test_catalog_integrity() -> void:
	CookbookCatalog.reset_all()
	var dishes := CookbookCatalog.get_all_dishes()
	_expect(dishes.size() == 45, "catalog: expected 45 dishes, got %d" % dishes.size())
	var with_art := 0
	for i in dishes.size():
		var d := dishes[i] as CookbookCatalog.DishEntry
		_expect(d.display_name.strip_edges() != "", "catalog[%d]: display_name empty" % i)
		_expect(d.description.strip_edges() != "", "catalog[%d]: description empty" % i)
		_expect(d.ingredients.strip_edges() != "", "catalog[%d]: ingredients empty" % i)
		_expect(d.stat_text.strip_edges() != "", "catalog[%d]: stat_text empty" % i)
		_expect(d.lore.strip_edges() != "", "catalog[%d]: lore empty" % i)
		_expect(d.tips.strip_edges() != "", "catalog[%d]: tips empty" % i)
		if CookbookUI.resolve_dish_texture(d) != null:
			with_art += 1
	_expect(with_art == 45, "catalog: expected complete dish art coverage, got %d/45" % with_art)
	var expected_plated_art := {
		ItemData.ItemType.PLATED_GREENS_BEEF_PORRIDGE: &"greens_beef_porridge_plated",
		ItemData.ItemType.PLATED_FRIED_WHITE_RICE: &"fried_white_rice_plated",
		ItemData.ItemType.PLATED_CLEAR_STIR_FRY_BEEF: &"clear_stir_fry_beef_plated",
		ItemData.ItemType.PLATED_GREENS_SOUP: &"greens_soup_plated",
		ItemData.ItemType.PLATED_BEEF_SOUP: &"beef_soup_plated",
	}
	for item_type in expected_plated_art:
		_expect(
			ItemCatalog.get_art_key(item_type) == expected_plated_art[item_type],
			"catalog: incorrect plated art mapping for item type %d" % item_type
		)
	_expect(CookbookCatalog.get_dish(&"tomahawk_steak") != null, "catalog: get_dish lookup failed")


func _test_ui_open_flip_and_lock() -> void:
	CookbookCatalog.reset_all()
	CookbookCatalog.set_test_hall_mode(true)

	var ui := CookbookUI.new()
	root.add_child(ui)
	ui.open(Callable())
	await _wait_frames(2)

	var cover := ui.find_child("Cover", true, false)
	var spread := ui.find_child("Spread", true, false)
	_expect(cover != null and cover.visible, "ui: cover should be visible on open")
	_expect(spread != null and not spread.visible, "ui: spread should be hidden until opened")

	var open_btn := ui.find_child("CoverOpenButton", true, false) as Button
	_expect(open_btn != null, "ui: CoverOpenButton missing")
	if open_btn != null:
		open_btn.pressed.emit()
	await create_timer(0.5).timeout

	_expect(spread != null and spread.visible, "ui: spread visible after opening")
	_expect(cover != null and not cover.visible, "ui: cover hidden after opening")

	var name_label := ui.find_child("DetailName", true, false) as Label
	_expect(name_label != null, "ui: DetailName missing")
	if name_label != null:
		_expect(name_label.text == "小炒黄牛肉", "ui: first dish should be 小炒黄牛肉, got '%s'" % name_label.text)

	var next_btn := ui.find_child("NextButton", true, false) as Button
	_expect(next_btn != null, "ui: NextButton missing")
	if next_btn != null:
		next_btn.pressed.emit()
	await create_timer(0.5).timeout
	name_label = ui.find_child("DetailName", true, false) as Label
	_expect(name_label != null and name_label.text == "战斧牛排", "ui: second dish should be 战斧牛排 after next")

	var prev_btn := ui.find_child("PrevButton", true, false) as Button
	_expect(prev_btn != null, "ui: PrevButton missing")
	if prev_btn != null:
		prev_btn.pressed.emit()
	await create_timer(0.5).timeout
	name_label = ui.find_child("DetailName", true, false) as Label
	_expect(name_label != null and name_label.text == "小炒黄牛肉", "ui: prev should return to 小炒黄牛肉")

	# 目录点击跳转
	var toc_btn := ui.find_child("TocButton2", true, false) as Button
	_expect(toc_btn != null, "ui: TocButton2 missing")
	if toc_btn != null:
		toc_btn.pressed.emit()
	await create_timer(0.5).timeout
	name_label = ui.find_child("DetailName", true, false) as Label
	_expect(name_label != null and name_label.text == "涮牛肉", "ui: toc jump should show 涮牛肉")
	if toc_btn != null:
		var toc_pad := toc_btn.get_parent().get_child(1) as MarginContainer
		_expect(toc_pad != null and toc_pad.mouse_filter == Control.MOUSE_FILTER_IGNORE, "ui: table-of-contents padding must pass clicks to the row button")

	# The four reported dishes use art with asymmetric transparent borders. The
	# detail icon should apply the visible-pixel centering offset for each one.
	var all_dishes := CookbookCatalog.get_all_dishes()
	for dish_index in [11, 12, 13, 19]:
		var dish := all_dishes[dish_index] as CookbookCatalog.DishEntry
		var target_btn := ui.find_child("TocButton%d" % dish_index, true, false) as Button
		_expect(target_btn != null, "ui: missing TOC button for dish %d" % (dish_index + 1))
		if target_btn != null:
			target_btn.pressed.emit()
		await create_timer(0.5).timeout
		var icon := ui.find_child("DishIcon", true, false) as TextureRect
		var expected_shift := CookbookUI.get_dish_icon_shift(CookbookUI.resolve_dish_texture(dish))
		_expect(icon != null, "ui: dish %d icon missing" % (dish_index + 1))
		if icon != null:
			_expect(is_equal_approx(icon.offset_left, expected_shift.x) and is_equal_approx(icon.offset_top, expected_shift.y), "ui: dish %d icon should center its visible pixels" % (dish_index + 1))

	# 锁定页（关闭试炼厅全解锁后，未解锁料理显示锁占位）
	CookbookCatalog.set_test_hall_mode(false)
	CookbookCatalog.reset_all()
	toc_btn = ui.find_child("TocButton1", true, false) as Button
	if toc_btn != null:
		toc_btn.pressed.emit()
	await create_timer(0.5).timeout
	var locked := ui.find_child("DetailLocked", true, false)
	_expect(locked != null, "ui: locked placeholder should show for locked dish")

	# 关闭
	ui.close()
	_expect(not ui.visible, "ui: close should hide ui")
	ui.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
