class_name BodiesParticleSystem
extends BodySystem
## Port of bodies.system.ParticleSystem (GDScript class BodiesParticleSystem):
## a system of particles emitted by an emitter and updated by commands.
##
## Bridge (particles phase, docs/ARCHITECTURE.md section 9): a
## VillageParticles2D draws the system; it builds no bodies and runs no
## simulation. The legacy simulation and drawing (--legacy=particles: the
## bodies, step and its command queue, draw, drawIt and the quads of
## place_particles) are removed (closing the particles phase, plan 6.10); the
## particle classes (ParticleFactory) keep the laws the GPU systems run, which
## tools/import/particles_to_scenes.gd samples.

var emitter = null
var additiveBlending: bool = false
var active: bool = true
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
## Bridge (particles phase): the game time (ms) the system was updated for
## since the last draw, the warm-up (s) its build ran, the random seed of its
## GPU system, the name of its definition in particleSystems.info and its
## particle kind (ParticleFactory).
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
	# Bridge: no bodies (the GPU system has the particles).
	gpu_seed = rand.nextInt(J.INT_MAX)


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


## Java: update(float elapsedTime) (milliseconds): the GPU system runs for
## that time (gpu_run). The particles fade per update but move per second,
## so the GPU systems run the laws as the original's real frame rate stepped
## them (Values.originalFrameStep).
func update(f, player = null, reset = null):
	var elapsedTime: float = f
	if active:
		if elapsedTime < 5 * Values.LOGIC_INTERVAL:
			gpu_run(elapsedTime)
	elif activateStatus != -1:
		if Database.getStatusFor(getName()) == activateStatus:
			active = true


## Bridge (particles phase): what the legacy update's step did, for
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


## Bridge (phase 1 step B, docs/ARCHITECTURE.md): the legacy draw(g, x, y)
## without drawing, for a scene that draws the system (LegacyParticles2D):
## sets the position as draw did and returns place_particles(x, y).
func place_view(x, y):
	var pos = getPosition()
	pos.x = x
	pos.y = -y
	return place_particles(x, y)


## Bridge (phase 1 step B): the legacy drawSprite(g, x, y) (a story actor's
## draw) without drawing: place_particles(x, y).
func place_sprite(x, y):
	return place_particles(x, y)


## Bridge (phase 1 step B): the legacy drawIt(g, x, y) without drawing, for
## LegacyParticles2D.show_systems: the state of the system (gpu_view), or
## empty when the system is inactive (drawIt drew nothing).
func place_particles(x, y) -> Dictionary:
	if not active:
		return {}
	return gpu_view()


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


func setEmitter(emitter):
	self.emitter = emitter


func setAdditiveBlending(add):
	additiveBlending = add


static func setWind(windForce, turbulence):
	windCommand.setForce(windForce)
	windCommand.setTurbulence(turbulence)


## Java: update(Values.LOGIC_INTERVAL) warmUp times: gpu_warm for that time
## (one original frame each).
func warmUp():
	gpu_warm(warmUp_ * Values.ORIGINAL_FRAME_MS / 1000.0)


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
