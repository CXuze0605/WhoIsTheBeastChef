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
var stirring_active: bool = false
var pan_pressing_active: bool = false
var unattended_stir_time: float = 0.0
var flash_qte_active: bool = false
var flash_qte_ratio: float = 0.0
var flash_qte_direction: float = 1.0
var flash_qte_attempts: int = 0
var flash_smoke: FlashStirSmoke


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
		advance_automatic_cooking(delta, null, false)
		_update_unattended_wok_risk(delta)
	if flash_qte_active:
		flash_qte_ratio += flash_qte_direction * config.flash_stir_qte_speed * delta
		if flash_qte_ratio >= 1.0:
			flash_qte_ratio = 1.0
			flash_qte_direction = -1.0
		elif flash_qte_ratio <= 0.0:
			flash_qte_ratio = 0.0
			flash_qte_direction = 1.0
	warning_flash_time += delta
	_refresh_status()


func get_carry_prompt(player: Node) -> String:
	if cookware_item == null:
		return "灶位为空；[%s] 放置锅具" % InputPrompt.action_text(&"interact_cookware", "R") if player.held_item is CookwareItem else "灶位为空"
	if player.held_item != null and _can_insert_selected_item(player.held_item.data):
		return "[%s] 向%s加入 %s" % [InputPrompt.action_text(&"interact_carry", "F"), cookware_item.get_cookware_name(), player.held_item.data.display_name]
	var content := _get_content_data()
	if content != null and player.can_receive_item_data(content):
		return "[%s] 取出 %s" % [InputPrompt.action_text(&"interact_carry", "F"), content.display_name]
	return ""


func carry_interact(player: Node) -> void:
	if cookware_item == null:
		player.notify_feedback("灶位为空：请使用 [%s] 放置锅具" % InputPrompt.action_text(&"interact_cookware", "R"))
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
		return "[%s] 拿起%s" % [InputPrompt.action_text(&"interact_cookware", "R"), cookware_item.get_cookware_name()]
	if cookware_item == null and player.held_item is CookwareItem:
		return "[%s] 将%s放到灶位" % [InputPrompt.action_text(&"interact_cookware", "R"), (player.held_item as CookwareItem).get_cookware_name()]
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
	var interact_key := InputPrompt.action_text(&"interact_primary", "E")
	if flash_qte_active:
		return "[%s] 炝炒 QTE 确认（指针 %.0f%%）" % [interact_key, flash_qte_ratio * 100.0]
	if cookware_item is PanItem and (cookware_item as PanItem).cook_stage == PanItem.CookStage.FLIP_WINDOW:
		return "[%s] 翻面" % interact_key
	if cookware_item is PanItem and (cookware_item as PanItem).cook_stage == PanItem.CookStage.PRESS_READY:
		return "[按住 %s] 压制米饼" % interact_key
	if cookware_item is PanItem and (cookware_item as PanItem).cook_stage == PanItem.CookStage.FIRST_SIDE and (cookware_item as PanItem).is_rice_cake():
		return "[%s] 提前翻面（会产生外焦里生）" % interact_key
	if burner_on and _wok_can_be_stirred():
		return "[按住 %s] 主动翻炒" % interact_key
	return "[%s] %s灶火" % [interact_key, "关闭" if burner_on else "开启"]


func begin_primary_interaction(player: Node) -> bool:
	if flash_qte_active:
		confirm_flash_stir_qte(
			flash_qte_ratio >= config.qte_perfect_min and flash_qte_ratio <= config.qte_perfect_max,
			player
		)
		return false
	if cookware_item is PanItem:
		var pan := cookware_item as PanItem
		if pan.cook_stage == PanItem.CookStage.PRESS_READY and pan.begin_pressing():
			active_stage = pan.cook_stage
			hold_progress.begin(config.rice_cake_press_time)
			pan_pressing_active = true
			last_event_text = "正在压制米饼"
			_refresh_status()
			return true
		if pan.cook_stage == PanItem.CookStage.FIRST_SIDE and pan.is_rice_cake():
			pan.flip_early()
			hold_progress.cancel()
			active_stage = pan.cook_stage
			last_event_text = "米饼提前翻面：记录【外焦里生】"
			player.notify_feedback(last_event_text)
			_refresh_status()
			return false
		if pan.cook_stage == PanItem.CookStage.FLIP_WINDOW:
			hold_progress.cancel()
			pan.flip(false)
			active_stage = pan.cook_stage
			last_event_text = "翻面成功；第二面开始自动煎制"
			player.notify_feedback(last_event_text)
			_refresh_status()
			return false
	if burner_on and _wok_can_be_stirred():
		var wok := cookware_item as WokItem
		active_stage = wok.cook_stage
		hold_progress.begin(_get_wok_duration(wok.cook_stage))
		stirring_active = true
		unattended_stir_time = 0.0
		last_event_text = "正在主动翻炒；松开会中断当前阶段"
		_refresh_status()
		return true
	set_burner_on(not burner_on, player)
	return false


func set_burner_on(value: bool, player: Node = null) -> void:
	if burner_on == value:
		return
	burner_on = value
	if not burner_on:
		_interrupt_current_stage("关火")
		stirring_active = false
		unattended_stir_time = 0.0
		last_event_text = "灶火已关闭；未完成阶段归零"
	else:
		last_event_text = "灶火已开启"
		advance_automatic_cooking(0.0, player)
	if player != null:
		player.notify_feedback(last_event_text)
	_refresh_status()


func advance_automatic_cooking(delta: float, player: Node = null, allow_active_stir_test_step: bool = true) -> bool:
	var freshness_content := _get_content_data()
	if freshness_content != null and freshness_content.is_rotten():
		hold_progress.cancel()
		stirring_active = false
		return false
	if not burner_on or cookware_item == null or cookware_item.is_stuck():
		if hold_progress.active:
			_interrupt_current_stage("加热条件中断")
		return false
	if cookware_item is WokItem:
		if _wok_can_be_stirred():
			# Historical tests and deterministic tooling call this public step
			# explicitly. Runtime `_process` opts out, so real cooking still
			# requires the hold-E interaction.
			if delta > 0.0 and allow_active_stir_test_step:
				return _advance_active_wok(delta, player, true)
			return false
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
	if (
		wok.cook_stage == WokItem.CookStage.STAGE_ONE_DONE
		and wok.pending_recipe != ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF
		and not wok.content_data.has_component(ItemData.ComponentType.CHILI_SEGMENTS)
	):
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
			if wok.pending_recipe == ExpandedRecipeCatalog.FRIED_WHITE_RICE:
				wok.complete_missing_group_1(config)
				last_event_text = "炒白饭完成"
			else:
				wok.complete_stage_one()
				last_event_text = "第一阶段短炒完成；等待分支材料"
		WokItem.CookStage.STAGE_ONE_DONE:
			if wok.pending_recipe == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF:
				wok.complete_missing_group_1(config)
				last_event_text = "清炒牛肉完成"
			else:
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
	if pan.cook_stage in [PanItem.CookStage.PRESS_READY, PanItem.CookStage.PRESSING]:
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
			if pan.is_rice_cake():
				pan.complete_rice_cake(config)
			else:
				pan.complete_steak()
				config.apply_tomahawk_stats(pan.content_data)
			last_event_text = "战斧牛排完成；可直接使用或完整装盘"
		PanItem.CookStage.READY:
			pan.mark_burnt(); last_event_text = "战斧牛排获得【焦糊】"
		PanItem.CookStage.BURNT_TAGGED:
			pan.turn_content_to_charcoal(); last_event_text = "战斧牛排变为焦炭"
	if pan.cook_stage == PanItem.CookStage.READY and pan.is_rice_cake():
		last_event_text = "米饼完成；可直接使用或摆盘"
	active_stage = pan.cook_stage
	_notify_stage(player)
	return true


func _advance_soup_pot(delta: float, player: Node = null) -> bool:
	var pot := cookware_item as SoupPotItem
	if not pot.has_water and pot.content_data == null:
		_cancel_empty_progress(SoupPotItem.CookStage.EMPTY)
		return false
	if pot.cook_stage == SoupPotItem.CookStage.BOILING and pot.content_data == null:
		_cancel_empty_progress(SoupPotItem.CookStage.BOILING)
		return false
	if pot.cook_stage == SoupPotItem.CookStage.MUSHY:
		_cancel_empty_progress(SoupPotItem.CookStage.MUSHY)
		return false
	if pot.cook_stage in [SoupPotItem.CookStage.PORRIDGE_READY, SoupPotItem.CookStage.CRISPY_BURNT]:
		_cancel_empty_progress(pot.cook_stage)
		return false
	if pot.cook_stage == SoupPotItem.CookStage.BEEF_SOUP_WAITING_GREENS:
		_cancel_empty_progress(pot.cook_stage)
		last_event_text = "牛肉汤底完成，等待加入青菜"
		return false
	if pot.cook_stage == SoupPotItem.CookStage.READY and pot.content_data != null and pot.content_data.recipe_id != &"":
		_cancel_empty_progress(pot.cook_stage)
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
		SoupPotItem.CookStage.RICE_COOKING, SoupPotItem.CookStage.PORRIDGE_COOKING:
			pot.complete_rice(config)
			last_event_text = "白米饭完成；可取出或继续加热为锅巴" if pot.cook_stage == SoupPotItem.CookStage.RICE_READY else "白粥完成；正在滚烫冷却"
		SoupPotItem.CookStage.RICE_READY:
			pot.complete_crispy_rice(config)
			last_event_text = "锅巴完成：已成为自动防具"
		SoupPotItem.CookStage.CRISPY_READY:
			pot.burn_crispy_rice(config)
			last_event_text = "锅巴继续过热并获得【焦糊】"
		SoupPotItem.CookStage.GREENS_COOKING, SoupPotItem.CookStage.ENRICHED_PORRIDGE_COOKING:
			pot.complete_expanded_recipe(config)
			last_event_text = "扩展煮制完成：%s" % pot.content_data.display_name
		SoupPotItem.CookStage.VEGETABLE_RICE_COOKING, SoupPotItem.CookStage.SOAKED_RICE_COOKING, SoupPotItem.CookStage.GREENS_SOAKED_RICE_COOKING:
			pot.complete_function_rice(config)
			last_event_text = "功能米饭完成：%s" % pot.content_data.display_name
		SoupPotItem.CookStage.BEEF_SOUP_BASE_COOKING:
			pot.complete_beef_soup_base()
			last_event_text = (
				"牛肉丁汤底完成：继续熬煮形成牛肉汤，形成前可加入青菜"
				if pot.pending_recipe == ExpandedRecipeCatalog.BEEF_SOUP
				else "牛肉汤底完成：等待加入青菜"
			)
		SoupPotItem.CookStage.BEEF_GREENS_SOUP_COOKING:
			pot.complete_beef_greens_soup(config)
			last_event_text = "青菜牛肉汤完成：可双击开启自动喷流"
		SoupPotItem.CookStage.GREENS_SOUP_BLANCHING:
			pot.complete_greens_soup_blanching(config)
			last_event_text = "青菜已焯熟：现在取出是盐水青菜，继续煮制为青菜汤"
		SoupPotItem.CookStage.GREENS_SOUP_FINISHING:
			pot.complete_greens_soup(config)
			last_event_text = "青菜汤完成：可直接使用或继续摆盘"
		SoupPotItem.CookStage.BEEF_SOUP_FINISHING:
			pot.complete_beef_soup(config)
			last_event_text = "牛肉汤完成：可直接使用或继续摆盘"
		SoupPotItem.CookStage.BEEF_SOUP_READY:
			pot.mark_overcooked()
			last_event_text = "牛肉汤继续熬煮并获得【煮老】"
	if pot.cook_stage in [
		SoupPotItem.CookStage.BEEF_BRAISED_RICE_COOKING,
		SoupPotItem.CookStage.GREENS_BEEF_BRAISED_RICE_COOKING,
	]:
		pot.complete_braised_rice(config)
		last_event_text = "焖饭完成：%s" % pot.content_data.display_name
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
	if pan_pressing_active:
		if not burner_on or not (cookware_item is PanItem) or (cookware_item as PanItem).cook_stage != PanItem.CookStage.PRESSING:
			pan_pressing_active = false
			hold_progress.cancel()
			return false
		if not hold_progress.advance(delta):
			return true
		(cookware_item as PanItem).finish_pressing()
		pan_pressing_active = false
		active_stage = (cookware_item as PanItem).cook_stage
		last_event_text = "压饼完成：第一面开始自动煎制"
		_notify_stage(player)
		return false
	if not stirring_active or not _wok_can_be_stirred() or not burner_on:
		stirring_active = false
		return false
	if not _advance_active_wok(delta, player):
		return true
	stirring_active = false
	unattended_stir_time = 0.0
	return false


func cancel_primary_interaction(player: Node) -> void:
	if pan_pressing_active:
		pan_pressing_active = false
		hold_progress.cancel()
		if cookware_item is PanItem and (cookware_item as PanItem).cook_stage == PanItem.CookStage.PRESSING:
			(cookware_item as PanItem).cook_stage = PanItem.CookStage.PRESS_READY
		player.notify_feedback("压饼中断：本阶段进度归零")
		_refresh_status()
		return
	if stirring_active:
		stirring_active = false
		if not config.active_stir_interrupt_keeps_progress:
			hold_progress.cancel()
		player.notify_feedback("翻炒中断：当前阶段进度归零，已投材料保留")
		last_event_text = "翻炒中断；已完成节点与投入材料保留"
		_refresh_status()


func blocks_movement_during_primary() -> bool:
	return stirring_active or pan_pressing_active


func _wok_can_be_stirred() -> bool:
	if not (cookware_item is WokItem) or cookware_item.is_stuck():
		return false
	var wok := cookware_item as WokItem
	if wok.content_data == null or wok.cook_stage not in [WokItem.CookStage.RAW_LOADED, WokItem.CookStage.STAGE_ONE_DONE]:
		return false
	if wok.cook_stage == WokItem.CookStage.RAW_LOADED:
		return wok.has_oil()
	if wok.pending_recipe in [
		ExpandedRecipeCatalog.STIR_FRY_GREENS,
		ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS,
		ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS,
	]:
		return false
	return (
		wok.pending_recipe == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF
		or wok.content_data.has_component(ItemData.ComponentType.CHILI_SEGMENTS)
	)


func _advance_active_wok(delta: float, player: Node, use_legacy_test_duration: bool = false) -> bool:
	var wok := cookware_item as WokItem
	if wok == null:
		return false
	if not hold_progress.active or active_stage != wok.cook_stage:
		active_stage = wok.cook_stage
		var duration := _get_wok_duration(wok.cook_stage)
		if use_legacy_test_duration:
			duration = (
				config.automatic_stage_one_time
				if wok.cook_stage == WokItem.CookStage.RAW_LOADED
				else config.automatic_stage_two_time
			)
		hold_progress.begin(duration)
	if not hold_progress.advance(delta):
		return false
	match wok.cook_stage:
		WokItem.CookStage.RAW_LOADED:
			if wok.pending_recipe == ExpandedRecipeCatalog.FRIED_WHITE_RICE:
				wok.complete_missing_group_1(config)
				last_event_text = "主动炒制完成：得到待摆盘炒白饭"
				active_stage = wok.cook_stage
				_notify_stage(player)
				return true
			if wok.pending_recipe in [
				ExpandedRecipeCatalog.SPICY_FRIED_RICE,
				ExpandedRecipeCatalog.SPICY_BEEF_GREENS,
				ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE,
				ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE,
			]:
				wok.complete_groups_6_7_wok(config)
				last_event_text = "主动炒制完成：%s" % wok.content_data.display_name
				active_stage = wok.cook_stage
				_notify_stage(player)
				return true
			if wok.pending_recipe in [
				ExpandedRecipeCatalog.BEEF_GREENS,
				ExpandedRecipeCatalog.GREENS_FRIED_RICE,
				ExpandedRecipeCatalog.MIXED_FRIED_RICE,
			] or (
				wok.pending_recipe == ExpandedRecipeCatalog.BEEF_FRIED_RICE
				and wok.recipe_sources.any(func(source: ItemData) -> bool: return source.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE)
			):
				wok.complete_wok_combination(config)
				last_event_text = "组合炒制完成：%s" % wok.content_data.display_name
				active_stage = wok.cook_stage
				_notify_stage(player)
				return true
			if wok.pending_recipe in [
				ExpandedRecipeCatalog.STIR_FRY_GREENS,
				ExpandedRecipeCatalog.SPICY_STIR_FRY_GREENS,
				ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS,
			]:
				if wok.pending_recipe == ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS:
					_begin_flash_stir_qte(player)
				else:
					wok.complete_greens(config)
					last_event_text = "主动炒制完成：%s" % wok.content_data.display_name
				active_stage = wok.cook_stage
				_notify_stage(player)
				return true
			wok.complete_stage_one()
			last_event_text = (
				"第一阶段完成：可加辣椒进入小炒黄牛肉，或继续炒成清炒牛肉"
				if wok.pending_recipe == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF
				else "第一阶段主动短炒完成；等待辣椒段"
			)
		WokItem.CookStage.STAGE_ONE_DONE:
			if wok.pending_recipe == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF:
				wok.complete_missing_group_1(config)
				last_event_text = "主动炒制完成：得到待摆盘清炒牛肉"
			else:
				wok.complete_stage_two()
				config.apply_combat_dish_stats(wok.content_data)
				last_event_text = "主动炒制完成：得到可直接使用或继续摆盘的小炒黄牛肉"
	active_stage = wok.cook_stage
	_notify_stage(player)
	return true


func _begin_flash_stir_qte(player: Node) -> void:
	flash_qte_active = true
	flash_qte_ratio = 0.0
	flash_qte_direction = 1.0
	flash_qte_attempts += 1
	last_event_text = "炝炒阶段完成：观察指针并按 %s 确认" % InputPrompt.action_text(&"interact_primary", "E")
	if player != null:
		player.notify_feedback(last_event_text)


func confirm_flash_stir_qte(success: bool, player: Node = null) -> bool:
	if not flash_qte_active or not (cookware_item is WokItem):
		return false
	flash_qte_active = false
	var wok := cookware_item as WokItem
	if success:
		wok.complete_greens(config)
		last_event_text = "炝炒 QTE 成功：料理完成，呛烟开始消散"
		if flash_smoke != null and is_instance_valid(flash_smoke):
			flash_smoke.begin_dissipating(config.flash_stir_smoke_duration)
	else:
		hold_progress.cancel()
		active_stage = wok.cook_stage
		last_event_text = "炝炒 QTE 失败：当前炒制段归零，材料保留"
	if player != null:
		player.notify_feedback(last_event_text)
	_refresh_status()
	return success


func _update_unattended_wok_risk(delta: float) -> void:
	if not burner_on or stirring_active or not _wok_can_be_stirred():
		unattended_stir_time = 0.0
		return
	unattended_stir_time += delta
	if unattended_stir_time < config.active_stir_unattended_burn_time:
		return
	unattended_stir_time = 0.0
	var wok := cookware_item as WokItem
	if wok.content_data != null and not wok.content_data.has_failure_tag(ItemData.FailureTag.BURNT):
		wok.content_data.add_failure_tag(ItemData.FailureTag.BURNT)
		wok.refresh_visual()
		last_event_text = "无人翻炒过久：料理获得【焦糊】风险标签"


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
				player.consume_held_resource_portion(ItemData.ItemType.COOKING_OIL)
				player.notify_feedback("炒锅已加油；油瓶剩余 %d/%d" % [maxi(0, held_data.remaining_portions), held_data.max_remaining_portions])
		ItemData.ItemType.GREENS_LEAF:
			if wok.add_combination_greens(held_data):
				player.consume_held_item()
				player.notify_feedback("整组 5 片青菜已加入组合炒制")
			elif wok.insert_greens(held_data):
				player.consume_held_item()
				player.notify_feedback("青菜叶已整组下锅（%d 片）" % wok.content_data.leaf_count)
				if wok.pending_recipe == ExpandedRecipeCatalog.FLASH_STIR_FRY_GREENS:
					_start_flash_smoke()
		ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE:
			if wok.insert_dice(held_data):
				player.consume_held_item()
				player.notify_feedback("牛肉丁已下锅：先完成第一阶段主动炒制")
		ItemData.ItemType.UNPLATED_WHITE_RICE:
			if wok.add_cooked_rice(held_data) or wok.insert_cooked_rice_base(held_data):
				player.consume_held_item()
				player.notify_feedback("完整未使用白米饭已加入：进入主动炒制")
		ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES:
			if wok.insert_meat(held_data):
				player.consume_held_item(); player.notify_feedback("牛肉片已整份下锅：第一阶段后可选择辣椒分支")
		ItemData.ItemType.CHILI_SEGMENTS:
			if wok.can_preheat_chili():
				if wok.preheat_chili(held_data):
					player.consume_held_item()
					player.notify_feedback("辣椒先入热油：进入炝香路线")
				return
			var early := wok.cook_stage == WokItem.CookStage.RAW_LOADED
			if wok.add_chili():
				player.consume_held_item(); player.notify_feedback("辣椒已加入%s" % ("，记录过早标签" if early else ""))
		ItemData.ItemType.SALT:
			if wok.add_salt():
				player.consume_held_resource_portion(ItemData.ItemType.SALT)
				player.notify_feedback("已加入盐；盐瓶剩余 %d/%d" % [maxi(0, held_data.remaining_portions), held_data.max_remaining_portions])


func _insert_into_pan(player: Node, pan: PanItem, held_data: ItemData) -> void:
	match held_data.item_type:
		ItemData.ItemType.COOKING_OIL:
			if pan.add_oil():
				player.consume_held_resource_portion(ItemData.ItemType.COOKING_OIL)
				player.notify_feedback("煎锅已加油；油瓶剩余 %d/%d" % [maxi(0, held_data.remaining_portions), held_data.max_remaining_portions])
		ItemData.ItemType.RAW_STEAK:
			if pan.insert_steak(held_data):
				player.consume_held_item(); player.notify_feedback("生牛排已下锅")
		ItemData.ItemType.UNPLATED_WHITE_RICE, ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE:
			if pan.insert_rice_cake_base(held_data):
				player.consume_held_item()
				player.notify_feedback("米饼原料已加入；材料完整后按住交互压饼")
		ItemData.ItemType.GREENS_CRUMBS:
			if pan.add_greens_crumbs(held_data):
				player.consume_held_item()
				player.notify_feedback("青菜碎已加入米饼：%d/5" % pan.content_data.leaf_count)
		ItemData.ItemType.SALT:
			if pan.add_salt():
				player.consume_held_resource_portion(ItemData.ItemType.SALT)
				player.notify_feedback("战斧牛排煎制中已加盐；盐瓶剩余 %d/%d" % [maxi(0, held_data.remaining_portions), held_data.max_remaining_portions])


func _insert_into_soup(player: Node, pot: SoupPotItem, held_data: ItemData) -> void:
	if held_data.item_type == ItemData.ItemType.CHILI_SEGMENTS:
		if pot.add_chili(held_data):
			player.consume_held_item()
			player.notify_feedback("辣椒已加入汤锅：进入辣味汤路线")
		return
	if held_data.item_type == ItemData.ItemType.SALT:
		if pot.add_salt(held_data):
			player.consume_held_resource_portion(ItemData.ItemType.SALT)
			player.notify_feedback("汤锅已加盐，可制作盐水青菜；盐瓶剩余 %d/%d" % [maxi(0, held_data.remaining_portions), held_data.max_remaining_portions])
		return
	if held_data.item_type in [ItemData.ItemType.GREENS_LEAF, ItemData.ItemType.GREENS_CRUMBS]:
		if pot.can_add_porridge_greens(held_data):
			if pot.add_porridge_greens(held_data, config):
				player.consume_held_item()
				player.notify_feedback("青菜加入牛肉粥：升级为青菜牛肉粥")
			return
		if pot.can_add_braised_rice_greens(held_data):
			if pot.add_braised_rice_greens(held_data, config):
				player.consume_held_item()
				player.notify_feedback("整组青菜加入未完成牛肉焖饭：升级为青菜牛肉焖饭")
			return
		if pot.can_add_beef_soup_greens(held_data):
			if pot.add_beef_soup_greens(held_data, config):
				player.consume_held_item()
				player.notify_feedback("青菜加入牛肉汤：有效叶数 %d/5" % pot.content_data.leaf_count)
			return
		if pot.can_add_vegetable_rice_greens(held_data):
			var recommended := hold_progress.get_ratio() >= 0.45
			if pot.add_vegetable_rice_greens(held_data, recommended, config):
				player.consume_held_item()
				player.notify_feedback("整组青菜加入半熟米饭：%s完美资格" % ("保留" if recommended else "顺序过早，失去"))
			return
		if pot.can_add_soaked_greens(held_data):
			if pot.add_soaked_greens(held_data, config):
				player.consume_held_item()
				player.notify_feedback("菜泡饭追加青菜：有效叶数 %d/5，短煮重新开始" % pot.content_data.leaf_count)
			return
		if pot.insert_greens(held_data):
			player.consume_held_item()
			player.notify_feedback("投入 %d 片青菜叶" % pot.content_data.leaf_count)
		return
	if held_data.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE:
		if pot.insert_cooked_rice(held_data, config):
			player.consume_held_item()
			player.notify_feedback("熟白米饭加一份水：开始快速制作泡饭")
		return
	if held_data.item_type in [ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE] and pot.can_add_braised_rice_beef(held_data):
		if pot.add_braised_rice_beef(held_data, config):
			player.consume_held_item()
			player.notify_feedback("整组牛肉丁加入一份水米饭：开始焖饭")
		return
	if held_data.item_type == ItemData.ItemType.MARINATED_BEEF_SLICES and pot.can_add_soaked_beef(held_data):
		if pot.add_soaked_beef(held_data, config):
			player.consume_held_item()
			player.notify_feedback("腌牛肉片加入泡饭：进入牛肉泡饭短煮")
		return
	if held_data.item_type in [ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES] and pot.can_insert_porridge_beef(held_data):
		if pot.insert_porridge_beef(held_data):
			player.consume_held_item()
			player.notify_feedback("整组牛肉片加入白粥：进入短煮阶段")
		return
	if held_data.item_type in [
		ItemData.ItemType.RAW_BEEF_SLICES,
		ItemData.ItemType.MARINATED_BEEF_SLICES,
		ItemData.ItemType.RAW_BEEF_DICE,
		ItemData.ItemType.MARINATED_BEEF_DICE,
	] and pot.can_insert_beef_soup_base(held_data):
		if pot.insert_beef_soup_base(held_data):
			player.consume_held_item()
			player.notify_feedback("两份水加入整组牛肉：开始汤底短煮")
		return
	if held_data.item_type == ItemData.ItemType.RAW_RICE:
		if pot.insert_rice(held_data):
			player.record_resource_consumed(ItemData.ItemType.RAW_RICE, 1)
			player.consume_held_item()
			player.notify_feedback("投入 1 份生米；使用 %s，开始烹饪" % ("1 份水" if pot.cook_stage == SoupPotItem.CookStage.RICE_COOKING else "2 份水"))
		return
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
			ItemData.ItemType.GREENS_LEAF:
				return wok.can_add_combination_greens(item_data) or wok.can_insert_greens(item_data)
			ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE:
				return wok.can_insert_dice(item_data)
			ItemData.ItemType.UNPLATED_WHITE_RICE:
				return wok.can_add_cooked_rice(item_data) or wok.can_insert_cooked_rice_base(item_data)
			ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES:
				return wok.can_insert_meat(item_data)
			ItemData.ItemType.CHILI_SEGMENTS:
				return wok.can_preheat_chili() or wok.can_add_chili()
			ItemData.ItemType.SALT:
				return wok.can_add_salt()
	if cookware_item is PanItem:
		var pan := cookware_item as PanItem
		match item_data.item_type:
			ItemData.ItemType.COOKING_OIL:
				return pan.content_data == null and pan.pan_state == PanItem.PanState.CLEAN
			ItemData.ItemType.RAW_STEAK:
				return pan.content_data == null
			ItemData.ItemType.UNPLATED_WHITE_RICE, ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE:
				return pan.can_insert_rice_cake_base(item_data)
			ItemData.ItemType.GREENS_CRUMBS:
				return pan.can_add_greens_crumbs(item_data)
			ItemData.ItemType.SALT:
				return pan.can_add_salt()
	if cookware_item is SoupPotItem:
		if item_data.item_type == ItemData.ItemType.CHILI_SEGMENTS:
			return (cookware_item as SoupPotItem).can_add_chili()
		if item_data.item_type == ItemData.ItemType.SALT:
			return (cookware_item as SoupPotItem).can_add_salt()
		if item_data.item_type in [ItemData.ItemType.GREENS_LEAF, ItemData.ItemType.GREENS_CRUMBS]:
			var soup_pot := cookware_item as SoupPotItem
			return soup_pot.can_add_porridge_greens(item_data) or soup_pot.can_add_braised_rice_greens(item_data) or soup_pot.can_add_beef_soup_greens(item_data) or soup_pot.can_add_vegetable_rice_greens(item_data) or soup_pot.can_add_soaked_greens(item_data) or soup_pot.can_insert_greens(item_data)
		if item_data.item_type == ItemData.ItemType.UNPLATED_WHITE_RICE:
			return (cookware_item as SoupPotItem).can_insert_cooked_rice(item_data)
		if item_data.item_type in [ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES] and (cookware_item as SoupPotItem).can_insert_porridge_beef(item_data):
			return true
		if item_data.item_type == ItemData.ItemType.MARINATED_BEEF_SLICES and (cookware_item as SoupPotItem).can_add_soaked_beef(item_data):
			return true
		if item_data.item_type in [ItemData.ItemType.RAW_BEEF_SLICES, ItemData.ItemType.MARINATED_BEEF_SLICES] and (cookware_item as SoupPotItem).can_insert_beef_soup_base(item_data):
			return true
		if item_data.item_type in [ItemData.ItemType.RAW_BEEF_DICE, ItemData.ItemType.MARINATED_BEEF_DICE]:
			return (cookware_item as SoupPotItem).can_add_braised_rice_beef(item_data) or (cookware_item as SoupPotItem).can_insert_beef_soup_base(item_data)
		if item_data.item_type == ItemData.ItemType.RAW_BEEF_SLICES:
			return (cookware_item as SoupPotItem).can_insert_slice()
		if item_data.item_type == ItemData.ItemType.RAW_RICE:
			return (cookware_item as SoupPotItem).can_insert_rice()
	return false


func _get_content_data() -> ItemData:
	if cookware_item is WokItem:
		return (cookware_item as WokItem).content_data
	if cookware_item is PanItem:
		return (cookware_item as PanItem).content_data
	if cookware_item is SoupPotItem:
		return (cookware_item as SoupPotItem).content_data
	return null


func get_freshness_content_data() -> ItemData:
	return _get_content_data()


func get_freshness_pause_reason(data: ItemData) -> String:
	if data == null or data != _get_content_data() or not burner_on:
		return ""
	if cookware_item is WokItem:
		return "有效主动炒制" if stirring_active and hold_progress.active else ""
	if cookware_item is PanItem or cookware_item is SoupPotItem:
		return "有效加热推进" if hold_progress.active else ""
	return ""


func handle_rotten_item_data(data: ItemData) -> void:
	if data != _get_content_data():
		return
	hold_progress.cancel()
	stirring_active = false
	flash_qte_active = false
	last_event_text = "锅内内容已腐败；请取出处理"
	_refresh_status()


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


func _start_flash_smoke() -> void:
	if flash_smoke != null and is_instance_valid(flash_smoke):
		return
	flash_smoke = FlashStirSmoke.new()
	get_tree().current_scene.add_child(flash_smoke)
	flash_smoke.setup(global_position, 185.0)


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
	if cookware_item is WokItem:
		var wok := cookware_item as WokItem
		if wok.pending_recipe in [
			ExpandedRecipeCatalog.SPICY_FRIED_RICE,
			ExpandedRecipeCatalog.SPICY_BEEF_GREENS,
			ExpandedRecipeCatalog.SPICY_BEEF_FRIED_RICE,
			ExpandedRecipeCatalog.SPICY_MIXED_FRIED_RICE,
		]:
			return config.fried_white_rice_stir_time
		if wok.pending_recipe == ExpandedRecipeCatalog.FRIED_WHITE_RICE:
			return config.fried_white_rice_stir_time
		if wok.pending_recipe == ExpandedRecipeCatalog.CLEAR_STIR_FRY_BEEF:
			return config.clear_beef_stage_one_time if stage == WokItem.CookStage.RAW_LOADED else config.clear_beef_stage_two_time
	match stage:
		WokItem.CookStage.RAW_LOADED: return config.active_stir_stage_one_time
		WokItem.CookStage.STAGE_ONE_DONE: return config.active_stir_stage_two_time
		WokItem.CookStage.STAGE_TWO_DONE: return config.automatic_burn_time
		WokItem.CookStage.BURNT_TAGGED: return config.automatic_charcoal_time
	return 1.0


func _get_pan_duration(stage: int) -> float:
	if cookware_item is PanItem and (cookware_item as PanItem).is_rice_cake():
		match stage:
			PanItem.CookStage.FIRST_SIDE: return config.rice_cake_first_side_time
			PanItem.CookStage.FLIP_WINDOW: return config.rice_cake_flip_late_time
			PanItem.CookStage.SECOND_SIDE: return config.rice_cake_second_side_time
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
		SoupPotItem.CookStage.RICE_COOKING: return config.white_rice_cook_time
		SoupPotItem.CookStage.PORRIDGE_COOKING: return config.rice_porridge_cook_time
		SoupPotItem.CookStage.RICE_READY: return config.crispy_rice_cook_time
		SoupPotItem.CookStage.CRISPY_COOKING: return config.crispy_rice_cook_time
		SoupPotItem.CookStage.CRISPY_READY: return config.crispy_rice_burn_time
		SoupPotItem.CookStage.GREENS_COOKING: return config.greens_porridge_short_cook_time
		SoupPotItem.CookStage.ENRICHED_PORRIDGE_COOKING:
			if (cookware_item as SoupPotItem).pending_recipe == ExpandedRecipeCatalog.GREENS_BEEF_PORRIDGE:
				return config.greens_beef_porridge_cook_time
			return config.greens_porridge_short_cook_time if (cookware_item as SoupPotItem).pending_recipe == ExpandedRecipeCatalog.GREENS_PORRIDGE else config.beef_porridge_short_cook_time
		SoupPotItem.CookStage.VEGETABLE_RICE_COOKING: return config.vegetable_rice_cook_time
		SoupPotItem.CookStage.SOAKED_RICE_COOKING: return config.soaked_rice_cook_time
		SoupPotItem.CookStage.GREENS_SOAKED_RICE_COOKING:
			return (
				config.group_4_soaked_rice_cook_time
				if (cookware_item as SoupPotItem).pending_recipe in [
					ExpandedRecipeCatalog.BEEF_SOAKED_RICE,
					ExpandedRecipeCatalog.GREENS_BEEF_SOAKED_RICE,
				]
				else config.greens_soaked_rice_cook_time
			)
		SoupPotItem.CookStage.BEEF_SOUP_BASE_COOKING:
			return config.beef_soup_stage_one_time if (cookware_item as SoupPotItem).pending_recipe in [ExpandedRecipeCatalog.BEEF_SOUP, ExpandedRecipeCatalog.SPICY_BEEF_SOUP] else config.soup_base_cook_time
		SoupPotItem.CookStage.BEEF_GREENS_SOUP_COOKING: return config.beef_greens_soup_finish_time
		SoupPotItem.CookStage.GREENS_SOUP_BLANCHING: return config.greens_porridge_short_cook_time
		SoupPotItem.CookStage.GREENS_SOUP_FINISHING: return config.greens_soup_finish_time
		SoupPotItem.CookStage.BEEF_SOUP_FINISHING: return config.beef_soup_finish_time
		SoupPotItem.CookStage.BEEF_SOUP_READY: return config.beef_soup_overcook_time
		SoupPotItem.CookStage.BEEF_BRAISED_RICE_COOKING, SoupPotItem.CookStage.GREENS_BEEF_BRAISED_RICE_COOKING:
			return config.beef_braised_rice_cook_time
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
		stirring_active = false
		unattended_stir_time = 0.0
		flash_qte_active = false
		if flash_smoke != null and is_instance_valid(flash_smoke):
			flash_smoke._clear_and_free()
		flash_smoke = null
	_refresh_status()


func reset_for_new_game() -> void:
	session_active = false
	burner_on = false
	hold_progress.cancel()
	stirring_active = false
	unattended_stir_time = 0.0
	flash_qte_active = false
	flash_qte_ratio = 0.0
	if flash_smoke != null and is_instance_valid(flash_smoke):
		flash_smoke._clear_and_free()
	flash_smoke = null
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
		return {
			SoupPotItem.CookStage.EMPTY: "空锅",
			SoupPotItem.CookStage.WATER_HEATING: "加热水",
			SoupPotItem.CookStage.BOILING: "沸腾",
			SoupPotItem.CookStage.SLICE_COOKING: "涮煮",
			SoupPotItem.CookStage.READY: "涮牛肉完成",
			SoupPotItem.CookStage.OVERCOOKED: "煮老",
			SoupPotItem.CookStage.MUSHY: "煮烂",
			SoupPotItem.CookStage.RICE_COOKING: "白米饭烹煮",
			SoupPotItem.CookStage.RICE_READY: "白米饭完成",
			SoupPotItem.CookStage.PORRIDGE_COOKING: "白粥熬煮",
			SoupPotItem.CookStage.PORRIDGE_READY: "白粥完成 · 滚烫",
			SoupPotItem.CookStage.CRISPY_COOKING: "形成锅巴",
			SoupPotItem.CookStage.CRISPY_READY: "锅巴完成",
			SoupPotItem.CookStage.CRISPY_BURNT: "锅巴焦糊",
			SoupPotItem.CookStage.GREENS_COOKING: "盐水青菜短煮",
			SoupPotItem.CookStage.ENRICHED_PORRIDGE_COOKING: "粥料短煮",
			SoupPotItem.CookStage.VEGETABLE_RICE_COOKING: "菜饭焖煮",
			SoupPotItem.CookStage.SOAKED_RICE_COOKING: "泡饭快煮",
			SoupPotItem.CookStage.GREENS_SOAKED_RICE_COOKING: "菜泡饭短煮",
			SoupPotItem.CookStage.BEEF_SOUP_BASE_COOKING: "牛肉汤底短煮",
			SoupPotItem.CookStage.BEEF_SOUP_WAITING_GREENS: "等待加入青菜",
			SoupPotItem.CookStage.BEEF_GREENS_SOUP_COOKING: "青菜牛肉汤收尾",
		}.get((cookware_item as SoupPotItem).cook_stage, "未知")
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
