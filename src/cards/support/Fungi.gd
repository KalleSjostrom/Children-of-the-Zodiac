class_name Fungi
extends SupportCard
## Port of cards.support.Fungi: cures hp and boosts the target's attack.

static var SHORT_INFO = ["Cures hp + offense up", ""]
static var SOUNDS = [SoundMap.MAGICS_CURE, SoundMap.MAGICS_STATUS_UP]
static var DELAYS = [0, 500]


func use(target, attacker):
	var boost: float = getBoostPercent() * attacker.getBattleAttack(Slot.SUPPORT)
	target.boostAttack(TURNS_TO_BOOST_MANY, (boost / target.getAttribute(Creature.ATTACK)))
	return cure(attacker, "Attack Up!")


func createAttackPercent():
	return STANDARD_SUPORT_LOW


func createBoostPercent():
	return STANDARD_BOOST_LOW


func createTextInfo():
	return [
		"The fungi picked in the deepest of forests has a peculiar effect",
		"on whoever dares to taste it. After the sporey flesh touches the",
		"lips of he who eats it, a rising physical potency will follow."]


func createShortInfo():
	setShortInfo("Support power: " + str(J.round(getAttackPercent() * 100)) + " %")
	setShortInfo("Boosts attack: " + str(J.round(getBoostPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return Cure.getStaticAnimation(info)
