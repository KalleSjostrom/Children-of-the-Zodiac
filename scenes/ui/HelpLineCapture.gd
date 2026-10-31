class_name HelpLineCapture
extends RefCounted
## Records the help line a menu page draws, for the HelpLine node that draws
## it in its place (phase 4.2 step B, docs/ARCHITECTURE.md section 14): it
## stands in for Graphics in a page's drawHelp (which calls
## drawCenteredImage for the button icons and drawString for their labels),
## makes the state changes of those calls on the real Graphics (the icons'
## binds, drawString's setColor(color)) and keeps what they would have
## drawn, in order. The page's drawHelp itself is unchanged:
##
##     var help := HelpLineCapture.new(g)
##     drawHelp(help)
##     help.show()

const VIEW := "res://scenes/ui/HelpLine.tscn"

var _g: Graphics
var _entries := []


func _init(g: Graphics) -> void:
	_g = g


## Graphics.drawCenteredImage(name, y) and (name, x, y) without the drawing
## (Graphics.place_centered_image).
func drawCenteredImage(name, a, b = null) -> void:
	var placed: Array
	if b == null:
		placed = _g.place_centered_image(name, Values.ORIGINAL_RESOLUTION[Values.X] / 2, a)
	else:
		placed = _g.place_centered_image(name, a, b)
	if not placed.is_empty():
		_entries.append(placed)


## Graphics.drawString without the drawing: the label in the text colour (at
## alpha) and the font set now, and drawString's setColor(color).
func drawString(string, x, y, alpha: float = 1.0) -> void:
	if string == null:
		return
	if str(string) != "":
		_entries.append([str(string), Vector2i(x, y), _g.getFontSize(), Graphics.text_color(alpha),
				Graphics.font_bold()])
	_g.setColor(_g.color)


## Shows what was recorded: the frame's next HelpLine node on the UI layer
## (Graphics.show_ui), with the material of the 2D state.
func show() -> void:
	var view = _g.show_ui(VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_help(_entries, _g.canvas_material())
