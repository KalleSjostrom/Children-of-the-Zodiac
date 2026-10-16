class_name ProtectingBarrier
extends SupportCard
## Port of cards.support.ProtectingBarrier: boosts the target's magic
## defense.

static var SHORT_INFO = ["Magic defense up", ""]
static var SOUNDS = [SoundMap.MAGICS_STATUS_UP]
static var DELAYS = [0]


func use(target, attacker):
	var boost: float = getBoostPercent() * attacker.getBattleAttack(Slot.SUPPORT)
	target.boostMagicDefense(TURNS_TO_BOOST_MANY, (boost / target.getAttribute(Creature.MAGIC_DEFENSE)))
	return HitElement.new(self, -1, HitElement.NORMAL, "Magic Defense Up!")


func createAttackPercent():
	return EMPTY


func createBoostPercent():
	return STANDARD_BOOST


func createTextInfo():
	return [
		"The armor of the Zodiac was forged in ancient times, before even",
		"the Tenjins walked upon the green earth. This magic armor will",
		"surely keep the bearer safe and sound for any kin of the black arts."]


func createShortInfo():
	setShortInfo("Boosts magic def: " + str(J.round(getBoostPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return Cure.getStaticAnimation(info)
