class_name HitElement
extends RefCounted
## Port of battle.HitElement: information about an attack in battle.

const NORMAL = 0
const CRIT = 1
const MISS = 2
const IMMUNE = 3
var card = null
var addEffect = [null, null, null, null]
var cureElem = null
var attackValue = [-2, -2, -2, -2]
var effect = [0, 0, 0, 0]
var target: int = 0


## Java overloads:
##   HitElement(Card c, int attack, int effect, String additionalEffect)
##   HitElement(int attack, String additionalEffect)
func _init(c = null, attack = null, p_effect = null, additionalEffect = null) -> void:
	if p_effect == null and not (c is Object):
		# HitElement(int attack, String additionalEffect)
		attackValue[0] = int(c)
		addEffect[0] = attack
		effect[0] = 0
		return
	card = c
	attackValue[0] = int(attack)
	addEffect[0] = additionalEffect
	effect[0] = int(p_effect)
	match int(p_effect):
		CRIT:
			addEffect[0] = "Critical Hit!"
		MISS:
			addEffect[0] = "Miss!"
		IMMUNE:
			addEffect[0] = "Immune!"


## Merges the given element with this hit element.
func merge(elem):
	var index: int = 0
	var found: bool = false
	var i: int = 1
	while i < attackValue.size() and not found:
		found = attackValue[i] == -2
		index = i
		i += 1
	attackValue[index] = elem.attackValue[0]
	addEffect[index] = elem.getEffectText(0)
	effect[index] = elem.effect[0]
	if cureElem != null:
		cureElem.attackValue[0] += elem.getCureElement().getAttackDamage()


func cureMerge(tempCure):
	attackValue[0] += tempCure.getAttackDamage()


## Adds a damage value to the effect string ("Critical hit" -> "Critical hit 362").
func addToEffect(damage):
	if effect[0] != MISS and effect[0] != IMMUNE:
		# Java string concatenation turns null into "null".
		var s = addEffect[0]
		addEffect[0] = ("null" if s == null else str(s)) + " " + str(damage)


## Checks if this hit element is an attack on every target in a party.
func onAll():
	return attackValue[1] != -2


## Calculates the number of targets that this element hit.
func size():
	var s: int = 1
	for i in range(1, attackValue.size()):
		s += 0 if attackValue[i] == -2 else 1
	return s


## Checks if the card attacked with is a support card.
func isSupport():
	return card is SupportCard


## Creates the extra cure element (used by drain cards).
func addCure(cure, p_effect):
	cureElem = HitElement.new(cure, p_effect)


func getCureElement():
	return cureElem


## Java overloads getAttackDamage(int i) and getAttackDamage() [i = 0].
func getAttackDamage(i = null):
	var idx: int = 0 if i == null else int(i)
	return attackValue[idx] if attackValue[idx] > 0 else 0


func getActuallAttackDamage():
	return attackValue[0]


func getCard():
	return card


func getEffectText(index):
	return addEffect[index]


func isMiss(index):
	return effect[index] == HitElement.MISS


func didHit():
	return effect[0] != HitElement.MISS and effect[0] != HitElement.IMMUNE


func isCrit():
	return effect[0] == HitElement.CRIT


## Gets the type of this hit element (Slot.ATTACK, MAGIC or SUPPORT).
func getType():
	return card.getType()


## Gets the color (element) of this hit element.
func getColor():
	var color: int = AbstractCard.NO_ELEMENT
	if card != null:
		color = card.getElement()
	return color


func setTest(p_target):
	self.target = p_target


func getTest():
	return target
