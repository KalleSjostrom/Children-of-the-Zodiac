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

## Bridge (phase 3 step B, docs/ARCHITECTURE.md section 12): draw without the
## drawing: the image bound as drawImage binds it (Graphics.skip_image).
## Returns [texture, rect (the quad drawImage would draw: its position
## rounded, its far corner truncated to whole pixels), tint (the current
## colour)], or [] when it draws nothing.
func place_icon(g, x, y) -> Array:
	var tint: Color = g.getCurrentColor()
	var t = g.skip_image(icon)
	if t == null:
		return []
	var px: int = roundi(x + xoffset)
	var py: int = roundi(y + yoffset)
	return [t.getGodotTexture(), Rect2i(px, py, int(px + t.getWidth() * scale) - px,
			int(py + t.getHeight() * scale) - py), tint]
