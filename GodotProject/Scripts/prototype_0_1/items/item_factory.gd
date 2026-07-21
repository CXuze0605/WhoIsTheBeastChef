class_name ItemFactory
extends RefCounted


static func create_carryable(item_data: ItemData) -> CarryableItem:
	var item: CarryableItem
	if item_data.item_type == ItemData.ItemType.WOK:
		item = WokItem.new()
	elif item_data.item_type == ItemData.ItemType.PAN:
		item = PanItem.new()
	elif item_data.item_type == ItemData.ItemType.SOUP_POT:
		item = SoupPotItem.new()
	else:
		item = CarryableItem.new()
	item.setup(item_data)
	return item
