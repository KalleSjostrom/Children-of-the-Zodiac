class_name HerbOfVitality
extends SupportCard
## Port of cards.support.HerbOfVitality: cures hp and boosts the target's
## defense.

static var SHORT_INFO = ["Cures hp + defense up", ""]
static var SOUNDS = [SoundMap.MAGICS_CURE, SoundMap.MAGICS_STATUS_UP]
static var DELAYS = [0, 500]


func use(target, attacker):
	var boost: float = getBoostPercent() * attacker.getBattleAttack(Slot.SUPPORT)
	target.boostDefense(TURNS_TO_BOOST_MANY, (boost / target.getAttribute(Creature.DEFENSE)))
	return cure(attacker, "Defense Up!")


func createAttackPercent():
	return STANDARD_SUPORT_LOW


func createBoostPercent():
	return STANDARD_BOOST_LOW


func createTextInfo():
	return [
		"The mystical herb have aided adventurers for an aeon of time.",
		"Not only for its healing powers but also for its significant",
		"impact on the users physical defense."]


func createShortInfo():
	setShortInfo("Support power " + str(J.round(getAttackPercent() * 100)) + " %")
	setShortInfo("Boosts defense")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return Cure.getStaticAnimation(info)
