class_name Emitter
extends RefCounted
## Port of particleSystem.emitter.Emitter.
## particlePool (Java Stack) and particles (Java ArrayList) are plain Arrays
## shared with the owning ParticleSystem.

var destroyed: bool = false
var time: float = 0.0
var emitTimeStep: float = 0.0
var timeCounter: float = 0.0
var particles = null
var info = null
var particlePool = null
var limit: int = 1000

func _init(p_particlePool = null, p_particles = null, p_info = null, p_emitTimeStep = null, p_limit = null) -> void:
	particlePool = p_particlePool
	particles = p_particles
	info = p_info
	limit = int(p_limit)
	emitTimeStep = float(p_emitTimeStep)

func update(system, elapsedTime):
	if not destroyed:
		time += elapsedTime
		var empty: bool = false
		while not empty and time >= emitTimeStep:
			if okToEmit():
				var p = getParticle(system)
				p.resurrect(system, null)
				particles.append(p)
			empty = not okToEmit()
			time -= emitTimeStep

func getParticle(system):
	var p = null
	if not particlePool.is_empty():
		p = particlePool.pop_back()
	elif particles.size() < limit:
		p = system.createParticle()
	return p

func destroy(enemy):
	destroyed = true

func isDestroyed():
	return destroyed

func getTime():
	return time

func getEmitTimeStep():
	return emitTimeStep

func getTimeCounter():
	return timeCounter

func getParticles():
	return particles

func getInfo():
	return info

func getParticlePool():
	return particlePool

func addTime(elapsedTime):
	time += elapsedTime

func addTimeCounter(t):
	timeCounter += t

func okToEmit():
	return not particlePool.is_empty() or particles.size() < limit
