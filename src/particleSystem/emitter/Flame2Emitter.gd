class_name Flame2Emitter
extends Emitter
## Port of particleSystem.emitter.Flame2Emitter.

var imageDateSet: bool = false
var enemyInfo = null
var scale: float = 0.0
var tempHeight: float = 0.0
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
			getImage()
			enemyInfo = system.getEnemy().getInfo()
			tempHeight = system.getEnemy().getTempHeight()
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
				var tries: int = 0
				var lastr: float = 0.0
				var r: float = 0.0
				while a < 0.5 and tries < 10:
					tries += 1
					lastr = r
					r = ParticleSystem.rand.nextDouble()
					var b: bool = tries % 2 == 0
					x = int((r if b else lastr) * width)
					y = int((lastr if b else r) * height)
					a = getAlpha(x, y)
				if tries >= 10:
					continue
				pos.y = y / 200.0
				pos.x = ((x - 0.5 * width) / 200.0)

				pos.x *= scale
				pos.y *= scale
				pos.y += enemyInfo.get_(EnemyInfo.HEIGHT) + tempHeight
				pos.x += enemyInfo.get_(EnemyInfo.X_OFFSET)
				pos.z = getInfo().getSource().z
				p.resurrect(system, pos)
				getParticles().append(p)
			empty = not okToEmit()
			addTime(-getEmitTimeStep())

static func getImage():
	var name: String = Values.BattleImages + "stroke3.png"
	var image: Image = ImageHandler.getImage(name)

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
			var c: Color = image.get_pixel(x, i)
			row[x * 4] = c.r8
			row[x * 4 + 1] = c.g8
			row[x * 4 + 2] = c.b8
			row[x * 4 + 3] = c.a8
			arow[x] = c.a8
		pixels[(height - 1) - i] = row
		alpha[(height - 1) - i] = arow

static func getAlpha(x, y):
	if alpha[y][x] / 255.0 == 1:
		var temp: float = alpha[y][x] / 255.0
		return temp
	return alpha[y][x] / 255.0
