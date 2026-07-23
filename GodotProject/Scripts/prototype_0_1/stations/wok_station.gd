class_name WokStation
extends ProcessingStation

# Historical class/file name retained for scene and test compatibility. Runtime
# behavior is Prototype 0.4's generic stove slot.
@export var station_id: StringName = &"prototype_stove_01"
@export var initial_cookware_type: int = ItemData.ItemType.WOK

var cookware_item: CookwareItem
var wok_item: WokItem:
	get:
		return cookware_item as WokItem
	set(value):
		cookware_item = value
var burner_on: bool = false
var active_stage: int = -1
var config := PrototypeCombatConfig.new()
var circular_indicator: CircularCookingIndicator
var last_event_text: String = "等待开火"
var warning_flash_time: float = 0.0
var session_active: bool = false


func _ready() -> void:
	display_title = "通用灶位"
	placeholder_color = Color("7a5551")
	super._ready()
	add_to_group("wok_station")
	add_to_group("stove_station")
	var combat_runtime := get_tree().get_first_node_in_group("combat_runtime") as CombatManager
	if combat_runtime != null:
		config = combat_runtime.config
	_create_initial_cookware()
	_build_circular_indicator()
	_refresh_status()


func _process(delta: float) -> void:
	if session_active:
		advance_automatic_cooking(delta)
	warning_flash_time += delta
	_refresh_status()


func get_carry_prompt(player: Node) -> String:
	if cookware_item == null:
		return "灶位为空；[R] 放置锅具" if player.held_item is CookwareItem else "灶位为空"
	if player.held_item != null and _can_insert_selected_item(player.held_item.data):
		return "[F] 向%s加入 %s" % [cookware_item.get_cookware_name(), player.held_item.data.display_name]
	var content := _get_content_data()
	if content != null and player.can_receive_item_data(content):
		return "[F] 取出 %s" % content.display_name
	return ""


func carry_interact(player: Node) -> void:
	if cookware_item == null:
		player.notify_feedback("灶位上没有锅具")
		return
	var held_data: ItemData = player.held_item.data if player.held_item != null else null
	if held_data != null and _can_insert_selected_item(held_data):
		_insert_selected_item(player, held_data)
		advance_automatic_cooking(0.0, player)
		_refresh_status()
		return
	var content := _get_content_data()
	if content != null:
		if not player.can_receive_item_data(content):
			player.notify_feedback("物品栏已满")
			return
		_interrupt_current_stage("取出食物")
		var taken := _take_content()
		if player.receive_item_data(taken):
			player.notify_feedback("从%s取出：%s；灶火保持%s" % [cookware_item.get_cookware_name(), taken.display_name, "开启" if burner_on else "关闭"])
		_refresh_status()
		return
	player.notify_feedback("该物品不能在当前锅具中加工")


func get_secondary_prompt(player: Node) -> String:
	if cookware_item != null and player.can_receive_item(cookware_item):
		return "[R] 拿起%s" % cookware_item.get_cookware_name()
	if cookware_item == null and player.held_item is CookwareItem:
		return "[R] 将%s放到灶位" % (player.held_item as CookwareItem).get_cookware_name()
	return ""


func secondary_interact(player: Node) -> void:
	if cookware_item != null:
		if not player.can_receive_item(cookware_item):
			player.notify_feedback("物品栏已满")
			return
		_interrupt_current_stage("锅具离开灶位")
		var pot := cookware_item
		cookware_item = null
		if player.pickup_item(pot):
			player.notify_feedback("%s已收入物品栏；当前未完成阶段归零，灶火保持%s" % [pot.get_cookware_name(), "开启" if burner_on else "关闭"])
		else:
			cookware_item = pot
		_refresh_status()
		return
	if not (player.held_item is CookwareItem):
		player.notify_feedback("需要手持炒锅、煎锅或汤锅")
		return
	cookware_item = player.release_held_to_container(self, Vector2(0.0, -10.0)) as CookwareItem
	active_stage = -1
	hold_progress.cancel()
	player.notify_feedback("%s已放到通用灶位%s" % [cookware_item.get_cookware_name(), "；自动加热从当前阶段起点开始" if burner_on else ""])
	advance_automatic_cooking(0.0, player)
	_refresh_status()


func get_primary_prompt(_player: Node) -> String:
	if cookware_item is PanItem and (cookware_item as PanItem).cook_stage == PanItem.CookStage.FLIP_WINDOW:
		return "[E] 翻面"
	return "[E] 关闭灶火" if burner_on else "[E] 开启灶火"


func begin_primary_interaction(player: Node) -> bool:
	if cookware_item is PanItem:
		var pan := cookware_item as PanItem
		if pan.cook_stage == PanItem.CookStage.FLIP_WINDOW:
			hold_progress.cancel()
			pan.flip(false)
			active_stage = pan.cook_stage
			last_event_text = "翻面成功；第二面开始自动煎制"
			player.notify_feedback(last_event_text)
			_refresh_status()
			return false
	set_burner_on(not burner_on, player)
	return false


func set_burner_on(value: bool, player: Node = null) -> void:
	if burner_on == value:
		return
	burner_on = value
	if not burner_on:
		_interrupt_current_stage("关火")
		last_event_text = "灶火已关闭；未完成阶段归零"
	else:
		last_event_text = "灶火已开启"
		advance_automatic_cooking(0.0, player)
	if player != null:
		player.notify_feedback(last_event_text)
	_refresh_status()


func advance_automatic_cooking(delta: float, player: Node = null) -> bool:
	if not burner_on or cookware_item == null or cookware_item.is_stuck():
		if hold_progress.active:
			_interrupt_current_stage("加热条件中断")
		return false
	if cookware_item is WokItem:
		return _advance_wok(delta, player)
	if cookware_item is PanItem:
		return _advance_pan(delta, player)
	if cookware_item is SoupPotItem:
		return _advance_soup_pot(delta, player)
	return false


func _advance_wok(delta: float, player: Node = null) -> bool:
	var wok := cookware_item as WokItem
	if wok.content_data == null:
		_cancel_empty_progress(WokItem.CookStage.EMPTY)
		return false
	if wok.cook_stage == WokItem.CookStage.RAW_LOADED and not wok.has_oil():
		_trigger_no_oil_accident(player)
		return true
	if wok.cook_stage == WokItem.CookStage.STAGE_ONE_DONE and not wok.content_data.has_component(ItemData.ComponentType.CHILI_SEGMENTS):
		_cancel_empty_progress(WokItem.CookStage.STAGE_ONE_DONE)
		last_event_text = "第一阶段完成，等待加入辣椒段"
		return false
	if wok.cook_stage == WokItem.CookStage.CHARCOAL:
		_cancel_empty_progress(WokItem.CookStage.CHARCOAL)
		return false
	if not _advance_stage_timer(wok.cook_stage, _get_wok_duration(wok.cook_stage), delta):
		return false
	match wok.cook_stage:
		WokItem.CookStage.RAW_LOADED:
			wok.complete_stage_one(); last_event_text = "第一阶段短炒完成；等待辣椒段"
		WokItem.CookStage.STAGE_ONE_DONE:
			wok.complete_stage_two()
			config.apply_combat_dish_stats(wok.content_data)
			last_event_text = "得到可直接使用或继续摆盘的小炒黄牛肉；灶火仍开启"
		WokItem.CookStage.STAGE_TWO_DONE:
			wok.mark_burnt()
			config.apply_combat_dish_stats(wok.content_data)
			last_event_text = "料理已获得【焦糊】标签"
		WokItem.CookStage.BURNT_TAGGED:
			wok.turn_content_to_charcoal(); last_event_text = "料理继续受热并变为焦炭"
	active_stage = wok.cook_stage
	_notify_stage(player)
	return true


func _advance_pan(delta: float, player: Node = null) -> bool:
	var pan := cookware_item as PanItem
	if pan.content_data == null:
		_cancel_empty_progress(PanItem.CookStage.EMPTY)
		return false
	if pan.cook_stage == PanItem.CookStage.FIRST_SIDE and not pan.has_oil():
		_trigger_no_oil_accident(player)
		return true
	if pan.cook_stage == PanItem.CookStage.CHARCOAL:
		_cancel_empty_progress(PanItem.CookStage.CHARCOAL)
		return false
	var duration := _get_pan_duration(pan.cook_stage)
	if not _advance_stage_timer(pan.cook_stage, duration, delta):
		return false
	match pan.cook_stage:
		PanItem.CookStage.FIRST_SIDE:
			pan.open_flip_window(); last_event_text = "第一面完成：进入翻面窗口"
		PanItem.CookStage.FLIP_WINDOW:
			pan.flip(true); last_event_text = "错过翻面窗口：自动翻面并记录【翻面过晚】"
		PanItem.CookStage.SECOND_SIDE:
			pan.complete_steak()
			config.apply_tomahawk_stats(pan.content_data)
			last_event_text = "战斧牛排完成；可直接使用或完整装盘"
		PanItem.CookStage.READY:
			pan.mark_burnt(); last_event_text = "战斧牛排获得【焦糊】"
		PanItem.CookStage.BURNT_TAGGED:
			pan.turn_content_to_charcoal(); last_event_text = "战斧牛排变为焦炭"
	active_stage = pan.cook_stage
	_notify_stage(player)
	return true


func _advance_soup_pot(delta: float, player: Node = null) -> bool:
	var pot := cookware_item as SoupPotItem
	if not pot.has_water:
		_cancel_empty_progress(SoupPotItem.CookStage.EMPTY)
		return false
	if pot.cook_stage == SoupPotItem.CookStage.BOILING and pot.content_data == null:
		_cancel_empty_progress(SoupPotItem.CookStage.BOILING)
		return false
	if pot.cook_stage == SoupPotItem.CookStage.MUSHY:
		_cancel_empty_progress(SoupPotItem.CookStage.MUSHY)
		return false
	if not _advance_stage_timer(pot.cook_stage, _get_soup_duration(pot.cook_stage), delta):
		return false
	match pot.cook_stage:
		SoupPotItem.CookStage.WATER_HEATING:
			pot.mark_boiling(); last_event_text = "汤锅水已沸腾"
		SoupPotItem.CookStage.SLICE_COOKING:
			pot.complete_slice(); last_event_text = "一片涮牛肉完成，等待取出"
		SoupPotItem.CookStage.READY:
			pot.mark_overcooked(); last_event_text = "涮牛肉获得【煮老】"
		SoupPotItem.CookStage.OVERCOOKED:
			pot.turn_to_mushy(); last_event_text = "涮牛肉变为【煮烂牛肉】"
	active_stage = pot.cook_stage
	_notify_stage(player)
	return true


func _advance_stage_timer(stage: int, duration: float, delta: float) -> bool:
	if not hold_progress.active or active_stage != stage:
		active_stage = stage
		hold_progress.begin(duration)
	return hold_progress.advance(delta)


func _cancel_empty_progress(stage: int) -> void:
	hold_progress.cancel()
	active_stage = stage


func _notify_stage(player: Node) -> void:
	if player != null:
		player.notify_feedback(last_event_text)
	_refresh_status()


func update_primary_interaction(player: Node, delta: float) -> bool:
	advance_automatic_cooking(delta, player)
	return false


func cancel_primary_interaction(player: Node) -> void:
	_interrupt_current_stage("测试中断")
	player.notify_feedback("自动加热阶段中断：当前阶段进度归零，已投材料保留")


func _insert_selected_item(player: Node, held_data: ItemData) -> void:
	if cookware_item is WokItem:
		_insert_into_wok(player, cookware_item as WokItem, held_data)
	elif cookware_item is PanItem:
		_insert_into_pan(player, cookware_item as PanItem, held_data)
	elif cookware_item is SoupPotItem:
		_insert_into_soup(player, cookware_item as SoupPotItem, held_data)


func _insert_into_wok(player: Node, wok: WokItem, held_data: ItemData) -> void:
	match held_data.item_type:
		ItemData.ItemType.COOKING_OIL:
			if wok.add_oil():
				player.consume_held_item(); player.notify_feedback("炒锅已加油")
		ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES:
			if wok.insert_meat(held_data):
				player.consume_held_item(); player.notify_feedback("牛肉片已整份下锅（五片全部用于小炒）")
		ItemData.ItemType.CHILI_SEGMENTS:
			var early := wok.cook_stage == WokItem.CookStage.RAW_LOADED
			if wok.add_chili():
				player.consume_held_item(); player.notify_feedback("辣椒已加入%s" % ("，记录过早标签" if early else ""))
		ItemData.ItemType.SALT:
			if wok.add_salt():
				player.consume_held_item(); player.notify_feedback("已加入盐；进度保持")


func _insert_into_pan(player: Node, pan: PanItem, held_data: ItemData) -> void:
	match held_data.item_type:
		ItemData.ItemType.COOKING_OIL:
			if pan.add_oil():
				player.consume_held_item(); player.notify_feedback("煎锅已加油")
		ItemData.ItemType.RAW_STEAK:
			if pan.insert_steak(held_data):
				player.consume_held_item(); player.notify_feedback("生牛排已下锅")
		ItemData.ItemType.SALT:
			if pan.add_salt():
				player.consume_held_item(); player.notify_feedback("战斧牛排煎制中已加盐；进度保持")


func _insert_into_soup(player: Node, pot: SoupPotItem, held_data: ItemData) -> void:
	if held_data.item_type != ItemData.ItemType.RAW_BEEF_SLICES or not pot.insert_slice(held_data):
		return
	if held_data.remaining_portions > 1:
		held_data.remaining_portions -= 1
		player.held_item.refresh_visual()
		player.inventory.notify_item_changed()
	else:
		player.consume_held_item()
	player.notify_feedback("投入 1 片生牛肉；剩余 %d 片" % maxi(0, held_data.remaining_portions))


func _can_insert_selected_item(item_data: ItemData) -> bool:
	if cookware_item == null or cookware_item.is_stuck():
		return false
	if cookware_item is WokItem:
		var wok := cookware_item as WokItem
		match item_data.item_type:
			ItemData.ItemType.COOKING_OIL:
				return wok.content_data == null and wok.wok_state == WokItem.WokState.CLEAN
			ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES:
				return wok.can_insert_meat(item_data)
			ItemData.ItemType.CHILI_SEGMENTS:
				return wok.can_add_chili()
			ItemData.ItemType.SALT:
				return wok.can_add_salt()
	if cookware_item is PanItem:
		var pan := cookware_item as PanItem
		match item_data.item_type:
			ItemData.ItemType.COOKING_OIL:
				return pan.content_data == null and pan.pan_state == PanItem.PanState.CLEAN
			ItemData.ItemType.RAW_STEAK:
				return pan.content_data == null
			ItemData.ItemType.SALT:
				return pan.can_add_salt()
	if cookware_item is SoupPotItem:
		return item_data.item_type == ItemData.ItemType.RAW_BEEF_SLICES and (cookware_item as SoupPotItem).can_insert_slice()
	return false


func _get_content_data() -> ItemData:
	if cookware_item is WokItem:
		return (cookware_item as WokItem).content_data
	if cookware_item is PanItem:
		return (cookware_item as PanItem).content_data
	if cookware_item is SoupPotItem:
		return (cookware_item as SoupPotItem).content_data
	return null


func _take_content() -> ItemData:
	if cookware_item is WokItem:
		return (cookware_item as WokItem).take_content()
	if cookware_item is PanItem:
		return (cookware_item as PanItem).take_content()
	if cookware_item is SoupPotItem:
		return (cookware_item as SoupPotItem).take_content()
	return null


func _trigger_no_oil_accident(player: Node = null) -> void:
	var charcoal_data: ItemData
	if cookware_item is WokItem:
		charcoal_data = (cookware_item as WokItem).trigger_no_oil_accident()
	elif cookware_item is PanItem:
		charcoal_data = (cookware_item as PanItem).trigger_no_oil_accident()
	else:
		return
	var charcoal := ItemFactory.create_carryable(charcoal_data)
	get_tree().current_scene.add_child(charcoal)
	charcoal.global_position = global_position + Vector2(0.0, 94.0)
	hold_progress.cancel()
	active_stage = -1
	last_event_text = "严重事故：无油加热，焦炭 +【粘锅】"
	if player != null:
		player.notify_feedback(last_event_text)
	_refresh_status()


func _interrupt_current_stage(reason: String) -> void:
	hold_progress.cancel()
	last_event_text = "%s：当前未完成阶段归零，已完成状态与投料保留" % reason
	active_stage = _get_current_stage()


func _get_current_stage() -> int:
	if cookware_item is WokItem:
		return (cookware_item as WokItem).cook_stage
	if cookware_item is PanItem:
		return (cookware_item as PanItem).cook_stage
	if cookware_item is SoupPotItem:
		return (cookware_item as SoupPotItem).cook_stage
	return -1


func _get_wok_duration(stage: int) -> float:
	match stage:
		WokItem.CookStage.RAW_LOADED: return config.automatic_stage_one_time
		WokItem.CookStage.STAGE_ONE_DONE: return config.automatic_stage_two_time
		WokItem.CookStage.STAGE_TWO_DONE: return config.automatic_burn_time
		WokItem.CookStage.BURNT_TAGGED: return config.automatic_charcoal_time
	return 1.0


func _get_pan_duration(stage: int) -> float:
	match stage:
		PanItem.CookStage.FIRST_SIDE: return config.pan_first_side_time
		PanItem.CookStage.FLIP_WINDOW: return config.pan_flip_window_time
		PanItem.CookStage.SECOND_SIDE: return config.pan_second_side_time
		PanItem.CookStage.READY: return config.pan_ready_to_burn_time
		PanItem.CookStage.BURNT_TAGGED: return config.pan_burnt_to_charcoal_time
	return 1.0


func _get_soup_duration(stage: int) -> float:
	match stage:
		SoupPotItem.CookStage.WATER_HEATING: return config.soup_water_heat_time
		SoupPotItem.CookStage.SLICE_COOKING: return config.shabu_cook_time
		SoupPotItem.CookStage.READY: return config.shabu_overcook_time
		SoupPotItem.CookStage.OVERCOOKED: return config.shabu_mushy_time
	return 1.0


func get_debug_state() -> String:
	if cookware_item == null:
		return "通用灶位\n灶火：%s\n锅具：无\n进度：0%%" % ("开启" if burner_on else "关闭")
	return "通用灶位\n灶火：%s\n%s\n进度：%d%%\n最近事件：%s" % ["开启" if burner_on else "关闭", cookware_item.get_debug_description(), roundi(get_progress_ratio() * 100.0), last_event_text]


func _build_circular_indicator() -> void:
	circular_indicator = CircularCookingIndicator.new()
	circular_indicator.name = "CircularCookingIndicator"
	circular_indicator.position = Vector2(0.0, -108.0)
	add_child(circular_indicator)


func _create_initial_cookware() -> void:
	match initial_cookware_type:
		ItemData.ItemType.PAN:
			var pan := PanItem.new(); pan.setup_pan(station_id); cookware_item = pan
		ItemData.ItemType.SOUP_POT:
			var pot := SoupPotItem.new(); pot.setup_soup_pot(station_id); cookware_item = pot
		_:
			var wok := WokItem.new(); wok.setup_wok(station_id); cookware_item = wok
	add_child(cookware_item)
	cookware_item.set_stored(self, Vector2(0.0, -10.0))


func set_session_active(value: bool) -> void:
	session_active = value
	if not session_active:
		hold_progress.cancel()
	_refresh_status()


func reset_for_new_game() -> void:
	session_active = false
	burner_on = false
	hold_progress.cancel()
	active_stage = -1
	last_event_text = "等待开火"
	if cookware_item != null and is_instance_valid(cookware_item):
		cookware_item.queue_free()
	cookware_item = null
	_create_initial_cookware()
	_refresh_status()


func _refresh_status() -> void:
	_refresh_circular_indicator()
	if placeholder == null:
		return
	var fire_text := "🔥开启" if burner_on else "关闭"
	if cookware_item == null:
		set_placeholder_status("灶火%s / 空灶位" % fire_text)
		placeholder.set_color(Color("55484b"))
	elif cookware_item.is_stuck():
		set_placeholder_status("灶火%s / %s【粘锅】" % [fire_text, cookware_item.get_cookware_name()])
		placeholder.set_color(Color("5a3333"))
	else:
		set_placeholder_status("灶火%s / %s / %s" % [fire_text, cookware_item.get_cookware_name(), _get_stage_text()])
		placeholder.set_color(Color("c27635") if burner_on else Color("7a5551"))


func _get_stage_text() -> String:
	if cookware_item == null: return "无锅具"
	if _get_content_data() == null:
		if cookware_item is SoupPotItem and (cookware_item as SoupPotItem).has_water:
			return "水已沸腾" if (cookware_item as SoupPotItem).cook_stage == SoupPotItem.CookStage.BOILING else "加热水中"
		return "空锅"
	if cookware_item is WokItem:
		return ["空锅", "第一阶段短炒", "等待辣椒/第二阶段", "成菜等待取出", "焦糊", "焦炭"][(cookware_item as WokItem).cook_stage]
	if cookware_item is PanItem:
		return ["空锅", "第一面煎制", "翻面窗口", "第二面煎制", "战斧牛排完成", "焦糊", "焦炭"][(cookware_item as PanItem).cook_stage]
	if cookware_item is SoupPotItem:
		return ["空锅", "加热水", "沸腾", "涮煮", "涮牛肉完成", "煮老", "煮烂"][(cookware_item as SoupPotItem).cook_stage]
	return "未知"


func _refresh_circular_indicator() -> void:
	if circular_indicator == null:
		return
	if cookware_item == null:
		circular_indicator.hide_indicator(); return
	if cookware_item.is_stuck():
		circular_indicator.set_indicator("stuck", 1.0, Color("ef476f"), CircularCookingIndicator.Symbol.STUCK, false, true); return
	if not burner_on:
		circular_indicator.set_indicator("burner_off", 1.0, Color("adb5bd"), CircularCookingIndicator.Symbol.OFF, false); return
	var ratio := get_progress_ratio()
	if _get_content_data() == null:
		if cookware_item is SoupPotItem and (cookware_item as SoupPotItem).cook_stage == SoupPotItem.CookStage.WATER_HEATING:
			circular_indicator.set_indicator("water_heat", ratio, Color("4cc9f0"), CircularCookingIndicator.Symbol.NONE, true)
		else:
			circular_indicator.set_indicator("empty_fire", 1.0, Color("f4a261"), CircularCookingIndicator.Symbol.FIRE, false)
		return
	var state_key := "cooking"
	var color := Color("4cc9f0")
	var symbol := CircularCookingIndicator.Symbol.NONE
	var flashing := false
	if cookware_item is WokItem:
		var stage := (cookware_item as WokItem).cook_stage
		if stage == WokItem.CookStage.RAW_LOADED:
			state_key = "stage_one"; color = Color("4cc9f0")
		elif stage == WokItem.CookStage.STAGE_ONE_DONE and not (cookware_item as WokItem).content_data.has_component(ItemData.ComponentType.CHILI_SEGMENTS):
			state_key = "waiting_chili"; color = Color("ffd166"); symbol = CircularCookingIndicator.Symbol.WAIT; flashing = true
		elif stage == WokItem.CookStage.STAGE_ONE_DONE:
			state_key = "stage_two"; color = Color("52b788")
		elif stage == WokItem.CookStage.STAGE_TWO_DONE:
			if hold_progress.active and ratio >= config.burn_warning_ratio:
				state_key = "burn_warning"; color = Color("ef476f"); symbol = CircularCookingIndicator.Symbol.WAIT; flashing = true
			else:
				state_key = "dish_ready"; color = Color("f4a261"); symbol = CircularCookingIndicator.Symbol.DONE
		elif stage == WokItem.CookStage.BURNT_TAGGED:
			state_key = "burnt_to_charcoal"; color = Color("9d4edd"); symbol = CircularCookingIndicator.Symbol.BURNT; flashing = true
		elif stage == WokItem.CookStage.CHARCOAL:
			state_key = "charcoal"; color = Color("55555d"); symbol = CircularCookingIndicator.Symbol.CHARCOAL
	elif cookware_item is PanItem:
		var stage := (cookware_item as PanItem).cook_stage
		if stage == PanItem.CookStage.FLIP_WINDOW:
			state_key = "flip"; color = Color("ffd166"); symbol = CircularCookingIndicator.Symbol.WAIT; flashing = true
		elif stage == PanItem.CookStage.READY:
			state_key = "steak_ready"; color = Color("f4a261"); symbol = CircularCookingIndicator.Symbol.DONE
		elif stage == PanItem.CookStage.BURNT_TAGGED:
			state_key = "burnt"; color = Color("9d4edd"); symbol = CircularCookingIndicator.Symbol.BURNT; flashing = true
		elif stage == PanItem.CookStage.CHARCOAL:
			state_key = "charcoal"; color = Color("55555d"); symbol = CircularCookingIndicator.Symbol.CHARCOAL
	elif cookware_item is SoupPotItem:
		var stage := (cookware_item as SoupPotItem).cook_stage
		if stage == SoupPotItem.CookStage.READY:
			state_key = "shabu_ready"; color = Color("f4a261"); symbol = CircularCookingIndicator.Symbol.DONE
		elif stage == SoupPotItem.CookStage.OVERCOOKED:
			state_key = "overboiled"; color = Color("9d4edd"); symbol = CircularCookingIndicator.Symbol.BURNT; flashing = true
		elif stage == SoupPotItem.CookStage.MUSHY:
			state_key = "mushy"; color = Color("55555d"); symbol = CircularCookingIndicator.Symbol.CHARCOAL
	circular_indicator.set_indicator(state_key, ratio if hold_progress.active else 1.0, color, symbol, hold_progress.active, flashing)
