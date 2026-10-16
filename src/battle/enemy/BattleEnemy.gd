class_name BattleEnemy
extends Object2D
## Port of battle.enemy.BattleEnemy: wraps a normal enemy (character.Enemy)
## into a 3D BattleEnemy which can be drawn, animated and battled against.
##
## Port notes:
## * Static setColor(float[]) is setColorStatic(c); the instance
##   setColor(Vector3f) keeps its name.
## * Fields named like methods: attack_ (the Attack name display), slice_,
##   shouldHit_.
## * The Java threads (attack animation, shake, rise, color recovery, slice)
##   are coroutines using Scheduler (PORTING.md section 5). attack() is a
##   coroutine: it returns immediately to a caller that does not await it.
## * drawSlice(g, texIndex, coordIndex) and drawSlice(g, texture, x, y, z)
##   are merged: an int second argument selects the first overload.

static var color = null
static var source = null
static var usedColor = null
var test1: float = 0.0
var test2: float = 0.0
var xs: float = 0.0
var hitting: bool = false
var images = null
var vector = null
var totalTime: float = 0.0
var info = null
var killed: bool = false
var rounds: int = 0
var attack_ = null
var card = null
var risey: float = 0.0
var shakeoffy: float = 0.0
var shakeoffx: float = 0.0
var mode: int = 0
var origHeight: float = 0.0
var origWidth: float = 0.0
var particleSystem: Array = []
var tempSource = null
var enemy = null
var slice_: bool = false
var useCritImage: bool = false
const XS_ACC = 0.00003
var xsSpeed: float = 0.0
var life: float = 0.0
var sliceFade: float = 0.0
var battle = null
var shouldHit_: bool = false
var preloadedSystem = null


## Wraps the given enemy into a 3D BattleEnemy.
func _init(enemy = null) -> void:
	super(enemy.getImages().size() + 1)
	if color == null:
		setColorStatic([1.0, 1.0, 1.0, 1.0])
	currentList = enemy.getStartFrame()
	images = enemy.getImages()
	info = enemy.getInfo()
	self.enemy = enemy

	attack_ = Attack.new()
	card = EnemyCard.new()


static func setColorStatic(c):
	color = c
	source = Values.copyArray(color)
	usedColor = Values.copyArray(color)


## Loads a texture for each animation frame of the enemy.
func initDraw(g: Graphics):
	for i in images.size():
		loadTexture(images[i], i)
	setSize(0, info.get_(EnemyInfo.SCALE))
	origWidth = width
	origHeight = height
	createCoords()
	attack_.initDraw(g)
	card.initDraw(g)


## Java: update(float elapsedTime) in milliseconds.
func update(progress = null):
	var elapsedTime: float = float(progress) if progress != null else 0.0
	attack_.update()
	card.update()
	for psp in particleSystem.duplicate():
		psp.update(elapsedTime / 1000.0)
		if psp.isDead():
			particleSystem.erase(psp)


## Creates the texture coordinates for the enemy texture. (Java:
## createCoords(); a single int argument goes to Object2D.createCoords(int).)
func createCoords(saveW = null, saveH = null, handW = null, handH = null):
	if saveW != null:
		super.createCoords(saveW)
		return
	createCoordList(1)

	var x: float = info.get_(EnemyInfo.X_OFFSET)
	createCoordFor((-width / 2) + x, (width / 2) + x, 0, X)
	var y: float = info.get_(EnemyInfo.HEIGHT)
	createCoordFor(y, y + height, 0, Y)
	createCoordFor(0, 0, 0, Z)


func slice():
	xs = 0
	xsSpeed = 0
	slice_ = true
	life = 2.5
	var nrFadeSteps: float = 1500.0 / Values.LOGIC_INTERVAL
	sliceFade = 3 / nrFadeSteps
	Scheduler.after(1500, func(): slice_ = false)


func drawTopLayer(g: Graphics):
	if useCritImage and not isVisible():
		g.fadeOldSchoolColorWhite(0.8, 0, 0, 0.5)


## Draws the enemy, its particle systems, the attack name and the card.
func draw(g, alpha = null, angle = null, origin = null, lastOrigin = null):
	if not killed:
		g.loadIdentity()
		g.translate(shakeoffx, shakeoffy + risey, info.get_(EnemyInfo.DEPTH))
		g.setColor3(usedColor)
		if isVisible():
			if slice_:
				life -= sliceFade
				drawSlice(g, currentList, 0)
			else:
				drawTex(g, currentList, 0)

		g.loadIdentity()
		for psp in particleSystem.duplicate():
			psp.draw(g)
		g.setColor(1)
		g.setAlphaTestEnabled(true)
		g.setAlphaFunc(0.1)
		attack_.draw(g)
		g.setAlphaFunc(0)
		card.draw(g)
	g.setColor(1)


func drawSlice(g, texture, x, y = null, z = null):
	if texture is int:
		var texIndex: int = texture
		var coordIndex: int = x
		if self.texture[texIndex] != null:
			var cl: Array = coordList[coordIndex]
			drawSlice(g, self.texture[texIndex].getTexture(), cl[0], cl[1], cl[2])
		return
	var gl = g.getGL()
	xsSpeed += XS_ACC * Values.INTERVAL
	xs -= xsSpeed
	var ys: float = xs * 0.3

	var y1: float = info.get_(EnemyInfo.HEIGHT)
	var y0: float = y1 + height
	var ym: float = info.get_(EnemyInfo.MIDDLE_POINT)
	var p: float = (y0 - ym) / (y0 - y1)

	test1 = p + 0.1
	test2 = p - 0.1
	var test1c: float = 1 - test1
	var test2c: float = 1 - test2

	var testy1: float = y[0] + (y[1] - y[0]) * test1c
	var testy2: float = y[0] + (y[1] - y[0]) * test2c
	g.setColor4(usedColor, life)
	g.push()
	texture.bind(gl)
	g.beginQuads()
	gl.glTexCoord2f(0, test1); gl.glVertex3f(x[0] + xs, testy1 + ys, z[0])
	gl.glTexCoord2f(1, test2); gl.glVertex3f(x[1] + xs, testy2 + ys, z[0])
	gl.glTexCoord2f(1, 0); gl.glVertex3f(x[1] + xs, y[1] + ys, z[1])
	gl.glTexCoord2f(0, 0); gl.glVertex3f(x[0] + xs, y[1] + ys, z[1])
	g.end()
	g.pop()

	testy1 = y[0] + (y[1] - y[0]) * test1c
	testy2 = y[0] + (y[1] - y[0]) * test2c

	texture.bind(gl)
	g.beginQuads()
	gl.glTexCoord2f(0, 1); gl.glVertex3f(x[0], y[0], z[0])
	gl.glTexCoord2f(1, 1); gl.glVertex3f(x[1], y[0], z[0])
	gl.glTexCoord2f(1, test2); gl.glVertex3f(x[1], testy2, z[1])
	gl.glTexCoord2f(0, test1); gl.glVertex3f(x[0], testy1, z[1])
	g.end()


func setScale():
	width *= 0.95
	height *= 0.95
	createCoords()


func isHitting():
	return hitting


## Starts the animation of the enemy attack (Java: separate threads).
func hit(i, target):
	if i == AttackInfo.NOP:
		return
	if i.getType() == Slot.NO_TYPE:
		attack(i, target)
	else:
		attack_.setAttackName(i.getName())
		card.setImage(i.getType(), i.getElement())
	if not hitting:
		hitting = true
		_hitThread(i, target)


func _hitThread(i, target) -> void:
	card.show()
	attack_.show()
	match i.getType():
		Slot.SUPPORT:
			await attack(i, target)
		Slot.MAGIC:
			await attack(i, target)
		Slot.ATTACK:
			await attack(i, target)
	card.hide()
	attack_.hide()


## Runs the frames of the attack (coroutine; Java slept between frames).
func attack(info, target):
	var frames: Array = info.getFrames()
	var def: int = 0
	var hasHit: bool = false
	for i in frames.size():
		var frame = frames[i]
		currentList = frame.getFrame()
		var sleepTime: float = frame.getAnimTime()
		var t1: int = J.currentTimeMillis()
		if frame.isDefault():
			def = frame.getFrame()
		if frame.playSoundEffect():
			var s: String = frame.getSoundEffect()
			SoundPlayer.playSound(Values.BattleSoundEffects + s + ".wav")
		if frame.shouldSwitchMusic():
			var s: String = frame.getMusic()
			battle.changeMusic(s, frame.getAnimTime())
		if frame.characterMode() > 0:
			match frame.characterMode():
				1:
					battle.testShowCharacters()
				2:
					battle.testHideCharacters()
		if frame.shouldClearSystems():
			particleSystem.clear()
		if frame.hasCard() and frame.shouldPreload():
			preloadedSystem = frame.getCardSystem(self, target)
		elif frame.hasCard():
			if preloadedSystem == null:
				particleSystem.append(frame.getCardSystem(self, target))
			else:
				particleSystem.append(preloadedSystem)
				preloadedSystem = null
			frame.getCard().playSound()
		if frame.shouldRise():
			rise(frame.getAnimTime(), frame.getRiseSpeed())
		if not hasHit and frame.shouldHit():
			shouldHit_ = true
			hasHit = true
		if frame.shouldExit():
			exit()
		var f: bool = frame.shouldShake() or frame.shouldCameraShake()
		if f:
			if frame.shouldShake():
				shake(frame.getAnimTime())
			if frame.shouldCameraShake():
				Camera.shakeit(frame.getAnimTime())
		var t2: int = J.currentTimeMillis()
		sleepTime -= (t2 - t1)
		if sleepTime > 0:
			await Scheduler.sleep(int(sleepTime))
	if not hasHit:
		shouldHit_ = true
	currentList = def
	hitting = false


func exit():
	battle.exitToNext()


func setTempSource(source):
	tempSource = source


func getTempSource():
	return tempSource


## Shakes the enemy for the given time in milliseconds (coroutine).
func shakeit(time):
	var max_: int = int(time) / 50
	for j in max_:
		await Scheduler.sleep(50)
		var m: float = 0.05
		mode += 1
		mode %= 3
		match mode:
			0: shakeoffx = m
			1: shakeoffx = 0
			2: shakeoffx = -m
			3: shakeoffy = m
			4: shakeoffy = 0
			5: shakeoffy = -m
	shakeoffx = 0
	shakeoffy = 0


func shake(time):
	shakeit(time)


## Makes the enemy rise and fall during the given time (Java: a thread).
func rise(time, speed):
	var riseSpeed: float = 0.0
	var totalTime_: int = 0
	var interval: int = int(Values.LOGIC_INTERVAL)
	while totalTime_ < time / 2.0:
		riseSpeed += speed
		risey += riseSpeed
		totalTime_ += interval
		await Scheduler.sleep(interval)
	while totalTime_ < time:
		riseSpeed -= speed
		risey += riseSpeed
		totalTime_ += interval
		await Scheduler.sleep(interval)


## Changes the color of the enemy to the new color; it then recovers by
## moving along the vector from the new color to the old one.
func changeColor(newColor):
	if newColor == null:
		return
	totalTime = 0
	source = newColor
	usedColor = Values.copyArray(source)
	vector = Utils3D.createVector(newColor, color)
	width = origWidth
	height = origHeight
	createCoords()
	_recoverColor()


func _recoverColor() -> void:
	while Utils3D.calcDistance(usedColor, color, 1) > 0.01:
		totalTime += 0.02
		for i in 3:
			usedColor[i] = source[i] + vector[i] * totalTime
		await Scheduler.sleep(30)
	usedColor = Values.copyArray(color)


func cancelColorChange():
	usedColor = Values.copyArray(color)


## Java: setColor(Vector3f color).
func setColor(c):
	usedColor[0] = c.x
	usedColor[1] = c.y
	usedColor[2] = c.z


func shouldHit():
	return shouldHit_


func resetHit():
	shouldHit_ = false


## Hides this enemy for the given time (ms).
func setHideTimer(hideTime, criticalHit):
	hideFor(hideTime)
	self.useCritImage = criticalHit


func kill():
	killed = true


func getInfo():
	return info


func next(i = null):
	return null


func wouldLikeToTalk():
	if has_method("wantsToTalk"):
		return call("wantsToTalk", rounds)
	return false


func increment():
	rounds += 1


func shouldHitAfterTalk():
	return rounds > BossDialog.BEGINNING


func setDialog(i, d = null):
	rounds = i


func getDialogIndex():
	return rounds


func getNextPlace():
	return enemy.getNextPlace()


func oneTurn():
	pass


func getTarget(characters, i):
	var t: int = i.getTarget()
	if t == CharacterRow.RANDOM:
		t = EnemyLogic.calcTarget(characters)
	return t


func getCurrentImageName():
	return images[currentList]


func getEnemy():
	return enemy


func getSourceColor():
	return Values.copyArray(color)


func getTempHeight():
	return risey


func setBattle(battle):
	self.battle = battle
