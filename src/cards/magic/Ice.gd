class_name Ice
extends Magic
## Port of cards.magic.Ice.
##
## This class represents the Ice magic in the game. The Ice magic
## is a basic magic with ice attribute.

static var SHORT_INFO = ["Ice magic", ""]
static var SOUNDS = [SoundMap.MAGICS_ICE, SoundMap.MAGICS_ICE, SoundMap.MAGICS_ICE]
static var DELAYS = [295, 200, 200]


## This method sets the element to ice.
func setElement():
	element = ICE_ELEMENT


## Creates and returns the textual information of the card.
func createTextInfo():
	return [
			"A violent frost is not enough to describe the icy coldness of this",
			"magic card. This artic magic will freeze the target upon collision",
			"destroying, with ease, a firey defense."]


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	info.setLevel(getLevel())
	return Ice.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()

	if not info.isOnEnemy():
		var source = info.getEnemy().getTempSource()
		settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, -0.5, -1.1))
		settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, -6.0) if source == null else source)
		settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z)

	settings.setValue(AnimSettings.SPEED, 5.0)
	settings.setValue(AnimSettings.COLOR, ICE_ELEMENT)

	settings.setValue(AnimSettings.NR_PARTICLES, 200.0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.1)

	settings.setValue(AnimSettings.NR_TEXTURES, 7.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.JITTER_1)
	settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.JITTER_2)
	settings.setValue(AnimSettings.NR_TEXTURES + 3, ParticleSystem.JITTER_3)
	settings.setValue(AnimSettings.NR_TEXTURES + 4, ParticleSystem.JITTER_4)
	settings.setValue(AnimSettings.NR_TEXTURES + 5, ParticleSystem.JITTER_2_45)
	settings.setValue(AnimSettings.NR_TEXTURES + 6, ParticleSystem.JITTER_3_45)
	settings.setValue(AnimSettings.NR_TEXTURES + 7, ParticleSystem.JITTER_4_45)

	Card.setSourceTargetVectorToLength(6.0, settings)
	psp.add(ParticleSystem.new(settings), 0)
	if info.getLevel() > 1:
		var s = settings.getVector(AnimSettings.SOURCE)
		s.x -= 0.3
		s.y += 0.3
		var t = settings.getVector(AnimSettings.TARGET)
		t.x -= 0.3
		t.y += 0.3
		psp.add(ParticleSystem.new(settings), 200)
	if info.getLevel() > 2:
		var s = settings.getVector(AnimSettings.SOURCE)
		s.x += 0.5
		s.y += 0.2
		var t = settings.getVector(AnimSettings.TARGET)
		t.x += 0.5
		t.y += 0.2
		psp.add(ParticleSystem.new(settings), 400)
	return psp
