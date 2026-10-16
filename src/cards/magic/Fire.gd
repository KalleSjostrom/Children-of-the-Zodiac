class_name Fire
extends Magic
## Port of cards.magic.Fire.
##
## This class represents the Fire magic in the game. The Fire magic
## is a basic magic with fire attribute.

static var SHORT_INFO = ["Fire magic", ""]
static var SOUNDS = [SoundMap.MAGICS_FIRE, SoundMap.MAGICS_FIRE, SoundMap.MAGICS_FIRE]
static var DELAYS = [295, 100, 100]


## This method sets the element to fire.
func setElement():
	element = FIRE_ELEMENT


## Creates and returns the textual information of the card. This is the
## three lines of "story" that tells the player about the card.
func createTextInfo():
	return [
			"The firey ball of magic will rush toward the target and disintegrate",
			"upon impact. The hot flames created with supreme magic will melt",
			"even the coldes of barriers leaving but a puddle of water."]


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	info.setLevel(getLevel())
	return Fire.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	settings.setValue(AnimSettings.SPEED, 5.0)

	settings.setValue(AnimSettings.NR_PARTICLES, 200.0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.05)

	var lvl: int = info.getLevel()
	if not info.isOnEnemy():
		var source = info.getEnemy().getTempSource()
		settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, -0.5, -1.1))
		settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, -6.0) if source == null else source)
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z)
		# TODO (original): Only shadow boar should have subtractive coloring.
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true)

		var distance: float = 0.7

		# Java switch with fall through (case 3 -> 2 -> 1).
		if lvl == 3:
			var v = settings.getVector(AnimSettings.TARGET)
			v.x -= distance
			psp.add(ParticleSystem.new(settings), 200)
			v = settings.getVector(AnimSettings.TARGET)
			v.x += distance
		if lvl == 3 or lvl == 2:
			var v = settings.getVector(AnimSettings.TARGET)
			v.x += distance
			psp.add(ParticleSystem.new(settings), 100)
			v = settings.getVector(AnimSettings.TARGET)
			v.x -= distance
		if lvl == 3 or lvl == 2 or lvl == 1:
			psp.add(ParticleSystem.new(settings), 0)
	else:
		var distance: float = 1.0
		Card.setSourceTargetVectorToLength(6.0, settings)

		if lvl == 3:
			var v = settings.getVector(AnimSettings.SOURCE)
			v.x -= distance
			psp.add(ParticleSystem.new(settings), 200)
			v = settings.getVector(AnimSettings.SOURCE)
			v.x += distance
		if lvl == 3 or lvl == 2:
			var v = settings.getVector(AnimSettings.SOURCE)
			v.x += distance
			psp.add(ParticleSystem.new(settings), 100)
			v = settings.getVector(AnimSettings.SOURCE)
			v.x -= distance
		if lvl == 3 or lvl == 2 or lvl == 1:
			psp.add(ParticleSystem.new(settings), 0)
	return psp
