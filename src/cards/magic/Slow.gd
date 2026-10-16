class_name Slow
extends Card
## Port of cards.magic.Slow: lowers the agility (speed) of the target.

static var SHORT_INFO = ["Enemy agility down", ""]
const TEXT = "Agility down!"


func use(target, attacker):
	var he = Card.checkPreferences(target, attacker, self, null)
	if he == null:
		target.boostSpeed(TURNS_TO_BOOST_MANY, -getAttackPercent())
		he = HitElement.new(self, -1, HitElement.NORMAL, TEXT)
	return he


func createAttackPercent():
	return STANDARD_BOOST


func createEffectChancePercent():
	return [0.9, 0.95, 1.0]


func createTextInfo():
	return [
			"Chronos, the deity of time, turning the great wheel of the Zodiac",
			"is called upon with the power containied in this card. Chronos will",
			"take the form of Aeon and turn time slower for the foes before him."]


func createShortInfo():
	setShortInfo("Lowers enemy's speed with " + str(J.round(getAttackPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func getAnimation(info):
	return Slow.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefaultNoFade()
	if info.isOnEnemy():
		settings.setValue(AnimSettings.SIZE, 1.0)
		settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, -4.0))
		settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, 0.0, -4.5))
	else:
		settings.setValue(AnimSettings.SIZE, 0.4)
		var s = info.getEnemy().getTempSource()
		settings.setVector(AnimSettings.SOURCE, Vector3f.new(s.x, s.y, s.z + 0.5))
		settings.setVector(AnimSettings.TARGET, Vector3f.new(s.x, s.y, s.z))
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.0, 0.0, 0.0))
	settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_WHITE)
	settings.setValue(AnimSettings.NR_PARTICLES, 1)
	settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0)
	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.ZERO)
	settings.setValue(AnimSettings.SPEED, 0)
	settings.setValue(AnimSettings.NR_TEXTURES, 3)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.CLOCK)
	settings.setValue(AnimSettings.NR_TEXTURES + 2, ParticleSystem.CLOCK_HOUR)
	settings.setValue(AnimSettings.NR_TEXTURES + 3, ParticleSystem.CLOCK_MINUTE)
	psp.add(SlowParticleSystem.new(settings), 0)
	return psp
