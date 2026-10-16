class_name GameSprite2D
extends RefCounted
## Port of graphics.Sprite2D (renamed: Godot owns Sprite2D). Wraps a texture
## with a position.

var data = null
var texture = null
var name = ""
var height: int = 0
var width: int = 0
var x: float = 0.0
var y: float = 0.0
var destroyed: bool = false
var loaded: bool = false

## Java overloads: Sprite2D(Texture tex, String name, BufferedImage data) and
## Sprite2D(String name, BufferedImage image).
func _init(tex = null, name = null, data = null) -> void:
	if not (tex is GameTexture):
		# Sprite2D(String name, BufferedImage image)
		self.name = tex if tex != null else ""
		self.data = name
		loaded = false
		return
	texture = tex
	self.data = data
	if data != null:
		height = data.get_height()
		width = data.get_width()
	self.name = name if name != null else ""
	destroyed = false
	loaded = true


func load():
	if data == null:
		data = GameResourceLoader.getResourceLoader().getBufferedImage(name)
		height = data.get_height()
		width = data.get_width()
	texture = GameTexture.fromImage(name, data)


func getName():
	return name


func getHeight():
	return height


func getWidth():
	return width


func getTexture():
	if destroyed:
		texture = GameTexture.fromImage(name, data)
		destroyed = false
	return texture


## Java overloads: draw(g), draw(g, x, y), draw(g, x, y, scale).
func draw(g, x = null, y = null, scale = null):
	if x == null:
		draw(g, self.x, self.y, 1.0)
		return
	if scale == null:
		scale = 1.0
	texture.bind(g.getGL())
	var ny: int = int(y)
	var nyh: int = int(y + height * scale)
	var xw: int = int(x + width * scale)
	g.drawi(texture.getImageTexCoords(), int(x), nyh, xw, ny)


func drawCentered(g, y):
	var w: int = J.round(width / 2.0)
	var nx: int = J.round(Values.ORIGINAL_RESOLUTION[Values.X] / 2.0) - w
	draw(g, nx, y)


func destroy(g):
	texture.destroy(g.getGL())
	destroyed = true


func isLoaded():
	return loaded


func setPosition(x, y):
	self.x = x
	self.y = y


func setXpos(xpos):
	x = xpos


func setYpos(ypos):
	y = ypos


func getYpos():
	return y


func getXpos():
	return x


func setName(name):
	self.name = name


func bind(g):
	texture.bind(g.getGL())
