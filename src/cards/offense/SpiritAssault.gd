class_name SpiritAssault
extends Card
## Port of cards.offense.SpiritAssault.
##
## Damages the enemy with the power of the dead: the offensive power of any
## dead party member is added to the caster of this card.

static var SHORT_INFO = ["Attack + adds the offense", "of dead party members"]
var lastAttacker = 0


func use(target, attacker):
	var chars: Array = Load.getCharacters()
	var extraAttack: int = 0
	for i in range(chars.size()):
		var c = chars[i]
		if not c.isAlive():
			extraAttack += c.getBattleAttack(Slot.ATTACK)
	return attack(target, attacker, CRITICAL_PRECENT, "", getType(), getType(), extraAttack, false)


func createAttackPercent():
	return STANDARD_ATTACK_LV4


func createTextInfo():
	return [
		"The strenght of fallen comrades fills the wielder as the",
		"attack slices through the enemies. But as suddenly as they",
		"appeared, the spirits of the dead soon wanders away."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")
	setShortInfo("Hit with the power of your dead party members")


func getVeryShortInfo():
	return SHORT_INFO


func playSound():
	var s: String = BattleCard.SOUNDS[lastAttacker]
	var i = getSoundEffectDelay()
	BattleCard.playBattleSound(s, i[0])


func getAnimation(info):
	if info.getAttacker() != null:
		lastAttacker = info.getAttacker().getIndex()
	return SpiritAssault.getStaticAnimation(info)


static func getStaticAnimation(info):
	var psp := ParticleSystemPacket.new()
	var settings = BattleCard.getDefaultBattleCardSettings(info.getLevel())
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.04)
	var size: float = 0.0
	match info.getLevel():
		1:
			settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.024)
			size = 0.5
		2:
			settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.022)
			size = 0.6
		3:
			settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.02)
			size = 0.7
		_:
			pass
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(-size, -0.4, -4.0))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(size, 0.4, -4.0))

	psp.add(ParticleSystem.new(settings), 800)

	settings = AnimationSettingsFactory.getDefault()
	settings.setValue(AnimSettings.EMITTANCE_TIME_STEP, (Values.LOGIC_INTERVAL / 1000.0) * 0.2)
	settings.setVector(AnimSettings.POSITION_NOISE, Vector3f.new(0.2, 0.2, 0.2))
	settings.setValue(AnimSettings.SPEED, 0.1)
	settings.setValue(AnimSettings.NR_PARTICLES, 50.0)
	settings.setValue(AnimSettings.SIZE, 0.1)
	settings.setValue(AnimSettings.FADE_RANDOM_MULT, 0.0)
	settings.setValue(AnimSettings.FADE_RANDOM_ADD, 0.0)
	settings.setValue(AnimSettings.FADE_INCREASE_DISTANCE_MULTIPLIER, 0.0)
	settings.setBoolean(AnimSettings.ADDITIVE_COLORING, false)
	settings.setValue(AnimSettings.COLOR, float(ParticleValues.COLOR_WHITE))
	var chars: Array = Load.getCharacters()
	for i in range(chars.size()):
		if not chars[i].isAlive():
			var x: float = BattleValues.getCharPosXForSupport(i) + 0.1
			var y: float = BattleValues.CHARACTER_POS_Y + 0.1
			var v := Vector3f.new(x, y, -2.0)
			settings.setVector(AnimSettings.SOURCE, v)
			settings.setVector(AnimSettings.TARGET, Vector3f.new(x, y, -2.1))
			settings.setVector(AnimSettings.DESTROY_GRAVITY_TARGET_POINT, Vector3f.new(0.0, 0.0, -2.0))
			settings.setValue(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_MULT, 0.2)
			settings.setBoolean(AnimSettings.DESTROY_GRAVITY_TARGET_POINT_KILL_ON_ARRIVE, false)
			psp.add(0, ParticleSystem.new(settings), 0)
	return psp
