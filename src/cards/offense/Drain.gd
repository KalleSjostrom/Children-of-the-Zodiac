class_name Drain
extends Card
## Port of cards.offense.Drain.
##
## Damages the enemy just like a normal battle card but also heals the
## attacker some percentage of the damage amount.

static var DRAIN_PERCENTAGE = [0.5, 1.0, 1.5]
static var SHORT_INFO = ["Attack + adds some of", "the damage to your hp"]
var lastAttacker = 0


## A drain card will draw some of the life taken from an enemy to the
## attacker.
func use(target, attacker):
	var he = Card.checkPreferences(target, attacker, self, null)
	if he == null:
		he = attack(target, attacker, true)
		if he.getAttackDamage() > 0:
			var cure: int = he.getAttackDamage()
			# Java: int cure *= float (truncating conversion).
			cure = int(cure * DRAIN_PERCENTAGE[he.getCard().getLevel() - 1])
			he.addCure(cure, "Drained")
	return he


func createAttackPercent():
	return SPECIAL_ATTACK


func createTextInfo():
	return [
		"A nosferatu is a blood sucking creature who gain life by taking",
		"life from other living creatures. This card abides by the same",
		"twisted nature as the lord of darkness."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")
	setShortInfo("Will drain " + str(J.round(DRAIN_PERCENTAGE[level - 1] * 100)) + " % of the damage")


func getVeryShortInfo():
	return SHORT_INFO


func playSound():
	var s: String = BattleCard.SOUNDS[lastAttacker]
	var i = getSoundEffectDelay()
	BattleCard.playBattleSound(s, i[0])


func getAnimation(info):
	if info.getAttacker() != null:
		lastAttacker = info.getAttacker().getIndex()
	return Drain.getStaticAnimation(info)


static func getStaticAnimation(info):
	var index: int = Load.getCharacterIndex(info.getAttacker().getName())

	var psp := ParticleSystemPacket.new()
	var settings = BattleCard.getDefaultBattleCardSettings(info.getLevel())
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.04)

	psp.add(ParticleSystem.new(settings), 0)

	settings.setValue(AnimSettings.NR_PARTICLES, 1000.0)
	settings.setValue(AnimSettings.SIZE, 0.1)
	settings.setValue(AnimSettings.PARTICLE_MASS, 0.0)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.001)
	settings.setValue(AnimSettings.COLOR, float(ParticleValues.COLOR_RANDOM))
	settings.setValue(AnimSettings.MASS_RANDOM_MULT, 0.3)
	settings.setValue(AnimSettings.DESTROY_MODE, float(ParticleValues.DESTROY_ONCE))

	settings.setVector(AnimSettings.DESTROY_FADE_GRAVITY, Vector3f.new(0.0, -0.1, 0.0))
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.DESTROY_FADE_RANDOM_ADD, 0.002)
	settings.setValue(AnimSettings.DESTROY_FORCE_VECTOR_AMPLIFIER, 0.0)
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, true)
	settings.setValue(AnimSettings.READY_MODE, float(ParticleSystem.IS_DESTROYED))

	var x: float = BattleValues.getCharPosXForSupport(index) + 0.1
	var y: float = BattleValues.CHARACTER_POS_Y + 0.1
	var v := Vector3f.new(x, y, -2.0)

	settings.setVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT, v)
	settings.setValue(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_MULT, 0.6)
	settings.setBoolean(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_KILL_ON_ARRIVE, true)

	psp.add(0, ParticleSystem.new(settings), 0)
	return psp
