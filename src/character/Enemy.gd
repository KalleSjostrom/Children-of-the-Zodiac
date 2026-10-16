class_name Enemy
extends Creature
## Port of character.Enemy: an enemy in the game. An enemy is a creature
## which the player battles.

const NORMAL_IMAGE = 0
const PRE_ATTACK_IMAGE = 1
const ATTACK_IMAGE = 2
var images = null
var armor = null
var cardPreferences = null
var dropRate: float = 0.0
var dropItem = null
var attackPercent: float = 0.0
var magicPercent: float = 0.0
var info = null
var bossDialog = null
var script_ = null
var dbName = null
var triggers = null
var items = null
var diesound = null
var startFrame: int = 0
var nextPlace = null

## Creates an enemy with the given name, attribute array and array of images
## to use when displaying the enemy.
func _init(name = null, att = null, imageArray = null) -> void:
	super(name, att)
	images = imageArray
	# Java: new Random(Math.abs(this.hashCode())).nextInt(70). Deterministic
	# mode derives the seed instead (instance ids depend on allocation order).
	var seedValue = null if J.deterministic else absi(get_instance_id())
	progress = float(JRandom.new(seedValue).nextInt(70))

func getDbName():
	return dbName

func setDbName(dbName):
	self.dbName = dbName

func setDropData(item, rate):
	dropItem = item
	dropRate = float(rate)

## Copies this enemy. It just calls the constructor with the attributes as
## parameters.
func copy():
	var attCopy = Values.copyArray(getAttribute())
	var enemy = get_script().new(name, attCopy, images)
	enemy.setDbName(dbName)
	if armor != null:
		enemy.setArmor(armor.defense, armor.magicDefense)
	enemy.setPreferences(int(attackPercent * 100), int(magicPercent * 100))
	enemy.setCardPreferences(cardPreferences)
	enemy.setInfo(info)
	enemy.setDropData(dropItem, dropRate)
	enemy.setDieSound(diesound)
	enemy.setNextPlace(nextPlace)
	enemy.setStartFrame(startFrame)
	return enemy

## Loads the image names for the enemy: name1.png, name2.png, ...
## Reuse indices are pairs (destination, source) of image indices.
static func loadImages(name, length, reuseindices):
	var imgs: Array = J.array(int(length), null)
	for i in range(imgs.size()):
		imgs[i] = Values.EnemyImages + name + "/" + name + str(i + 1) + ".png"
	var i: int = 0
	while i < reuseindices.size():
		imgs[reuseindices[i]] = imgs[reuseindices[i + 1]]
		i += 2
	return imgs

## Sets the card preference.
func setCardPreferences(cardPre):
	cardPreferences = cardPre

func addCardPreferences(name, val):
	if cardPreferences == null:
		cardPreferences = {}
	cardPreferences[name] = val

## Gets the image of this enemy with the specified number (NORMAL_IMAGE,
## PRE_ATTACK_IMAGE or ATTACK_IMAGE).
func getImage(number = null):
	return images[number]

## Gets the total defense of the creature.
func getTotalDefense():
	var def: int = 0
	if armor != null and not tempCrushed:
		def += armor.defense
	return getAttribute(DEFENSE) + def

## Gets the total magical defense of the creature.
func getTotalMagicDefense():
	var def: int = 0
	if armor != null and not tempCrushed:
		def += armor.magicDefense
	return getAttribute(MAGIC_DEFENSE) + def

## Gets the total attack of the given type (Slot.ATTACK, Slot.MAGIC or
## Slot.SUPPORT), boosts included. Only used from the battle.
func getBattleAttack(type):
	var att: int = 0
	if type == Slot.ATTACK:
		att = J.round(attackBoost.getCurrentBoost() * getTotalAttack())
	elif type == Slot.MAGIC:
		att = J.round(magicBoost.getCurrentBoost() * getTotalMagicAttack())
	elif type == Slot.SUPPORT:
		att = getAttribute(SUPPORT_ATTACK)
	return att

## Gets the total defense of the given type (Slot.ATTACK or Slot.MAGIC),
## boosts included. Only used from the battle.
func getBattleDefense(type):
	var def: int = 0
	if type == Slot.ATTACK:
		def = J.round(defenseBoost.getCurrentBoost() * getTotalDefense())
	elif type == Slot.MAGIC:
		def = J.round(magicDefenseBoost.getCurrentBoost() * getTotalMagicDefense())
	return def

## Gets the total attack of the enemy.
func getTotalAttack():
	return getAttribute(ATTACK)

## Gets the total magic attack of the enemy.
func getTotalMagicAttack():
	return getAttribute(MAGIC_ATTACK)

## Gets the type of attack that this enemy would like to use.
func getAttackType():
	var type: int
	var rand: float = J.random()
	if rand <= attackPercent:
		type = Slot.ATTACK
	elif rand <= magicPercent:
		type = Slot.MAGIC
	else:
		type = Slot.SUPPORT
	return type

func getAttackTypeExcluedSupport():
	var type: int = Slot.SUPPORT
	while type == Slot.SUPPORT:
		type = getAttackType()
	return type

## Gets the amount of experience to give to the player when this enemy
## is defeated.
func getSpoilExp():
	return getAttribute(EXPERIENCE_SPOILS)

## Gets the amount of gold to give to the player when this enemy
## is defeated.
func getSpoilGold():
	return getAttribute(GOLD_SPOILS)

func getSpoilItem():
	return dropItem

func getDropRate():
	return dropRate

## Gets the list of all the images in this enemies animation.
func getImages():
	return images

## Gets the percentage of vulnerability for the card with the given name,
## or -1 if there is no preference.
func getCardPreference(name):
	var retVal: int = -1
	if cardPreferences != null:
		var percent = cardPreferences.get(name)
		if percent != null:
			retVal = int(percent)
	return retVal

## Gets the index of the next image in this enemies animation.
func nextImage(imageIndex):
	imageIndex += 1
	if imageIndex >= images.size():
		imageIndex = 0
	return imageIndex

func setDieSound(diesound):
	self.diesound = diesound

func getDieSound():
	return diesound

## Creates an armor with the given values and equips it.
func setArmor(armorDefense, armorMagicDefense):
	armor = EnemyArmor.new(armorDefense, armorMagicDefense)

## Temporarily removes the armor for this enemy.
func crushArmor():
	var res: int = -1
	if armor == null:
		res = Creature.HAS_NO_ARMOR
	elif tempCrushed:
		res = Creature.ARMOR_ALREADY_CRUSHED
	else:
		res = Creature.ARMOR_CRUSHED
		tempCrushed = true
	return res

## Changes the element of this enemy to the given value.
func changeElement(element):
	setAttribute(ELEMENT, element)

## Does nothing (the element of an enemy never has to be changed back).
func changeElementBack():
	pass

## Gets the element of this enemy.
func getElement():
	return getAttribute(ELEMENT)

func setStartFrame(startFrame):
	self.startFrame = int(startFrame)

func getStartFrame():
	return startFrame

## Converts the given percents to floating point values from 0 to 1.
func setPreferences(attPer, magPer):
	attackPercent = attPer / 100.0
	magicPercent = magPer / 100.0

func setInfo(info):
	self.info = info

func getInfo():
	return info

func setDialog(bd):
	bossDialog = bd

func getDialog():
	return bossDialog

func setScript(script_):
	self.script_ = script_

func getScript():
	return script_

func setTriggers(triggers):
	self.triggers = triggers

func setItems(items):
	self.items = items

func getTriggers():
	return triggers

func getItems():
	return items

func setNextPlace(nextPlace):
	self.nextPlace = nextPlace

func getNextPlace():
	return nextPlace


## An enemy armor. It only has normal defense and magical defense.
class EnemyArmor extends RefCounted:
	var defense: int = 0
	var magicDefense: int = 0

	func _init(armorDefense = null, armorMagicDefense = null) -> void:
		defense = int(armorDefense)
		magicDefense = int(armorMagicDefense)
