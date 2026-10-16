class_name Destroyer
extends Card
## Port of cards.offense.Destroyer.
##
## A powerful physical attack card (level 4 attack percent) whose animation
## slices the enemy.

static var SHORT_INFO = ["Powerful attack", ""]
var lastAttacker = 0


func use(target, attacker):
	return attack(target, attacker)


func createAttackPercent():
	return STANDARD_ATTACK_LV4


func createTextInfo():
	return [
		"The spirit of the katana resides in this card. The worlds most powerful and",
		"deadly sword, sharp enough to cut through steel as well as foes. To withstand",
		"an impact of this kind, you must be tought and... oh, yeah right, you can't."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func playSound():
	var s: String = BattleCard.SOUNDS[lastAttacker]
	var i = getSoundEffectDelay()
	BattleCard.playBattleSound(s, i[0])


func getAnimation(info):
	var attacker = info.getAttacker()
	if attacker != null:
		lastAttacker = attacker.getIndex()
	var psp := ParticleSystemPacket.new()

	var settings = BattleCard.getDefaultBattleCardSettings(level)

	var middle: float = info.getEnemy().getInfo().get_(EnemyInfo.MIDDLE_POINT)
	var d: float = info.getEnemy().getInfo().get_(EnemyInfo.DEPTH)
	settings.setVector(AnimSettings.SOURCE, Vector3f.new(-1.115, middle - 0.325, d))
	settings.setVector(AnimSettings.TARGET, Vector3f.new(1.115, middle + 0.325, d))
	settings.setBoolean(AnimSettings.DESTROY_ENEMY_SLICE, true)
	settings.setValue(AnimSettings.READY_MODE, float(ParticleSystem.IS_DELAYED))
	settings.setValue(AnimSettings.READY_MODE_DELAY_TIME, 1500.0)

	psp.add(ParticleSystem.new(settings, info.getEnemy()), 0)
	return psp
