class_name CriticalBlow
extends Card
## Port of cards.offense.CriticalBlow.
##
## A battle card with one addition: the chance of a critical hit is greatly
## increased.

static var shortInfo = ["Attack + increased chance", "for critical hit"]
var lastAttacker = 0


## A critical blow increases the chance to make a critical blow.
func use(target, attacker):
	return attack(target, attacker, getEffectChanceToHit() + CRITICAL_PRECENT)


func createAttackPercent():
	return SPECIAL_ATTACK


func createEffectChancePercent():
	return STANDARD_EFFECT_CHANCE


func createTextInfo():
	return [
		"A sword forged by the great blacksmith from the ancient times,",
		"especially made to cut critical wounds on the target. This card",
		"releases the essence of the devastating edge from the past."]


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")
	setShortInfo("Chance for critical hit: " + str(J.round((getEffectChanceToHit() + CRITICAL_PRECENT) * 100)) + " %")


func getVeryShortInfo():
	return shortInfo


func playSound():
	var s: String = BattleCard.SOUNDS[lastAttacker]
	var i = getSoundEffectDelay()
	BattleCard.playBattleSound(s, i[0])


func getAnimation(info):
	var attacker = info.getAttacker()
	if attacker != null:
		lastAttacker = attacker.getIndex()
	return BattleCard.getStaticAnimation(info)
