class_name SaveSlots
extends RefCounted
## The save slots the player sees (COTZ-005): the three manual slots, the
## hidden autosave slot, and when each was saved, for the slot lists of the
## title's Continue, the menu's Save and the church.
##
## Autosaves (Easy and Medium, see Difficulty) go to AUTOSAVE after every
## labyrinth battle and when a village, a labyrinth floor, the world map or
## the airship is entered (Save.autosave). The title lists the slot when it
## exists; it cannot be saved to by hand.

## The slots the player saves to.
const MANUAL: PackedStringArray = ["Slot 1", "Slot 2", "Slot 3"]
## The autosave slot.
const AUTOSAVE := "Autosave"
const MONTHS: PackedStringArray = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
## Distance between the entries of a menu slot list, with room for the date
## under each name (draw_dates_under).
const MENU_DISTANCE := 72
const DATE_FONT_SIZE := 20
## The node that shows the dates (show_dates_beside).
const SLOT_DATES_VIEW := "res://scenes/ui/SlotDates.tscn"
## Dev only (deterministic runs, --seed): the time a slot's date counts from,
## 1 Jan 2000, 00:00 (UTC, no time zone).
const DETERMINISTIC_EPOCH := 946684800

## Dev only: when each slot was written in this deterministic run, in ms of
## the game clock (note_saved), so the slot lists show the same date in every
## run (a file's modification time is wall-clock time).
static var _saved_game_ms := {}


## The file of a slot (in Save.saveDir(), like Save and Load use).
static func path(slot: String) -> String:
	return Save.saveDir() + slot + ".sav"


## True when the player has saved to the slot. (Loading an unsaved slot
## falls back to the shipped developer saves in maps/Banks/.)
static func exists(slot: String) -> bool:
	return FileAccess.file_exists(path(slot))


## The slots the title's Continue lists: the autosave first when there is
## one, then the manual slots.
static func loadable() -> PackedStringArray:
	var slots := PackedStringArray()
	if exists(AUTOSAVE):
		slots.append(AUTOSAVE)
	slots.append_array(MANUAL)
	return slots


## When the slot was saved, in local time ("20 Oct 2026, 15:43"), or "Empty".
## A deterministic run (dev) shows the game clock's time of the save instead,
## counted from DETERMINISTIC_EPOCH.
static func saved_at(slot: String) -> String:
	if not exists(slot):
		return "Empty"
	var unix: int
	if J.deterministic:
		unix = DETERMINISTIC_EPOCH + int(_saved_game_ms.get(slot, 0.0) / 1000.0)
	else:
		var bias: int = int(Time.get_time_zone_from_system().get("bias", 0))
		unix = FileAccess.get_modified_time(path(slot)) + bias * 60
	var t: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	return "%d %s %d, %02d:%02d" % [t.day, MONTHS[t.month - 1], t.year, t.hour, t.minute]


## Dev only: notes that the slot's file was just written (Save.saveGame), for
## the dates of a deterministic run (saved_at).
static func note_saved(slot: String) -> void:
	if J.deterministic:
		_saved_game_ms[slot] = J.gameClockMs


## Draws the date of each slot of a menu list under its name (the list's
## distance should be MENU_DISTANCE), then sets the font size back to
## font_size. Entries that are not slots ("Back") get nothing.
static func draw_dates_under(g: Graphics, node: MenuNode, font_size: int) -> void:
	_draw_dates(g, node, Vector2i(14, 30))
	g.setFontSize(font_size)


## Draws the date of each slot of a list to the right of its name, at x,
## then sets the font size back to font_size.
static func draw_dates_beside(g: Graphics, node: MenuNode, x: int, font_size: int) -> void:
	_draw_dates(g, node, Vector2i(x - node.Xpos, 0))
	g.setFontSize(font_size)


## draw_dates_beside without the drawing (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14): the same state changes (the font sizes,
## drawString's setColor(color)), and the frame's next SlotDates node on the
## UI layer shows the dates where they would have been drawn (Graphics.show_ui).
static func show_dates_beside(g: Graphics, node: MenuNode, x: int, font_size: int) -> void:
	_show_dates(g, node, Vector2i(x - node.Xpos, 0))
	g.setFontSize(font_size)


## draw_dates_under without the drawing (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14): the same state changes, and the frame's
## next SlotDates node on the UI layer shows the dates (the menu's Save list).
static func show_dates_under(g: Graphics, node: MenuNode, font_size: int) -> void:
	_show_dates(g, node, Vector2i(14, 30))
	g.setFontSize(font_size)


static func _draw_dates(g: Graphics, node: MenuNode, offset: Vector2i) -> void:
	g.setFontSize(DATE_FONT_SIZE)
	for i in range(node.getSize()):
		var slot: String = node.children[i].getName()
		if slot == AUTOSAVE or MANUAL.has(slot):
			g.drawString(saved_at(slot), node.Xpos + offset.x, node.Ypos + i * node.distance + offset.y)


static func _show_dates(g: Graphics, node: MenuNode, offset: Vector2i) -> void:
	g.setFontSize(DATE_FONT_SIZE)
	var dates := []
	for i in range(node.getSize()):
		var slot: String = node.children[i].getName()
		if slot == AUTOSAVE or MANUAL.has(slot):
			dates.append([saved_at(slot), Vector2i(node.Xpos + offset.x,
					node.Ypos + i * node.distance + offset.y), Graphics.text_color(1.0)])
			g.setColor(g.color)
	if dates.is_empty():
		return
	var view = g.show_ui(SLOT_DATES_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_dates(dates, Graphics.font_bold(), g.canvas_material())
