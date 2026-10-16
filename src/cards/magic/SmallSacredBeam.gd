class_name SmallSacredBeam
extends Card
## Port of cards.magic.SmallSacredBeam: the enemy (smaller animation) version
## of SacredBeam.

static var SHORT_INFO = ["Powerful magic +", "chance of open wound"]
static var SOUNDS = [SoundMap.MAGICS_SACRED_BEAM]
static var DELAYS = [200]


func use(target, attacker):
	var he = Card.checkPreferences(target, attacker, self, null)
	if he == null:
		var fullName: String = ""
		var simpleName: String = "openwound"
		var ret: int = Card.checkPreferences3(
				target, attacker, null, false, self, fullName, simpleName)
		match ret:
			Card.IMMUNE:
				he = attack(target, attacker, "Immune!", true)
			Card.HIT:
				target.openWound()
				he = attack(target, attacker, "Open wound!", true)
			Card.MISS:
				he = attack(target, attacker, "Open wound failed!", true)
			_:
				pass
	return he


func createAttackPercent():
	return STANDARD_ATTACK_LV4


func setElement():
	element = NO_ELEMENT


func createTextInfo():
	return [
			"An extremely bright ray of light burns a hole in the very essence",
			"of night as it passes through the target. When the ray finally",
			"burns out, the foe is left painfully bleeding to death."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %, (causes Open Wound)")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return SmallSacredBeam.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = AnimationSettingsFactory.getDefaultNoFade()
	var source = info.getEnemy().getTempSource()
	settings.setVector(AnimSettings.TARGET, Vector3f.new(0.0, -0.5, -1.1))
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(0.0, 0.0, -6.0) if source == null else source)
	settings.setValue(AnimSettings.CHECK_DESTROY_MODE, ParticleSystem.POS_Z_GREATER_TARGET_Z)
	settings.setValue(AnimSettings.DESTROY_MODE, ParticleValues.DESTROY_MULTIPLE_TIMES)
	settings.setValue(AnimSettings.COLOR, ParticleValues.COLOR_GRAY)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.01, 0.01, 0.01))
	settings.setValue(AnimSettings.SIZE, 0.1)
	settings.setValue(AnimSettings.SPEED, 7)
	settings.setValue(AnimSettings.NR_PARTICLES, 500)
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.05)
	settings.setValue(AnimSettings.EMITTER_TYPE, ParticleSystem.INTERPOLATING_EMITTER_TYPE)
	psp.add(ParticleSystem.new(settings), 0)
	return psp


func getSimpleName():
	return "SacredBeam"
