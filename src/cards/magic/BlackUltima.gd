class_name BlackUltima
extends Card
## Port of cards.magic.BlackUltima: the enemy version of Ultima.

static var SHORT_INFO = ["Powerful magic", ""]
static var SOUNDS = [
		SoundMap.MAGICS_ULTIMA, SoundMap.MAGICS_ULTIMA, SoundMap.MAGICS_ULTIMA,
		SoundMap.MAGICS_ULTIMA, SoundMap.MAGICS_ULTIMA]
static var DELAYS = [295, 200, 200, 200, 200]


func getSimpleName():
	return "Ultima"


func use(target, attacker):
	return attack(target, attacker)


func createAttackPercent():
	return STANDARD_ATTACK_LV4


func createTextInfo():
	return [
			"The forces of the universe gathers around the wielder of this card",
			"as the power of Ultima is released. This supreme power know no",
			"bounds and will surely disintegrate even the strongest of fiends."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func getAnimation(info):
	return BlackUltima.getStaticAnimation(info)


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	var target
	var source
	if info.isOnEnemy():
		target = Vector3f.new(0.0, 0.0, -6.0)
		source = Vector3f.new((J.random() - 0.5) * 2, -0.5, 0.0)
	else:
		source = info.getEnemy().getTempSource()
		source = Vector3f.new(0.0, 0.0, -7.0) if source == null else source
		target = Vector3f.new(0.0, -0.5, 0.0)
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z)
	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE)
	settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_ONCE)
	settings.setValue(AnimSettings.SIZE, 0.1)
	settings.setValue(AnimSettings.SIZE_RANDOM_MULT, 0.3)
	settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0)
	settings.setValue(AnimSettings.SPEED, 5)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.3, 0.3, 0.3))
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)
	settings.setVector(AnimSettings.SOURCE, source)
	settings.setValue(AnimSettings.NR_PARTICLES, 250)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.1)
	# Note (as in Java): the interpolation info is calculated with the default
	# target, since TARGET is only set after this call.
	var info1 = ParticleSystem.calcInterpolationInfo(settings)

	settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_BLACK)
	var amlifier: float = 0.8
	var wave1 = UpDownSideWave.new(1.0, amlifier, 0.0, info1, false)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1)
	settings.setVector(AnimSettings.TARGET, randomTarget(target))
	psp.add(ParticleSystem.new(settings), 0)

	wave1 = UpDownSideWave.new(1.0, amlifier, 0.0, info1, true)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1)
	settings.setVector(AnimSettings.TARGET, randomTarget(target))
	psp.add(ParticleSystem.new(settings), 200)

	wave1 = UpDownSideWave.new(1.0, amlifier, PI, info1, false)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1)
	settings.setVector(AnimSettings.TARGET, randomTarget(target))
	psp.add(ParticleSystem.new(settings), 400)

	wave1 = UpDownSideWave.new(1.0, amlifier, PI, info1, true)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1)
	settings.setVector(AnimSettings.TARGET, randomTarget(target))
	psp.add(ParticleSystem.new(settings), 600)

	wave1 = UpDownSideWave.new(1.0, amlifier, 0.0, info1, true)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, wave1)
	settings.setVector(AnimSettings.TARGET, randomTarget(target))
	psp.add(ParticleSystem.new(settings), 800)
	return psp


## As in Java: returns a copy of t and then randomizes t itself (so each
## call returns the target randomized by the previous call).
static func randomTarget(t):
	var newtarget = Vector3f.new(t)
	t.y = J.random() - 0.5
	t.x = J.random() - 0.5
	return newtarget
