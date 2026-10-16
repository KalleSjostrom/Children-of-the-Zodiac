class_name Tornado
extends PowerMagic
## Port of cards.magic.Tornado: the powerful version of the wind magic.

static var SHORT_INFO = ["Powerful wind magic", ""]
static var SOUNDS = [SoundMap.MAGICS_TORNADO]
static var DELAYS = [0]


func setElement():
	element = WIND_ELEMENT


func createTextInfo():
	return [
			"Gemini, Libra and Aquarius forged their immense power into",
			"this card. When this power is set free, the tornado will blow away",
			"even foes that stand fast, especially those hiding behind earth."]


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return Tornado.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	settings.setValue(AnimSettings.SIZE, 0.18)
	settings.setValue(AnimSettings.SPEED, 2.0)
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, -2.0, -6.0))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, 3.0, -6.0))
	var period: float = 0.225
	var radius: float = 0.25
	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE)
	settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Y_GREATER_TARGET_Y)
	settings.setValue(AnimSettings.COLOR, WIND_ELEMENT)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.04)
	settings.setValue(AnimSettings.NR_TEXTURES, 1)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND)
	var source = settings.getVector(AnimSettings.SOURCE)
	settings.setVector(AnimSettings.GRAVITY, Vector3f.new(0.0, 0.002, 0.0))
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.03)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.01)
	settings.setValue(AnimSettings.NR_PARTICLES, 1500)
	var total: float = ParticleSystem.calcTotalTime(settings)
	var wave = WhirlWind.new(period, radius, 0.0, source, true, total)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(ParticleSystem.new(settings), 0)
	wave = WhirlWind.new(period, radius, PI, source, true, total)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(ParticleSystem.new(settings), 0)

	period = 0.225 * 3
	radius = 0.2
	settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_WHITE)
	settings.setValue(AnimSettings.SIZE, 0.07)
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.03)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.01)
	settings.setValue(AnimSettings.NR_PARTICLES, 25)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 3.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.STONE)
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)
	settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY)
	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, -0.05, 0.0))
	total = ParticleSystem.calcTotalTime(settings)
	wave = WhirlWind.new(period, radius, 0.0, source, true, total)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(0, ParticleSystem.new(settings), 0)
	wave = WhirlWind.new(period, radius, PI / 2, source, true, total)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(0, ParticleSystem.new(settings), 0)
	wave = WhirlWind.new(period, radius, PI, source, true, total)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(0, ParticleSystem.new(settings), 0)
	wave = WhirlWind.new(period, radius, (3 * PI) / 2, source, true, total)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
	psp.add(0, ParticleSystem.new(settings, info.getEnemy()), 0)
	return psp
