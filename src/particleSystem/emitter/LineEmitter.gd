class_name LineEmitter
extends Emitter
## Port of particleSystem.emitter.LineEmitter.

func _init(p_particlePool = null, p_particles = null, p_info = null, p_emitTimeStep = null, p_limit = null) -> void:
	super(p_particlePool, p_particles, p_info, p_emitTimeStep, p_limit)

func update(system, elapsedTime):
	if not isDestroyed():
		addTime(elapsedTime)
		var empty: bool = false
		var nrToEmit: float = getTime() / getEmitTimeStep()
		var timePerPart: float = elapsedTime / nrToEmit
		while not empty and getTime() >= getEmitTimeStep():
			if okToEmit():
				var p = getParticle(system)
				var pos = getInfo().useVectorEquationFromSource()
				p.resurrect(null, pos)
				getParticles().append(p)
				addTimeCounter(timePerPart)
			empty = not okToEmit()
			addTime(-minf(elapsedTime, getEmitTimeStep()))
