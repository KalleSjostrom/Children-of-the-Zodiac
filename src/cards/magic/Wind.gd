class_name Wind
extends Magic
## Port of cards.magic.Wind.
##
## This class represents the Wind magic in the game. The Wind magic
## is a basic magic with wind attribute.

static var SHORT_INFO = ["Wind magic", ""]
static var SOUNDS = [SoundMap.MAGICS_WIND, SoundMap.MAGICS_WIND, SoundMap.MAGICS_WIND]
static var DELAYS = [500, 200, 200]


## This method sets the element to wind.
func setElement():
	element = WIND_ELEMENT


## Creates and returns the textual information of the card.
func createTextInfo():
	return [
			"Even a slow breeze will turn into a full-blown gale when releasing the power",
			"of this card. Wind is one of natures most mighty forces, ",
			"which could deal immense damage to defenses made of earth."]


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	info.setLevel(getLevel())
	return Wind.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var def = AnimationSettingsFactory.getDefault()
	var ds = def.getVector(AnimSettings.SOURCE)
	ds.z = 0.0
	def.setValue(AnimSettings.SIZE, 0.13)
	def.setValue(AnimSettings.SPEED, 15.0)
	if info.isOnEnemy():
		var dt = def.getVector(AnimSettings.TARGET)
		dt.z = -14.0
		ds = def.getVector(AnimSettings.SOURCE)
		ds.y = -1.7
	else:
		var source = info.getEnemy().getTempSource()
		def.setVector(AnimSettings.TARGET, Vector3f.new(0.0, -0.5, 0.0))
		def.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, -7.0) if source == null else source)
		def.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z)
	var period: float = 0.225 * 3
	var radius: float = 0.25

	var color: int = WIND_ELEMENT

	var settings = AnimationSettingsFactory.getCircleWave(def, color, 0.0)

	Card.setSourceTargetVectorToLength(14.0, settings)

	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE)
	settings.setVector(AnimSettings.GRAVITY, Vector3f.new(0.0, 0.001, 0.0))
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.03)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.01)
	settings.setValue(AnimSettings.NR_PARTICLES, 600.0)

	# Four waves with the phases 0, PI / 2, PI and 3 PI / 2 (the original
	# repeated the same block four times, setting the color for all but the
	# first one).
	var phases: Array = [0.0, PI / 2, PI, 3 * PI / 2.0]
	for k in range(4):
		var wave := CircularWave.new(period, radius, phases[k], false)
		if k > 0:
			settings.setValue(AnimSettings.COLOR, color)
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
		settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND)
		psp.add(ParticleSystem.new(settings), 0)
	if info.getLevel() == 1:
		return psp

	radius = 0.5
	settings.setValue(AnimSettings.NR_PARTICLES, 1000.0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.07)

	for k in range(4):
		var wave := CircularWave.new(period, radius, phases[k], true)
		if k > 0:
			settings.setValue(AnimSettings.COLOR, color)
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
		settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND)
		psp.add(ParticleSystem.new(settings), 200)

	if info.getLevel() == 2:
		return psp

	radius = 0.75
	settings.setValue(AnimSettings.NR_PARTICLES, 1500.0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.03)

	for k in range(4):
		var wave := CircularWave.new(period, radius, phases[k], false)
		if k > 0:
			settings.setValue(AnimSettings.COLOR, color)
		settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave)
		settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
		settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.ROUND)
		psp.add(ParticleSystem.new(settings), 400)

	return psp
