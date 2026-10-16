class_name JColor
extends RefCounted
## java.awt.Color constants and constructors.
##
## Godot's Color constants differ from Java's (e.g. Godot GRAY is 190/255 while
## Java's gray is 128/255), so ported code uses these instead.

const white := Color(1, 1, 1)
const WHITE := white
const lightGray := Color8(192, 192, 192)
const LIGHT_GRAY := lightGray
const gray := Color8(128, 128, 128)
const GRAY := gray
const darkGray := Color8(64, 64, 64)
const DARK_GRAY := darkGray
const black := Color(0, 0, 0)
const BLACK := black
const red := Color(1, 0, 0)
const RED := red
const pink := Color8(255, 175, 175)
const PINK := pink
const orange := Color8(255, 200, 0)
const ORANGE := orange
const yellow := Color(1, 1, 0)
const YELLOW := yellow
const green := Color(0, 1, 0)
const GREEN := green
const magenta := Color(1, 0, 1)
const MAGENTA := magenta
const cyan := Color(0, 1, 1)
const CYAN := cyan
const blue := Color(0, 0, 1)
const BLUE := blue


## new Color(int r, int g, int b[, int a]) with 0-255 components.
static func rgb255(r: int, g: int, b: int, a: int = 255) -> Color:
	return Color8(r, g, b, a)


## new Color(float r, float g, float b[, float a]) with 0-1 components.
static func rgbf(r: float, g: float, b: float, a: float = 1.0) -> Color:
	return Color(r, g, b, a)


## Color.getRGBComponents / getColorComponents as a float array.
static func components(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]
