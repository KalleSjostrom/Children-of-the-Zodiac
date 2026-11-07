extends Control
## The Church's bless page (phase 4.2 step B, docs/ARCHITECTURE.md section
## 14): what Church.draw3D draws between the page's pieces and its list, in
## the legacy order: "Cost" (size 30), a BlessRow per character (its cost,
## its LevelUpBar range, the markers on the current row), the help text's
## rows (HelpText.drawTopLayer: Row.drawRows, black words and coloured ones
## over a black shadow, then the rows' icons) and the total cost. The legacy
## Church keeps the pairs, the markers, the total and the blessing's swing;
## its twin (Church._show_bless) hands this node what it would have drawn
## (Graphics.show_ui).

const BLESS_ROW := preload("res://scenes/ui/BlessRow.tscn")

@onready var _cost: BaselineLabel = $Cost
@onready var _rows: Control = $Rows
@onready var _words: Control = $Words
@onready var _icons: Control = $Icons
@onready var _total: Control = $Total


## Lines are [text, position (the baseline's start), font size, colour,
## bold] each. cost: the column's title; rows: {"cost": a line, "bar":
## LevelUpBar.place_static's parts, "hands": [texture, rect, tint] each}
## per character; words: the help text's words (lines) and icons ([texture,
## rect, tint] each, Icon.place_icon); total: "Total cost: " and the sum. mat
## is the material of the legacy drawing (Graphics.canvas_material).
func show_page(cost: Array, rows: Array, words: Array, icons: Array, total: Array,
		mat: Material) -> void:
	material = mat
	_cost.text = cost[0]
	_cost.position = Vector2(cost[1])
	_cost.theme_type_variation = MenuText.role(cost[2])
	_cost.color = cost[3]
	_cost.bold = cost[4]
	var views := _rows.get_children()
	for i in rows.size():
		var view: Control
		if i < views.size():
			view = views[i]
		else:
			view = BLESS_ROW.instantiate()
			view.use_parent_material = true
			_rows.add_child(view)
		view.visible = true
		view.show_row(rows[i].cost, rows[i].bar, rows[i].hands)
	for i in range(rows.size(), views.size()):
		views[i].visible = false
	_words.show_labels(_entries(words))
	_icons.show_images(icons)
	_total.show_labels(_entries(total))


static func _entries(lines: Array) -> Array:
	var entries := []
	for line: Array in lines:
		entries.append([line[0], line[1], MenuText.role(line[2]), line[3], line[4],
				HORIZONTAL_ALIGNMENT_LEFT])
	return entries
