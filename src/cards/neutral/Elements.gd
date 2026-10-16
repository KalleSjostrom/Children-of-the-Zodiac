class_name Elements
extends Card
## Port of cards.neutral.Elements: base class of the element changing cards
## (TheElementOfFire/Ice/Wind/Earth). The concrete card sets the element.

const TEXT = "Elem Change!"
static var SHORT_INFO = ["Changes targets element", ""]


func use(target, attacker):
	return Card.checkPreferences(target, attacker, self, TEXT, true)


func createAttackPercent():
	return null


func createShortInfo():
	var elem: String = ""
	match element:
		Card.FIRE_ELEMENT:
			elem = "fire"
		Card.ICE_ELEMENT:
			elem = "ice"
		Card.WIND_ELEMENT:
			elem = "wind"
		Card.EARTH_ELEMENT:
			elem = "earth"
	setShortInfo("Changes the targets element to " + elem)


func getVeryShortInfo():
	return SHORT_INFO


func getAnimation(info):
	var psp := ParticleSystemPacket.new()
	if info.isOnEnemy():
		var settings = AnimationSettingsFactory.getDefaultNoFade()
		settings.setValue(AnimSettings.READY_MODE, ParticleSystem.IS_DELAYED)
		settings.setValue(AnimSettings.READY_MODE_DELAY_TIME, 500)
		settings.setValue(AnimSettings.SPEED, 12)
		settings.setValue(AnimSettings.COLOR, element)
		var es = EnemySystem.new(settings, info.getEnemy())
		psp.add(es, 0)
	else:
		return Cure.getStaticAnimation(info)
	return psp


func canBeMerged():
	return false
