class_name BlackDeath
extends Card
## Port of cards.magic.BlackDeath: the enemy version of Death.

static var SHORT_INFO = ["Chance of instant kill", ""]
const TEXT = "Instant Kill!"
static var SOUNDS = [SoundMap.MAGICS_DEATH]
static var DELAYS = [0]


func getSimpleName():
	return "Death"


func use(target, attacker):
	var he = Card.checkPreferences(target, attacker, self, null)
	if he == null:
		if Values.rand.nextFloat() <= getEffectChanceToHit():
			var damage: int = target.getAttribute(Creature.HP)
			he = HitElement.new(self, damage, HitElement.NORMAL, TEXT)
		else:
			he = HitElement.new(self, -1, HitElement.MISS, "")
	return he


func createAttackPercent():
	return null


func createEffectChancePercent():
	return [0.4, 0.5, 0.6]


func createTextInfo():
	return [
			"The grim reaper will make an appearance if this card is successfully",
			"used. The foe before the wielder will follow the reaper down to",
			"the netherworld where an eternity of pain awaits."]


func createShortInfo():
	setShortInfo(str(J.round(getEffectChanceToHit() * 100)) + " % to kill your foe")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return BlackDeath.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefaultNoFade()
	settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_WHITE)
	var s = info.getEnemy().getTempSource()
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(s.x, s.y, s.z + 0.5))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(s))
	settings.setValue(AnimSettings.NR_PARTICLES, 1)
	settings.setValue(AnimSettings.IS_DEAD_LIMIT, 0)
	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.ZERO)
	settings.setValue(AnimSettings.SIZE, 0.2)
	settings.setValue(AnimSettings.SPEED, 0.3)
	settings.setValue(AnimSettings.NR_TEXTURES, 1)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, ParticleSystem.DEATH_0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.1)
	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.DEMOLISH_EMITTER_TYPE)
	settings.setValue(AnimSettings.BLEND_MODE, ParticleSystem.BLEND_MODE_NO_BLEND)
	settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.PLAIN_DESTROY)
	settings.setValue(AnimSettings.NR_TEXTURES, 1)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.0, 0.0, 0.0))
	psp.add(ImageParticleSystem.new(settings), 0)
	return psp
