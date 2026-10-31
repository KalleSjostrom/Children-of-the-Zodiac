extends Control
## A character's status line (phase 4.2 step B, docs/ARCHITECTURE.md section
## 14), as StatusPage.drawTop draws it: the portrait, the name, the class, the
## level, the HP (or "Dead"), the two slot labels and the slots of the weapon
## and of the armour and left hand, each slot in the colour of a comparison
## (white, red for one an item would take away, green for one it would add).
## The layout is MenuValues.STATUS_X / STATUS_Y's; the node's y is the line's
## offset (the start and tutorial pages draw a line per character, 190 px
## apart). The start, deck and tutorial pages show it on its own; EquipStatus
## (the equip page, the Weapon Store) has one.

## The distance between two slots (Slot.DISTANCE).
@export var slot_distance := 50

@onready var _portrait: TextureRect = $Portrait
@onready var _texts: Array[BaselineLabel] = [$Name, $Class, $Level, $Hp, $OffLabel, $DefLabel]
@onready var _slots: Array[Control] = [$OffSlots, $DefSlots]


## The line at offset (its y): the portrait ([texture, rect, tint] at the
## table's place; [] for none), texts (the name, "Class: …", "Level: …",
## "Hp: …" or "Dead", "Off. Slots: ", "Def. Slots: "), colors (the text
## colour of each), font_size and bold; slots: the weapon's and the armour's
## slots, [texture, tint] each, in drawing order. mat is the material of the
## legacy drawing (Graphics.canvas_material).
func show_line(offset: int, portrait: Array, texts: PackedStringArray, colors: Array[Color],
		font_size: int, bold: bool, slots: Array, mat: Material) -> void:
	position.y = offset
	material = mat
	_portrait.visible = not portrait.is_empty()
	if _portrait.visible:
		var r: Rect2i = portrait[1]
		_portrait.texture = portrait[0]
		_portrait.size = Vector2(r.size)
		_portrait.self_modulate = portrait[2]
	var role := MenuText.role(font_size)
	for i in _texts.size():
		_texts[i].text = texts[i]
		_texts[i].color = colors[i]
		_texts[i].theme_type_variation = role
		_texts[i].bold = bold
	for row in _slots.size():
		_slots[row].show_row(slots[row], slot_distance)
