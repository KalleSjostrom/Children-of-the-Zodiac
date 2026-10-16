class_name Haste
extends SupportCard
## Port of cards.support.Haste: boosts the target's speed.

static var SHORT_INFO = ["Agility up", ""]
const TEXT = "Agility up!"
static var SOUNDS = [SoundMap.MAGICS_HASTE]
static var DELAYS = [0]


func use(target, attacker):
	target.boostSpeed(TURNS_TO_BOOST_MANY, getBoostPercent())
	return HitElement.new(self, -1, HitElement.NORMAL, TEXT)


func createAttackPercent():
	return [0.0, 0.0, 0.0]


func createBoostPercent():
	return STANDARD_BOOST


func createTextInfo():
	return [
		"Chronos, the deity of time, turning the great wheel of the Zodiac",
		"is called upon with the power containied in this card. Chronos will",
		"escalate time itself and therefore aid the target in battle."]


func createShortInfo():
	setShortInfo("Boosts speed: " + str(J.round(getBoostPercent() * 100)) + " %")


func getVeryShortInfo():
	return SHORT_INFO


func getSoundEffect():
	return SOUNDS


func getSoundEffectDelay():
	return DELAYS


func getAnimation(info):
	return Cure.getStaticAnimation(info)
