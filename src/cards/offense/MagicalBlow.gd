class_name MagicalBlow
extends Card
## Port of cards.offense.MagicalBlow.
##
## Like a battle card but damages with the magic attack (on the target's
## physical defense).

static var SHORT_INFO = ["Attack using magical offense", ""]
var lastAttacker = 0


func use(target, attacker):
	return attack(target, attacker, CRITICAL_PRECENT, "", Slot.MAGIC, Slot.ATTACK, 0, false)


func createAttackPercent():
	return SPECIAL_ATTACK


func createTextInfo():
	return [
		"The attacker will wield a sword brimming with the magic essence",
		"of the attacker. The attack will pass through any physical defense",
		"in much the same way as magical force."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")
	setShortInfo("Hit with magical attack power on physical defense")


func getVeryShortInfo():
	return SHORT_INFO


func playSound():
	var s: String = BattleCard.SOUNDS[lastAttacker]
	var i = getSoundEffectDelay()
	BattleCard.playBattleSound(s, i[0])


func getAnimation(info):
	var psp := ParticleSystemPacket.new()
	if info.getAttacker() != null:
		lastAttacker = info.getAttacker().getIndex()
	var settings = BattleCard.getDefaultBattleCardSettings(info.getLevel())

	settings.setValue(AnimSettings.NR_PARTICLES, 200.0)
	settings.setValue(AnimSettings.SIZE, 0.03)
	settings.setValue(AnimSettings.EMITTER_TYPE, float(ParticleSystem.INTERPOLATING_EMITTER_TYPE))
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.05)
	psp.add(ParticleSystem.new(settings), 0) # Normal

	settings.setValue(AnimSettings.SIZE_RANDOM_MULT, 0.02)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.2, 0.2, 0.2))
	settings.setValue(AnimSettings.COLOR, float(ParticleValues.COLOR_YELLOW))
	settings.setValue(AnimSettings.NR_TEXTURES, 1.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, float(ParticleSystem.ROUND_WHITE))
	psp.add(ParticleSystem.new(settings), 0) # YELLOW

	settings.setValue(AnimSettings.NR_TEXTURES, 2.0)
	settings.setValue(AnimSettings.NR_TEXTURES + 1, float(ParticleSystem.JITTER_4))
	settings.setValue(AnimSettings.NR_TEXTURES + 2, float(ParticleSystem.JITTER_4_45))

	settings.setValue(AnimSettings.DESTROY_MODE, float(ParticleValues.DESTROY_ONCE))
	settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 3.0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.08)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.08)

	psp.add(ParticleSystem.new(settings), 0)
	return psp
