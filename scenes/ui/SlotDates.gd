extends Control
## When each save slot of a slot list was saved (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14), as SaveSlots draws the dates beside (or
## under) the slots' names: "20 Oct 2026, 15:43" or "Empty", in the text
## colour the list left. The title's Continue list; the menu's Save page and
## the church later.

@onready var _dates: Control = $Dates


## The dates, [text, position (the baseline's start), colour] each, in the
## bold font or not; mat is the material of the legacy drawing
## (Graphics.canvas_material).
func show_dates(dates: Array, bold: bool, mat: Material) -> void:
	material = mat
	var entries := []
	for d: Array in dates:
		entries.append([d[0], d[1], &"SaveSlotDate", d[2], bold, HORIZONTAL_ALIGNMENT_LEFT])
	_dates.show_labels(entries)
