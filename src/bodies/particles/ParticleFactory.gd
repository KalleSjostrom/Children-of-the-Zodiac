class_name ParticleFactory
extends RefCounted
## Port of bodies.particles.ParticleFactory.

const FIRE_PARTICLE = 0
const SMOKE_PARTICLE = 1
const RAINBOW_PARTICLE = 3
const SNOW_PARTICLE = 5
const STAR_PARTICLE = 8


static func createParticle(type, settings):
	var b = null
	match int(type):
		FIRE_PARTICLE:
			b = FireParticle.new(settings)
		SMOKE_PARTICLE:
			b = SmokeParticle.new(settings)
		SNOW_PARTICLE:
			b = BodiesSnowParticle.new(settings)
		STAR_PARTICLE:
			b = StarParticle.new(settings)
		RAINBOW_PARTICLE:
			b = RainbowParticle.new(settings)
		_:
			pass
	return b
