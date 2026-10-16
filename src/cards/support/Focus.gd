class_name Focus
extends SupportCard
## Port of cards.support.Focus: boosts the target's magic attack.

static var SHORT_INFO = ["Magic offense up", ""]
static var SOUNDS = [SoundMap.MAGICS_STATUS_UP]
static var DELAYS = [0]


func use(target, attacker):
	var boost: float = getBoostPercent() * attacker.getBattleAttack(Slot.SUPPORT)
	target.boostMagicAttack(TURNS_TO_BOOST_MANY, (boost / target.getAttribute(Creature.MAGIC_ATTACK)))
	return HitElement.new(self, -1, HitElement.NORMAL, "Magic Attack Up!")


func createAttackPercent():
	return EMPTY


func createBoostPercent():
	return STANDARD_BOOST


func createTextInfo():
	return [
		"Takes a moment to focus all inner strenght, creating an immens",
		"magical offense capability. When the magic power is then released",
		"nothing will be left but clouds of dust."]


func createShortInfo():
	setShortInfo("Boosts magic off: " + str(J.round(getBoostPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return Cure.getStaticAnimation(info)
