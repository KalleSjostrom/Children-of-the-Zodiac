class_name ImageShape
extends EmitterShape
## Port of bodies.emitter.ImageShape: emits from the opaque pixels of an image.

var height: int = 0
var width: int = 0
var pixels = null
var flipY: bool = false
var flipX: bool = false


func _init(settings = null) -> void:
	super(settings)
	flipY = settings.getBoolean(ShapeSettings.FLIP_VERTICALLY)
	flipX = settings.getBoolean(ShapeSettings.FLIP_HORIZONTALLY)
	var scalex: float = settings.getValue(ShapeSettings.SCALE_X)
	var scaley: float = settings.getValue(ShapeSettings.SCALE_Y)
	scalex = 1.0 if scalex == 0 else scalex
	scaley = 1.0 if scaley == 0 else scaley
	var imageName: String = settings.getString(ShapeSettings.IMAGE)
	var image: Image = GameResourceLoader.getResourceLoader().getBufferedImage(
		Values.ParticleSystemsImages + imageName + ".png")
	if image == null:
		push_error("ImageShape: could not load image " + imageName)
		pixels = []
		return
	var w: float = image.get_width()
	var h: float = image.get_height()
	w *= scalex
	h *= scaley
	width = J.round(w)
	height = J.round(h)
	image = GraphicHelp.scaleImage(image, width, height)
	# Java reads the alpha raster row by row.
	pixels = J.array2d(height, width, 0)
	for i in range(height):
		var row = pixels[i]
		for j in range(width):
			row[j] = image.get_pixel(j, i).a8


func modifyDirection(direction):
	return direction


func getEmittancePos():
	var emitPosition = Vector3f.new()
	var found: bool = false
	var maxit: int = 500
	var i: int = 0
	var w: int = 0
	var h: int = 0
	if width <= 0 or height <= 0:
		return emitPosition
	# Java: while (!found || i < maxit) - runs at least maxit iterations and
	# continues until an opaque pixel is found.
	while not found or i < maxit:
		w = J.round(J.random() * (width - 1))
		h = J.round(J.random() * (height - 1))
		found = pixels[h][w] >= 100
		i += 1
	if found:
		emitPosition.x = float(width - w if flipX else w)
		emitPosition.y = -float(height - h if flipY else h)
		emitPosition.addLocal(getPosition())
	return emitPosition
