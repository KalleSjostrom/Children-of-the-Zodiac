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
