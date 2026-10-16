class_name GameTexture
extends RefCounted
## Port of graphics.GameTexture.
##
## In this port a GameTexture also plays the role of the JOGL Texture class:
## getTexture() returns the GameTexture itself, so Java code such as
## `ImageHandler.getTexture(n).getTexture().bind(g)` or
## `Utils3D.draw3D(g, t.getTexture(), coords)` keeps working unchanged.

var name := ""
var texture: Texture2D
var data: Image # CPU copy (java.awt.image.BufferedImage), loaded lazily
var width := 0
var height := 0
var destroyed := false
var loaded := false
var x := 0.0
var y := 0.0


func _init(p_name: String = "", p_texture: Texture2D = null, p_data: Image = null) -> void:
	name = p_name
	texture = p_texture
	data = p_data
	if texture != null:
		width = texture.get_width()
		height = texture.get_height()
		loaded = true
	elif data != null:
		width = data.get_width()
		height = data.get_height()


static func fromImage(p_name: String, image: Image) -> GameTexture:
	var t := ImageTexture.create_from_image(image)
	return GameTexture.new(p_name, t, image)


func load() -> void:
	if texture == null and data != null:
		texture = ImageTexture.create_from_image(data)
		loaded = true


func getHeight() -> int:
	return height


func getWidth() -> int:
	return width


func getImageWidth() -> int:
	return width


func getImageHeight() -> int:
	return height


## Returns this object (it acts as the JOGL Texture).
func getTexture() -> GameTexture:
	if texture == null:
		self.load()
	return self


func getGodotTexture() -> Texture2D:
	if texture == null:
		self.load()
	return texture


## JOGL Texture.getImageTexCoords(): in this port v = 0 is the image top.
func getImageTexCoords() -> TextureCoords:
	return TextureCoords.DEFAULT


func destroy(g = null) -> void:
	destroyed = true


func isLoaded() -> bool:
	return loaded


## Binds this texture for the following immediate mode (glBegin/glEnd) calls.
func bind(g = null) -> void:
	(g if g is Graphics else Graphics.gl).bindTexture(self)


## Gets the CPU side image (java BufferedImage).
func getData() -> Image:
	if data == null and texture != null:
		data = texture.get_image()
		if data != null and data.is_compressed():
			data.decompress()
	return data


## JOGL Texture.updateImage: re-uploads the (modified) image data.
func updateImage(g = null, image: Image = null) -> void:
	if image != null:
		data = image
	if data == null:
		return
	if texture is ImageTexture and texture.get_width() == data.get_width() \
			and texture.get_height() == data.get_height():
		(texture as ImageTexture).update(data)
	else:
		texture = ImageTexture.create_from_image(data)
	width = data.get_width()
	height = data.get_height()


func getName() -> String:
	return name


func setName(p_name: String) -> void:
	name = p_name


func setPosition(px: int, py: int) -> void:
	x = px
	y = py


func setXpos(xpos: int) -> void:
	x = xpos


func setYpos(ypos: int) -> void:
	y = ypos


func getYpos() -> float:
	return y


func drawMany(g: Graphics, px: float, py: float, scale: float) -> void:
	var halfHeight := (height * scale) / 2.0
	var halfWidth := (width * scale) / 2.0
	py -= halfHeight
	px -= halfWidth
	var nyh := int(py + 2 * halfHeight)
	var xw := int(px + 2 * halfWidth)
	g.drawi(getImageTexCoords(), int(px), nyh, xw, int(py), false)


## Java overloads: draw(g), draw(g, x, y), draw(g, x, y, scale),
## draw(g, x, y, width, height, scale, percent),
## draw(g, x, y, width, height, size, percentLow, percentHigh).
func draw(g: Graphics, px = null, py = null, a = null, b = null, c = null, d = null, e = null) -> void:
	if px == null:
		draw(g, x, y)
	elif c == null:
		var scale: float = 1.0 if a == null else float(a)
		drawPart(g, px, py, width, height, scale, 1.0)
	elif e == null:
		drawPart(g, px, py, a, b, c, d)
	else:
		drawPartRange(g, px, py, a, b, c, d, e)


func drawPart(g: Graphics, px: float, py: float, w: float, h: float, scale: float, percent: float) -> void:
	bind(g)
	var tc := getImageTexCoords()
	var ny := int(py)
	var nyh := int(py + h * scale)
	var xw := int(px + w * scale * percent)
	g.drawip(tc, int(px), nyh, xw, ny, percent)


func drawPartRange(g: Graphics, px: int, py: int, w: int, h: int, size: float,
		percentLow: float, percentHigh: float) -> void:
	bind(g)
	var tc := getImageTexCoords()
	var ny := int(py)
	var nyh := int(py + h * size)
	var xw := int(px + w * size * percentHigh)
	var nx := int(px + w * size * percentLow)
	g.drawipp(tc, nx, nyh, xw, ny, percentLow, percentHigh)


func drawCentered(g: Graphics, py: float) -> void:
	var w := J.round(width / 2.0)
	var px := J.round(Values.ORIGINAL_RESOLUTION[Values.X] / 2.0) - w
	draw(g, px, py)


## JOGL TextureCoords: left/right/top/bottom texture coordinates.
class TextureCoords extends RefCounted:
	static var DEFAULT := TextureCoords.new(0.0, 1.0, 1.0, 0.0)
	var _l: float
	var _b: float
	var _r: float
	var _t: float

	func _init(l: float, b: float, r: float, t: float) -> void:
		_l = l
		_b = b
		_r = r
		_t = t

	func left() -> float:
		return _l

	func right() -> float:
		return _r

	func top() -> float:
		return _t

	func bottom() -> float:
		return _b
