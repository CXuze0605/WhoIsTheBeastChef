class_name CookwareRack
extends Interactable

var soup_pot: SoupPotItem


func _ready() -> void:
	display_title = "备用锅具位"
	placeholder_size = Vector2(136.0, 72.0)
	placeholder_color = Color("4f657a")
	super._ready()
	add_to_group("cookware_rack")
	_create_soup_pot()
	_refresh_status()


func get_carry_prompt(player: Node) -> String:
	if soup_pot != null and player.can_receive_item(soup_pot):
		return "[F] 拿起汤锅"
	return ""


func carry_interact(player: Node) -> void:
	if soup_pot == null:
		player.notify_feedback("备用锅具位为空")
		return
	if not player.pickup_item(soup_pot):
		return
	soup_pot = null
	player.notify_feedback("已拿起汤锅；可在水池加水，再放到任一空灶位")
	_refresh_status()


func reset_for_new_game() -> void:
	if soup_pot != null and is_instance_valid(soup_pot):
		soup_pot.queue_free()
	soup_pot = null
	_create_soup_pot()
	_refresh_status()


func _create_soup_pot() -> void:
	soup_pot = SoupPotItem.new()
	soup_pot.setup_soup_pot(&"prototype_soup_rack")
	add_child(soup_pot)
	soup_pot.set_stored(self, Vector2(0.0, -8.0))


func _refresh_status() -> void:
	set_placeholder_status("汤锅待取" if soup_pot != null else "空")
