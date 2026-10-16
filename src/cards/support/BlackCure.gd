class_name BlackCure
extends SupportCard
## Port of cards.support.BlackCure.
##
## The enemy version of the Cure card (its image and name are the ones of
## Cure); the animation uses black particles.

static var SHORT_INFO = ["Cures hp", ""]
static var SOUNDS = [SoundMap.MAGICS_CURE]
static var DELAYS = [0]


func getSimpleName():
	return "Cure"


## The given target is not used; the cured hp is calculated by the
## animator in battle.
func use(target, attacker):
	return cure(attacker)


func createAttackPercent():
	return STANDARD_SUPORT


func createTextInfo():
	return [
		"The ancient tenjins learned the secret of the curing potion back",
		"in the days of peace and harmony. When using this now, however,",
		"one must put a lot of supporting power for it to be of great use."]


func createShortInfo():
	setShortInfo("Support power: " + str(J.round(getAttackPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return BlackCure.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()

	settings.setValue(AnimSettings.READY_MODE, float(ParticleSystem.IS_DEAD))
	var x: float = -0.4
	var y: float = -0.6
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(x, y, -2.0))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, y + 2, -2.0))
	var l := Line.new(settings.getVector(AnimSettings.SOURCE), 0.8)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, l)
	addToSystemPacket(psp, settings)
	return psp


static func addTargetToSettings(target, settings):
	var x: float = BattleValues.getCharPosXForSupport(target) - 0.03
	var y: float = BattleValues.CHARACTER_POS_Y - 0.05
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(x, y, -2.0))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, y + 1, -2.0))
	var l := Line.new(settings.getVector(AnimSettings.SOURCE), 0.45)
	settings.setVectorEquation(AnimSettings.POSITION_VECTOR_EQUATION, l)


static func addToSystemPacket(psp, settings):
	settings.setValue(AnimSettings.MASS_RANDOM_MULT, 0.1)
	settings.setValue(AnimSettings.SPEED, 1.5)
	settings.setValue(AnimSettings.COLOR, float(ParticleValues.COLOR_BLACK))
	settings.setValue(AnimSettings.CHECK_DESTROY_MODE, float(ParticleSystem.POS_Y_GREATER_TARGET_Y))
	settings.setValue(AnimSettings.DESTROY_MODE, float(ParticleValues.PLAIN_DESTROY))
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.01)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.01)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0.0)

	settings.setVector(AnimSettings.GRAVITY, Vector3f.new(0.0, 0.02, 0.0))
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.02)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.02)
	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, 0.02, 0.0))
	settings.setValue(AnimSettings.SIZE, 0.1)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.0, 0.0, 0.0))
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)

	settings.setValue(AnimSettings.EMITTER_TYPE, float(ParticleSystem.LINE_EMITTER_TYPE))

	settings.setValue(AnimSettings.NR_PARTICLES, 250.0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.12)

	settings.setValue(AnimSettings.NR_TEXTURES, 3.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, float(ParticleSystem.JITTER_4))
	settings.setValue(AnimSettings.NR_TEXTURES + 2, float(ParticleSystem.JITTER_2_45))
	settings.setValue(AnimSettings.NR_TEXTURES + 3, float(ParticleSystem.JITTER_4_45))

	psp.add(ParticleSystem.new(settings), 0)
