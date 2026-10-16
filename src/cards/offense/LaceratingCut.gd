class_name LaceratingCut
extends Card
## Port of cards.offense.LaceratingCut.
##
## A battle card with one addition: the chance of an open wound exists.
## The hit is calculated in getAnimation (useBefore) so the animation can
## show the wound; use() returns that result.

static var SHORT_INFO = ["Attack +", "chance for open wound"]
var lastAttacker = 0
var preCalculatedElement = null
var openWound = false


## The target starts bleeding and its life decreases some amount each turn
## for three turns, if the attack is successful.
func use(target, attacker):
	return preCalculatedElement


func useBefore(target, attacker):
	openWound = false
	var he = Card.checkPreferences(target, attacker, self, null)
	if he == null:
		var fullName := ""
		var simpleName := "openwound"
		var ret: int = Card.checkPreferences3(
				target, attacker, null, false, self, fullName, simpleName)
		if ret == Card.IMMUNE:
			he = attack(target, attacker, "Immune!", true)
		elif ret == Card.HIT:
			target.openWound()
			openWound = true
			he = attack(target, attacker, "Open wound!", true)
		elif ret == Card.MISS:
			he = attack(target, attacker, "Open wound failed!", true)
	return he


func createAttackPercent():
	return SPECIAL_ATTACK


func createEffectChancePercent():
	return STANDARD_EFFECT_CHANCE


func createTextInfo():
	return [
		"The razor sharp edge of this blade will cut the enemy with much",
		"precision that will cause the enemy to bleed heavily. The bleeding",
		"will stop eventually but it will surely take some time."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")
	setShortInfo("Chance to cause open wound " + str(J.round(getEffectChanceToHit() * 100)) + "%")


func getVeryShortInfo():
	return SHORT_INFO


func playSound():
	var s: String = BattleCard.SOUNDS[lastAttacker]
	var i = getSoundEffectDelay()
	BattleCard.playBattleSound(s, i[0])


func getAnimation(info):
	var attacker = info.getAttacker()
	if attacker != null:
		lastAttacker = info.getAttacker().getIndex()
	preCalculatedElement = useBefore(info.getEnemy().getEnemy(), attacker)
	return LaceratingCut.getStaticAnimation(info, openWound)


static func getStaticAnimation(info, openWound):
	var psp := ParticleSystemPacket.new()
	var settings = BattleCard.getDefaultBattleCardSettings(info.getLevel())
	if not openWound:
		psp.add(ParticleSystem.new(settings), 0)
	else:
		psp.add(ParticleSystem.new(settings), 0)
		settings.setValue(AnimSettings.NR_PARTICLES, 500.0)
		settings.setValue(AnimSettings.SIZE, 0.06)
		settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.12)
		settings.setValue(AnimSettings.PARTICLE_MASS, 0.0)
		settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.001)
		settings.setValue(AnimSettings.COLOR, float(ParticleValues.COLOR_RED))
		settings.setValue(AnimSettings.MASS_RANDOM_MULT, 0.3)
		settings.setValue(AnimSettings.DESTROY_MODE, float(ParticleValues.DESTROY_ONCE))
		settings.getVector(AnimSettings.SOURCE).y -= 0.1
		settings.getVector(AnimSettings.TARGET).y -= 0.1

		settings.setValue(AnimSettings.READY_MODE, float(ParticleSystem.IS_DESTROYED))

		settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, -0.1, 0.0))
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.0)
		settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.02)
		settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 0.0)
		settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)

		psp.add(0, ParticleSystem.new(settings), 100)
	return psp
