class_name DemolishEmitter
extends Emitter
## Port of particleSystem.emitter.DemolishEmitter.

var initiated: bool = false

func _init(p_particlePool = null, p_particles = null, p_info = null, p_emitTimeStep = null, p_limit = null) -> void:
	super(p_particlePool, p_particles, p_info, p_emitTimeStep, p_limit)

func update(system, elapsedTime):
	if not initiated:
		for p in getParticles():
			p.resurrect(system, null)
		initiated = true
	if not isDestroyed():
		addTime(elapsedTime)
		for p in getParticles():
			var partpos = p.getPosition()
			var pos = getInfo().interpolate(system.getPosition().clone(), getTime())
			pos.z = partpos.z
			p.setPosition(pos)

func destroy(enemy):
	if not isDestroyed() and enemy != null:
		enemy.setScale()
	super.destroy(enemy)
