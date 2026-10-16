class_name DoubleBackground
extends GameSprite2D
## Port of graphics.DoubleBackground: manages the backgrounds of a village or
## the landscape (bottom layer tiles, top layer images, night layer and
## particle systems).

const BOTTOM_LAYER = -1
const VILLAGER_LAYER = 0
const UPPER_LAYER = 1
const WEATHER_LAYER = 2
const POS = 0
const TARGET = 1
const STEP = 2
const ACC = 3
## java.awt.image.BufferedImage.TYPE_INT_RGB / TYPE_INT_ARGB.
const TYPE_INT_RGB = 1
const TYPE_INT_ARGB = 2
var velocityTarget: float = 0.0
var pos = [0.0, 0.0]
var target = null
var accelerating = [false, false]
var moving: bool = false
var nightTop = null
var imageWidth: int = 0
var imageHeight: int = 0
var HORIZONTAL_IMAGES: int = 0
var VERTICAL_IMAGES: int = 0
var bg = null
var extraBackground = null
## Java HashMap<int[], String> (identity keys): an Array of [int[] pos, String].
var top = []
## Java HashMap<int[], String> (identity keys): an Array of [int[] pos, String].
var bottom = []
## Java HashMap<Integer, ArrayList<ParticleSystem>>.
var systems = {}
var height_: int = 0
var width_: int = 0
var offsetx: int = 0
var offsety: int = 0
var actualHeight: int = 0
var actualWidth: int = 0
const USE_CUT = true

static var _staticLoaded: bool = false


## Java overloads: DoubleBackground(int bw, int bh) and
## DoubleBackground(int backgroundWidth, int backgroundHeight, int actualWidth, int actualHeight).
func _init(backgroundWidth = null, backgroundHeight = null, actualWidth = null, actualHeight = null) -> void:
	super(null, null)
	if not _staticLoaded:
		# Java static initializer.
		_staticLoaded = true
		ImageHandler.addPermanentlyLoadOnUse(Values.VillageImages + "top/greentree.png")
	if actualWidth == null:
		actualWidth = backgroundWidth
		actualHeight = backgroundHeight
	width_ = backgroundWidth
	height_ = backgroundHeight
	self.actualHeight = actualHeight
	self.actualWidth = actualWidth
	target = J.array2d(2, 5, 0.0)


## Java overloads: init(String name, boolean nightLayer),
## init(String path, String name, boolean nightLayer),
## init(String name, boolean nightLayer, int extra),
## init(String path, String name, boolean nightLayer, int extra).
func init(path, name, nightLayer = null, extra = null):
	if name is bool:
		# init(name, nightLayer[, extra])
		var n = path
		var night: bool = name
		var ex = nightLayer
		if ex == null:
			loadImages(n, n, night)
		else:
			loadImages(n, n, night, ex)
	else:
		if extra == null:
			loadImages(path, name, nightLayer)
		else:
			loadImages(path, name, nightLayer, extra)


func setLandscapeImages(names, night):
	if USE_CUT:
		var n: String = doit(Values.LandscapeImages, "", names[0], night)
		bg = cutImage(n, 0, TYPE_INT_RGB)
		doTopLayer(Values.LandscapeImages, names[1])
	else:
		bottom.append([[0, 0], doit(Values.LandscapeImages, "", names[0], night)])
		doTopLayer(Values.LandscapeImages, names[1])


## Java overloads: loadImages(path, name, nightLayer) and
## loadImages(path, name, nightLayer, int extra).
func loadImages(path, name, nightLayer, extra = null):
	if extra == null:
		var n: String = doit(path, name, nightLayer)
		bg = cutImage(n, 0, TYPE_INT_RGB if n.ends_with(".jpg") else TYPE_INT_ARGB)
		doTopLayer(Values.VillageImages, path)
		return
	var temp: String = name + "0"
	var fullTemp: String = Values.VillageImages + path + "/" + temp + ".jpg"
	if not GameResourceLoader.getResourceLoader().exists(fullTemp):
		temp = name
	putextra(path, temp, nightLayer, [0, 0])
	if extra == 1:
		var w: int = J.round((getWidth() + 0.1) / 2.0)
		var p := [0, 0]
		p[Values.X] = w
		putextra(path, name + "1", nightLayer, p)
	elif extra == 2:
		var h: int = J.round((getHeight() + 0.1) / 2.0)
		var p := [0, 0]
		p[Values.Y] = h
		putextra(path, name + "1", nightLayer, p)
	doTopLayer(Values.VillageImages, path)


## Java overloads: doit(folder, path, name, nightLayer) and
## doit(path, name, nightLayer) (folder = Values.VillageImages).
func doit(folder, path, name, nightLayer = null):
	if nightLayer == null:
		return doit(Values.VillageImages, folder, path, name)
	var name1: String = folder + path + ("" if path == "" else "/")
	var name2: String = name1
	var rl := GameResourceLoader.getResourceLoader()
	if nightLayer:
		var jpgFileName: String = name1 + name + " at Night.jpg"
		if rl.exists(jpgFileName) or rl.exists(name1 + name + " at Nightfolder"):
			name1 = jpgFileName
		else:
			name1 += name + ".jpg"
		var topFileName: String = name2 + name + " at Night - 1.png"
		if rl.exists(topFileName):
			nightTop = topFileName
		else:
			nightTop = folder + "standardOvernight.png"
		ImageHandler.addToCurrentLoadNow(nightTop)
	else:
		var temp: String = name1 + name + ".png"
		if rl.exists(temp) or (rl.exists(name1 + name + "folder") \
				and rl.exists(name1 + name + "folder/x0y0.png")):
			name1 = temp
		else:
			temp = name1 + name + ".jpg"
			name1 = temp
	return name1


func doTopLayer(path, name):
	var reader = GameResourceLoader.getResourceLoader().getBufferedReader(path + name, "/top/top.info")
	if reader == null:
		return
	var line = ""
	while line != null:
		line = reader.readLine()
		if line != null:
			var args: Array = J.split(line, ":")
			var n: String = args[0]
			var p := [0, 0]
			p[Values.X] = J.parseInt(args[1])
			p[Values.Y] = J.parseInt(args[2])
			if n.begins_with("i"):
				n = n.replace("i/", "")
				top.append([p, path + "/top/" + n])
			else:
				top.append([p, path + name + "/top/" + n])
	reader.close()


func cutImage(im, layer, type):
	var bga
	if im != "No Place":
		var jpg: bool = im.ends_with(".jpg")
		var pathen: String = im.replace(".jpg" if jpg else ".png", "folder")
		var b: bool = GameResourceLoader.getResourceLoader().exists(
				pathen + "/x0y0" + (".jpg" if jpg else ".png"))
		if b:
			bga = generateNames(pathen, jpg)
		else:
			bga = cutImage2(im, layer, type, null, pathen, jpg)
	else:
		bga = []
	return bga


## Cuts the image into 256x256 tiles. Java also wrote the tiles to disk (a
## cache folder next to the image); this port only cuts them in memory.
func cutImage2(im, layer, type, f, pathen, jpg):
	var image: Image = GameResourceLoader.getResourceLoader().getBufferedImage(im)
	if image == null:
		push_error("DoubleBackground: could not load " + str(im))
		return []
	if self.bg == null:
		imageWidth = 256
		imageHeight = 256
		HORIZONTAL_IMAGES = int(ceil(image.get_width() / float(imageWidth)))
		VERTICAL_IMAGES = int(ceil(image.get_height() / float(imageHeight)))
		self.bg = J.array2d(HORIZONTAL_IMAGES, VERTICAL_IMAGES, null)
	var bgl: Array = J.array2d(HORIZONTAL_IMAGES, VERTICAL_IMAGES, null)

	var usedWidth: int = imageWidth
	var usedHeight: int = imageHeight

	for i in range(HORIZONTAL_IMAGES):
		if i == HORIZONTAL_IMAGES - 1:
			usedWidth = image.get_width() - (i * imageWidth)
		else:
			usedWidth = imageWidth
		for j in range(VERTICAL_IMAGES):
			if j == VERTICAL_IMAGES - 1:
				usedHeight = image.get_height() - (j * imageHeight)
			else:
				usedHeight = imageHeight
			var one: Image = GraphicHelp.createImage(usedWidth, usedHeight)
			var src: Image = image
			if src.get_format() != one.get_format():
				src = image.duplicate()
				src.convert(one.get_format())
				image = src
			one.blit_rect(src, Rect2i(i * imageWidth, j * imageHeight, usedWidth, usedHeight), Vector2i(0, 0))
			if type == TYPE_INT_RGB:
				# BufferedImage.TYPE_INT_RGB has no alpha channel.
				one.convert(Image.FORMAT_RGB8)
			bgl[i][j] = ImageHandler.addToCurrentConvertNow(im + "x" + str(i) + "y" + str(j), one)
	return bgl


func generateNames(path, jpg):
	if self.bg == null:
		imageWidth = 256
		imageHeight = 256
		HORIZONTAL_IMAGES = int(ceil(actualWidth / float(imageWidth)))
		VERTICAL_IMAGES = int(ceil(actualHeight / float(imageHeight)))
		self.bg = J.array2d(HORIZONTAL_IMAGES, VERTICAL_IMAGES, null)
	var bgl: Array = J.array2d(HORIZONTAL_IMAGES, VERTICAL_IMAGES, null)

	for i in range(HORIZONTAL_IMAGES):
		for j in range(VERTICAL_IMAGES):
			bgl[i][j] = ImageHandler.addToCurrentLoadNow(
					path + "/" + "x" + str(i) + "y" + str(j) + (".jpg" if jpg else ".png"))
	return bgl


func putextra(path, name, nightLayer, pos):
	bottom.append([pos, doit(path, name, nightLayer)])


## Sets either the x or y position depending on the first argument.
func setPos(XorY, newPos):
	moving = pos[XorY] != newPos
	pos[XorY] = float(newPos)
	updatePos(XorY)


## Java overloads: move(int XorY, int amount) and
## move(int distance, int direction, double duration).
func move(distance, direction, duration = null):
	if duration == null:
		var XorY: int = distance
		var amount = direction
		moving = true
		pos[XorY] += amount
		updatePos(XorY)
		return
	var index: int = direction % 2
	target[index][TARGET] = pos[index] + (distance * Values.DIRECTIONS[direction])
	index = absi(index - 1)
	target[index][TARGET] = float(pos[index])
	var dur: float = float(duration) / Values.LOGIC_INTERVAL
	for i in range(pos.size()):
		target[i][STEP] = abs(target[i][TARGET] - pos[i]) / dur
		target[i][STEP] *= Values.DIRECTIONS[direction]


func updatePos(XorY):
	target[XorY][POS] = float(pos[XorY])
	target[XorY][TARGET] = float(pos[XorY])


func getPos():
	return pos


func drawBottom(g):
	if extraBackground == null:
		drawBottomLayer(g)
	else:
		g.drawImage(extraBackground, pos[Values.X], pos[Values.Y], 1)


## Draws the top layer in the village: every static object that should be
## drawn on top of the player (roofs, treetops) and the night layer.
## sprites: Java HashMap<Integer, Sprite> (Dictionary) or null.
func drawTop(g, removeAlpha, sprites):
	if extraBackground == null:
		if removeAlpha:
			g.setAlphaFunc(0.9)
		var px: float = pos[Values.X]
		var py: float = pos[Values.Y]
		var spriteList = null
		if sprites != null:
			spriteList = sprites.values()
		for entry in top:
			var p: Array = entry[0]
			var s: String = entry[1]
			if spriteList != null:
				var gt: GameTexture = ImageHandler.getTexture(s)
				var h: int = gt.getHeight()
				var w: int = gt.getWidth()
				for sprite in spriteList:
					if sprite.isVisible():
						var sPos
						if sprite is PartyMember:
							sPos = sprite.getMemberPos()
						else:
							sPos = sprite.getPos()
						var temp: int = int(sPos[Values.X] - p[Values.X])
						if (temp + 36) > 0 and temp < w:
							var tempy: int = int(sPos[Values.Y] - p[Values.Y])
							if (tempy + 55) > 0 and tempy < h:
								g.drawImage(s, px + p[Values.X], py + p[Values.Y], 1)
								break
			else:
				g.drawImage(s, px + p[Values.X], py + p[Values.Y], 1)
		g.setAlphaFunc(0)
		if nightTop != null:
			if nightTop.contains("standard"):
				g.drawImage(nightTop, 0, 0, 2)
			else:
				g.drawImage(nightTop, pos[Values.X], pos[Values.Y], 2)
	drawSystem(g, systems.get(UPPER_LAYER))
	drawSystem(g, systems.get(WEATHER_LAYER))


func drawSystem(g, systems):
	if systems != null:
		for p in systems:
			p.draw(g, int(pos[Values.X]), int(pos[Values.Y]))


func updateSystem(elapsedTime, systems):
	if systems != null:
		for p in systems:
			p.update(elapsedTime)


func drawBottomLayer(g):
	drawSystem(g, systems.get(BOTTOM_LAYER))
	if USE_CUT:
		var x: int
		var y: int
		var resX: int = Values.ORIGINAL_RESOLUTION[Values.X]
		var resY: int = Values.ORIGINAL_RESOLUTION[Values.Y]
		var px: float = pos[Values.X]
		var py: float = pos[Values.Y]
		for i in range(HORIZONTAL_IMAGES):
			x = int(i * imageWidth + px) + offsetx
			if x > -imageWidth and x < resX:
				var column: Array = bg[i]
				for j in range(VERTICAL_IMAGES):
					y = int(j * imageHeight + py + offsety)
					if y > -imageHeight and y < resY:
						g.drawImage(column[j], x, y)
	else:
		for entry in bottom:
			var p: Array = entry[0]
			g.drawImage(entry[1], pos[Values.X] + p[Values.X] + offsetx,
					pos[Values.Y] + p[Values.Y] + offsety, 1)


func update(elapsedTime):
	for i in range(2):
		var p: float = target[i][POS]
		var t: float = target[i][TARGET]
		var s: float = target[i][STEP]
		var a: float = target[i][ACC]

		if accelerating[i] and abs(s) >= abs(velocityTarget):
			target[i][ACC] = 0.0
			accelerating[i] = false
		if p != t:
			if abs(p - t) <= abs((p + s + a) - t):
				target[i][POS] = t
				target[i][ACC] = 0.0
			else:
				target[i][STEP] += target[i][ACC]
				target[i][POS] += target[i][STEP]
			pos[i] = float(J.round(target[i][POS]))
	updateSystem(elapsedTime, systems.get(UPPER_LAYER))
	updateSystem(elapsedTime, systems.get(WEATHER_LAYER))


func moveTo(x, y, time):
	var numberOfSteps: float = time / float(Values.LOGIC_INTERVAL)
	var distX: float = x - pos[Values.X]
	var distY: float = y - pos[Values.Y]
	var stepX: float = distX / numberOfSteps
	var stepY: float = distY / numberOfSteps
	target[Values.X][TARGET] = float(x)
	target[Values.Y][TARGET] = float(y)
	target[Values.X][STEP] = stepX
	target[Values.Y][STEP] = stepY


## v^2 - v0^2 = 2as; a = -v0^2 / (2 * s) since v = 0 (the screen stops);
## v0 is the current step size.
func stopScreen():
	for i in range(2):
		var p: float = target[i][POS]
		var t: float = target[i][TARGET]
		if p != t:
			var s: float = abs(p - t)
			target[i][ACC] = (target[i][STEP] * target[i][STEP]) / (2 * s)
			target[i][ACC] *= 1 if target[i][STEP] < 0 else -1


func moveScreen(a, s, t, direction):
	for i in range(2):
		target[i][ACC] = 0.0
		target[i][STEP] = 0.0
		target[i][TARGET] = 0.0

	var fa: float = a
	var tt: float = float(t) / Values.LOGIC_INTERVAL
	var first: float = fa * tt
	var second: float = fa * fa * tt * tt - 2 * fa * s
	var sq: float = sqrt(second)
	velocityTarget = first - sq # Choose this root instead of first + sqrt. (Why?)
	var index: int = direction % 2
	accelerating[index] = true
	target[index][TARGET] = pos[index] + (s * Values.DIRECTIONS[direction])
	target[index][ACC] = -fa if target[index][TARGET] < pos[index] else fa
	index = absi(index - 1)
	target[index][TARGET] = float(pos[index])


func stop():
	moving = false


func isMoving():
	return moving


## Centers the background around the given position.
func centerAround(playerPos):
	if playerPos != null:
		var hx: int = Values.ORIGINAL_RESOLUTION[Values.X] / 2
		var hy: int = Values.ORIGINAL_RESOLUTION[Values.Y] / 2
		var y: float = max(playerPos[Values.Y], hy)
		var x: float = max(playerPos[Values.X], hx)
		y = min(y, getHeight() - hy)
		x = min(x, getWidth() - hx)
		pos[Values.X] = float(-J.round(x - hx))
		pos[Values.Y] = float(-J.round(y - hy))


func checkUpRight(axis):
	var ret: bool
	if axis == Values.X:
		ret = pos[axis] <= -(getWidth() - Values.ORIGINAL_RESOLUTION[Values.X])
	else:
		ret = pos[axis] <= -(getHeight() - Values.ORIGINAL_RESOLUTION[Values.Y])
	return ret


func checkDownLeft(axis):
	return pos[axis] >= 0


func setExtraBack(back):
	extraBackground = back


func getHeight():
	return height_


func getWidth():
	return width_


func addSystem(p, layer):
	var sys = systems.get(layer)
	if sys == null:
		sys = []
		systems[layer] = sys
	sys.append(p)


func setOffset(x, y):
	offsetx = x
	offsety = y


func getParticleSystem(name):
	for ps in systems.values():
		for p in ps:
			if p.getName() == name:
				return p
	return null
