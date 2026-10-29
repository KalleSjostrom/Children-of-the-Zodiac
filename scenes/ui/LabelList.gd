extends Control
## Lines of text whose number changes from frame to frame (a menu's choices, a
## tutorial page's words, the credits): one BaselineLabel child per entry,
## made as needed and kept, in the order given (the legacy drawing's order).
## Children use the parent's material.


## Shows one label per entry and hides the others. An entry is [text,
## position (Vector2i: the baseline's start, or its centre or end with
## alignment), theme type variation (Text20 …), colour, bold, alignment
## (HORIZONTAL_ALIGNMENT_LEFT, _CENTER or _RIGHT)].
func show_labels(entries: Array) -> void:
	var labels := get_children()
	for i in entries.size():
		var label: BaselineLabel
		if i < labels.size():
			label = labels[i]
		else:
			label = BaselineLabel.new()
			label.use_parent_material = true
			add_child(label)
		var e: Array = entries[i]
		label.text = e[0]
		label.position = Vector2(e[1])
		label.theme_type_variation = e[2]
		label.color = e[3]
		label.bold = e[4]
		label.alignment = e[5]
		label.visible = true
	for i in range(entries.size(), labels.size()):
		labels[i].visible = false
