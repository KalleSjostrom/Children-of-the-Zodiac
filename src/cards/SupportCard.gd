class_name SupportCard
extends Card
## Port of cards.SupportCard.
##
## This class is a generalization of all the support cards in the game.
## Its only purpose is that it creates means to separate a support card
## from an other card. All the cards that should be put in the support slot
## in battle must extend this class.

## Java: private final float[] BOOST_PERCENT = createBoostPercent();
## (created lazily on first use).
var BOOST_PERCENT = null
var _boostPercentCreated: bool = false


## Gets the amount of percent to boost some characteristics.
func getBoostPercent():
	if not _boostPercentCreated:
		BOOST_PERCENT = createBoostPercent()
		_boostPercentCreated = true
	return BOOST_PERCENT[level - 1]


## Gets the amount of percent to boost the target attribute with.
##
## per: the attack percent of the card.
## support: the total support offense of the attacker.
## targetAttribute: the target attribute to boost.
func getBoost(per, support, targetAttribute):
	var boost: float = per * support
	return boost / targetAttribute


## Java overloads: cure(Character attacker) and
## cure(Character attacker, String effect).
## Calculates the effect of a "cure"-card being used by the attacker.
func cure(attacker, effect = null):
	if effect == null:
		effect = ""
	var baseAttack: int = attacker.getBattleAttack(Slot.SUPPORT)
	var cureAmount: int = J.round(baseAttack * getAttackPercent())
	var hitType: int = HitElement.NORMAL
	return HitElement.new(self, cureAmount, hitType, effect)


## Creates the boost percent of this card. If this method is not
## overridden the boost percent will be set to 0, 0, 0.
func createBoostPercent():
	return [0.0, 0.0, 0.0]
