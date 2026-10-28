class_name Blizzard
extends PowerMagic
## Port of cards.magic.Blizzard.
##
## This class represents the Blizzard magic in the game. A Blizzard is a strong
## version of the ice magic.

static var SHORT_INFO = ["Powerful ice magic", ""]
static var SOUNDS = [
		SoundMap.MAGICS_BLIZZARD, SoundMap.MAGICS_BLIZZARD, SoundMap.MAGICS_BLIZZARD,
		SoundMap.MAGICS_BLIZZARD, SoundMap.MAGICS_BLIZZARD, SoundMap.MAGICS_BLIZZARD]
static var DELAYS = [1, 200, 200, 200, 200, 200]


## Plays all the sounds (not limited by the level as in Card.playSound()).
func playSound():
	var soundEffectDelay = getSoundEffectDelay()
	var soundEffect = getSoundEffect()
	var size: int = soundEffectDelay.size()
	var found: bool = false
	var i: int = 0
	while i < size and not found:
		found = soundEffectDelay[0] > 0
		i += 1
	if found:
		_playSoundSequence(soundEffectDelay, soundEffect, size)
	else:
		for j in range(size):
			SoundPlayer.playSound(soundEffect[j])


## This method sets the element to ice.
func setElement():
	element = ICE_ELEMENT


## Creates and returns the textual information of the card.
func createTextInfo():
	return [
			"Razor sharp ice crystals rains heavely from the sky whilst the cold",
			"paralyzes the enemies. This blizzard bears the names of Cancer,",
			"Scorpius and Pisces and will exhaust even the largest of fires."]


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return Blizzard.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefault()
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.5 + ParticleSystem.rand.nextDouble() * 2, 3.0, -5.9))
	settings.setValue(AnimSettings.SPEED, 6.0)
	settings.setValue(AnimSettings.COLOR, ICE_ELEMENT)
	settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Y_LESS_TARGET_Y)

	if not info.isOnEnemy():
		var t = settings.getVector(AnimSettings.TARGET)
		t.z = -2.0
		t.y = -1.0

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

	psp.add(ParticleSystem.new(settings), 0)
	psp.add(ParticleSystem.new(settings), 600)
	var s = settings.getVector(AnimSettings.SOURCE)
	s.x -= 0.3
	s.y += 0.3
	var t2 = settings.getVector(AnimSettings.TARGET)
	t2.x -= 0.3
	t2.y += 0.3
	psp.add(ParticleSystem.new(settings), 200)
	psp.add(ParticleSystem.new(settings), 800)
	s = settings.getVector(AnimSettings.SOURCE)
	s.x += 0.5
	s.y += 0.2
	t2 = settings.getVector(AnimSettings.TARGET)
	t2.x += 0.5
	t2.y += 0.2
	psp.add(ParticleSystem.new(settings), 400)
	psp.add(ParticleSystem.new(settings), 1000)
	return psp
