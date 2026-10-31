extends Control
## The help line at the bottom of a menu page (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14): the button icons
## (AbstractPage.BUTTON_ICONS, centred on their places) and their labels, in
## the order the page's drawHelp draws them (an icon and the label next to it
## can overlap at their edges). The pages' drawHelp run against a
## HelpLineCapture, which hands this node what they would have drawn; the
## Church's help line later.

## A child per entry, in drawing order: a TextureRect for an icon, a
## BaselineLabel for a label.


## entries: [texture, rect, tint] (an icon, Graphics.place_image's) or [text,
## position (the baseline's start), font size, colour, bold] (a label) each,
## in drawing order. mat is the material of the legacy drawing
## (Graphics.canvas_material).
func show_help(entries: Array, mat: Material) -> void:
	material = mat
	for i in entries.size():
		var e: Array = entries[i]
		if e[0] is String:
			var label := _child(i, false) as BaselineLabel
			label.text = e[0]
			label.position = Vector2(e[1])
			label.theme_type_variation = MenuText.role(e[2])
			label.color = e[3]
			label.bold = e[4]
		else:
			var rect := _child(i, true) as TextureRect
			var r: Rect2i = e[1]
			rect.texture = e[0]
			rect.position = Vector2(r.position)
			rect.size = Vector2(r.size)
			rect.self_modulate = e[2]
	var children := get_children()
	for i in range(entries.size(), children.size()):
		children[i].visible = false


## The child at index, a TextureRect (image) or a BaselineLabel, made (or
## remade when the kind at that index changed) as needed; shown.
func _child(index: int, image: bool) -> Control:
	var children := get_children()
	if index < children.size():
		var old: Control = children[index]
		if (old is TextureRect) == image:
			old.visible = true
			return old
		remove_child(old)
		old.queue_free()
	var made: Control
	if image:
		var rect := TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		made = rect
	else:
		made = BaselineLabel.new()
	made.use_parent_material = true
	made.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(made)
	move_child(made, index)
	return made
