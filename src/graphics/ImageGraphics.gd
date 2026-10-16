class_name ImageGraphics
extends RefCounted
## Emulation of the java.awt.Graphics2D subset the game used to paint into
## BufferedImages (text, filled rectangles and images), working on a Godot
## Image. Text is rasterized by blitting glyphs from the font cache.
##
## Java: `Graphics2D g = image.createGraphics();` -> `var g := ImageGraphics.new(image)`.

var image: Image
var color := Color.WHITE
var fontType := 0
var fontSize := 12
var translation := Vector2i.ZERO


func _init(p_image: Image) -> void:
	image = p_image
	if image.is_compressed():
		image.decompress()
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)


func setColor(c: Color) -> void:
	color = c


func getColor() -> Color:
	return color


## Java: g.setFont(Values.getFont(type, size)). Accepts the [type, size]
## array returned by Values.getFont, or (type, size).
func setFont(type, size: int = -1) -> void:
	if type is Array:
		fontType = type[0]
		fontSize = type[1]
		return
	fontType = type
	if size > 0:
		fontSize = size


func setFontSize(size: int) -> void:
	fontSize = size


func setRenderingHint(a = null, b = null) -> void:
	pass


func translate(x: int, y: int) -> void:
	translation += Vector2i(x, y)


func dispose() -> void:
	pass


func fillRect(x: int, y: int, w: int, h: int) -> void:
	var r := Rect2i(x + translation.x, y + translation.y, w, h).intersection(
		Rect2i(0, 0, image.get_width(), image.get_height()))
	if r.size.x <= 0 or r.size.y <= 0:
		return
	if color.a >= 1.0:
		image.fill_rect(r, color)
	else:
		var src := Image.create_empty(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
		src.fill(color)
		image.blend_rect(src, Rect2i(Vector2i.ZERO, r.size), r.position)


## Clears the rectangle to fully transparent (AlphaComposite.Clear).
func clearRect(x: int, y: int, w: int, h: int) -> void:
	var r := Rect2i(x + translation.x, y + translation.y, w, h).intersection(
		Rect2i(0, 0, image.get_width(), image.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		image.fill_rect(r, Color(0, 0, 0, 0))


## Java overloads: drawImage(img, x, y, observer) and drawImage(img, x, y, w, h, observer).
func drawImage(src, x: int, y: int, a = null, b = null, c = null) -> void:
	var im: Image = src
	if src is GameTexture:
		im = src.getData()
	elif src is String:
		im = ImageHandler.getImage(src)
	if im == null:
		return
	var s := im
	if s.is_compressed() or s.get_format() != Image.FORMAT_RGBA8:
		s = s.duplicate()
		if s.is_compressed():
			s.decompress()
		s.convert(Image.FORMAT_RGBA8)
	if a is int and b is int:
		s = s.duplicate()
		s.resize(maxi(a, 1), maxi(b, 1), Image.INTERPOLATE_BILINEAR)
	image.blend_rect(s, Rect2i(0, 0, s.get_width(), s.get_height()),
		Vector2i(x, y) + translation)


## Draws a string with its baseline at y (like Graphics2D.drawString).
func drawString(text: String, x: float, y: float) -> void:
	var font: Font = _font(fontType)
	if font == null or text == "":
		return
	var ts := TextServerManager.get_primary_interface()
	var rids := font.get_rids()
	if rids.is_empty():
		return
	var shaped := ts.create_shaped_text()
	ts.shaped_text_add_string(shaped, text, rids, fontSize)
	var glyphs := ts.shaped_text_get_glyphs(shaped)
	var pen := Vector2(x, y) + Vector2(translation)
	var size_v := Vector2i(fontSize, 0)
	for gl in glyphs:
		var frid: RID = gl.get("font_rid", rids[0])
		var idx: int = gl.get("index", 0)
		var adv: float = gl.get("advance", 0.0)
		var goff: Vector2 = gl.get("offset", Vector2.ZERO)
		if frid.is_valid() and idx != 0:
			ts.font_render_glyph(frid, size_v, idx)
			var tex_idx := ts.font_get_glyph_texture_idx(frid, size_v, idx)
			if tex_idx >= 0:
				var atlas := ts.font_get_texture_image(frid, size_v, tex_idx)
				var uv := ts.font_get_glyph_uv_rect(frid, size_v, idx)
				var off := ts.font_get_glyph_offset(frid, size_v, idx)
				if atlas != null and uv.size.x > 0 and uv.size.y > 0:
					_blitGlyph(atlas, Rect2i(uv), Vector2i((pen + goff + off).round()))
		pen.x += adv
	ts.free_rid(shaped)


static func _font(type: int) -> Font:
	Graphics._loadFonts()
	return Graphics._fonts[type]


func _blitGlyph(atlas: Image, src: Rect2i, dst: Vector2i) -> void:
	var w := image.get_width()
	var h := image.get_height()
	for yy in src.size.y:
		var ty := dst.y + yy
		if ty < 0 or ty >= h:
			continue
		for xx in src.size.x:
			var tx := dst.x + xx
			if tx < 0 or tx >= w:
				continue
			var p := atlas.get_pixel(src.position.x + xx, src.position.y + yy)
			var cov: float = p.a
			if cov <= 0.0:
				continue
			var a := cov * color.a
			var d := image.get_pixel(tx, ty)
			var out_a := a + d.a * (1.0 - a)
			if out_a <= 0.0:
				continue
			var rgb := (Color(color.r, color.g, color.b) * a + Color(d.r, d.g, d.b) * d.a * (1.0 - a)) / out_a
			image.set_pixel(tx, ty, Color(rgb.r, rgb.g, rgb.b, out_a))


## FontMetrics.stringWidth.
func stringWidth(text: String) -> int:
	return J.round(_font(fontType).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x)
