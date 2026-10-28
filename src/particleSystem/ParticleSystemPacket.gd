class_name ParticleSystemPacket
extends RefCounted
## Port of particleSystem.ParticleSystemPacket: a group of particle systems
## with individual start delays (ms).

var systems = []
var delays = {}
var answerdAlready: bool = false
var added: bool = false
var useStartStop: bool = false
# Not in Java: milliseconds not yet simulated (see update).
var stepTime: float = 0.0

## Java overloads: ParticleSystemPacket() [= true] and (boolean useStartStop).
func _init(p_useStartStop = null) -> void:
	useStartStop = true if p_useStartStop == null else bool(p_useStartStop)

## Java overloads:
##   add(ParticleSystem system, int delay)
##   add(int i, ParticleSystem system, int delay)
##   boolean add()  [marks the packet as added, returns true]
func add(i = null, system = null, delay = null):
	if i == null:
		added = true
		return added
	if delay == null:
		# add(system, delay)
		systems.append(i)
		delays[i] = int(system)
	else:
		systems.insert(int(i), system)
		delays[system] = int(delay)

func draw(g):
	# TODO (original): called when systems.size() == 0...
	if systems.size() > 0: # Shouldn't be needed.
		if useStartStop:
			systems[0].start(g)
		for ps in systems:
			var delay: int = delays[ps]
			if delay <= 0:
				ps.draw(g)
		if useStartStop:
			systems[systems.size() - 1].end(g)

## elaspsedTime in seconds (delays are in ms). The particles fade per update
## but move per second, so the port steps the systems as the original's real
## frame rate did (Values.originalFrameStep).
func update(elaspsedTime):
	# Bridge (the battle effects phase): the GPU systems run for the game time
	# of every frame (ParticleSystem.gpu_elapsed), not in the legacy steps.
	for ps in systems:
		if ps.gpu and delays[ps] <= 0:
			ps.gpu_elapsed += elaspsedTime
			ps.gpu_age += elaspsedTime
	stepTime += elaspsedTime * 1000
	var dt: float = Values.originalFrameStep(stepTime)
	if dt == 0:
		return
	stepTime -= dt
	var step: float = dt / 1000.0
	for ps in systems:
		var delay: int = delays[ps]
		if delay <= 0:
			ps.update(step)
		else:
			delays[ps] = int(delay - step * 1000)

func isDestroyed():
	var destroyed: bool = true
	var i: int = 0
	while i < systems.size() and destroyed:
		destroyed = systems[i].isDestroyed()
		i += 1
	return destroyed

func isDead():
	var dead: bool = true
	var i: int = 0
	while i < systems.size() and dead:
		dead = systems[i].isDead()
		i += 1
	return dead

func isReady():
	if answerdAlready:
		return false
	var ready: bool = true
	var i: int = 0
	while i < systems.size() and ready:
		ready = systems[i].isReady()
		i += 1
	if ready:
		answerdAlready = true
	return ready

func getColor():
	return systems[0].getColor()

func isAdded():
	return added
