class_name MenuText
extends Control
## Lines of text a menu page draws at places it computes (phase 4.2 step B,
## docs/ARCHITECTURE.md section 14): the deck page's deck titles, the help
## page's difficulty text, the map page's "Explored". Each frame the page's
## twin hands this node the lines it would have drawn (Graphics.show_ui).

## The game's theme, whose roles role() looks up.
const GAME_THEME: Theme = preload("res://resources/theme/game_theme.tres")

@onready var _lines: Control = $Lines


## role()'s answers, by prefix and size.
static var _roles := {}


## The theme role of text at font_size: <prefix><size> when the game's theme
## has it, else Text<size> (the deck page's help line at the size the card
## info leaves, 20). The type's own entries are looked up: has_font_size (and
## a Control's has_theme_font_size) is true for any type while the theme has
## a default font size, and a label of a type the theme lacks gets that
## default (24).
static func role(font_size: int, prefix := "MenuText") -> StringName:
	var key := "%s%d" % [prefix, font_size]
	var known = _roles.get(key)
	if known == null:
		var r := StringName(key)
		known = r if GAME_THEME.get_font_size_list(r).has("font_size") \
				else StringName("Text%d" % font_size)
		_roles[key] = known
	return known


## lines: [text, position (the baseline's start, its centre or its end with
## alignment), font size, colour, bold, alignment] each, in drawing order. mat
## is the material of the legacy drawing (Graphics.canvas_material).
func show_lines(lines: Array, mat: Material) -> void:
	material = mat
	var entries := []
	for line: Array in lines:
		entries.append([line[0], line[1], role(line[2]), line[3], line[4], line[5]])
	_lines.show_labels(entries)
