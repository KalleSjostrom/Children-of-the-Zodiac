extends Control
## An item of equipment (phase 4.2 step B, docs/ARCHITECTURE.md section 14),
## as StatusPage.drawEquip draws it: its picture, its name, the two slot
## labels, its slots (in the weapons' row or the armours'), its eight
## percentages. The layout is MenuValues.STATUS_X / STATUS_Y's; the node's y
## is the item's offset (324 on the equip page and in the Weapon Store).

## The y of the slots of a weapon and of another item, from the item's top
## (MenuValues.STATUS_Y[8] and [9]).
@export var slot_rows := PackedInt32Array([53, 93])
## The distance between two slots (Slot.DISTANCE).
@export var slot_distance := 50

@onready var _picture: TextureRect = $Picture
@onready var _texts: Array[BaselineLabel] = [$Name, $OffLabel, $DefLabel, $Lines/Attack,
	$Lines/Magic, $Lines/Support, $Lines/Agility, $Lines/Defence, $Lines/MagicDefence, $Lines/Hit,
	$Lines/Evade]
@onready var _slots: Control = $Slots


## The item at offset (its y): its picture ([texture, rect, tint]; [] for
## none), texts (the name, the two slot labels, the eight percentages) in
## colors at font_size in the bold font or not, its slots ([texture, tint]
## each) in the weapons' row or the other. mat is the material of the legacy
## drawing (Graphics.canvas_material).
func show_item(offset: int, picture: Array, texts: PackedStringArray, colors: Array[Color],
		font_size: int, bold: bool, weapon: bool, slots: Array, mat: Material) -> void:
	position.y = offset
	material = mat
	_picture.visible = not picture.is_empty()
	if _picture.visible:
		var r: Rect2i = picture[1]
		_picture.texture = picture[0]
		_picture.size = Vector2(r.size)
		_picture.self_modulate = picture[2]
	var role := MenuText.role(font_size)
	for i in _texts.size():
		_texts[i].text = texts[i]
		_texts[i].color = colors[i]
		_texts[i].theme_type_variation = role
		_texts[i].bold = bold
	_slots.position.y = slot_rows[0 if weapon else 1]
	_slots.show_row(slots, slot_distance)
