class_name AbstractEmitter
extends Body
## Port of bodies.emitter.AbstractEmitter: emits bodies from an emitter shape
## at a given time step.
##
## emitFrom merges three Java methods (dispatch on the arguments):
##  - emitFrom()                              -> abstract, true when the pool is empty
##  - emitFrom(Stack<Body> pool, Body master) (pool is an Array)
##  - emitFrom(Body b, EmitterShape warmer)   (pool is a Body)

var emitTimeStep: float = 2.0
var time: float = 0.0
var shape = null
var swiftness: float = 0.0
var speed: float = 0.0
var fade: bool = false
var increase: bool = false
var cutoff: float = 0.0


func _init(settings = null, shape = null) -> void:
	if settings == null:
		return
	setForce(settings.getVector(EmitterSettings.FORCE))
	emitTimeStep = SystemLoader.getValueFromInterval(
		settings.getString(EmitterSettings.EMITTANCE_TIME_STEP))
	self.shape = shape


## Java: update(float elapsedTime) (seconds, called by EmitterUpdateCommand).
func update(elapsedTime, body = null):
	time += elapsedTime
	var empty: bool = false
	while not empty and time >= emitTimeStep:
		empty = emitFrom()
		time -= emitTimeStep
		if fade:
			emitTimeStep += (1 if increase else -1) * pow(emitTimeStep * speed, swiftness)
			fade = (emitTimeStep < cutoff) if increase else (emitTimeStep > cutoff)
			if not fade:
				emitTimeStep = J.FLOAT_MAX


## Bridge (particles phase, docs/ARCHITECTURE.md section 9): update without
## bodies, for a system a VillageParticles2D draws: the emission clock and
## the fade (setFade) go on as if every emission found a body; the GPU
## system follows emitTimeStep.
func advance(elapsedTime):
	time += elapsedTime
	while emitTimeStep > 0 and time >= emitTimeStep:
		time -= emitTimeStep
		if fade:
			emitTimeStep += (1 if increase else -1) * pow(emitTimeStep * speed, swiftness)
			fade = (emitTimeStep < cutoff) if increase else (emitTimeStep > cutoff)
			if not fade:
				emitTimeStep = J.FLOAT_MAX


func setFade(fade, speed, swiftness, increase, cutoff):
	self.fade = fade
	self.speed = speed
	self.swiftness = swiftness
	self.increase = increase
	self.cutoff = cutoff


func getPosition():
	return shape.getPosition()


func emitFrom(pool = null, master = null):
	if pool == null:
		# Abstract emitFrom(): implemented by the subclasses.
		return true
	if pool is Array:
		if pool.size() > 0:
			var b = pool.pop_back()
			b.dequeueForEmittance()
			var pos = null
			var vel
			if master != null:
				pos = master.getPosition()
				vel = master.getVelocity().mult(0.5)
			else:
				pos = shape.getEmittancePos()
				vel = Vector3f.new()
			emit(b, pos, vel)
		return
	# emitFrom(Body b, EmitterShape warmer)
	emit(pool, master.getEmittancePos(), Vector3f.new())


func getShape():
	return shape


func emit(b, emitPosition, vel):
	b.reset()
	b.setVelocity(vel.clone())
	b.setPosition(emitPosition)
	var magnitude: float = getForce().length()
	var direction = getShape().modifyDirection(getForce().normalize())
	direction.normalizeLocal()
	direction.multLocal(magnitude)
	b.addForce(direction)
	b.setEmitPosition(emitPosition.clone())


func postEmit(b):
	pass


func fillPool(b):
	pass
