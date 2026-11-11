class_name ResultScreenBase
extends RefCounted
## Port of battle.resultScreen.Screen: a basic screen which results or spoils
## can be drawn upon.

## The background used in the result screens (loaded lazily, see getBack()).
static var back = ""
var background = ""
var scale: float = 0.0
var bx: int = 0
var by: int = 0
var alpha: float = 0.0


## Java: static String back = ImageHandler.addPermanentlyLoadNow(...).
static func getBack() -> String:
	if back == "":
		back = ImageHandler.addPermanentlyLoadNow(Values.BattleImages + "resultBack.png")
	return back


## Java overloads:
##   Screen()                                        -> (back, 170, 190, 1.1, .5)
##   Screen(float alpha)                             -> (back, 170, 190, 1.1, alpha)
##   Screen(String back, int x, int y, float scale, float alpha)
func _init(back = null, x = null, y = null, scale = null, alpha = null) -> void:
	if back == null:
		_setValues(getBack(), 170, 190, 1.1, 0.5)
	elif x == null and not (back is String):
		_setValues(getBack(), 170, 190, 1.1, float(back))
	else:
		_setValues(back, x, y, scale, alpha)


func _setValues(p_back, x, y, p_scale, p_alpha) -> void:
	background = p_back
	bx = int(x)
	by = int(y)
	self.scale = float(p_scale)
	self.alpha = float(p_alpha)


## Draws the background on the given graphics.
func drawBackground(g):
	g.fadeOldSchool(alpha)
	g.setColor(1)
	g.drawImage(background, bx, by, scale)


# Bridge (phase 4.4 step B, docs/ARCHITECTURE.md section 15): the result and
# spoils screens' drawing without the drawing. The twins make the drawing's
# state changes in the same order and show, where each part was drawn, its
# UI node (Graphics.show_ui, the UI layer; pooled per scene and occurrence).
# --legacy=battle_screens keeps the legacy drawing.

## The nodes of the screens: the background (a LevelBar: the scaled image as
## its legacy quad) and the played cards; the lines are MenuText nodes
## (AbstractPage.show_lines), the dim a Fade node (Graphics.show_fade).
const BACK_VIEW := "res://scenes/ui/LevelBar.tscn"
const CARD_VIEW := "res://scenes/ui/CardView.tscn"


## drawBackground without the drawing: the dim (fadeOldSchool's colour and
## bind: a Fade node on the UI layer, the screen's lines and cards drawn over
## it), setColor(1), the background's bind; the frame's next LevelBar shows
## the background at its scale as the legacy quad (Graphics.place_image_part
## with percent 1: a TextureRect of an image scaled up is 1/255 off on a few
## pixels, plan 12).
func show_background(g) -> void:
	g.show_fade(alpha, Graphics.UI_LAYER)
	g.setColor(1)
	var t: GameTexture = ImageHandler.getTexture(background)
	var placed: Array = [] if t == null \
			else g.place_image_part(background, bx, by, t.getWidth(), t.getHeight(), scale, 1.0)
	var view = g.show_ui(BACK_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_parts([placed], g.canvas_material())


## drawWithShadow(text, x, y[, c]) without the drawing
## (Graphics.place_with_shadow: its text colours and drawString's
## setColor(color)): its two lines for AbstractPage.show_lines, the shadow (1
## px down and to the right) first.
static func shadow_lines(g, text, x: int, y: int, c = null) -> Array:
	return _pair(g, str(text), x, y, g.place_with_shadow(c))


## drawValueWithShadow(value, x, y, c) without the drawing
## (Graphics.place_value_with_shadow): its two lines, the shadow first.
static func value_lines(g, value: int, x: int, y: int, c: Color) -> Array:
	return _pair(g, str(value), x, y, g.place_value_with_shadow(value, c))


static func _pair(g, text: String, x: int, y: int, colors: Array[Color]) -> Array:
	var size: int = g.getFontSize()
	var bold := Graphics.font_bold()
	return [[text, Vector2i(x + 1, y + 1), size, colors[0], bold, HORIZONTAL_ALIGNMENT_LEFT],
			[text, Vector2i(x, y), size, colors[1], bold, HORIZONTAL_ALIGNMENT_LEFT]]
