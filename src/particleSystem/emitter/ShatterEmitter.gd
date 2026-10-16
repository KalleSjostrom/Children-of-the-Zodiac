class_name ShatterEmitter
extends Emitter
## Port of particleSystem.emitter.ShatterEmitter.

var imageDateSet: bool = false
static var enemyName = null
var enemyInfo = null
var scale: float = 0.0
static var width: int = 0
static var height: int = 0
static var pixels = null
static var alpha = null

func _init(p_particlePool = null, p_particles = null, p_info = null, p_emitTimeStep = null, p_limit = null) -> void:
	super(p_particlePool, p_particles, p_info, p_emitTimeStep, p_limit)

func update(system, elapsedTime):
	if not isDestroyed():
		if not imageDateSet:
			imageDateSet = true
			getImage(system)
			enemyInfo = system.getEnemy().getInfo()
			scale = enemyInfo.get_(EnemyInfo.SCALE) * 800
		addTime(elapsedTime)
		var empty: bool = false
		while not empty and getTime() >= getEmitTimeStep():
			if okToEmit():
				var p = getParticle(system)
				var pos = p.getPosition()

				var a: float = 0.0
				var x: int = 0
				var y: int = 0
				var c = null
				var tries: int = 0
				while a < 0.5 and tries < 50:
					tries += 1
					x = int(J.random() * width)
					y = int(J.random() * height)
					a = getAlpha(x, y)
				if tries >= 50:
					continue
				c = getColor(x, y)
				pos.y = y / 200.0
				pos.x = ((x - 0.5 * width) / 200.0)

				pos.x *= scale
				pos.y *= scale
				pos.y += enemyInfo.get_(EnemyInfo.HEIGHT)
				pos.x += enemyInfo.get_(EnemyInfo.X_OFFSET)
				pos.z = getInfo().getSource().z
				p.resurrect(system, pos)
				p.setColor(c, a)
				getParticles().append(p)
			empty = not okToEmit()
			addTime(-getEmitTimeStep())

static func getImage(system):
	var name: String = system.getEnemy().getCurrentImageName()
	var image: Image = ImageHandler.getImage(name)
	if enemyName != null and name == enemyName:
		return
	var w: float = image.get_width()
	var h: float = image.get_height()

	var scalex: float = 0.25
	var scaley: float = 0.25
	w *= scalex
	h *= scaley

	width = J.round(w)
	height = J.round(h)
	image = GraphicHelp.scaleImage(image, width, height)

	# Java: Raster.getPixels (RGBA bands per pixel) and the alpha raster,
	# rows stored bottom-up.
	pixels = J.array(height)
	alpha = J.array(height)
	for i in range(height):
		var row: Array = J.array(width * 4, 0)
		var arow: Array = J.array(width, 0)
		for x in range(width):
			var col: Color = image.get_pixel(x, i)
			row[x * 4] = col.r8
			row[x * 4 + 1] = col.g8
			row[x * 4 + 2] = col.b8
			row[x * 4 + 3] = col.a8
			arow[x] = col.a8
		pixels[(height - 1) - i] = row
		alpha[(height - 1) - i] = arow

func getColor(x, y):
	x *= 4
	return Vector3f.new(
			pixels[y][x] / 255.0, pixels[y][x + 1] / 255.0, pixels[y][x + 2] / 255.0)

static func getAlpha(x, y):
	if alpha[y][x] / 255.0 == 1:
		var temp: float = alpha[y][x] / 255.0
		alpha[y][x] = 0
		return temp
	return alpha[y][x] / 255.0
