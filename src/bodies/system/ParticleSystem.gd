class_name BodiesParticleSystem
extends BodySystem
## Port of bodies.system.ParticleSystem (GDScript class BodiesParticleSystem):
## a system of particles emitted by an emitter and updated by commands.

var UPDATE_COMMAND = UpdateCommand.new()
var GRAVITY_COMMAND = GravityCommand.new()
var EMITTER_COMMAND = EmitterUpdateCommand.new()
var emitter = null
var additiveBlending: bool = false
var inited: bool = false
var active: bool = true
var cq = CommandQueue.new()
var tex = null
var position = Vector3f.new()
var background = null
var texture = null
var warmUp_: int = 0
var backx: int = 0
var backy: int = 0
var activateStatus: int = -1
static var windCommand = WindCommand.new()
var zeroTime: int = 0
# Not in Java: milliseconds not yet simulated (see update).
var stepTime: float = 0.0


## Java: ParticleSystem(SystemSettings settings, ParticleSettings pSettings,
## AbstractEmitter emitter, EmitterShape warmer).
func _init(settings = null, pSettings = null, emitter = null, warmer = null) -> void:
	super()
	var particleType: int = int(pSettings.getValue(ParticleSettings.KIND))
	var nrParticles: int = 0
	if settings != null:
		for type in SystemLoader.settingKeys(settings):
			var s: String
			match int(type):
				SystemSettings.TEXTURE:
					setTexture(settings.getString(type))
				SystemSettings.ADDITIVE:
					setAdditiveBlending(settings.getBoolean(type))
				SystemSettings.NR_PARTICLES:
					nrParticles = int(settings.getValue(type))
				SystemSettings.WARM_UP_LENGTH:
					warmUp_ = int(settings.getValue(type))
				SystemSettings.BACKGROUND:
					s = settings.getString(type)
					var args = J.split(s, ";")
					background = Values.ParticleSystemsImages + args[0]
					backx = J.parseInt(args[1])
					backy = J.parseInt(args[2])
				_:
					pass
	self.emitter = emitter

	for i in range(nrParticles):
		var b = addBody(ParticleFactory.createParticle(particleType, pSettings))
		b.setParent(self)
		if warmer != null:
			emitter.emitFrom(b, warmer)
		else:
			emitter.fillPool(b)
	EMITTER_COMMAND.setEmitter(emitter)


func setTexture(tex):
	texture = ImageHandler.addPermanentlyLoadNow(Values.ParticleSystemsImages + tex)


func setPos(p):
	super.setPos(p)
	var emitterPos = emitter.getPosition()
	emitterPos.x = p[Values.X]
	emitterPos.y = -p[Values.Y]


func getPos():
	return pos


func getPosition():
	return position


func getY():
	return -(emitter.getPosition().y + 56)


## Java: update(float elapsedTime) (milliseconds). The particles fade per
## update but move per second, so the port steps them as the original's real
## frame rate did (Values.originalFrameStep). Stepping every 60 FPS frame made
## the smoke rise a third as high, as a bright clump.
func update(f, player = null, reset = null):
	var elapsedTime: float = f
	if active:
		if elapsedTime < 5 * Values.LOGIC_INTERVAL:
			stepTime += elapsedTime
			var dt: float = Values.originalFrameStep(stepTime)
			if dt > 0:
				stepTime -= dt
				step(dt / 1000.0)
	elif activateStatus != -1:
		if Database.getStatusFor(getName()) == activateStatus:
			active = true


## The body of Java's update, for one step of elapsedTime seconds.
func step(elapsedTime):
	enqueue(cq, elapsedTime)
	cq.run(getBodies(), elapsedTime)

	var b = getBodies()
	var tempBody
	var it = b.iterator()
	var index: int = 0
	while it.hasNext():
		tempBody = it.next()
		if tempBody.isDead():
			emitter.postEmit(tempBody)
		index += 1


func drawSprite(g, x, y):
	drawIt(g, x, y)


## Java overloads: draw(Graphics g, int x, int y) and the inherited
## draw(Graphics g) (x == null).
func draw(g, x = null, y = null):
	if x == null:
		super.draw(g)
		return
	var pos = getPosition()
	pos.x = x
	pos.y = -y
	drawIt(g, x, y)


func drawIt(g, x, y):
	if active:
		if not inited:
			init(g)
			inited = true
		if background != null:
			g.drawImage(background, x + backx, y + backy)
		g.beginBlend(false)
		g.setBlendFunc(Graphics.GL_ONE if additiveBlending else Graphics.GL_ONE_MINUS_SRC_ALPHA)
		tex.bind(g)
		g.beginQuads()
		var b = getBodies()
		var it = b.iterator()
		while it.hasNext():
			var body = it.next()
			if body.isAlive():
				body.draw(g, tex, position)
		g.end()
		g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
		g.setAlphaFunc(0.1)
		g.setColor(1)


## Bridge (phase 1 step B, docs/ARCHITECTURE.md): draw(g, x, y) without
## drawing, for a scene that draws the system (LegacyParticles2D): sets the
## position as draw does and returns place_particles(x, y).
func place_view(x, y):
	var pos = getPosition()
	pos.x = x
	pos.y = -y
	return place_particles(x, y)


## Bridge (phase 1 step B): drawSprite(g, x, y) (a story actor's draw)
## without drawing: place_particles(x, y).
func place_sprite(x, y):
	return place_particles(x, y)


## Bridge (phase 1 step B): drawIt(g, x, y) without drawing: initializes the
## texture as drawIt does and returns what it would draw, for
## LegacyParticles2D.show_systems: "texture", "additive", "corners" and
## "colors" (four corners per particle, screen pixels, in drawi's vertex
## order), and "image" / "image_at" for the background image. Empty when the
## system is inactive (drawIt draws nothing).
func place_particles(x, y) -> Dictionary:
	if not active:
		return {}
	if not inited:
		init()
		inited = true
	var corners := PackedVector2Array()
	var colors := PackedColorArray()
	var b = getBodies()
	var it = b.iterator()
	while it.hasNext():
		var body = it.next()
		if body.isAlive():
			var quad: Array = body.place_quad(tex, position)
			for i in 4:
				corners.append(quad[i])
				colors.append(quad[4])
	var view := {"texture": tex.getGodotTexture(), "additive": additiveBlending,
		"corners": corners, "colors": colors}
	if background != null:
		view["image"] = ImageHandler.getTexture(background).getGodotTexture()
		view["image_at"] = Vector2i(x + backx, y + backy)
	return view


func init(g = null):
	tex = ImageHandler.getTexture(texture)


func enqueue(cq, elapsedTime):
	cq.enqueue(UPDATE_COMMAND)
	var bs = getBodies()
	if bs.size() > 0 and bs.iterator().next() is SmokeParticle:
		cq.enqueue(windCommand)
	# cq.enqueue(DRAG_COMMAND)
	cq.enqueue(GRAVITY_COMMAND)
	cq.enqueue(EMITTER_COMMAND)


func getCommandQueue():
	return cq


func setEmitter(emitter):
	self.emitter = emitter


func setAdditiveBlending(add):
	additiveBlending = add


static func setWind(windForce, turbulence):
	windCommand.setForce(windForce)
	windCommand.setTurbulence(turbulence)


## Java: update(Values.LOGIC_INTERVAL) warmUp times; here one step each.
func warmUp():
	for i in range(warmUp_):
		self.update(Values.ORIGINAL_FRAME_MS)


func getWarmUp():
	return warmUp_


func setWarmUp(warm):
	warmUp_ = warm


func setActive(activate):
	active = activate


func setActivateStatus(status):
	activateStatus = status


func getEmitter():
	return emitter
