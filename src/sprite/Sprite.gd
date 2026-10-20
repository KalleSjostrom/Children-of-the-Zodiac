class_name Sprite
extends RefCounted
## Port of sprite.Sprite: an animated object (player, party members,
## villagers, actors, ...).
##
## Port notes (Java overloads merged, see docs/port_notes/story.md):
##  - setPos(p): a Java int[] position (as created by Parser.getPos: three
##    ints [x, y, direction]) is recognised by its size (>= 3) and int
##    elements; otherwise p is the float[] position [y, x] which is stored.
##  - move/moveActor/standStill/standStillActor(dir = null, anim = null,
##    ia = null): 0, 1 or 3 arguments as the Java overloads. The internal
##    3-argument versions (never overridden in Java) are _moveImpl etc.
##  - update(f): Java's update(float elapsedTime).

const STANDARD_WIDTH = 36
const STANDARD_HEIGHT = 56

var animImages = null
var anim = VillageAnimation.new()
var name = ""
var drawX: int = 0
var drawY: int = 0
var direction: int = 0
var width: int = STANDARD_WIDTH
var height: int = STANDARD_HEIGHT
var moving: bool = false
var speed: float = 0.0
var pos = [0.0, 0.0]

static var EMOTIONS = null

var xs = [15, 17, 19]
var currentX: int = 1
var currentEmotion: int = -1
# Java: new Rectangle(0, 0, getHeight(), getWidth()) (width and height swapped
# as in the original).
var boundingRect = SpriteRectangle.new(0, 0, STANDARD_HEIGHT, STANDARD_WIDTH)
var shakeEmotion: bool = false
var counter: float = 0.0
var emotionSpeed: float = 0.8
var emotionX: int = 0
var emotionY: int = 0
var size: int = 4


## Java's static initializer: the emotion images, loaded permanently on first
## use (lazily, so that loading this script does not load textures).
static func _getEmotions() -> Array:
	if EMOTIONS == null:
		EMOTIONS = [
			Values.Emotions + "exclamation.png", Values.Emotions + "question.png",
			Values.Emotions + "questionEx.png", Values.Emotions + "dot.png",
			Values.Emotions + "aye.png", Values.Emotions + "no.png",
			Values.Emotions + "zzz.png", Values.Emotions + "hihi.png",
			Values.Emotions + "ha1.png", Values.Emotions + "ha2.png"]
		for i in EMOTIONS.size():
			ImageHandler.addPermanentlyLoadNow(EMOTIONS[i])
	return EMOTIONS


## Java overloads: loadImages(path, name, nr) and loadImages(path, name)
## (16 images).
func loadImages(path, name, nr = null):
	if nr == null:
		nr = 16
	loadImagesFromPath(str(path) + str(name) + "/" + str(name), nr)


func loadImagesFromPath(path, nr):
	animImages = J.array(nr, "")
	for i in animImages.size():
		animImages[i] = str(path) + str(i + 1) + ".png"
		ImageHandler.addToCurrentLoadNow(animImages[i])
	size = mini(nr, size)
	for i in size:
		anim.addFrame(animImages[0], 150)


## Loads the images for this sprite in the list of permanent images.
func loadPermImages(path, name):
	animImages = J.array(16, "")
	for i in animImages.size():
		animImages[i] = str(path) + str(name) + "/" + str(name) + str(i + 1) + ".png"
		ImageHandler.addPermanentlyLoadNow(animImages[i])
	for i in size:
		anim.addFrame(animImages[0], 150)


## Returns the bounding rectangle (the same, mutable, object every time).
func getRectangle():
	boundingRect.x = J.round(pos[Values.X])
	boundingRect.y = J.round(pos[Values.Y])
	return boundingRect


## Takes the information from the given sprite and overwrites this one's.
func merge(sprite):
	animImages = sprite.animImages
	anim = sprite.anim
	pos = sprite.pos
	name = sprite.name
	drawX = sprite.drawX
	drawY = sprite.drawY


func getHeight():
	return height


func getWidth():
	return width


## Java overloads: checkCollision(checkPos, maxDistance) and
## checkCollision(checkPos, maxDistance, direction).
func checkCollision(checkPos, maxDistance = null, direction = null):
	if direction == null:
		direction = self.direction
	var collided := false
	if inRange(checkPos, maxDistance, false):
		if direction == Values.UP:
			collided = checkPos[Values.Y] < pos[Values.Y]
		elif direction == Values.RIGHT:
			collided = checkPos[Values.X] > pos[Values.X]
		elif direction == Values.DOWN:
			collided = checkPos[Values.Y] > pos[Values.Y]
		elif direction == Values.LEFT:
			collided = checkPos[Values.X] < pos[Values.X]
	return collided


## Java: update(float elapsedTime) (milliseconds).
func update(f, player = null, reset = null):
	anim.update(f)


## Gets the current image in the animation of this sprite.
func getImage():
	return anim.getImage()


func inRange(checkPos, maxDistance, b):
	var dist := int(Vector2(checkPos[Values.X], checkPos[Values.Y]).distance_to(
		Vector2(pos[Values.X], pos[Values.Y])))
	return dist < maxDistance


func isVisible():
	var compareX: int = drawX + getWidth()
	var compareY: int = drawY + getHeight()
	return compareX > 0 or drawX < Values.RESOLUTIONS[Values.X] \
		or compareY > 0 or drawY < Values.RESOLUTIONS[Values.Y]


func isMoving():
	return moving


func getName():
	return name


func setName(name):
	self.name = name


func getPos():
	return pos


## Java overloads setPos(float[] p) and setPos(int[] p) (see the file header).
func setPos(p):
	if _isIntPos(p):
		pos[0] = float(p[1])
		pos[1] = float(p[0])
		_standStillImpl(p[2], anim, animImages)
	else:
		pos = p


## True if p is a Java int[] position (Parser.getPos: [x, y, direction]).
static func _isIntPos(p) -> bool:
	return p is Array and p.size() >= 3 and p[0] is int and p[1] is int


func drawAtPosition(g, x, y):
	drawSprite(g, x, y)


## Java overloads: draw(Graphics g) and the abstract draw(g, int x, int y).
func draw(g, x = null, y = null):
	if x == null:
		drawSprite(g, drawX, drawY)


func drawSprite(g, x, y):
	g.drawImage(anim.getImage(), x, y)
	if currentEmotion != -1:
		emotionX = x
		emotionY = y


## Bridge (phase 1 step B, docs/ARCHITECTURE.md): drawSprite(g, x, y)
## without drawing, for a mode whose scene draws the sprite (ActorView):
## keeps what drawSprite sets (the emotion bubble's position) and returns
## the image it would draw (an image path, or null).
func place_sprite(x, y):
	if currentEmotion != -1:
		emotionX = x
		emotionY = y
	return anim.getImage()


## Bridge (phase 1 step B): draw(g, x, y) without drawing, for the sprites of
## a village scene: [image, screen x, screen y] as place_sprite, or [] when
## draw(g, x, y) draws nothing (as here; subclasses draw). The particle
## systems return their particles instead (BodiesParticleSystem.place_view).
func place_view(x, y):
	return []


func drawEmotions(g):
	if currentEmotion != -1:
		if shakeEmotion:
			if ((counter + emotionSpeed) > xs.size() - 1) or ((counter + emotionSpeed) < 0):
				emotionSpeed *= -1
			counter += emotionSpeed
			currentX = J.round(counter)
		g.drawImage(_getEmotions()[currentEmotion], emotionX + xs[currentX], emotionY - 13)


## Java overloads: setImages() and setImages(int direction).
func setImages(direction = null):
	if direction == null:
		direction = self.direction
	if isMoving():
		_moveImpl(direction, anim, animImages)
	else:
		_standStillImpl(direction, anim, animImages)


## Java overloads: move(), move(int dir) and move(int dir, Animation, String[]).
func move(dir = null, anim = null, ia = null):
	if dir == null:
		_moveImpl(direction, self.anim, animImages)
	elif anim == null:
		_moveImpl(dir, self.anim, animImages)
	else:
		_moveImpl(dir, anim, ia)


## Java overloads: moveActor(), moveActor(int) and moveActor(int, Animation, String[]).
func moveActor(dir = null, anim = null, ia = null):
	if dir == null:
		_moveActorImpl(direction, self.anim, animImages)
	elif anim == null:
		_moveActorImpl(dir, self.anim, animImages)
	else:
		_moveActorImpl(dir, anim, ia)


## Java overloads: standStill(), standStill(int) and standStill(int, Animation, String[]).
func standStill(dir = null, anim = null, ia = null):
	if dir == null:
		_standStillImpl(direction, self.anim, animImages)
	elif anim == null:
		_standStillImpl(dir, self.anim, animImages)
	else:
		_standStillImpl(dir, anim, ia)


## Java overloads: standStillActor(int) and standStillActor(int, Animation, String[]).
func standStillActor(dir, anim = null, ia = null):
	if anim == null:
		_standStillActorImpl(dir, self.anim, animImages)
	else:
		_standStillActorImpl(dir, anim, ia)


## Java: protected move(int dir, Animation anim, String[] ia).
func _moveImpl(dir: int, p_anim, ia) -> void:
	if ia == null:
		return
	for i in size:
		if dir * size < ia.size() and i < ia.size():
			p_anim.changePic(i, ia[i + dir * size])


## Java: protected standStill(int dir, Animation anim, String[] ia).
func _standStillImpl(dir: int, p_anim, ia) -> void:
	if ia == null:
		return
	for i in size:
		if dir * size < ia.size():
			p_anim.changePic(i, ia[dir * size])


## Java: protected moveActor(int dir, Animation anim, String[] ia).
func _moveActorImpl(dir: int, p_anim, ia) -> void:
	if not moving or direction != dir:
		direction = dir
		moving = true
		if ia == null:
			return
		for i in size:
			if dir * size < ia.size() and i < ia.size():
				p_anim.changePic(i, ia[i + dir * size])


## Java: protected standStillActor(int dir, Animation anim, String[] ia).
func _standStillActorImpl(dir: int, p_anim, ia) -> void:
	if moving or direction != dir:
		direction = dir
		moving = false
		if ia == null:
			return
		for i in size:
			if dir * size < ia.size():
				p_anim.changePic(i, ia[dir * size])


## Shows the image in the animation images with the given index.
func animate(pos):
	for i in size:
		anim.changePic(i, animImages[pos])


## Adds an image with the given name at the given index of the animation
## images (the array grows if needed).
func addAnimation(name, pos):
	if pos >= animImages.size():
		var newAnim := J.array(pos + 1, null)
		for i in animImages.size():
			newAnim[i] = animImages[i]
		animImages = newAnim
	animImages[pos] = name


func getX():
	return pos[Values.X]


func getY():
	return pos[Values.Y]


func setDirection(dir):
	direction = dir


func setEmotion(show, emotion, shake):
	currentEmotion = emotion if show else -1
	currentX = 1
	shakeEmotion = shake


func getDirection():
	return direction


func setMoving(m):
	moving = m


## java.awt.Rectangle (mutable, shared like in Java).
class SpriteRectangle extends RefCounted:
	var x: int = 0
	var y: int = 0
	var width: int = 0
	var height: int = 0

	func _init(px: int = 0, py: int = 0, w: int = 0, h: int = 0) -> void:
		x = px
		y = py
		width = w
		height = h

	## java.awt.Rectangle.intersects(Rectangle).
	func intersects(r) -> bool:
		var tw: int = width
		var th: int = height
		var rw: int = r.width
		var rh: int = r.height
		if rw <= 0 or rh <= 0 or tw <= 0 or th <= 0:
			return false
		var tx: int = x
		var ty: int = y
		var rx: int = r.x
		var ry: int = r.y
		rw += rx
		rh += ry
		tw += tx
		th += ty
		return ((rw < rx or rw > tx) and (rh < ry or rh > ty)
			and (tw < tx or tw > rx) and (th < ty or th > ry))
