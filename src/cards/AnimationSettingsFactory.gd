class_name AnimationSettingsFactory
extends RefCounted
## Port of cards.AnimationSettingsFactory: creates the default particle
## animation settings used by the cards.

const DEFAULT = 0
const WAVE = 1


static func getDefault():
	var settings := AnimSettings.new()
	settings.setValue(AnimSettings.SIZE, 0.2)
	settings.setValue(AnimSettings.SYSTEM_MASS, 1.0)
	settings.setValue(AnimSettings.MASS_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.SIZE_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.LIFE_MULTIPLIER, 1.0)
	settings.setValue(AnimSettings.PARTICLE_MASS, 0.01)
	settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_LESS_TARGET_Z)
	settings.setValue(AnimSettings.SPEED, 3.0)
	settings.setValue(AnimSettings.NR_PARTICLES, 400.0)
	settings.setValue(AnimSettings.COLOR, Card.FIRE_ELEMENT)
	settings.setVector(AnimSettings.SOURCE, Vector3f.new((J.random() - 0.5) * 2, -1.0, 0.0))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, -0.5, -6.0))
	settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 3.0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.02)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.02)
	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.DEFAULT_EMITTER_TYPE)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.1, 0.1, 0.1))
	settings.setValue(AnimSettings.VELOCITY_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.VELOCITY_RANDOM_ADD, 0.0)
	settings.setBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES, false)
	settings.setValue(AnimSettings.IS_DEAD_LIMIT, 50.0)
	settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DESTROYED)
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.01)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.006)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_POWER, 1.0)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0.05)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, 0.0)
	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, -0.01, 0.0))
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true)

	settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_ONCE)

	settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND)
	return settings


static func getDefaultNoFade():
	var settings = getDefault()
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.0)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0.0)
	return settings


static func getDefaultSword():
	var settings := AnimSettings.new()
	settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DEAD)
	settings.setValue(AnimSettings.SIZE, 0.1)
	settings.setValue(AnimSettings.SYSTEM_MASS, 1.0)
	settings.setValue(AnimSettings.LIFE_MULTIPLIER, 1.0)
	settings.setValue(AnimSettings.PARTICLE_MASS, 0.01)
	settings.setValue(AnimSettings.SPEED, 8.0)
	settings.setValue(AnimSettings.NR_PARTICLES, 1000.0)
	settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_GRAY)
	settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.CHECK_DISTANCE)
	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE)
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(-0.5, 0.5, -4.0))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(0.5, -0.5, -4.0))

	settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 3.0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.2)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.0, 0.0, 0.0))
	settings.setValue(AnimSettings.VELOCITY_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.VELOCITY_RANDOM_ADD, 0.0)
	settings.setBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES, false)
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.08)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_POWER, 1.0)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0.0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.02)
	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, 0.0, 0.0))
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true)
	settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY)
	var sb := SwordBackground.new(
			settings.getVector(AnimSettings.SOURCE), settings.getVector(AnimSettings.TARGET))
	settings.setSystemDrawable(AnimSettings.SYSTEM_DRAWABLE, sb)

	settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND)
	return settings


static func getCircleWave(settings, color, phase):
	settings.setValue(AnimSettings.NR_PARTICLES, 150.0)
	settings.setValue(AnimSettings.COLOR, color)
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.0)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0.0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.15)

	settings.setValue(AnimSettings.NR_TEXTURES, 2.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND)
	settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JITTER_2)

	var wave := CircularWave.new(0.6, 0.5, float(phase), true)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)

	return settings
