class_name FlareEmitter
extends Emitter
## Port of particleSystem.emitter.FlareEmitter.

var time_: float = 0.0
var limit_: float = 0.7

func _init(p_particlePool = null, p_particles = null, p_info = null, p_emitTimeStep = null, p_limit = null) -> void:
	super(p_particlePool, p_particles, p_info, p_emitTimeStep, p_limit)
	p_particlePool.append_array(p_particles)
	p_particles.clear()
	for i in range(400):
		var p = p_particlePool.pop_back()
		p_particles.append(p)
		var v = ParticleSystem.getRandomCircleVector(4.0)
		var s = p_info.getSource()
		v.z = s.z
		p.resurrect(null, v, 0)

func destroy(enemy):
	super.destroy(enemy)
	getParticles().append_array(getParticlePool())

func update(system, elapsedTime):
	if not isDestroyed():
		time_ += elapsedTime
		if time_ > limit_:
			var parts = getParticles()
			for i in range(400):
				var p = parts[i]
				var pos = p.getPosition().clone()
				pos.z = 0.0
				var vec = pos.normalizeLocal().mult(-0.03)
				vec.z = pos.z
				p.setForce(vec)
