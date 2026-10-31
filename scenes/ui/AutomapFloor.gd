extends Control
## One floor of the menu's map (phase 4.2 step B, docs/ARCHITECTURE.md
## section 14; Automap): its name (screen text: the legacy text ignores the
## modelview), then its cells' pieces, icons and the player's arrow as
## TextureRects in the floor's own space under Zoom, whose transform is the
## modelview the legacy drawing put them through (the overview's third and
## the floor's place; the identity for one floor), in that order (the cells
## of a floor's top row can lie over its name). Under that transform the
## TextureRects draw the legacy pixels (every automap shot; plan 9.2).

@onready var _names: Control = $Names
@onready var _zoom: Node2D = $Zoom
@onready var _cells: Control = $Zoom/Cells


## names: [text, centre, font size, colour, bold, alignment] each (the name
## and, on the player's floor, its shadow first); images: [texture, rect (in
## the floor's space), tint] each (Graphics.place_image's); modelview: the
## transform they are drawn under (Graphics.modelview_2d).
func show_floor(names: Array, images: Array, modelview: Transform2D) -> void:
	var entries := []
	for name: Array in names:
		entries.append([name[0], name[1], _role(name[2]), name[3], name[4], name[5]])
	_names.show_labels(entries)
	_zoom.transform = modelview
	_cells.show_images(images)


func _role(font_size: int) -> StringName:
	if font_size == 24:
		return &"AutomapFloorName"
	if font_size == 34:
		return &"AutomapFloorTitle"
	return StringName("Text%d" % font_size)
