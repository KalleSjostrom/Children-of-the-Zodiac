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
## Not in Java (which uses Math.random): the random numbers of the village and
## cutscene particles (bodies, commands, SystemLoader's intervals), apart from
## J's shared generator, so that a seeded run's other draws do not depend on
## how much the particles draw. Main seeds it in deterministic runs.
static var rand := JRandom.new()
var zeroTime: int = 0
# Not in Java: milliseconds not yet simulated (see update).
var stepTime: float = 0.0
## Bridge (particles phase, docs/ARCHITECTURE.md section 9): true when a
## VillageParticles2D draws this system (gpu_path()): it builds no bodies and
## runs no simulation. Then: the game time (ms) it was updated for since the
## last draw, the warm-up (s) its build ran, the random seed of its GPU
## system, the name of its definition in particleSystems.info and its
## particle kind (ParticleFactory).
var gpu: bool = false
var gpu_elapsed: float = 0.0
var gpu_warm_up: float = 0.0
var gpu_seed: int = 0
var definition: String = ""
var particle_kind: int = -1


## Java: ParticleSystem(SystemSettings settings, ParticleSettings pSettings,
## AbstractEmitter emitter, EmitterShape warmer).
func _init(settings = null, pSettings = null, emitter = null, warmer = null) -> void:
	super()
	var particleType: int = int(pSettings.getValue(ParticleSettings.KIND))
	var nrParticles: int = 0
	particle_kind = particleType
	gpu = gpu_path()
	if settings != null:
		definition = str(settings.getName())
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

	if gpu:
		# Bridge: no bodies (the GPU system has the particles).
		gpu_seed = rand.nextInt(J.INT_MAX)
	else:
		for i in range(nrParticles):
			var b = addBody(ParticleFactory.createParticle(particleType, pSettings))
			b.setParent(self)
			if warmer != null:
				emitter.emitFrom(b, warmer)
			else:
				emitter.fillPool(b)
	EMITTER_COMMAND.setEmitter(emitter)


## Bridge (particles phase): whether the village and cutscene systems are
## drawn by VillageParticles2D (the village scenes draw, and
## --legacy=particles is not given) instead of the legacy simulation.
static func gpu_path() -> bool:
	return not Main.is_legacy("particles") and not Main.is_legacy("villages")


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
			if gpu:
				gpu_run(elapsedTime)
				return
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
		# Main.hide_particles (dev): no image and no particles, the same GL state.
		if background != null and not Main.hide_particles:
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
				if Main.hide_particles:
					body.modifySize(body.getSize()) # draw's state change (SmokeParticle)
				else:
					body.draw(g, tex, position)
		g.end()
		g.setBlendFunc(Graphics.GL_ONE_MINUS_SRC_ALPHA)
		g.setAlphaFunc(0.1)
		g.setColor(1)


## Bridge (particles phase): what update's step does on the GPU path, for
## elapsedTime ms: the GPU system runs for that game time (gpu_elapsed, handed
## over at draw time), and what stays legacy goes on: the emitter's clock
## (its fade, AbstractEmitter.advance) and the turbulence of the shared wind
## that a smoke system's step turns (WindCommand.drift).
func gpu_run(elapsedTime: float) -> void:
	gpu_elapsed += elapsedTime
	emitter.advance(elapsedTime / 1000.0)
	if particle_kind == ParticleFactory.SMOKE_PARTICLE:
		windCommand.drift(elapsedTime / 1000.0)


## Bridge (particles phase): a warm-up of seconds on the GPU path: the GPU
## system starts with that much simulated (VillageParticles2D: preprocess);
## the emitter's clock and the wind go on as in gpu_run. Only an active
## system warms up, as update steps only an active one.
func gpu_warm(seconds: float) -> void:
	if not active:
		return
	gpu_warm_up += seconds
	emitter.advance(seconds)
	if particle_kind == ParticleFactory.SMOKE_PARTICLE:
		windCommand.drift(seconds)


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
## system is inactive (drawIt draws nothing). On the GPU path the state of
## the system instead (gpu_view).
func place_particles(x, y) -> Dictionary:
	if not active:
		return {}
	if gpu:
		return gpu_view()
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


## Bridge (particles phase): the state VillageParticles2D.show_state takes
## (see there), handed over where the legacy draw would draw: "gpu",
## "definition", "slave" (a master/slave emitter's slave: its master's
## scene draws it), "elapsed" (ms since the last draw, then reset),
## "warm_up", "seed", "emitter" (the emitter shape's position, y down),
## "position" (what the particles are drawn relative to: the position draw
## sets, zero for stars, which ignore it, and for a cutscene actor, whose
## draw does not set it), "step" (the emitter's time step) and, for smoke,
## "wind" (y up).
func gpu_view() -> Dictionary:
	var ep = emitter.getPosition()
	var offset = Vector3f.ZERO if particle_kind == ParticleFactory.STAR_PARTICLE else position
	var view := {"gpu": true, "definition": definition,
		"slave": emitter is MasterSlaveEmitter and emitter.slave == self,
		"elapsed": gpu_elapsed, "warm_up": gpu_warm_up, "seed": gpu_seed,
		"emitter": Vector2(ep.x, -ep.y), "position": Vector2(offset.x, offset.y),
		"step": emitter.emitTimeStep}
	if particle_kind == ParticleFactory.SMOKE_PARTICLE:
		view["wind"] = Vector2(windCommand.wind.x, windCommand.wind.y)
	gpu_elapsed = 0.0
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


## Java: update(Values.LOGIC_INTERVAL) warmUp times; here one step each (on
## the GPU path, gpu_warm for that time).
func warmUp():
	if gpu:
		gpu_warm(warmUp_ * Values.ORIGINAL_FRAME_MS / 1000.0)
		return
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
