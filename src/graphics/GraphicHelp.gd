class_name GraphicHelp
extends RefCounted
## Port of graphics.GraphicHelp: helpers working on CPU images
## (java.awt.image.BufferedImage -> Godot Image).

const BRIGHTNESS := 0.8


## Returns a gray scale copy of the image (80 % brightness, alpha kept).
static func toGrayScale(im: Image) -> Image:
	var image := im.duplicate() as Image
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	var i := 0
	var n := data.size()
	while i < n:
		var g := int(BRIGHTNESS * (0.3 * data[i] + 0.59 * data[i + 1] + 0.11 * data[i + 2]))
		data[i] = g
		data[i + 1] = g
		data[i + 2] = g
		i += 4
	return Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data)


## Creates an image of the given fraction of the screen size, filled with c.
static func getImage(xpercent: float, ypercent: float, c: Color) -> Image:
	var width := J.round(Values.ORIGINAL_RESOLUTION[Values.X] * xpercent)
	var height := J.round(Values.ORIGINAL_RESOLUTION[Values.Y] * ypercent)
	var im := Image.create_empty(maxi(width, 1), maxi(height, 1), false, Image.FORMAT_RGBA8)
	im.fill(c)
	return im


## Java overloads: drawStringWithBlackFrame(Graphics2D|Graphics g, text, x, y,
## size, Color c, offset, font).
static func drawStringWithBlackFrame(g, text: String, x: int, y: int, size: int,
		c: Color, offset: int, font: int) -> void:
	if g is ImageGraphics:
		g.setFont(font, size)
		g.setColor(JColor.BLACK)
		g.drawString(text, x + offset, y)
		g.drawString(text, x - offset, y)
		g.drawString(text, x, y + offset)
		g.drawString(text, x, y - offset)
		g.setColor(c)
		g.drawString(text, x, y)
	else:
		g.setFontSize(size)
		Graphics.setTextColor(JColor.black)
		Graphics.setTextColor(c)
		g.drawString(text, x, y, 0.8)


## Java overloads: scaleImage(Image, int newW, int newH) and (Image, float scale).
static func scaleImage(im: Image, a, b = null) -> Image:
	if im == null:
		return null
	var w: int
	var h: int
	if b == null:
		w = J.round(im.get_width() * float(a))
		h = J.round(im.get_height() * float(a))
	else:
		w = int(a)
		h = int(b)
	var copy := im.duplicate() as Image
	if copy.is_compressed():
		copy.decompress()
	copy.resize(maxi(w, 1), maxi(h, 1), Image.INTERPOLATE_CUBIC)
	return copy


## new BufferedImage(w, h, TYPE_*) -> transparent RGBA image.
static func createImage(w: int, h: int) -> Image:
	return Image.create_empty(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)
