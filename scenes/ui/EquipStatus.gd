extends Control
## A character's status with an item's comparison (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14), as EquipPage.drawStatus draws it: the
## status line (StatusLine, its slots compared with the item's), the twelve
## attributes, and over each of the first eight that the item would change
## the value with the change ("12 +3") in black and again 1 px up and left in
## green (more) or red (less). The equip page shows it; the Weapon Store
## later. The layout is MenuValues.STATUS_X / STATUS_Y's.

@onready var _top: Control = $Top
@onready var _attributes: Array[Node] = $Attributes.get_children()
@onready var _changes: Control = $Changes


## top: StatusPage.place_top's line; attributes: [text, colour] of the twelve
## values (StatusPage.place_attributes); changes: [attribute (0 to 7), text,
## shift (0, or -1 for the coloured line), colour] each, in drawing order;
## font_size and bold the font. mat is the material of the legacy drawing
## (Graphics.canvas_material).
func show_status(top: Dictionary, attributes: Array, changes: Array, font_size: int, bold: bool,
		mat: Material) -> void:
	material = mat
	_top.show_line(top.offset, top.portrait, top.texts, Array(top.colors, TYPE_COLOR, "", null),
			top.size, top.bold, top.slots, mat)
	var role := MenuText.role(font_size)
	for i in _attributes.size():
		var label: BaselineLabel = _attributes[i]
		label.text = attributes[i][0]
		label.color = attributes[i][1]
		label.theme_type_variation = role
		label.bold = bold
	var entries := []
	for change: Array in changes:
		var at: Vector2 = _attributes[change[0]].position
		entries.append([change[1], Vector2i(at) + Vector2i(change[2], change[2]), role, change[3],
				bold, HORIZONTAL_ALIGNMENT_LEFT])
	_changes.show_labels(entries)
