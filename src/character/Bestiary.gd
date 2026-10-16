class_name Bestiary
extends RefCounted
## Port of character.Bestiary: a list of all the enemies in the game collected
## in a bestiary. Here, the player can browse through the enemies that the
## player has encountered. If the player has encountered the enemy enough
## times, some stats and images are shown from the bestiary page in the menu.

static var bestiary = null
## Dictionary int -> Stats.
var enemyList = {}

func _init() -> void:
	enemyList = {}

## Gets the only Bestiary object.
static func getBestiary():
	if bestiary == null:
		bestiary = Bestiary.new()
	return bestiary

## Java overloads:
## getStats() -> the Dictionary of all stats (used by Save).
## getStats(int index) -> the index:th enemy added.
## getStats(Enemy enemy) -> the stats of the given enemy.
## getStats(String name) -> the stats of the enemy with the given db name.
func getStats(index = null):
	if index == null:
		return enemyList
	if index is int:
		return enemyList.get(index)
	if index is String:
		for key in enemyList:
			var stats = enemyList.get(key)
			if index == stats.enemy.getDbName():
				return stats
		return null
	# Enemy
	return getStats(String(index.getDbName()))

## Gets the size of the bestiary.
func getSize():
	return enemyList.size()

## Adds the given enemy in the bestiary together with the given stats.
func addEnemy(enemy, stats):
	if enemy == null:
		push_error("Null enemy!")
		GameCore.exitGame()
		return
	enemyList[getSize()] = Stats.new(enemy, stats)

## Updates the battle counter for the given enemy. This method is
## called after an enemy has been defeated.
func updateStats(enemy, enemySize):
	getStats(enemy).battleCounter += int(enemySize)


## The stats for an enemy. These stats are the attributes of an enemy but with
## a limiting counter that must be higher than a set value to get the actual
## attribute of an enemy. Otherwise ??? is returned as the attribute.
class Stats extends RefCounted:
	const NAME = 0
	const HP = 1
	const AGILITY = 2
	const ATTACK = 3
	const MAGIC = 4
	const SUPPORT = 5
	const DEFENSE = 6
	const MAGIC_DEFENSE = 7
	const EVADE = 8
	const HIT = 9
	const ELEMENT = 10
	const GOLD = 11
	const EXPERIANCE = 12
	const IMAGE = 13
	const CRITICAL_HIT = 14
	const BATTLE_COUNTER = 15
	var enemy = null
	var stats = null
	var battleCounter: int = 0
	var counterOffset: int = 0

	func _init(enemy = null, stats = null) -> void:
		self.enemy = enemy
		self.stats = stats

	## The enemy associated with these stats.
	func getEnemy():
		return enemy

	## Gets an array with the stats of the enemy, or "???" for the attributes
	## that the player has not earned yet.
	func getInfo():
		var info: Array = J.array(BATTLE_COUNTER + 1, null)
		for i in range(1, IMAGE + 1):
			info[i] = str(enemy.getAttribute(i)) if battleCounter + counterOffset + 1 >= int(stats[i]) else "???"
		info[BATTLE_COUNTER] = str(battleCounter)
		info[NAME] = enemy.getName() if battleCounter + counterOffset + 1 >= int(stats[13]) else "???"
		return info

	## Causes the attributes up to the given attribute of the enemy to be
	## shown in the bestiary.
	func moveCounterTo(attribute):
		if battleCounter + counterOffset < int(stats[attribute]):
			counterOffset = int(stats[attribute]) - battleCounter

	## Causes all the attributes of the enemy to be shown in the bestiary.
	func moveCounterToLast():
		for i in range(0, BATTLE_COUNTER):
			moveCounterTo(i)

	## Checks if the player has encountered this enemy enough times to show
	## the image in the bestiary menu page.
	func shouldShowImage():
		return battleCounter >= int(stats[IMAGE])

	func setCounter(counter):
		battleCounter = int(counter)

	func setCounterOffset(counter):
		counterOffset = int(counter)

	func getBattleCounter():
		return battleCounter

	func getCounterOffset():
		return counterOffset
