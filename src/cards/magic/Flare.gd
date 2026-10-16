class_name Flare
extends PowerMagic
## Port of cards.magic.Flare.
##
## This class represents the Flare magic in the game. A Flare is a strong
## version of the fire magic.

static var SHORT_INFO = ["Powerful fire magic", ""]
static var SOUNDS = [SoundMap.MAGICS_FLARE]
static var DELAYS = [450]


## This method sets the element to fire.
func setElement():
	element = FIRE_ELEMENT


## Creates and returns the textual information of the card.
func createTextInfo():
	return [
			"The blazing fires of the Flare was created by the three Zodiacs of",
			"fire Aries, Leo and Sagittarius. A flare could turn even a massive",
			"block of ice into a tidal wave rendering any ice defense useless."]


func canBeMerged():
	return false


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return Flare.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	settings.setValue(AnimSettings.NR_PARTICLES, 1500.0)
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, -6.0))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, 0.0, -12.0))
	settings.setValue(AnimSettings.SPEED, 0.0)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_POWER, 0.0)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0.0)
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, -0.03)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, -0.018)
	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, 0.0, 0.0))
	settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 5.0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.08)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.08)
	settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.PARTICLES_DESTROYED)
	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.FLARE_EMITTER_TYPE)
	settings.setValue(AnimSettings.IS_DEAD_LIMIT, 30.0)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, 0.0)
	psp.add(ParticleSystem.new(settings), 0)
	return psp
