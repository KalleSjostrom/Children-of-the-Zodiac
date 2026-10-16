class_name Magic
extends Card
## Port of cards.magic.Magic.
##
## This class combines the shared price grouping for the magic cards.
## All these cards should have the same price regardless of element.


## This method lets the attacker attack the target with this card.
func use(target, attacker):
	return attack(target, attacker)


## Creates the attack percent (one value per card level).
func createAttackPercent():
	return STANDARD_ATTACK


func createShortInfo():
	setShortInfo("Power: " + str(J.round(getAttackPercent() * 100)) + " %")
