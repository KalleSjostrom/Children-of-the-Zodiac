class_name Icon
extends RefCounted
## Port of menu.tutorial.Icon: an icon drawn next to a tutorial row.

var icon = ""
var xoffset: int = 0
var yoffset: int = 0
var scale: float = 0.0

## Java overloads: Icon(String icon) and Icon(String icon, x, y, float scale).
func _init(icon = null, x = null, y = null, scale = null) -> void:
	self.icon = icon
	if x != null:
		xoffset = x
		yoffset = y
		self.scale = scale

func draw(g, x, y):
	g.drawImage(icon, x + xoffset, y + yoffset, scale)
