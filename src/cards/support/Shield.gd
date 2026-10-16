class_name ShieldCard
extends SupportCard
## Port of cards.support.Shield (class renamed to ShieldCard because
## equipment.Shield owns the name Shield; the Java name stays
## "cards.support.Shield" in ClassRegistry). Boosts the target's defense.

static var SHORT_INFO = ["Defense up", ""]
static var SOUNDS = [SoundMap.MAGICS_STATUS_UP]
static var DELAYS = [0]


func use(target, attacker):
	var boost: float = getBoostPercent() * attacker.getBattleAttack(Slot.SUPPORT)
	target.boostDefense(TURNS_TO_BOOST_MANY, (boost / target.getAttribute(Creature.DEFENSE)))
	return HitElement.new(self, -1, HitElement.NORMAL, "Defense Up!")


func createAttackPercent():
	return EMPTY


func createBoostPercent():
	return STANDARD_BOOST


func createTextInfo():
	return [
		"The shield of protection has kept warriors safe for a long time.",
		"The shield will protect the wielder against any infuriating attack",
		"from the fiends of the world."]


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
