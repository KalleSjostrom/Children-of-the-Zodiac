extends RefCounted
## Drawing on Images for the village-remake tools' annotated maps (headless
## runs have no renderer, so no fonts): lines, outlines, filled polygons
## and numbered markers in a 3x5 pixel font.

## The digits 0-9, 3x5, row by row (1: ink).
const DIGITS := [
	"111101101101111", "010110010010111", "111001111100111", "111001111001111", "101101111001001",
	"111100111001111", "111100111101111", "111001010010010", "111101111101111", "111101111001111",
]


static func blend(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, image.get_pixel(x, y).blend(color))


static func line(image: Image, a: Vector2, b: Vector2, color: Color, width := 1) -> void:
	var n := maxi(int(a.distance_to(b)), 1)
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		for dy in width:
			for dx in width:
				blend(image, int(p.x) + dx - width / 2, int(p.y) + dy - width / 2, color)


static func rect_outline(image: Image, r: Rect2, color: Color, width := 1) -> void:
	var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		line(image, c[i], c[(i + 1) % 4], color, width)


static func fill_rect(image: Image, r: Rect2i, color: Color) -> void:
	var clipped := r.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			blend(image, x, y, color)


static func polyline(image: Image, points: PackedVector2Array, color: Color, closed := false, width := 1) -> void:
	for i in points.size() - (0 if closed else 1):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		if not (is_nan(a.x) or is_nan(b.x)):
			line(image, a, b, color, width)


static func circle(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var n := maxi(int(radius * 6), 12)
	for i in n:
		var p := center + Vector2.from_angle(TAU * i / n) * radius
		blend(image, int(p.x), int(p.y), color)


## A number at top_left, each font pixel scale pixels, on a dark plate.
static func number(image: Image, value: int, top_left: Vector2i, color: Color, scale := 2) -> void:
	var text := str(value)
	var plate := Rect2i(top_left - Vector2i(1, 1), Vector2i(text.length() * 4 * scale + 1, 6 * scale + 1))
	fill_rect(image, plate, Color(0, 0, 0, 0.7))
	for i in text.length():
		var glyph: String = DIGITS[text.unicode_at(i) - 48]
		for gy in 5:
			for gx in 3:
				if glyph[gy * 3 + gx] == "1":
					fill_rect(image, Rect2i(top_left + Vector2i((i * 4 + gx) * scale, gy * scale), Vector2i(scale, scale)), color)


## A marker: a cross at p and its number beside it.
static func marker(image: Image, p: Vector2, value: int, color: Color, scale := 2) -> void:
	line(image, p - Vector2(5, 0), p + Vector2(5, 0), color, 2)
	line(image, p - Vector2(0, 5), p + Vector2(0, 5), color, 2)
	number(image, value, Vector2i(p) + Vector2i(6, -6), color, scale)
