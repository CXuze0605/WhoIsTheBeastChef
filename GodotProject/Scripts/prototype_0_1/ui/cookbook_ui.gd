class_name CookbookUI
extends Control

# 烹饪大典 UI —— 书本形态菜谱（封面 → 羊皮纸双页 → 翻页浏览）
# 全部由代码构建：不依赖场景文件，纸张/皮革纹理运行时生成一次并缓存。

# --- 书卷调色板 ---
const INK := Color("#3a2a1a")
const INK_SOFT := Color("#5a4632")
const INK_FAINT := Color("#8a7658")
const PARCH := Color("#f0e2c0")
const PARCH_DEEP := Color("#e6d3a8")
const LEATHER := Color("#3a2414")
const LEATHER_DARK := Color("#291a0d")
const GOLD := Color("#c9a35c")
const ACCENT_RED := Color("#8b3a2b")
const LOCKED := Color("#8a7a62")
const DIM := Color(0.0, 0.0, 0.0, 0.55)

const BOOK_W := 1080
const BOOK_H := 700
const FLIP_TIME := 0.26

static var _parchment_cache: Dictionary = {}
static var _leather_cache: Texture2D

var _dish_list: Array = []
var _selected_index: int = 0
var _close_callback: Callable = Callable()
var _flipping := false

var _book: Control
var _cover: Control
var _cover_open_button: Button
var _spread: Control
var _left_page: PanelContainer
var _left_content: VBoxContainer
var _right_page: PanelContainer
var _right_content: VBoxContainer
var _toc_scroll: ScrollContainer
var _toc_rows: Array = []
var _prev_button: Button
var _next_button: Button
var _page_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dish_list = CookbookCatalog.get_all_dishes()
	_build_ui()


func open(close_fn: Callable = Callable()) -> void:
	_close_callback = close_fn
	_dish_list = CookbookCatalog.get_all_dishes()
	_refresh_toc_rows()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_selected_index = clampi(_selected_index, 0, maxi(0, _dish_list.size() - 1))
	_update_toc_highlight()
	_show_detail(_selected_index)
	_show_cover()


func _refresh_toc_rows() -> void:
	if _left_content == null:
		return
	for child in _left_content.get_children():
		child.free()
	_build_toc_rows()


func close() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 复位到“合上的书”，下次打开仍从封面开始。
	_cover.visible = true
	_spread.visible = false
	_cover.scale = Vector2.ONE
	_cover.modulate.a = 1.0
	_cover_open_button.disabled = false


# --- 构建 ---

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_book = Control.new()
	_book.name = "Book"
	_book.size = Vector2(BOOK_W, BOOK_H)
	add_child(_book)
	_recenter_book()
	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_recenter_book)

	_build_cover()
	_build_spread()
	_show_cover()


func _recenter_book() -> void:
	if _book == null:
		return
	var vp := get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return
	var scale := minf((vp.x - 48.0) / float(BOOK_W), (vp.y - 48.0) / float(BOOK_H))
	scale = maxf(scale, 0.4)
	_book.pivot_offset = Vector2(BOOK_W, BOOK_H) * 0.5
	_book.scale = Vector2(scale, scale)
	_book.position = (vp - Vector2(BOOK_W, BOOK_H) * scale) * 0.5


# --- 封面 ---

func _build_cover() -> void:
	_cover = Control.new()
	_cover.name = "Cover"
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_book.add_child(_cover)

	# 书页堆（右侧露出的纸边，制造厚度感）
	var page_block := PanelContainer.new()
	page_block.position = Vector2(16, 12)
	page_block.size = Vector2(BOOK_W - 16, BOOK_H - 12)
	page_block.add_theme_stylebox_override("panel", _style(PARCH_DEEP, 12))
	_cover.add_child(page_block)

	# 皮革封面
	var face := PanelContainer.new()
	face.position = Vector2(2, 2)
	face.size = Vector2(BOOK_W - 20, BOOK_H - 18)
	face.add_theme_stylebox_override("panel", _style(LEATHER_DARK, 16, GOLD, 3, 12))
	_cover.add_child(face)

	var leather := TextureRect.new()
	leather.texture = _get_leather_texture()
	leather.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leather.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(leather)

	var inner := PanelContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0), 12, Color(GOLD, 0.55), 1))
	face.add_child(inner)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 36)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	vbox.add_child(_make_ornament(GOLD))

	var title := Label.new()
	title.text = "烹饪大典"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", GOLD)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "《谁是大厨生》· 食谱手记"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color("#d8c39a"))
	vbox.add_child(sub)

	vbox.add_child(_make_ornament(GOLD))

	var badge_row := HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_row.add_theme_constant_override("separation", 10)
	var methods := ["炒", "煮", "炸", "煎"]
	for m in methods:
		badge_row.add_child(_make_badge(m, Color("#d9b26a"), INK))
	vbox.add_child(badge_row)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var hint := Label.new()
	hint.text = "—  点击翻开  —"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("#cbb07c"))
	vbox.add_child(hint)

	var footer := Label.new()
	footer.text = "已收录料理 × %d" % _dish_list.size()
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color("#a88e62"))
	vbox.add_child(footer)

	# 透明整面按钮：点击任意处翻开书
	_cover_open_button = Button.new()
	_cover_open_button.name = "CoverOpenButton"
	_cover_open_button.flat = true
	_cover_open_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover_open_button.pressed.connect(_on_cover_open)
	face.add_child(_cover_open_button)


func _show_cover() -> void:
	_cover.visible = true
	_spread.visible = false
	_cover.scale = Vector2.ONE
	_cover.modulate.a = 1.0
	_cover_open_button.disabled = false


func _on_cover_open() -> void:
	_cover_open_button.disabled = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_cover, "scale", Vector2(1.02, 1.02), 0.16)
	tween.parallel().tween_property(_cover, "modulate:a", 0.0, 0.16)
	tween.tween_callback(_reveal_spread)


func _reveal_spread() -> void:
	_cover.visible = false
	_cover.scale = Vector2.ONE
	_cover.modulate.a = 1.0
	_cover_open_button.disabled = false
	_spread.visible = true
	_spread.scale = Vector2(0.98, 0.98)
	_spread.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_spread, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(_spread, "scale", Vector2.ONE, 0.15)


# --- 展开双页 ---

func _build_spread() -> void:
	_spread = Control.new()
	_spread.name = "Spread"
	_spread.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_spread.visible = false
	_book.add_child(_spread)

	var page_block := PanelContainer.new()
	page_block.position = Vector2(14, 10)
	page_block.size = Vector2(BOOK_W - 14, BOOK_H - 10)
	page_block.add_theme_stylebox_override("panel", _style(PARCH_DEEP, 10))
	_spread.add_child(page_block)

	var page_row := HBoxContainer.new()
	page_row.position = Vector2(0, 0)
	page_row.size = Vector2(BOOK_W - 14, BOOK_H - 56)
	page_row.add_theme_constant_override("separation", 12)
	_spread.add_child(page_row)

	# 左页：目录
	_left_page = PanelContainer.new()
	_left_page.name = "LeftPage"
	_left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left_page.add_theme_stylebox_override("panel", _style(PARCH, 8))
	page_row.add_child(_left_page)
	_add_page_texture(_left_page, 7, Vector2(1.0, 0.5))

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 30)
	left_margin.add_theme_constant_override("margin_right", 22)
	left_margin.add_theme_constant_override("margin_top", 22)
	left_margin.add_theme_constant_override("margin_bottom", 16)
	left_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_left_page.add_child(left_margin)

	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_margin.add_child(left_vbox)

	var toc_title := Label.new()
	toc_title.text = "目  录"
	toc_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toc_title.add_theme_font_size_override("font_size", 26)
	toc_title.add_theme_color_override("font_color", ACCENT_RED)
	left_vbox.add_child(toc_title)

	var toc_line := _make_ornament(ACCENT_RED)
	left_vbox.add_child(toc_line)

	_toc_scroll = ScrollContainer.new()
	_toc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_toc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(_toc_scroll)

	_left_content = VBoxContainer.new()
	_left_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toc_scroll.add_child(_left_content)

	_build_toc_rows()

	# 右页：详情
	_right_page = PanelContainer.new()
	_right_page.name = "RightPage"
	_right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_page.add_theme_stylebox_override("panel", _style(PARCH, 8))
	page_row.add_child(_right_page)
	_add_page_texture(_right_page, 11, Vector2(0.0, 0.5))

	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 22)
	right_margin.add_theme_constant_override("margin_right", 30)
	right_margin.add_theme_constant_override("margin_top", 22)
	right_margin.add_theme_constant_override("margin_bottom", 16)
	right_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_right_page.add_child(right_margin)

	var right_scroll := ScrollContainer.new()
	right_scroll.name = "DetailScroll"
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_margin.add_child(right_scroll)

	_right_content = VBoxContainer.new()
	_right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(_right_content)

	# 书脊
	var spine := ColorRect.new()
	spine.name = "Spine"
	spine.color = Color(0.14, 0.08, 0.04, 0.9)
	spine.position = Vector2((BOOK_W - 14) * 0.5 - 4.0, 6)
	spine.size = Vector2(8, BOOK_H - 64)
	_spread.add_child(spine)

	# 右上关闭
	var close_btn := _make_chip_button("合上 [Esc]", 150)
	close_btn.name = "CloseButton"
	close_btn.position = Vector2(BOOK_W - 172, 8)
	close_btn.pressed.connect(_on_close)
	_spread.add_child(close_btn)

	# 底部控制条
	_prev_button = _make_chip_button("< 上一道", 150)
	_prev_button.name = "PrevButton"
	_prev_button.position = Vector2(60, BOOK_H - 48)
	_prev_button.pressed.connect(_on_prev_pressed)
	_spread.add_child(_prev_button)

	_next_button = _make_chip_button("下一道 >", 150)
	_next_button.name = "NextButton"
	_next_button.position = Vector2(BOOK_W - 210, BOOK_H - 48)
	_next_button.pressed.connect(_on_next_pressed)
	_spread.add_child(_next_button)

	_page_label = Label.new()
	_page_label.name = "PageLabel"
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.add_theme_font_size_override("font_size", 15)
	_page_label.add_theme_color_override("font_color", INK_FAINT)
	_page_label.position = Vector2(BOOK_W * 0.5 - 120, BOOK_H - 44)
	_page_label.size = Vector2(240, 28)
	_spread.add_child(_page_label)


func _add_page_texture(page: PanelContainer, seed_value: int, shadow_to: Vector2) -> void:
	var tex := TextureRect.new()
	tex.texture = _get_parchment_texture(seed_value)
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(tex)

	# 书脊侧阴影：让页面有向内的凹感
	var shade := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.width = 256
	grad.height = 256
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(0.25, 0.15, 0.06, 0.0), Color(0.25, 0.15, 0.06, 0.16)])
	grad.gradient = g
	grad.fill = GradientTexture2D.FILL_LINEAR
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = shadow_to
	shade.texture = grad
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(shade)


# --- 目录 ---

func _build_toc_rows() -> void:
	_toc_rows.clear()
	for i in _dish_list.size():
		var dish := _dish_list[i] as CookbookCatalog.DishEntry
		var unlocked := CookbookCatalog.is_unlocked(dish.recipe_id)

		var row := PanelContainer.new()
		row.name = "TocRow%d" % i
		row.custom_minimum_size.y = 36
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0), 6))
		_left_content.add_child(row)

		var btn := Button.new()
		btn.name = "TocButton%d" % i
		btn.flat = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.pressed.connect(_on_toc_pressed.bind(i))
		row.add_child(btn)

		var pad := MarginContainer.new()
		pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pad.add_theme_constant_override("margin_left", 12)
		pad.add_theme_constant_override("margin_right", 12)
		row.add_child(pad)

		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 8)
		pad.add_child(hbox)

		var num := Label.new()
		num.text = "%02d" % (i + 1)
		num.custom_minimum_size.x = 34
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		num.add_theme_font_size_override("font_size", 14)
		num.add_theme_color_override("font_color", INK_FAINT)
		hbox.add_child(num)

		var name := Label.new()
		name.text = dish.display_name if unlocked else "？？？"
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.add_theme_font_size_override("font_size", 17)
		name.add_theme_color_override("font_color", INK if unlocked else LOCKED)
		hbox.add_child(name)

		var mark := Label.new()
		mark.text = "·" if unlocked else "锁"
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.add_theme_font_size_override("font_size", 14)
		mark.add_theme_color_override("font_color", Color("#5a8a5a") if unlocked else LOCKED)
		hbox.add_child(mark)

		_toc_rows.append(row)


func _update_toc_highlight() -> void:
	for i in _toc_rows.size():
		var row := _toc_rows[i] as PanelContainer
		if row == null:
			continue
		if i == _selected_index:
			row.add_theme_stylebox_override("panel", _style(Color(0.45, 0.28, 0.12, 0.22), 6))
		else:
			row.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0), 6))
	if _toc_scroll != null and _selected_index < _toc_rows.size():
		var target := _toc_rows[_selected_index] as Control
		if target != null:
			_toc_scroll.ensure_control_visible(target)


# --- 详情页 ---

func _show_detail(index: int) -> void:
	for c in _right_content.get_children():
		c.queue_free()

	var dish := _dish_list[index] as CookbookCatalog.DishEntry
	var unlocked := CookbookCatalog.is_unlocked(dish.recipe_id)
	var test_hall := CookbookCatalog.is_test_hall_mode()

	if not unlocked and not test_hall:
		var lock_box := VBoxContainer.new()
		lock_box.name = "DetailLocked"
		lock_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lock_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_right_content.add_child(lock_box)

		var lock_icon := Label.new()
		lock_icon.text = "？？？"
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_icon.add_theme_font_size_override("font_size", 46)
		lock_icon.add_theme_color_override("font_color", LOCKED)
		lock_box.add_child(lock_icon)

		var lock_msg := Label.new()
		lock_msg.text = "这道料理尚未解锁。\n在游戏中首次制作后，它会出现在这里。"
		lock_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_msg.add_theme_font_size_override("font_size", 16)
		lock_msg.add_theme_color_override("font_color", INK_SOFT)
		lock_box.add_child(lock_msg)

		var lock_spacer := Control.new()
		lock_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lock_box.add_child(lock_spacer)

		_page_label.text = "第 %d 道 · 共 %d 道" % [index + 1, _dish_list.size()]
		return

	# 标题行：插图 + 菜名
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 16)
	_right_content.add_child(header)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(150, 100)
	icon_frame.add_theme_stylebox_override("panel", _style(PARCH_DEEP, 10, Color(INK_FAINT, 0.5), 1))
	header.add_child(icon_frame)

	var dish_texture := resolve_dish_texture(dish)
	if dish_texture != null:
		var icon_tex := TextureRect.new()
		icon_tex.texture = dish_texture
		icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.add_child(icon_tex)
	else:
		var fallback := Label.new()
		fallback.text = String(dish.display_name).substr(0, 1)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 46)
		fallback.add_theme_color_override("font_color", Color(INK, 0.45))
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_frame.add_child(fallback)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 8)
	header.add_child(title_box)

	var name_label := Label.new()
	name_label.name = "DetailName"
	name_label.text = dish.display_name
	if test_hall and not unlocked:
		name_label.text += "（试炼厅预览）"
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", INK)
	title_box.add_child(name_label)

	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 8)
	title_box.add_child(tags)

	tags.add_child(_make_badge(dish.cooking_method, Color("#d9b26a"), INK))
	tags.add_child(_make_badge(dish.attack_form, Color("#c9a35c"), INK))
	if dish.can_plate:
		tags.add_child(_make_badge("可摆盘", Color("#9cc29a"), INK))
	if dish.has_perfect:
		tags.add_child(_make_badge("完美终结", Color("#e0c06a"), INK))
	if dish.is_healing:
		tags.add_child(_make_badge("回复型", Color("#d9a0a0"), INK))

	_right_content.add_child(_make_ornament(ACCENT_RED))

	_add_section(_right_content, "烹饪之法", dish.ingredients)
	_add_section(_right_content, "数值一览", dish.stat_text)
	_add_section(_right_content, "风味", "“" + dish.lore + "”", Color("#6b4a2b"))
	_add_section(_right_content, "实战心得", dish.tips)

	var footnote := Label.new()
	footnote.text = "· 数值为当前原型配置，以实际战斗为准 ·"
	footnote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footnote.add_theme_font_size_override("font_size", 12)
	footnote.add_theme_color_override("font_color", INK_FAINT)
	_right_content.add_child(footnote)

	_page_label.text = "第 %d 道 · 共 %d 道" % [index + 1, _dish_list.size()]


func _add_section(container: VBoxContainer, title: String, body: String, body_color: Color = INK) -> void:
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", ACCENT_RED)
	container.add_child(title_label)

	var body_label := Label.new()
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", body_color)
	body_label.custom_minimum_size.y = 24
	container.add_child(body_label)


# --- 翻页与选择 ---

func _on_prev_pressed() -> void:
	_select_dish(_selected_index - 1)


func _on_next_pressed() -> void:
	_select_dish(_selected_index + 1)


func _on_toc_pressed(index: int) -> void:
	_select_dish(index)


func _select_dish(index: int) -> void:
	if _flipping:
		return
	if index < 0 or index >= _dish_list.size() or index == _selected_index:
		return
	_selected_index = index
	_update_toc_highlight()
	_play_page_flip()


func _play_page_flip() -> void:
	if _flipping:
		return
	_flipping = true
	_prev_button.disabled = true
	_next_button.disabled = true
	var page := _right_page
	page.pivot_offset = Vector2(0.0, page.size.y * 0.5)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(page, "scale:x", 0.03, FLIP_TIME * 0.5)
	tween.tween_callback(_swap_page_content)
	tween.tween_property(page, "scale:x", 1.0, FLIP_TIME * 0.5)
	tween.tween_callback(_finish_flip)


func _swap_page_content() -> void:
	_show_detail(_selected_index)


func _finish_flip() -> void:
	_flipping = false
	_prev_button.disabled = false
	_next_button.disabled = false
	_right_page.scale.x = 1.0


# --- 关闭与输入 ---

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("toggle_pause") or _is_escape_pressed(event):
		_on_close()
		get_viewport().set_input_as_handled()
		return
	if _cover.visible and event.is_action_pressed("ui_accept"):
		_on_cover_open()
		get_viewport().set_input_as_handled()
		return
	if not _spread.visible or _flipping:
		return
	if event.is_action_pressed("ui_right"):
		_select_dish(_selected_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_select_dish(_selected_index - 1)
		get_viewport().set_input_as_handled()


func _is_escape_pressed(event: InputEvent) -> bool:
	if event is not InputEventKey:
		return false
	var key := event as InputEventKey
	return key.pressed and not key.echo and (key.keycode == KEY_ESCAPE or key.physical_keycode == KEY_ESCAPE)


func _on_close() -> void:
	close()
	if _close_callback.is_valid():
		_close_callback.call()


# --- 工具 ---

func _make_chip_button(text: String, width: float) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, 34)
	btn.add_theme_stylebox_override("normal", _style(Color("#efe3c8"), 16, Color(INK_FAINT, 0.6), 1))
	btn.add_theme_stylebox_override("hover", _style(Color("#e6d5b0"), 16, Color(INK_FAINT, 0.8), 1))
	btn.add_theme_stylebox_override("pressed", _style(Color("#dcc79b"), 16, INK_FAINT, 1))
	btn.add_theme_stylebox_override("disabled", _style(Color("#d8c9a8"), 16, Color(INK_FAINT, 0.4), 1))
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", INK)
	btn.add_theme_color_override("font_hover_color", INK)
	btn.add_theme_color_override("font_pressed_color", INK)
	btn.add_theme_color_override("font_disabled_color", Color(INK, 0.5))
	return btn


static func _make_badge(text: String, tint: Color, text_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(tint, 0.28), 9))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", text_color)
	margin.add_child(label)
	panel.add_child(margin)
	return panel


static func _make_ornament(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 3)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(color, 2))
	return panel


static func _style(bg: Color, radius: float, border_color: Color = Color.TRANSPARENT, border_width: int = 0, shadow_size: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(radius))
	if border_width > 0:
		sb.border_color = border_color
		sb.set_border_width_all(border_width)
	if shadow_size > 0:
		sb.shadow_color = Color(0, 0, 0, 0.28)
		sb.shadow_size = shadow_size
	return sb


# --- 运行时纹理（一次性生成并缓存） ---

static func _get_leather_texture() -> Texture2D:
	if _leather_cache == null:
		_leather_cache = _make_material_texture(224, Color(0.24, 0.14, 0.08), 0.05, 42)
	return _leather_cache


static func _get_parchment_texture(seed_value: int) -> Texture2D:
	if not _parchment_cache.has(seed_value):
		_parchment_cache[seed_value] = _make_material_texture(192, Color(0.94, 0.88, 0.74), 0.028, seed_value)
	return _parchment_cache[seed_value]


static func _make_material_texture(size: int, base: Color, noise_strength: float, seed_value: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# 斑点噪点（纸张颗粒 / 皮革毛孔）
	var speckles := 2600
	for i in speckles:
		var x := rng.randi_range(0, size - 1)
		var y := rng.randi_range(0, size - 1)
		var a := rng.randf_range(0.02, 0.09)
		var dark := rng.randf() < 0.55
		var c := Color(base.r * 0.82, base.g * 0.82, base.b * 0.72, a) if dark else Color(minf(1.0, base.r * 1.12), minf(1.0, base.g * 1.08), minf(1.0, base.b * 1.02), a)
		var dst := img.get_pixel(x, y)
		img.set_pixel(x, y, dst.lerp(c, a))
	# 边缘暗化（纸张受潮 / 皮革压痕）
	var edge := maxi(10, size / 6)
	for i in edge:
		var t := float(i) / float(edge)
		var dark := 1.0 - 0.16 * (t * t)
		var c := Color(base.r * dark, base.g * dark, base.b * dark)
		img.fill_rect(Rect2i(i, 0, 1, size), c)
		img.fill_rect(Rect2i(size - 1 - i, 0, 1, size), c)
		img.fill_rect(Rect2i(0, i, size, 1), c)
		img.fill_rect(Rect2i(0, size - 1 - i, size, 1), c)
	return ImageTexture.create_from_image(img)


# 根据美术键解析料理插图；无匹配时返回 null（UI 回退为首字占位）
static func resolve_dish_texture(dish: CookbookCatalog.DishEntry) -> Texture2D:
	if dish == null:
		return null
	var key := String(dish.art_key)
	var candidates: Array[String] = [key]
	if not key.ends_with("_plated"):
		candidates.append(key + "_plated")
	if not key.ends_with("_unplated"):
		candidates.append(key + "_unplated")
	if key.begins_with("plated_"):
		candidates.append(key.trim_prefix("plated_") + "_plated")
	for c in candidates:
		var tex := PrototypeArtCatalog.TEXTURES.get(StringName(c)) as Texture2D
		if tex != null:
			return tex
	return null
