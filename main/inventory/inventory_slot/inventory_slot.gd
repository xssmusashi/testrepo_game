extends PanelContainer

@onready var icon_rect = $Icon
@onready var amount_label = $AmountLabel

func update_slot(item_id: String, amount: int):
	if item_id == "":
		icon_rect.texture = null
		amount_label.text = ""
	else:
		var data = ItemDb.get_item(item_id)
		if data:
			icon_rect.texture = data.icon
			amount_label.text = str(amount) if amount > 1 else ""
