class_name Colliding
extends PowerMagic
## Port of cards.magic.Colliding: the powerful version of the earth magic.

static var SHORT_INFO = ["Powerful earth magic", ""]
static var SOUNDS = [SoundMap.MAGICS_COLLIDING]
static var DELAYS = [200]


func setElement():
	element = EARTH_ELEMENT


func createTextInfo():
	return [
			"Tremling earth is called forth by Taurus, Virgo and Capricorn.",
			"The earth will rapture and the foes that stand in the way will",
			"gasp for air as they are swallowed whole by the raging quake."]


func getVeryShortInfo():
	return SHORT_INFO


func getAnimation(info):
	return Colliding.getStaticAnimation(info)


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.05)
	var size: float = 1.2
	settings.setValue(AnimSettings.SPEED, 7)
	settings.setValue(AnimSettings.SIZE, 0.4 * size)
	settings.setValue(AnimSettings.NR_PARTICLES, 150)
	settings.setValue(AnimSettings.PARTICLE_MASS, 0.1)
	var temp = Vector3f.new(0.3, 0.3, 0.3).multLocal(size)
	settings.setVector(AnimSettings.POSITION_NOISE, temp)
	settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 14)
	# RESET VELOCITY ON IMPACT
	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, -0.1, 0.0))
	settings.setValue(AnimSettings.COLOR, EARTH_ELEMENT)
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)
	settings.setValue(AnimSettings.NR_TEXTURES, 3)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.JONAS_ROUND)
	settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JONAS_ROUND_2)
	settings.setValue(AnimSettings.NR_TEXTURES + 3, ParticleSystem.ROUND)
	settings.setValue(AnimSettings.NR_TEXTURES + 4, ParticleSystem.SHARP)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0)
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0)
	settings.setBoolean(AnimSettings.SET_VELOCITY_ON_PARTICLES, true)
	settings.setValue(AnimSettings.VELOCITY_RANDOM_MULT, 0)
	settings.setValue(AnimSettings.VELOCITY_RANDOM_ADD, 1)
	settings.setValue(AnimSettings.LIFE_MULTIPLIER, 0.18)
	settings.setBoolean(AnimSettings.DESTROY_CAMERA_SHAKE, true)
	settings.setBoolean(AnimSettings.DESTROY_ENEMY_SHAKE, true)

	settings.setVector(AnimSettings.SOURCE, Vector3f.new(-4.0, 3.0, -5.9))
	psp.add(ParticleSystem.new(settings), 0)
	settings.getVector(AnimSettings.SOURCE).x = 4.0
	psp.add(ParticleSystem.new(settings), 0)

	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true)
	settings.setValue(AnimSettings.SIZE, 0.3 * size)
	settings.setValue(AnimSettings.NR_PARTICLES, 100)
	settings.setVector(AnimSettings.POSITION_NOISE,
			Vector3f.new(0.55, 0.55, 0.55).multLocal(size))
	settings.getVector(AnimSettings.SOURCE).x = -4.0
	psp.add(ParticleSystem.new(settings, info.getEnemy()), 0)
	settings.getVector(AnimSettings.SOURCE).x = 4.0
	psp.add(ParticleSystem.new(settings, info.getEnemy()), 0)
	return psp
